//
//  BetterCDFilterable.swift
//  SQL
//
//  Created by Michael Arrington on 4/2/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


public protocol Filterable {
	associatedtype FilterKey: CodingKey
	
	static func key<T: Bindable>(for path: KeyPath<Self, T>) -> FilterKey
}
