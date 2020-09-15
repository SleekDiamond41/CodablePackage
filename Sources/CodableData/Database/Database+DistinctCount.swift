//
//  Database+DistinctCount.swift
//  
//
//  Created by Michael Arrington on 6/7/20.
//

import Foundation


extension Database {
	
	private func _distinctCount<Element, T>(_ path: KeyPath<Element, T>, using filter: Filter<Element>) throws -> Int where Element: Model & Filterable, T: Bindable & Unbindable {
		
		let column = Element.key(for: path).stringValue
		
		var s = Statement(.distinctCount(filter, columns: [column]))
		
		try s.prepare(in: connection.db)
		
		defer {
			s.finalize()
		}
		
		let status = s.step()
		
		guard status == .row else {
			assertionFailure()
			return 0
		}
		
		let proxy = Proxy(s, isNull: { _ in false })
		return Int.unbind(proxy)
	}
	
	@inlinable
	public func distinctCount<Element, T>(_ path: KeyPath<Element, T>) throws -> Int where Element: Model & Filterable, T: Bindable & Unbindable {
		return try distinctCount(path, using: Filter<Element>())
	}
	
	public func distinctCount<Element, T>(_ path: KeyPath<Element, T>, using filter: Filter<Element>) throws -> Int where Element: Model & Filterable, T: Bindable & Unbindable {
		
		do {
			// make sure table exists
			_ = try table(Element.tableName)
			return try _distinctCount(path, using: filter)
			
		} catch PreparationError.noSuchTable {
			return 0
		}
	}
}
