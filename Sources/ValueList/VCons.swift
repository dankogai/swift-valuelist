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
    public var car:Node? = nil
    public var cdr:Node? = nil
    //
    public init() {
        car = nil
        cdr = nil
    }
    public init(car:Node? = nil, cdr:Node? = nil) {
        self.car = car
        self.cdr = cdr
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
    public init(nodes:[Node]) {
        self.init()
        guard let first = nodes.first else { return }
        var cdr:Node? = nil
        for node in nodes.dropFirst().reversed() {
            cdr = .Pair(Self(car:node, cdr:cdr))
        }
        self.car = first
        self.cdr = cdr
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
        if car == nil && cdr == nil {
            car = node
            return
        }
        if cdr == nil {
            cdr = .Pair(Self(car:node))
        } else if var next = cdr?.pair {
            next.append(node:node)
            cdr = .Pair(next)
        } else {
            preconditionFailure("cannot append to an improper list")
        }
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
    public var isEmpty:Bool {
        return car == nil && cdr == nil
    }
    /// Splices `cons` at the end of the list — concatenation, not nesting:
    /// (1 2) appended contentsOf (3 4) == (1 2 3 4).
    public mutating func append(contentsOf cons:Self) {
        guard !cons.isEmpty else { return }
        if isEmpty {
            self = cons
            return
        }
        if cdr == nil {
            cdr = .Pair(cons)
        } else if var next = cdr?.pair {
            next.append(contentsOf:cons)
            cdr = .Pair(next)
        } else {
            preconditionFailure("cannot append to an improper list")
        }
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
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.car == rhs.car && lhs.cdr == rhs.cdr
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
    /// Replaces the car of the `position`-th occupied cell;
    /// returns false when the list is shorter than that.
    private mutating func replaceCar(at position:inout Int, with node:Node) -> Bool {
        if car != nil {
            if position == 0 {
                car = node
                return true
            }
            position -= 1
        }
        guard var next = cdr?.pair else { return false }
        let replaced = next.replaceCar(at:&position, with:node)
        cdr = .Pair(next)
        return replaced
    }
    /// Array-like positional access, counting elements the way iteration does
    /// (nil cars are skipped, an atom cdr ends the list).
    /// Unwrap the returned node with `.atom` or `.pair`.
    public subscript(position:Int) -> Node {
        get {
            return self[index(startIndex, offsetBy:position)]
        }
        set {
            var position = position
            guard position >= 0, replaceCar(at:&position, with:newValue) else {
                preconditionFailure("index out of bounds")
            }
        }
    }
}
