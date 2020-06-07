//
//  Transaction.swift
//  
//
//  Created by Michael Arrington on 6/6/20.
//

import Foundation

public class Transaction {
	private var queries = [String]()
	private var bindings = [SQLValue]()
	
	public func save<C>(_ models: C) where C: Collection, C.Element: Model & Filterable {
		
	}
}
