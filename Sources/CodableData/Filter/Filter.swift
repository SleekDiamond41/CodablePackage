//
//  Filter.swift
//  SQL
//
//  Created by Michael Arrington on 4/2/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation

protocol Rule {
	associatedtype T: Bindable

	var query: (String, [T]) { get }
}


public struct Filter<Element> where Element: Filterable {

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

	private(set) var bindings: [Bindable]
	private var _query: String
	private var limit: Limit?
	private var sort: SortRule<Element>?


	init(query: String, bindings: [Bindable], limit: Limit?, sort: SortRule<Element>?) {
		self._query = query
		self.bindings = bindings
		self.limit = limit
		self.sort = sort
	}

	init(_ sort: SortRule<Element>) {
		self._query = ""
		self.bindings = []
		self.limit = nil
		self.sort = sort
	}

    init<T, U>(path: KeyPath<Element, T>, rule: U) where U: Rule, U.T == T {
        let (str, vals) = rule.query
        self._query = "\(Element.key(for: path).stringValue) \(str)"
        self.bindings = vals
        self.limit = nil
        self.sort = nil
    }

    public init() {
        self._query = ""
        self.bindings = []
        self.limit = nil
        self.sort = nil
    }

    // MARK: - Helper Methods
    private func join(_ other: Filter, with conjunction: String, usingParentheses: Bool) -> Filter {
        var copy = self

        if _query.isEmpty {
            // don't include self._query if there's nothing to add,
            // but use parentheses just to be extra safe
            copy._query = other._query
        }
        else {
            if usingParentheses {
                copy._query = "(" + _query + ") \(conjunction) (" + other._query + ")"
            }
            else {
                copy._query = _query + " \(conjunction) " + other._query
            }
        }

        copy.bindings += other.bindings

        if let sort = other.sort {
			// if there's a more recent `sort`,
			// that overrides the old value
            copy.sort = sort
        }

        if let limit = other.limit {
			// if there's a more recent `limit`,
			// that overrides the old value
            copy.limit = limit
        }

        return copy
    }

	func and<T, U>(path: KeyPath<Element, T>, rule: U) -> Filter where U: Rule, U.T == T {
        return join(Filter(path: path, rule: rule), with: "AND", usingParentheses: false)
	}

	func or<T, U>(path: KeyPath<Element, T>, rule: U) -> Filter where U: Rule, U.T == T {

        return join(Filter(path: path, rule: rule), with: "OR", usingParentheses: false)
	}

    // MARK: - Public Methods

    public func and(_ filter: Filter) -> Filter {
        return join(filter, with: "AND", usingParentheses: true)
    }

    public func or(_ filter: Filter) -> Filter {

        return join(filter, with: "OR", usingParentheses: true)
    }

	public func sorting<T>(by path: KeyPath<Element, T>, ascending: Bool = true) -> Filter where T: Bindable & Comparable {

		var copy = self
        copy.sort = self.sort?.then(path, ascending: ascending) ?? SortRule(path, ascending: ascending)
		return copy
	}

	public func limit(_ limit: Int, page: Int = 0) -> Filter {
		var copy = self
		copy.limit = Limit(limit, page)
		return copy
	}
}

extension Filter: CustomStringConvertible {

    public var description: String {
        return """
        Filter<\(Element.self)>
            - Query: "\(query)"
            - Binding Values: \(bindings)
        """
    }
}
