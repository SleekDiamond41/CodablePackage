//
//  WhereClause.swift
//  SQL
//
//  Created by Michael Arrington on 4/2/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation

protocol Rule {
	associatedtype T: CDBindable
	
	var query: (String, [T]) { get }
}


public struct CDFilter<Element> where Element: CDFilterable {
	
	var query: String {
		var result = ""
		if _query.count > 0 {
			result += "WHERE " + _query
		}
		if let sort = sort {
			result += (result.count > 0 ? " " : "") + sort.query
		}
		if let limit = limit {
			result += (result.count > 0 ? " " : "") + limit.query
		}
		return result
	}
	
	private(set) var bindings: [CDBindable]
	private var _query: String
	private var limit: CDLimit?
	private var sort: CDSortRule<Element>?
	
	static func query(_ q: String, sort: CDSortRule<Element>?, limit: CDLimit?) -> String {
		var result = ""
		if q.count > 0 {
			result += "WHERE " + q
		}
		if let sort = sort {
			result += (result.count > 0 ? " " : "") + sort.query
		}
		if let limit = limit {
			result += (result.count > 0 ? " " : "") + limit.query
		}
		return result
	}
	
	
	init(query: String, bindings: [CDBindable], limit: CDLimit?, sort: CDSortRule<Element>?) {
		self._query = query
		self.bindings = bindings
		self.limit = limit
		self.sort = sort
	}
	
	init(_ sort: CDSortRule<Element>) {
		self._query = ""
		self.bindings = []
		self.limit = nil
		self.sort = sort
	}
	
	public func and(_ filter: CDFilter) -> CDFilter {
		var copy = self
		copy._query = "(" + _query + ") AND (" + filter._query + ")"
		return copy
	}
	
	public func or(_ filter: CDFilter) -> CDFilter {
		var copy = self
		copy._query = "(" + _query + ") OR (" + filter._query + ")"
		return copy
	}
	
	
	init<T, U>(path: KeyPath<Element, T>, rule: U) where U: Rule, U.T == T {
		let (str, vals) = rule.query
		self._query = "\(Element.key(for: path).stringValue) \(str)"
		self.bindings = vals
		self.limit = nil
		self.sort = nil
	}
	
	func and<T, U>(path: KeyPath<Element, T>, rule: U) -> CDFilter where U: Rule, U.T == T {
		let (str, vals) = rule.query
		
		var copy = self
		copy._query += " AND \(Element.key(for: path).stringValue) \(str)"
		copy.bindings += vals
		return copy
	}
	
	func or<T, U>(path: KeyPath<Element, T>, rule: U) -> CDFilter where U: Rule, U.T == T {
		let (str, vals) = rule.query
		
		var copy = self
		copy._query += " OR \(Element.key(for: path).stringValue) \(str)"
		copy.bindings += vals
		return copy
	}
	
	public func sort<T>(by path: KeyPath<Element, T>, ascending: Bool = false) -> CDFilter where T: CDBindable & Comparable {
		let s: CDSortRule<Element>
		if let sort = sort {
			s = sort
		} else {
			s = CDSortRule(path, ascending: ascending)
		}
		var copy = self
		copy.sort = s
		return copy
	}
	
	public func sort(by sort: CDSortRule<Element>) -> CDFilter {
		var copy = self
		copy.sort = sort
		return copy
	}
	
	public func limit(_ limit: Int, _ page: Int = 1) -> CDFilter {
		var copy = self
		copy.limit = CDLimit(limit, page)
		return copy
	}
	
	public func limit(_ limit: CDLimit) -> CDFilter {
		var copy = self
		copy.limit = limit
		return copy
	}
	
}


func test() {
	
//	let ids = (UUID(), UUID(), UUID())
//	
//	let a = Filter<Person>(\.id, is: .equal(to: ids.0))
//		.or(\.id, is: .equal(to: ids.1))
//		.or(\.id, is: .equal(to: ids.2))
//	// WHERE id LIKE ? OR id LIKE ? OR id LIKE ?
//	
//	let b = Filter(\Person.nickName, is: .equal(to: nil))
//	
////	let c = Filter<Person>(\.id, .equal, to: ids.0)
//	
//	
//	
//	let filter = Filter(\Person.name, is: .notEqual(to: "Michael"))
//		.or(\.id, is: .notEqual(to: UUID()))
//		.or(\.name, is: .notEqual(to: "Arrington"))
//		.or(\.id, is: .notEqual(to: UUID()))
}


class MyClass: Equatable {
	static func == (left: MyClass, right: MyClass) -> Bool {
		return left.id == right.id
	}
	
	let id = UUID()
	var name: String = ""
}
