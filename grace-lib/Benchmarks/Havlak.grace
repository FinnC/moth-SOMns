// Copyright 2011 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//
// Adapted for Grace by Richard Roberts
//   2018, June
//

import "harness" as harness
import "Core" as core

def Array: Unknown = platform.kernel.Array

type BasicBlockType = interface {
  bbName
}

class newBasicBlockType(name': String) -> BasicBlockType {
  method bbName -> String { name' }
}

def BBNonHeader: BasicBlockType   = newBasicBlockType("BBNonHeader")
def BBDead: BasicBlockType        = newBasicBlockType("BBDead")
def BBReducible: BasicBlockType   = newBasicBlockType("BBReducible")
def BBSelf: BasicBlockType        = newBasicBlockType("BBSelf")
def BBIrreducible: BasicBlockType = newBasicBlockType("BBIrreducible")

type BasicBlock = interface {
  inEdges
  outEdges
  name
  numPred
  addOutEdge(to)
  addInEdge(from)
  customHash
}

type BasicBlockEdge = interface {
  from
  to
}

type ControlFlowGraph = interface {
  basicBlockMap
  startNode
  edgeList
  createNode(name)
  addEdge(edge)
  numNodes
  startBasicBlock
  basicBlocks
}

type SimpleLoop = interface {
  counter
  depthLevel
  parent_
  isRoot_
  nestingLevel_
  header
  isReducible
  basicBlocks
  children
  addNode(bb)
  addChildLoop(loop)
  parent
  parent(val)
  isRoot
  setIsRoot
  nestingLevel
  nestingLevel(level)
}

type LoopStructureGraph = interface {
  root
  loops
  loopCounter
  createNewLoop (bb) reducible (isReducible)
  calculateNestingLevel
  calculateNestingLevelRec (loop) depth (depth)
  numLoops
}


type UnionFindNode = interface {
  parent_
  bb_
  dfsNumber_
  loop
  initNode(bb)dfs(dfsNumber)
  findSet
  union(basicBlock)
  parent
  bb
  dfsNumber
}

type LoopTesterApp = interface {
  cfg
  lsg
  buildDiamond(start)
  buildConnect(start)end(end)
  buildStraight(start)n(n)
  buildBaseLoop(from)
  main(numDummyLoops)loop(findLoopIterations)p(parLoop)p(pparLoops)p(ppparLoops)
  constructCFG(parLoops)p(pparLoops)p(ppparLoops)
  addDummyLoops(numDummyLoops)
  findLoops(loopStructure)
  constructSimpleCFG
}

type HavlakLoopFinder = interface {
  cfg
  lsg
  unvisited
  maxNonBackPreds
  nonBackPreds
  backPreds
  number
  maxSize
  header
  htype
  last
  nodes
  isAncestor(w)v(v)
  doDFS(currentNode)current(current)
  initAllNodes
  identifyEdges(size)
  processEdges(nodeW)w(w)
  findLoops
  stepEProcessNonBackPreds(w)nodePool(nodePool)workList(workList)x(x)
  setLoopAttribute(w)nodePool(nodePool)loop(loop)
  stepD(w)nodePool(nodePool)
}

class newHavlak -> harness.Benchmark {
  inherit harness.newBenchmark

  method innerBenchmarkLoop (innerIterations: Number) -> Boolean {
    return verifyResult (newLoopTesterApp.main ( innerIterations )
                                          loop ( 50    )
                                          p    ( 10    )
                                          p    ( 10    )
                                          p    (  5    )) iterations (innerIterations)
  }

  method verifyResult (result: List) iterations (innerIterations: Number) -> Boolean {
    (innerIterations == 15000).ifTrue { return (result.at(1) == 46602). and { result.at(2) == 5213 } }
    (innerIterations ==  1500).ifTrue { return (result.at(1) ==  6102). and { result.at(2) == 5213 } }
    (innerIterations ==   150).ifTrue { return (result.at(1) ==  2052). and { result.at(2) == 5213 } }
    (innerIterations ==    15).ifTrue { return (result.at(1) ==  1647). and { result.at(2) == 5213 } }
    (innerIterations ==     1).ifTrue { return (result.at(1) ==  1605). and { result.at(2) == 5213 } }

    print("No verification result for {innerIterations} found")
    print("Result is {result.at(1)}, {result.at(2)}")
    return false
  }

}

class newBasicBlock (name': Number) -> BasicBlock {
  def inEdges: core.Vector  = core.newVector(2)
  def outEdges: core.Vector = core.newVector(2)
  def name: Number = name'

  method numPred -> Number { return inEdges.size }

  method addOutEdge (to: BasicBlock) -> Done {
    outEdges.append (to)
    done
  }

  method addInEdge (from: BasicBlock) -> Done {
    inEdges.append (from)
    done
  }

  method customHash -> Number { return name }
}

class newBasicBlockEdgeFor (cfg: ControlFlowGraph) from (fromName: Number) to (toName: Number) -> BasicBlockEdge {
  def from: BasicBlock = cfg.createNode(fromName)
  def to: BasicBlock   = cfg.createNode(toName)

  from.addOutEdge(to)
  to.addInEdge(from)
  cfg.addEdge(self)
}

class newControlFlowGraph -> ControlFlowGraph {
  def basicBlockMap: core.Vector = core.newVector
  var startNode: BasicBlock := done
  def edgeList: core.Vector = core.newVector

  method createNode(name: Number) -> BasicBlock {
    var node: BasicBlock

    basicBlockMap.at(name).notNil.ifTrue {
      node := basicBlockMap.at (name)
    } ifFalse {
      node := newBasicBlock (name)
      basicBlockMap. at (name) put (node)
    }

    (numNodes == 1).ifTrue { startNode := node }
    return node
  }

  method addEdge(edge: BasicBlockEdge) -> Done {
    edgeList.append(edge)
    done
  }

  method numNodes -> Number {
    return basicBlockMap.size
  }

  method startBasicBlock -> BasicBlock {
    return startNode
  }

  method basicBlocks -> core.Vector {
    return basicBlockMap
  }
}

class newLoopStructureGraph -> LoopStructureGraph {
  def root: SimpleLoop = newSimpleLoopWithBasicBlock (done) reducible (false)
  def loops: core.Vector = core.newVector
  var loopCounter: Number := 0

  root.nestingLevel(0)
  root.counter := loopCounter
  loopCounter := loopCounter + 1
  loops.append(root)

  method createNewLoop (bb: BasicBlock) reducible (isReducible: Boolean) -> SimpleLoop {
    var loop: SimpleLoop :=  newSimpleLoopWithBasicBlock (bb) reducible (isReducible)
    loop.counter := loopCounter
    loopCounter := loopCounter + 1
    loops.append(loop)
    return loop
  }

  method calculateNestingLevel -> Done {
    loops.forEach { liter: SimpleLoop ->
      liter.isRoot.ifFalse {
        liter.parent.isNil.ifTrue {
          liter.parent(root)
        }
      }
    }
    calculateNestingLevelRec (root) depth (0)
    done
  }

  method calculateNestingLevelRec (loop: SimpleLoop) depth (depth: Number) -> Done {
    loop.depthLevel := depth
    loop.children.forEach { liter: SimpleLoop ->
      calculateNestingLevelRec (liter) depth (depth + 1)
      loop.nestingLevel (loop.nestingLevel.max(1 + liter.nestingLevel))
    }
    done
  }

  method numLoops -> Number {
    return loops.size
  }
}


class newSimpleLoopWithBasicBlock (bb: BasicBlock) reducible (isReducible': Boolean) -> SimpleLoop {
  var counter: Number := 0
  var depthLevel: Number := 0

  var parent_: SimpleLoop := done
  var isRoot_: Boolean  := false
  var nestingLevel_: Number := 0

  def header: BasicBlock = bb
  def isReducible: Boolean = isReducible'
  def basicBlocks: core.Set = core.newIdentitySet
  def children: core.Set = core.newIdentitySet

  bb.notNil.ifTrue {
    basicBlocks.add (bb)
  }

  method addNode (bb: BasicBlock) -> Done {
    basicBlocks.add (bb)
    done
  }

  method addChildLoop (loop: SimpleLoop) -> Done {
    children.add (loop)
    done
  }

  method parent -> SimpleLoop { return parent_ }

  method parent (val: SimpleLoop) -> Done {
    parent_ := val
    parent_.addChildLoop (self)
  }

  method isRoot    -> Boolean { return isRoot_ }

  method setIsRoot -> Done {
    isRoot_ := true
    done
  }

  method nestingLevel -> Number { return nestingLevel_ }

  method nestingLevel (level: Number) -> Done {
    nestingLevel_ := level
    (level == 0).ifTrue { setIsRoot }
    done
  }
}

class newUnionFindNode -> UnionFindNode {
  var parent_: UnionFindNode := done
  var bb_: BasicBlock := done
  var dfsNumber_: Number := 0
  var loop: SimpleLoop := done

  method initNode (bb: BasicBlock) dfs (dfsNumber: Number) -> Done {
    parent_ := self
    bb_ := bb
    dfsNumber_ := dfsNumber
    loop := done
    done
  }

  method findSet -> UnionFindNode {
    var nodeList: core.Vector := core.newVector

    var node: UnionFindNode := self

    { node != node.parent }.whileTrue {
      (node.parent != node.parent.parent). ifTrue {
        nodeList.append (node)
      }
      node := node.parent
    }

    nodeList.forEach { iter: UnionFindNode -> iter.union(parent_) }
    return node
  }

  method union(node: UnionFindNode) -> Done {
    parent_ := node
    done
  }

  method parent -> UnionFindNode { return parent_ }

  method bb -> BasicBlock { return bb_ }

  method dfsNumber -> Number { return dfsNumber_ }
}

class newLoopTesterApp -> LoopTesterApp {
  def cfg: ControlFlowGraph = newControlFlowGraph
  def lsg: LoopStructureGraph = newLoopStructureGraph

  cfg.createNode(1)

  method buildDiamond (start: Number) -> Number {
    var bb0: Number := start
    newBasicBlockEdgeFor (cfg) from (bb0)               to (bb0 + 1)
    newBasicBlockEdgeFor (cfg) from (bb0)               to (bb0 + 2)
    newBasicBlockEdgeFor (cfg) from (bb0 + 1) to (bb0 + 3)
    newBasicBlockEdgeFor (cfg) from (bb0 + 2) to (bb0 + 3)
    return bb0 + 3
  }

  method buildConnect (start: Number) end (end: Number) -> Done {
    newBasicBlockEdgeFor (cfg) from (start) to (end)
    done
  }

  method buildStraight (start: Number) n (n: Number) -> Number {
    0.to (n - 1) do { i: Number ->
      buildConnect (start + i) end (start + i + 1)
    }
    return start + n
  }

  method buildBaseLoop (from: Number) -> Number {
    var header: Number := buildStraight (from) n (1)
    var diamond1: Number := buildDiamond (header)
    var d11: Number := buildStraight (diamond1) n (1)
    var diamond2: Number := buildDiamond (d11)
    var footer: Number := buildStraight (diamond2) n (1)

    buildConnect (diamond2) end (d11)
    buildConnect (diamond1) end (header)
    buildConnect (footer)   end (from)
    footer := buildStraight (footer) n (1)
    return footer
  }

  method main (numDummyLoops: Number) loop (findLoopIterations: Number) p (parLoop: Number) p (pparLoops: Number) p (ppparLoops: Number) -> List {
    constructSimpleCFG
    addDummyLoops (numDummyLoops)
    constructCFG (parLoop) p (pparLoops) p (ppparLoops)
    findLoops(lsg)
    findLoopIterations.timesRepeat { findLoops (newLoopStructureGraph) }
    lsg.calculateNestingLevel
    return Array.with (lsg.numLoops) with (cfg.numNodes)
  }

  method constructCFG (parLoops: Number) p (pparLoops: Number) p (ppparLoops: Number) -> Done {
    var n: Number := 3

    parLoops.timesRepeat {
      cfg.createNode (n + 1)
      buildConnect (2) end (n + 1)
      n := n + 1

      pparLoops.timesRepeat {
        var top: Number := n
        n := buildStraight (n) n (1)
        ppparLoops.timesRepeat { n := buildBaseLoop(n) }
        var bottom: Number := buildStraight (n) n (1)
        buildConnect (n) end (top)
        n := bottom
      }

      buildConnect (n) end (1)
    }
    done
  }

  method addDummyLoops (numDummyLoops: Number) -> Done {
    numDummyLoops.timesRepeat {
      findLoops (lsg)
    }
    done
  }

  method findLoops (loopStructure: LoopStructureGraph) -> Done {
    var finder: HavlakLoopFinder := newHavlakLoopFinder (cfg) lsg (loopStructure)
    finder.findLoops
    done
  }

  method constructSimpleCFG -> Done {
    cfg.createNode (1)
    buildBaseLoop (1)
    cfg.createNode (2)
    newBasicBlockEdgeFor (cfg) from (1) to (3)
    done
  }
}

class newHavlakLoopFinder (cfg': ControlFlowGraph) lsg (lsg': LoopStructureGraph) -> HavlakLoopFinder {
  def cfg: ControlFlowGraph = cfg'
  def lsg: LoopStructureGraph = lsg'
  def unvisited: Number = 2147483647
  def maxNonBackPreds: Number = 32 * 1024
  def nonBackPreds: core.Vector = core.newVector
  def backPreds: core.Vector = core.newVector
  def number: core.Dictionary = core.newIdentityDictionary

  var maxSize: Number := 0
  var header: List := done
  var htype: List := done
  var last: List := done
  var nodes: List := done

  // BasicBlockClass enum #BBTop #BBNonHeader #BBReducible #BBSelf
  //                      #BBIrreducible #BBDead #BBLast

  method isAncestor (w: Number) v (v: Number) -> Boolean {
    return (w <= v) && (v <= last.at(w))
  }

  method doDFS (currentNode: BasicBlock) current (current: Number) -> Number {

    nodes.at(current).initNode (currentNode) dfs (current)
    number.at (currentNode) put (current)

    var lastId: Number := current
    var outerBlocks: core.Vector := currentNode.outEdges

    1.to(outerBlocks.size) do { i: Number ->
      var target: BasicBlock := outerBlocks.at(i)
      (number.at(target) == unvisited). ifTrue {
        lastId := doDFS (target) current (lastId + 1)
      }
    }

    last.at (current) put (lastId)
    return lastId
  }

  method initAllNodes -> Done {
    cfg.basicBlocks.forEach { bb: BasicBlock ->
      number.at (bb) put (unvisited)
    }

    doDFS (cfg.startBasicBlock) current (1)
    done
  }

  method identifyEdges (size: Number) -> Done {
    1.to(size) do { w: Number ->
      header.at (w) put (1)
      htype.at (w) put (BBNonHeader)

      var nodeW: BasicBlock := nodes.at(w).bb
      nodeW.isNil.ifTrue {
        htype.at(w) put (BBDead)
      } ifFalse {
        processEdges (nodeW) w (w)
      }
    }
  }

  method processEdges (nodeW: BasicBlock) w (w: Number) -> Done {
    (nodeW.numPred > 0).ifTrue {
      nodeW.inEdges.forEach { nodeV: BasicBlock ->
        var v: Number := number.at (nodeV)
        (v != unvisited). ifTrue {
          isAncestor (w) v (v).ifTrue {
            backPreds. at (w). append (v)
          } ifFalse {
            nonBackPreds. at (w). add (v)
          }
        }
      }
    }
    done
  }

  method findLoops -> Done {
    cfg.startBasicBlock.isNil.ifTrue { return self }

    var size: Number := cfg.numNodes

    nonBackPreds.removeAll
    backPreds.removeAll
    number.removeAll

    (size > maxSize).ifTrue {
      header := Array.new (size)
      htype := Array.new (size)
      last := Array.new (size)
      nodes := Array.new (size)
      maxSize := size
    }

    1.to (size) do { i: Number ->
      nonBackPreds.append (core.newSet)
      backPreds.append (core.newVector)
      nodes.at (i) put (newUnionFindNode)
    }

    initAllNodes
    identifyEdges(size)
    header.at (1) put (1)

    size.downTo (1) do { w: Number ->
      var nodePool: core.Vector := core.newVector
      var nodeW: BasicBlock := nodes.at(w).bb

      nodeW.notNil.ifTrue {
        stepD (w) nodePool (nodePool)

        var workList: core.Vector := core.newVector
        nodePool.forEach { niter: UnionFindNode -> workList.append(niter) }

        (nodePool.size != 0).ifTrue {
          htype.at (w) put (BBReducible)
        }

        { workList.isEmpty }. whileFalse {
          var x: UnionFindNode := workList.removeFirst

          var nonBackSize: Number := nonBackPreds.at(x.dfsNumber).size
          (nonBackSize > maxNonBackPreds). ifTrue { return self }
          stepEProcessNonBackPreds (w) nodePool (nodePool) workList (workList) x (x)
        }

        ((nodePool.size > 0).or { htype.at(w) == BBSelf }). ifTrue {
          var loop: SimpleLoop := lsg.createNewLoop (nodeW) reducible (htype.at(w) != BBIrreducible)
          setLoopAttribute (w) nodePool (nodePool) loop (loop)
        }
      }
    }
    done
  }

  method stepEProcessNonBackPreds (w: Number) nodePool (nodePool: core.Vector) workList (workList: core.Vector) x (x: UnionFindNode) -> Done {
    nonBackPreds.at(x.dfsNumber).forEach { iter: Number ->
      var y: UnionFindNode := nodes.at(iter)
      var ydash: UnionFindNode := y.findSet

      (!isAncestor(w)v(ydash.dfsNumber)). ifTrue {
        htype.at (w) put (BBIrreducible)
        nonBackPreds.at(w).add(ydash.dfsNumber)

      } ifFalse {
        (ydash.dfsNumber != w). ifTrue {
          (nodePool.hasSome { e: UnionFindNode -> e == ydash }). ifFalse {
            workList.append (ydash)
            nodePool.append (ydash)
          }
        }
      }
    }
    done
  }

  method setLoopAttribute (w: Number) nodePool (nodePool: core.Vector) loop (loop: SimpleLoop) -> Done {
    nodes . at (w) . loop := loop

    nodePool.forEach { node: UnionFindNode ->
      header.at(node.dfsNumber) put (w)
      node.union (nodes.at(w))

      node.loop.notNil.ifTrue {
        node.loop.parent(loop)
      } ifFalse {
        loop.addNode(node.bb)
      }
    }
    done
  }

  method stepD (w: Number) nodePool (nodePool: core.Vector) -> Done {
    backPreds.at (w). forEach { v: Number ->
      (v != w). ifTrue {
        nodePool.append (nodes.at(v).findSet)
      } ifFalse {
        htype. at (w) put (BBSelf)
      }
    }
  }
}

method newInstance -> harness.Benchmark { newHavlak }
