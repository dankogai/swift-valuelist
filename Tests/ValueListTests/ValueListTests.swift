import Testing
@testable import ValueList

@Suite struct EquatabilityTests {
    @Test func atomEquality() {
        #expect(Node.Atom(42) == Node.Atom(42))
        #expect(Node.Atom(42) != Node.Atom(43))
        #expect(Node.Atom("swift") == Node.Atom("swift"))
        #expect(Node.Atom("swift") != Node.Atom("lisp"))
    }

    @Test func atomVsPair() {
        let atom = Node.Atom(0)
        let pair = Node.Pair(Cons(car: .Atom(0)))
        #expect(atom != pair)
        #expect(pair != atom)
    }

    @Test func emptyCons() {
        #expect(Cons<Int>() == Cons<Int>())
        #expect(Cons<Int>() == Cons<Int>(car: nil, cdr: nil))
    }

    @Test func consEquality() {
        let lhs = Cons(car: .Atom(1), cdr: .Atom(2))
        let rhs = Cons(car: .Atom(1), cdr: .Atom(2))
        #expect(lhs == rhs)
    }

    @Test func consInequality() {
        let base = Cons(car: .Atom(1), cdr: .Atom(2))
        #expect(base != Cons(car: .Atom(9), cdr: .Atom(2)))
        #expect(base != Cons(car: .Atom(1), cdr: .Atom(9)))
        #expect(base != Cons(car: .Atom(1), cdr: nil))
        #expect(base != Cons(car: nil, cdr: .Atom(2)))
    }

    @Test func nestedEquality() {
        // ((1 . 2) . (3 . nil))
        func make() -> Node<Int> {
            .Pair(Cons(
                car: .Pair(Cons(car: .Atom(1), cdr: .Atom(2))),
                cdr: .Pair(Cons(car: .Atom(3), cdr: nil))
            ))
        }
        #expect(make() == make())
    }

    @Test func nestedInequality() {
        let lhs = Node.Pair(Cons(car: .Pair(Cons(car: .Atom(1), cdr: nil)), cdr: nil))
        let rhs = Node.Pair(Cons(car: .Pair(Cons(car: .Atom(2), cdr: nil)), cdr: nil))
        #expect(lhs != rhs)
    }
}
