import Benchmark
import SoA

typealias Arr = ContiguousArray

let read = BenchmarkSuite(name: "Loop read", settings: Iterations(100000), WarmupIterations(1000)) { suite in
    //=====//
    // AoS //
    //=====//
    struct MyStruct {
        var field1: Int
        var field2: String
        var field3: Float64
    }

    var arr = Arr<MyStruct>(repeating: MyStruct(field1: 420, field2: "Hello world", field3: 6.9), count: 1000)

    //=====//
    // SoA //
    //=====//
    // var soa = SoA(withCapacity: 1000)
    var soa = SoA()
    soa.realloc(withUnsafeCapacity: 1000)

    let idx1 = soa.newArray(Int.self)
    let fields1: UnsafeMutableBufferPointer<Int?> = soa.unsafeGetArray(withIndex: idx1)
    for i in 0..<1000 { fields1[i] = 420 }

    let idx2 = soa.newArray(String.self)
    let fields2: UnsafeMutableBufferPointer<String?> = soa.unsafeGetArray(withIndex: idx2)
    for i in 0..<1000 { fields2[i] = "Hello world" }

    let idx3 = soa.newArray(Float64.self)
    let fields3: UnsafeMutableBufferPointer<Float64?> = soa.unsafeGetArray(withIndex: idx3)
    for i in 0..<1000 { fields3[i] = 6.9 }

    //=========//
    // benches //
    //=========//

    suite.benchmark("Array of struct") {
        // for i in 0..<1000 {
        //     arr[i].field1 = 5
        // }
        arr.withUnsafeMutableBufferPointer { ptr in
            for i in 0..<1000 {
                let _f = ptr[i].field1
            }
        }
    }

    suite.benchmark("Struct of arrays") {
        let a: UnsafeMutableBufferPointer<Int?> = soa.unsafeGetArray(withIndex: 0)
        for i in 0..<1000 {
            let _f = a[i]
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

    var arr = Arr<MyStruct>(repeating: MyStruct(field1: 420, field2: "Hello world", field3: 6.9), count: 1000)

    //=====//
    // SoA //
    //=====//
    var soa = SoA()
    soa.realloc(withUnsafeCapacity: 1000)

    let idx1 = soa.newArray(Int.self)
    let fields1: UnsafeMutableBufferPointer<Int?> = soa.unsafeGetArray(withIndex: idx1)
    for i in 0..<1000 { fields1[i] = 420 }

    let idx2 = soa.newArray(String.self)
    let fields2: UnsafeMutableBufferPointer<String?> = soa.unsafeGetArray(withIndex: idx2)
    for i in 0..<1000 { fields2[i] = "Hello world" }

    let idx3 = soa.newArray(Float64.self)
    let fields3: UnsafeMutableBufferPointer<Float64?> = soa.unsafeGetArray(withIndex: idx3)
    for i in 0..<1000 { fields3[i] = 6.9 }

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

    suite.benchmark("Struct of arrays") {
        let a: UnsafeMutableBufferPointer<Int?> = soa.unsafeGetArray(withIndex: 0)
        for i in 0..<1000 {
            a[i] = 69
        }
    }
}

Benchmark.main([mut, read])
