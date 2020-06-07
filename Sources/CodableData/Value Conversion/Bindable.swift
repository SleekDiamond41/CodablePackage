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
public enum SQLValue: Codable, Equatable {
	case text(String)
	case integer(Int64)
	case double(Double)
	case blob(Data)
	case null
	
	private enum CodingKeys: String, CodingKey {
		case type
		case value
		
		enum Types: String, Codable {
			case text
			case integer
			case double
			case blob
			case null
		}
	}
	
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let type = try container.decode(CodingKeys.Types.self, forKey: .type)
		
		switch type {
		case .text:
			self = .text(try container.decode(String.self, forKey: .value))
		case .integer:
			self = .integer(try container.decode(Int64.self, forKey: .value))
		case .double:
			self = .double(try container.decode(Double.self, forKey: .value))
		case .blob:
			self = .blob(try container.decode(Data.self, forKey: .value))
		case .null:
			// no value to decode here
			self = .null
		}
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		switch self {
		case .text(let value):
			try container.encode(CodingKeys.Types.text, forKey: .type)
			try container.encode(value, forKey: .value)
		case .integer(let value):
			try container.encode(CodingKeys.Types.integer, forKey: .type)
			try container.encode(value, forKey: .value)
		case .double(let value):
			try container.encode(CodingKeys.Types.double, forKey: .type)
			try container.encode(value, forKey: .value)
		case .blob(let value):
			try container.encode(CodingKeys.Types.blob, forKey: .type)
			try container.encode(value, forKey: .value)
		case .null:
			try container.encode(CodingKeys.Types.null, forKey: .type)
			// no value to encode here
		}
	}
}


/// A value that can be bound to a SQLite statement.
public protocol Bindable: Encodable {
	
	/// The value to be bound into the SQLite statement.
	var bindingValue: SQLValue { get }
}

extension Optional: Bindable where Wrapped: Bindable {
	public var bindingValue: SQLValue {
		switch self {
		case .none:
			return .null
		case .some(let val):
			return val.bindingValue
		}
	}
}

extension UUID: Bindable {
	public var bindingValue: SQLValue {
		return uuidString.bindingValue
	}
}

extension String: Bindable {
	public var bindingValue: SQLValue {
		return .text(self)
	}
}

extension Int64: Bindable {
	public var bindingValue: SQLValue {
		return .integer(self)
	}
}

extension Int: Bindable {
	public var bindingValue: SQLValue {
		return Int64(self).bindingValue
	}
}

extension Int32: Bindable {
	public var bindingValue: SQLValue {
		return Int64(self).bindingValue
	}
}

extension Int16: Bindable {
	public var bindingValue: SQLValue {
		return Int64(self).bindingValue
	}
}

extension Int8: Bindable {
	public var bindingValue: SQLValue {
		return Int64(self).bindingValue
	}
}

extension UInt64: Bindable {
	public var bindingValue: SQLValue {
		return .integer(Int64(self - UInt64(Int64.max)))
	}
}

extension UInt: Bindable {
	public var bindingValue: SQLValue {
		return Int64(self).bindingValue
	}
}

extension UInt32: Bindable {
	public var bindingValue: SQLValue {
		return Int64(self).bindingValue
	}
}

extension UInt16: Bindable {
	public var bindingValue: SQLValue {
		return Int64(self).bindingValue
	}
}

extension UInt8: Bindable {
	public var bindingValue: SQLValue {
		return Int64(self).bindingValue
	}
}

extension Double: Bindable {
	public var bindingValue: SQLValue {
		return .double(self)
	}
}

extension Float: Bindable {
	public var bindingValue: SQLValue {
		return Double(self).bindingValue
	}
}

extension Data: Bindable {
	public var bindingValue: SQLValue {
		return .blob(self)
	}
}

extension Date: Bindable {
	public var bindingValue: SQLValue {
		// FIXME: using Doubles for storage means Dates lose precision
		return .double(timeIntervalSince1970)
	}
}

extension Bool: Bindable {
	public var bindingValue: SQLValue {
		return .integer(self ? 1 : 0)
	}
}
