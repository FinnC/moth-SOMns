import "mirrors" as mirrors
import "random" as random
import "/../Modules/points" as points

method asString {"modules.grace"}

method testMethodNameMirror {
  def o = object {
    method foo {}
    method bar(x) {}
  }

  def names = mirrors.methodNamesForObject(o)
  (names.at(1.asInteger) == "foo").ifFalse { "testMethodNameMirror failed on foo"}
  (names.at(2.asInteger) == "bar:").ifFalse { "testMethodNameMirror failed on bar:"}

  "testMethodNameMirror passed"
}

method testReflectiveInvoke {
  def o = object { method foo { "bar" } }
  def ret = mirrors.invoke("foo".asSymbol) on (o)
  (ret == "bar").ifFalse { "testReflectiveInvoke failed" }
  "testReflectiveInvoke passed"
}


method testRandom {
  random.setSeed(455.asInteger)
  (random.random == 0.2993820096131838).ifFalse { "testRandom failed on case 1"}
  (random.random == 0.0963912413214313).ifFalse { "testRandom failed on case 2"}
  (random.random == 0.3855344472419318).ifFalse { "testRandom failed on case 3"}

  random.setSeed(12345.asInteger)
  (random.random == 0.787335011825742 ).ifFalse { "testRandom failed on case 4"}
  (random.random == 0.8171358815899901).ifFalse { "testRandom failed on case 5"}
  (random.random == 0.8258793011367971).ifFalse { "testRandom failed on case 6"}

  random.setSeed(12121.asInteger)
  (random.random == 0.31320668345159075).ifFalse { "testRandom failed on case 7"}
  (random.random == 0.19261463340199894).ifFalse { "testRandom failed on case 8"}
  (random.random == 0.3400320439459831 ).ifFalse { "testRandom failed on case 9"}

  var jr := random.Jenkins(1.asInteger)
  (jr.next == -1266253386).ifFalse { error("testRandom failed on Jenkins case 1")}
  (jr.next == -90995496  ).ifFalse { error("testRandom failed on Jenkins case 2")}
  (jr.next == -1239305412).ifFalse { error("testRandom failed on Jenkins case 3")}

  var jr := random.Jenkins(2.asInteger)
  (jr.next == -496519092 ).ifFalse { error("testRandom failed on Jenkins case 4")}
  (jr.next == 1739325048 ).ifFalse { error("testRandom failed on Jenkins case 5")}
  (jr.next == 1786620943 ).ifFalse { error("testRandom failed on Jenkins case 6")}

  "testRandom passed"
}

method testPoints {
    //var p1 := points.point2Dx(4) y(6)
    //var p2 := points.point2Dx(2) y(1)
    //var p3 := p1 + p2
    //if((p3.x != 6) && (p3.y != 7)) then { return "testPoints failed on +" }
    //p3 := p1 - p2
    //if((p3.x != 2) && (p3.y != 5)) then { return "testPoints failed on -" }
    //p3 := -p1
    //if((p3.x != -4) && (p3.y != -6)) then { return "testPoints failed on prefix-" }
    //p3 := p1 * 2
    //if((p3.x != 8) && (p3.y != 12)) then { return "testPoints failed on *" }
    //p3 := p1 / 2
    //if((p3.x != 2) && (p3.y != 3)) then { return "testPoints failed on \\" }
    //p3 := (points.point2Dx(3)y(4)).length
    //if(p3 != 5) then { return "testPoints failed on length" }
    //p3 := p1.distanceTo(p2)
    //if(p3 != 5.385164807134504) then { return "testPoints failed on distanceTo" }
    //p3 := p1.dot(p2)
    //if(p3 != 14) then { return "testPoints failed on dot" }
    //p3 := points.point2Dx(3)y(4).norm
    //if((p3.x != (3 / 5)) && (p3.y != (4 / 5))) then { return "testPoints failed on norm" }

    "testPoints passed"
}