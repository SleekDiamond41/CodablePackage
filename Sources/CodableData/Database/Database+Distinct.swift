//
//  Database+Distinct.swift
//  
//
//  Created by Michael Arrington on 6/7/20.
//

import Foundation


extension Database {
	
	private func _distinct<Element, T>(_ path: KeyPath<Element, T>, using filter: Filter<Element>) throws -> [T] where Element: Model & Filterable, T: Bindable & Unbindable {
		
		let column = Element.key(for: path).stringValue
		
		var s = Statement(.distinct(filter, column: column))
		
		try s.prepare(in: connection.db)
		
		defer {
			s.finalize()
		}
		
		let proxy = Proxy(s, isNull: { (_) in false })
		var results = [T]()
		var status = s.step()
		
		while status == .row {
			results.append(T.unbind(proxy))
			status = s.step()
		}
		
		return results
	}
	
	@inlinable
	public func distinct<Element, T>(_ path: KeyPath<Element, T>) throws -> [T] where Element: Model & Filterable, T: Bindable & Unbindable {
		return try distinct(path, using: Filter<Element>())
	}
	
	public func distinct<Element, T>(_ path: KeyPath<Element, T>, using filter: Filter<Element>) throws -> [T] where Element: Model & Filterable, T: Bindable & Unbindable {
		do {
			// make sure the table exists
			_ = try table(Element.tableName)
			return try _distinct(path, using: filter)
		} catch PreparationError.noSuchTable {
			return []
		}
	}
}
