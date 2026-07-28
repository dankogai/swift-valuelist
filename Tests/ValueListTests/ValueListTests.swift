import Testing
@testable import ValueList

@Suite struct EquatabilityTests {
    @Test func atomEquality() {
        #expect(VNode.Atom(42) == VNode.Atom(42))
        #expect(VNode.Atom(42) != VNode.Atom(43))
        #expect(VNode.Atom("swift") == VNode.Atom("swift"))
        #expect(VNode.Atom("swift") != VNode.Atom("lisp"))
    }

    @Test func atomVsPair() {
        let atom = VNode.Atom(0)
        let pair = VNode.Pair(VCons(car: .Atom(0)))
        #expect(atom != pair)
        #expect(pair != atom)
    }

    @Test func emptyCons() {
        #expect(VCons<Int>() == VCons<Int>())
        #expect(VCons<Int>() == VCons<Int>(car: nil, cdr: nil))
    }

    @Test func consEquality() {
        let lhs = VCons(car: .Atom(1), cdr: .Atom(2))
        let rhs = VCons(car: .Atom(1), cdr: .Atom(2))
        #expect(lhs == rhs)
    }

    @Test func consInequality() {
        let base = VCons(car: .Atom(1), cdr: .Atom(2))
        #expect(base != VCons(car: .Atom(9), cdr: .Atom(2)))
        #expect(base != VCons(car: .Atom(1), cdr: .Atom(9)))
        #expect(base != VCons(car: .Atom(1), cdr: nil))
        #expect(base != VCons(car: nil, cdr: .Atom(2)))
    }

    @Test func nestedEquality() {
        // ((1 . 2) . (3 . nil))
        func make() -> VNode<Int> {
            .Pair(VCons(
                car: .Pair(VCons(car: .Atom(1), cdr: .Atom(2))),
                cdr: .Pair(VCons(car: .Atom(3), cdr: nil))
            ))
        }
        #expect(make() == make())
    }

    @Test func nestedInequality() {
        let lhs = VNode.Pair(VCons(car: .Pair(VCons(car: .Atom(1), cdr: nil)), cdr: nil))
        let rhs = VNode.Pair(VCons(car: .Pair(VCons(car: .Atom(2), cdr: nil)), cdr: nil))
        #expect(lhs != rhs)
    }
}

@Suite struct VariadicInitTests {
    @Test func emptyList() {
        #expect(VCons<Int>() == VCons<Int>())
    }

    @Test func singleElement() {
        #expect(VCons(42) == VCons(car: .Atom(42)))
    }

    @Test func multipleElements() {
        let expected = VCons(
            car: .Atom(1),
            cdr: .Pair(VCons(car: .Atom(2), cdr: .Pair(VCons(car: .Atom(3)))))
        )
        #expect(VCons(1, 2, 3) == expected)
    }

    @Test func mixedElementsAndSublists() {
        // (1 (2 3) 4) — a VCons argument becomes a sublist
        let mixed = VCons<Int>(1, VCons(2, 3), 4)
        let expected = VCons(
            car: .Atom(1),
            cdr: .Pair(VCons(
                car: .Pair(VCons(2, 3)),
                cdr: .Pair(VCons(car: .Atom(4)))
            ))
        )
        #expect(mixed == expected)
        #expect(mixed.description == "(1 (2 3) 4)")
    }

    @Test func deeplyNestedSublists() {
        // (1 (2 (3 4)))
        let list = VCons<Int>(1, VCons<Int>(2, VCons(3, 4)))
        #expect(list.description == "(1 (2 (3 4)))")
    }

    @Test func sublistOnly() {
        // ((1 2)) — a single VCons argument is still wrapped as a sublist, not flattened
        let list = VCons<Int>(VCons(1, 2))
        #expect(list == VCons(car: .Pair(VCons(1, 2))))
        #expect(list.description == "((1 2))")
    }

    @Test func mixedMatchesManualConstruction() {
        let viaInit = VCons<String>("a", VCons("b"), "c")
        var manual = VCons<String>()
        manual.car = .Atom("a")
        manual.cdr = .Pair(VCons(car: .Pair(VCons("b")), cdr: .Pair(VCons(car: .Atom("c")))))
        #expect(viaInit == manual)
    }
}

@Suite struct DescriptionTests {
    @Test func emptyCons() {
        #expect(VCons<Int>().description == "()")
    }

    @Test func atom() {
        #expect(VNode.Atom(42).description == "42")
        #expect(VNode.Atom("swift").description == "swift")
    }

    @Test func properList() {
        #expect(VCons(1, 2, 3).description == "(1 2 3)")
        #expect(VCons(42).description == "(42)")
    }

    @Test func dottedPair() {
        #expect(VCons(car: .Atom(1), cdr: .Atom(2)).description == "(1 . 2)")
    }

    @Test func nestedList() {
        // ((1 2) 3)
        let inner = VCons(1, 2)
        let outer = VCons(car: .Pair(inner), cdr: .Pair(VCons(3)))
        #expect(outer.description == "((1 2) 3)")
    }

    @Test func nilCar() {
        #expect(VCons<Int>(car: nil, cdr: .Atom(2)).description == "(nil . 2)")
    }
}

@Suite struct SequenceTests {
    @Test func emptyConsYieldsNothing() {
        #expect(Array(VCons<Int>()).isEmpty)
    }

    @Test func singleElement() {
        #expect(Array(VCons(42)) == [.Atom(42)])
    }

    @Test func properListYieldsCarsInOrder() {
        #expect(Array(VCons(1, 2, 3)) == [.Atom(1), .Atom(2), .Atom(3)])
    }

    @Test func dottedPairDropsAtomCdr() {
        // iteration only follows .Pair cdrs; the atom cdr of (1 . 2) is not an element
        #expect(Array(VCons(car: .Atom(1), cdr: .Atom(2))) == [.Atom(1)])
    }

    @Test func nilCarsAreSkipped() {
        let list = VCons<Int>(car: nil, cdr: .Pair(VCons(car: .Atom(2), cdr: .Pair(VCons(car: nil)))))
        #expect(Array(list) == [.Atom(2)])
    }

    @Test func nestedListYieldsPairNode() {
        // ((1 2) 3) yields the inner list as a single .Pair node, then .Atom(3)
        let inner = VCons(1, 2)
        let outer = VCons(car: .Pair(inner), cdr: .Pair(VCons(3)))
        #expect(Array(outer) == [.Pair(inner), .Atom(3)])
    }

    @Test func iterationDoesNotConsumeTheCons() {
        let list = VCons(1, 2, 3)
        #expect(Array(list) == Array(list))
    }

    @Test func sequenceAlgorithms() {
        let list = VCons(1, 2, 3, 4)
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
        var list = VCons<Int>()
        list.append(1)
        #expect(list == VCons(1))
        #expect(list.description == "(1)")
    }

    @Test func appendElement() {
        var list = VCons(1, 2)
        list.append(3)
        #expect(list == VCons(1, 2, 3))
        #expect(list.description == "(1 2 3)")
    }

    @Test func appendRepeatedly() {
        var list = VCons<Int>()
        for value in 1...5 { list.append(value) }
        #expect(list == VCons(1, 2, 3, 4, 5))
    }

    @Test func appendSublist() {
        var list = VCons(1, 2)
        list.append(VCons(3, 4))
        #expect(list == VCons<Int>(1, 2, VCons(3, 4)))
        #expect(list.description == "(1 2 (3 4))")
    }

    @Test func appendNode() {
        var list = VCons(1)
        list.append(node: .Atom(2))
        #expect(list == VCons(1, 2))
    }

    @Test func appendHasValueSemantics() {
        let original = VCons(1, 2)
        var copy = original
        copy.append(3)
        #expect(original == VCons(1, 2))
        #expect(copy == VCons(1, 2, 3))
    }
}

@Suite struct ConcatenationTests {
    @Test func appendContentsOfConsConcatenates() {
        var list = VCons(1, 2)
        list.append(contentsOf: VCons(3, 4))
        #expect(list == VCons(1, 2, 3, 4))
        #expect(list.description == "(1 2 3 4)")
    }

    @Test func appendContentsOfSequence() {
        var list = VCons(1, 2)
        list.append(contentsOf: [3, 4])
        #expect(list == VCons(1, 2, 3, 4))
        list.append(contentsOf: 5...6)
        #expect(list == VCons(1, 2, 3, 4, 5, 6))
    }

    @Test func appendContentsOfEmptyIsNoOp() {
        var list = VCons(1, 2)
        list.append(contentsOf: VCons<Int>())
        #expect(list == VCons(1, 2))
        list.append(contentsOf: [Int]())
        #expect(list == VCons(1, 2))
    }

    @Test func appendContentsOfOntoEmpty() {
        var list = VCons<Int>()
        list.append(contentsOf: VCons(1, 2))
        #expect(list == VCons(1, 2))
    }

    @Test func concatenationVersusNesting() {
        var spliced = VCons(1, 2)
        spliced.append(contentsOf: VCons(3, 4))
        var nested = VCons(1, 2)
        nested.append(VCons(3, 4))
        #expect(spliced.description == "(1 2 3 4)")
        #expect(nested.description == "(1 2 (3 4))")
        #expect(spliced != nested)
    }

    @Test func plusOperator() {
        #expect(VCons(1, 2) + VCons(3, 4) == VCons(1, 2, 3, 4))
        #expect((VCons(1, 2) + VCons(3, 4)).description == "(1 2 3 4)")
    }

    @Test func plusWithEmpty() {
        #expect(VCons<Int>() + VCons(1, 2) == VCons(1, 2))
        #expect(VCons(1, 2) + VCons<Int>() == VCons(1, 2))
        #expect(VCons<Int>() + VCons<Int>() == VCons<Int>())
    }

    @Test func plusLeavesOperandsUntouched() {
        let lhs = VCons(1, 2)
        let rhs = VCons(3, 4)
        _ = lhs + rhs
        #expect(lhs == VCons(1, 2))
        #expect(rhs == VCons(3, 4))
    }

    @Test func plusIsAssociative() {
        let (a, b, c) = (VCons(1), VCons(2), VCons(3))
        #expect((a + b) + c == a + (b + c))
    }

    @Test func plusEquals() {
        var list = VCons(1, 2)
        list += VCons(3, 4)
        #expect(list == VCons(1, 2, 3, 4))
    }
}
