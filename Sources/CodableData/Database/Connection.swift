//
//  Connection.swift
//  SQL
//
//  Created by Michael Arrington on 3/30/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation
import SQLite3


enum ConnectionError: Error {
    case connectionUnexpectedlyNil
    case statusCode(expected: Status, actual: Status)
}

class Connection {
	
	let db: OpaquePointer
	
	
	deinit {
		let status = Status(sqlite3_close(db))
		guard status == .ok else {
			fatalError()
		}
	}
	
	
	private init(_ db: OpaquePointer) {
		self.db = db
	}

	convenience init(dir: URL, name: String) throws {

		let url = dir.appendingPathComponent(name).appendingPathExtension("sqlite3")//.removingPercentEncoding!
		print("Opening connection to SQL database to:", url.path)

		if !FileManager.default.fileExists(atPath: url.path) {
			print("Directory doesn't exist")
			do {
				print("Creating directory")
				try FileManager.default.createDirectory(atPath: dir.path, withIntermediateDirectories: true)
				print("Created directory")
			} catch let error as NSError {
				print(url.path)
				print(url.absoluteString)
				print(url)
				guard error.code == 516 else {
					fatalError(String(reflecting: error))
				}
			}
		} else {
			print("Directory exists")
		}

		var db: OpaquePointer!
		let status = Status(sqlite3_open(url.path, &db))

		guard db != nil else {
            throw ConnectionError.connectionUnexpectedlyNil
		}

		guard status == .ok else {
			print(Connection.error(db))
            throw ConnectionError.statusCode(expected: .ok, actual: status)
		}

		self.init(db)
	}
	
	convenience init(_ configuration: Database.Configuration) throws {
		try self.init(dir: configuration.directory, name: configuration.filename)
	}
	
	private static func error(_ db: OpaquePointer) -> String {
		return String(cString: sqlite3_errmsg(db))
	}
}
