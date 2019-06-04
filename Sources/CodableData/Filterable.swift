//
//  BetterCDFilterable.swift
//  SQL
//
//  Created by Michael Arrington on 4/2/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


public protocol CDFilterable {
	associatedtype FilterKey: CodingKey
	
	static func key<T: CDBindable>(for path: KeyPath<Self, T>) -> FilterKey
}

extension Person {
	public typealias FilterKey = Person.CodingKeys
	
	public static func key<T: CDBindable>(for path: KeyPath<Person, T>) -> Person.CodingKeys {
		switch path {
		case \Person.id: return .id
		case \Person.name: return .name
		default:
			fatalError("Unknown KeyPath")
		}
	}
	
}
