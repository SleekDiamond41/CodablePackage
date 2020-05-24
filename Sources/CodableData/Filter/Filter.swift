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

enum JoinMethod: String {
	case and = "AND"
	case or = "OR"
}

protocol _Query {
	var query: String { get }
	var bindings: [Bindable] { get }
	
	mutating func remove(column: String)
}


struct AnyRule: _Query {
	let column: String
	
	private(set) var query: String
	private(set) var bindings: [Bindable]
	
	init<R>(column: String, rule: R) where R: Rule {
		self.column = column
		
		let stuff = rule.query
		
		self.bindings = stuff.1
		self.query = "\(column.sqlFormatted()) \(stuff.0)"
	}
	
	mutating func remove(column: String) {
		if column == self.column {
			query = ""
			bindings = []
		}
	}
}


struct Compound: _Query {
	
	var query: String {
		var results = [String]()
		
		for i in parts.indices {
			guard !parts[i].1.query.isEmpty else {
				continue
			}
			var s = ""
			
			if i > parts.startIndex {
				s += " " + parts[i].0.rawValue + " "
			}
			
			if usesParenthesis {
				s += "("
			}
			
			s += parts[i].1.query
			
			if usesParenthesis {
				s += ")"
			}
			
			results.append(s)
		}
		
		guard !results.isEmpty else {
			return ""
		}
		
		return results.joined()
	}
	
	var bindings: [Bindable] {
		return Array(parts.map { $0.1.bindings }.joined())
	}
	
	var parts = [(JoinMethod, _Query)]()
	let usesParenthesis: Bool
	
	mutating func remove(column: String) {
		for i in parts.indices {
			parts[i].1.remove(column: column)
		}
	}
}




public struct Filter<Element> where Element: Filterable {

	var query: String {
		
		return [
			_query.map { !$0.query.isEmpty ? "WHERE " + $0.query : "" },
			sort?.query,
			limit?.query,
		]
		.compactMap { ($0?.isEmpty ?? true) ? nil : $0 }
		.joined(separator: " ")
		
//		var result = ""
//
//		if let query = _query?.query, !query.isEmpty {
//			result += "WHERE " + query
//		}
//		if let sort = sort {
//			result += (result.count > 0 ? " " : "") + sort.query
//		}
//		if let limit = limit {
//			result += (result.count > 0 ? " " : "") + limit.query
//		}
//		return result
	}
	
	var bindings: [Bindable] { _query?.bindings ?? [] }

	private(set) var _query: _Query?
	private var limit: Limit?
	private var sort: SortRule<Element>?
	
	var usesColumns: Bool {
		return [_query?.query, sort?.query]
			.compactMap { $0 }
			.reduce(false) { $0 || !$1.isEmpty }
	}
	
	mutating func remove(column: String) {
		_query?.remove(column: column)
		sort?.remove(column: column)
	}


	init(query: _Query?, bindings: [Bindable], limit: Limit?, sort: SortRule<Element>?) {
		self._query = query
//		self.bindings = bindings
		self.limit = limit
		self.sort = sort
	}

	init(_ sort: SortRule<Element>) {
//		self._query = ""
//		self.bindings = []
		self.limit = nil
		self.sort = sort
	}

    init<T, U>(path: KeyPath<Element, T>, rule: U) where U: Rule, U.T == T {
//        let (str, vals) = rule.query
//        self._query = "\(Element.key(for: path).stringValue) \(str)"
		self._query = AnyRule(column: Element.key(for: path).stringValue, rule: rule)
//		self.bindings = rule.query.1
        self.limit = nil
        self.sort = nil
    }

    public init() {
//        self._query = ""
//        self.bindings = []
        self.limit = nil
        self.sort = nil
    }

    // MARK: - Helper Methods
    private func join(_ other: Filter, with method: JoinMethod, usingParentheses: Bool) -> Filter {
        var copy = self
		
		if _query == nil {
			copy._query = other._query
        }
        else {
			let parts = [_query, other._query].compactMap { $0 }.map { (method, $0) }
			copy._query = Compound(parts: parts, usesParenthesis: usingParentheses)
        }

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
		return join(Filter(path: path, rule: rule), with: .and, usingParentheses: false)
	}

	func or<T, U>(path: KeyPath<Element, T>, rule: U) -> Filter where U: Rule, U.T == T {

		return join(Filter(path: path, rule: rule), with: .or, usingParentheses: false)
	}

    // MARK: - Public Methods

    public func and(_ filter: Filter) -> Filter {
		return join(filter, with: .and, usingParentheses: true)
    }

    public func or(_ filter: Filter) -> Filter {
		return join(filter, with: .or, usingParentheses: true)
    }

	public func sorting<T>(by path: KeyPath<Element, T>, direction: SortRule<Element>.Direction = .ascending) -> Filter where T: Bindable & Comparable {

		var copy = self
        copy.sort = self.sort?.then(path, direction: direction) ?? SortRule(path, direction: direction)
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
            - Binding Values: \(_query?.bindings ?? [])
        """
    }
}
