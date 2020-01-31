//
//  StringComparison.swift
//  SQL
//
//  Created by Michael Arrington on 4/3/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


public enum StringEquality: Rule {
	case like(String)
	case glob(String)
	case regex(String)
	case matches(String)
	
	var query: (String, [String]) {
		switch self {
		case .like(let val):
			return ("LIKE ?", [val])
		case .glob(let val):
			return ("GLOB ?", [val])
		case .regex(let val):
			return ("REGEXP ?", [val])
		case .matches(let val):
			return ("MATCH ?", [val])
		}
	}
}


extension Filter {
	
	public init(_ path: KeyPath<Element, String>, _ rule: StringEquality) {
		self.init(path: path, rule: rule)
	}
	
	public func and(_ path: KeyPath<Element, String>, _ rule: StringEquality) -> Filter {
		return and(path: path, rule: rule)
	}
	
	public func or(_ path: KeyPath<Element, String>, _ rule: StringEquality) -> Filter {
		return or(path: path, rule: rule)
	}
	
}
