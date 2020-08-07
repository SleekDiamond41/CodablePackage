//
//  Name.swift
//  
//
//  Created by Michael Arrington on 1/31/20.
//

import Foundation
import CodableData

struct Name: UUIDModel, Codable, Filterable, Equatable {
    let id: UUID

    var first: String
    var last: String
    var age: Int = 0
	
	static var idKey = \Name.id

    enum CodingKeys: String, CodingKey {
        case id
        case first
        case last
        case age
    }

    static func key(for path: PartialKeyPath<Name>) -> CodingKeys {
        switch path {
        case \Name.id: return .id
        case \Name.first: return .first
        case \Name.last: return .last
        case \Name.age: return .age
        default:
            preconditionFailure()
        }
    }
	
	static func path(for key: CodingKeys) -> PartialKeyPath<Name> {
		switch key {
		case .id: return \.id
		case .first: return \.first
		case .last: return \.last
		case .age: return \.age
		}
	}
}
