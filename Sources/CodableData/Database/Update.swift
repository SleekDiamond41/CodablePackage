//
//  Update.swift
//  
//
//  Created by Michael Arrington on 9/14/20.
//

import Foundation

extension Database {
	
	public func update<Element>(_ update: Update<Element>) throws where Element: Model & Codable & Filterable {
		guard !update.actions.isEmpty else {
			// nothing to do here
			return
		}
		
		var table: Table
		
		do {
			table = try self.table(Element.tableName)
		} catch PreparationError.noSuchTable {
			let temp = Table(name: Element.tableName, columns: update.actions.map {
				Table.Column(name: $0.key, type: $0.value)
			})
			create(temp)
			
			table = try self.table(Element.tableName)
		}
		
		let filter = Transaction.AnyFilter(query: update.filter.query, bindings: update.filter.bindings)
		
		try Writer().update(table: &table,
							updates: update.actions,
							filter: filter,
							connection: connection) { (t, columns) in
								for c in columns {
									try add(column: c, to: &t)
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
		
		public func set<Value>(_ path: KeyPath<Element, Value>, to value: Value) -> Update where Value: Bindable {
			var copy = self
			copy.actions[Element.key(for: path).stringValue] = value.bindingValue
			return copy
		}
	}
}
