//
//  RowReadable.swift
//  SQL
//
//  Created by Michael Arrington on 3/31/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation
import SQLite3


struct Person: CDModel, Equatable {
	let id: UUID
	let name: String
	let nickName: String?
	
	init(id: UUID, name: String, nickName: String? = nil) {
		self.id = id
		self.name = name
		self.nickName = nickName
	}
	
	enum CodingKeys: String, CodingKey {
		case id
		case name
		case nickName = "nick_name"
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		self.id = try container.decode(UUID.self, forKey: .id)
		self.name = try container.decode(String.self, forKey: .name)
		self.nickName = try container.decode(String?.self, forKey: .nickName)
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		try container.encode(id, forKey: .id)
		try container.encode(name, forKey: .name)
		try container.encode(nickName, forKey: .nickName)
	}
}


enum ReaderError: Error {
	case noSuchTable(String)
}

class Reader {
	
	private func read<T: Decodable>(_ : T.Type, from s: Statement, in table: Table) throws -> T {
		let reader = _Reader(s, table)
		return try T(from: reader)
	}
	
	func read<T>(_ : T.Type, s: Statement, _ table: Table) throws -> T where T: Decodable {
		let r = _Reader(s, table)
		return try T(from: r)
	}
}

fileprivate class _Reader: Decoder {
	var codingPath: [CodingKey] {
		return []
	}
	
	var userInfo: [CodingUserInfoKey : Any] {
		return [:]
	}
	
	let s: Statement
	let table: Table
	
	var currentColumn: Int32?
	
	init(_ s: Statement, _ table: Table) {
		self.s = s
		self.table = table
	}
	
	func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
		return KeyedDecodingContainer(KeyedContainer(self))
	}
	
	func unkeyedContainer() throws -> UnkeyedDecodingContainer {
		fatalError()
	}
	
	func singleValueContainer() throws -> SingleValueDecodingContainer {
		return SingleValueContainer(self)
	}
	
	
	class KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
		
		var codingPath: [CodingKey] = []
		var allKeys: [Key] = []
		
		private var values: [String: Decodable] = [:]
		
		let decoder: _Reader
		
		init(_ decoder: _Reader) {
			self.decoder = decoder
		}
		
		func contains(_ key: Key) -> Bool {
			return index(for: key) != nil
		}
		
		private func index(for key: Key) -> Int32? {
			guard let index = decoder.table.columns.firstIndex(where: { $0.name == key.stringValue }) else {
//				fatalError()
				return nil
			}
			return Int32(index)
		}
		
		func decodeNil(forKey key: Key) throws -> Bool {
			guard let index = index(for: key) else {
				return true
			}
			
			let type = ColumnType(sqlite3_column_type(decoder.s.p, index))
			return type == nil
			
//			do {
//				//FIXME: need a way to check for nil values before knowing what I'm supposed to convert it to
//				_ = try Double.unbind(from: decoder.s, at: index)
//				return false
//
//			} catch {
//				return true
//			}
			
//			return 0.0 == (try Double.unbind(from: decoder.s, at: index))
//			ColumnType(String(cString: sqlite3_column_decltype(s.p, i)))
//			return false
		}
		
		func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
			let i = index(for: key)
			
			do {
				if let U = T.self as? Unbindable.Type {
					return try U.unbind(from: decoder.s, at: i) as! T
				} else {
					assert(decoder.currentColumn == nil)
					decoder.currentColumn = i
					return try T(from: decoder)
				}
			} catch {
				preconditionFailure(key.stringValue + ": " + String(reflecting: error))
			}
		}
		
		func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
			fatalError()
		}
		
		func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
			fatalError()
		}
		
		func superDecoder() throws -> Decoder {
			fatalError()
		}
		
		func superDecoder(forKey key: Key) throws -> Decoder {
			fatalError()
		}
		
	}
	
	class SingleValueContainer: SingleValueDecodingContainer {
		var codingPath: [CodingKey] = []
		
		let decoder: _Reader
		
		init(_ decoder: _Reader) {
			self.decoder = decoder
		}
		
		func decodeNil() -> Bool {
			return decoder.currentColumn == nil
		}
		
		func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
			defer {
				decoder.currentColumn = nil
			}
			
			guard let index = decoder.currentColumn else {
				fatalError()
			}
			
			if let U = T.self as? Unbindable.Type {
				return try U.unbind(from: decoder.s, at: index) as! T
			} else {
				let data = try Data.unbind(from: decoder.s, at: index)
				let d = JSONDecoder()
				return try d.decode(T.self, from: data)
			}
		}
		
	}
	
}
