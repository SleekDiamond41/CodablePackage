//
//  Database.swift
//  SQL
//
//  Created by Michael Arrington on 3/30/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


public class Database {
	
	public let configuration: Configuration
	
	let conns: (Connection, Connection)
	
	public init(_ configuration: Configuration = .default) {
		
		let a = Connection(configuration, queue: DispatchQueue(label: "com.CodableData.\(configuration.filename).Connection.Sync", qos: configuration.syncPriority))
		let b = Connection(configuration, queue: DispatchQueue(label: "com.CodableData.\(configuration.filename).Connection.Async", qos: configuration.asyncPriority))
		self.conns = (a, b)
		
		self.configuration = configuration
	}
	
	func sync<T>(_ block: (OpaquePointer) -> T) -> T {
		return conns.0.sync { (db) in
			return block(db)
		}
	}
	
	func async(_ block: @escaping (OpaquePointer) -> Void) {
		conns.1.async { (db) in
			block(db)
		}
	}
	
	static func _execute(db: OpaquePointer, _ query: String) {
		do {
			var s = Statement(query)
			try s.prepare(in: db)
			defer {
				s.finalize()
			}
			try s.step()
		} catch {
			fatalError(String(reflecting: error))
		}
	}
	
	func execute(_ query: String) {
		sync { db in
			Database._execute(db: db, query)
		}
	}
	
	func execute(_ query: String, _ handler: @escaping () -> Void) {
		async { db in
			Database._execute(db: db, query)
			handler()
		}
	}
	
}
