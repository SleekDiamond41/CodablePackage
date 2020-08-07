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

        let other = Filter<Name>(\.first, is: .exactly("Arrington"))
			.and(\.last, is: .ends(with: "example"))

        filter = filter.and(other)
        XCTAssertEqual(filter.query, """
		WHERE ("age" > ? AND "age" < ?) AND ("first" LIKE ? AND "last" LIKE ?)
		""")
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

        let other = Filter<Name>(\.first, is: .exactly("Arrington"))
			.or(\.last, is: .ends(with:"example"))

        filter = filter.or(other)
        XCTAssertEqual(filter.query, """
		WHERE ("age" > ? OR "age" < ?) OR ("first" LIKE ? OR "last" LIKE ?)
		""")
        XCTAssertEqual(filter.bindings.count, 4)
    }
	
//	func test_inValues() {
//		let filter = Filter<Name>().and(\.first, is: .starts(with: "m%"))
//			.and(\.age, is: .in([]))
//
//		print(filter.description)
//	}

    func testDescription() {
        XCTAssertEqual(Filter<Name>().description, """
        Filter<Name>:
        """)

        let filter = Filter<Name>(\.last, is: .notEqual(to: "Arrington"))
            .or(Filter(\.age, is: .greater(than: 20))
                .and(\.first, is: .exactly("Michael")))
            .and(\.age, is: .less(than: 40))
            .or(Filter(\.age, is: .less(than: 40)))
			.sort(by: \.last, .ascending)
			.sort(by: \.age, .descending)
			.limit(15, page: 3)
		
        XCTAssertEqual(filter.description, """
        Filter<Name>: WHERE ((last IS NOT 'Arrington') OR (age IS GREATER THAN 20 AND first IS EXACTLY 'Michael') AND age IS LESS THAN 40) OR (age IS LESS THAN 40) ORDER BY "last" ASC, "age" DESC LIMIT 15 OFFSET 45
        """)
    }
	
	func testDecodingEncoding() {
		let filter = Filter<Name>(\.last, is: .notEqual(to: "Arrington"))
			.or(Filter(\.age, is: .greater(than: 20))
				.and(\.first, is: .exactly("Michael")))
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
