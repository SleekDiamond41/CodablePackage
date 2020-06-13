//
//  Comparison.swift
//  SQL
//
//  Created by Michael Arrington on 4/3/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


public struct Comparison<T>: Rule where T: Bindable & Comparable {
	
	internal let query: (String, [SQLValue])
	
	internal init(_ query: (String, [SQLValue])) {
		self.query = query
	}
	
	public static func greater(than other: T) -> Comparison {
		return Comparison(("> ?", [other.bindingValue]))
	}
	
	public static func less(than other: T) -> Comparison {
		return Comparison(("< ?", [other.bindingValue]))
	}
	
	public static func between(_ a: T, and b: T) -> Comparison {
		return Comparison(("BETWEEN ? AND ?", [a.bindingValue, b.bindingValue]))
	}
	
	public static func notBetween(_ a: T, and b: T) -> Comparison {
		return Comparison(("NOT BETWEEN ? AND ?", [a.bindingValue, b.bindingValue]))
	}
}


extension Filter {
	
	public init<T>(_ path: KeyPath<Element, T>, is rule: Comparison<T>) where T: Bindable & Comparable {
		self.init(path: path, rule: rule)
	}
	
	public func and<T>(_ path: KeyPath<Element, T>, is rule: Comparison<T>) -> Filter where T: Bindable & Comparable {
        return and(path: path, rule: rule)
	}
	
	public func or<T>(_ path: KeyPath<Element, T>, is rule: Comparison<T>) -> Filter where T: Bindable & Comparable {
		return or(path: path, rule: rule)
	}
}
