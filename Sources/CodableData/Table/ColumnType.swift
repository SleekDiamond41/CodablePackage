//
//  ColumnType.swift
//  CodablePackage
//
//  Created by Michael Arrington on 3/30/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation
import SwiftFilter
import SQLite3


enum ColumnType: String {
	case text = "TEXT"
	case integer = "INTEGER"
	case double = "FLOAT"
	case blob = ""
}

extension ColumnType {
	
	init?(_ value: Int32) {
		switch value {
		case SQLITE3_TEXT, SQLITE_TEXT:
			self = .text
		case SQLITE_INTEGER:
			self = .integer
		case SQLITE_FLOAT:
			self = .double
		case SQLITE_BLOB:
			self = .blob
		default:
			return nil
		}
	}
}


extension ColumnType: Unbindable {
	
	static func unbind(_ proxy: UnbindingProxy) throws -> ColumnType {
		let type = try proxy.get() as String

		if type.contains("TEXT") {
			return .text
		} else if type.contains("INTEGER") {
			return .integer
		} else if type.contains("FLOAT") {
			return .double
		} else {
			return .blob
		}
	}
}
