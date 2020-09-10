//
//  Database+DistinctCount.swift
//  
//
//  Created by Michael Arrington on 6/7/20.
//

import Foundation


extension Database {
	
	@inlinable
	public func distinctCount<Element, T>(_ path: KeyPath<Element, T>) throws -> Int64 where Element: Model & Filterable, T: Bindable & Unbindable {
		return try distinctCount(path, using: Filter<Element>())
	}
	
	public func distinctCount<Element, T>(_ path: KeyPath<Element, T>, using filter: Filter<Element>) throws -> Int64 where Element: Model & Filterable, T: Bindable & Unbindable {
		guard try table(Element.tableName) != nil else {
			return 0
		}
		
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
		return Int64.unbind(proxy)
	}
}
