# SoA

A struct of arrays implementation in pure Swift.

## Usage

Add to your `package.swift` in the dependencies:

```swift
.package(url: "https://github.com/jomy10/swift-soa", .branch("master"))
```

Add to your `Package.swift` in a target's dependency:

```swift
.package(name: "SoA", package: "soa-swift")
```

### New SoA intance 

Initialize a `Soa` instance with an initial capacity of 32 elements.
```swift
let soa = SoA(
  Fields()
    .field(Int.self)
    .field(String.self)
)
```

### Changing array capacity

When you want to add more elements than the current capacity of the `SoA` (`soa.capacity`), you
need to resize it first.

```swift
soa.capacity = soa.capacity * 2
```

### Adding elements

When adding elements, you should always make sure you're not adding more elements than the capacity
allows.

```swift
var soa = SoA(
  Fields().field(Int.self)
)
let idx = 5 // element 5 in array 0 (field 0)
if idx < soa.capacity {
  soa.set(0, at: idx, 69)
} else {
  // resize first
}
```

### Retrieving elements

```swift
soa.get(0, at: idx)
```

### Non-primitive types

If you want to add types like classes to the struct of array, you will have to convert them to a pointer first.

For String types, you can use the designated string functions.

```swift
soa.get(1, at: 0) as String?
soa.set(1, at: 0, str: "Hello world")
```

For pointers:

```swift
soa.getBufPtr(1, at: 0)
// set pointer and deallocate previous managed pointer at the specified index
soa.set(1, at: 0, ptr: myPtr)
// set pointer, deallocate previous managed pointer at the specified index,
// and add this pointer to be managed by the `SoA`
soa.set(1, at: 0, managedPtr: myPtr)
// set pointer without trying to deallocate the previous pointer
soa.setUnmanaged(1, at: 0, ptr: myPtr)
```

Strings will always use the `soa.set(Int, at: Int, managedPtr: UnsafeRawBufferPointer)`.

### Looping

Using the `set` method to mutate elements in a loop can be slow, use `slice` instead.

**Primitive types**
```swift
// Slice field 0
soa.slice(0) { (slice: UnsafeSoASlice<Int>) in
  var slice = slice
  slice[0] = 5
  print(slice[0])
}
```

**Pointers**
```swift
soa.slice(0) { (slice: UnsafeSoASliceBufPtr<MyType>) in
  var slice = slice
  // set pointer and deallocate previous
  slice[0] = otherPointer
  // set pointer and deallocate previous and manage this one
  slice[managedPtr: 0] = otherPointer
  // set pointer without trying to deallocate
  slice[unmanaged: 0] = otherPointer
  
  print(slice[0])
}
```

**Strings**
```swift
soa.slice(0) { (slice: UnsafeSoAString) in
  var slice = slice
  slice[0] = "Hello!"
  print(slice[0])
}
```

## Notes

The library is intentionally low-level as it is meant as a "core" library. The user of
the library is encouraged to build their own abstraction layer on top of this library.

## Running tests

```bash
swift test
```

## Running benchmarks

```bash
./bench.sh
```

## License

The library is licensed under the [GNU LGPL3.0](LICENSE).
