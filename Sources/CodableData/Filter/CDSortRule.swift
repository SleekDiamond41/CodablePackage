//
//  SortRule.swift
//  SQL
//
//  Created by Michael Arrington on 4/3/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation

fileprivate func string<Element, T>(path: KeyPath<Element, T>, ascending: Bool) -> String where Element: CDFilterable, T: CDBindable & Comparable {
	return "ORDER BY \(Element.key(for: path).stringValue) \(ascending ? "ASC" : "DESC")"
}


public struct CDSortRule<Element: CDFilterable> {
	
	var query: String {
		return parts.joined(separator: ", ")
	}
	private let parts: [String]
	
	init(parts: [String]) {
		self.parts = parts
	}
	
	public init<T>(_ path: KeyPath<Element, T>, ascending: Bool = true) where T: CDBindable & Comparable {
		self.parts = [string(path: path, ascending: ascending)]
	}
	
	public func then<T>(_ path: KeyPath<Element, T>, ascending: Bool = true) -> CDSortRule where T: CDBindable & Comparable {
		return CDSortRule(parts: parts + [string(path: path, ascending: ascending)])
	}
}
