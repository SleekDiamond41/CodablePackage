//
//  Filter.swift
//  
//
//  Created by Michael Arrington on 8/6/20.
//

import Foundation
import SwiftFilter

public typealias Filter = SwiftFilter.Filter
public typealias Filterable = SwiftFilter.Filterable
public typealias SortRule = SwiftFilter.SortRule
public typealias Limit = SwiftFilter.Limit
public typealias Where = SwiftFilter.Where
public typealias SQLValue = SwiftFilter.SQLValue


public typealias Bindable = SwiftFilter.Bindable & Unbindable


extension SQLValue: CustomStringConvertible {
	
	public var description: String {
		switch self {
		case .integer(let num):
			return "\(num)"
		case .double(let num):
			return "\(num)"
		case .string(let s):
			return "'\(s)'"
		case .blob(let data):
			return "[RawData:\((data as NSData).length)-bytes]"
		case .null:
			return "NULL"
		}
	}
}


extension Where.StringEquality: CustomStringConvertible {
	var query: String {
		let column = T.key(for: keyPath).stringValue.sqlFormatted()
		
		return "\(column) LIKE ?"
	}
	
	var bindingValues: [SQLValue] {
		
		let value: String
		
		switch method {
		case .contains:
			value = "%\(self.value)%"
		case .exactly:
			value = "\(self.value)"
		case .starts:
			value = "\(self.value)%"
		case .ends:
			value = "%\(self.value)"
		}
		
		return [.string(value)]
	}
	
	public var description: String {
		let column = T.key(for: keyPath).stringValue
		
		switch method {
		case .contains:
			return "\(column) CONTAINS '\(value)'"
		case .exactly:
			return "\(column) IS EXACTLY '\(value)'"
		case .starts:
			return "\(column) STARTS WITH '\(value)'"
		case .ends:
			return "\(column) ENDS WITH '\(value)'"
		}
	}
}

extension Where.Equality: CustomStringConvertible {
	
	var query: String {
		let column = T.key(for: keyPath).stringValue.sqlFormatted()
		
		switch method {
		case .equal:
			return column + " IS ?"
		case .notEqual:
			return column + " IS NOT ?"
		case .in:
			let placeholders = Array(repeating: "?", count: values.count)
				.joined(separator: ", ")
			return column + " IN (\(placeholders))"
		case .notIn:
			let placeholders = Array(repeating: "?", count: values.count)
				.joined(separator: ", ")
			return column + " NOT IN (\(placeholders))"
		}
	}
	
	public var description: String {
		let column = T.key(for: keyPath).stringValue
		
		switch method {
		case .equal:
			return column + " IS \(values[0].description)"
		case .notEqual:
			return column + " IS NOT \(values[0].description)"
		case .in:
			let vals = values
				.map { $0.description }
				.joined(separator: ", ")
			return column + " IS IN (\(vals))"
		case .notIn:
			let vals = values
				.map { $0.description }
				.joined(separator: ", ")
			return column + " IS NOT IN (\(vals))"
		}
	}
}

extension Where.Comparison: CustomStringConvertible {
	var query: String {
		let column = T.key(for: keyPath).stringValue.sqlFormatted()
		
		switch method {
		case .lessThan:
			return column + " < ?"
		case .greaterThan:
			return column + " > ?"
		case .between:
			return column + " BETWEEN ? AND ?"
		case .notBetween:
			return column + " NOT BETWEEN ? AND ?"
		}
	}
	
	public var description: String {
		let column = T.key(for: keyPath).stringValue
		
		switch method {
		case .lessThan:
			return column + " IS LESS THAN \(values[0].description)"
		case .greaterThan:
			return column + " IS GREATER THAN \(values[0].description)"
		case .between:
			return column + " IS BETWEEN \(values[0].description) AND \(values[1].description)"
		case .notBetween:
			return column + " IS NOT BETWEEN \(values[0].description) AND \(values[1].description)"
		}
	}
}

extension Where: CustomStringConvertible {
	
	var query: String {
		switch self {
		case .comparison(let comparison):
			return comparison.query
		case .equality(let equality):
			return equality.query
		case .stringEquality(let se):
			return se.query
		case let .compound(a, conjunction, b):
			switch conjunction {
			case .and:
				return "\(a.query) AND \(b.query)"
			case .or:
				return "\(a.query) OR \(b.query)"
			}
		case let .grouped(a, conjunction, b):
			switch conjunction {
			case .and:
				return "(\(a.query)) AND (\(b.query))"
			case .or:
				return "(\(a.query)) OR (\(b.query))"
			}
		}
	}
	
	var bindingValues: [SQLValue] {
		switch self {
		case .comparison(let comparison):
			return comparison.values
		case .equality(let equality):
			return equality.values
		case .stringEquality(let se):
			return se.bindingValues
		case let .compound(a, _, b):
			return a.bindingValues + b.bindingValues
		case let .grouped(a, _, b):
			return a.bindingValues + b.bindingValues
		}
	}
	
	public var description: String {
		switch self {
		case .comparison(let comparison):
			return comparison.description
		case .equality(let equality):
			return equality.description
		case .stringEquality(let se):
			return se.description
		case let .compound(a, conjunction, b):
			switch conjunction {
			case .and:
				return "\(a.description) AND \(b.description)"
			case .or:
				return "\(a.description) OR \(b.description)"
			}
		case let .grouped(a, conjunction, b):
			switch conjunction {
			case .and:
				return "(\(a.description)) AND (\(b.description))"
			case .or:
				let result = "(\(a.description)) OR (\(b.description))"
				return result
			}
		}
	}
}

extension SortRule.Sort {
	
	var query: String {
		let column = Element.key(for: path).stringValue.sqlFormatted()
		
		switch direction {
		case .ascending:
			return column + " ASC"
		case .descending:
			return column + " DESC"
		}
	}
}

extension SortRule: CustomStringConvertible {
	
	var query: String {
		return "ORDER BY " + sorts.map { $0.query }.joined(separator: ", ")
	}
	
	var bindingValues: [SQLValue] {
		return []
	}
	
	public var description: String {
		return query
	}
}

extension Limit: CustomStringConvertible {
	
	var query: String {
		// pages start at 0, negative values are a no-no
		let offset = max(0, page) * count

		let limitString = "LIMIT ?"

		if offset > 0 {
			return limitString + " OFFSET ?"
		}

		return limitString
	}
	
	var bindingValues: [SQLValue] {
		let offset = max(0, page) * count
		
		if offset > 0 {
			return [.integer(Int64(count)), .integer(Int64(page))]
		}
		
		return [.integer(Int64(count))]
	}
	
	public var description: String {
		// pages start at 0, negative values are a no-no
		let offset = max(0, page) * count

		let limitString = "LIMIT \(count)"

		if offset > 0 {
			return limitString + " OFFSET \(offset)"
		}

		return limitString
	}
}


extension Filter {
	var query: String {
		return [
			FilterReader.clause(from: self).map {
				"WHERE " + $0.query
			},
			FilterReader.sorting(from: self)?.query,
			FilterReader.limit(from: self)?.query,
		]
		.compactMap { $0 }
		.filter { !$0.isEmpty }
		.joined(separator: " ")
	}
	
	var bindings: [SQLValue] {
		return (FilterReader.clause(from: self)?.bindingValues ?? [])
			+ (FilterReader.sorting(from: self)?.bindingValues ?? [])
			+ (FilterReader.limit(from: self)?.bindingValues ?? [])
	}
	
	var updateQuery: (String, [SQLValue]) {
		let clause = FilterReader.clause(from: self).map {
			("WHERE " + $0.query, $0.bindingValues)
		} ?? ("", [])
		
		// TODO: find a way to display "helpful tips" to consumers
		// for example, if we're in DEBUG and they used a Sort without
		// a Limit, pop up some kind of alert to let them know that
		// behaves weird
		
		guard let limit = FilterReader.limit(from: self) else {
			// SQLite gets mad if you use a Sort without a Limit
			// for partial updates, so no need to check for a Sort
			// if we don't have a Limit.
			// Or maybe we should default to Int.max if there's no Limit
			// so consumers get the behavior they would expect?
			return clause
		}
		
		guard let sort = FilterReader.sorting(from: self) else {
			
			return (clause.0 + " " + limit.query,
					clause.1 + limit.bindingValues)
		}
		
		let query = [
			clause.0,
			sort.query,
			limit.query,
		]
		.joined(separator: " ")
		
		let bindings = clause.1 + sort.bindingValues + limit.bindingValues
		
		return (query, bindings)
	}
}

extension Filter: CustomStringConvertible {
	
	public var description: String {
		return [
			"Filter<\(Element.self)>:",
			FilterReader.clause(from: self).map {
				"WHERE " + $0.description
			},
			FilterReader.sorting(from: self)?.description,
			FilterReader.limit(from: self)?.description,
		]
		.compactMap { $0 }
		.filter { !$0.isEmpty }
		.joined(separator: " ")
	}
}
