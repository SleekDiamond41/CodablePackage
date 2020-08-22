//
//  Transaction.swift
//  
//
//  Created by Michael Arrington on 6/6/20.
//

import Foundation
import OSLog


extension Database {
	
	public func transact(_ block: (inout Transaction) -> Void) throws {
		var transaction = Transaction()
		block(&transaction)
		try transaction.execute(in: self)
	}
}


public struct Transaction: Codable, CustomStringConvertible {
	
	private struct Action: Codable {
		let query: String
		let values: [SQLValue]
	}
	
	private var actions = [Action]()
	
	private func message(for action: Action) -> String {
		return """
		\(action.query)
			- Values: \(action.values)
		"""
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
		let values = try! Writer<Element>.values(for: model)
		
		let query = String.save(Element.self, values)
		let vals = values.map { $0.value.bindingValue }
		
		actions.append(Action(query: query, values: vals))
	}
	
	public mutating func save<C>(_ models: C) where C: Collection, C.Element: Model & Codable & Filterable {
		for model in models {
			save(model)
		}
	}
	
	public mutating func delete<Element>(_ filter: Filter<Element>) where Element: Model & Codable & Filterable {
		actions.append(Action(query: .delete(filter), values: filter.bindings))
	}
	
	public mutating func delete<Element>(_ model: Element) where Element: Model & Codable & Filterable {
		let id = model[keyPath: Element.idKey]
		let filter = Filter(Element.idKey, is: .equal(to: id))
		
		let query = String.delete(filter)
		
		// it's a little sloppy to just hardcode in the assumption that there will
		// be exactly one ? placeholder in the statement, but since we're making
		// the Filter in this same function it feels reasonable
		actions.append(Action(query: query, values: [id.bindingValue]))
	}
	
	public mutating func delete<C>(_ models: C) where C: Collection, C.Element: Model & Codable & Filterable {
		for model in models {
			delete(model)
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
				
				var s = Statement(action.query)
				try s.prepare(in: db.connection.db)
				defer { s.finalize() }
				
				for (offset, value) in action.values.enumerated() {
					try s.bind(value, at: Int32(offset) + 1)
				}
				
				status = s.step()
				
				guard status == .done else {
					preconditionFailure()
				}
				
				execute("END TRANSACTION;")
			}
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
}
