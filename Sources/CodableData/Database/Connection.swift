//
//  Connection.swift
//  SQL
//
//  Created by Michael Arrington on 3/30/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation
import SQLite3
//import Logging
import os

enum ConnectionError: Error {
    case connectionUnexpectedlyNil
    case statusCode(expected: Status, actual: Status)
    case disconnectFailure
}

class Connection {


    // MARK: Private Properties

//	private let log: Logger
	let id = UUID()
    let config: Configuration
    private let fileManager = FileManager()
	
	private(set) var isConnected = false


    // MARK: Public Properties

	private var _db: OpaquePointer?
	var db: OpaquePointer! {
		if !isConnected {
			do {
				try connect()
			} catch {
				preconditionFailure()
			}
		}
		return _db
	}


    // MARK: Initializers

    init(_ configuration: Configuration) {

        self.config = configuration
//		self.log = Logger(subsystem: "com.the-duct-ape.CodableData", category: "Connection")
    }


	deinit {
        do {
            try disconnect()
        } catch {
            preconditionFailure(String(reflecting: error))
        }
	}


    // MARK: Internal Methods

    func connect() throws {
        assert(_db == nil)

        if !directoryExists() {
            try createDirectory()
        }

        try _connect()
    }

    func deleteEverything() throws {
		print("\nDeleting everyting! \(config.filename)\n")
		if isConnected {
			try disconnect()
		}
		
        try deleteFile()
    }


    // MARK: Helper Methods

    private func directoryExists() -> Bool {
        var isDirectory = ObjCBool(false)
        return fileManager.fileExists(atPath: config.url.absoluteString, isDirectory: &isDirectory)
            && isDirectory.boolValue
    }

    private func createDirectory() throws {

        try fileManager.createDirectory(atPath: config.directory.path, withIntermediateDirectories: true)
    }

    private func _connect() throws {
		
		print("\(id.uuidString) - Connecting to database at '\(config.url.absoluteString)'")
		
		var flags = SQLITE_OPEN_SHAREDCACHE
		if config.isReadOnly {
			flags |= SQLITE_OPEN_READONLY
		} else {
			flags |= SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE
		}

        var db: OpaquePointer!
        let status = Status(sqlite3_open_v2(config.url.path, &db, flags, nil))

        guard db != nil else {
            throw ConnectionError.connectionUnexpectedlyNil
        }

        guard status == .ok else {
			debugPrint(String(cString: sqlite3_errmsg(db)))
            throw ConnectionError.statusCode(expected: .ok, actual: status)
        }
		
		// setup connection
		var journalModeError: UnsafeMutablePointer<Int8>?
		let journalStatus = Status(sqlite3_exec(db, "PRAGMA journal_mode=WAL;", nil, nil, &journalModeError))

		guard journalStatus == .ok else {
			debugPrint(String(cString: sqlite3_errmsg(db)))
			throw ConnectionError.statusCode(expected: .ok, actual: journalStatus)
		}
		assert(journalModeError == nil)
		
		var readUncommittedError: UnsafeMutablePointer<Int8>?
		let readUncommittedStatus = Status(sqlite3_exec(db, "PRAGMA read_uncommitted=1;", nil, nil, &readUncommittedError))
		
		guard readUncommittedStatus == .ok else {
			debugPrint(String(cString: sqlite3_errmsg(db)))
			throw ConnectionError.statusCode(expected: .ok, actual: readUncommittedStatus)
		}
		assert(readUncommittedError == nil)
		
        self._db = db
		self.isConnected = true
    }

    private func disconnect() throws {
//		log.critical(<#T##message: Logger.Message##Logger.Message#>, metadata: <#T##Logger.Metadata?#>, source: <#T##String?#>)

        guard _db != nil else {
            return
        }
		
		print("\(id.uuidString) - Disconnecting from database at '\(config.url.absoluteString)'")

        defer {
            _db = nil
			isConnected = false
        }

        let status = Status(sqlite3_close(_db))

        guard status == .ok else {
            throw ConnectionError.disconnectFailure
        }
    }

    private func deleteFile() throws {

		do {
			try fileManager.removeItem(at: config.url)
		} catch let error as NSError {
			if error.code == NSFileNoSuchFileError {
				// the file is already gone, our job is done
				// without having to do it ourselves.
				// No reason to throw an error.
				return
			}
			
			throw error
		}
    }
}
