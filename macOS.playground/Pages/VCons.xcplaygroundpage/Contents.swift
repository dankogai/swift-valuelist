/*:
# VCons — the faithful cons cell

Cars hold atoms or nested sublists, cdrs can be dotted, and everything
is a value: copies are independent, mutation never leaks.
*/
import ValueList
//: ## Building lists
let flat = VCons(1, 2, 3)
flat.description                        // (1 2 3)
let nested = VCons<Int>(1, VCons(2, 3), 4)
nested.description                      // (1 (2 3) 4)
let sublists = VCons(VCons(1, 2), VCons(3, 4))
sublists.description                    // ((1 2) (3 4)) — a VCons<Int>
let dotted = VCons(car: .Atom(1), cdr: .Atom(2))
dotted.description                      // (1 . 2)
VCons<Int>().description                // ()
//: ## car, cdr, and nodes — unwrap with .atom and .pair
flat.car
flat.car?.atom                          // 1
flat.cdr?.pair?.description             // (2 3)
nested[1].pair?.description             // (2 3)
nested[1].pair?[0].atom                 // 2 — subscripts chain through sublists
//: ## Iteration yields nodes
for node in nested {
    node.description                    // 1, (2 3), 4
}
flat.map { $0.atom! }                   // [1, 2, 3]
nested.compactMap { $0.atom }           // [1, 4] — top-level atoms only
nested.atoms().description              // (1 2 3 4) — every leaf, as a VList
dotted.atoms().description              // (1 2) — dotted tails count
//: ## Growing — prepend is O(1), append walks
var grown = VCons(2, 3)
grown.prepend(.Atom(1))
grown.description                       // (1 2 3)
grown.append(4)
grown.description                       // (1 2 3 4)
grown.append(VCons(5, 6))               // a sublist...
grown.description                       // (1 2 3 4 (5 6))
grown.append(contentsOf: VCons(7, 8))   // ...whereas contentsOf splices
grown.description                       // (1 2 3 4 (5 6) 7 8)
(VCons(1, 2) + VCons(3, 4)).description // (1 2 3 4)
//: ## Subscripts — by Int and by Range, like Array
let list = VCons(0, 1, 2, 3, 4)
list[2].atom                            // 2
list[1..<3].description                 // (1 2)
list[2...].description                  // (2 3 4)
var edited = list
edited[0] = .Atom(100)
edited[1..<3] = VCons(9)                // replaceSubrange semantics — resizes
edited.description                      // (100 9 3 4)
//: ## Sorting — a stable merge sort, no Array round-trip
VCons(3, 1, 2).sorted { $0.atom! < $1.atom! }.description  // (1 2 3)
//: ## Reversal is cell-preserving
list.reversed().description             // (4 3 2 1)
var flipped = VCons(1, 2, 3)
flipped.reverse()
flipped.description                     // (3 2 1)
//: ## Value semantics
let original = VCons(1, 2, 3)
var copy = original
copy[0] = .Atom(100)
original.description                    // (1 2 3) — untouched
copy.description                        // (100 2 3)
original == VCons(1, 2, 3)              // true
//: [VList — the Array-compatible proper list](@next)
