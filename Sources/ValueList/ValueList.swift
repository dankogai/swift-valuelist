//
//  ValueList.swift
//  ValueList
//
//  Copyright (c) 2026 Dan Kogai. All rights reserved.
//

public indirect enum VNode<Element> {
    case Atom(Element)
    case Pair(VCons<Element>)
}

public struct VCons<Element> {
    public var car:VNode<Element>? = nil
    public var cdr:VNode<Element>? = nil
    //
    public init() {
        car = nil
        cdr = nil
    }
    public init(car:VNode<Element>? = nil, cdr:VNode<Element>? = nil) {
        self.car = car
        self.cdr = cdr
    }
}

extension VCons {
    public init(nodes:[VNode<Element>]) {
        self.init()
        guard let first = nodes.first else { return }
        var cdr:VNode<Element>? = nil
        for node in nodes.dropFirst().reversed() {
            cdr = .Pair(VCons(car:node, cdr:cdr))
        }
        self.car = first
        self.cdr = cdr
    }
    public init(_ values:Element ...) {
        self.init(nodes:values.map{ .Atom($0) })
    }
    /// Accepts a mix of `Element` and `VCons<Element>`;
    /// a `VCons` argument becomes a sublist, e.g. VCons<Int>(1, VCons(2, 3), 4) == (1 (2 3) 4).
    /// Note: `Element` cannot be inferred through `Any`, so mixed calls
    /// need the type spelled out, as in `VCons<Int>(...)`.
    public init(_ values:Any ...) {
        self.init(nodes:values.map{ value in
            switch value {
            case let cons as VCons<Element>: return .Pair(cons)
            case let node as VNode<Element>: return node
            case let element as Element:    return .Atom(element)
            default:
                preconditionFailure("\(value) is neither Element nor VCons<Element>")
            }
        })
    }
}

extension VCons {
    /// Appends `node` at the end of the list.
    /// An empty cons becomes a one-element list;
    /// appending to an improper list — one whose last cdr is an atom — is a programmer error.
    public mutating func append(node:VNode<Element>) {
        if car == nil && cdr == nil {
            car = node
            return
        }
        switch cdr {
        case nil:
            cdr = .Pair(VCons(car:node))
        case .Pair(var next)?:
            next.append(node:node)
            cdr = .Pair(next)
        case .Atom?:
            preconditionFailure("cannot append to an improper list")
        }
    }
    public mutating func append(_ element:Element) {
        append(node:.Atom(element))
    }
    /// Appends `cons` as a sublist, e.g. (1 2) appended (3 4) == (1 2 (3 4)).
    public mutating func append(_ cons:VCons<Element>) {
        append(node:.Pair(cons))
    }
}

extension VCons {
    public var isEmpty:Bool {
        return car == nil && cdr == nil
    }
    /// Splices `cons` at the end of the list — concatenation, not nesting:
    /// (1 2) appended contentsOf (3 4) == (1 2 3 4).
    public mutating func append(contentsOf cons:VCons<Element>) {
        guard !cons.isEmpty else { return }
        if isEmpty {
            self = cons
            return
        }
        switch cdr {
        case nil:
            cdr = .Pair(cons)
        case .Pair(var next)?:
            next.append(contentsOf:cons)
            cdr = .Pair(next)
        case .Atom?:
            preconditionFailure("cannot append to an improper list")
        }
    }
    public mutating func append<S:Sequence>(contentsOf values:S) where S.Element == Element {
        append(contentsOf:VCons(nodes:values.map{ .Atom($0) }))
    }
    /// Concatenates two lists, e.g. (1 2) + (3 4) == (1 2 3 4).
    public static func +(lhs:VCons<Element>, rhs:VCons<Element>) -> VCons<Element> {
        var result = lhs
        result.append(contentsOf:rhs)
        return result
    }
    public static func +=(lhs:inout VCons<Element>, rhs:VCons<Element>) {
        lhs.append(contentsOf:rhs)
    }
}

extension VNode: CustomStringConvertible {
    public var description:String {
        switch self {
        case .Atom(let value): return "\(value)"
        case .Pair(let cons):  return cons.description
        }
    }
}
extension VCons: CustomStringConvertible {
    public var description:String {
        if car == nil && cdr == nil { return "()" }
        var elements = [String]()
        var cons = self
        while true {
            elements.append(cons.car.map{ "\($0)" } ?? "nil")
            switch cons.cdr {
            case nil:
                return "(" + elements.joined(separator:" ") + ")"
            case .Atom(let value)?:
                return "(" + elements.joined(separator:" ") + " . \(value))"
            case .Pair(let next)?:
                cons = next
            }
        }
    }
}

extension VNode: Equatable where Element: Equatable {
    public static func ==(lhs: VNode<Element>, rhs: VNode<Element>) -> Bool {
        switch (lhs, rhs) {
        case (.Atom(let lhs), .Atom(let rhs)):
            return lhs == rhs
        case (.Pair(let lhs), .Pair(let rhs)):
            return lhs == rhs
        default: return false
        }
    }
}
extension VCons: Equatable where Element: Equatable {
    public static func ==(lhs: VCons<Element>, rhs: VCons<Element>) -> Bool {
        return lhs.car == rhs.car && lhs.cdr == rhs.cdr
    }
}

extension VCons: Sequence {
    public struct Iterator: IteratorProtocol {
        var cons:VCons<Element>?
        public mutating func next() -> VNode<Element>? {
            while let current = cons {
                switch current.cdr {
                case .Pair(let next)?: cons = next
                default:               cons = nil
                }
                if let car = current.car { return car }
            }
            return nil
        }
    }
    public func makeIterator() -> Iterator {
        return Iterator(cons: self)
    }
    
    
}

