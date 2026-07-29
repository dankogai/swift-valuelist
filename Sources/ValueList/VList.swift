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
    /// Fails on an empty array — a VList always has at least a car.
    public init?(_ elements: [Element]) {
        guard let first = elements.first else { return nil }
        var cdr: VList<Element>? = nil
        for element in elements.dropFirst().reversed() {
            cdr = VList(car: element, cdr: cdr)
        }
        self.init(car: first, cdr: cdr)
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
