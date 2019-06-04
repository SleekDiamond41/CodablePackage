//
//  Status.swift
//  SQL
//
//  Created by Michael Arrington on 3/30/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import SQLite3

	
enum Status {
	case ok
	case done
	case row
	case error
	case `internal`
	case perm
	case abort
	case busy
	case locked
	case noMem
	case readOnly
	case interrupt
	case ioErr
	case corrupt
	case notFound
	case full
	case cantOpen
	case `protocol`
	case empty
	case schema
	case tooBig
	case constraint
	case mismatch
	case misuse
	case noLFS
	case auth
	case format
	case range
	case notADatabase
	case notice
	case warning
}


extension Status {
	
	init(_ rawValue: Int32) {
		switch rawValue {
		case SQLITE_OK: self = .ok
		case SQLITE_DONE: self = .done
		case SQLITE_ROW: self = .row
		case SQLITE_ERROR: self = .error
		case SQLITE_INTERNAL: self = .internal
		case SQLITE_PERM: self = .perm
		case SQLITE_ABORT: self = .abort
		case SQLITE_BUSY: self = .busy
		case SQLITE_LOCKED: self = .locked
		case SQLITE_NOMEM: self = .noMem
		case SQLITE_READONLY: self = .readOnly
		case SQLITE_INTERRUPT: self = .interrupt
		case SQLITE_IOERR: self = .ioErr
		case SQLITE_CORRUPT: self = .corrupt
		case SQLITE_NOTFOUND: self = .notFound
		case SQLITE_FULL: self = .full
		case SQLITE_CANTOPEN: self = .cantOpen
		case SQLITE_PROTOCOL: self = .protocol
		case SQLITE_EMPTY: self = .empty
		case SQLITE_SCHEMA: self = .schema
		case SQLITE_TOOBIG: self = .tooBig
		case SQLITE_CONSTRAINT: self = .constraint
		case SQLITE_MISMATCH: self = .mismatch
		case SQLITE_MISUSE: self = .misuse
		case SQLITE_NOLFS: self = .noLFS
		case SQLITE_AUTH: self = .auth
		case SQLITE_FORMAT: self = .format
		case SQLITE_RANGE: self = .range
		case SQLITE_NOTADB: self = .notADatabase
		case SQLITE_NOTICE: self = .notice
		case SQLITE_WARNING: self = .warning
		default:
			fatalError("Unknown status '\(rawValue)'")
		}
	}
	
	var rawValue: Int32 {
		switch self {
		case .ok: return SQLITE_OK
		case .done: return SQLITE_DONE
		case .row: return SQLITE_ROW
		case .error: return SQLITE_ERROR
		case .internal: return SQLITE_INTERNAL
		case .perm: return SQLITE_PERM
		case .abort: return SQLITE_ABORT
		case .busy: return SQLITE_BUSY
		case .locked: return SQLITE_LOCKED
		case .noMem: return SQLITE_NOMEM
		case .readOnly: return SQLITE_READONLY
		case .interrupt: return SQLITE_INTERRUPT
		case .ioErr: return SQLITE_IOERR
		case .corrupt: return SQLITE_CORRUPT
		case .notFound: return SQLITE_NOTFOUND
		case .full: return SQLITE_FULL
		case .cantOpen: return SQLITE_CANTOPEN
		case .protocol: return SQLITE_PROTOCOL
		case .empty: return SQLITE_EMPTY
		case .schema: return SQLITE_SCHEMA
		case .tooBig: return SQLITE_TOOBIG
		case .constraint: return SQLITE_CONSTRAINT
		case .mismatch: return SQLITE_MISMATCH
		case .misuse: return SQLITE_MISUSE
		case .noLFS: return SQLITE_NOLFS
		case .auth: return SQLITE_AUTH
		case .format: return SQLITE_FORMAT
		case .range: return SQLITE_RANGE
		case .notADatabase: return SQLITE_NOTADB
		case .notice: return SQLITE_NOTICE
		case .warning: return SQLITE_WARNING
		}
	}
}
