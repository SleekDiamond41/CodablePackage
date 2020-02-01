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
    case disconnectFailure
}

class Connection {


    // MARK: Private Properties

    private let config: Database.Configuration
    private let fileManager = FileManager()


    // MARK: Public Properties

    private(set) var db: OpaquePointer!


    // MARK: Initializers

    init(_ configuration: Database.Configuration) {

        self.config = configuration
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

        if !fileExists() {
            createFile()
        }

        try _connect()
    }

    func deleteEverything() throws {

        try disconnect()
        try deleteFile()
    }


    // MARK: Helper Methods

    private func fileExists() -> Bool {

        return fileManager.fileExists(atPath: config.url.absoluteString)
    }

    private func createFile() {

        fileManager.createFile(atPath: config.url.absoluteString,
                               contents: nil,
                               attributes: nil)
    }

    private func _connect() throws {

        var db: OpaquePointer!
        let status = Status(sqlite3_open(config.url.absoluteString, &db))

        guard db != nil else {
            throw ConnectionError.connectionUnexpectedlyNil
        }

        guard status == .ok else {
            throw ConnectionError.statusCode(expected: .ok, actual: status)
        }

        self.db = db
    }

    private func disconnect() throws {

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
