//
//  SortRule.swift
//  SQL
//
//  Created by Michael Arrington on 4/3/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation

fileprivate func string<Element, T>(path: KeyPath<Element, T>, ascending: Bool) -> String where Element: Filterable, T: Bindable & Comparable {
	return "ORDER BY \(Element.key(for: path).stringValue) \(ascending ? "ASC" : "DESC")"
}


public struct SortRule<Element: Filterable> {
	
	var query: String {
		return parts.joined(separator: ", ")
	}
	private let parts: [String]
	
	init(parts: [String]) {
		self.parts = parts
	}
	
	public init<T>(_ path: KeyPath<Element, T>, ascending: Bool = true) where T: Bindable & Comparable {
		self.parts = [string(path: path, ascending: ascending)]
	}
	
	public func then<T>(_ path: KeyPath<Element, T>, ascending: Bool = true) -> SortRule where T: Bindable & Comparable {
		return SortRule(parts: parts + [string(path: path, ascending: ascending)])
	}
}
