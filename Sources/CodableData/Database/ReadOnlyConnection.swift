//
//  ReadOnlyConnection.swift
//  
//
//  Created by Michael Arrington on 9/28/20.
//

import Foundation


/// Querying with a given Database instance across multiple threads simultaneously
/// would cause undefined behavior. Therefore,  `ReadOnlyConnection` exists as a
/// lightweight, separate connection that can be used for only reading.
public final class ReadOnlyConnection {
	
	let db: Database
	
	internal init(db: Database) {
		self.db = db
	}
	
	public func get<T>(with filter: Filter<T>) throws -> [T] where T: Decodable & Model {
		
		return try db.get(with: filter)
	}
	
	public func count<T>(with filter: Filter<T>) throws -> Int where T: Decodable & Model {
		
		return try db.count(with: filter)
	}
	
	@inlinable
	public func distinct<Element, T>(_ path: KeyPath<Element, T>) throws -> [T] where Element: Model & Filterable, T: Bindable {
		
		return try distinct(path, using: Filter<Element>())
	}
	
	public func distinct<Element, T>(_ path: KeyPath<Element, T>, using filter: Filter<Element>) throws -> [T] where Element: Model & Filterable, T: Bindable {
		
		return try db.distinct(path, using: filter)
	}
	
	@inlinable
	public func distinctCount<Element, T>(_ path: KeyPath<Element, T>) throws -> Int where Element: Model & Filterable, T: Bindable {
		
		return try distinctCount(path, using: Filter<Element>())
	}
	
	public func distinctCount<Element, T>(_ path: KeyPath<Element, T>, using filter: Filter<Element>) throws -> Int where Element: Model & Filterable, T: Bindable {
		
		return try db.distinctCount(path, using: filter)
	}
}
