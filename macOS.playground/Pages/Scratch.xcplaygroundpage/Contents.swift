//: [Previous](@previous)

import ValueList

var cons0 = Cons<Int>()
cons0.car = .Atom(0)
var cons1 = Cons(car:.Atom(0))

var cons2 = cons1
cons2.cdr = .Pair(cons0)
var cons3 = Cons(car:.Atom(0), cdr:.Pair(cons0))

cons2 == cons3
//: [Next](@next)
