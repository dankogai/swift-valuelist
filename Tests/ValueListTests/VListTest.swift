//
//  VListTest.swift
//  ValueList
//
//  Created by Dan Kogai on 2026-07-29.
//

import Testing
@testable import ValueList

@Suite struct VListTests {
    @Test func singleNode() {
        let list = VList(car: 42)
        #expect(list.car == 42)
        #expect(list.cdr == nil)
    }

    @Test func genericOverAnyElement() {
        #expect(VList(car: "swift").car == "swift")
        #expect(VList(car: 3.14).car == 3.14)
    }

    @Test func chaining() {
        let list = VList(car: 1, cdr: VList(car: 2, cdr: VList(car: 3)))
        #expect(list.car == 1)
        #expect(list.cdr?.car == 2)
        #expect(list.cdr?.cdr?.car == 3)
        #expect(list.cdr?.cdr?.cdr == nil)
    }

    @Test func carIsMutable() {
        var list = VList(car: 1)
        list.car = 10
        #expect(list.car == 10)
    }

    @Test func cdrIsAssignable() {
        var list = VList(car: 1)
        list.cdr = VList(car: 2)
        #expect(list.cdr?.car == 2)
        list.cdr = nil
        #expect(list.cdr == nil)
    }

    @Test func cdrReassignmentReplacesWholeTail() {
        var list = VList(car: 1, cdr: VList(car: 2, cdr: VList(car: 3)))
        list.cdr = VList(car: 9)
        #expect(list.cdr?.car == 9)
        #expect(list.cdr?.cdr == nil)
    }

    @Test func deepMutationThroughOptionalChaining() {
        var list = VList(car: 1, cdr: VList(car: 2, cdr: VList(car: 3)))
        list.cdr?.cdr?.car = 30
        #expect(list.cdr?.cdr?.car == 30)
        #expect(list.cdr?.car == 2)
    }

    @Test func growAndShrinkAtTheHead() {
        var list = VList(car: 2)
        list = VList(car: 1, cdr: list)   // push
        #expect(list.car == 1)
        #expect(list.cdr?.car == 2)
        list = list.cdr!                  // pop
        #expect(list.car == 2)
        #expect(list.cdr == nil)
    }

    @Test func longChainSurvives() {
        var list = VList(car: 999)
        for value in stride(from: 998, through: 0, by: -1) {
            list = VList(car: value, cdr: list)
        }
        var count = 0
        var walker: VList<Int>? = list
        while let current = walker {
            #expect(current.car == count)
            count += 1
            walker = current.cdr
        }
        #expect(count == 1000)
    }

    @Test func initFromArray() {
        let list = VList([1, 2, 3])
        #expect(list?.car == 1)
        #expect(list?.cdr?.car == 2)
        #expect(list?.cdr?.cdr?.car == 3)
        #expect(list?.cdr?.cdr?.cdr == nil)
    }

    @Test func initFromEmptyArrayFails() {
        #expect(VList<Int>([]) == nil)
    }

    @Test func initFromSingleElementArray() {
        let list = VList([42])
        #expect(list?.car == 42)
        #expect(list?.cdr == nil)
    }

    @Test func variadicInit() {
        let list = VList(1, 2, 3)
        #expect(list.car == 1)
        #expect(list.cdr?.car == 2)
        #expect(list.cdr?.cdr?.car == 3)
        #expect(list.cdr?.cdr?.cdr == nil)
        #expect(VList(42).cdr == nil)
    }

    @Test func variadicMatchesManualConstruction() {
        let viaInit = VList("a", "b", "c")
        let manual = VList(car: "a", cdr: VList(car: "b", cdr: VList(car: "c")))
        #expect(viaInit.car == manual.car)
        #expect(viaInit.cdr?.car == manual.cdr?.car)
        #expect(viaInit.cdr?.cdr?.car == manual.cdr?.cdr?.car)
    }

    @Test func descriptionPrintsLikeLisp() {
        #expect(VList(1, 2, 3).description == "(1 2 3)")
        #expect(VList(42).description == "(42)")
        #expect(VList("a", "b").description == "(a b)")
        #expect("\(VList(1, 2, 3))" == "(1 2 3)")
    }

    @Test func nestedListDescription() {
        // a VList of VLists prints its sublists recursively via their car
        let nested = VList(car: VList(1, 2), cdr: VList(car: VList(3, 4)))
        #expect(nested.description == "((1 2) (3 4))")
    }

    @Test func sequenceYieldsElementsInOrder() {
        #expect(Array(VList(1, 2, 3)) == [1, 2, 3])
        #expect(Array(VList(42)) == [42])
    }

    @Test func iterationDoesNotConsumeTheList() {
        let list = VList(1, 2, 3)
        #expect(Array(list) == Array(list))
    }

    @Test func sequenceAlgorithms() {
        let list = VList(1, 2, 3, 4)
        #expect(list.map { $0 * 2 } == [2, 4, 6, 8])
        #expect(list.reduce(0, +) == 10)
        #expect(list.contains(3))
        #expect(!list.contains(5))
        #expect(list.first { $0 > 2 } == 3)
        var collected = [Int]()
        for value in list { collected.append(value) }
        #expect(collected == [1, 2, 3, 4])
    }

    @Test func collectionCountAndFirst() {
        let list = VList(1, 2, 3)
        #expect(list.count == 3)
        #expect(list.first == 1)
        #expect(VList(42).count == 1)
        #expect(list.isEmpty == false)
    }

    @Test func subscriptByIndex() {
        let list = VList(10, 20, 30)
        var i = list.startIndex
        #expect(list[i] == 10)
        i = list.index(after: i)
        #expect(list[i] == 20)
        i = list.index(after: i)
        #expect(list[i] == 30)
        #expect(list.index(after: i) == list.endIndex)
    }

    @Test func indicesAreOrdered() {
        let list = VList(1, 2, 3)
        let first = list.startIndex
        let second = list.index(after: first)
        #expect(first < second)
        #expect(second < list.endIndex)
    }

    @Test func indexOffsetAndDistance() {
        let list = VList(10, 20, 30)
        #expect(list[list.index(list.startIndex, offsetBy: 2)] == 30)
        #expect(list.distance(from: list.startIndex, to: list.endIndex) == 3)
    }

    @Test func collectionAlgorithms() {
        let list = VList(1, 2, 3, 4)
        #expect(Array(list.dropFirst()) == [2, 3, 4])
        #expect(Array(list.prefix(2)) == [1, 2])
        #expect(Array(list.suffix(1)) == [4])
        #expect(list.firstIndex(of: 3).map { list[$0] } == 3)
        #expect(list.max() == 4)
        #expect(list.min() == 1)
    }

    @Test func collectionMatchesIterator() {
        let list = VList(1, 2, 3)
        var viaCollection = [Int]()
        var i = list.startIndex
        while i < list.endIndex {
            viaCollection.append(list[i])
            i = list.index(after: i)
        }
        #expect(viaCollection == Array(list))
    }

    @Test func equatable() {
        #expect(VList(1, 2, 3) == VList(1, 2, 3))
        #expect(VList(1, 2, 3) != VList(1, 2, 4))
        #expect(VList(1, 2, 3) != VList(1, 2))
        #expect(VList(1, 2) != VList(1, 2, 3))
        #expect(VList(42) == VList(42))
    }

    @Test func hashable() {
        #expect(VList(1, 2, 3).hashValue == VList(1, 2, 3).hashValue)
        let set: Set = [VList(1, 2), VList(3, 4), VList(1, 2)]
        #expect(set.count == 2)
    }

    @Test func initFromAnySequence() {
        #expect(VList(1...3) == VList(1, 2, 3))
        #expect(VList([1, 2, 3].lazy.map { $0 * 10 }) == VList(10, 20, 30))
        #expect(VList(EmptyCollection<Int>()) == nil)
    }

    @Test func last() {
        #expect(VList(1, 2, 3).last == 3)
        #expect(VList(42).last == 42)
    }

    @Test func subscriptByIntGet() {
        let list = VList(10, 20, 30)
        #expect(list[0] == 10)
        #expect(list[1] == 20)
        #expect(list[2] == 30)
    }

    @Test func subscriptByIntSet() {
        var list = VList(1, 2, 3)
        list[1] = 20
        #expect(list == VList(1, 20, 3))
        list[0] = 10
        list[2] = 30
        #expect(list == VList(10, 20, 30))
    }

    @Test func subscriptSetHasValueSemantics() {
        let original = VList(1, 2, 3)
        var copy = original
        copy[2] = 30
        #expect(original == VList(1, 2, 3))
        #expect(copy == VList(1, 2, 30))
    }

    @Test func appendElement() {
        var list = VList(1, 2)
        list.append(3)
        #expect(list == VList(1, 2, 3))
        var single = VList(1)
        single.append(2)
        #expect(single == VList(1, 2))
    }

    @Test func appendContentsOf() {
        var list = VList(1, 2)
        list.append(contentsOf: VList(3, 4))
        #expect(list == VList(1, 2, 3, 4))
        list.append(contentsOf: [5, 6])
        #expect(list == VList(1, 2, 3, 4, 5, 6))
        list.append(contentsOf: [Int]())
        #expect(list == VList(1, 2, 3, 4, 5, 6))
    }

    @Test func plusAndPlusEquals() {
        #expect(VList(1, 2) + VList(3, 4) == VList(1, 2, 3, 4))
        var list = VList(1, 2)
        list += VList(3, 4)
        #expect(list == VList(1, 2, 3, 4))
        let lhs = VList(1, 2)
        let rhs = VList(3, 4)
        _ = lhs + rhs
        #expect(lhs == VList(1, 2))
        #expect(rhs == VList(3, 4))
    }

    @Test func behavesLikeArray() {
        let list = VList(3, 1, 4, 1, 5)
        let array = [3, 1, 4, 1, 5]
        #expect(Array(list) == array)
        #expect(list.count == array.count)
        #expect(list.first == array.first)
        #expect(list.last == array.last)
        #expect(list[2] == array[2])
        #expect(list.sorted() == array.sorted())
        #expect(list.map { $0 * 2 } == array.map { $0 * 2 })
        #expect(list.filter { $0 > 2 } == array.filter { $0 > 2 })
        #expect(list.contains(5) == array.contains(5))
        #expect(list.max() == array.max())
        #expect(Array(list.reversed()) == array.reversed())
        #expect(Array(VList(1, 2) + VList(3, 4)) == [1, 2] + [3, 4])
    }

    @Test func valueSemantics() {
        let original = VList(car: 1, cdr: VList(car: 2))
        var copy = original
        copy.car = 10
        copy.cdr?.car = 20
        #expect(original.car == 1)
        #expect(original.cdr?.car == 2)
        #expect(copy.car == 10)
        #expect(copy.cdr?.car == 20)
    }

    @Test func sharedTailIsCopiedNotAliased() {
        let tail = VList(car: 2, cdr: VList(car: 3))
        var a = VList(car: 1, cdr: tail)
        let b = VList(car: 0, cdr: tail)
        a.cdr?.car = 20
        #expect(a.cdr?.car == 20)
        #expect(b.cdr?.car == 2)
        #expect(tail.car == 2)
    }
}
