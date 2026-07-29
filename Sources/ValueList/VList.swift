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
    /// An empty sequence yields the empty list.
    /// Builds in order in a single pass, one cell per element.
    public init<S: Sequence>(_ elements: S) where S.Element == Element {
        var iterator = elements.makeIterator()
        func build() -> Self? {
            guard let element = iterator.next() else { return nil }
            return Self(car: element, cdr: build())
        }
        self = build() ?? Self()
    }
    /// Concrete overload so VList([1, 2, 3]) binds Element to Int —
    /// without it the variadic init would win with Element = [Int].
    public init(_ elements: [Element]) {
        self.init(elements[...])
    }
    /// VList(1, 2, 3); with no arguments, the empty list.
    public init(_ elements: Element...) {
        self.init(elements[...])
    }
}
extension VList: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Element...) {
        self.init(elements[...])
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
        return lhs.car == rhs.car && lhs.cdr == rhs.cdr
    }
}
extension VList: Hashable where Element: Hashable {
    public func hash(into hasher: inout Hasher) {
        for element in self { hasher.combine(element) }
    }
}
extension VList {
    /// Like Array's last: nil when empty. O(count).
    public var last: Element? {
        guard !isEmpty else { return nil }
        var current = self
        while let next = current.cdr { current = next }
        return current.car
    }
    /// Replaces the car of the `position`-th cell;
    /// returns false when the list is shorter than that.
    private mutating func replaceCar(at position: Int, with element: Element) -> Bool {
        guard !isEmpty else { return false }
        if position == 0 {
            car = element
            return true
        }
        guard var next = cdr else { return false }
        let replaced = next.replaceCar(at: position - 1, with: element)
        cdr = next
        return replaced
    }
    /// Array-like positional access, O(position); traps out of bounds.
    public subscript(position: Int) -> Element {
        get {
            return self[index(startIndex, offsetBy: position)]
        }
        set {
            guard position >= 0, replaceCar(at: position, with: newValue) else {
                preconditionFailure("index out of bounds")
            }
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
    public mutating func append(contentsOf list: Self) {
        guard !list.isEmpty else { return }
        if isEmpty {
            self = list
            return
        }
        if var next = cdr {
            next.append(contentsOf: list)
            cdr = next
        } else {
            cdr = list
        }
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
// let a: [Int] = list.map { ... }.
extension VList {
    /// One pass prepending — reversal is the direction a linked list
    /// naturally builds in, so no extra pass is needed here.
    public func reversed() -> Self {
        var result = Self()
        for element in self {
            result = Self(car: element, cdr: result)
        }
        return result
    }
    // The transformations below recurse down the cdr chain, consing each
    // transformed car onto the recursively built tail: in order, one cell
    // per output element, no reversal pass. Each level applies its closure
    // before recursing so side effects run front-to-back.
    public func map<T>(_ transform: (Element) throws -> T) rethrows -> VList<T> {
        guard let car = car else { return VList<T>() }
        return VList<T>(car: try transform(car), cdr: try cdr?.map(transform))
    }
    public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> Self {
        guard let car = car else { return Self() }
        let included = try isIncluded(car)
        let rest = try cdr?.filter(isIncluded)
        return included ? Self(car: car, cdr: rest) : rest ?? Self()
    }
    public func compactMap<T>(_ transform: (Element) throws -> T?) rethrows -> VList<T> {
        guard let car = car else { return VList<T>() }
        let transformed = try transform(car)
        let rest = try cdr?.compactMap(transform)
        guard let transformed else { return rest ?? VList<T>() }
        return VList<T>(car: transformed, cdr: rest)
    }
    public func flatMap<S: Sequence>(_ transform: (Element) throws -> S) rethrows -> VList<S.Element> {
        guard let car = car else { return VList<S.Element>() }
        let head = VList<S.Element>(try transform(car))
        let rest = try cdr?.flatMap(transform) ?? VList<S.Element>()
        return head + rest
    }
    /// Sorting is the one honest Array round-trip: a comparison sort
    /// needs random access, which a linked spine cannot offer.
    public func sorted(by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows -> Self {
        return Self(try Array(self).sorted(by: areInIncreasingOrder))
    }
}
extension VList where Element: Comparable {
    public func sorted() -> Self {
        return Self(Array(self).sorted())
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
        if position == 0 { return removeFirst() }
        guard position > 0, var next = cdr else {
            preconditionFailure("index out of bounds")
        }
        let removed = next.remove(at: position - 1)
        cdr = next
        return removed
    }
    public mutating func removeAll() {
        self = Self()
    }
}
