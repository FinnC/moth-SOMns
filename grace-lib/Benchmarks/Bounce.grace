// Copyright (c) 2001-2018 see AUTHORS file
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the 'Software'), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//
// Adapted for Grace by Richard Roberts
//   2018, June
//

import "harness" as harness

type Ball = interface {
  bounce
}

class newBounce -> harness.Benchmark {
  inherit harness.newBenchmark

  method benchmark -> Number {
    def random: harness.Random = harness.newRandom

    def ballCount: Number = 100
    var bounces: Number := 0
    def balls: List = platform.kernel.Array.new (ballCount) withAll { newBall(random) }

    1.to(50) do { i: Number ->
      balls.do { ball: Ball ->
        ball.bounce.ifTrue {
          bounces := bounces + 1
        }
      }
    }

    bounces
  }

  method verifyResult(result: Number) -> Boolean {
    result == 1331
  }
}

class newBall(random: harness.Random) -> Ball {
  var x: Number := random.next % 500
  var y: Number := random.next % 500
  var xVel: Number := (random.next % 300) - 150
  var yVel: Number := (random.next % 300) - 150

  method bounce -> Boolean {
    def xLimit: Number = 500
    def yLimit: Number = 500
    var bounced: Boolean := false

    x := x + xVel
    y := y + yVel

    (x > xLimit).ifTrue {
      x := xLimit
      xVel := 0 - xVel.abs
      bounced := true
    }

    (x < 0).ifTrue {
      x := 0
      xVel := xVel.abs
      bounced := true
    }

    (y > yLimit).ifTrue {
      y := yLimit
      yVel := 0 - yVel.abs
      bounced := true
    }

    (y < 0).ifTrue {
      y := 0
      yVel := yVel.abs
      bounced := true
    }

    bounced
  }
}

method newInstance -> harness.Benchmark { newBounce }
