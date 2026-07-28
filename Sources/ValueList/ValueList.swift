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
