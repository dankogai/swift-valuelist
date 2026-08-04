//
//  VCons.swift
//  ValueList
//
//  Created by Dan Kogai on 2026-07-29.
//

import Testing
@testable import ValueList

@Suite struct EquatabilityTests {
    @Test func atomEquality() {
        #expect(VCons<Int>.Node.Atom(42) == VCons<Int>.Node.Atom(42))
        #expect(VCons<Int>.Node.Atom(42) != VCons<Int>.Node.Atom(43))
        #expect(VCons<String>.Node.Atom("swift") == VCons<String>.Node.Atom("swift"))
        #expect(VCons<String>.Node.Atom("swift") != VCons<String>.Node.Atom("lisp"))
    }

    @Test func atomVsPair() {
        let atom = VCons<Int>.Node.Atom(0)
        let pair = VCons<Int>.Node.Pair(VCons(car: .Atom(0)))
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
        func make() -> VCons<Int>.Node {
            .Pair(VCons(
                car: .Pair(VCons(car: .Atom(1), cdr: .Atom(2))),
                cdr: .Pair(VCons(car: .Atom(3), cdr: nil))
            ))
        }
        #expect(make() == make())
    }

    @Test func nestedInequality() {
        let lhs = VCons<Int>.Node.Pair(VCons(car: .Pair(VCons(car: .Atom(1), cdr: nil)), cdr: nil))
        let rhs = VCons<Int>.Node.Pair(VCons(car: .Pair(VCons(car: .Atom(2), cdr: nil)), cdr: nil))
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

    @Test func listOfSublists() {
        // VCons(vcons, vcons) infers VCons<Int>, not the absurd VCons<VCons<Int>>
        let list = VCons(VCons(1, 2), VCons(3, 4))
        #expect(type(of: list) == VCons<Int>.self)
        #expect(list.description == "((1 2) (3 4))")
        #expect(list[0].pair == VCons(1, 2))
        #expect(list[1].pair == VCons(3, 4))
        #expect(list.count == 2)
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
        #expect(VCons<Int>.Node.Atom(42).description == "42")
        #expect(VCons<String>.Node.Atom("swift").description == "swift")
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

@Suite struct CollectionTests {
    @Test func emptyCollection() {
        let empty = VCons<Int>()
        #expect(empty.startIndex == empty.endIndex)
        #expect(empty.count == 0)
        #expect(empty.first == nil)
    }

    @Test func countAndFirst() {
        let list = VCons(1, 2, 3)
        #expect(list.count == 3)
        #expect(list.first == .Atom(1))
    }

    @Test func subscriptByIndex() {
        let list = VCons(1, 2, 3)
        var i = list.startIndex
        #expect(list[i] == .Atom(1))
        i = list.index(after: i)
        #expect(list[i] == .Atom(2))
        i = list.index(after: i)
        #expect(list[i] == .Atom(3))
        #expect(list.index(after: i) == list.endIndex)
    }

    @Test func indicesAreOrdered() {
        let list = VCons(1, 2, 3)
        let first = list.startIndex
        let second = list.index(after: first)
        #expect(first < second)
        #expect(second < list.endIndex)
    }

    @Test func indexOffsetBy() {
        let list = VCons(10, 20, 30)
        let i = list.index(list.startIndex, offsetBy: 2)
        #expect(list[i] == .Atom(30))
        #expect(list.distance(from: list.startIndex, to: list.endIndex) == 3)
    }

    @Test func collectionMatchesIterator() {
        // Collection traversal must agree with the Sequence iterator,
        // including nil-car skipping and dropping the atom cdr of a dotted pair
        let cases: [VCons<Int>] = [
            VCons(1, 2, 3),
            VCons(car: .Atom(1), cdr: .Atom(2)),
            VCons(car: nil, cdr: .Pair(VCons(car: .Atom(2), cdr: .Pair(VCons(car: nil))))),
            VCons(),
        ]
        for list in cases {
            var viaCollection = [VCons<Int>.Node]()
            var i = list.startIndex
            while i < list.endIndex {
                viaCollection.append(list[i])
                i = list.index(after: i)
            }
            #expect(viaCollection == Array(list))
        }
    }

    @Test func nilCarsAreSkipped() {
        let list = VCons<Int>(car: nil, cdr: .Pair(VCons(car: .Atom(2))))
        #expect(list.count == 1)
        #expect(list.first == .Atom(2))
    }

    @Test func dottedPairHasCountOne() {
        let pair = VCons(car: .Atom(1), cdr: .Atom(2))
        #expect(pair.count == 1)
        #expect(pair.first == .Atom(1))
    }

    @Test func collectionAlgorithms() {
        let list = VCons(1, 2, 3, 4)
        #expect(Array(list.dropFirst()) == [.Atom(2), .Atom(3), .Atom(4)])
        #expect(Array(list.prefix(2)) == [.Atom(1), .Atom(2)])
        #expect(Array(list.suffix(1)) == [.Atom(4)])
        #expect(list.firstIndex(of: .Atom(3)).map { list[$0] } == .Atom(3))
    }
}

@Suite struct IntSubscriptTests {
    @Test func getByPosition() {
        let list = VCons(10, 20, 30)
        #expect(list[0] == .Atom(10))
        #expect(list[1] == .Atom(20))
        #expect(list[2] == .Atom(30))
    }

    @Test func atomUnwrapsElement() {
        let list = VCons(10, 20, 30)
        #expect(list[0].atom == 10)
        #expect(list[1].atom == 20)
        #expect(list[0].pair == nil)
    }

    @Test func pairUnwrapsSublist() {
        let list = VCons<Int>(1, VCons(2, 3), 4)
        #expect(list[1].pair == VCons(2, 3))
        #expect(list[1].pair?[0].atom == 2)
        #expect(list[1].atom == nil)
    }

    @Test func getSkipsNilCars() {
        let list = VCons<Int>(car: nil, cdr: .Pair(VCons(car: .Atom(2))))
        #expect(list[0].atom == 2)
    }

    @Test func getFromDottedPair() {
        #expect(VCons(car: .Atom(1), cdr: .Atom(2))[0].atom == 1)
    }

    @Test func setElement() {
        var list = VCons(1, 2, 3)
        list[1] = .Atom(20)
        #expect(list == VCons(1, 20, 3))
        #expect(list.description == "(1 20 3)")
        list[0] = .Atom(10)
        list[2] = .Atom(30)
        #expect(list == VCons(10, 20, 30))
    }

    @Test func setSublist() {
        var list = VCons(1, 2, 3)
        list[1] = .Pair(VCons(8, 9))
        #expect(list == VCons<Int>(1, VCons(8, 9), 3))
        #expect(list.description == "(1 (8 9) 3)")
    }

    @Test func setSkipsNilCars() {
        var list = VCons<Int>(car: nil, cdr: .Pair(VCons(car: .Atom(2))))
        list[0] = .Atom(20)
        #expect(list.description == "(nil 20)")
    }

    @Test func setHasValueSemantics() {
        let original = VCons(1, 2, 3)
        var copy = original
        copy[1] = .Atom(20)
        #expect(original == VCons(1, 2, 3))
        #expect(copy == VCons(1, 20, 3))
    }
}

@Suite struct PrependReverseTests {
    @Test func prependOntoEmptyFillsCar() {
        var list = VCons<Int>()
        list.prepend(.Atom(1))
        #expect(list == VCons(1))
        #expect(list.description == "(1)")
    }

    @Test func prependGrowsAtTheHead() {
        var list = VCons(2, 3)
        list.prepend(.Atom(1))
        #expect(list == VCons(1, 2, 3))
        list.prepend(.Pair(VCons(0)))
        #expect(list.description == "((0) 1 2 3)")
    }

    @Test func prependedLeavesOriginalUntouched() {
        let original = VCons(2, 3)
        let grown = original.prepended(.Atom(1))
        #expect(original == VCons(2, 3))
        #expect(grown == VCons(1, 2, 3))
    }

    @Test func reversedProperList() {
        #expect(VCons(1, 2, 3).reversed() == VCons(3, 2, 1))
        #expect(VCons(42).reversed() == VCons(42))
        #expect(VCons<Int>().reversed() == VCons<Int>())
    }

    @Test func reversedPreservesNilCarCells() {
        // (1 nil 2) reversed is (2 nil 1) — the hole survives
        let list = VCons<Int>(car: .Atom(1),
                              cdr: .Pair(VCons(car: nil,
                                               cdr: .Pair(VCons(car: .Atom(2))))))
        #expect(list.reversed().description == "(2 nil 1)")
    }

    @Test func reverseInPlace() {
        var list = VCons(1, 2, 3)
        list.reverse()
        #expect(list == VCons(3, 2, 1))
    }
}

@Suite struct RangeSubscriptTests {
    @Test func rangeSubscriptGet() {
        let list = VCons(0, 1, 2, 3, 4)
        #expect(list[1..<3] == VCons(1, 2))
        #expect(list[1...3] == VCons(1, 2, 3))
        #expect(list[2...] == VCons(2, 3, 4))
        #expect(list[..<2] == VCons(0, 1))
        #expect(list[...2] == VCons(0, 1, 2))
        #expect(list[...] == list)
        #expect(list[1..<1].isEmpty)
    }

    @Test func rangeSubscriptKeepsSublistNodes() {
        let list = VCons<Int>(1, VCons(2, 3), 4)
        #expect(list[1..<2].description == "((2 3))")
        #expect(list[1...] == VCons<Int>(VCons(2, 3), 4))
    }

    @Test func rangeSubscriptCountsOccupiedCells() {
        // positions follow iteration: nil cars are skipped
        let list = VCons<Int>(car: nil, cdr: .Pair(VCons(1, 2, 3)))
        #expect(list[0..<2] == VCons(1, 2))
    }

    @Test func rangeSubscriptSet() {
        var list = VCons(0, 1, 2, 3, 4)
        list[1..<3] = VCons(9)
        #expect(list == VCons(0, 9, 3, 4))          // shrinks like replaceSubrange
        list[1..<2] = VCons(1, 2)
        #expect(list == VCons(0, 1, 2, 3, 4))       // grows back
        list[3...] = VCons<Int>()
        #expect(list == VCons(0, 1, 2))             // empty replacement removes
        list[...] = VCons(7, 8)
        #expect(list == VCons(7, 8))
    }

    @Test func rangeSubscriptSetHasValueSemantics() {
        let original = VCons(1, 2, 3)
        var copy = original
        copy[0..<2] = VCons(9)
        #expect(original == VCons(1, 2, 3))
        #expect(copy == VCons(9, 3))
    }
}

@Suite struct AtomsTests {
    @Test func flatList() {
        #expect(VCons(1, 2, 3).atoms() == VList(1, 2, 3))
        #expect(VCons(42).atoms() == VList(42))
        #expect(VCons<Int>().atoms() == VList<Int>())
    }

    @Test func nestedSublistsAreFlattened() {
        #expect(VCons<Int>(1, VCons(2, 3), 4).atoms() == VList(1, 2, 3, 4))
        // ((1 2) (3 (4 5)))
        let deep = VCons<Int>(VCons(1, 2), VCons<Int>(3, VCons(4, 5)))
        #expect(deep.atoms() == VList(1, 2, 3, 4, 5))
    }

    @Test func dottedPairIncludesTailAtom() {
        #expect(VCons(car: .Atom(1), cdr: .Atom(2)).atoms() == VList(1, 2))
        // (1 (2 . 3) 4)
        let list = VCons<Int>(1, VCons(car: .Atom(2), cdr: .Atom(3)), 4)
        #expect(list.atoms() == VList(1, 2, 3, 4))
    }

    @Test func nilCarsAreSkipped() {
        let list = VCons<Int>(car: nil, cdr: .Pair(VCons(car: .Atom(2), cdr: .Pair(VCons(car: nil)))))
        #expect(list.atoms() == VList(2))
    }
}
