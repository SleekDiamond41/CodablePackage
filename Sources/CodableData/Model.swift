//
//  Model.swift
//  CodablePackage
//
//  Created by Michael Arrington on 4/3/19.
//  Copyright © 2019 Duct Ape Productions. All rights reserved.
//

import Foundation


public protocol Model {
	associatedtype PrimaryKey: Equatable & Bindable
	
	static var idKey: KeyPath<Self, PrimaryKey> { get }
	
	
	/// The name of the table to which this object should be saved.
	///
	/// - Note: CodableData surrounds the given name in double quotes ("\"") so capitalization, spaces and some punctuation marks (-.+!?) are valid characters and respected by SQLite. See https://stackoverflow.com/a/3694305/9626155 for more information.
	///
	/// Remember namespacing when implementing a custom tableName. String(reflecting: MyModel.self), String(describing: MyModel.self) and "\(MyModel.self)" all return the String name of the object, but the latter two return unique the name of the type within its own scope, ignoring namespacing. For example:
	///
	///     struct Foo {
	///       struct Bar {}
	///     }
	///
	///     String(reflecting: Foo.Bar.self) == "Foo.Bar"
	///     String(describing: Foo.Bar.self) == "Bar"
	///     "\(Foo.Bar.self)"                == "Bar"
	///
	/// CodableData's default behavior is to use the first version.
	static var tableName: String { get }
}

extension Model {
	public static var tableName: String {
		let s = String(reflecting: Self.self)
		let pattern = #"unknown context at \$([0-9]|[a-f])*"#
		
		guard s.range(of: pattern, options: .regularExpression) == nil else {
			let message = """
			the default implementation of `tableName` uses `String(reflecting: Self.self)`. The result includes an inconsistent section of text identified by the regex pattern "\(pattern)"; therefore, the default behavior cannot be relied upon for data-table naming.

			To resolve this issue, update your object to implement a custom `tableName` property.
			"""
			preconditionFailure(message)
		}
		return s
	}
}

public protocol UUIDModel: Model where PrimaryKey == UUID {
//	static var idKey: KeyPath<Self, PrimaryKey> { get }
}

//TODO: implement using row ids instead of UUIDs
// if id is valid, update, else insert (table definition should include primary key being
// autoincrementing, if id is nil then it's ignored when inserting, then we read back the
// newest value from the database to get it with a valid id

//protocol RowModel: Model where PrimaryKey == Int64? {
//	var id: Int64? { get set }
//}
//
//struct Paper: Codable, UUIDModel {
//	let id: UUID
//
//	static var idKey = \Paper.id
//}
//
//extension Paper: Filterable {
//	enum CodingKeys: String, CodingKey {
//		case id
//	}
//
//	static func key<T>(for path: KeyPath<Paper, T>) -> CodingKeys where T : Bindable {
//		switch path {
//		case \Paper.id:
//			return .id
//		default:
//			fatalError("Unknown key path")
//		}
//	}
//
//	static func path(for key: CodingKeys) -> PartialKeyPath<Paper> {
//		switch key {
//		case .id: return \.id
//		}
//	}
//}


//TODO: Implement SQLRowModel to allow tables that use row id as the primary key

//public typealias SQLRowModel = Codable & RowModel & CDFilterable
//public protocol RowModel {
//	var id: Int64? { get }
//}
