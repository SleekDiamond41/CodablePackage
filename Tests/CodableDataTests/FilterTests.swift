//
//  FilterTests.swift
//  
//
//  Created by Michael Arrington on 1/31/20.
//

import XCTest
@testable import CodableData

class FilterTests: XCTestCase {

    func test_andComparison() {
        var filter = Filter<Name>()
        XCTAssertEqual(filter.query, "")
        XCTAssertEqual(filter.bindings.count, 0)

        filter = filter.and(\.age, is: .greater(than: 18))
        XCTAssertEqual(filter.query, "WHERE \"age\" > ?")
        XCTAssertEqual(filter.bindings.count, 1)

        filter = filter.and(\.age, is: .less(than: 30))
        XCTAssertEqual(filter.query, "WHERE \"age\" > ? AND \"age\" < ?")
        XCTAssertEqual(filter.bindings.count, 2)

        let other = Filter<Name>(\.first, is: .matches("Arrington"))
            .and(\.last, is: .regex("example"))

        filter = filter.and(other)
        XCTAssertEqual(filter.query, "WHERE (\"age\" > ? AND \"age\" < ?) AND (\"first\" MATCH ? AND \"last\" REGEXP ?)")
        XCTAssertEqual(filter.bindings.count, 4)
    }

    func test_orComparison() {
        var filter = Filter<Name>()
        XCTAssertEqual(filter.query, "")
        XCTAssertEqual(filter.bindings.count, 0)

        filter = filter.or(\.age, is: .greater(than: 18))
        XCTAssertEqual(filter.query, "WHERE \"age\" > ?")
        XCTAssertEqual(filter.bindings.count, 1)

        filter = filter.or(\.age, is: .less(than: 30))
        XCTAssertEqual(filter.query, "WHERE \"age\" > ? OR \"age\" < ?")
        XCTAssertEqual(filter.bindings.count, 2)

        let other = Filter<Name>(\.first, is: .matches("Arrington"))
            .or(\.last, is: .regex("example"))

        filter = filter.or(other)
        XCTAssertEqual(filter.query, "WHERE (\"age\" > ? OR \"age\" < ?) OR (\"first\" MATCH ? OR \"last\" REGEXP ?)")
        XCTAssertEqual(filter.bindings.count, 4)
    }
	
	func test_inValues() {
		var filter = Filter<Name>().and(\.first, is: .like("m%"))
		
		print(filter.description)
	}

    func testDescription() {
        XCTAssertEqual(Filter<Name>().description, """
        Filter<Name>
            - Query:
            - Binding Values: []
        """)

        let filter = Filter<Name>(\.last, is: .notEqual(to: "Arrington"))
            .or(Filter(\.age, is: .greater(than: 20))
                .and(\.first, is: .like("Michael")))
            .and(\.age, is: .less(than: 40))
            .or(Filter(\.age, is: .less(than: 40)))
			.sorting(by: \.last, .ascending)
			.sorting(by: \.age, .descending)

        XCTAssertEqual(filter.description, """
        Filter<Name>
            - Query: WHERE (("last" NOT LIKE ?) OR ("age" > ? AND "first" LIKE ?) AND "age" < ?) OR ("age" < ?) ORDER BY "last" ASC, "age" DESC
            - Binding Values: ["Arrington", 20, "Michael", 40, 40]
        """)
    }
	
	func testDecodingEncoding() {
		let filter = Filter<Name>(\.last, is: .notEqual(to: "Arrington"))
			.or(Filter(\.age, is: .greater(than: 20))
				.and(\.first, is: .like("Michael")))
			.and(\.age, is: .less(than: 40))
			.or(Filter(\.age, is: .less(than: 40)))
		
		do {
			let data = try JSONEncoder().encode(filter)
			let result = try JSONDecoder().decode(Filter<Name>.self, from: data)
			
			XCTAssertEqual(result, filter)
			XCTAssertEqual(result.description, filter.description)
		} catch {
			
		}
	}
}
