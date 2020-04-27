//
//  SortRule.swift
//  SQL
//
//  Created by Michael Arrington on 4/3/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


public struct SortRule<Element: Filterable> {
	
	public enum Direction {
		case ascending, descending
	}
	
	private struct Sort {
		let column: String
		let direction: Direction
		
		var query: String {
			return column + " " + (direction == .ascending ? "ASC" : "DESC")
		}
	}
	
	var query: String {
		return "ORDER BY " + sorts.map { $0.query }.joined(separator: ", ")
	}
	private var sorts: [Sort]
	
	private init(sorts: [Sort]) {
		self.sorts = sorts
	}
	
	public init<T>(_ path: KeyPath<Element, T>, direction: Direction = .ascending) where T: Bindable & Comparable {
		self.sorts = [Sort(column: Element.key(for: path).stringValue, direction: direction)]
	}
	
	public func then<T>(_ path: KeyPath<Element, T>, direction: Direction = .ascending) -> SortRule where T: Bindable & Comparable {
		return SortRule(sorts: sorts + [Sort(column: Element.key(for: path).stringValue, direction: direction)])
	}
	
	mutating func remove(column: String) {
		sorts.removeAll { $0.column == column }
	}
}
