//
//  VList.swift
//  ValueList
//
//  Created by Dan Kogai on 2026-07-29.
//
//  Copyright (c) 2026 Dan Kogai. All rights reserved.
//

public struct VList<Element> {
    /// A struct cannot store itself — its size would be infinite — and
    /// `indirect` exists only for enums, so the cell is heap-boxed here;
    /// .Nil doubles as the empty list. Value semantics are preserved.
    private indirect enum Node {
        case Nil
        case Cell(car: Element, cdr: VList<Element>)
    }
    private var node: Node = .Nil
    /// The empty list.
    public init() {}
    public init(car: Element, cdr: Self? = nil) {
        node = .Cell(car: car, cdr: cdr ?? Self())
    }
    public var isEmpty: Bool {
        if case .Nil = node { return true } else { return false }
    }
    /// nil iff the list is empty.
    public var car: Element? {
        get {
            if case .Cell(let car, _) = node { return car }
            return nil
        }
        set {
            switch (newValue, node) {
            case (nil, _):
                node = .Nil     // removing the car drops the tail with it
            case (let car?, .Cell(_, let cdr)):
                node = .Cell(car: car, cdr: cdr)
            case (let car?, .Nil):
                node = .Cell(car: car, cdr: Self())
            }
        }
    }
    /// nil when the list is empty or has a single element.
    public var cdr: Self? {
        get {
            if case .Cell(_, let cdr) = node, !cdr.isEmpty { return cdr }
            return nil
        }
        set {
            guard case .Cell(let car, _) = node else {
                preconditionFailure("an empty VList has no cdr")
            }
            node = .Cell(car: car, cdr: newValue ?? Self())
        }
    }
}
extension VList {
    /// O(1) — the natural way to grow a linked list.
    public mutating func prepend(_ element: Element) {
        self = .init(car: element, cdr: self)
    }
    public func prepending(_ element: Element) -> Self {
        var copy = self
        copy.prepend(element)
        return copy
    }
    /// One pass prepending — reversal is the direction a linked list
    /// naturally builds in.
    public func reversed() -> Self {
        var result = Self()
        for element in self {
            result.prepend(element)
        }
        return result
    }
    /// Like Array's mutating reverse().
    public mutating func reverse() {
        self = reversed()
    }
}
// Building in order without recursion: prepend everything — O(1) each,
// which builds reversed — then reverse once. Two passes of cells, no
// intermediate Array, no unbounded stack.
extension VList {
    /// An empty sequence yields the empty list.
    public init<S: Sequence>(_ elements: S) where S.Element == Element {
        self.init()
        for element in elements {
            prepend(element)
        }
        reverse()
    }
    /// Concrete overload so VList([1, 2, 3]) binds Element to Int —
    /// without it the variadic init would win with Element = [Int].
    /// Builds in a single pass: an Array can be walked backwards, and its
    /// reversed() is a lazy view, so prepending needs no reverse() after.
    public init(_ elements: [Element]) {
        self.init()
        for element in elements.reversed() {
            prepend(element)
        }
    }
    /// VList(1, 2, 3); with no arguments, the empty list.
    public init(_ elements: Element...) {
        self.init(elements)
    }
}
extension VList: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
}
extension VList: CustomStringConvertible {
    /// Lisp notation, e.g. VList(1, 2, 3) prints as (1 2 3); () when empty.
    public var description: String {
        return "(" + self.map { "\($0)" }.joined(separator: " ") + ")"
    }
}
extension VList: Sequence {
    public struct Iterator: IteratorProtocol {
        var list: VList<Element>?
        public mutating func next() -> Element? {
            guard let current = list, let car = current.car else { return nil }
            list = current.cdr
            return car
        }
    }
    public func makeIterator() -> Iterator {
        return Iterator(list: self)
    }
}
extension VList: Collection {
    /// Wraps the remaining list so that index(after:) is O(1);
    /// `offset` orders indices for Comparable, with Int.max as endIndex.
    public struct Index: Comparable {
        fileprivate let offset: Int
        fileprivate let list: VList<Element>?
        public static func ==(lhs: Index, rhs: Index) -> Bool {
            return lhs.offset == rhs.offset
        }
        public static func <(lhs: Index, rhs: Index) -> Bool {
            return lhs.offset < rhs.offset
        }
    }
    public var startIndex: Index {
        return isEmpty ? endIndex : Index(offset: 0, list: self)
    }
    public var endIndex: Index {
        return Index(offset: Int.max, list: nil)
    }
    public subscript(position: Index) -> Element {
        guard let car = position.list?.car else {
            preconditionFailure("index out of bounds")
        }
        return car
    }
    public func index(after i: Index) -> Index {
        guard let list = i.list else {
            preconditionFailure("cannot advance past endIndex")
        }
        guard let next = list.cdr else { return endIndex }
        return Index(offset: i.offset + 1, list: next)
    }
}
// Array compatibility. Only what Sequence/Collection defaults cannot provide:
// contains, firstIndex(of:), min/max, dropFirst, prefix/suffix and friends
// all come for free.
extension VList: Equatable where Element: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.elementsEqual(rhs)
    }
}
extension VList: Hashable where Element: Hashable {
    public func hash(into hasher: inout Hasher) {
        for element in self { hasher.combine(element) }
    }
}
extension VList {
    /// Splits off the first `position` elements, returned in reverse;
    /// `self` becomes the rest. The building block for positional edits:
    /// modify the rest, then prepend the reversed prefix back on.
    private mutating func liftPrefix(_ position: Int) -> Self? {
        var reversedPrefix = Self()
        var remaining = position
        while remaining > 0 {
            guard let car = car else { return nil }
            reversedPrefix.prepend(car)
            self = cdr ?? Self()
            remaining -= 1
        }
        return remaining == 0 ? reversedPrefix : nil
    }
    /// Prepends `reversedPrefix` back, restoring its original order.
    private mutating func restorePrefix(_ reversedPrefix: Self) {
        for element in reversedPrefix {
            prepend(element)
        }
    }
    /// Like Array's last: nil when empty. O(count).
    public var last: Element? {
        guard !isEmpty else { return nil }
        var current = self
        while let next = current.cdr { current = next }
        return current.car
    }
    /// Array-like positional access, O(position); traps out of bounds.
    public subscript(position: Int) -> Element {
        get {
            return self[index(startIndex, offsetBy: position)]
        }
        set {
            guard position >= 0, let reversedPrefix = liftPrefix(position), !isEmpty else {
                preconditionFailure("index out of bounds")
            }
            car = newValue
            restorePrefix(reversedPrefix)
        }
    }
    /// Bounds of `range` within this list, trapping out of bounds like Array.
    private func bounds<R: RangeExpression>(of range: R) -> Range<Int> where R.Bound == Int {
        let count = self.count
        let bounds = range.relative(to: 0..<count)
        precondition(bounds.lowerBound >= 0 && bounds.upperBound <= count,
                     "range out of bounds")
        return bounds
    }
    /// Range subscripting like Array's: list[1..<3], list[1...3], list[1...],
    /// list[..<2], list[...2]. Returns a VList rather than a slice; the setter
    /// replaces the range and may resize, like Array's replaceSubrange.
    /// O(count); traps on out-of-bounds like Array.
    public subscript<R: RangeExpression>(range: R) -> Self where R.Bound == Int {
        get {
            let bounds = self.bounds(of: range)
            return Self(dropFirst(bounds.lowerBound).prefix(bounds.count))
        }
        set {
            let bounds = self.bounds(of: range)
            var result = Self(prefix(bounds.lowerBound))
            result.append(contentsOf: newValue)
            result.append(contentsOf: dropFirst(bounds.upperBound))
            self = result
        }
    }
    public subscript(_: UnboundedRange) -> Self {
        get { return self }
        set { self = newValue }
    }
}
extension VList {
    /// Splices `list` at the end — concatenation, like Array's append(contentsOf:).
    /// Prepends self's elements onto `list` back to front.
    public mutating func append(contentsOf list: Self) {
        guard !list.isEmpty else { return }
        var result = list
        for element in reversed() {
            result.prepend(element)
        }
        self = result
    }
    public mutating func append<S: Sequence>(contentsOf newElements: S) where S.Element == Element {
        append(contentsOf: Self(newElements))
    }
    public mutating func append(_ element: Element) {
        append(contentsOf: Self(car: element))
    }
    /// Concatenates two lists, e.g. (1 2) + (3 4) == (1 2 3 4).
    public static func + (lhs: Self, rhs: Self) -> Self {
        var result = lhs
        result.append(contentsOf: rhs)
        return result
    }
    public static func += (lhs: inout Self, rhs: Self) {
        lhs.append(contentsOf: rhs)
    }
}
// VList-returning transformations. These shadow the Sequence defaults in
// member lookup, so list.map { ... } stays a VList; the Array-returning
// versions remain reachable where the context asks for one, as in
// let a: [Int] = list.map { ... }. All build by prepend-then-reverse:
// in order, no recursion, no intermediate Array.
extension VList {
    public func map<T>(_ transform: (Element) throws -> T) rethrows -> VList<T> {
        var result = VList<T>()
        for element in self {
            result.prepend(try transform(element))
        }
        result.reverse()
        return result
    }
    public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> Self {
        var result = Self()
        for element in self where try isIncluded(element) {
            result.prepend(element)
        }
        result.reverse()
        return result
    }
    public func compactMap<T>(_ transform: (Element) throws -> T?) rethrows -> VList<T> {
        var result = VList<T>()
        for element in self {
            if let transformed = try transform(element) {
                result.prepend(transformed)
            }
        }
        result.reverse()
        return result
    }
    public func flatMap<S: Sequence>(_ transform: (Element) throws -> S) rethrows -> VList<S.Element> {
        var result = VList<S.Element>()
        for element in self {
            for transformed in try transform(element) {
                result.prepend(transformed)
            }
        }
        result.reverse()
        return result
    }
    /// A stable merge sort over the cells themselves (MergeSort.swift) —
    /// sequential access is all a linked list needs.
    public func sorted(by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows -> Self {
        return try mergeSorted(by: areInIncreasingOrder)
    }
}
extension VList where Element: Comparable {
    public func sorted() -> Self {
        return mergeSorted()
    }
}
extension VList {
    /// Like Array's: traps on an empty list.
    @discardableResult
    public mutating func removeFirst() -> Element {
        guard let car = car else {
            preconditionFailure("cannot removeFirst from an empty VList")
        }
        self = cdr ?? Self()
        return car
    }
    /// Like Array's: traps when position is out of bounds.
    @discardableResult
    public mutating func remove(at position: Int) -> Element {
        guard position >= 0, let reversedPrefix = liftPrefix(position), let removed = car else {
            preconditionFailure("index out of bounds")
        }
        self = cdr ?? Self()
        restorePrefix(reversedPrefix)
        return removed
    }
    public mutating func removeAll() {
        self = Self()
    }
}
