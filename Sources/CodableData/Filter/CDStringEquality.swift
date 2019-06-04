//
//  StringComparison.swift
//  SQL
//
//  Created by Michael Arrington on 4/3/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


public enum CDStringEquality: Rule {
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


extension CDFilter {
	
	public init(_ path: KeyPath<Element, String>, _ rule: CDStringEquality) {
		self.init(path: path, rule: rule)
	}
	
	public func and(_ path: KeyPath<Element, String>, _ rule: CDStringEquality) -> CDFilter {
		return and(path: path, rule: rule)
	}
	
	public func or(_ path: KeyPath<Element, String>, _ rule: CDStringEquality) -> CDFilter {
		return or(path: path, rule: rule)
	}
	
}
