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
