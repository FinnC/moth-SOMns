import "/../Modules/collections" as col
//inherit col.abbreviations
import "/../Modules/matrix" as matrix

method testCreateList {
    def l: List = col.abbreviations.list(15, 67, -8)
    if(l.at(1) != 15) then { return "testCreateList failed" }
    if(l.at(2) != 67) then { return "testCreateList failed" }
    if(l.at(3) != -8) then { return "testCreateList failed" }

    def l2: List = col.abbreviations.list
    if(l2.size != 0) then { return "testCreateList failed" }
    "testCreateList passed"
}

method testAddToList {
    def l: List = col.abbreviations.list(453, 7, 18)
    l.add(4)
    if(l.at(4) != 4) then { return "testAddToList failed" }

    l.addAll(col.abbreviations.list(6, 87, 34, 1))
    if(l.at(5) != 6) then { return "testAddToList failed" }
    if(l.at(6) != 87) then { return "testAddToList failed" }
    if(l.at(7) != 34) then { return "testAddToList failed" }
    if(l.at(8) != 1) then { return "testAddToList failed" }

    l.addAllFirst(col.abbreviations.list(56,78,2,9))
    if(l.at(1) != 56) then { return "testAddToList failed" }
    if(l.at(2) != 78) then { return "testAddToList failed" }
    if(l.at(3) != 2) then { return "testAddToList failed" }
    if(l.at(4) != 9) then { return "testAddToList failed" }

    l.addLast(4)
    if(l.at(l.size) != 4) then { return "testAddToList failed" }

    l.insert(1)at(3)
    if(l.at(3) != 1) then { return "testAddToList failed" }

    "testAddToList passed"
}

method testCopyList {
    def l: List = col.abbreviations.list(1,2,5,4)

    def l2 = l.copy
    if(l.at(1) != 1) then { return "testCopyList failed" }
    if(l.at(2) != 2) then { return "testCopyList failed" }
    if(l.at(3) != 5) then { return "testCopyList failed" }
    if(l.at(4) != 4) then { return "testCopyList failed" }

    "testCopyList passed"
}

method testRemoveFromList {
    def l: List = col.abbreviations.list(453, 7, 12, 76, 34, 18, 456, 8)

    if((l.removeLast != 8) || (l.size != 7)) then { return "testRemoveFromList failed" }
    if((l.removeAt(2) != 7) || (l.size != 6)) then { return "testRemoveFromList failed" }
    if((l.removeFirst != 453) || (l.size != 5)) then { return "testRemoveFromList failed" }
    l.remove(76)
    if(l.size != 4) then  { return "testRemoveFromList failed" }

    l.removeAll(col.abbreviations.seq(456, 12))
    if((l.size != 2)) then { return "testRemoveFromList failed" }

    l.clear
    if(l.size != 0) then { return "testRemoveFromList failed" }

    "testRemoveFromList passed"
}

method testContainsList {
    def l: List = col.abbreviations.list(453, 7, 18)
    if(!l.contains(453) || !l.contains(7) || !l.contains(18)) then {
        return "testContainsList failed"
    }

    if(l.contains(-12) || l.contains(1232) || l.contains(454)) then {
        return "testContainsList failed"
    }

    "testContainsList passed"
}

method testMapList {
    var a := col.abbreviations.list(1, 2, 3, 4)

    def mapped = a.map { num ->
        "map" ++ "{num}"
    }
    def iter = mapped.iterator
    def iter2 = a.iterator
    while{iter.hasNext} do {
        def str = "map" + "{iter2.next}"
        if(iter.next != str) then { "testMapList failed" }
    }

    "testMapList passed"
}

method testListFold {
    def input = col.abbreviations.list(3,5,7,9,11,13,15,17)
    def sum = input.fold {acc, each -> each + acc } startingWith 0
    if(sum != 80) then { return "testListFold failed" }
    def product = input.fold {acc, each -> each * acc } startingWith 1
    if(product != 34459425) then { return "testListFold failed" }
    def concatenation = input.fold {acc, each -> acc ++ each} startingWith ""
    if(concatenation != "3.05.07.09.011.013.015.017.0") then { return "testListFold failed" }
    "testListFold passed"
}

method testListFilter {
    def a = col.abbreviations.list(3,3,3,35,8,5,3)
    def filtera = a.filter {num ->
        num != 3
    }
    var iter := filtera.iterator
    while{iter.hasNext} do {
        if(iter.next == 3) then { return "testListFilter passed" }
    }
    "testListFilter passed"
}

method testAllSatisfyList {
    def a = col.abbreviations.list(4,4,4,4,4,4)
    var value := a.allSatisfy { num ->
        num == 4
    }
    if(!value) then { return "testAllSatisfyList failed" }
    value := a.allSatisfy { num ->
        num != 4
    }
    if(value) then { return "testAllSatisfyList failed" }
    "testAllSatisfyList passed"
}

method testFuncList {
    def a = col.abbreviations.list(1,2,3,4)
    def b = col.abbreviations.list(5,6,7)

    def a1 = a << b
    def a2 = a >> b

    if(a1.at(1) != 1) then { return "testFuncList failed" }
    if(a1.at(4) != 4) then { return "testFuncList failed" }
    if(a1.at(5) != 5) then { return "testFuncList failed" }
    if(a1.at(7) != 7) then { return "testFuncList failed" }

    if(a2.at(1) != 5) then { return "testFuncList failed" }
    if(a2.at(3) != 7) then { return "testFuncList failed" }
    if(a2.at(4) != 1) then { return "testFuncList failed" }
    if(a2.at(7) != 4) then { return "testFuncList failed" }
    "testFuncList passed"
}

method testCreateSeq {
    def s: Sequence = col.abbreviations.seq(15, 67, -8)
    if(s.at(1) != 15) then { return "testCreateSeq failed" }
    if(s.at(2) != 67) then { return "testCreateSeq failed" }
    if(s.at(3) != -8) then { return "testCreateSeq failed" }

    def s2: Sequence = col.abbreviations.seq()
    if(s2.size != 0) then { return "testCreateSeq failed" }
    "testCreateSeq passed"
}

method testAbsentSeq {
    def s = col.abbreviations.list(15, 67, -8)
    var v := s.at(2)ifAbsent{ -1 }
    if(v != 67) then { return "testAbsentSeq failed" }
    v := s.at(90)ifAbsent{ -1 }
    if(v != -1) then { return "testAbsentSeq failed" }

    v := s.indexOf(-8)ifAbsent{ -2 }
    if(v != 3) then { return "testAbsentSeq failed" }
    v := s.indexOf(45)ifAbsent{ -2 }
    if(v != -2) then { return "testAbsentSeq failed" }

    v := s.remove(67)ifAbsent{ -3 }
    if(s.size != 2) then { return "testAbsentSeq failed" }
    v := s.remove(99)ifAbsent{ -3 }
    if((v != -3) || (s.size != 2)) then { return "testAbsentSeq failed" }

    s.addAll(col.abbreviations.seq(45,91,89))

    v := s.removeAll(col.abbreviations.seq(45,91))ifAbsent{ -4 }
    if((v == -4) || (s.size != 3)) then { return "testAbsentSeq failed" }

    "testAbsentSeq passed"
}

method testContainsSeq {
    def s: Sequence = col.abbreviations.seq(453, 7, 18)
    if(!s.contains(453) || !s.contains(7) || !s.contains(18)) then {
        return "testContainsSeq failed"
    }

    if(s.contains(-12) || s.contains(1232) || s.contains(454)) then {
        return "testContainsSeq failed"
    }

    "testContainsSeq passed"
}

method testReverseSeq {
    def s = col.abbreviations.seq(56,234,2)

    def s2 = s.reversed

    if((s2.at(1) != 2) || (s2.at(2) != 234) || (s2.at(3) != 56)) then { "testReverseSeq failed" }

    "testReverseSeq passed"
}

method testCreateRange {
    def r = col.range.from(1)to(3)
    if(r.size != 3) then { return "testCreateRange failed" }
    if(r.at(1) != 1) then { return "testCreateRange failed" }
    if(r.at(2) != 2) then { return "testCreateRange failed" }
    if(r.at(3) != 3) then { return "testCreateRange failed" }

    def r2 = col.range.from(4)downTo(1)
    if(r2.at(1) != 4) then { return "testCreateRange failed" }
    if(r2.at(2) != 3) then { return "testCreateRange failed" }
    if(r2.at(3) != 2) then { return "testCreateRange failed" }
    if(r2.at(4) != 1) then { return "testCreateRange failed" }

    "testCreateRange passed"
}

method testContainsRange {
    def r = col.range.from(3)to(10)
    if(r.contains(-1) || r.contains(0) || r.contains(11)) then { return "testContainsRange failed" }
    if(!r.contains(3) || !r.contains(10) || !r.contains(5)) then { return "testContainsRange failed" }

    def r2 = col.range.from(8)downTo(2)
    if(r2.contains(-1) || r2.contains(0) || r2.contains(11)) then { return "testContainsRange failed" }
    if(!r2.contains(3) || !r2.contains(8) || !r2.contains(2)) then { return "testContainsRange failed" }

    "testContainsRange passed"
}

method testReverseRange {
    var r := col.range.from(3)to(10)
    r := r.reversed

    if((r.at(1) != 10) || (r.at(8) != 3)) then { return "testReverseRange failed" }

    r := col.range.from(5)downTo(1)
    r := r.reversed

    if((r.at(1) != 1) || (r.at(5) != 5)) then { return "testReverseRange failed" }

    "testReverseRange passed"
}

method testIndicesSeq {
    def s1: Sequence = col.abbreviations.seq(56, 87,120, -34)
    def s2: Sequence = s1.indices

    if(s2.size != 4) then { return "testIndicesSeq failed" }
    if(s2.at(1) != 1) then { return "testIndicesSeq failed" }
    if(s2.at(2) != 2) then { return "testIndicesSeq failed" }
    if(s2.at(3) != 3) then { return "testIndicesSeq failed" }
    if(s2.at(4) != 4) then { return "testIndicesSeq failed" }

    "testIndicesSeq passed"
}

method testCreateSet {
    var s: Set := col.abbreviations.set(2,1,1,2,2,3,-3)

    if(!s.contains(2) || !s.contains(1) || !s.contains(3) || !s.contains(-3)) then { return "testCreateSet failed" }
    //if(s.contains(0) || s.contains(192)) then { return "testCreateSet failed" }

    s := col.abbreviations.set(4,4,4,4,4,4)
    if(!s.contains(4) || !(s.size == 1)) then { return "testCreateSet failed" }

    "testCreateSet passed"
}

method testAddSet {
    var s: Set := col.abbreviations.set(1,2,3,4)
    s.add(2)
    s.add(8)
    if(!s.contains(8) || !(s.size == 5)) then { return "testAddSet failed" }

    s.add(-1)
    s.add(1)
    s.add(3)
    s.add(5)
    s.add(3)
    if(!s.contains(-1) || !s.contains(5) || !(s.size == 7)) then { return "testAddSet failed" }
    "testAddSet passed"
}

method testRemoveSet {
    var s : Set := col.abbreviations.set(1,2,3,4)
    s.remove(1)
    s.remove(2)
    s.remove(4)
    if(s.contains(1) || s.contains(2) || s.contains(4) || !(s.size == 1)) then { return "testRemoveSet failed" }

    s.clear
    if(s.size != 0) then { return "testRemoveSet failed" }

    "testRemoveSet passed"
}

method testCopySet {
    def s : Set = col.abbreviations.set(1,2,4,3)
    def s2 = s.copy

    if(!s.contains(1) || !s.contains(2) || !s.contains(3) || !s.contains(4)) then { return "testCopySet failed" }
    "testCopySet passed"
}

method testIntersectionSet {
    def s1 = col.abbreviations.set(1,2,3,4)
    def s2 = col.abbreviations.set(2,3)
    def s3 = s1 ** s2

    if(!s3.contains(2) || !s3.contains(3) || s3.contains(1) || s3.contains(4)) then { return "testIntersectionSet failed" }
    "testIntersectionSet passed"
}

method testDifferenceSet {
    def s1 = col.abbreviations.set(1,2,3,4,6,7,8)
    def s2 = col.abbreviations.set(3,4,5)
    def s3 = s1 -- s2
    if(!s3.contains(1) || !s3.contains(2) || !s3.contains(6) || !s3.contains(7) || !s3.contains(8)) then { return "testDifferenceSet failed"}
    "testDifferenceSet passed"
}

method testIsSubset {
    def s1 = col.abbreviations.set(1,2,3,4,5,6)
    def s2 = col.abbreviations.set(3,4,5)
    def s3 = col.abbreviations.set(6,7,8)

    if(s1.isSubset(s2)) then { return "testIsSubset failed" }
    if(!s2.isSubset(s1)) then { return "testIsSubset failed" }
    if(s3.isSubset(s1)) then { return "testIsSubset failed" }

    "testIsSubset passed"
}

method testIsSuperset {
    def s1 = col.abbreviations.set(1,2,3,4,5,6)
    def s2 = col.abbreviations.set(3,4,5)
    def s3 = col.abbreviations.set(6,7,8)

    if(!s1.isSuperset(s2)) then { "testIsSuperset failed" }
    if(s1.isSuperset(s3)) then { "testIsSuperset failed" }
    if(s2.isSuperset(s1)) then { "testIsSuperset failed" }

    "testIsSuperset passed"
}

method testIntoSet {
    def s1 = col.abbreviations.set(1,2,3,4,5,6)
    def s2 = col.abbreviations.set(7,8,4)

    s1.into(s2)
    if(!s2.contains(1) || !s2.contains(6) || s1.contains(7)) then { "testIntoSet failed" }

    "testIntoSet passed"
}

method testAnySatisfySet {
    def a = col.abbreviations.set(3,7,6,1,2,90)
    var value := a.anySatisfy { num ->
        num == 91
    }
    if(value) then { return "testAnySatisfy failed" }
    value := a.anySatisfy { num ->
        num == 90
    }
    if(!value) then { return "testAnySatisfy failed" }
    "testAnySatisfy passed"
}

method testMapSet {
    var a := col.abbreviations.set(1, 2, 3, 4)

    def mapped = a.map { num ->
        "map" ++ "{num}"
    }
    def iter = mapped.iterator
    def iter2 = a.iterator
    while{iter.hasNext} do {
        def str = "map" + "{iter2.next}"
        if(iter.next != str) then { "testMapSet failed" }
    }

    "testMapSet passed"
}

method testCreateDictionary {
    def d = col.abbreviations.dictionary("a" :: 12,"a" :: 12,"b" :: 13)

    if(d.size != 2) then { "testCreateDictionary failed" }
    if((d.at("a") != 12) || (d.at("b") != 13)) then { "testCreateDictionary failed" }
    "testCreateDictionary passed"
}

method testAddDictionary {
    def d = col.abbreviations.dictionary("a" :: 12, "b" :: 13)

    d.at("c")put(14)
    if(d.at("c") != 14) then { "testAddDictionary failed" }
    d.at("a")put(15)
    if(d.at("a") != 15) then { "testAddDictonary failed" }
    "testAddDictionary passed"
}

method testAbsentDictionary {
    def d = col.abbreviations.dictionary("a" :: 12,"a" :: 12,"b" :: 13)

    if(d.at("a")ifAbsent{ -3 } != 12) then { return "testAbsentDictionary failed" }
    if(d.at("r")ifAbsent{ -3 } != -3) then { return "testAbsentDictionary failed" }
    "testAbsentDictionary passed"
}

method testContainsDictionary {
    def d = col.abbreviations.dictionary("a" :: 12,"a" :: 12,"b" :: 13)

    if(!d.containsKey("a") || d.containsKey("r")) then { return "testContainsDictionary failed" }
    if(!d.containsValue(12) || !d.contains(13)) then { return "testContainsDictionary failed" }
    "testContainsDictionary passed"
}

method testRemoveDictionary {
    def d = col.abbreviations.dictionary("a" :: 12,"b" :: 13,"c" :: 14,"d" :: 15, "e" :: 16, "f" :: 17)

    d.removeKey("a")
    if((d.size != 5) || (d.containsKey("a")) || (d.containsValue(12))) then { return "testRemoveDictionary failed" }

    d.removeValue(14)
    if((d.size != 4) || d.containsKey("c") || d.containsValue(14)) then { return "testRemoveDictionary failed" }

    d.removeAllKeys(col.abbreviations.list("d", "e"))
    if((d.size != 2) || d.containsKey("d") || d.containsKey("e")) then { return "testRemoveDictionary failed" }

    d.clear
    if((d.size != 0) || d.containsKey("b") || d.containsKey("d")) then { return "testRemoveDictionary failed" }
    "testRemoveDictionary passed"
}

method testCopyDictionary {
    def d = col.abbreviations.dictionary("a" :: 12,"b" :: 13)

    def a = d.copy
    if(!a.containsKey("a") || !a.containsKey("b") || !a.contains(12) || !a.contains(13)) then { return "testCopyDictionary failed" }
    "testCopyDictionary passed"
}

method testFuncDictionary {
    var d1 := col.abbreviations.dictionary("a" :: 12,"b" :: 13)
    var d2 := col.abbreviations.dictionary("c" :: 14,"d" :: 15)

    var d3 := d1 ++ d2
    if(!d3.contains(12) || !d3.contains(13) || !d3.contains(14) || !d3.contains(15)) then { return "testFuncDictionary failed" }

    def d4 = d3 -- d1
    if(d4.contains(12) || d4.contains(13)) then { return "testFuncDictionary failed" }

    def d5 = d3 >> col.abbreviations.seq(1,2,3)

    d2 := col.abbreviations.dictionary("a" :: 14,"d" :: 15)
    d3 := d1 ++ d2
    if(!d3.contains(13) || !d3.contains(14) || !d3.contains(15)) then { return "testFuncDictionary failed" }
    "testFuncDictionary passed"
}

method testEqualsCollection {
    def a = col.abbreviations.seq(1,2,3,4)
    def b = col.abbreviations.seq(1,2,3,4,5,6,7)

    if(!(a == a)) then { "testEqualsCollection failed" }
    if(a == b) then { "testEqualsCollection failed" }

    "testEqualsCollection passed"
}

method testSortCollections {
    var l := col.abbreviations.list(6,4,0,1)

    l.sort
    if((l.at(1) != 0) || (l.at(2) != 1) || (l.at(3) != 4) || (l.at(4) != 6)) then { return "testSortCollections failed" }

    l := col.abbreviations.list(6,4,0,1)
    l.sortBy { l, r ->
        var v := -1
        if(l == r) then { v := 0}
        if(l < r) then { v := 1 }
        v
    }
    if((l.at(1) != 6) || (l.at(2) != 4) || (l.at(3) != 1) || (l.at(4) != 0)) then { return "testSortCollections failed" }

    var s := col.abbreviations.seq(9,2,8,4)
    l := s.sorted
    if((l.at(1) != 2) || (l.at(2) != 4) || (l.at(3) != 8) || (l.at(4) != 9)) then { return "testSortCollections failed" }
    l := s.sortedBy { l, r ->
        var v := -1
        if(l == r) then { v := 0}
        if(l < r) then { v := 1 }
        v
    }
    if((l.at(1) != 9) || (l.at(2) != 8) || (l.at(3) != 4) || (l.at(4) != 2)) then { return "testSortCollections failed" }
    "testSortCollections passed"
}

method testBinding {
    var o := 13 :: "g"
    var r := 13 :: "g"

    if((o.key != 13) || (o.value != "g")) then { return "testBinding failed, key and value failed" }
    if(!(o == r)) then { return "testBinding failed, equals failed" }
    "testBinding passed"
}

method testCreateMatrix {
    var m := matrix.matrix(1,4).withAll(col.abbreviations.seq(1,2,3,4))
    var m2 := matrix.matrix(2,4).withAll(col.abbreviations.seq(1,2,3,4,5,6,7,8))

    if((m.atRow(1)column(1) != 1) || (m.atRow(1)column(2) != 2) ||
     (m.atRow(1)column(3) != 3) || (m.atRow(1)column(4) != 4)) then "testCreateMatrix failed"

    if((m2.atRow(1)column(1) != 1) || (m2.atRow(1)column(2) != 2) ||
     (m2.atRow(1)column(3) != 3) || (m2.atRow(1)column(4) != 4)) then "testCreateMatrix failed"

    if((m2.atRow(2)column(1) != 5) || (m2.atRow(2)column(2) != 6) ||
     (m2.atRow(2)column(3) != 7) || (m2.atRow(2)column(4) != 8)) then "testCreateMatrix failed"

    //m := matrix.matrix(2,4).rows(col.abbreviations.seq(col.abbreviations.seq(1,2,3,4), col.abbreviations.seq(5,6,7,8))) //doesn't work
    //columns won't work as well

    "testCreateMatrix passed"
}

method testAddMatrix {
    var m := matrix.matrix(2,3).withAll(col.abbreviations.seq(1,2,3,4,5,6))
    var m2 := matrix.matrix(2,3).withAll(col.abbreviations.seq(1,2,3,4,5,6))

    def m3 = m + m2
    if((m3.atRow(1)column(1) != 2) || (m3.atRow(1)column(2) != 4) || (m3.atRow(1)column(3) != 6)
       || (m3.atRow(2)column(1) != 8) || (m3.atRow(2)column(2) != 10) || (m3.atRow(2)column(3) != 12)) then { return "testAddMatrix failed" }

    "testAddMatrix passed"
}

method testSubMatrix {
    var m := matrix.matrix(2,3).withAll(col.abbreviations.seq(1,2,3,4,5,6))
    var m2 := matrix.matrix(2,3).withAll(col.abbreviations.seq(1,2,3,4,5,6))

    def m3 = m - m2
    if((m3.atRow(1)column(1) != 0) || (m3.atRow(1)column(2) != 0) || (m3.atRow(1)column(3) != 0)
       || (m3.atRow(2)column(1) != 0) || (m3.atRow(2)column(2) != 0) || (m3.atRow(2)column(3) != 0)) then { return "testAddMatrix failed" }
    "testSubMatrix passed"
}

method testMulMatrix {
    var m := matrix.matrix(2,3).withAll(col.abbreviations.seq(1,2,3,4,5,6))

    var m3 := m * 2

    if((m3.atRow(1)column(1) != 2) || (m3.atRow(1)column(2) != 4) || (m3.atRow(1)column(3) != 6)
       || (m3.atRow(2)column(1) != 8) || (m3.atRow(2)column(2) != 10) || (m3.atRow(2)column(3) != 12)) then { return "testMulMatrix failed" }

    "testMulMatrix passed"
}

method testDivMatrix {
    var m := matrix.matrix(2,3).withAll(col.abbreviations.seq(1,2,3,4,5,6))

    var m3 := m / 2

    if((m3.atRow(1)column(1) != 0.5) || (m3.atRow(1)column(2) != 1.0) || (m3.atRow(1)column(3) != 1.5)
       || (m3.atRow(2)column(1) != 2.0) || (m3.atRow(2)column(2) != 2.5) || (m3.atRow(2)column(3) != 3.0)) then { return "testDivMatrix failed" }

    "testDivMatrix passed"
}

method testTimesMat {
    var m :=  matrix.matrix(2,3).withAll(col.abbreviations.seq(5,1,4,3,7,2))
    var m2 :=  matrix.matrix(3,3).withAll(col.abbreviations.seq(1,2,3,6,3,3,8,3,3))
    var m3 := m.times(m2)

    if((m3.atRow(1)column(1) != 43) || (m3.atRow(1)column(2) != 25) || (m3.atRow(1)column(3) != 30)
       || (m3.atRow(2)column(1) != 61) || (m3.atRow(2)column(2) != 33) || (m3.atRow(2)column(3) != 36)) then { return "testTimesMat failed" }

    "testTimesMat passed"
}

method testReshapeMat {
    var m :=  matrix.matrix(2,3).withAll(col.abbreviations.seq(5,1,4,3,7,2))

    m.reshapeWithNumRows(3)numColumns(2)
    if((m.numRows != 3) || (m.numColumns != 2)) then { return "testReshapeMat failed, reshapeWithNumRowsnumColumns failed" }

    m.reshapeWithNumRows(2)numColumns(4)additionalValues(col.abbreviations.seq(8,8))
    if((m.numRows != 2) || (m.numColumns != 4)) then { return "testReshapeMat failed, reshapeWithNumRowsnumColumns failed" }

    "testReshapeMat passed"
}

method testAddDelRowMat {
    var m :=  matrix.matrix(2,3).withAll(col.abbreviations.seq(5,1,4,3,7,2))

    m.addRow(col.abbreviations.seq(1,2,3))at(1)
    if((m.atRow(1)column(1) != 1) || (m.atRow(1)column(2) != 2) || (m.atRow(1)column(3) != 3)) then { return "testAddDelRowMat failed, add failed" }
    m.deleteRow(1)
    if((m.atRow(1)column(1) != 5) || (m.atRow(1)column(2) != 1) || (m.atRow(1)column(3) != 4)) then { return "testAddDelRowMat failed, delete failed" }

    "testAddDelRowMat passed"
}

method testAddDelColMat {
    var m := matrix.matrix(2,3).withAll(col.abbreviations.seq(5,1,4,3,7,2))

    m.addColumn(col.abbreviations.seq(1,2))at(2)
    if((m.atRow(1)column(2) != 1) || (m.atRow(2)column(2) != 2)) then { return "testAddDeColMat failed, add failed" }
    m.deleteColumn(2)
    if((m.atRow(1)column(2) != 1) || (m.atRow(2)column(2) != 7)) then { return "testAddDeColMat failed, delete failed" }
    "testAddDelColMat passed"
}

method testReplaceMat {
    var m :=  matrix.matrix(3,3).withAll(col.abbreviations.seq(1,2,3,6,3,3,8,3,3))

    m.replaceRowAt(1)with(col.abbreviations.seq(7,7,7))
    if((m.atRow(1)column(1) != 7) || (m.atRow(1)column(2) != 7) || (m.atRow(1)column(3) != 7)) then { return "testReplaceMat failed, replace row failed" }

    m.replaceColumnAt(2)with(col.abbreviations.seq(4,4,4))
    if((m.atRow(1)column(2) != 4) || (m.atRow(2)column(2) != 4) || (m.atRow(3)column(2) != 4)) then { return "testAddDeColMat failed, replace column failed" }

    "testReplaceMat passed"
}