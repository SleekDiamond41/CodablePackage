//
//  Database.swift
//  SQL
//
//  Created by Michael Arrington on 3/30/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation

enum DatabaseError: Error {
    case internalInconsistency
}

/// A type-safe wrapper around the SQLite3 database framework.
///
/// - Note: A `Database` is not thread-safe, and its methods should only be called from a single thread. It is advised that consumers of this framework create a wrapper around a `Database` instance rather than consuming it directly. The wrapper should guarantee that the `Database` methods are accessed on a single thread. Note that this does not mean one thread at a time, it means one thread ever, as long as the `Database` instance exists. Failure to do so could cause unexpected behavior.
public class Database {

	let connection: Connection
	
	public var dir: URL {
		connection.config.directory
	}
	
	public var filename: String {
		connection.config.filename
	}


    /// /// Opens a connection to  a new database at the given directory, with the given filename.
    ///
    /// If a database does not exist at the given location a new database will be created.
    ///
    /// - Parameters:
    ///   - dir: the full URL to a directory. Default is /ApplicationSupport/CodableData/
    ///   - filename: the name of the database file. Default is "Data"
    /// - Throws: Potentially any ConnectionError
    public convenience init(
        dir: URL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask).first!.appendingPathComponent("CodableData"),
        filename: String = "Data") throws {

        let config = Configuration(directory: dir, filename: filename, isReadOnly: false)
		
		try self.init(connection: Connection(config))
	}
	
	internal init(connection: Connection) throws {
		self.connection = connection
		try self.connection.connect()
	}

    @discardableResult
	func execute(_ query: String) -> Status {

		do {
            var s = Statement(query)
            try s.prepare(in: connection.db)
            defer {
                s.finalize()
            }
            return s.step()
        } catch {
            fatalError(String(reflecting: error))
        }
	}

    public func deleteTheWholeDangDatabase() throws {
        try connection.deleteEverything()
        try connection.connect()
    }
	
	/// Multi-threading with SQLite can be tricky. Save yourself a headache and get
	/// a unique connection for reading asynchronously from the database
	public func getReadOnly() throws -> ReadOnlyConnection {
		let config = Configuration(
			directory: connection.config.directory,
			filename: connection.config.filename,
			isReadOnly: true)
		
		let db = try Database(connection: Connection(config))
		return ReadOnlyConnection(db: db)
	}
	
	func deleteWithoutReconnecting() throws {
		try connection.deleteEverything()
	}
}
