public struct UnsafeSoAString {
    @usableFromInline var bufPtr: UnsafeSoASliceBufPtr<CChar>

    @inlinable internal init(_ p: UnsafeSoASliceBufPtr<CChar>) {
        self.bufPtr = p
    }
    
    @inlinable public subscript(_ idx2: Int) -> String {
        get {
            let buffer: UnsafeBufferPointer<CChar> = self.bufPtr[idx2]
            return String(cString: buffer.baseAddress.unsafelyUnwrapped)
        }
        set {
            let buffer: UnsafeMutableRawBufferPointer = newValue.utf8CString.withUnsafeBytes { (buffer) -> UnsafeMutableRawBufferPointer in 
                let copy = UnsafeMutableRawBufferPointer.allocate(
                    byteCount: buffer.count,
                    alignment: MemoryLayout<CChar>.alignment
                )
                copy.copyMemory(from: buffer)
                return copy
            }
            
            // self.set(idx, at: idx2, managedPtr: UnsafeRawBufferPointer(buffer))
            self.bufPtr[managedPtr: idx2] = UnsafeBufferPointer(buffer.bindMemory(to: CChar.self))
        }
    }
}

public struct UnsafeSoASliceBufPtr<Element> {
    @usableFromInline let startIdx: Int
    /// Size of the element in bytes
    @usableFromInline let ptr: UnsafeMutableBufferPointer<UInt8>
    @usableFromInline let ptrManager: SoAPointerManager
    
    @inlinable internal init(start: Int, ptr: UnsafeMutableBufferPointer<UInt8>, manager: SoAPointerManager) {
        self.startIdx = start
        self.ptr = ptr
        self.ptrManager = manager
    }

    @inlinable internal mutating func set(at idx2: Int, ptr element: UnsafeBufferPointer<Element>/*UnsafeRawBufferPointer*/) {
        let startIdx = self.startIdx + idx2 * __ptrSize2x //self.sizes[idx]
        let startIdxOfSize = startIdx + __ptrSize
        withUnsafeBytes(of: element.baseAddress.unsafelyUnwrapped) { bytes in
            // self.arr.replaceSubrange(startIdx..<startIdxOfSize, with: $0)
            UnsafeMutableRawBufferPointer(start: self.ptr.baseAddress.unsafelyUnwrapped + startIdx, count: bytes.count)
                .copyMemory(from: bytes)
        }
    
        withUnsafeBytes(of: element.count.bigEndian) { bytes in
            // self.arr.replaceSubrange(startIdxOfSize..<startIdxOfSize + __ptrSize, with: $0)
            UnsafeMutableRawBufferPointer(start: self.ptr.baseAddress.unsafelyUnwrapped + startIdxOfSize, count: bytes.count)
                .copyMemory(from: bytes)
        }
    }
    
    @inlinable public subscript(_ idx2: Int) -> UnsafeBufferPointer<Element> {
        @inlinable get {
            let startIdx = self.startIdx + idx2 * __ptrSize2x
            let startIdxOfSize = startIdx + __ptrSize
            let ptr: UnsafePointer<Element> = Array(self.ptr[startIdx..<startIdxOfSize]).withUnsafeBytes { $0.load(as: UnsafePointer<Element>.self) }
            let count = self.ptr[startIdxOfSize..<startIdxOfSize + __ptrSize].reduce(0) { last, current in
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
        @inlinable set {
            self.set(at: idx2, ptr: newValue)
            self.ptrManager.dealloc(startIdx)
        }
    }
    
    @inlinable public subscript(managedPtr idx2: Int) -> UnsafeBufferPointer<Element> {
        @available(*, unavailable, message: "subscript(managedPtr: Int) is unavailable")
        get { fatalError() }
        @inlinable set {
            self.set(at: idx2, ptr: newValue)
            self.ptrManager.manage(startIdx, UnsafeRawBufferPointer(newValue))
        }
    }
    
    /// Don't check for previous pointers to deallocate
    @inlinable public subscript(unmanaged idx2: Int) -> UnsafeBufferPointer<Element> {
        @available(*, unavailable, message: "subscript(unmanaged: Int) is unavailable")
        get { fatalError() }
        @inlinable set {
            self.set(at: idx2, ptr: newValue)
        }
    }
}

public struct UnsafeSoASlice<Element> {
    @usableFromInline let startIdx: Int
    /// Size of the element in bytes
    @usableFromInline let size: Int
    @usableFromInline let ptr: UnsafeMutableBufferPointer<UInt8>
    
    @inlinable internal init(start: Int, size: Int, ptr: UnsafeMutableBufferPointer<UInt8>) {
        self.startIdx = start
        self.size = size
        self.ptr = ptr
    }
    
    @inlinable public subscript(_ idx2: Int) -> Element {
        @inlinable get {
            (self.ptr.baseAddress.unsafelyUnwrapped + startIdx + idx2 * self.size)
                .withMemoryRebound(to: Element.self, capacity: 1) { $0.pointee }
        }
        @inlinable set {
            withUnsafeBytes(of: newValue) { bytes in
                UnsafeMutableRawBufferPointer(start: self.ptr.baseAddress.unsafelyUnwrapped + self.startIdx + idx2 * size, count: bytes.count)
                    .copyMemory(from: bytes)
            }
        }
    }
}

extension SoA {
    @inlinable public mutating func slice<T>(_ idx: Int, _ fun: (UnsafeSoASlice<T>) -> ()) {
        self.arr.withUnsafeMutableBufferPointer { ptr in
            fun(
                UnsafeSoASlice(
                    start: self.indices[idx],
                    size: MemoryLayout<T>.size,
                    ptr: ptr
                )
            )
        }
    }

    @inlinable public mutating func slice<T>(_ idx: Int, _ fun: (UnsafeSoASliceBufPtr<T>) -> ()) {
        self.arr.withUnsafeMutableBufferPointer { ptr in
            fun(
                UnsafeSoASliceBufPtr(
                    start: self.indices[idx],
                    ptr: ptr,
                    manager: self.ptrManager
                )
            )
        }
    }

    @inlinable public mutating func slice(_ idx: Int, _ fun: (UnsafeSoAString) -> ()) {
        self.arr.withUnsafeMutableBufferPointer { ptr in
            fun(
                UnsafeSoAString(
                    UnsafeSoASliceBufPtr(
                        start: self.indices[idx],
                        ptr: ptr,
                        manager: self.ptrManager
                    )
                )
            )
        }
    }
}
