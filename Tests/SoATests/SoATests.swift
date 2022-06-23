import XCTest
@testable import SoA

typealias Arr = ContiguousArray

let ARR_COUNT = 1000

final class SoATests: XCTestCase {
    func testPointer() {
        var soa = SoA(
            Fields()
                .field(UnsafeBufferPointer<Int>.self),
            initialCapacity: 3
        )
        let i = 5
        withUnsafeBytes(of: i) {
            soa.set(0, at: 0, ptr: $0)
            let ptr = soa.getBufPtr(0, at: 0) as UnsafeBufferPointer<Int>
            XCTAssertEqual(5, ptr.baseAddress!.pointee)
        }
    }
    
    func testMultiplePointers() {
        var soa = SoA(
            Fields()
                .field(UnsafeBufferPointer<Int>.self),
            initialCapacity: 3
        )
        let i = 5
        withUnsafeBytes(of: i) {
            soa.set(0, at: 0, ptr: $0)
            let ptr = soa.getBufPtr(0, at: 0) as UnsafeBufferPointer<Int>
            XCTAssertEqual(5, ptr.baseAddress!.pointee)
            
            let j = 76
            withUnsafeBytes(of: j) {
                soa.set(0, at: 1, ptr: $0)
                let ptr2: UnsafeBufferPointer<Int> = soa.getBufPtr(0, at: 1)
                XCTAssertEqual(76, ptr2.baseAddress!.pointee)
                XCTAssertEqual(5, ptr.baseAddress!.pointee)
            }
        }
        print(soa)
    }
    
    func testInteger() {
        var soa = SoA(
            Fields()
                .field(Int64.self)
                .field(Int.self),
            initialCapacity: 2
        )
        soa.set(0, at: 0, Int64.max)
        soa.set(0, at: 1, Int64.max)
        
        soa.set(1, at: 0, Int.max)
        soa.set(1, at: 1, 69)
        
        XCTAssertEqual(Int64.max, soa.get(0, at: 0))
        XCTAssertEqual(Int64.max, soa.get(0, at: 1))
        XCTAssertEqual(Int.max, soa.get(1, at: 0))
        XCTAssertEqual(69, soa.get(1, at: 1))
    }
    
    func testString() {
        var soa = SoA(
            Fields()
                .field(Int.self)
                .field(String.self)
                .field(Int32.self),
            initialCapacity: 2
        )
        
        XCTAssertEqual(0, soa.get(2, at: 0) as Int32)
        XCTAssertEqual(0, soa.get(2, at: 1) as Int32)
        soa.set(1, at: 0, str: "Hello world")
        soa.set(1, at: 1, str: "Goodbye!")
        
        XCTAssertEqual(0, soa.get(0, at: 0))
        XCTAssertEqual(0, soa.get(0, at: 1))
        XCTAssertEqual(0, soa.get(2, at: 0) as Int32)
        XCTAssertEqual(0, soa.get(2, at: 1) as Int32)
        XCTAssertEqual("Hello world", soa.get(1, at: 0) as String?)
        XCTAssertEqual("Goodbye!", soa.get(1, at: 1) as String?)
    }
    
    func testStringSlice() {
        var soa = SoA(
            Fields()
                .field(Int.self)
                .field(String.self)
                .field(Int32.self),
            initialCapacity: 2
        )
        
        XCTAssertEqual(0, soa.get(2, at: 0) as Int32)
        XCTAssertEqual(0, soa.get(2, at: 1) as Int32)
        soa.slice(1) { (slice: UnsafeSoAString) in
            var slice = slice
            slice[0] = "Hello world"
            slice[1] = "Goodbye!"
        }
        
        XCTAssertEqual(0, soa.get(0, at: 0))
        XCTAssertEqual(0, soa.get(0, at: 1))
        XCTAssertEqual(0, soa.get(2, at: 0) as Int32)
        XCTAssertEqual(0, soa.get(2, at: 1) as Int32)
        soa.slice(1) { (slice: UnsafeSoAString) in
            XCTAssertEqual("Hello world", slice[0])
            XCTAssertEqual("Goodbye!", slice[1])
        }
    }
}