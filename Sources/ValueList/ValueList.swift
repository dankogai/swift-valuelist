// The Swift Programming Language
// https://docs.swift.org/swift-book

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
    public init(_ values:Element ...) {
        self.init()
        guard let first = values.first else { return }
        var cdr:Node<Element>? = nil
        for value in values.dropFirst().reversed() {
            cdr = .Pair(Cons(car:.Atom(value), cdr:cdr))
        }
        self.car = .Atom(first)
        self.cdr = cdr
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
