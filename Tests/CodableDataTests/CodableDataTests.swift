import XCTest
@testable import CodableData

struct Name: UUIDModel, Codable, Filterable {
    let id: UUID

    var first: String
    var last: String

    enum CodingKeys: String, CodingKey {
        case id
        case first
        case last
    }

    static func key<T>(for path: KeyPath<Name, T>) -> CodingKeys where T : Bindable {
        switch path {
        case \Name.id: return .id
        case \Name.first: return .first
        case \Name.last: return .last
        default:
            preconditionFailure()
        }
    }
}

final class CodableDataTests: XCTestCase {

    func testCreateDatabase() {
        XCTAssertNoThrow(try Database(filename: "Testing"))
    }

    func testDatabase() {

        do {
            let db = try Database()

//            XCTAssertEqual(try db.count(with: Filter<Name>()), 0)

            let model = Name(id: UUID(), first: "Michael", last: "Arrington")

            XCTAssertNoThrow(try db.save(model))

//            XCTAssertEqual(db.count(with: Filter<Name>()), 1)

        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
