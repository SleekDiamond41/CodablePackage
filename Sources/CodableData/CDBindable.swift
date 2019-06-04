//
//  Bindable.swift
//  SQL
//
//  Created by Michael Arrington on 3/30/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation
import SQLite3


/// A value that can be bound into a SQLite statement
public enum CDValue {
	case text(String)
	case integer(Int64)
	case double(Double)
	case blob(Data)
	case null
	
	func bind(into s: Statement, at index: Int32) throws {
		switch self {
		case .text(let str):
			let status = Status(sqlite3_bind_text(s.p, index, NSString(string: str).utf8String, -1, nil))
			guard status == .ok else {
				fatalError(String(reflecting: status))
			}
		case .integer(let num):
			let status = Status(sqlite3_bind_int64(s.p, index, num))
			guard status == .ok else {
				fatalError(String(reflecting: status))
			}
		case .double(let num):
			let status = Status(sqlite3_bind_double(s.p, index, num))
			guard status == .ok else {
				fatalError(String(reflecting: status))
			}
		case .blob(let d):
			let data = d as NSData
			
			let status = Status(sqlite3_bind_blob(s.p, index, data.bytes, Int32(data.length), nil))
			guard status == .ok else {
				fatalError(String(reflecting: s))
			}
		case .null:
			let status = Status(sqlite3_bind_null(s.p, index))
			guard status == .ok else {
				fatalError(String(reflecting: status))
			}
		}
	}
}


/// A value that can be bound to a SQLite statement.
public protocol CDBindable: Encodable {
	
	/// The value to be bound into the SQLite statement.
	var bindingValue: CDValue { get }
}

extension Optional: CDBindable where Wrapped: CDBindable {
	public var bindingValue: CDValue {
		switch self {
		case .none:
			return .null
		case .some(let val):
			return val.bindingValue
		}
	}
}

extension UUID: CDBindable {
	public var bindingValue: CDValue {
		return uuidString.bindingValue
	}
}

extension String: CDBindable {
	public var bindingValue: CDValue {
		return .text(self)
	}
}

extension Int64: CDBindable {
	public var bindingValue: CDValue {
		return .integer(self)
	}
}

extension Int: CDBindable {
	public var bindingValue: CDValue {
		return Int64(self).bindingValue
	}
}

extension Int32: CDBindable {
	public var bindingValue: CDValue {
		return Int64(self).bindingValue
	}
}

extension Int16: CDBindable {
	public var bindingValue: CDValue {
		return Int64(self).bindingValue
	}
}

extension Int8: CDBindable {
	public var bindingValue: CDValue {
		return Int64(self).bindingValue
	}
}

extension UInt64: CDBindable {
	public var bindingValue: CDValue {
		return .integer(Int64(self - UInt64(Int64.max)))
	}
}

extension UInt: CDBindable {
	public var bindingValue: CDValue {
		return Int64(self).bindingValue
	}
}

extension UInt32: CDBindable {
	public var bindingValue: CDValue {
		return Int64(self).bindingValue
	}
}

extension UInt16: CDBindable {
	public var bindingValue: CDValue {
		return Int64(self).bindingValue
	}
}

extension UInt8: CDBindable {
	public var bindingValue: CDValue {
		return Int64(self).bindingValue
	}
}

extension Double: CDBindable {
	public var bindingValue: CDValue {
		return .double(self)
	}
}

extension Float: CDBindable {
	public var bindingValue: CDValue {
		return Double(self).bindingValue
	}
}

extension Data: CDBindable {
	public var bindingValue: CDValue {
		return .blob(self)
	}
}

extension Date: CDBindable {
	public var bindingValue: CDValue {
		return .double(timeIntervalSince1970)
	}
}

extension Bool: CDBindable {
	public var bindingValue: CDValue {
		return .integer(self ? 1 : 0)
	}
}
