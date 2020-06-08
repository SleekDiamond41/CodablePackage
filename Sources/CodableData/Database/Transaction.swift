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


public struct Transaction: CustomStringConvertible {
	
	private var actions = [(query: String, values: [SQLValue])]()
	
	public var description: String {
		"""
		BEGIN TRANSACTION;
		\(actions.map { $0.query }.joined(separator: "\n"))
		END TRANSACTION;
		"""
	}
	
	internal init() { }
	
	public mutating func save<Element>(_ model: Element) where Element: Model & Codable & Filterable {
		let values = try! Writer<Element>.values(for: model)
		
		let query = String.save(Element.self, values)
		let vals = values.map { $0.value.bindingValue }
		
		actions.append((query, vals))
	}
	
	public mutating func save<C>(_ models: C) where C: Collection, C.Element: Model & Codable & Filterable {
		for model in models {
			save(model)
		}
	}
	
	public mutating func delete<Element>(_ model: Element) where Element: Model & Codable & Filterable {
		let id = model[keyPath: Element.idKey]
		let filter = Filter(Element.idKey, is: .equal(to: id))
		
		let query = String.delete(filter)
		
		// it's a little sloppy to just hardcode in the assumption that there will
		// be exactly one ? placeholder in the statement, but since we're making
		// the Filter in this same function it feels reasonable
		actions.append((query, [id.bindingValue]))
	}
	
	public mutating func delete<C>(_ models: C) where C: Collection, C.Element: Model & Codable & Filterable {
		for model in models {
			delete(model)
		}
	}
	
	internal mutating func execute(in db: Database) throws {
		
		var status = Status.error
		
		do {
			// we put this in a `do` block to make sure
			// the statement will be finalized
			var begin = Statement("BEGIN TRANSACTION;")
			try begin.prepare(in: db.connection.db)
			defer { begin.finalize() }
			
			status = begin.step()
		}
		
		guard status == .done else {
			preconditionFailure("okay how'd I mess up 'BEGIN TRANSACTION'")
		}
		
		for (q, values) in actions {
			var s = Statement(q)
			try s.prepare(in: db.connection.db)
			defer { s.finalize() }
			
			for (offset, value) in values.enumerated() {
				try s.bind(value, at: Int32(offset) + 1)
			}
			
			status = s.step()
			
			guard status == .done else {
				preconditionFailure()
			}
		}
		
		var end = Statement("END TRANSACTION;")
		try end.prepare(in: db.connection.db)
		defer { end.finalize() }
		
		status = end.step()
		
		guard status == .done else {
			preconditionFailure()
		}
	}
}
