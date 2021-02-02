//for memory allocation of the collections
class mem {
    class allocate(s) {
        var arr := platform.kernel.Array.new(s)

        method putAt(index : Integer, value) {
            arr.at(index.asInteger)put(value)
        }

        method at(n : Integer) {
            arr.at(n.asInteger)
        }

        method size {
            arr.size
        }
    }
}

method abs(n) {
    if(n < 0) then {- n} else {n}
}

method max(n1, n2) {
    if(n1 > n2) then { n1 } else { n2 }
}

type Iterator[[T]] = interface {
    hasNext -> Boolean
    next -> T
}

type Collection[[T]] = interface {
    iterator -> Iterator[[T]]
    at(n:Number) -> T
    isEmpty -> Boolean
    size -> Number
    sizeIfUnknown(action: Function0[[Number]]) -> Number
    first -> T
    do(action: Function1[[T, Unknown]]) -> Done
    do(action: Function1[[T, Unknown]]) separatedBy(sep:Function0[[Unknown]]) -> Done
    map[[R]](unaryFunction:Function1[[T,R]]) -> Collection[[T]]
    fold[[R]](binaryFunction:Function2[[R,T,R]])startingWith(initial:R) -> R
    filter(condition:Function1[[T, Boolean]]) -> Collection[[T]]
    anySatisfy(condition:Function1[[T, Boolean]]) -> Boolean
    allSatisfy(condition:Function1[[T, Boolean]]) -> Boolean
    ++(other:Enumerable[[T]]) -> Collection[[T]]
    ==(other: Object) -> Boolean
    >>(target:Sink[[T]]) -> Collection[[T]]
    <<(source:Enumerable[[T]]) -> Collection[[T]]
}

type CollectionFactory[[T]] = interface {
    with(element:T) -> Collection[[T]]
    withAll(elements:Collection[[T]]) -> Collection[[T]]
    <<(source:Collection[[T]]) -> Collection[[T]]
    empty -> Collection[[T]]
}

type Enumerable[[T]] = Collection[[T]] & interface {
    values -> Enumerable[[T]]
    keysAndValuesDo(action:Function2[[Number, T, Object]]) -> Done
    sorted -> List[[T]]
    sortedBy(sortBlock:Function2[[T,T,Number]]) -> List[[T]]
}

type Expandable[[T]] = Collection[[T]] & interface {
    addAll(xs: Collection[[T]]) -> Self
}

type Sequenceable[[T]] = Enumerable[[T]] & interface {
    at[[W]](n:Number) ifAbsent(action:Function0[[W]]) -> T | W
    indices -> Sequence[[Number]]
    keys -> Sequence[[Number]]
    indexOf(sought:T) -> Number
    indexOf[[W]](sought:T) ifAbsent(action:Function0[[W]]) -> Number | W
    contains(sought: T) -> Boolean
    second -> T
    third -> T
    fourth -> T
    fifth -> T
    last -> T
    reversed -> Sequence[[T]]
}

type Sequence[[T]] = Sequenceable[[T]] & interface {
}

type List[[T]] = Sequenceable[[T]] & interface {
    at(ix:Number) put(v:T)
    add(new:T) -> List[[T]]
    addLast(new:T) -> List[[T]]
    addFirst(new:T) -> List[[T]]
    addAll(xs: Collection[[T]]) -> List[[T]]
    addAllFirst(news: Collection[[T]]) -> List[[T]]
    remove(sought:T) -> List[[T]]
    remove(sought:T) ifAbsent(action:Function0[[Unknown]]) -> List[[T]]
    removeFirst -> T
    removeAt(n: Number) -> T
    removeLast -> T
    removeAll(elements: Collection[[T]]) -> List[[T]]
    removeAll(elements: Collection[[T]]) ifAbsent(action:Function0[[Unknown]]) -> List[[T]]
    insert(elt:T)at(n:Number) -> List[[T]]
    clear -> List[[T]]
    insert(element:T)at(n:Number) -> List[[T]]
    sort -> List[[T]]
    sortBy(sortBlock:Function2[[T,T,Number]]) -> List[[T]]
    copy -> List[[T]]
}

type Set[[T]] = Collection[[T]] & interface {
    add(element:T) -> Set[T]
    addAll(elements: Iterable[[T]]) -> Self
    remove(element: T) -> Set[[T]]
    remove(element: T) ifAbsent(block: Function0[[Done]]) -> Set[[T]]
    removeAll(elems:Collection[[T]])
    removeAll(elems:Collection[[T]]) ifAbsent(block: Function1[[T,Done]]) -> Set[[T]]
    contains(element:T) -> Boolean
    clear -> Set[[T]]
    find(predicate: Function1[[T, Boolean]]) ifNone(notFoundBlock: Function0[[T]]) -> T
    copy -> Set[[T]]
    ** (other:Set[[T]]) -> Set[[T]]
    -- (other:Set[[T]]) -> set[[T]]
    isSubset(s2: Set[[T]]) -> Boolean
    isSuperset(s2: Collection[[T]]) -> Boolean
    into(existing:Collection[[T]]) -> Collection[[T]]
}

type Binding[[K,T]] = {
    key -> K
    value -> T
    hash -> Number
    == (x) -> Boolean
}

type DictionaryFactory[[K,T]] = interface {
    empty -> Dictionary[[K,T]]
    with(initialBinding:Binding[[K,T]]) -> Dictionary[[K,T]]
    withAll(initialBindings:Binding[[K,T]]) -> Dictionary[[K,T]]
    <<(source:Binding[[K,T]]) -> Dictionary[[K,T]]
}

type Dictionary[[K,T]] = Collection[[T]] & interface {
    size -> Number
    at(key:K) put(value:T) -> Dictionary[[K,T]]
    at(k:K) -> T
    at(k:K) ifAbsent(action:Function0[[T]]) -> T
    containsKey(k:K) -> Boolean
    containsValue(v:T) -> Boolean
    contains(v:T) -> Boolean
    removeAllKeys(keys: Collection[[K]]) -> Self
    removeKey(key: K) -> Self
    removeAllValues(removals: Collection[[T]]) -> Self
    removeValue(removal: T) -> Self
    clear -> Dictionary[[T]]
    keys -> Collection[[K]]
    values -> Collection[[T]]
    bindings -> Enumerable[[Binding[[K,T]]]]
    keysAndValuesDo(action:Procedure2[[K,T]]) -> Done
    keysDo(action:Procedure1[[T]]) -> Done
    valuesDo(action:Procedure1[[T]]) -> Done
    copy -> Self
    ++(other:Dictionary[[K,T]]) -> Dictionary[[K,T]]
    --(other:Dictionary[[K,T]]) -> Dictionary[[K,T]]
    >>(target:Sink[[Binding[[K,T]]]])
    <<(source:Collection[[Binding[[K,T]]]])
}

//implementation
class collectionFactoryTrait[[T]] { //TODO: make into a trait when traits are implemented
    method withAll(elements:Collection[[T]]) -> Collection[[T]] { abstract }
    method with(element) -> Collection[[T]] { self.withAll [self] }
    method <<(source) -> Collection[[T]] { self.withAll(source) }
    method empty -> Unknown { self.withAll [] }
}

class dictionaryFactoryTrait[[T]] { //TODO: make into a trait when traits are implemented
    method withAll(initialBindings) -> Dictionary[[K,T]] { abstract }
    method with(initialBinding) -> Dictionary[[K,T]] { self.withAll [self] }
    method <<(source) -> Dictionary[[K,T]] { self.withAll(source) }
    method empty -> Dictionary[[K,T]] { self.withAll [] }
}

class iteratorConcat[[T]](left:Iterator[[T]], right:Iterator[[T]]) {
    print "aaa"
    method next {
        print "at her31"
        if(left.hasNext) then {
            left.next
        } else {
            right.next
        }
    }
    method hasNext {
        if(left.hasNext) then { return true }   //error of if then not working for rows() matrix is found here
        return right.hasNext
    }
    method asString { "an iterator over a concatenation" }
}

class lazyConcatenation[[T]](left,right) -> Enumerable[[T]] {
    //TODO: add use enumerable[[Collection[[T]]]] when use works
    inherit enumerable[[T]]
    method iterator {
        var t := iteratorConcat(left.iterator, right.iterator)
        t
    }
    method size { left.size + right.size }
}

class lazySequenceOver[[T,R]](source: Collection[[T]]) mappedBy(function:Block1[[T,R]]) -> Enumerable[[R]] {
    inherit enumerable[[T]]   //getting null location assertion error here

    class iterator {
        def sourceIterator = source.iterator
        method asString { "an iterator over a lazy map sequence" }
        method hasNext {sourceIterator.hasNext}
        method next {function.apply(sourceIterator.next)}
    }
    method size { source.size }
    method isEmpty { source.isEmpty }
    method asString {
        var str := "map ["
        def iter = self.iterator
        while{iter.hasNext} do {
            str := str + " {iter.next} "
        }
        str := str + "]"
    }
}

class lazySequenceOver[[T,R]](source: Collection[[T]]) filteredBy(predicate:Block1[[T,Boolean]]) {
    //inherit enumerable[[T]] //getting null location assertion error here
    class iterator {
        var cache
        var cacheLoaded := false
        var count := 1
        def sourceIterator = source.iterator
        method asString {"an iterator over filter {source}"}
        method hasNext {
            if(cacheLoaded) then {return true}
            if(getNext) then {return true}
            return false
        }
        method next {
            if(!cacheLoaded) then {getNext}
            cacheLoaded := false
            return cache
        }

        method getNext { //TODO: add is confidential when it works properly
            var i := count
            while {sourceIterator.hasNext} do {
                def outerNext = sourceIterator.next
                def acceptable = predicate.apply(outerNext)
                if(acceptable) then {
                    cacheLoaded := true
                    cache := outerNext
                    count := i
                    return true
                }
                i := i + 1
            }

            return false
        }
    }
    method size { source.size }
    method at(index) {
        def iter = iterator
        var i := 1
        while {iter.hasNext} do {
            def e = iter.next
            if(i == index) then { return e }
            i := i + 1
        }
    }
}

method isEqual(left) toCollection(right) {
    //TODO: add type checking to check that right is iterable
    def leftIter = left.iterator
    def rightIter = right.iterator
    while{leftIter.hasNext && rightIter.hasNext} do {
        if(leftIter.next != rightIter.next) then {
            return false
        }
    }
    leftIter.hasNext == rightIter.hasNext
}

class collection[[T]] {
    var size is readable := 0

    method sizeIfUnknown(action) {
        action.apply
    }

    method isEmpty { size == 0 }

    method first {
        if(isEmpty) then { error("no elements in sequence")}
        inner.at(1)
    }

    method do(block1) {
        var iter := self.iterator

        while {iter.hasNext} do {   //ERROR FOR MATRIX ROWS, VALUE FROM NEXT DOESN'T EXIST?
            block1.apply(iter.next)
        }
    }

    method do(block1) separatedBy(block0) {
        var firstTime := true
        self.do { each ->
            if(firstTime) then {
                firstTime := false
            } else {
                block0.apply
            }
            block1.apply(each)
        }
        return self
    }

    method at(n) { abstract }

    method ++(other) {
        def l = list.withAll(self)
        l.addAll(other)
        list.withAll(l)
    }

    method ==(other) {
        isEqual(self) toICollection(other)
    }

    method >>(target) { target << self }

    method <<(source) { self ++ source }

    method map[[R]](block1:Block1[[T,R]]) {
        lazySequenceOver(self) mappedBy(block1)
    }

    method fold(blk)startingWith(initial) {
        var result := initial
        self.do {it ->
            result := blk.apply(result, it)
        }
        result
    }

    method filter(selectionCondition:Block1[[T,Boolean]]) {
        lazySequenceOver(self) filteredBy(selectionCondition)
    }

    method anySatisfy(condition:Block1[[T, Boolean]]) {
        do { each ->
            if(condition.apply(each)) then { return true }
        }
        false
    }

    method allSatisfy(condition:Block1[[T, Boolean]]) {
        do { each ->
            if(!condition.apply(each)) then { return false }
        }
        true
    }

    method iterator {
        object {
            var idx := 1
            method asString { "anIterator" }
            method hasNext { idx <= size }
            method next {
                if(idx > size) then { error("iterator exhausted")}
                def ret = at(idx)
                idx := idx + 1
                ret
            }
        }
    }
}

//enumerable collection
class enumerable[[T]] {
    inherit collection[[T]]
    method values { self }

    method valuesAndKeysDo(action) {
        var index := 0
        def selfIterator = self.iterator
        while {selfIterator.hasNext} do {
            index := index + 1
            action.apply(index, selfIterator.next)
        }
    }

    method sorted {
        var l := list.withAll(self)
        l.sort
        return l
    }

    method sortedBy(sortBlock) {
        var l := list.withAll(self)
        l.sortBy(sortBlock)
        return l
    }
}

//sequenceable collection
class sequenceable[[T]] {
    inherit enumerable[[T]]

    method sizeIfUnknown(action) { size }

    method indices {
        range.from 1 to(size)
    }

    method keys {   //for dictionaries
        range.from 1 to(size)
    }

    method at(n) {
        boundsCheck(n)
        inner.at(n)
    }

    method at(n) ifAbsent(action) {
        if(!(!(n >= 1) || !(n <= size))) then {
            inner.at(n)
        } else {
            action.apply
        }
    }

    method indexOf(sought) {
        var i := 1
        while {i <= size} do {
            if(inner.at(i) == sought) then {
                return i
            }
            i := i + 1
        }
        error("No such object in this sequenceable")
    }

    method indexOf(sought) ifAbsent(action) {
        var i := 1
        while {i <= size} do {
            if(inner.at(i) == sought) then {
                return i
            }
            i := i + 1
        }
        action.apply
    }

    method contains(sought) {
        var iter := iterator
        while { iter.hasNext } do {
            if(iter.next == sought) then {
                return true
            }
        }
        return false
    }

    method second {
        if(size < 2) then { error("index out of bounds") }
        inner.at(2)
    }

    method third {
        if(size < 3) then { error("index out of bounds") }
        inner.at(3)
    }

    method fourth {
        if(size < 4) then { error("index out of bounds") }
        inner.at(4)
    }

    method fifth {
        if(size < 5) then { error("index out of bounds") }
        inner.at(5)
    }

    method last {
        if(isEmpty) then { error("no elements in sequence") }
        inner.at(size)
    }

    method boundsCheck(n: Number) { //TODO: add is confidential when it works properly
        if ( !(n >= 1) || !(n <= size)) then {
            error("index out of bounds")
        }
    }

    method reversed {
        def newL = list.empty
        var ix := size
        while {ix > 0} do {
            newL.add(self.at(ix))
            ix := ix - 1
        }
        seq.withAll(newL)
    }
}

//sequence collection
class seq[[T]] {
    inherit collectionFactoryTrait[[T]]

    method withAll(a: Array) -> Sequence[[T]] {
        object {
            inherit sequenceable[[T]]
            //variables
            def initialSize = a.size
            var inner := mem.allocate(initialSize)

            var i := 1
            while { i <= initialSize } do {
                inner.putAt(i, a.at(i))
                i := i + 1
                size := size + 1
            }

            method asString {
                var str := "seq ["
                def iter = self.iterator
                while {iter.hasNext} do {
                    str := str + " {iter.next} "
                }
                str := str + "]"
                str
            }
        }
    }
}

//range collection
class range {
    var start is readable := 0
    var stop is readable := 0

    method from(lower)to(upper) -> Sequence[[Number]] {
        object {
            inherit sequenceable[[T]]
            //TODO: add match case for checking that lower and upper are numbers
            //checking that lower and upper are integers
            start := lower.asInteger
            if(start != lower) then {
                error "lower is not an integer"
            }
            stop := upper.asInteger
            if(stop != upper) then {
                error "upper is not an integer"
            }

            def size = if ((upper - lower + 1) < 0) then { 0 } else {upper - lower + 1}    //override size from collection
            //TODO: adding hash for range

            method at(ix:Number) {  //override at from sequenceable
                if(ix > self.size) then {
                    error "requested range.at({ix}), but upper bound is {size}"
                }
                if(ix < 1) then {
                    error "requested range.at({ix}), but lower bound is 1"
                }
                return start + (ix - 1)
            }

            method contains(elem) -> Boolean {  //override contains from sequenceable
                //TODO: replace with try catch when try catch is implemented
                def intElem = elem.asInteger
                if(intElem != elem) then { return false }
                if(intElem < start) then { return false }
                if(intElem > stop) then { return false }
                return true
            }

            method do(block1) { //TODO add is override when it is implemented
                var val := start
                while {val <= stop} do {
                    block1.apply(val)
                    val := val + 1
                }
            }

            method reversed {
                from(upper)downTo(lower)
            }

            method iterator -> Iterator {   //TODO add is override when it is implemented
                object {
                    var val := start
                    method hasNext { val <= stop }
                    method next {
                        if (val > stop) then {error "iterator exhausted"}
                        val := val + 1
                        return (val - 1)
                    }
                }
            }

            method asString -> String {
                "range.from {lower} to {upper}"
            }
        }
    }

    method from(upper)downTo(lower) -> Sequence[[Number]] {
        object {
            inherit sequenceable[[T]]
            //TODO: add match case for checking that lower and upper are numbers
            //checking that lower and upper are integers
            start := upper.asInteger
            if(start != upper) then {
                error "upper is not an integer"
            }
            stop := lower.asInteger
            if(stop != lower) then {
                error "lower is not an integer"
            }

            def size is public =    //TODO add is override when it is implemented
                if((upper - lower + 1) < 0) then { 0 } else { upper - lower + 1}

            method at(ix: Number) { //TODO add is override when it is implemented
                if(ix > self.size) then {
                    error "requested range.at({ix}), but upper bound is {size}"
                }
                if(ix < 1) then {
                    error "requested range.at({ix}), but lower bound is 1"
                }
                return start - (ix - 1)
            }

            method contains(elem) -> Boolean {  //TODO add is override when it is implemented
                //TODO: replace with try catch when try catch is implemented
                def intElem = elem.asInteger
                if(intElem != elem) then { return false }
                if(intElem > start) then { return false }
                if(intElem < stop) then { return false }
                return true
            }

            method do(block1) { //TODO add is override when it is implemented
                var val := start
                while {val >= stop} do {
                    block1.apply(val)
                    val := val - 1
                }
            }

            method reversed {
                from(lower)to(upper)
            }

            method ++(other) {
                sequence.withAll(self, other)
            }

            method iterator {   //TODO add is override when it is implemented
                object {
                    var val := start
                    method hasNext { val >= stop }
                    method next {
                        if(val < stop) then {error "iterator exhausted"}
                        val := val - 1
                        return (val + 1)
                    }
                    method asString { "an Iterator over {super.asString}"}
                }
            }

            method asString -> String {
                "range.from {upper} down to {lower}"
            }
        }
    }
}

//list collection
class list[[T]] {
    inherit collectionFactoryTrait[[T]]
    method withAll(a) -> List[[T]] {
        object {
            inherit sequenceable[[T]]
            var size is readable := 0
            def initialSize = a.size
            var inner := mem.allocate(initialSize)  //TODO: when using java use initialSize for size

            var i := 1
            while { i <= initialSize} do {
                inner.putAt(i, a.at(i))
                i := i + 1
                size := size + 1
            }

            method at(n) put(v) {
                if(n == (size + 1)) then {
                    addLast(v)
                } else {
                    boundsCheck(n)
                    inner.putAt((n), v)
                }
            }

            method add(e) {
                addAll( abbreviations.seq(e))
            }

            method addLast(e) {
                add(e)
            }

            method addAll(l) {
                //when running out of space
                if((size + l.size) > inner.size) then {
                    expandTo(max(size + l.size, size * 2))
                }
                def iter = l.iterator

                var i := size + 1
                while {iter.hasNext} do {
                    inner.putAt(i, iter.next)
                    i := i + 1
                    size := size + 1
                }
                self
            }

            method addAllFirst(l) {
                if((size + l.size) > inner.size) then {
                    expandTo(max(size + l.size, size * 2))
                }
                //create new list
                def lis = list.empty
                var iter := l.iterator
                while { iter.hasNext } do {
                    lis.add(iter.next)
                }
                iter := self.iterator
                while {iter.hasNext} do {
                    lis.add(iter.next)
                }

                var i := 1
                while {i <= lis.size} do {
                    inner.putAt(i, lis.at(i))
                    i := i + 1
                }
                size := size + l.size

                self
            }

            method remove(sought) {
                removeCheck
                def index = indexOf(sought)
                removeAt(index)
                self
            }

            method remove(sought) ifAbsent(action) {
                def index = self.indexOf(sought) ifAbsent {
                    return action.apply
                }
                removeAt(index)
                self
            }

            method removeFirst {
                removeCheck
                removeAt(1)
            }

            method removeAt(n) {
                removeCheck
                boundsCheck(n)
                def removed = inner.at(n)
                var i := n + 1
                while { i <= size } do {
                    inner.putAt((i - 1), inner.at(i))
                    i := i + 1
                }
                size := size - 1
                return removed
            }

            method removeLast {
                removeCheck
                def result = inner.at(size)
                size := size - 1
                result
            }

            method removeAll(elements) {
                var i := 1
                while {i <= elements.size} do {
                    def ix = indexOf(elements.at(i))
                    removeAt(ix)
                    i := i + 1
                }
                self
            }

            method removeAll(elements) ifAbsent(action) {
                elements.do { each ->
                    def index = indexOf(each) ifAbsent { 0 }
                    if(index != 0) then {
                        removeAt(index)
                    } else {
                        action.apply
                    }
                }
                self
            }

            method clear {
                var i := size
                while {i > 0} do {
                    removeLast
                    i := i - 1
                }
                self
            }

            method insert(elt:T) at(n) {
                boundsCheck(n)
                if((size + 1) > inner.size) then {
                    expandTo(size + 1)
                }
                var i := size
                while {i >= n} do {
                    inner.putAt((i + 1), inner.at(i))
                    i := i - 1
                }
                inner.putAt(n, elt)
                size := size + 1
                self
            }

            method sort {
                sortBy { l, r ->
                    var v := 1
                    if(l == r) then { v := 0}
                    if(l < r) then { v := -1 }
                    v
                }
            }

            method sortBy(sortBlock) {
                quicksort(1, size, sortBlock)
            }

            method copy {
                withAll(self)
            }

            method asString {
                var str := "list ["
                def iter = self.iterator
                while {iter.hasNext} do {
                    str := str + " {iter.next} "
                }
                str := str + "]"
                str
            }

            method quicksort(left, right, sortBlock) { //TODO: add is confidential when it works properly
                if(left < right) then {
                    var p := partition(left, right, sortBlock)
                    quicksort(left, p, sortBlock)
                    quicksort(p + 1, right, sortBlock)
                }
            }

            method partition(left, right, sortBlock) { //TODO: add is confidential when it works properly
                var pivot := at(left)
                var i := left - 1
                var j := right + 1
                while { true } do {
                    do {
                        i := i + 1
                    } while { sortBlock.apply(at(i), pivot) == -1 } //get(j) < pivot } //FIX
                    do {
                        j := j - 1
                    } while { sortBlock.apply(at(j), pivot) == 1 } //get(j) > pivot }  //FIX
                    if(i >= j) then {
                        return j
                    }
                    def temp = at(i)
                    inner.putAt(i, at(j))
                    inner.putAt(j, temp)
                }
            }

            method removeCheck {    //TODO: add is confidential when it works properly
                if(size == 0) then {
                    error("nothing left to remove")
                }
            }

            method expandTo(newSize) { //TODO: add is confidential when it works properly
                def newInner = mem.allocate(newSize)
                var i := 1
                while {i <= size} do {
                    newInner.putAt(i, inner.at(i))
                    i := i + 1
                }
                inner := newInner
            }
        }
    }
}

//set collection
class set {
    inherit collectionFactoryTrait[[T]]

    method withAll(a) -> Set[[T]] {
        object {
            inherit collection[[T]]

            def initialSize = a.size
            var dict := dictionary.empty

            def present = object {
                def present = true
                method asString { "present" }
            }

            addAll(a)

            method size {
                dict.size
            }

            method add(e) {
                addAll [e]
            }

            method addAll(elements) {
                var i := 1
                while { i <= elements.size} do {
                    dict.at(elements.at(i))put(present)
                    i := i + 1
                }
                self
            }

            method remove(e) {
                removeAll(abbreviations.seq(e))
            }

            method remove(e) ifAbsent(block) {
                removeAll [ e ] ifAbsent(block)
            }

            method removeAll(elements) {
                var i := 1
                while{i <= elements.size} do {
                    dict.removeKey(elements.at(i))   //TODO: when exceptions are implemented, add exception to removeKey which can be caught here and then thrown
                    i := i + 1
                }
                self
            }

            method removeAll(elements) ifAbsent(block) {
                var i := 1
                while{i <= elements.size} do {
                    var e := elements.at(i)
                    if(dict.containsKey(e)) then {
                        dict.removeKey(e)
                    } else {
                        block.apply
                    }
                    i := i + 1
                }
            }

            method do(action) {
                dict.keysDo(action)
            }

            method clear {
                dict.clear
                self
            }

            method contains(sought) {
                dict.containsKey(sought)
            }

            method find(booleanBlock) ifNone(notFoundBlock) {
                self.dict.keysDo { each ->
                    if(booleanBlock.apply(each)) then { return each }
                }
                return notFoundBlock.apply
            }

            method copy {
                def s = list.empty
                def iter = self.iterator
                while {iter.hasNext} do {
                    s.add(iter.next)
                }
                withAll(s)
            }

            method **(other) {
                def newSet = set.empty
                other.dict.keysDo { each ->
                    if(other.contains(each)) then { newSet.add(each) }
                }
                newSet
            }

            method --(other) {
                def result = set.empty
                result.dict := dict -- other.dict
                result
            }

            method isSubset(s2) {
                self.dict.keysDo{ each ->
                    if(!s2.dict.containsKey(each)) then { return false }
                }
                return true
            }

            method isSuperset(s2) {
                self.dict.keysDo{ each ->
                    if(!self.dict.containsKey(each)) then { return false }
                }
                return true
            }

            method into(existing: Expandable[[T]]) {
                dict.keysDo { each ->
                    existing.add(each)
                }
                existing
            }

            method iterator {   //TODO add is override when it is implemented
                dict.keys.iterator
            }

            method map[[R]](block1:Block1[[T,R]]) { //TODO: add is override when it is implemented
                lazySequenceOver(self) mappedBy(block1)
            }

            method anySatisfy(condition:Block1[[T, Boolean]]) {
                dict.keysDo { each ->
                    if(condition.apply(each)) then { return true }
                }
                false
            }

            method asString {
                var str := "set ["
                def iter = dict.keys.iterator
                while {iter.hasNext} do {
                    str := str + " {iter.next} "
                }
                str := str + "]"
                str
            }
        }
    }
}

class dictionary {
    inherit collectionFactoryTrait[[T]]

    method withAll(initialBindings) -> Dictionary[[K,T]] {
        object {
            //inherit collection[[T]] //   TODO: causes null location error
            var numBindings := 0
            var inner := mem.allocate(8)
            def unused = object {
                var unused := true
                def key is public = self
                def value is public = self
                method asString { "unused" }
            }
            def removed = object {
                var removed := true
                def key is public = self
                def value is public = self
                method asString { "removed" }
            }

            var i := 1
            while{i <= inner.size} do {
                inner.putAt(i, unused)
                i := i + 1
            }

            initialBindings.do { b ->
                at(b.key)put(b.value)
            }

            method size {
                numBindings
            }

            method add(binding) {
                self.at(binding.key)put(binding.value)
            }

            method addAll(bindings) {
                bindings.do{ each -> add(each) }
                self
            }

            method at(key)put(value) {
                var t := findPositionForAdd(key)
                if((inner.at(t) == unused) || (inner.at(t) == removed)) then {
                    numBindings := numBindings + 1
                }
                inner.putAt(t, key :: value)
                if((size * 2) > inner.size) then { expand }
                self
            }

            method at(key) {
                var t := findPosition(key)
                var b := inner.at(findPosition(key))
                if(b.key == key) then {
                    return b.value
                }
                error "dictionary does not contain entry with key {key}"
            }

            method at(key)ifAbsent(action) {
                var t := findPosition(key)
                var b := inner.at(findPosition(key))
                if(b.key == key) then {
                    return b.value
                }
                action.apply
            }

            method containsKey(key) {
                var t := findPosition(key)
                if(inner.at(t).key == key) then {
                    return true
                }
                return false
            }

            method containsValue(v) {
                self.valuesDo{ each ->
                    if(v == each) then { return true }
                }
                return false
            }

            method contains(value) {
                containsValue(value)
            }

            method removeAllKeys(keys) {
                keys.do { k ->
                    var t := findPosition(k)
                    if(inner.at(t).key == k) then {
                        inner.putAt(t, removed)
                        numBindings := numBindings - 1
                    } else {
                        error("dictionary does not contain entry with key {k}")
                    }
                }
                return self
            }

            method removeKey(key) {
                removeAllKeys [key]
            }

            method removeAllValues(removals) {
                var i := 1
                while{i <= inner.size} do {
                    def a = inner.at(i)
                    if(removals.contains(a.value)) then {
                        inner.putAt(i, removed)
                        numBindings := numBindings - 1
                    }
                    i := i + 1
                }
                return self
            }

            method removeValue(removal) {
                removeAllValues [removal]
            }

            method clear {
                var i := 1
                while{ i <= inner.size } do {
                    if((inner.at(i) != unused) && (inner.at(i) != removed)) then {
                        inner.putAt(i, removed)
                        numBindings := numBindings - 1
                    }
                    i := i + 1
                }
                self
            }

            method keys {
                def sourceDict = self
                object {
                    //inherit enumerable[[T]]   //   TODO: causes null location error
                    def sourceDictInner = sourceDict
                    class iterator {
                        def sourceIterator = sourceDictInner.bindingsIterator
                        method hasNext { sourceIterator.hasNext }
                        method next { sourceIterator.next.key }
                        method asString { "an iterator over keys of {sourceDictionary}" }
                    }
                    def size is public = sourceDict.size
                }
            }

            method values {
                def sourceDict = self
                object {
                    //inherit enumerable[[T]]   //   TODO: causes null location error
                    def sourceDictInner = sourceDict
                    class iterator {
                        def sourceIterator = sourceDictInner.bindingsIterator
                        method hasNext { sourceIterator.hasNext }
                        method next { sourceIterator.next.value }
                        method asString { "an iterator over values of {sourceDictionary}" }
                    }
                    def size is public = sourceDict.size
                }
            }

            method bindings {
                def sourceDict = self
                object {
                    //inherit enumerable[[T]]   //   TODO: causes null location error
                    def sourceDictInner = sourceDict
                    method iterator { sourceDictInner.bindingsIterator }
                    def size is public = sourceDict.size
                }
            }

            method keysAndValuesDo(action) {
                var i := 1
                while{i <= inner.size} do {
                    def a = inner.at(i)
                    if((a != unused) && (a != removed)) then {
                        action.apply(a.key)
                        action.apply(a.value)
                    }
                    i := i + 1
                }
            }

            method keysDo(action) {
                var i := 1
                while{i <= inner.size} do {
                    def a = inner.at(i)
                    if((a != unused) && (a != removed)) then {
                        action.apply(a.key)
                    }
                    i := i + 1
                }
            }

            method valuesDo(action) {
                var i := 1
                while {i <= inner.size} do {
                    def a = inner.at(i)
                    if((a != unused) && (a != removed)) then {
                        action.apply(a.value)
                    }
                    i := i + 1
                }
            }

            method do(action) {
                valuesDo(action)
            }

            method copy {
                def newCopy = dictionary.empty
                self.keysDo { k ->
                    def v = at(k).value
                    newCopy.at(k)put(v)
                }
                newCopy
            }

            method ++(other) {
                def newDict = self.copy
                other.keysDo { k ->
                    def v = other.at(k).value
                    newDict.at(k)put(v)
                }
                newDict
            }

            method --(other) {
                def newDict = dictionary.empty
                keysDo { k ->
                    if(!other.containsKey(k)) then {
                        def v = at(k).value
                        newDict.at(k)put(v)
                    }
                }
                newDict
            }

            method >>(target) {
                target << self.bindings
            }

            method <<(source) {
                self.addAll(source)

            }

            method iterator { values.iterator }

            method asString {
                var str := "dictionary ["
                def iter = self.bindings.iterator
                while {iter.hasNext} do {
                    str := str + " {iter.next} "
                }
                str := str + "]"
                str
            }

            class bindingsIterator {    //TODO: add is confidential when it works properly
                var count := 1
                var index := 1
                var elt

                method hasNext { size >= count }
                method next {
                    if(size < count) then { error("iterator exhausted") }
                    while {
                        elt := inner.at(index)
                        (elt == unused) || (elt == removed)
                    } do {
                        index := index + 1
                    }
                    count := count + 1
                    index := index + 1
                    elt
                }
            }

            method findPosition(x) {  //TODO: add is confidential when it works properly
                def h = x.hash
                def s = inner.size - 1
                var t := abs(h % s)
                var jump := 5
                var candidate
                while {
                    candidate := inner.at(t + 1)    //adding 1 so that t can not reach 0
                    candidate != unused
                } do {
                    if(candidate.key == x) then {
                        return t + 1
                    }
                    if(jump != 0) then {
                        t := abs((t * 3 + 1) % s)
                        jump := jump - 1
                    } else {
                        t := abs((t + 1) % s)
                    }
                }
                return t + 1
            }

            method findPositionForAdd(x) {  //TODO: add is confidential when it works properly
                def h = x.hash
                def s = inner.size - 1
                var t := abs(h % s)
                var jump := 5
                var candidate
                while {
                    candidate := inner.at(t + 1)    //adding 1 so that t can not reach 0
                    (candidate != unused) && (candidate != removed)
                } do {
                    if(candidate.key == x) then {
                        return t + 1
                    }
                    if(jump != 0) then {
                        t := abs((t * 3 + 1) % s)
                        jump := jump - 1
                    } else {
                        t := abs((t + 1) % s)
                    }
                }
                return t + 1
            }

            method expand {  //TODO: add is confidential when it works properly
                def c = inner.size
                def newSize = c * 2
                def oldInner = inner
                numBindings := 0
                inner := mem.allocate(newSize)
                var i := 1
                while {i <= newSize} do {
                    inner.putAt(i, unused)
                    i := i + 1
                }
                i := 1
                while {i <= oldInner.size} do {
                    def v = oldInner.at(i)
                    if(v != unused) then {
                        at(v.key)put(v.value)
                    }
                    i := i + 1
                }
            }

        }
    }
}

def outerAccess = self  //outer pointer for abbreviations class
class abbreviations {
    method seq {outerAccess.seq.empty }
    method seq(a) { outerAccess.seq.withAll [a] }
    method seq(a,b) { outerAccess.seq.withAll [a,b] }
    method seq(a,b,c) { outerAccess.seq.withAll [a,b,c] }
    method seq(a,b,c,d) { outerAccess.seq.withAll [a,b,c,d] }
    method seq(a,b,c,d,e) { outerAccess.seq.withAll [a,b,c,d,e] }
    method seq(a,b,c,d,e,f) { outerAccess.seq.withAll [a,b,c,d,e,f] }
    method seq(a,b,c,d,e,f,g) { outerAccess.seq.withAll [a,b,c,d,e,f,g] }
    method seq(a,b,c,d,e,f,g,h) { outerAccess.seq.withAll [a,b,c,d,e,f,g,h] }
    method seq(a,b,c,d,e,f,g,h,i) { outerAccess.seq.withAll [a,b,c,d,e,f,g,h,i] }

    method list { outerAccess.list.empty }
    method list(a) { outerAccess.list.withAll (seq(a)) }
    method list(a,b) { outerAccess.list.withAll (seq(a,b)) }
    method list(a,b,c) { outerAccess.list.withAll (seq(a,b,c)) }
    method list(a,b,c,d) { outerAccess.list.withAll (seq(a,b,c,d)) }
    method list(a,b,c,d,e) { outerAccess.list.withAll (seq(a,b,c,d,e)) }
    method list(a,b,c,d,e,f) { outerAccess.list.withAll (seq(a,b,c,d,e,f)) }
    method list(a,b,c,d,e,f,g) { outerAccess.list.withAll (seq(a,b,c,d,e,f,g)) }
    method list(a,b,c,d,e,f,g,h) { outerAccess.list.withAll (seq(a,b,c,d,e,f,g,h)) }
    method list(a,b,c,d,e,f,g,h,i) { outerAccess.list.withAll (seq(a,b,c,d,e,f,g,h,i)) }

    method set { outerAccess.set.empty }
    method set(a) { outerAccess.set.withAll (seq(a)) }
    method set(a,b) { outerAccess.set.withAll (seq(a,b)) }
    method set(a,b,c) { outerAccess.set.withAll (seq(a,b,c)) }
    method set(a,b,c,d) { outerAccess.set.withAll (seq(a,b,c,d)) }
    method set(a,b,c,d,e) { outerAccess.set.withAll (seq(a,b,c,d,e)) }
    method set(a,b,c,d,e,f) { outerAccess.set.withAll (seq(a,b,c,d,e,f)) }
    method set(a,b,c,d,e,f,g) { outerAccess.set.withAll (seq(a,b,c,d,e,f,g)) }
    method set(a,b,c,d,e,f,g,h) { outerAccess.set.withAll (seq(a,b,c,d,e,f,g,h)) }
    method set(a,b,c,d,e,f,g,h,i) { outerAccess.set.withAll (seq(a,b,c,d,e,f,g,h,i)) }

    method dictionary(a) { outerAccess.dictionary.withAll (seq(a)) }
    method dictionary(a,b) { outerAccess.dictionary.withAll (seq(a,b)) }
    method dictionary(a,b,c) { outerAccess.dictionary.withAll (seq(a,b,c)) }
    method dictionary(a,b,c,d) { outerAccess.dictionary.withAll (seq(a,b,c,d)) }
    method dictionary(a,b,c,d,e) { outerAccess.dictionary.withAll (seq(a,b,c,d,e)) }
    method dictionary(a,b,c,d,e,f) { outerAccess.dictionary.withAll (seq(a,b,c,d,e,f)) }
    method dictionary(a,b,c,d,e,f,g) { outerAccess.dictionary.withAll (seq(a,b,c,d,e,f,g)) }
    method dictionary(a,b,c,d,e,f,g,h) { outerAccess.dictionary.withAll (seq(a,b,c,d,e,f,g,h)) }
    method dictionary(a,b,c,d,e,f,g,h,i) { outerAccess.dictionary.withAll (seq(a,b,c,d,e,f,g,h,i)) }
}

//...........................................0.........0...........................................
//...........................................00.......00...........................................
//............................................0.......0............................................
//..............................................00000..............................................
//............................................000000000............................................
//..0000000000000000000000000000000000000000000.00000.0000000000000000000000000000000000000000000..
//...000000000000000000i....i00000000000000000.0.000.0.00000000000000000i....i000000000000000000...
//.....00000000000000i..0000..i00000000000000.00..0..00.00000000000000i..0000..i00000000000000.....
//........00000000000..000000..000000000000..000.....000..000000000000..000000..00000000000........
//..........000000000i..0000..i0000000000..00000..0..00000..0000000000i..0000..i0000000000.........
//............000000000i....i0000000000..00000...000...00000..0000000000i....i000000000............
//...............000000000000000000...0000000...00000...0000000...000000000000000000...............
//..................000000000000...000000000...0000000...000000000...000000000000..................
//...............................0000000000..._________...0000000000...............................
//........................00000000..000000...00000000000...000000..00000000........................
//.........................00..i00i.0000....0000000000000....0000.i00i..00.........................
//...........................00...0000......_____________......0000...00...........................
//.............................0000.........0000000000000.........0000.............................
//...........................................00000000000...........................................
//..............................................00000..............................................
