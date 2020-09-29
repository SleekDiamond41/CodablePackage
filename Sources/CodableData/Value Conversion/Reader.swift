//
//  RowReadable.swift
//  SQL
//
//  Created by Michael Arrington on 3/31/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation
import SQLite3


enum ReaderError: Error {
	case noSuchColumn(String)
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
	
	var proxy: Proxy!
	let s: Statement
	let table: Table
	
	var currentColumn: Int32?
	
	init(_ s: Statement, _ table: Table) {
		self.s = s
		self.table = table
		self.proxy = Proxy(s, isNull: { [unowned self] i in
			self.isNull(at: i)
		})
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
	
	private func isNull(at index: Int32) -> Bool {
		let type = ColumnType(sqlite3_column_type(s.p, index))
		return type == nil
	}
	
	
	class KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
		
		var codingPath: [CodingKey] = []
		var allKeys: [Key] = []
		
		private var values: [String: Decodable] = [:]
		
		unowned let decoder: _Reader
		
		init(_ decoder: _Reader) {
			self.decoder = decoder
		}
		
		func contains(_ key: Key) -> Bool {
			return (try? index(for: key)) != nil
		}
		
		private func index(for key: Key) throws -> Int32 {
			guard let index = decoder.table.columns.firstIndex(where: { $0.name == key.stringValue }) else {
				throw ReaderError.noSuchColumn(key.stringValue)
			}
			return Int32(index)
		}
		
		func decodeNil(forKey key: Key) throws -> Bool {
			let i = try index(for: key)
			
			return decoder.isNull(at: i)
		}
		
		func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
			
			decoder.proxy.index = try index(for: key)
			
			do {
				if let U = T.self as? Bindable.Type {
					return try U.unbind(decoder.proxy) as! T
				} else {
					assert(decoder.currentColumn == nil)
					decoder.currentColumn = decoder.proxy.index
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
		
		unowned let decoder: _Reader
		
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
			
			guard decoder.currentColumn != nil else {
				fatalError()
			}
			
			if let U = T.self as? Bindable.Type {
				return try U.unbind(decoder.proxy) as! T
			} else {
				let data = try Data.unbind(decoder.proxy)
				let d = JSONDecoder()
				return try d.decode(T.self, from: data)
			}
		}
	}
}
