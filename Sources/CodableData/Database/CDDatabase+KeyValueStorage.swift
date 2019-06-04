//
//  CDDatabase+KeyValueStorage.swift
//  CodableData
//
//  Created by Michael Arrington on 6/2/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation

enum KVStorage {
	struct Key: CDUUIDModel, Codable, CDFilterable {
		let id: UUID
		let key: String
		
		enum CodingKeys: String, CodingKey {
			case id
			case key
		}
		
		static func key<T>(for path: KeyPath<KVStorage.Key, T>) -> CodingKeys where T : CDBindable {
			switch path {
			case \Key.id:
				return .id
			case \Key.key:
				return .key
			default:
				fatalError()
			}
		}
	}
	
	struct Value: CDUUIDModel, Codable, CDFilterable {
		let id: UUID
		let value: String
		
		enum CodingKeys: String, CodingKey {
			case id
			case value
		}
		
		static func key<T>(for path: KeyPath<KVStorage.Value, T>) -> CodingKeys where T : CDBindable {
			switch path {
			case \Value.id:
				return .id
			case \Value.value:
				return .value
			default:
				fatalError()
			}
		}
	}
}

extension CDDatabase {
	
	static func store<T>(db: OpaquePointer, _ k: String, _ v: T) where T: Codable {
		let filter = CDFilter<KVStorage.Key>(\.key, is: .equal(to: k)).limit(1)
		
		let key: KVStorage.Key
		
		if let existing = get(db, filter: filter).first {
			key = existing
		} else {
			key = KVStorage.Key(id: UUID(), key: k)
		}
		
		let data = try! JSONEncoder().encode(v)
		guard let str = String(data: data, encoding: .utf8) else {
			fatalError()
		}
		
		let value = KVStorage.Value(id: key.id, value: str)
		
		replace(db: db, key)
		replace(db: db, value)
	}
	
	public func store<T>(key: String, value: T) where T: Codable {
		sync {
			CDDatabase.store(db: $0, key, value)
		}
	}
	
	public func store<T>(key: String, value: T, _ handler: @escaping () -> Void) where T: Codable {
		async {
			CDDatabase.store(db: $0, key, value)
			handler()
		}
	}
	
	static func value<T>(db: OpaquePointer, k: String) -> T? where T: Decodable {
		let filter = CDFilter<KVStorage.Key>(\.key, is: .equal(to: k)).limit(1)
		
		guard let key = get(db, filter: filter).first else {
			return nil
		}
		guard let value = get(db, KVStorage.Value.self, id: key.id) else {
			return nil
		}
		guard let data = value.value.data(using: .utf8) else {
			return nil
		}
		
		do {
			return try JSONDecoder().decode(T.self, from: data)
		} catch {
			return nil
		}
	}
	
	public func value<T>(for key: String) -> T? where T: Decodable {
		return sync {
			return CDDatabase.value(db: $0, k: key)
		}
	}
	
	public func value<T>(for key: String, _ handler: @escaping (T?) -> Void) where T: Decodable {
		async {
			handler(CDDatabase.value(db: $0, k: key))
		}
	}
	
}
