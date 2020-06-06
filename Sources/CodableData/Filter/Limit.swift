//
//  Limit.swift
//  SQL
//
//  Created by Michael Arrington on 4/3/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


struct Limit: Codable, Equatable {
	var query: String {
        // pages start at 0, negative values are a no-no
        let offset = max(0, page) * limit

        let limitString = "LIMIT \(limit)"

        if offset > 0 {
            return limitString + " OFFSET \(offset)"
        }

        return limitString
	}
	
	let limit: UInt
	let page: UInt
	
	init(_ limit: UInt, _ page: UInt) {
		self.limit = limit
		self.page = page
	}
}
