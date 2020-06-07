//
//  Database+Distinct.swift
//  
//
//  Created by Michael Arrington on 6/7/20.
//

import Foundation


extension Database {
	
	public func distinct<Element, T>(_ path: KeyPath<Element, T>, by direction: SortRule<Element>.Direction? = nil) throws -> [T] where Element: Model & Filterable, T: Bindable & Unbindable {
		guard try table(Element.tableName) != nil else {
			return []
		}
		
		let column = Element.key(for: path).stringValue
		
		var s = Statement(.distinct(Element.self, column: column, direction: direction))
		
		try s.prepare(in: connection.db)
		
		defer {
			s.finalize()
		}
		
		var results = [T]()
		var status = s.step()
		
		while status == .row {
			results.append(try T.unbind(from: s, at: 0))
			status = s.step()
		}
		
		return results
	}
}
