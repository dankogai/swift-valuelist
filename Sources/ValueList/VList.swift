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
    /// `indirect` exists only for enums, so the recursion is routed
    /// through this heap-boxed link; value semantics are preserved.
    private indirect enum Link {
        case Nil
        case Next(VList<Element>)
    }
    private var link: Link = .Nil
    public var car: Element
    public var cdr: VList<Element>? {
        get {
            if case .Next(let list) = link { return list } else { return nil }
        }
        set {
            link = newValue.map { .Next($0) } ?? .Nil
        }
    }
    public init(car: Element, cdr: VList<Element>? = nil) {
        self.car = car
        self.cdr = cdr
    }
}
extension VList {
    /// Fails on an empty sequence — a VList always has at least a car.
    public init?<S: Sequence>(_ elements: S) where S.Element == Element {
        let elements = Array(elements)
        guard let first = elements.first else { return nil }
        var cdr: VList<Element>? = nil
        for element in elements.dropFirst().reversed() {
            cdr = VList(car: element, cdr: cdr)
        }
        self.init(car: first, cdr: cdr)
    }
    /// Concrete overload so VList([1, 2, 3]) binds Element to Int —
    /// without it the variadic init would win with Element = [Int].
    public init?(_ elements: [Element]) {
        self.init(elements[...])
    }
    /// VList(1, 2, 3) — the required first argument makes an empty
    /// VList unrepresentable at compile time.
    public init(_ first: Element, _ rest: Element...) {
        self.init(car: first, cdr: VList(rest))
    }
}
extension VList: CustomStringConvertible {
    /// Lisp notation, e.g. VList(1, 2, 3) prints as (1 2 3).
    /// Iterative so long lists cannot overflow the stack.
    public var description: String {
        var elements = [String]()
        var list: VList<Element>? = self
        while let current = list {
            elements.append("\(current.car)")
            list = current.cdr
        }
        return "(" + elements.joined(separator: " ") + ")"
    }
}
extension VList:Sequence {
    public struct Iterator: IteratorProtocol {
        var list: VList<Element>?
        public mutating func next() -> Element? {
            guard let current = list else { return nil }
            list = current.cdr
            return current.car
        }
    }
    public func makeIterator() -> Iterator {
        return Iterator(list: self)
    }
}
extension VList:Collection {
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
        return Index(offset: 0, list: self)
    }
    public var endIndex: Index {
        return Index(offset: Int.max, list: nil)
    }
    public subscript(position: Index) -> Element {
        guard let list = position.list else {
            preconditionFailure("index out of bounds")
        }
        return list.car
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
// map, filter, contains, firstIndex(of:), sorted(), min/max, dropFirst,
// prefix/suffix and friends all come for free. The removal family
// (remove(at:), removeFirst, popLast, …) is deliberately absent — removing
// the only element would produce an empty VList, which is unrepresentable —
// as is ExpressibleByArrayLiteral, whose empty literal [] could only trap.
extension VList: Equatable where Element: Equatable {
    public static func == (lhs: VList<Element>, rhs: VList<Element>) -> Bool {
        return lhs.car == rhs.car && lhs.cdr == rhs.cdr
    }
}
extension VList: Hashable where Element: Hashable {
    public func hash(into hasher: inout Hasher) {
        for element in self { hasher.combine(element) }
    }
}
extension VList {
    /// Non-optional, unlike Array's — a VList is never empty. O(count).
    public var last: Element {
        var current = self
        while let next = current.cdr { current = next }
        return current.car
    }
    /// Replaces the car of the `position`-th cell;
    /// returns false when the list is shorter than that.
    private mutating func replaceCar(at position: Int, with element: Element) -> Bool {
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
}
extension VList {
    /// Splices `list` at the end — concatenation, like Array's append(contentsOf:).
    public mutating func append(contentsOf list: VList<Element>) {
        if var next = cdr {
            next.append(contentsOf: list)
            cdr = next
        } else {
            cdr = list
        }
    }
    public mutating func append<S: Sequence>(contentsOf newElements: S) where S.Element == Element {
        guard let list = VList(newElements) else { return }
        append(contentsOf: list)
    }
    public mutating func append(_ element: Element) {
        append(contentsOf: VList(car: element))
    }
    /// Concatenates two lists, e.g. (1 2) + (3 4) == (1 2 3 4).
    public static func + (lhs: VList<Element>, rhs: VList<Element>) -> VList<Element> {
        var result = lhs
        result.append(contentsOf: rhs)
        return result
    }
    public static func += (lhs: inout VList<Element>, rhs: VList<Element>) {
        lhs.append(contentsOf: rhs)
    }
}
