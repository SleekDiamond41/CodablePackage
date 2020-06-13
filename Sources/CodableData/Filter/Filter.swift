//
//  Filter.swift
//  SQL
//
//  Created by Michael Arrington on 4/2/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation

protocol Rule {
	var query: (String, [SQLValue]) { get }
}

enum JoinMethod: String, Codable, Equatable {
	case and = "AND"
	case or = "OR"
}


enum Query: Codable, Equatable {
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let type = try container.decode(CodingKeys.Types.self, forKey: .type)
		
		switch type {
		case .anyRule:
			self = .anyRule(try container.decode(AnyRule.self, forKey: .value))
		case .compound:
			self = .compound(try container.decode(Compound.self, forKey: .value))
		}
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		switch self {
		case .anyRule(let rule):
			try container.encode(CodingKeys.Types.anyRule, forKey: .type)
			try container.encode(rule, forKey: .value)
		case .compound(let compound):
			try container.encode(CodingKeys.Types.compound, forKey: .type)
			try container.encode(compound, forKey: .value)
		}
	}
	
	private enum CodingKeys: String, CodingKey {
		case type
		case value
		
		enum Types: String, Codable {
			case anyRule
			case compound
		}
	}
	
	case anyRule(AnyRule)
	case compound(Compound)
	
	var query: String {
		switch self {
		case .anyRule(let rule):
			return rule.query
		case .compound(let compound):
			return compound.query
		}
	}
	
	var bindings: [SQLValue] {
		switch self {
		case .anyRule(let rule):
			return rule.bindings
		case .compound(let compound):
			return compound.bindings
		}
	}
	
	mutating func remove(column: String) {
		switch self {
		case .anyRule(var rule):
			rule.remove(column: column)
			self = .anyRule(rule)
		case .compound(var compound):
			compound.remove(column: column)
			self = .compound(compound)
		}
	}
}

struct AnyRule: Codable, Equatable {
	let column: String
	
	private(set) var query: String
	private(set) var bindings: [SQLValue]
	
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


struct Compound: Codable, Equatable {
	
	var query: String {
		var results = [String]()
		
		for i in parts.indices {
			guard !parts[i].query.query.isEmpty else {
				continue
			}
			var s = ""
			
			if i > parts.startIndex {
				s += " " + parts[i].method.rawValue + " "
			}
			
			if usesParenthesis {
				s += "("
			}
			
			s += parts[i].query.query
			
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
	
	var bindings: [SQLValue] {
		return Array(parts.map { $0.query.bindings }.joined())
	}
	
	struct Part: Codable, Equatable {
		let method: JoinMethod
		var query: Query
	}
	
	private(set) var parts = [Part]()
	let usesParenthesis: Bool
	
	mutating func remove(column: String) {
		for i in parts.indices {
			parts[i].query.remove(column: column)
		}
	}
}




public struct Filter<Element>: Codable, Equatable where Element: Filterable {

	var query: String {
		
		return [
			_query.map { !$0.query.isEmpty ? "WHERE " + $0.query : "" },
			sort?.query.0,
			limit?.query.0,
		]
		.compactMap { $0 }
		.filter { !$0.isEmpty }
		.joined(separator: " ")
	}
	
	var bindings: [SQLValue] {
		(_query?.bindings ?? [])
			+ (sort?.query.1 ?? [])
			+ (limit?.query.1 ?? [])
	}

	private(set) var _query: Query?
	private var limit: Limit?
	private var sort: SortRule<Element>?
	
	var usesColumns: Bool {
		return [_query?.query, sort?.query.0]
			.compactMap { $0 }
			.allSatisfy { !$0.isEmpty }
	}
	
	mutating func remove(column: String) {
		_query?.remove(column: column)
		sort?.remove(column: column)
	}
	

	init<T, U>(path: KeyPath<Element, T>, rule: U) where U: Rule, T: Bindable {
		
		self._query = .anyRule(AnyRule(column: Element.key(for: path).stringValue, rule: rule))
    }

    public init() {
		// this allows consumers to create a Filter for ALL elements of type Element
	}

    // MARK: - Helper Methods
    private func join(_ other: Filter, with method: JoinMethod, usingParentheses: Bool) -> Filter {
        var copy = self
		
		if _query == nil {
			copy._query = other._query
        }
        else {
			let parts = [_query, other._query]
				.compactMap { $0 }
				.map { Compound.Part(method: method, query: $0) }
			
			copy._query = .compound(Compound(parts: parts, usesParenthesis: usingParentheses))
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

	func and<T, U>(path: KeyPath<Element, T>, rule: U) -> Filter where U: Rule, T: Bindable {
		return join(Filter(path: path, rule: rule), with: .and, usingParentheses: false)
	}

	func or<T, U>(path: KeyPath<Element, T>, rule: U) -> Filter where U: Rule, T: Bindable {
		return join(Filter(path: path, rule: rule), with: .or, usingParentheses: false)
	}

    // MARK: - Public Methods

    public func and(_ filter: Filter) -> Filter {
		return join(filter, with: .and, usingParentheses: true)
    }

    public func or(_ filter: Filter) -> Filter {
		return join(filter, with: .or, usingParentheses: true)
    }

	public func sorting<T>(by path: KeyPath<Element, T>, _ direction: SortRule<Element>.Direction = .ascending) -> Filter where T: Bindable & Comparable {

		var copy = self
        copy.sort = self.sort?.then(path, direction) ?? SortRule(path, direction)
		return copy
	}

	public func limit(_ limit: UInt32, page: UInt32 = 0) -> Filter {
		var copy = self
		copy.limit = Limit(limit, page)
		return copy
	}
}

extension Filter: CustomStringConvertible {

    public var description: String {
		
		var valueString = "["
		
		let bindings = _query?.bindings ?? []
		
		if !bindings.isEmpty {
			
			for value in bindings {
				switch value {
				case .text(let s):
					valueString.append("\"\(s)\"")
				case .integer(let int):
					valueString.append("\(int)")
				case .double(let num):
					valueString.append("\(num)")
				case .blob(let data):
					valueString.append(data.description)
				case .null:
					valueString.append("<NULL>")
				}
				
				valueString.append(", ")
			}
			
			// remove the dangling comma and space
			valueString.removeLast(2)
		}
		
		valueString += "]"
		
		let q = query.isEmpty ? "" : (" " + query)
		
        return """
        Filter<\(Element.self)>
            - Query:\(q)
            - Binding Values: \(valueString)
        """
    }
}
