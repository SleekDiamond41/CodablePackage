//
//  Limit.swift
//  SQL
//
//  Created by Michael Arrington on 4/3/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


struct Limit {
	var query: String {
        // pages start at 1
		return "LIMIT \(limit) OFFSET \(limit * (max(1, page-1)))"
	}
	
	let limit: Int
	let page: Int
	
	init(_ limit: Int, _ page: Int = 1) {
		self.limit = limit
		self.page = page
	}
}
