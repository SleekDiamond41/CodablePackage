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
    private let config: Configuration
    private let fileManager = FileManager()


    // MARK: Public Properties

    private(set) var db: OpaquePointer!


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
        assert(db == nil)

        if !directoryExists() {
            try createDirectory()
        }

        try _connect()
    }

    func deleteEverything() throws {

        try disconnect()
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

        var db: OpaquePointer!
        let status = Status(sqlite3_open(config.url.path, &db))

        guard db != nil else {
            throw ConnectionError.connectionUnexpectedlyNil
        }

        guard status == .ok else {
            throw ConnectionError.statusCode(expected: .ok, actual: status)
        }

        self.db = db
    }

    private func disconnect() throws {
//		log.critical(<#T##message: Logger.Message##Logger.Message#>, metadata: <#T##Logger.Metadata?#>, source: <#T##String?#>)

        guard db != nil else {
            return
        }

        defer {
            db = nil
        }

        let status = Status(sqlite3_close(db))

        guard status == .ok else {
            throw ConnectionError.disconnectFailure
        }
    }

    private func deleteFile() throws {

        try fileManager.removeItem(at: config.url)
    }
}
