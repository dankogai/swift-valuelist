//
//  MergeSortTests.swift
//  ValueList
//

import Testing
@testable import ValueList

@Suite struct MergeSortTests {
    @Test func sortsAnySequence() {
        #expect([3, 1, 2].mergeSorted() == VList(1, 2, 3))
        #expect(stride(from: 9, through: 1, by: -2).mergeSorted() == VList(1, 3, 5, 7, 9))
        #expect(AnySequence([2, 1]).mergeSorted() == VList(1, 2))
    }

    @Test func edgeCases() {
        #expect([Int]().mergeSorted() == VList<Int>())
        #expect([42].mergeSorted() == VList(42))
        #expect([2, 2, 2].mergeSorted() == VList(2, 2, 2))
        #expect([1, 2, 3].mergeSorted() == VList(1, 2, 3))  // already sorted
    }

    @Test func sortsAHundredElements() {
        // (37k mod 101) for k in 1...100 is a permutation of 1...100
        let jumbled = (1...100).map { ($0 * 37) % 101 }
        #expect(jumbled.mergeSorted() == VList(1...100))
    }

    @Test func isStable() {
        // equal keys keep their original order: bb stays before aa
        let words = VList("bb", "aa", "c", "dd")
        #expect(words.sorted { $0.count < $1.count } == VList("c", "bb", "aa", "dd"))
    }

    @Test func comparatorVariants() {
        #expect(VList(1, 2, 3).sorted(by: >) == VList(3, 2, 1))
        #expect([1, 2, 3].mergeSorted(by: >) == VList(3, 2, 1))
    }

    @Test func vListSortedStillBehavesLikeArray() {
        let list = VList(3, 1, 4, 1, 5, 9, 2, 6)
        #expect(Array(list.sorted()) == [3, 1, 4, 1, 5, 9, 2, 6].sorted())
    }

    @Test func vConsSortsNodes() {
        let list = VCons(3, 1, 2)
        #expect(list.sorted { $0.atom! < $1.atom! } == VCons(1, 2, 3))
        // sublists sort by whatever the comparator says — here, element count
        let mixed = VCons<Int>(VCons(1, 2), 3)
        let sorted = mixed.sorted { ($0.pair?.count ?? 1) < ($1.pair?.count ?? 1) }
        #expect(sorted.description == "(3 (1 2))")
    }
}
