type Point = interface {
    x -> Number
    y -> Number

    == (other:Object) -> Boolean
    + (other:Point) -> Point
    - (other:Point) -> Point
    negated -> Point
    * (other:Number) -> Point
    / (other:Number) -> Point
    length -> Number
    distanceTo (other:Point) -> Number
    dot (other:Point) -> Number
    norm -> Point
}

method point2Dx(xv)y(yv) {
    object {
        var x := xv
        var y := yv

        method +(other:Point) {
            point2Dx(self.x + other.x)y(self.y + other.y)
        }

        method -(other:Point) {
            point2Dx(self.x - other.x)y(self.y - other.y)
        }

        method negated {    //is same as prefix-
            point2Dx(-x)y(-y)
        }

        method *(other:Number) {
            point2Dx(x * other)y(y * other)
        }

        method /(other:Number) {
            point2Dx(x / other)y(y / other)
        }

        method length {
            ((self.x.pow(2)) + (self.y.pow(2))).sqrt
        }

        method distanceTo(other:Point) {
           (((self.x - other.x).pow(2)) + ((self.y - other.y).pow(2))).sqrt
        }

        method dot(other:Point) {
            (self.x * other.x) + (self.y * other.y)
        }

        method norm {
            self / self.length
        }

        method asString {
            var str := "("
            str := str + x + "@" + y + ")"
            str
        }
    }
}