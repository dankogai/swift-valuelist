//
//  main.swift
//  Benchmarks
//
//  How slow are VList and VCons against Array? Run locally with
//
//      swift run -c release Benchmarks [n]
//
//  (default n = 10_000; O(n²) cases are capped at 1_000). This target
//  is deliberately not a test: CI only runs `swift test`, so GitHub
//  never executes it.
//

import ValueList
import Foundation

@inline(never) func blackHole<T>(_ value: T) {
    withExtendedLifetime(value) {}
}

/// Best of three, in milliseconds.
func measure(_ body: () -> Void) -> Double {
    var best = Double.greatestFiniteMagnitude
    for _ in 0..<3 {
        let start = DispatchTime.now().uptimeNanoseconds
        body()
        let ms = Double(DispatchTime.now().uptimeNanoseconds - start) / 1e6
        best = min(best, ms)
    }
    return best
}

func format(_ ms: Double) -> String {
    return String(format: "%10.3fms", ms)
}
func ratio(_ ms: Double, to base: Double) -> String {
    return base > 0 ? String(format: "%8.1f×", ms / base) : "        —"
}

struct Row {
    let name: String
    let n: Int
    let array: Double
    let vlist: Double?
    let vcons: Double?
    func print() {
        var line = name.padding(toLength: 26, withPad: " ", startingAt: 0)
        line += String(format: "%7d", n)
        line += format(array)
        line += vlist.map { format($0) + ratio($0, to: array) } ?? "            —         —"
        line += vcons.map { format($0) + ratio($0, to: array) } ?? "            —         —"
        Swift.print(line)
    }
}

let n = CommandLine.arguments.dropFirst().first.flatMap { Int($0) } ?? 10_000
let nQuad = min(n, 1_000)   // for operations that are O(n²) on a linked list

// deterministic jumble: (k * 37) mod p walks all residues for prime-ish p
let jumbled = (0..<n).map { ($0 &* 2_654_435_761) % n }
let arrayData = Array(0..<n)
let vlistData = VList<Int>(0..<n)
var vconsData = VCons<Int>()
vconsData.append(contentsOf: 0..<n)
let vlistJumbled = VList(jumbled)
var vconsJumbled = VCons<Int>()
vconsJumbled.append(contentsOf: jumbled)
let arrayQuad = Array(0..<nQuad)
let vlistQuad = VList<Int>(0..<nQuad)
var vconsQuad = VCons<Int>()
vconsQuad.append(contentsOf: 0..<nQuad)

var rows = [Row]()

rows.append(Row(name: "build from Sequence", n: n,
    array: measure { blackHole(Array(0..<n)) },
    vlist: measure { blackHole(VList<Int>(0..<n)) },
    vcons: measure {
        var cons = VCons<Int>()
        cons.append(contentsOf: 0..<n)
        blackHole(cons)
    }))

rows.append(Row(name: "grow at the head ×n", n: n,
    array: measure {   // Array's honest analogue of prepend is insert(at: 0)
        var array = [Int]()
        for value in 0..<n { array.insert(value, at: 0) }
        blackHole(array)
    },
    vlist: measure {
        var list = VList<Int>()
        for value in 0..<n { list.prepend(value) }
        blackHole(list)
    },
    vcons: measure {
        var cons = VCons<Int>()
        for value in 0..<n { cons.prepend(.Atom(value)) }
        blackHole(cons)
    }))

rows.append(Row(name: "append ×n", n: nQuad,
    array: measure {
        var array = [Int]()
        for value in 0..<nQuad { array.append(value) }
        blackHole(array)
    },
    vlist: measure {
        var list = VList<Int>()
        for value in 0..<nQuad { list.append(value) }
        blackHole(list)
    },
    vcons: measure {
        var cons = VCons<Int>()
        for value in 0..<nQuad { cons.append(value) }
        blackHole(cons)
    }))

rows.append(Row(name: "iterate and sum", n: n,
    array: measure {
        var sum = 0
        for value in arrayData { sum &+= value }
        blackHole(sum)
    },
    vlist: measure {
        var sum = 0
        for value in vlistData { sum &+= value }
        blackHole(sum)
    },
    vcons: measure {
        var sum = 0
        for node in vconsData { sum &+= node.atom ?? 0 }
        blackHole(sum)
    }))

rows.append(Row(name: "subscript sweep [0..<n]", n: nQuad,
    array: measure {
        var sum = 0
        for i in 0..<nQuad { sum &+= arrayQuad[i] }
        blackHole(sum)
    },
    vlist: measure {
        var sum = 0
        for i in 0..<nQuad { sum &+= vlistQuad[i] }
        blackHole(sum)
    },
    vcons: measure {
        var sum = 0
        for i in 0..<nQuad { sum &+= vconsQuad[i].atom ?? 0 }
        blackHole(sum)
    }))

rows.append(Row(name: "map { $0 + 1 }", n: n,
    array: measure { blackHole(arrayData.map { $0 &+ 1 }) },
    vlist: measure { blackHole(vlistData.map { $0 &+ 1 }) },
    vcons: nil))

rows.append(Row(name: "reversed", n: n,
    array: measure { blackHole(Array(arrayData.reversed())) },
    vlist: measure { blackHole(vlistData.reversed()) },
    vcons: measure { blackHole(vconsData.reversed()) }))

rows.append(Row(name: "sorted", n: n,
    array: measure { blackHole(jumbled.sorted()) },
    vlist: measure { blackHole(vlistJumbled.sorted()) },
    vcons: measure { blackHole(vconsJumbled.sorted { ($0.atom ?? 0) < ($1.atom ?? 0) }) }))

print("swift-valuelist vs Array — n = \(n), O(n²) cases capped at \(nQuad); best of 3, release build")
print("")
print("operation                       n    Array          VList     ×/Arr      VCons     ×/Arr")
print(String(repeating: "-", count: 92))
for row in rows { row.print() }
