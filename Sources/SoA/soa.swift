/// Fields of a SoA
///
/// ```
/// Fields()
///     .field(String.self)
///     .field(Int.self)
/// ```
public final class Fields {
    @usableFromInline var sizes: ContiguousArray<Int>
    
    public init() {
        self.sizes = []
    }
    
    @inlinable public func field<T>(_ type: T.Type) -> Self {
        sizes.append(MemoryLayout<T>.size)
        return self
    }
    
    @inlinable public func field(_ type: String.Type) -> Self {
        sizes.append(__ptrSize * 2)
        return self
    }
}

@usableFromInline internal final class SoAPointerManager {
    // maybe store in memory contiguously using array, and have an [Int:Int] to map
    // them to the array indices
    @usableFromInline var ptrs: [Int:UnsafeRawBufferPointer]
    
    init() {
        self.ptrs = [:]
    }
    
    /// Manage the given pointer and deallocate the previous one if any
    @inlinable func manage(_ id: Int, _ ptr: UnsafeRawBufferPointer) {
        if let prevPtr = self.ptrs[id] {
            prevPtr.deallocate()
        }
        self.ptrs[id] = ptr
    }
    
    /// deallocate the pointer with the id if presentt
    @inlinable func dealloc(_ id: Int) {
        if let prevPtr = self.ptrs[id] {
            prevPtr.deallocate()
            self.ptrs.removeValue(forKey: id)
        }
    }
    
    deinit {
        for (_, ptr) in ptrs {
            ptr.deallocate()
        }
    }
}

/// A struct of arrays
///
/// This library is meant to be low-level, so read this part of the documentation well,
/// it will explain everything you need to know (and check). The user is encouraged
/// to build their own abstraction layer on top of SoA to fit their specific use case,
/// ensuring maximum performance.
///
/// ## Struct fields
///
/// Struct fields are added in the initialization of the SoA.
/// ```
/// var soa = SoA(
///     Fields()
///         .field(Int.self)
///         .field(UnsafeBufferPointer<MyClass>.self)
///         .field(String.self)
/// )
/// ```
/// 
/// ## Capacity
///
/// An initial capacity can be specified at initialization (default = 32)
/// ```
/// var soa = Soa(
///     Fields().field(Int.self),
///     initialCapacity: 64   
/// )
/// ```
///
/// The capacity is the amount of elements of each field the SoA can hold at a time.
///
/// Always make sure you're not adding elements past the current capacity.
/// ``` 
/// let currentCapacity = soa.capacity // Read the current capacity
/// soa.capacity = 128 // Increase the current capacity
/// // Always make sure the new capacity is bigger than the old capacity
/// ```
///
/// ## Adding elements
///
/// Elements that are added to the SoA should be stack-allocated and have a fixed byte size.
/// e.g. Int, Float, Pointers, ...
///
/// When allocating reference types or variables with a variable lenght in bytes (e.g. classes),
/// a pointer is required. One exception is strings, when using `soa.set(Int, at: Int, str: String)`,
/// SoA will copy the string to a new memory address and manage the pointer.
/// ```
/// var soa = SoA (
///     Field().field(UnsafeBufferPointer<T>.self)
/// )
/// soa.set(0, at: 0, ptr: myPtr) // Here, you have to manually deallocate the pointer
/// // Here, the pointer will be deallocated when the index in the SoA is overridden,
/// // or when the SoA goes out of scope
/// soa.set(0, at: 0, managedPtr: mySecondPtr) 
///
/// soa.getBufPtr(0, at: 0)
/// soa.getBufPtr(0, at: 1)
/// ```
///
/// ## Retrieving elements
///
/// Take the following fields:
/// ```
/// Fields()
///     .field(Int.self)
///     .field(String.self)
/// ```
/// 
/// We can get the first value of the Int field array using `soa.get(0, at: 0)`.
/// We can get the second value of the Int field array using `soa.get(0, at: 1)`.
/// We can get the first value of the String field array using `soa.get(0, at: 0)`.
public struct SoA {
    /// Sizes of all the elements according to their index
    @usableFromInline var sizes: ContiguousArray<Int>
    /// Array holding all element data
    @usableFromInline var arr: ContiguousArray<UInt8> 
    /// The current amount of elements of each type the array can hold
    ///
    /// Increase the capacity by changing this value, but make sure the new
    /// capacity is bigger than the the old value
    @inlinable public var capacity: Int {
        get { self.cap }
        set {
            self.resize(cap: newValue)
            self.cap = newValue
        }
    }
    /// current capacity of the array
    @usableFromInline var cap: Int
    /// indices of each element in the array
    @usableFromInline var indices: ContiguousArray<Int>
    @usableFromInline var ptrManager: SoAPointerManager
    
    public init(_ fields: Fields, initialCapacity: Int = 32) {
        self.arr = ContiguousArray<UInt8>(
            repeating: 0,
            count: fields.sizes.reduce(0) { result, size in
                result + size * initialCapacity
            }
        )
        self.sizes = fields.sizes
        self.cap = initialCapacity
        self.indices = []
        self.indices.reserveCapacity(self.sizes.count)
        var arrIdx = 0
        for size in self.sizes {
            self.indices.append(arrIdx)
            arrIdx += size * initialCapacity
        }
        self.ptrManager = SoAPointerManager()
        
        // print("Sizes:", self.sizes)
    }
    
    /// Resize the array to a new capacity
    @inlinable internal mutating func resize(cap newCap: Int) {
        var totalCapacity = 0
        // TODO: with SIMD
        for size in self.sizes {
            totalCapacity += size * newCap
        }
        
        var newArr = ContiguousArray<UInt8>(repeating: 0, count: totalCapacity)
        var newIdx = 0
        var oldIdx = 0
        for (typeId, size) in self.sizes.enumerated() {
            // Copy elements to `newArr`
            let oldIdx2 = size * self.cap
            // newArr.insert(contentsOf: self.arr[oldIdx..<oldIdx2], at: newIdx)
            newArr.replaceSubrange(newIdx..<size * newCap, with: self.arr[oldIdx..<oldIdx2])
            
            // map new index
            self.indices[typeId] = newIdx

            // Calculate indexes for the next element
            oldIdx = oldIdx2
            newIdx = size * newCap
        }
        
        self.arr = newArr
    }
}
