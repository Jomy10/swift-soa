import XCTest
@testable import SoA

final class soa_swiftTests: XCTestCase {
    func testNewArraySetElementAndRetrieve() {
        let soa = SoA()
        soa.newArray(String.self)
        soa[0][1] = "Hello world"
        XCTAssertEqual(soa[0][1], "Hello world")
    }

    func testValueFunc() {
        let soa = SoA()
        soa.newArray(String.self)
        soa[0][1] = "Hello world"
        XCTAssertEqual(soa.value(of: 0, at: 1), "Hello world")
    }
}
