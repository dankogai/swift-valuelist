# Benchmark results

How slow are `VList` and `VCons` against `Array`? Measured, not guessed.

Reproduce locally (CI never runs this — the workflow only invokes `swift test`):

```bash
swift run -c release Benchmarks
```

An optional argument overrides n, e.g. `swift run -c release Benchmarks 100000`.

## Environment

- Apple M1, macOS 26.6
- Swift 6.3.3, release build (`-c release`)
- n = 10 000; operations that are O(n²) on a linked list are capped at n = 1 000
- Best of 3 runs per measurement

## Results

```
operation                       n    Array          VList     ×/Arr      VCons     ×/Arr
--------------------------------------------------------------------------------------------
build from Sequence         10000     0.014ms     7.274ms   518.1×     3.704ms   263.8×
grow at the head ×n         10000     6.977ms     1.053ms     0.2×     1.006ms     0.1×
append ×n                    1000     0.004ms   237.522ms 56445.5×   122.664ms 29150.1×
iterate and sum             10000     0.000ms     1.341ms        —     0.119ms        —
subscript sweep [0..<n]      1000     0.000ms    25.435ms        —    21.951ms        —
map { $0 + 1 }              10000     0.052ms     5.100ms    98.6×            —         —
reversed                    10000     0.005ms     2.529ms   518.7×     1.847ms   378.8×
sorted                      10000     0.169ms    87.721ms   519.3×    88.816ms   525.8×
```

A `—` in a ratio column means `Array`'s time rounded to 0.000ms — the optimizer
vectorizes a 10 000-int sum or bounds-checked sweep into nothing measurable —
so a ratio would be meaningless. A `—` in a time column means the operation has
no direct counterpart (`VCons.map` yields `Node`s via `Sequence`, not a `VCons`).

## Reading the numbers

- **The lists win exactly one race: growing at the head.** `prepend` is a true
  O(1); `Array.insert(at: 0)` shuffles the entire buffer every call, quadratic
  in total. At n = 10 000 the lists are ~7× *faster*, and the gap widens with n.
- **The disaster case is repeated `append`**: an O(n) walk per call makes the
  loop quadratic — ~56 000× at just n = 1 000. Build with an initializer or
  `append(contentsOf:)` instead of element-by-element appends.
- **Everything else sits in the expected band** (~100–520×): the price of one
  heap-boxed cell per element — allocation, pointer chasing, ARC — against a
  contiguous buffer the CPU prefetches for free.
- `sorted` costs ~520× despite being the same O(n log n) as `Array.sorted` —
  the constant factor is cell churn: each merge pass allocates fresh cells,
  where `Array` sorts in place.

Numbers are from one machine on one day; treat them as orders of magnitude,
not gospel.
