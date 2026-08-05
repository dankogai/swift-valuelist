//
//  VCons.swift
//  ValueList
//
//  Copyright (c) 2026 Dan Kogai. All rights reserved.
//

public struct VCons<Element> {
    /// The cell content type. An implementation detail of `VCons` —
    /// build lists with the `VCons` initializers and `append` family
    /// rather than constructing nodes directly.
    public indirect enum Node {
        case Atom(Element)
        case Pair(VCons<Element>)
    }
    //
    public var car:Node? = nil
    public var cdr:Node? = nil
    public init() {}
    public init(car:Node? = nil, cdr:Node? = nil) {
        self.car = car
        self.cdr = cdr
    }
}

extension VCons {
    public var isEmpty:Bool {
        return car == nil && cdr == nil
    }
    /// O(1) — the natural way to grow a list. Prepending onto the empty
    /// list fills its car, so (cons x ()) == (x), not (x nil).
    public mutating func prepend(_ node:Node) {
        self = isEmpty ? Self(car:node) : Self(car:node, cdr:.Pair(self))
    }
    public func prepended(_ node:Node) -> Self {
        var copy = self
        copy.prepend(node)
        return copy
    }
    /// Cell-preserving reversal, e.g. (1 nil 2) reversed == (2 nil 1);
    /// reversing an improper list is a programmer error.
    public func reversed() -> Self {
        var result:Self? = nil
        var current:Self? = self
        while let cell = current {
            guard cell.cdr?.atom == nil else {
                preconditionFailure("cannot reverse an improper list")
            }
            result = Self(car:cell.car, cdr:result.map{ .Pair($0) })
            current = cell.cdr?.pair
        }
        return result ?? Self()
    }
    public mutating func reverse() {
        self = reversed()
    }
}

extension VCons.Node {
    public var atom:Element? {
        if case .Atom(let v) = self { return v } else { return nil }
    }
    public var pair:VCons<Element>? {
        if case .Pair(let v) = self { return v } else { return nil }
    }
}

extension VCons {
    /// Builds in a single pass: an Array can be walked backwards, and its
    /// reversed() is a lazy view, so prepending needs no reverse() after.
    public init(nodes:[Node]) {
        self.init()
        for node in nodes.reversed() {
            prepend(node)
        }
    }
    // Disfavored so that all-VCons arguments pick the sublist overload below
    // (binding Element to the inner type) instead of Element = VCons<...>.
    @_disfavoredOverload
    public init(_ values:Element ...) {
        self.init(nodes:values.map{ .Atom($0) })
    }
    /// A list of sublists, e.g. VCons(VCons(1, 2), VCons(3, 4)) == ((1 2) (3 4)) —
    /// inferred as VCons<Int>, not the absurd VCons<VCons<Int>>.
    public init(_ values:Self ...) {
        self.init(nodes:values.map{ .Pair($0) })
    }
    /// Converts `value` to a Node: a `VCons` becomes .Pair, a `Node` passes
    /// through, an `Element` becomes .Atom; anything else is a programmer error.
    internal static func node(of value:Any) -> Node {
        switch value {
        case let cons as Self: return .Pair(cons)
        case let node as Node:           return node
        case let element as Element:     return .Atom(element)
        default:
            preconditionFailure("\(value) is neither Element nor VCons<Element>")
        }
    }
    /// Accepts a mix of `Element` and `VCons<Element>`;
    /// a `VCons` argument becomes a sublist, e.g. VCons<Int>(1, VCons(2, 3), 4) == (1 (2 3) 4).
    /// Note: `Element` cannot be inferred through `Any`, so mixed calls
    /// need the type spelled out, as in `VCons<Int>(...)`.
    /// Disfavored so homogeneous calls keep resolving to the typed overloads.
    @_disfavoredOverload
    public init(_ values:Any ...) {
        self.init(nodes:values.map{ VCons.node(of:$0) })
    }
}

extension VCons {
    /// Appends `node` at the end of the list.
    /// An empty cons becomes a one-element list;
    /// appending to an improper list — one whose last cdr is an atom — is a programmer error.
    public mutating func append(node:Node) {
        append(contentsOf:Self(car:node))
    }
    public mutating func append(_ element:Element) {
        append(node:.Atom(element))
    }
    /// Appends `cons` as a sublist, e.g. (1 2) appended (3 4) == (1 2 (3 4)).
    public mutating func append(_ cons:Self) {
        append(node:.Pair(cons))
    }
}

extension VCons {
    /// Splices `cons` at the end of the list — concatenation, not nesting:
    /// (1 2) appended contentsOf (3 4) == (1 2 3 4).
    /// Prepends self's cells onto `cons` back to front, via reversed() —
    /// which is also what traps when self is improper.
    public mutating func append(contentsOf cons:Self) {
        guard !cons.isEmpty else { return }
        if isEmpty {
            self = cons
            return
        }
        var result = cons
        var current:Self? = reversed()
        while let cell = current {
            result = Self(car:cell.car, cdr:.Pair(result))
            current = cell.cdr?.pair
        }
        self = result
    }
    public mutating func append<S:Sequence>(contentsOf values:S) where S.Element == Element {
        append(contentsOf:Self(nodes:values.map{ .Atom($0) }))
    }
    /// Concatenates two lists, e.g. (1 2) + (3 4) == (1 2 3 4).
    public static func +(lhs:Self, rhs:Self) -> Self {
        var result = lhs
        result.append(contentsOf:rhs)
        return result
    }
    public static func +=(lhs:inout Self, rhs:Self) {
        lhs.append(contentsOf:rhs)
    }
}

extension VCons.Node: CustomStringConvertible {
    public var description:String {
        // exactly one of pair/atom is non-nil
        return pair?.description ?? "\(atom!)"
    }
}
extension VCons: CustomStringConvertible {
    public var description:String {
        if car == nil && cdr == nil { return "()" }
        var elements = [String]()
        var cons = self
        while true {
            elements.append(cons.car.map{ "\($0)" } ?? "nil")
            if let next = cons.cdr?.pair {
                cons = next
            } else if let value = cons.cdr?.atom {
                return "(" + elements.joined(separator:" ") + " . \(value))"
            } else {
                return "(" + elements.joined(separator:" ") + ")"
            }
        }
    }
}

extension VCons.Node: Equatable where Element: Equatable {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.atom == rhs.atom && lhs.pair == rhs.pair
    }
}
extension VCons: Equatable where Element: Equatable {
    /// Walks the spine iteratively; recursion remains only for nested
    /// sublists in cars — inherent to a tree.
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        var lhs = lhs, rhs = rhs
        while true {
            guard lhs.car == rhs.car else { return false }
            if lhs.cdr == nil && rhs.cdr == nil { return true }
            if let l = lhs.cdr?.atom, let r = rhs.cdr?.atom { return l == r }
            guard let l = lhs.cdr?.pair, let r = rhs.cdr?.pair else { return false }
            (lhs, rhs) = (l, r)
        }
    }
}

extension VCons: Sequence {
    public struct Iterator: IteratorProtocol {
        var cons:VCons<Element>?
        public mutating func next() -> VCons<Element>.Node? {
            while let current = cons {
                cons = current.cdr?.pair
                if let car = current.car { return car }
            }
            return nil
        }
    }
    public func makeIterator() -> Iterator {
        return Iterator(cons: self)
    }
}

extension VCons: Collection {
    /// Wraps the remaining list so that index(after:) is O(1);
    /// `offset` orders indices for Comparable, with Int.max as endIndex.
    public struct Index: Comparable {
        fileprivate let offset:Int
        fileprivate let cons:VCons<Element>?
        public static func ==(lhs:Index, rhs:Index) -> Bool {
            return lhs.offset == rhs.offset
        }
        public static func <(lhs:Index, rhs:Index) -> Bool {
            return lhs.offset < rhs.offset
        }
    }
    /// The first cell at or after `cons` whose car is non-nil,
    /// matching the Iterator's nil-car skipping.
    private static func firstOccupied(_ cons:Self?, offset:Int) -> Index {
        var cons = cons
        var offset = offset
        while let current = cons {
            if current.car != nil { return Index(offset:offset, cons:current) }
            cons = current.cdr?.pair
            offset += 1
        }
        return Index(offset:Int.max, cons:nil)
    }
    public var startIndex:Index {
        return VCons.firstOccupied(self, offset:0)
    }
    public var endIndex:Index {
        return Index(offset:Int.max, cons:nil)
    }
    public subscript(position:Index) -> Node {
        guard let car = position.cons?.car else {
            preconditionFailure("index out of bounds")
        }
        return car
    }
    public func index(after i:Index) -> Index {
        guard let cons = i.cons else {
            preconditionFailure("cannot advance past endIndex")
        }
        guard let next = cons.cdr?.pair else { return endIndex }
        return VCons.firstOccupied(next, offset:i.offset + 1)
    }
}

extension VCons {
    /// Peels cells off the front — collected in reverse into `reversedPrefix` —
    /// until the `position`-th occupied cell is at the head;
    /// false when the list is shorter than that.
    private mutating func liftPrefix(_ position:Int, into reversedPrefix:inout Self?) -> Bool {
        var remaining = position
        while car == nil || remaining > 0 {
            if car != nil { remaining -= 1 }
            guard let next = cdr?.pair else { return false }
            reversedPrefix = Self(car:car, cdr:reversedPrefix.map{ .Pair($0) })
            self = next
        }
        return true
    }
    /// Prepends the cells collected by liftPrefix back, restoring their order.
    private mutating func restorePrefix(_ reversedPrefix:Self?) {
        var current = reversedPrefix
        while let cell = current {
            self = Self(car:cell.car, cdr:.Pair(self))
            current = cell.cdr?.pair
        }
    }
    /// Array-like positional access, counting elements the way iteration does
    /// (nil cars are skipped, an atom cdr ends the list).
    /// Unwrap the returned node with `.atom` or `.pair`.
    public subscript(position:Int) -> Node {
        get {
            return self[index(startIndex, offsetBy:position)]
        }
        set {
            var reversedPrefix:Self? = nil
            guard position >= 0, liftPrefix(position, into:&reversedPrefix) else {
                preconditionFailure("index out of bounds")
            }
            car = newValue
            restorePrefix(reversedPrefix)
        }
    }
    /// Bounds of `range` within this list, trapping out of bounds like Array.
    private func bounds<R:RangeExpression>(of range:R) -> Range<Int> where R.Bound == Int {
        let count = self.count
        let bounds = range.relative(to:0..<count)
        precondition(bounds.lowerBound >= 0 && bounds.upperBound <= count,
                     "range out of bounds")
        return bounds
    }
    /// Range subscripting like Array's: list[1..<3], list[1...3], list[1...],
    /// list[..<2], list[...2]. Positions count elements the way iteration does,
    /// so the result is a proper list of the occupied nodes — nil cars and an
    /// atom cdr do not survive the trip. The setter replaces the range and may
    /// resize, like Array's replaceSubrange. O(count); traps like Array.
    public subscript<R:RangeExpression>(range:R) -> Self where R.Bound == Int {
        get {
            let bounds = self.bounds(of:range)
            var result = Self()
            for node in dropFirst(bounds.lowerBound).prefix(bounds.count) {
                result.prepend(node)
            }
            result.reverse()
            return result
        }
        set {
            let bounds = self.bounds(of:range)
            var result = self[..<bounds.lowerBound]
            result.append(contentsOf:newValue)
            result.append(contentsOf:self[bounds.upperBound...])
            self = result
        }
    }
    public subscript(_: UnboundedRange) -> Self {
        get { return self }
        set { self = newValue }
    }
}

extension VCons {
    /// Sorts the occupied nodes into a proper list — nil cars and an
    /// atom cdr do not survive, like the range subscripts. A stable
    /// merge sort (MergeSort.swift): sequential access only, no Array.
    public func sorted(by areInIncreasingOrder: (Node, Node) throws -> Bool) rethrows -> Self {
        var result = Self()
        for node in try mergeSorted(by: areInIncreasingOrder).reversed() {
            result.prepend(node)
        }
        return result
    }
}

extension VCons {
    /// All leaf atoms of the tree, flattened into a VList in order:
    /// (1 (2 3) 4).atoms() == (1 2 3 4), and the atom cdr of a dotted
    /// pair is included: (1 . 2).atoms() == (1 2). Spines are walked
    /// iteratively; recursion only descends into nested sublists in
    /// cars — inherent to a tree, like Node.==.
    public func atoms() -> VList<Element> {
        var result = VList<Element>()
        func visit(_ cons:Self) {
            var current:Self? = cons
            while let cell = current {
                if let atom = cell.car?.atom { result.prepend(atom) }
                if let sublist = cell.car?.pair { visit(sublist) }
                if let tail = cell.cdr?.atom { result.prepend(tail) }
                current = cell.cdr?.pair
            }
        }
        visit(self)
        result.reverse()
        return result
    }
}
