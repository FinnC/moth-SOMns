 import "/../Modules/collections" as col

 type Matrix[[T]] = Collection[[T]] & interface {
    size -> Number
    numRows -> Number
    numColumns -> Number
    +(other:Matrix[[T]]) -> Matrix[[T]]
    -(other:Matrix[[T]]) -> Matrix[[T]]
    *(other) -> Matrix[[T]]
    /(other) -> Matrix[[T]]
    transpose -> Matrix[[T]]
    times(other:Matrix[[T]]) -> Matrix[[T]]
    reshapeWithNumRows(rs:Number) numColumns(cs:Number) -> Matrix[[T]]
    reshapeWithNumRows(rs:Number) numColumns(cs:Number) additionalValues(vs:Collection[[T]]) -> Matrix[[T]]
    addRow(row:Collection[[T]]) at(index:Number) -> Matrix[[T]]
    addColumn(column:Collection[[T]]) at(index:Number) -> Matrix[[T]]
    deleteRow(r:Number) -> Matrix[[T]]
    deleteColumn(c:Number) -> Matrix[[T]]
    replaceRowAt(r:Number) with(row:Collection[[T]]) -> Matrix[[T]]
    replaceColumnAt(c:Number) with(col:Collection[[T]]) -> Matrix[[T]]
    ==(other:Object) -> Boolean
    !=(other:Object) -> Boolean
    ++(other:Matrix[[T]]) -> Matrix[[T]]
    copy -> Matrix[[T]]
 }

 type MatrixFactory[[T]] = interface {
    rows(rows: Collection[[Collection[[T]]]]) -> Matrix[[T]]
    columns(columns: Collection[[Collection[[T]]]]) -> Matrix[[T]]
    atRow(r:Number) column(c:Number) put(v:T) -> Matrix
    atRow(r:Number) column(c:Number) -> T
    value(v:T) -> Matrix[[T]]
    values(vs: Collection[[T]]) -> Matrix[[T]]
 }

 type ComparableToMatrix[[T]] = interface {
    numRows -> Number
    numColumns -> Number
    atRow(r:Number) column(c:Number)
 }

 method dot(v1: Collection, v2: Collection) {
    var dotProduct := 0
    def iterator1 = v1.iterator
    def iterator2 = v2.iterator

    while {iterator1.hasNext && iterator2.hasNext} do {
        dotProduct := dotProduct + (iterator1.next * iterator2.next)
    }
    dotProduct
 }

 method listOfSize(size) withValue(v) { //TODO: add is confidential when it works properly
    def l = list.empty
    repeat(size) times { l.add(v) }
    l
 }

 class lazyZipperSequence[[T]] (source1: Collection[[Collection[[T]]]], source2: Collection[[T]]) {
    //TODO: add use enumerable[[Collection[[T]]]] when use works
    method iterator {
        object {
            def iterator1 = source1.iterator
            def iterator2 = source2.iterator

            method asString { "a zipper iterator over {iterator1} and {iterator2}" }
            method hasNext { iterator1.hasNext }
            method next { col.lazyConcatenation(iterator1.next, iterator2.next) }
        }
    }
    method size { source1.size }
    method isEmpty { (source1.size == 0) && (source2.size == 0) }
 }

 method mapColumnsToRows(columns: Collection[[Collection]]) {
    if(columns.size == 0) then { return [] }
    columns.fold{ rs, c ->
        lazyZipperSequence(rs,c)
    } startingWith( listOfSize(columns.first.size) withValue([]) )
 }

 class matrix[[T]](rs, cs) -> MatrixFactory[[T]] {
    method asString {"the matrix factory"}

    method withAll(a:Collection[[T]]) -> Matrix[[T]] { values(a) }

    method << (source) { values(source) }

    method rows(r: Collection[[Collection[[T]]]]) -> Matrix[[T]] {
        values ( r.fold{ r1, r2 ->
            var v := col.lazyConcatenation(r1,r2)
            v
        } startingWith(col.abbreviations.list) )
    }

    method columns(c: Collection[[Collection[[T]]]]) -> Matrix[[T]] {
        rows(mapColumnsToRows(c))
    }

    class values(vs: Collection[[T]]) -> Matrix[[T]] {
        if((rs * cs) != vs.size) then { error("dimensions {rs}x{cs} is not compatible with values of size {vs.size}") }
        var impl := vs >> col.abbreviations.list

        var numRows is public := rs
        var numColumns is public := cs

        method isRowValid(r) { (r > 0) && (r <= numRows)} //TODO: add is confidential when it works properly
        method isColumnValid(c) { (c > 0) && (c <= numColumns)} //TODO: add is confidential when it works properly

        method size { impl.size }

        method indexFromRow(r) column(c) { //TODO: add is confidential when it works properly
            if(!(isRowValid(r) && isColumnValid(c))) then { error("position {r},{c} is out of bounds") }
            (r - 1) * numColumns + c
        }

        method indexFromRow(r) column(c) ifOutOfBounds(action) { //TODO: add is confidential when it works properly
            if(!(isRowValid(r) && isColumnValid(c))) then { action.apply }
            (r - 1) * numColumns + c
        }

        method atRow(r) column(c) put(v:T) {
            impl.at(indexFromRow(r)column(c)) put(v)
            self
        }

        method atRow(r) column(c) {
            impl.at(indexFromRow(r) column(c))
        }

        method columns -> Enumerable[[Enumerable[[T]]]] {
            def sourceMatrix = self
            object {
                inherit col.collection[[Collection[[T]]]]
                method iterator {
                    object {
                        var currentColumn := 1
                        method hasNext { currentColumn <= numColumns }
                        method next {
                            def c = currentColumn
                            currentColumn := currentColumn + 1
                            sourceMatrix.column(c)
                        }
                        method asString {
                            "an iterator over columns of {sourceMatrix}"
                        }
                    }
                }
                def size is public = numColumns
            }
        }

        method rows -> Enumerable[[Enumerable[[T]]]] {
            def sourceMatrix = self
            object {
                //inherit col.collection[[Collection[[T]]]] //inheritance does not work here, when fixed remove do and do separated
                method iterator {
                    object {
                        var currentRow := 1
                        method hasNext { currentRow <= numRows }
                        method next {
                            def r = currentRow
                            currentRow := currentRow + 1
                            sourceMatrix.row(r)
                        }
                        method asString {
                            "an iterator over rows of {sourceMatrix}"
                        }
                    }
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

                def size is public = numRows
            }
        }

        method row(r) {
            def sourceMatrix = self
            object {
                inherit col.collection[[T]]   //inheritance error here, but need do separatedBy for asString so be careful
                method iterator {
                    object {
                        var currentColumn := 1
                        method hasNext { currentColumn <= numColumns }
                        method next {
                            def c = currentColumn
                            currentColumn := currentColumn + 1
                            sourceMatrix.atRow(r) column(c)
                        }
                        method asString {
                            "an iterator over row {r} of {sourceMatrix}"
                        }
                    }
                }
                def size is public = numColumns

                method asString {
                    var string := "["
                    do { each ->
                        string := string ++ each.asString
                    } separatedBy { string := string ++ ", " }
                    string ++ "]"
                }
            }
        }

        method column(c) {
            def sourceMatrix = self
            object {
                //inherit col.collection[[T]]   //inheritance error here
                method iterator {
                    object {
                        var currentRow := 1
                        method hasNext { currentRow <= numRows }
                        method next {
                            def r = currentRow
                            currentRow := currentRow + 1
                            sourceMatrix.atRow(r) column(c)
                        }
                        method asString {
                            "an iterator over column {c} of {sourceMatrix}"
                        }
                    }
                }
                def size is public = numColumns
            }
        }

        //operations
        method applyScalarOperation(op) with (num) {   //TODO: add is confidential when it works properly
            matrix(self.numRows, self.numColumns).values(impl.map{each -> op.apply(each, num)})
        }

        method applyMatrixOperation(op) with (other) {  //TODO: add is confidential when it works properly
            if((other.numRows != self.numRows) || (other.numColumns != self.numColumns)) then {
                error("Dimensions of {other} are not compatible with dimensions of {self}")
            }
            def newMatrix = self.copy
            (col.range.from(1)to(numColumns)).do { c ->
                (col.range.from(1)to(numRows)).do { r ->
                    newMatrix.atRow(r) column(c) put (op.apply(newMatrix.atRow(r)column(c), other.atRow(r)column(c)))
                }
            }
            newMatrix
        }

        method +(other: Matrix[[T]]) {
            applyMatrixOperation{a, b -> a + b} with (other)
        }

        method -(other: Matrix[[T]]) {
            applyMatrixOperation{a, b -> a - b} with (other)
        }

        method *(other) {   //only works for scalar multiplication rn
            applyScalarOperation{a, b -> a * b} with (other)
            //type matching doesn't work
            //if(ComparableToMatrix.matches(other)) then {
            //    applyMatrixOperation{a, b -> a * b} with (other)
            //    return
            //}
            //if { ImplementsTimesOperator.matches(other) } then {
            //    applyScalarOperation{a, b -> a * b} with (other)
            //    return
            //}
            //error("Type of {other} does not support operator *")
        }

        method /(other) {
            applyScalarOperation{a, b -> a / b} with (other)
        }

        method transpose {  //does not work since rows does not work
            matrix(self.numColumns, self.numRows).rows(self.columns)
        }

        method times(other: Matrix[[T]]) {

            if((other.numRows != self.numColumns)) then {
                error("Dimensions of {other} are not compatible with dimensions of {self}")
            }

            def newValues = col.abbreviations.list
            self.rows.do { row ->
                other.columns.do { col ->
                    newValues.add(dot(row, col))
                }
            }
            matrix(self.numRows, other.numColumns).values(newValues)
        }

        method reshapeWithNumRows(rs) numColumns(cs) {
            if((rs * cs) != impl.size) then { error("dimensions {rs}x{cs} not compatible with value of size {impl.size}") }
            numRows := rs
            numColumns := cs
            self
        }

        method reshapeWithNumRows(rs) numColumns(cs) additionalValues(vs) {
            if((rs * cs) != (impl.size + vs.size)) then { error("dimensions {rs}x{cs} not compatible with values of size {impl.size + vs.size}") }
            impl.addAll(vs)
            numRows := rs
            numColumns := cs
            self
        }

        method addRow(row) at(r) {
            if(row.size != numColumns) then { error("row size must be equal to {numColumns}") }
            if((r <= 0) || (r > numRows)) then { error("invalid row number {r}") }

            var index := indexFromRow(r) column(1) ifOutOfBounds {size}
            row.do { each ->
                impl.insert(each) at(index)
                index := index + 1
            }
            numRows := numRows + 1
            self
        }

        method addColumn(col) at(c) {
            if(col.size != numRows) then { error("row size must be equal to {numColumns}") }
            if((c <= 0) || (c > (numColumns + 1))) then { error("invalid column number {c}") }

            var index := indexFromRow(1) column(c) ifOutOfBounds {numColumns + 1}
            col.do {each ->
                impl.insert(each) at (index)
                index := index + numColumns + 1
            }
            numColumns := numColumns + 1
            self
        }

        method deleteRow(r) {
            if((r <= 0) || (r > numRows)) then { error("row {r} does not exist") }

            def index = indexFromRow(r) column(1)
            repeat (numColumns) times {
                impl.removeAt(index)
            }

            numRows := numRows - 1
            self
        }

        method deleteColumn(c) {
            if((c <= 0) || (c > numColumns)) then { error("column {c} does not exist") }

            var index := indexFromRow(1) column(c)
            repeat (numRows) times {
                impl.removeAt(index)
                index := index + numColumns - 1
            }

            numColumns :=  numColumns - 1
            self
        }

        method replaceRowAt(r) with(row) {
            if(row.size != numColumns) then { error("row size must be equal to {numColumns}") }
            if((r <= 0) || (r > numRows)) then { error("invalid row number {r}") }

            var c := 1
            row.do { each ->
                self.atRow(r) column(c) put (each)
                c := c + 1
            }
            self
        }

        method replaceColumnAt(c) with(col) {
            if(col.size != numRows) then { error("column size must be equal to {numRows}") }
            if((c <= 0) || (c > numColumns)) then { error("invalid column number {c}") }

            var r := 1
            col.do { each ->
                self.atRow(r) column(c) put (each)
                r := r + 1
            }
            self
        }

        method ==(other) {
            //add type matching when it works

            col.range.from(1)to(numColumns).do { c ->
                col.range.from(1)to(numRows).do { r ->
                    def currentValue = self.atRow(r) column(c) ifAbsent { return false }
                    def otherValue = other.atRow(r) column(c) ifAbsent { return false }
                    if(currentValue != otherValue) then { return false }
                }
            }
            return true
        }

        method !=(other) {
            !(self == other)
        }

        method ++(other) {
            if((other.size % self.numColumns) != 0) then { error("size of {other} is incompatible with dimensions {numRows}x{numColumns}") }
            matrix((impl.size + other.size) / self.numColumns, self.numColumns).values(col.lazyConcatenation(impl, other.value))
        }

        method copy {   //only works for scalar division rn
            matrix(numRows,numColumns).values(impl)
        }

        method asString {
            var string := "matrix ["
            self.rows.do { each ->
                string := string ++ each.asString
            } separatedBy { string := string ++ ", " }
            string ++ "]"
        }
    }
 }