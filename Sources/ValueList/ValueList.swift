//
//  ValueList.swift
//  ValueList
//
//  Copyright (c) 2026 Dan Kogai. All rights reserved.
//

public indirect enum Node<Element> {
    case Atom(Element)
    case Pair(Cons<Element>)
}

public struct Cons<Element> {
    public var car:Node<Element>? = nil
    public var cdr:Node<Element>? = nil
    //
    public init() {
        car = nil
        cdr = nil
    }
    public init(car:Node<Element>? = nil, cdr:Node<Element>? = nil) {
        self.car = car
        self.cdr = cdr
    }
}

extension Cons {
    public init(nodes:[Node<Element>]) {
        self.init()
        guard let first = nodes.first else { return }
        var cdr:Node<Element>? = nil
        for node in nodes.dropFirst().reversed() {
            cdr = .Pair(Cons(car:node, cdr:cdr))
        }
        self.car = first
        self.cdr = cdr
    }
    public init(_ values:Element ...) {
        self.init(nodes:values.map{ .Atom($0) })
    }
    /// Accepts a mix of `Element` and `Cons<Element>`;
    /// a `Cons` argument becomes a sublist, e.g. Cons<Int>(1, Cons(2, 3), 4) == (1 (2 3) 4).
    /// Note: `Element` cannot be inferred through `Any`, so mixed calls
    /// need the type spelled out, as in `Cons<Int>(...)`.
    public init(_ values:Any ...) {
        self.init(nodes:values.map{ value in
            switch value {
            case let cons as Cons<Element>: return .Pair(cons)
            case let node as Node<Element>: return node
            case let element as Element:    return .Atom(element)
            default:
                preconditionFailure("\(value) is neither Element nor Cons<Element>")
            }
        })
    }
}

extension Cons {
    /// Appends `node` at the end of the list.
    /// An empty cons becomes a one-element list;
    /// appending to an improper list — one whose last cdr is an atom — is a programmer error.
    public mutating func append(node:Node<Element>) {
        if car == nil && cdr == nil {
            car = node
            return
        }
        switch cdr {
        case nil:
            cdr = .Pair(Cons(car:node))
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
    public mutating func append(_ cons:Cons<Element>) {
        append(node:.Pair(cons))
    }
}

extension Cons {
    public var isEmpty:Bool {
        return car == nil && cdr == nil
    }
    /// Splices `cons` at the end of the list — concatenation, not nesting:
    /// (1 2) appended contentsOf (3 4) == (1 2 3 4).
    public mutating func append(contentsOf cons:Cons<Element>) {
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
        append(contentsOf:Cons(nodes:values.map{ .Atom($0) }))
    }
    /// Concatenates two lists, e.g. (1 2) + (3 4) == (1 2 3 4).
    public static func +(lhs:Cons<Element>, rhs:Cons<Element>) -> Cons<Element> {
        var result = lhs
        result.append(contentsOf:rhs)
        return result
    }
    public static func +=(lhs:inout Cons<Element>, rhs:Cons<Element>) {
        lhs.append(contentsOf:rhs)
    }
}

extension Node: CustomStringConvertible {
    public var description:String {
        switch self {
        case .Atom(let value): return "\(value)"
        case .Pair(let cons):  return cons.description
        }
    }
}
extension Cons: CustomStringConvertible {
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

extension Node: Equatable where Element: Equatable {
    public static func ==(lhs: Node<Element>, rhs: Node<Element>) -> Bool {
        switch (lhs, rhs) {
        case (.Atom(let lhs), .Atom(let rhs)):
            return lhs == rhs
        case (.Pair(let lhs), .Pair(let rhs)):
            return lhs == rhs
        default: return false
        }
    }
}
extension Cons: Equatable where Element: Equatable {
    public static func ==(lhs: Cons<Element>, rhs: Cons<Element>) -> Bool {
        return lhs.car == rhs.car && lhs.cdr == rhs.cdr
    }
}

extension Cons: Sequence {
    public struct Iterator: IteratorProtocol {
        var cons:Cons<Element>?
        public mutating func next() -> Node<Element>? {
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

