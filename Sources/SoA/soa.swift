@usableFromInline
internal typealias Arr = ContiguousArray

/// Holds all arrays
public final class SoA {
    /// Initial capacity for arrays
    @inlinable public var initialCapacity: Int {
        get { self.initCap }
    }
    @usableFromInline internal var initCap: Int = 32

    /// The current capacity of the arrays
    @inlinable public var currentCapacity: Int {
        get { self.curCap }
    }
    @usableFromInline internal var curCap: Int = 32

    /// `void **` holding all arrays
    @usableFromInline internal var arrs: Arr<UnsafeMutableRawPointer>

    @usableFromInline internal var types: Arr<Any.Type>

    @inlinable public var allTypes: ContiguousArray<Any.Type> {
        get { self.types }
    }

    public init() {
        self.arrs = []
        self.types = []
    }

    public init(withIitialCapacity cap: Int) {
        self.initCap = cap
        self.curCap = cap
        self.arrs = []
        self.types = []
    }

    deinit {
        for i in 0..<self.arrs.count {
            self.arrs[i].deallocate()
        }
    }

    /// Add a new array to the struct of arrays with type T
    ///
    /// Returns the index of the new array
    @discardableResult
    public func newArray<T>(_ type: T.Type) -> Int {
        let buffer = UnsafeMutableBufferPointer<T?>.allocate(capacity: self.curCap)
        _ = buffer.initialize(repeating: nil)
        self.arrs.append(buffer.baseAddress!)
        self.types.append(T.self)
        return self.arrs.count - 1
    }

    /// make sure to initialize the array with this SoA object's initial capactiy
    public func unsafeNewArray<T>(_ arr: UnsafeMutablePointer<T?>) {
        self.arrs.append(&arr.pointee)
        self.types.append(T.self)
    }

    /// Get an array and cast to type `T`
    @inlinable
    public func unsafeGetArray<T>(withIndex index: Int) -> UnsafeMutableBufferPointer<T?> {
        return UnsafeMutableBufferPointer(start: self.arrs[index].bindMemory(to: Optional<T>.self, capacity: self.curCap), count: self.curCap)
    }

    /// Get an immutable pointer to the array with the specified index and type `T`
    public func unsafeGetArray<T>(withIndex index: Int) -> UnsafeBufferPointer<T?> {
        return UnsafeBufferPointer(start: self.arrs[index].bindMemory(to: Optional<T>.self, capacity: self.curCap), count: self.curCap)
    }

    @inlinable
    public subscript<T>(_ index: Int) -> UnsafeMutableBufferPointer<T?> {
        get {
            self.unsafeGetArray(withIndex: index)
        }

        set(newVal) {
            self.setArray(withIndex: index, newVal.baseAddress!)
        }
    }

    public func value<T>(of arrayIndex: Int, at elementIndex: Int) -> T {
        (self.unsafeGetArray(withIndex: arrayIndex) as UnsafeMutableBufferPointer<T?>)[elementIndex].unsafelyUnwrapped
    }

    /// Increase the array's capaciy by two
    @inlinable public func realloc() {
        for i in 0..<self.arrs.count {
            self.reallocArray(withIndex: i, type: self.types[i], newCapacity: self.curCap * 2)
        }

        self.curCap *= 2
    }

    /// Unsafe because capacity needs to be higher than current capacity
    @inlinable public func realloc(withUnsafeCapacity cap: Int) {
        for i in 0..<self.arrs.count {
            self.reallocArray(withIndex: i, type: self.types[i], newCapacity: cap)
        }
        self.curCap = cap
    }

    /// Reallocate a specific array with a specific amount of capacity
    @usableFromInline internal func reallocArray<T>(withIndex index: Int, type: T, newCapacity size: Int) {
        let buffer: UnsafeMutableBufferPointer<T?> = self.unsafeGetArray(withIndex: index)
        var curArr: [T?] = Array(buffer)
        curArr += Array<T?>(repeating: nil, count: curArr.count - size)

        var newBuffer = UnsafeMutableBufferPointer<T?>.allocate(capacity: size)
        _ = newBuffer.initialize(from: curArr)

        self.setArray(withIndex: index, &newBuffer)
    }

    @inlinable internal func setArray(withIndex index: Int, _ ptr: UnsafeMutableRawPointer) {
        self.arrs[index] = ptr
    }
}
