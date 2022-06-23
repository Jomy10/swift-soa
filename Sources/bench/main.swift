import Benchmark
import SoA
import Foundation

typealias Arr = ContiguousArray

let ARR_COUNT = 1000

let read = BenchmarkSuite(name: "Loop read", settings: Iterations(100000), WarmupIterations(1000)) { suite in
    //=====//
    // AoS //
    //=====//
    struct MyStruct {
        var field1: Int
        var field2: String
        var field3: Float64
    }

    let arr = Arr<MyStruct>(repeating: MyStruct(field1: 420, field2: "Hello world", field3: 6.9), count: ARR_COUNT)

    //=====//
    // SoA //
    //=====//
    var soa = SoA(
        Fields()
            .field(Int.self)
            .field(String.self)
            .field(Float64.self),
        initialCapacity: ARR_COUNT
    )
    
    for i in 0..<ARR_COUNT {
        soa.set(0, at: i, 420)
        soa.set(1, at: i, str: "Hello world")
        soa.set(2, at: i, 6.9)
    }

    //=========//
    // benches //
    //=========//

    suite.benchmark("Array of struct") {
        // for i in 0..<1000 {
        //     arr[i].field1 = 5
        // }
        arr.withUnsafeBufferPointer { ptr in
            for i in 0..<ARR_COUNT {
                let _ = ptr[i].field1
            }
        }
    }

    suite.benchmark("Struct of arrays") {
        // let a: UnsafeMutableBufferPointer<Int?> = soa.unsafeGetArray(withIndex: 0)
        // for i in 0..<1000 {
        //     let _ = a[i]
        // }
        for i in 0..<ARR_COUNT {
            let _: Int = soa.get(0, at: i)
        }
    }
    
    suite.benchmark("Struct of arrays + ptr") {
        for i in 0..<ARR_COUNT {
            soa.get(0, at: i) { (ptr: UnsafePointer<Int>) in
                let _ = ptr.pointee
            }
        }
    }
    
    suite.benchmark("Struct of arrays + slice") {
        soa.slice(0) { (slice: UnsafeSoASlice<Int>) in
            for i in 0..<ARR_COUNT {
                let _ = slice[i]
            }
        }
    }
}

let mut = BenchmarkSuite(name: "Loop mutate", settings: Iterations(100000), WarmupIterations(1000)) { suite in
    //=====//
    // AoS //
    //=====//
    struct MyStruct {
        var field1: Int
        var field2: String
        var field3: Float64
    }

    var arr = Arr<MyStruct>(repeating: MyStruct(field1: 420, field2: "Hello world", field3: 6.9), count: ARR_COUNT)

    //=====//
    // SoA //
    //=====//
    var soa = SoA(
        Fields()
            .field(Int.self)
            .field(String.self)
            .field(Float64.self),
        initialCapacity: ARR_COUNT
    )
    
    for i in 0..<ARR_COUNT {
        soa.set(0, at: i, 420)
        soa.set(1, at: i, str: "Hello world")
        soa.set(2, at: i, 6.9)
    }
    
    //=========//
    // benches //
    //=========//
    suite.benchmark("Array of struct") {
        arr.withUnsafeMutableBufferPointer { ptr in
            for i in 0..<1000 {
                ptr[i].field1 = 69
            }
        }
    }

    // slowest
    suite.benchmark("Struct of arrays") {
        for i in 0..<1000 {
            soa.set(0, at: i, 69)
        }
    }
    
    // fastest
    suite.benchmark("Struct of Arrays + slice") {
        soa.slice(0) { (ptr: UnsafeSoASlice<Int>) in
            var ptr = ptr
            for i in 0..<1000 {
                ptr[i] = 69
            }
        }
    }
}

let mutPtr = BenchmarkSuite(name: "Loop mut ptr", settings: Iterations(10000), WarmupIterations(1000)) { suite in
    //=====//
    // SoA //
    //=====//
    var soa = SoA(
        Fields()
            .field(UnsafeMutableBufferPointer<Int>.self),
        initialCapacity: ARR_COUNT
    )
    
    for i in 0..<ARR_COUNT {
        let ptr1 = UnsafeMutableRawBufferPointer.allocate(byteCount: MemoryLayout<Int>.stride, alignment: MemoryLayout<Int>.alignment)
        let j = 5
        withUnsafeBytes(of: j) {
            ptr1.copyMemory(from: $0)
        }
        soa.set(0, at: i, managedPtr: UnsafeRawBufferPointer(ptr1))
    }
    
    //=========//
    // benches //
    //=========//
    let ptr = UnsafeMutableRawBufferPointer.allocate(byteCount: MemoryLayout<Int>.stride, alignment: MemoryLayout<Int>.alignment)
    let i = 69
    withUnsafeBytes(of: i) {
        ptr.copyMemory(from: $0)
    }
    
    // slowest
    suite.benchmark("Struct of arrays") {
        for i in 0..<1000 {
            soa.set(0, at: i, ptr: UnsafeRawBufferPointer(ptr))
        }
    }
    
    let typedMutPtr: UnsafeMutableBufferPointer = ptr.bindMemory(to: Int.self)
    let typedPtr: UnsafeBufferPointer<Int> = UnsafeBufferPointer(typedMutPtr)
    
    suite.benchmark("Struct of arrays + unmanaged") {
        for i in 0..<1000 {
            soa.setUnmanaged(0, at: i, ptr: UnsafeRawBufferPointer(ptr))
        }
    }
    
    suite.benchmark("Struct of arrays + slice") {
        soa.slice(0) { (slice: UnsafeSoASliceBufPtr<Int>) in
            var slice = slice
            for i in 0..<1000 {
                slice[i] = typedPtr
            }
        }
    }
    
    // fastest
    suite.benchmark("SoA + slice unmanaged") {
        soa.slice(0) { (slice: UnsafeSoASliceBufPtr<Int>) in
            var slice = slice
            for i in 0..<1000 {
                slice[unmanaged: i] = typedPtr
            }
        }
    }
    ptr.deallocate()
    
    // suite.benchmark("Struct of Arrays + slice") {
    //     soa.slice(0) { (ptr: UnsafeSoASlice<Int>) in
    //         var ptr = ptr
    //         for i in 0..<1000 {
    //             var ptr = UnsafeMutableRawBufferPointer.allocate(1)
    //             var j = 69
    //             ptr.copyMemory(&j)
    //             ptr[i] = ptr
    //         }
    //     }
    // }
}   

Benchmark.main([mutPtr, mut, read])
