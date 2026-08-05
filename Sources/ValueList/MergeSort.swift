//
//  MergeSort.swift
//  ValueList
//
//  Copyright (c) 2026 Dan Kogai. All rights reserved.
//

// A stable merge sort that needs nothing but sequential access — no
// subscripts, no Array buffering. Elements are dealt into singleton
// runs (a VList of VLists), then adjacent runs are merged in passes
// until one remains: O(n log n) comparisons, iterative throughout.
// Ties are taken from the left run, so equal elements keep their order.

/// Merges two sorted runs into one, left-biased for stability.
fileprivate func merge<T>(
    _ lhs: VList<T>, _ rhs: VList<T>,
    by areInIncreasingOrder: (T, T) throws -> Bool
) rethrows -> VList<T> {
    var result = VList<T>()
    var lhs: VList<T>? = lhs.isEmpty ? nil : lhs
    var rhs: VList<T>? = rhs.isEmpty ? nil : rhs
    while let l = lhs?.car, let r = rhs?.car {
        if try areInIncreasingOrder(r, l) {
            result.prepend(r)
            rhs = rhs?.cdr
        } else {
            result.prepend(l)
            lhs = lhs?.cdr
        }
    }
    while let l = lhs?.car {
        result.prepend(l)
        lhs = lhs?.cdr
    }
    while let r = rhs?.car {
        result.prepend(r)
        rhs = rhs?.cdr
    }
    result.reverse()
    return result
}

extension Sequence {
    /// Stable merge sort of any sequence, delivered as a VList —
    /// a linked list is all merge sort ever needs.
    public func mergeSorted(
        by areInIncreasingOrder: (Element, Element) throws -> Bool
    ) rethrows -> VList<Element> {
        var runs = VList<VList<Element>>()
        for element in self {
            runs.prepend(VList(car: element))
        }
        runs.reverse()
        while runs.cdr != nil {
            var merged = VList<VList<Element>>()
            var iterator = runs.makeIterator()
            while let first = iterator.next() {
                if let second = iterator.next() {
                    merged.prepend(try merge(first, second, by: areInIncreasingOrder))
                } else {
                    merged.prepend(first)
                }
            }
            merged.reverse()
            runs = merged
        }
        return runs.car ?? VList()
    }
}
extension Sequence where Element: Comparable {
    public func mergeSorted() -> VList<Element> {
        return mergeSorted(by: <)
    }
}
