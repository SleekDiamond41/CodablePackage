//
//  CDDatabase+KeyValueStorage.swift
//  CodableData
//
//  Created by Michael Arrington on 6/2/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation

extension Database {
	
	public func keyValueStorage() -> KeyValueStorage {
		return KeyValueStorage(self)
	}
}


// MARK: - KeyValueStorage
public final class KeyValueStorage {
	private let db: Database
	
	init(_ db: Database) {
		self.db = db
	}
	
	public func store<T>(_ value: T, for key: String) where T: Encodable {
		
		do {
			let data = try JSONEncoder().encode(value)
			let pair = KeyValue(id: key, data: data)
			try db.save(pair)
			
		} catch {
			assertionFailure(String(describing: error))
		}
	}
	
	public func value<T>(for key: String) -> T? where T: Decodable {
		do {
			let filter = Filter<KeyValue>(\.id, is: .exactly(key))
				.limit(1)
			
			guard let pair = try db.get(with: filter).first else {
				return nil
			}
			
			return try JSONDecoder().decode(T.self, from: pair.data)
			
		} catch {
			assertionFailure(String(describing: error))
			return nil
		}
	}
	
	public func removeValue(for key: String) {
		let filter = Filter<KeyValue>(\.id, is: .exactly(key))
			.limit(1)
		
		do {
			guard let existing = try db.get(with: filter).first else {
				return
			}
			
			try db.delete(existing)
		} catch {
			assertionFailure(String(describing: error))
		}
	}
}


// MARK: - KeyValue
private struct KeyValue: Model, Codable, Filterable {
	
	static let idKey = \KeyValue.id
	static let tableName = "__Key_Value_Storage__"
	
	let id: String
	let data: Data
	
	
	enum CodingKeys: String, CodingKey {
		case id
		case data
	}
	
	static func key(for path: PartialKeyPath<KeyValue>) -> CodingKeys {
		switch path {
		case KeyValue.idKey:
			return .id
		case \KeyValue.data:
			return .data
		default:
			preconditionFailure("Unknown KeyPath!")
		}
	}
	
	static func path(for key: CodingKeys) -> PartialKeyPath<KeyValue> {
		switch key {
		case .id:
			return \.id
		case .data:
			return \.data
		}
	}
}
