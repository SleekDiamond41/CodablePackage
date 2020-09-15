//
//  Transaction.swift
//  
//
//  Created by Michael Arrington on 6/6/20.
//

import Foundation


extension Database {
	
	public func transact(_ block: (inout Transaction) -> Void) throws {
		var transaction = Transaction()
		block(&transaction)
		try transaction.execute(in: self)
	}
}


public struct Transaction: Codable, CustomStringConvertible {
	
	struct AnyFilter: Codable {
		let query: String
		let bindings: [SQLValue]
	}
	
	enum Action: Codable {
		case delete(table: String, AnyFilter)
		case save(table: String, values: [(String, SQLValue)])
		case partial(AnyUpdate)
		
		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			
			let temp = try container.decode(Case.self, forKey: .case)
			
			switch temp {
			case .delete:
				let table = try container.decode(String.self, forKey: .table)
				let filter = try container.decode(AnyFilter.self, forKey: .filter)
				self = .delete(table: table, filter)
				
			case .save:
				let table = try container.decode(String.self, forKey: .table)
				let values = try container.decode([Value].self, forKey: .values)
				self = .save(table: table, values: values.map { ($0.string, $0.value) })
				
			case .partial:
				let batch = try container.decode(AnyUpdate.self, forKey: .values)
				self = .partial(batch)
			}
		}
		
		func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			
			switch self {
			case let .delete(table: table, filter):
				try container.encode(Case.delete, forKey: .case)
				try container.encode(table, forKey: .table)
				try container.encode(filter, forKey: .filter)
				
			case let .save(table: table, values: values):
				try container.encode(Case.save, forKey: .case)
				try container.encode(table, forKey: .table)
				try container.encode(values.map { Value(string: $0.0, value: $0.1) }, forKey: .values)
				
			case let .partial(update):
				try container.encode(Case.partial, forKey: .case)
				try container.encode(update, forKey: .values)
			}
		}
		
		private struct Value: Codable {
			let string: String
			let value: SQLValue
		}
		
		private enum Case: String, Codable {
			case save
			case delete
			case partial
		}
		
		enum CodingKeys: String, CodingKey {
			case `case`
			
			case table
			case filter
			case values
		}
	}
	
	private var actions = [Action]()
	
	private func message(for action: Action) -> String {
		switch action {
		case let .delete(table: table, filter):
			return """
			DELETE FROM \(table):
			\(filter.query)
			- Values: \(filter.bindings)
			"""
		case let .save(table: table, values: values):
			return """
			SAVE TO \(table):
				- Values: \(values)
			"""
		case .partial(let update):
			return """
			UPDATE \(update.table)
			- Values: \(update.actions.map {
				$0.key + " = " + $0.value.description
			})
			- Query: \(update.filter.query)
			"""
		}
	}
	
	public var description: String {
		"""
		BEGIN TRANSACTION;
		\(actions.map { message(for: $0) })
		END TRANSACTION;
		"""
	}
	
	internal init() { }
	
	public mutating func save<Element>(_ model: Element) where Element: Model & Codable & Filterable {
		let values = try! Writer.values(for: model)
		
		actions.append(.save(table: Element.tableName, values: values))
	}
	
	public mutating func save<C>(_ models: C) where C: Collection, C.Element: Model & Codable & Filterable {
		let table = C.Element.tableName
		
		actions.append(contentsOf: models.map {
			let values = try! Writer.values(for: $0)
			return .save(table: table, values: values)
		})
	}
	
	public mutating func delete<Element>(_ filter: Filter<Element>) where Element: Model & Codable & Filterable {
		actions.append(.delete(table: Element.tableName, AnyFilter(query: filter.query, bindings: filter.bindings)))
	}
	
	public mutating func delete<Element>(_ model: Element) where Element: Model & Codable & Filterable {
		let key = Element.idKey
		let id = model[keyPath: key]
		let filter = Filter(key, is: .equal(to: id))
		
		delete(filter)
	}
	
	public mutating func delete<C>(_ models: C) where C: Collection, C.Element: Model & Codable & Filterable {
		
		guard !models.isEmpty else {
			// without this check, sending an empty array
			// would delete everything from the relevant table
			return
		}
		
		let key = C.Element.idKey
		let ids = models.map {
			$0[keyPath: key]
		}
		
		delete(Filter(key, is: .in(ids)))
	}
	
	public mutating func update(_ batch: AnyUpdate) {
		actions.append(.partial(batch))
	}
	
	@inlinable
	public mutating func update<S>(_ batches: S) where S: Sequence, S.Element == AnyUpdate {
		for batch in batches {
			update(batch)
		}
	}
	
	@inlinable
	public mutating func update<Element>(_ batch: Update<Element>) {
		update(AnyUpdate(batch))
	}
	
	@inlinable
	public mutating func update<S, Element>(_ batches: S) where S: Sequence, S.Element == Update<Element> {
		for batch in batches {
			update(batch)
		}
	}
	
	internal mutating func execute(in db: Database) throws {
		
		var status = Status.error
		
		func execute(_ s: String) {
			var begin = Statement(s)
			try! begin.prepare(in: db.connection.db)
			defer { begin.finalize() }
			
			status = begin.step()
			
			guard status == .done else {
				preconditionFailure("we messed up while performing '\(s)'")
			}
		}
		
		// write a thing
		execute("BEGIN IMMEDIATE TRANSACTION;")
		
		do {
			for action in actions {
				try perform(action, in: db)
			}
			
			execute("END TRANSACTION;")
			
		} catch {
			print("""
			ERROR while executing transaction:
			\(description)
			Error Message: \(String(describing: error))
			""")
			
			// we had an issue during the transaction,
			// so we roll back any changes made during this period
			execute("END TRANSACTION;")
			execute("ROLLBACK;")
			
			throw error
		}
	}
	
	private func perform(_ action: Action, in db: Database) throws {
		switch action {
		case let .save(table: table, values: vals):
			try db._save(tableName: table, values: vals)
			
		case let .delete(table: table, filter):
			try db._delete(table, query: filter.query, bindings: filter.bindings)
			
		case let .partial(batch):
			try db.update(batch)
		}
	}
}
