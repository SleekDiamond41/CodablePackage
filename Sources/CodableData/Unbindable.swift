//
//  Unbindable.swift
//  SQL
//
//  Created by Michael Arrington on 3/31/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation
import SQLite3

enum UnbindError: Error {
	case nilFound
}


protocol Unbindable {
	static func unbind(from s: Statement, at index: Int32!) throws -> Self
}

extension Optional: Unbindable where Wrapped: Unbindable {
	static func unbind(from s: Statement, at index: Int32!) throws -> Optional<Wrapped> {
		guard let index = index else {
			return .none
		}
		do {
			return .some(try Wrapped.unbind(from: s, at: index))
		} catch {
			print(String(reflecting: error))
			return .none
		}
	}
}

extension UUID: Unbindable {
	static func unbind(from s: Statement, at index: Int32!) throws -> UUID {
		let str = try String.unbind(from: s, at: index)
		let id = UUID(uuidString: str)
		return id!
	}
}

extension String: Unbindable {
	static func unbind(from s: Statement, at index: Int32!) throws -> String {
		guard let p = sqlite3_column_text(s.p, index) else {
			fatalError()
		}
		return String(cString: p)
	}
}

extension Int64: Unbindable {
	static func unbind(from s: Statement, at index: Int32!) throws -> Int64 {
		return sqlite3_column_int64(s.p, index)
	}
}

extension Int32: Unbindable {
	static func unbind(from s: Statement, at index: Int32!) throws -> Int32 {
		return sqlite3_column_int(s.p, index)
	}
}

extension Int16: Unbindable {
	static func unbind(from s: Statement, at index: Int32!) throws -> Int16 {
		return Int16(try Int32.unbind(from: s, at: index))
	}
}

extension Int8: Unbindable {
	static func unbind(from s: Statement, at index: Int32!) throws -> Int8 {
		return Int8(try Int32.unbind(from: s, at: index))
	}
}

extension Int: Unbindable {
	static func unbind(from s: Statement, at index: Int32!) throws -> Int {
		return Int(try Int64.unbind(from: s, at: index))
	}
}

extension UInt64: Unbindable {
	static func unbind(from s: Statement, at index: Int32!) throws -> UInt64 {
		let int64 = try Int64.unbind(from: s, at: index)
		return UInt64(int64 + Int64.max)
	}
}

extension UInt32: Unbindable {
	static func unbind(from s: Statement, at index: Int32!) throws -> UInt32 {
		return UInt32(try UInt64.unbind(from: s, at: index))
	}
}

extension UInt16: Unbindable {
	static func unbind(from s: Statement, at index: Int32!) throws -> UInt16 {
		return UInt16(try UInt64.unbind(from: s, at: index))
	}
}

extension UInt8: Unbindable {
	static func unbind(from s: Statement, at index: Int32!) throws -> UInt8 {
		return UInt8(try UInt64.unbind(from: s, at: index))
	}
}

extension UInt: Unbindable {
	static func unbind(from s: Statement, at index: Int32!) throws -> UInt {
		return UInt(try UInt64.unbind(from: s, at: index))
	}
}

extension Double: Unbindable {
	static func unbind(from s: Statement, at index: Int32!) throws -> Double {
		return sqlite3_column_double(s.p, index)
	}
}

extension Float: Unbindable {
	static func unbind(from s: Statement, at index: Int32!) throws -> Float {
		return Float(try Double.unbind(from: s, at: index))
	}
}

extension Data: Unbindable {
	static func unbind(from s: Statement, at index: Int32!) throws -> Data {
		guard let raw = sqlite3_column_blob(s.p, index) else {
			fatalError()
		}
		let len = sqlite3_column_bytes(s.p, index)
		return Data(bytes: raw, count: Int(len))
	}
}

extension Date: Unbindable {
	static func unbind(from s: Statement, at index: Int32!) throws -> Date {
		return Date(timeIntervalSince1970: try Double.unbind(from: s, at: index))
	}
}

extension Bool: Unbindable {
	static func unbind(from s: Statement, at index: Int32!) throws -> Bool {
		return try Int32.unbind(from: s, at: index) > 0
	}
}
