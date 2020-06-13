//
//  StringComparison.swift
//  SQL
//
//  Created by Michael Arrington on 4/3/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


public struct StringEquality: Rule {
	
	let query: (String, [SQLValue])
	
	internal init(_ query: (String, [SQLValue])) {
		self.query = query
	}
	
	public static func like(_ value: String) -> StringEquality {
		return StringEquality(("LIKE ?", [value.bindingValue]))
	}
	
	public static func glob(_ value: String) -> StringEquality {
		return StringEquality(("GLOB ?", [value.bindingValue]))
	}
	
	public static func regex(_ value: String) -> StringEquality {
		// FIXME: add unit tests for REGEXP
		return StringEquality(("REGEXP ?", [value.bindingValue]))
	}
	
	public static func matches(_ value: String) -> StringEquality {
		return StringEquality(("MATCH ?", [value.bindingValue]))
	}
}


extension Filter {
	
	public init(_ path: KeyPath<Element, String>, is rule: StringEquality) {
		self.init(path: path, rule: rule)
	}
	
	public func and(_ path: KeyPath<Element, String>, is rule: StringEquality) -> Filter {
        return and(path: path, rule: rule)
	}
	
	public func or(_ path: KeyPath<Element, String>, is rule: StringEquality) -> Filter {
        return or(path: path, rule: rule)
	}
}
