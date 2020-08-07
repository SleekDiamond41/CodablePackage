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

public protocol UnbindingProxy {
	func get() -> Int64
	func get() -> Double
	func get() -> String
	func get() -> Data
	
	func isNull() -> Bool
}


extension UUID: Bindable {
	public var bindingValue: SQLValue {
		uuidString.bindingValue
	}
	
	public static func unbind(_ proxy: UnbindingProxy) -> UUID {
		return UUID(uuidString: proxy.get())!
	}
}


public protocol Unbindable {
	@inlinable
	static func unbind(_ proxy: UnbindingProxy) -> Self
}


extension Optional where Wrapped: Unbindable {
	
	public static func unbind(_ proxy: UnbindingProxy) -> Self {
		if proxy.isNull() {
			return .none
		}
		return Wrapped.unbind(proxy)
	}
}


extension Int: Unbindable {
	public static func unbind(_ proxy: UnbindingProxy) -> Int {
		return Int(proxy.get() as Int64)
	}
}
extension Int8: Unbindable {
	public static func unbind(_ proxy: UnbindingProxy) -> Int8 {
		return Int8(proxy.get() as Int64)
	}
}
extension Int16: Unbindable {
	public static func unbind(_ proxy: UnbindingProxy) -> Int16 {
		return Int16(proxy.get() as Int64)
	}
}
extension Int32: Unbindable {
	public static func unbind(_ proxy: UnbindingProxy) -> Int32 {
		return Int32(proxy.get() as Int64)
	}
}
extension Int64: Unbindable {
	public static func unbind(_ proxy: UnbindingProxy) -> Int64 {
		return proxy.get()
	}
}
extension UInt: Unbindable {
	public static func unbind(_ proxy: UnbindingProxy) -> UInt {
		return UInt(proxy.get() as Int64)
	}
}
extension UInt8: Unbindable {
	public static func unbind(_ proxy: UnbindingProxy) -> UInt8 {
		return UInt8(proxy.get() as Int64)
	}
}
extension UInt16: Unbindable {
	public static func unbind(_ proxy: UnbindingProxy) -> UInt16 {
		return UInt16(proxy.get() as Int64)
	}
}
extension UInt32: Unbindable {
	public static func unbind(_ proxy: UnbindingProxy) -> UInt32 {
		return UInt32(proxy.get() as Int64)
	}
}
extension UInt64: Unbindable {
	public static func unbind(_ proxy: UnbindingProxy) -> UInt64 {
		return UInt64(proxy.get() as Int64)
	}
}


extension Bool: Unbindable {
	public static func unbind(_ proxy: UnbindingProxy) -> Bool {
		return (proxy.get() as Int64) != 0
	}
}


extension String: Unbindable {
	public static func unbind(_ proxy: UnbindingProxy) -> String {
		return proxy.get()
	}
}


extension Double: Unbindable {
	public static func unbind(_ proxy: UnbindingProxy) -> Double {
		return proxy.get()
	}
}
extension Float: Unbindable {
	public static func unbind(_ proxy: UnbindingProxy) -> Float {
		return Float(proxy.get() as Double)
	}
}


extension Data: Unbindable {
	public static func unbind(_ proxy: UnbindingProxy) -> Data {
		return proxy.get()
	}
}


extension Date: Unbindable {
	public static func unbind(_ proxy: UnbindingProxy) -> Date {
		let interval = proxy.get() as Double
		return Date(timeIntervalSinceReferenceDate: interval)
	}
}
