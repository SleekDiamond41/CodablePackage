//
//  Writer.swift
//  SQL
//
//  Created by Michael Arrington on 4/2/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation

extension Table.Column {
	init(name: String, type: SQLValue) {
		let t: ColumnType
		switch type {
		case .string:
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

class Writer {
	
	static func values<T>(for value: T) throws -> [(key: String, value: SQLValue)] where T: Model & Encodable {
		let writer = _Writer()
		try value.encode(to: writer)
		return writer.values
	}
	
	private let writer = _Writer()
	
	
	func prepare<T>(_ value: T) throws where T: Model & Encodable {
		try value.encode(to: writer)
	}
	
	func tableDefinition() -> Table {
		let name = "FIX tableDefinition YA DUMMY" //T.tableName
		let columns = writer.values
			.map { Table.Column(name: $0.0, type: $0.1) }
		
		return Table(name: name, columns: columns)
	}
	
	func replace(_ values: [(String, SQLValue)], into table: inout Table, connection: Connection, newColumnsHandler: (inout Table, [Table.Column]) throws -> Void) throws {
		
		let existingColumns = Set(table.columns.map { $0.name })
		
		let newColumns = values.filter { column in
			!existingColumns.contains(column.0)
		}
		.map {
			Table.Column(name: $0.0, type: $0.1)
		}
		
		try newColumnsHandler(&table, newColumns)
		
		var s = Statement(.save(table.name, values))

        //TODO: refactor so this can actually throw if needed
        try! s.prepare(in: connection.db)
		
		defer {
			s.finalize()
		}
		
		var i: Int32 = 1
		for (_ , value) in values {
            do {
				try s.bind(value, at: i)
            } catch {
                preconditionFailure(String(reflecting: error))
            }
			i += 1
		}
		
		let status = s.step()
		
		guard status == .done else {
			assertionFailure("expected status to be '\(Status.done)' but it was '\(status)'")
			throw ConnectionError.statusCode(expected: .done, actual: status)
		}
	}
	
	func update(table: inout Table, updates: [String: SQLValue], filter: Transaction.AnyFilter, connection: Connection, newColumnsHandler: (inout Table, [Table.Column]) throws -> Void) throws {
		let existingColumns = Set(table.columns.map { $0.name })
		
		let columnNames = Array(updates.keys)
		
		let newColumns = columnNames.filter {
			!existingColumns.contains($0)
		}
		.map {
			// should be safe to unwrap, since we're iterating
			// over the actual keys of the Dictionary
			Table.Column(name: $0, type: updates[$0]!)
		}
		
		try newColumnsHandler(&table, newColumns)
		
		var s = Statement(.update(table: table.name, query: filter.query, keys: columnNames))
		
		try s.prepare(in: connection.db)
		
		defer {
			s.finalize()
		}
		
		var i: Int32 = 1
		for name in columnNames {
			do {
				// we're using the actual Dictionary keys,
				// it should be safe to force unwrap
				try s.bind(updates[name]!, at: i)
			} catch {
				preconditionFailure(error.localizedDescription)
			}
			i += 1
		}
		
		for binding in filter.bindings {
			do {
				try s.bind(binding, at: i)
			} catch {
				preconditionFailure(error.localizedDescription)
			}
			i += 1
		}
		
		let status = s.step()
		
		guard status == .done else {
			assertionFailure("expected status to be '\(Status.done)' but it was '\(status)'")
			throw ConnectionError.statusCode(expected: .done, actual: status)
		}
	}
}


fileprivate protocol _WriterContainer {
	var values: [(String, Bindable)] { get }
}

fileprivate class _Writer: Encoder {
	var codingPath: [CodingKey] {
		return []
	}
	
	var userInfo: [CodingUserInfoKey : Any] {
		return [:]
	}
	
	var values = [(String, SQLValue)]()
	var currentKey: String?
	
	
	func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
		return KeyedEncodingContainer(KeyedContainer<Key>(self))
	}
	
	func unkeyedContainer() -> UnkeyedEncodingContainer {
		fatalError()
	}
	
	func singleValueContainer() -> SingleValueEncodingContainer {
		return SingleValueContainer(self)
	}
	
	class KeyedContainer<Key>: KeyedEncodingContainerProtocol where Key: CodingKey {
		
		var codingPath: [CodingKey] {
			return []
		}
		
		unowned let encoder: _Writer
		
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
			
			if let bindable = value as? Bindable {
				encoder.values.append((key.stringValue, bindable.bindingValue))
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
			
			if let bind = value as? Bindable {
				encoder.values.append((key, bind.bindingValue))
			} else {
				let e = JSONEncoder()
				let data = try e.encode(value)
				encoder.values.append((key, data.bindingValue))
			}
		}
	}
}
