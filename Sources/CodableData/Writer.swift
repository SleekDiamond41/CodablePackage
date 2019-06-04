//
//  Writer.swift
//  SQL
//
//  Created by Michael Arrington on 4/2/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation

extension Table.Column {
	init(name: String, type: CDValue) {
		let t: ColumnType
		switch type {
		case .text:
			t = .text
		case .integer:
			t = .integer
		case .double:
			t = .double
		case .blob:
			t = .blob
		case .null:
			t = .integer
		}
		self.init(name: name, type: t)
	}
}

class Writer<T: CDModel & Encodable> {
	
	private let writer = _Writer()
	
	
	func prepare(_ value: T) throws {
		try value.encode(to: writer)
	}
	
	func tableDefinition() -> Table {
		return Table(name: T.tableName, columns:
			writer.values.map {
				Table.Column(name: $0.0, type: $0.1.bindingValue)
			}
		)
	}
	
	func replace(_ value: T, into table: inout Table, db: OpaquePointer, newColumnsHandler: ([Table.Column]) -> Void) throws {
		
		newColumnsHandler(writer.values.filter { (val) in
			return !table.columns.contains(where: { $0.name == val.0 })
			}.map {
				Table.Column(name: $0.0, type: $0.1.bindingValue)
			})
		
		let keys = writer.values.map { $0.0 }.joined(separator: ", ")
		let values = [String](repeating: "?", count: writer.values.count).joined(separator: ", ")
		
		var s = Statement("REPLACE INTO \(table.name) (\(keys)) VALUES (\(values))")
		
		try s.prepare(in: db)
		defer {
			s.finalize()
		}
		var i: Int32 = 1
		for (_ , value) in writer.values {
			try value.bindingValue.bind(into: s, at: i)
			i += 1
		}
		
		try s.step()
	}
	
}

fileprivate protocol _WriterContainer {
	var values: [(String, CDBindable)] { get }
}

fileprivate class _Writer: Encoder {
	var codingPath: [CodingKey] {
		return []
	}
	
	var userInfo: [CodingUserInfoKey : Any] {
		return [:]
	}
	
	var values = [(String, CDBindable)]()
	var currentKey: String?
	
	
	func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
		return KeyedEncodingContainer(KeyedContainer<Key>(self))
	}
	
	func unkeyedContainer() -> UnkeyedEncodingContainer {
		fatalError()
	}
	
	func singleValueContainer() -> SingleValueEncodingContainer {
		fatalError()
	}
	
	class KeyedContainer<Key>: KeyedEncodingContainerProtocol where Key: CodingKey {
		
		var codingPath: [CodingKey] {
			return []
		}
		
		let encoder: _Writer
		
		init(_ encoder: _Writer) {
			self.encoder = encoder
		}
		
		
//		private func index(for key: Key) -> Int32 {
//			if let i = indices[key.stringValue] {
//				return i
//			}
//
//			let str = key.stringValue
//
//			guard let index = table.columns.firstIndex(where: { $0.name == str }) else {
//				fatalError("No column named '\(str)'")
//				//				return nil
//			}
//
//			let i = Int32(index)
//			indices[str] = i
//			return i
//		}
		
		func encodeNil(forKey key: Key) throws {
			
//			switch table.columns[Int(i)].type {
//			case .text:
//				let val: String? = nil
//				values.append((key.stringValue, val))
//			case .integer:
//				let val: Int64? = nil
//				values.append((key.stringValue, val))
//			case .double:
//				let val: Double? = nil
//				values.append((key.stringValue, val))
//			case .blob:
//				let val: Data? = nil
//				values.append((key.stringValue, val))
//			}
		}
		
		
		func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
//			let i = index(for: key)
			
			if let bindable = value as? CDBindable {
				encoder.values.append((key.stringValue, bindable))
			} else {
				// value is likely an enum, encode its RawValue
				assert(encoder.currentKey == nil)
				encoder.currentKey = key.stringValue
				try value.encode(to: encoder)
			}
		}
		
		func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
			fatalError()
		}
		
		func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
			fatalError()
		}
		
		func superEncoder() -> Encoder {
			fatalError()
		}
		
		func superEncoder(forKey key: Key) -> Encoder {
			fatalError()
		}
		
	}
	
	struct SingleValueContainer: SingleValueEncodingContainer {
		
		var codingPath: [CodingKey] = []
		
		let encoder: _Writer
		
		init(_ encoder: _Writer) {
			self.encoder = encoder
		}
		
		mutating func encodeNil() throws {
			
		}
		
		mutating func encode<T>(_ value: T) throws where T : Encodable {
			defer {
				encoder.currentKey = nil
			}
			guard let key = encoder.currentKey else {
				preconditionFailure("Expected to have a key to encode value '\(value)'")
			}
			
			if let bind = value as? CDBindable {
				encoder.values.append((key, bind))
			} else {
				let e = JSONEncoder()
				let data = try e.encode(value)
				encoder.values.append((key, data))
			}
		}
	}
	
}
