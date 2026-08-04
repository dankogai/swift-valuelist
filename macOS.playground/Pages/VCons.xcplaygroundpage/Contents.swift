//: [Previous](@previous)

import ValueList

var cons = VCons(0,1,2,3)

cons.map{ $0.atom! }[2] + 2

cons[2].atom
