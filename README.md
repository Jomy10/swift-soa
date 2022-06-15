# SoA

A struct of arrays implementation in Swift using pointers.

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

```swift
let soa = SoA()
```

### Adding a new field

```swift
// a new array of type Int
soa.newArray(Int.self)
```

#### Getting a field

```swift
/// Get the array we just added
let fields: UnsafeMutableBufferPointer<Int> = soa[0]
```

### Changing array capacity

Because these are implemented as pointers, when you want to add more elements to the array
so that the amount of element would exceed the current array capacity (`soa.currentCapacity`),
you'll first have to increase the capacity.

```swift
/// Double the array's capacity
soa.realloc()
```

## Notes

The library is intentionally simple and low-level as it is meant as a "core" library.

## License

The library is licensed under the [GNU LGPL3.0](LICENSE).
