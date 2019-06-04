//
//  Connection.swift
//  SQL
//
//  Created by Michael Arrington on 3/30/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation
import SQLite3


class Connection {
	
	private let db: OpaquePointer
	private let queue: DispatchQueue
	
	
	deinit {
		let status = Status(sqlite3_close(db))
		guard status == .ok else {
			fatalError()
		}
	}
	
	
	private init(_ db: OpaquePointer, queue: DispatchQueue) {
		self.db = db
		self.queue = queue
	}
	
	convenience init(dir: URL, name: String, queue: DispatchQueue) {
		
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
			fatalError()
		}
		guard status == .ok else {
			print(Connection.error(db))
			fatalError()
		}
		self.init(db, queue: queue)
	}
	
	convenience init(_ configuration: CDDatabase.Configuration, queue: DispatchQueue) {
		self.init(dir: configuration.directory, name: configuration.filename, queue: queue)
	}
	
	private static func error(_ db: OpaquePointer) -> String {
		return String(cString: sqlite3_errmsg(db))
	}
	
	func sync<T>(_ block: (OpaquePointer) -> T) -> T {
		return queue.sync {
			return block(db)
		}
	}
	
	func async(_ block: @escaping (OpaquePointer) -> Void) {
		queue.async {
			block(self.db)
		}
	}
	
}
