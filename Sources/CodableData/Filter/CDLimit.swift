//
//  Limit.swift
//  SQL
//
//  Created by Michael Arrington on 4/3/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


public struct CDLimit {
	var query: String {
		return "LIMIT \(limit) OFFSET \(limit * (page-1))"
	}
	
	public let limit: Int
	public let page: Int
	
	public init(_ limit: Int, _ page: Int = 1) {
		self.limit = limit
		self.page = page
	}
}
