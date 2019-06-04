//
//  Equality.swift
//  SQL
//
//  Created by Michael Arrington on 4/3/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


public enum CDEquality<T>: Rule where T: Equatable & CDBindable {
	case equal(to: T)
	case notEqual(to: T)
	
	var query: (String, [T]) {
		switch self {
		case .equal(to: let value):
			if let oper = value as? EqualityOperand {
				return (oper.equalQuery, oper.shouldBind ? [value] : [])
			} else {
				return ("IS ?", [value])
			}
		case .notEqual(to: let value):
			if let oper = value as? EqualityOperand {
				return (oper.equalQuery, oper.shouldBind ? [value] : [])
			} else {
				return ("IS NOT ?", [value])
			}
		}
	}
}


extension CDFilter {
	
	public init<T>(_ path: KeyPath<Element, T>, is rule: CDEquality<T>) where T: Equatable & CDBindable {
		self.init(path: path, rule: rule)
	}
	
	public func and<T>(_ path: KeyPath<Element, T>, is rule: CDEquality<T>) -> CDFilter where T: Equatable & CDBindable {
		return and(path: path, rule: rule)
	}
	
	public func or<T>(_ path: KeyPath<Element, T>, is rule: CDEquality<T>) -> CDFilter where T: Equatable & CDBindable {
		return or(path: path, rule: rule)
	}
	
}


fileprivate protocol EqualityOperand {
	var shouldBind: Bool { get }
	var equalQuery: String { get }
	var notEqualQuery: String { get }
}

extension String: EqualityOperand {
	fileprivate var shouldBind: Bool {
		return true
	}
	fileprivate var equalQuery: String {
		return "LIKE"
	}
	fileprivate var notEqualQuery: String {
		return "NOT LIKE"
	}
}

extension Optional: EqualityOperand {
	fileprivate var shouldBind: Bool {
		switch self {
		case .none:
			return false
		case .some:
			return true
		}
	}
	fileprivate var equalQuery: String {
		switch self {
		case .none:
			return "IS NULL"
		case .some(let val):
			if let v = val as? EqualityOperand {
				return v.equalQuery
			} else {
				return "IS ?"
			}
		}
	}
	fileprivate var notEqualQuery: String {
		switch self {
		case .none:
			return "IS NOT NULL"
		case .some(let val):
			if let v = val as? EqualityOperand {
				return v.equalQuery
			} else {
				return "IS NOT ?"
			}
		}
	}
}
