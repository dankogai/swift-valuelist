[![build status](https://github.com/dankogai/swift-valuelist/actions/workflows/swift.yml/badge.svg)](https://github.com/dankogai/swift-valuelist/actions/workflows/swift.yml)

# swift-valuelist

Lisp lists with Swift value semantics — no classes, no reference counting surprises. Two types:

- **`VCons`** — the faithful cons cell. Cars can hold atoms or nested sublists, cdrs can be dotted, holes are allowed. `(1 (2 3) . 4)` is a value you can build, print, and compare.
- **`VList`** — the ergonomic proper list. Element-typed, never improper, and compatible with `Array` (performance aside): subscripts, ranges, literals, `map`/`filter`, the removal family.

Both are structs. Copies are independent; mutation never leaks across variables:

```swift
let original = VList(1, 2, 3)
var copy = original
copy[0] = 100
original  // (1 2 3) — untouched
copy      // (100 2 3)
```

## Synopsis

```swift
import ValueList

// VList — feels like Array, prints like Lisp
var list: VList = [1, 2, 3]        // (1 2 3)
list.prepend(0)                    // (0 1 2 3), O(1)
list.append(4)                     // (0 1 2 3 4)
list[1...2]                        // (1 2)
list.filter { $0 > 1 }.map { $0 * 10 }.sorted()  // (20 30 40)

// VCons — cars hold atoms or sublists
let tree = VCons<Int>(1, VCons(2, 3), 4)   // (1 (2 3) 4)
tree[1].pair?[0].atom              // Optional(2)
tree.atoms()                       // (1 2 3 4) as a VList
VCons(car: .Atom(1), cdr: .Atom(2))  // (1 . 2), a dotted pair
```

## Usage

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/dankogai/swift-valuelist.git", branch: "main"),
],
```

and `import ValueList`. Requires Swift 6. The bundled `macOS.playground` walks through both types interactively — open the package in Xcode and pick a page.

## `VList<Element>`

A proper, singly-linked list of `Element`, built from `car`/`cdr` cells with the recursion heap-boxed behind the scenes.

### Building

```swift
VList(1, 2, 3)          // variadic
VList([1, 2, 3])        // from an Array
VList(1...3)            // from any Sequence
let literal: VList = [1, 2, 3]
VList<Int>()            // the empty list, ()
VList(car: 1, cdr: VList(car: 2))  // cell by cell
```

### Lisp face

```swift
let list = VList(1, 2, 3)
list.car          // Optional(1) — nil iff empty
list.cdr          // Optional((2 3)) — nil when empty or single
list.description  // "(1 2 3)"; the empty list prints ()
var grown = list
grown.prepend(0)  // (0 1 2 3) — O(1), the natural growth direction
grown.reverse()   // (3 2 1 0) in place; reversed() for a copy
```

### Array face

`VList` conforms to `Sequence`, `Collection`, `Equatable`/`Hashable` (when `Element` does), `CustomStringConvertible`, and `ExpressibleByArrayLiteral`. Everything `Collection` derives — `count`, `first`, `contains`, `firstIndex(of:)`, `min`/`max`, `dropFirst`, `prefix`/`suffix`, `reduce` — comes for free. On top of that:

```swift
var list = VList(1, 2, 3)
list[1]                  // 2 — O(position)
list[1] = 20             // in place
list[1...]               // (20 3)
list[0..<2] = VList(9)   // replaceSubrange semantics: (9 3)
list.append(4)           // also append(contentsOf:), + and +=
list.last                // Optional(4)
list.removeFirst()       // 9
list.remove(at: 1)       // 4
list.removeAll()         // ()
```

Transformations return `VList`, so chains never leave the type — while the `Array`-returning `Sequence` versions stay reachable when the context asks:

```swift
VList(5, 3, 1, 4, 2).filter { $0 > 1 }.map { $0 * 10 }.sorted()  // (20 30 40 50)
let asArray: [Int] = VList(1, 2, 3).map { $0 * 2 }               // [2, 4, 6]
[3, 1, 2].mergeSorted()   // (1 2 3) — any Sequence sorts into a VList
```

## `VCons<Element>`

The real thing: a cell whose `car` and `cdr` each hold an optional `Node` — `.Atom(Element)` or `.Pair(VCons)`. That representation admits everything Lisp's does: nested sublists, dotted pairs, holes.

### Building

```swift
VCons(1, 2, 3)                       // (1 2 3)
VCons<Int>(1, VCons(2, 3), 4)        // (1 (2 3) 4) — mixed needs the type spelled out
VCons(VCons(1, 2), VCons(3, 4))      // ((1 2) (3 4)) — inferred as VCons<Int>
VCons(car: .Atom(1), cdr: .Atom(2))  // (1 . 2)
VCons<Int>()                         // ()
```

### Nodes, unwrapped with `.atom` and `.pair`

Iteration and subscripts yield `Node`; the two accessors take it from there:

```swift
let tree = VCons<Int>(1, VCons(2, 3), 4)
tree[0].atom            // Optional(1)
tree[1].pair            // Optional((2 3))
tree[1].pair?[0].atom   // Optional(2)
tree.compactMap { $0.atom }  // [1, 4] — top-level atoms
tree.atoms()            // (1 2 3 4) — every leaf, flattened into a VList
```

### Growing and slicing

```swift
var list = VCons(2, 3)
list.prepend(.Atom(1))              // (1 2 3)
list.append(4)                      // (1 2 3 4)
list.append(VCons(5, 6))            // (1 2 3 4 (5 6)) — a sublist
list.append(contentsOf: VCons(7))   // splices: (... (5 6) 7)
VCons(1, 2) + VCons(3, 4)           // (1 2 3 4)
VCons(0, 1, 2, 3)[1..<3]            // (1 2); setters resize like Array
VCons(1, 2, 3).reversed()           // (3 2 1) — cell-preserving
```

Positions count elements the way iteration does: `nil` cars are skipped and an atom cdr ends the walk, so `(1 . 2)` iterates as just `1` — the dotted tail is reachable via `cdr` (and included by `atoms()`).

## Design notes

- **Value semantics via `indirect enum`.** A struct cannot store itself, so the recursion is heap-boxed through an indirect enum; the box is copied on mutation, never shared observably.
- **Prepend, then reverse.** Spines are built and edited iteratively — `prepend` is O(1), a final `reverse()` restores order, and sources that can be walked backwards (like `Array`) skip even that. No recursion on any spine, so list length never touches the stack; recursion remains only where trees make it inherent (nested sublists in `VCons` cars).
- **Costs are what a linked list costs.** `count`, positional access, and `append` are O(n); `prepend` is O(1). Even `sorted()` stays in the family: a stable bottom-up merge sort over the cells themselves (`MergeSort.swift`) — sequential access is all merge sort ever needs, so nothing buffers into an `Array`. As a bonus, every `Sequence` gains `mergeSorted(by:)`, delivering its elements sorted into a `VList`.
- **`VList` cannot be improper by construction**; `VCons` can, and its API traps (`preconditionFailure`) rather than misbehaves when an operation meets an improper list it cannot honor — appending to, reversing, or range-subscripting past a dotted tail.

## Benchmarks

"Performance aside" is quantifiable. A standalone executable target compares both types against `Array` — run it locally (CI never does; the workflow only invokes `swift test`):

```bash
swift run -c release Benchmarks
```

Full results and commentary live in [BENCHMARK.md](BENCHMARK.md). The shape in one sentence: `prepend` is the one race a linked list wins (~7× faster than Array's head-insert, which is O(n²) in total), repeated `append` is the one to avoid (quadratic — build with an init or `append(contentsOf:)` instead), and everything else costs a few hundred× — the price of a heap cell per element versus a contiguous buffer.

## License

[MIT](LICENSE). Copyright (c) 2026 Dan Kogai.
