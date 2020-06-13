//
//  Limit.swift
//  SQL
//
//  Created by Michael Arrington on 4/3/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


struct Limit: Codable, Equatable {
	var query: (String, [SQLValue]) {
        // pages start at 0, negative values are a no-no
        let offset = max(0, page) * limit

        let limitString = "LIMIT ?"

        if offset > 0 {
			return (limitString + " OFFSET ?", [limit.bindingValue, page.bindingValue])
        }

		return (limitString, [limit.bindingValue])
	}
	
	let limit: UInt32
	let page: UInt32
	
	init(_ limit: UInt32, _ page: UInt32) {
		self.limit = limit
		self.page = page
	}
}
