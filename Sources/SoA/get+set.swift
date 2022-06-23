@usableFromInline internal let __ptrSize = MemoryLayout<Int>.size
@usableFromInline internal let __ptrSize2x = __ptrSize * 2

extension SoA {
    //============================================
    // General
    //============================================

    /// Insert a primitive type `element` in array `idx` at position `idx2`
    @inlinable public mutating func set<T>(_ idx: Int, at idx2: Int, _ element: T) {
        #if DEBUG
        if T.self == String.self {
            fatalError("Don't use `set(_ idx: Int, at idx2: Int, _ element: T)` for String types or other non-stack-allocated types. Use the specific set metheod `set(_ idx: Int, at idx2: Int, str element: Int)` instead.")
        }
        #endif
        // let size = MemoryLayout<T>.size
        let startIdx = self.indices[idx] + idx2 * MemoryLayout<T>.size // size
        self.arr.withUnsafeMutableBufferPointer { ptr in
            withUnsafeBytes(of: element) { bytes in
                // self.arr.replaceSubrange(startIdx..<startIdx + size, with: ptr)
                UnsafeMutableRawBufferPointer(start: ptr.baseAddress.unsafelyUnwrapped + startIdx, count: bytes.count)
                    .copyMemory(from: bytes)
            }
        }
    }
     
    /// Get a pointer to the primitive type
    @inlinable public func get<T>(_ idx: Int, at idx2: Int, _ fun: (UnsafePointer<T>) -> ()) {
        #if DEBUG
        if T.self == String.self || T.self == String?.self {
            fatalError("Strings can't be retrieved using `get(_ idx: Int, at idx2: Int, _ fun: (UnsafePointer<T>) -> ())`, use either `get(_ idx: Int, at idx2: Int, _ func: (UnsafeMutableBufferPointer<CChar>) -> ())` or `get(_ idx: Int, at idx2: Int) -> String?`")
        }
        #endif
        self.arr.withUnsafeBufferPointer { buffer in
            (buffer.baseAddress.unsafelyUnwrapped + self.indices[idx] + idx2 * MemoryLayout<T>.size) // * self.sizes[idx])
                .withMemoryRebound(to: T.self, capacity: 1) { fun($0) }
        }
    }
    
    /// Get a primitive type
    @inlinable public func get<T>(_ idx: Int, at idx2: Int) -> T {
        #if DEBUG
        if T.self == String.self || T.self == String?.self {
            fatalError("Function `get(_ idx: Int, at idx2: Int) -> String?` needs an explicit case to `String?`")
        }
        #endif
        return self.arr.withUnsafeBufferPointer { buffer in
            return (buffer.baseAddress.unsafelyUnwrapped + self.indices[idx] + idx2 * MemoryLayout<T>.size)
                .withMemoryRebound(to: T.self, capacity: 1) { $0.pointee }
        }
    }
    
    //============================================
    // Buffer pointers
    //============================================
    
    @inlinable internal mutating func set(_ idx: Int, at idx2: Int, ptr element: UnsafeRawBufferPointer, start startIdx: Int) {
        let startIdxOfSize = startIdx + __ptrSize
        self.arr.withUnsafeMutableBufferPointer { buffer in
            withUnsafeBytes(of: element.baseAddress.unsafelyUnwrapped) { bytes in
                // self.arr.replaceSubrange(startIdx..<startIdxOfSize, with: $0)
                UnsafeMutableRawBufferPointer(start: buffer.baseAddress.unsafelyUnwrapped + startIdx, count: bytes.count)
                    .copyMemory(from: bytes)
            }
        
            withUnsafeBytes(of: element.count.bigEndian) { bytes in
                // self.arr.replaceSubrange(startIdxOfSize..<startIdxOfSize + __ptrSize, with: $0)
                UnsafeMutableRawBufferPointer(start: buffer.baseAddress.unsafelyUnwrapped + startIdxOfSize, count: bytes.count)
                    .copyMemory(from: bytes)
            }
        }
    }

    /// Set the element at `idx2` in array `idx` to be a pointer `element`.
    @inlinable public mutating func set(_ idx: Int, at idx2: Int, ptr element: UnsafeRawBufferPointer) {
        let startIdx = self.indices[idx] + idx2 * __ptrSize2x //self.sizes[idx]
        self.set(idx, at: idx2, ptr: element, start: startIdx)
        self.ptrManager.dealloc(startIdx)
    }
    
    /// Will not try to deallocate the previous pointer
    @inlinable public mutating func setUnmanaged(_ idx: Int, at idx2: Int, ptr element: UnsafeRawBufferPointer) {
        let startIdx = self.indices[idx] + idx2 * __ptrSize2x //self.sizes[idx]
        self.set(idx, at: idx2, ptr: element, start: startIdx)
    }
    
    /// Set the element at `idx2` in array `idx` to be a pointer `element`.
    /// Automatically deallocate the pointer when it is no longer used
    @inlinable public mutating func set(_ idx: Int, at idx2: Int, managedPtr element: UnsafeRawBufferPointer) {
        let startIdx = self.indices[idx] + idx2 * __ptrSize2x
        self.set(idx, at: idx2, ptr: element, start: startIdx)
        self.ptrManager.manage(startIdx, element)
    }

    /// Get the buffer pointer in the array `idx` at position `idx2`.
    @inlinable public func getBufPtr<T>(_ idx: Int, at idx2: Int) -> UnsafeBufferPointer<T> {
        let startIdx = self.indices[idx] + idx2 * __ptrSize2x
        let startIdxOfSize = startIdx + __ptrSize
        let ptr: UnsafePointer<T> = self.arr[startIdx..<startIdxOfSize].withUnsafeBytes { $0.load(as: UnsafePointer<T>.self) }
        let count = self.arr[startIdxOfSize..<startIdxOfSize + __ptrSize].reduce(0) { last, current in
            var last = last
            last = last << __ptrSize
            last = last | Int(current)
            return last
        }
        return UnsafeBufferPointer(
            start: ptr,
            count: count
        )
    }
    
    //============================================
    // Strings
    //============================================
    
    /// Set a string `element` in array `idx` at `idx2`
    @inlinable public mutating func set(_ idx: Int, at idx2: Int, str element: String) {
        let buffer: UnsafeMutableRawBufferPointer = element.utf8CString.withUnsafeBytes { buffer in 
            let copy = UnsafeMutableRawBufferPointer.allocate(
                byteCount: buffer.count,
                alignment: MemoryLayout<CChar>.alignment
            )
            copy.copyMemory(from: buffer)
            return copy
        }
        self.set(idx, at: idx2, managedPtr: UnsafeRawBufferPointer(buffer))
    }
    
    /// Get a string element
    @inlinable public func get(_ idx: Int, at idx2: Int) -> String? {
        let buffer: UnsafeBufferPointer<CChar> = self.getBufPtr(idx, at: idx2)
        return String(cString: buffer.baseAddress.unsafelyUnwrapped)
    }
    
    /// Get a pointer to a string
    @inlinable public func get(_ idx: Int, at idx2: Int, _ fun: (UnsafeBufferPointer<CChar>) -> ()) {
        let buffer: UnsafeBufferPointer<CChar> = self.getBufPtr(idx, at: idx2)
        fun(buffer)
    }
}
