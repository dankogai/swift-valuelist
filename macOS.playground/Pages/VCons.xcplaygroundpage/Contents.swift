//: [Previous](@previous)

import ValueList

var cons = VCons(0,1,2,3)

cons.map{ $0.atom! }[2] + 2

var cons2 = VCons<Int>(0,1,2,3,cons)
cons2.description
//if case .Atom(let v) = cons[1] {
//    v
//    v + 1
//}

//for v in cons {
//    print(v)
//}

//: [Next](@next)
