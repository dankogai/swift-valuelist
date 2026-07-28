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

@Suite struct VariadicInitTests {
    @Test func emptyList() {
        #expect(Cons<Int>() == Cons<Int>())
    }

    @Test func singleElement() {
        #expect(Cons(42) == Cons(car: .Atom(42)))
    }

    @Test func multipleElements() {
        let expected = Cons(
            car: .Atom(1),
            cdr: .Pair(Cons(car: .Atom(2), cdr: .Pair(Cons(car: .Atom(3)))))
        )
        #expect(Cons(1, 2, 3) == expected)
    }

    @Test func mixedElementsAndSublists() {
        // (1 (2 3) 4) — a Cons argument becomes a sublist
        let mixed = Cons<Int>(1, Cons(2, 3), 4)
        let expected = Cons(
            car: .Atom(1),
            cdr: .Pair(Cons(
                car: .Pair(Cons(2, 3)),
                cdr: .Pair(Cons(car: .Atom(4)))
            ))
        )
        #expect(mixed == expected)
        #expect(mixed.description == "(1 (2 3) 4)")
    }

    @Test func deeplyNestedSublists() {
        // (1 (2 (3 4)))
        let list = Cons<Int>(1, Cons<Int>(2, Cons(3, 4)))
        #expect(list.description == "(1 (2 (3 4)))")
    }

    @Test func sublistOnly() {
        // ((1 2)) — a single Cons argument is still wrapped as a sublist, not flattened
        let list = Cons<Int>(Cons(1, 2))
        #expect(list == Cons(car: .Pair(Cons(1, 2))))
        #expect(list.description == "((1 2))")
    }

    @Test func mixedMatchesManualConstruction() {
        let viaInit = Cons<String>("a", Cons("b"), "c")
        var manual = Cons<String>()
        manual.car = .Atom("a")
        manual.cdr = .Pair(Cons(car: .Pair(Cons("b")), cdr: .Pair(Cons(car: .Atom("c")))))
        #expect(viaInit == manual)
    }
}

@Suite struct DescriptionTests {
    @Test func emptyCons() {
        #expect(Cons<Int>().description == "()")
    }

    @Test func atom() {
        #expect(Node.Atom(42).description == "42")
        #expect(Node.Atom("swift").description == "swift")
    }

    @Test func properList() {
        #expect(Cons(1, 2, 3).description == "(1 2 3)")
        #expect(Cons(42).description == "(42)")
    }

    @Test func dottedPair() {
        #expect(Cons(car: .Atom(1), cdr: .Atom(2)).description == "(1 . 2)")
    }

    @Test func nestedList() {
        // ((1 2) 3)
        let inner = Cons(1, 2)
        let outer = Cons(car: .Pair(inner), cdr: .Pair(Cons(3)))
        #expect(outer.description == "((1 2) 3)")
    }

    @Test func nilCar() {
        #expect(Cons<Int>(car: nil, cdr: .Atom(2)).description == "(nil . 2)")
    }
}

@Suite struct SequenceTests {
    @Test func emptyConsYieldsNothing() {
        #expect(Array(Cons<Int>()).isEmpty)
    }

    @Test func singleElement() {
        #expect(Array(Cons(42)) == [.Atom(42)])
    }

    @Test func properListYieldsCarsInOrder() {
        #expect(Array(Cons(1, 2, 3)) == [.Atom(1), .Atom(2), .Atom(3)])
    }

    @Test func dottedPairDropsAtomCdr() {
        // iteration only follows .Pair cdrs; the atom cdr of (1 . 2) is not an element
        #expect(Array(Cons(car: .Atom(1), cdr: .Atom(2))) == [.Atom(1)])
    }

    @Test func nilCarsAreSkipped() {
        let list = Cons<Int>(car: nil, cdr: .Pair(Cons(car: .Atom(2), cdr: .Pair(Cons(car: nil)))))
        #expect(Array(list) == [.Atom(2)])
    }

    @Test func nestedListYieldsPairNode() {
        // ((1 2) 3) yields the inner list as a single .Pair node, then .Atom(3)
        let inner = Cons(1, 2)
        let outer = Cons(car: .Pair(inner), cdr: .Pair(Cons(3)))
        #expect(Array(outer) == [.Pair(inner), .Atom(3)])
    }

    @Test func iterationDoesNotConsumeTheCons() {
        let list = Cons(1, 2, 3)
        #expect(Array(list) == Array(list))
    }

    @Test func sequenceAlgorithms() {
        let list = Cons(1, 2, 3, 4)
        let doubled = list.map { node -> Int in
            guard case .Atom(let value) = node else { return 0 }
            return value * 2
        }
        #expect(doubled == [2, 4, 6, 8])
        #expect(list.contains(.Atom(3)))
        #expect(!list.contains(.Atom(5)))
        #expect(list.first { $0 == .Atom(2) } == .Atom(2))
    }
}

@Suite struct AppendTests {
    @Test func appendToEmpty() {
        var list = Cons<Int>()
        list.append(1)
        #expect(list == Cons(1))
        #expect(list.description == "(1)")
    }

    @Test func appendElement() {
        var list = Cons(1, 2)
        list.append(3)
        #expect(list == Cons(1, 2, 3))
        #expect(list.description == "(1 2 3)")
    }

    @Test func appendRepeatedly() {
        var list = Cons<Int>()
        for value in 1...5 { list.append(value) }
        #expect(list == Cons(1, 2, 3, 4, 5))
    }

    @Test func appendSublist() {
        var list = Cons(1, 2)
        list.append(Cons(3, 4))
        #expect(list == Cons<Int>(1, 2, Cons(3, 4)))
        #expect(list.description == "(1 2 (3 4))")
    }

    @Test func appendNode() {
        var list = Cons(1)
        list.append(node: .Atom(2))
        #expect(list == Cons(1, 2))
    }

    @Test func appendHasValueSemantics() {
        let original = Cons(1, 2)
        var copy = original
        copy.append(3)
        #expect(original == Cons(1, 2))
        #expect(copy == Cons(1, 2, 3))
    }
}

@Suite struct ConcatenationTests {
    @Test func appendContentsOfConsConcatenates() {
        var list = Cons(1, 2)
        list.append(contentsOf: Cons(3, 4))
        #expect(list == Cons(1, 2, 3, 4))
        #expect(list.description == "(1 2 3 4)")
    }

    @Test func appendContentsOfSequence() {
        var list = Cons(1, 2)
        list.append(contentsOf: [3, 4])
        #expect(list == Cons(1, 2, 3, 4))
        list.append(contentsOf: 5...6)
        #expect(list == Cons(1, 2, 3, 4, 5, 6))
    }

    @Test func appendContentsOfEmptyIsNoOp() {
        var list = Cons(1, 2)
        list.append(contentsOf: Cons<Int>())
        #expect(list == Cons(1, 2))
        list.append(contentsOf: [Int]())
        #expect(list == Cons(1, 2))
    }

    @Test func appendContentsOfOntoEmpty() {
        var list = Cons<Int>()
        list.append(contentsOf: Cons(1, 2))
        #expect(list == Cons(1, 2))
    }

    @Test func concatenationVersusNesting() {
        var spliced = Cons(1, 2)
        spliced.append(contentsOf: Cons(3, 4))
        var nested = Cons(1, 2)
        nested.append(Cons(3, 4))
        #expect(spliced.description == "(1 2 3 4)")
        #expect(nested.description == "(1 2 (3 4))")
        #expect(spliced != nested)
    }

    @Test func plusOperator() {
        #expect(Cons(1, 2) + Cons(3, 4) == Cons(1, 2, 3, 4))
        #expect((Cons(1, 2) + Cons(3, 4)).description == "(1 2 3 4)")
    }

    @Test func plusWithEmpty() {
        #expect(Cons<Int>() + Cons(1, 2) == Cons(1, 2))
        #expect(Cons(1, 2) + Cons<Int>() == Cons(1, 2))
        #expect(Cons<Int>() + Cons<Int>() == Cons<Int>())
    }

    @Test func plusLeavesOperandsUntouched() {
        let lhs = Cons(1, 2)
        let rhs = Cons(3, 4)
        _ = lhs + rhs
        #expect(lhs == Cons(1, 2))
        #expect(rhs == Cons(3, 4))
    }

    @Test func plusIsAssociative() {
        let (a, b, c) = (Cons(1), Cons(2), Cons(3))
        #expect((a + b) + c == a + (b + c))
    }

    @Test func plusEquals() {
        var list = Cons(1, 2)
        list += Cons(3, 4)
        #expect(list == Cons(1, 2, 3, 4))
    }
}
