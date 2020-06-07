//
//  Database+DistinctCount.swift
//  
//
//  Created by Michael Arrington on 6/7/20.
//

import Foundation


extension Database {
	
	public func distinctCount<Element, T>(_ path: KeyPath<Element, T>) throws -> Int64 where Element: Model & Filterable, T: Bindable & Unbindable {
		guard try table(Element.tableName) != nil else {
			return 0
		}
		
		let column = Element.key(for: path).stringValue
		
		var s = Statement(.distinctCount(Element.self, columns: [column]))
		
		try s.prepare(in: connection.db)
		
		defer {
			s.finalize()
		}
		
		guard s.step() == .row else {
			assertionFailure()
			return 0
		}
		
		return try Int64.unbind(from: s, at: 0)
	}
}
