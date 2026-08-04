//: [VCons — the faithful cons cell](@previous)
/*:
# VList — the Array-compatible proper list

Element-typed, never improper, and a drop-in for Array-shaped code
(performance aside) — while still printing and thinking like Lisp.
*/
import ValueList
//: ## Building lists
VList(1, 2, 3).description              // (1 2 3)
VList([1, 2, 3]).description            // from an Array
VList(1...3).description                // from any Sequence
let literal: VList = [1, 2, 3]
literal.description
VList<Int>().description                // () — the empty list
VList(car: 1, cdr: VList(car: 2)).description  // cell by cell
//: ## The Lisp face
let list = VList(1, 2, 3)
list.car                                // 1 — nil iff empty
list.cdr?.description                   // (2 3) — nil when empty or single
list.cdr?.car                           // 2
var pushed = list
pushed.prepend(0)                       // O(1) — the natural growth direction
pushed.description                      // (0 1 2 3)
pushed.reversed().description           // (3 2 1 0)
//: ## Array-ish reads — Collection gives most of it for free
list.count
list.first
list.last
list[1]
list[1...].description                  // (2 3)
list.contains(2)
list.max()
list.reduce(0, +)
//: ## Array-ish writes
var edited = VList(1, 2, 3)
edited[1] = 20
edited.description                      // (1 20 3)
edited[1..<2] = VList(2)                // replaceSubrange semantics
edited.description                      // (1 2 3)
edited.append(4)
edited += VList(5)
edited.description                      // (1 2 3 4 5)
edited.removeFirst()                    // 1
edited.remove(at: 1)                    // 3
edited.description                      // (2 4 5)
edited.removeAll()
edited.description                      // ()
//: ## Transformations stay VLists
let chained = VList(5, 3, 1, 4, 2)
    .filter { $0 > 1 }
    .map { $0 * 10 }
    .sorted()
chained.description                     // (20 30 40 50)
VList("a", "b").flatMap { [$0, $0] }.description  // (a a b b)
let asArray: [Int] = chained.map { $0 / 10 }      // Array versions stay reachable
asArray
//: ## Value semantics
let original = VList(1, 2, 3)
var copy = original
copy[0] = 100
original.description                    // (1 2 3) — untouched
copy.description                        // (100 2 3)
Set([VList(1, 2), VList(1, 2), VList(3)]).count   // 2 — Hashable too
