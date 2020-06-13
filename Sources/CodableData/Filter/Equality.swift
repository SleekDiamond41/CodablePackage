//
//  Equality.swift
//  SQL
//
//  Created by Michael Arrington on 4/3/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


public struct Equality<T>: Rule where T: Equatable & Bindable {
	
	internal let query: (String, [SQLValue])
	
	internal init(_ query: (String, [SQLValue])) {
		self.query = query
	}
}

extension Equality {
	
	public static func equal(to value: String) -> Equality {
		return Equality(("LIKE ?", [value.bindingValue]))
	}
	
	public static func notEqual(to value: String) -> Equality {
		return Equality(("NOT LIKE ?", [value.bindingValue]))
	}
	
	public static func equal(to value: T) -> Equality {
		return Equality(("IS ?", [value.bindingValue]))
	}
	
	public static func notEqual(to value: T) -> Equality {
		return Equality(("IS NOT ?", [value.bindingValue]))
	}
	
	public static func `in`(_ values: [T]) -> Equality {
		let q = [
			"IN (",
			Array(repeating: "?", count: values.count).joined(separator: ", "),
			")",
		].joined()
		
		return Equality((q, values.map { $0.bindingValue }))
	}
	
	public static func notIn(_ values: [T]) -> Equality {
		let q = [
			"NOT IN (",
			Array(repeating: "?", count: values.count).joined(separator: ", "),
			")",
		].joined()
		
		return Equality((q, values.map { $0.bindingValue }))
	}
}


extension Filter {
	
	public init<T>(_ path: KeyPath<Element, T>, is rule: Equality<T>) where T: Equatable & Bindable {
		self.init(path: path, rule: rule)
	}
	
	public func and<T>(_ path: KeyPath<Element, T>, is rule: Equality<T>) -> Filter where T: Equatable & Bindable {
        return and(path: path, rule: rule)
	}
	
	public func or<T>(_ path: KeyPath<Element, T>, is rule: Equality<T>) -> Filter where T: Equatable & Bindable {
        return or(path: path, rule: rule)
	}
}
