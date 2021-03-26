//
//  Update.swift
//  
//
//  Created by Michael Arrington on 9/14/20.
//

import Foundation

extension Database {
	
	public func update(_ batch: AnyUpdate) throws {
		guard !batch.actions.isEmpty else {
			// nothing to do here
			return
		}
		
		var table: Table
		
		do {
			table = try self.table(batch.table)
		} catch PreparationError.noSuchTable {
			let temp = Table(name: batch.table, columns: batch.actions.map {
				Table.Column(name: $0.key, type: $0.value)
			})
			create(temp)
			
			table = try self.table(batch.table)
		}
		
		let filter = Transaction.AnyFilter(query: batch.filter.query, bindings: batch.filter.bindings)
		
		try Writer().update(table: &table,
							updates: batch.actions,
							filter: filter,
							connection: connection) { (t, columns) in
								for c in columns {
									try add(column: c, to: &t)
								}
		}
	}
}


public struct Update<Element> where Element: Model & Codable & Filterable {
	private(set) var actions: [String: SQLValue]
	let filter: Filter<Element>
	
	public init(_ filter: Filter<Element>) {
		self.filter = filter
		self.actions = [:]
	}
	
	public init(_ id: Element.PrimaryKey) {
		self.init(Filter(Element.idKey, is: .equal(to: id)))
	}
	
	public func set<Value>(_ path: WritableKeyPath<Element, Value>, to value: Value) -> Update where Value: Bindable {
		// using WritableKeyPath here means that consumers can't mutate items in the database
		// in ways that would be inconsistent with mutating a data model.
		// It is worth noting however that using this could mean that the database
		// could enter a state that is invalid, since the only constraints in this
		// system are on the data model itself, and this object bypasses the data model.
		
		var copy = self
		copy.actions[Element.key(for: path).stringValue] = value.bindingValue
		return copy
	}
	
	public func toAnyUpdate() -> AnyUpdate {
		return AnyUpdate(self)
	}
}

public struct AnyUpdate: Codable {
	let table: String
	let actions: [String: SQLValue]
	let filter: Transaction.AnyFilter
	
	init<Element>(_ update: Update<Element>) where Element: Model {
		self.table = Element.tableName
		self.actions = update.actions
		
		let query = update.filter.updateQuery
		self.filter = Transaction.AnyFilter(query: query.0, bindings: query.1)
	}
	
	public struct UpdateReader {
		let update: AnyUpdate
		
		public init(_ update: AnyUpdate) {
			self.update = update
		}
		
		public func getTableName() -> String {
			return update.table
		}
	}
}
