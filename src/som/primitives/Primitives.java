/**
 * Copyright (c) 2013 Stefan Marr,   stefan.marr@vub.ac.be
 * Copyright (c) 2009 Michael Haupt, michael.haupt@hpi.uni-potsdam.de
 * Software Architecture Group, Hasso Plattner Institute, Potsdam, Germany
 * http://www.hpi.uni-potsdam.de/swa/
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

package som.primitives;

import som.compiler.MethodGenerationContext;
import som.interpreter.Invokable;
import som.interpreter.Primitive;
import som.interpreter.nodes.ArgumentReadNode;
import som.interpreter.nodes.ExpressionNode;
import som.interpreter.nodes.enforced.EnforcedPrim;
import som.vm.Universe;
import som.vmobjects.SClass;
import som.vmobjects.SInvokable;
import som.vmobjects.SInvokable.SMethod;
import som.vmobjects.SInvokable.SPrimitive;
import som.vmobjects.SSymbol;

import com.oracle.truffle.api.CompilerDirectives.SlowPath;
import com.oracle.truffle.api.dsl.NodeFactory;

public abstract class Primitives {

  protected final Universe universe;

  public Primitives() {
    this.universe = Universe.current();
  }

  public final void installPrimitivesIn(final SClass value) {
    // Save a reference to the holder class
    holder = value;

    // Install the primitives from this primitives class
    installPrimitives();
  }

  public abstract void installPrimitives();

  @SlowPath
  public static SInvokable constructPrimitive(final SSymbol signature,
      final NodeFactory<? extends ExpressionNode> nodeFactory,
      final Universe universe, final SClass holder, final boolean isUnenforced) {
    int numArgs = signature.getNumberOfSignatureArguments();

    MethodGenerationContext mgen = new MethodGenerationContext(null);
    mgen.setPrimitive(true);

    ExpressionNode[] argsEnforced   = new ExpressionNode[numArgs];
    ExpressionNode[] argsUnenforced = new ExpressionNode[numArgs];
    for (int i = 0; i < numArgs; i++) {
      argsEnforced[i]   = new ArgumentReadNode(i, true);
      argsUnenforced[i] = new ArgumentReadNode(i, false);
    }

    EnforcedPrim   primNodeEnforced = EnforcedPrim.create(argsEnforced);
    ExpressionNode primNodeUnenforced;

    switch (numArgs) {
      case 1:
        primNodeUnenforced = nodeFactory.createNode(false, argsUnenforced[0]);
        break;
      case 2:
        primNodeUnenforced = nodeFactory.createNode(false, argsUnenforced[0], argsUnenforced[1]);
        break;
      case 3:
        primNodeUnenforced = nodeFactory.createNode(false, argsUnenforced[0], argsUnenforced[1], argsUnenforced[2]);
        break;
      case 4:
        primNodeUnenforced = nodeFactory.createNode(false, argsUnenforced[0], argsUnenforced[1], argsUnenforced[2], argsUnenforced[3]);
        break;
      default:
        throw new RuntimeException("Not supported by SOM.");
    }

    boolean shouldInline = MethodGenerationContext.shouldAlwaysBeInlined(signature);
    Primitive enforcedMethod;
    Primitive unenforcedMethod;
    if (isUnenforced) {
      enforcedMethod   = null;
      unenforcedMethod = new Primitive(primNodeUnenforced,
          mgen.getFrameDescriptor(), false, shouldInline);
    } else {
      enforcedMethod   = new Primitive(primNodeEnforced,
          mgen.getFrameDescriptor(), true, shouldInline);
      unenforcedMethod = new Primitive(primNodeUnenforced,
          mgen.getFrameDescriptor(), false, shouldInline);
    }
    SPrimitive prim = (SPrimitive) universe.newMethod(signature, enforcedMethod,
        unenforcedMethod, true, new SMethod[0], isUnenforced);

    if (!isUnenforced) { enforcedMethod.setPrimitive(prim);
    } else {             assert enforcedMethod == null; }
    return prim;
  }

  @SlowPath
  public static Primitive constructEmptyPrimitive(final SSymbol signature,
      final Universe universe, final boolean unenforced) {
    MethodGenerationContext mgen = new MethodGenerationContext(null);

    ExpressionNode primNode = EmptyPrim.create(false, new ArgumentReadNode(0, false));  /* TODO: enforced!!! */ /* TODO: enforced!!! */
    Primitive primMethodNode = new Primitive(primNode, mgen.getFrameDescriptor(), false, MethodGenerationContext.shouldAlwaysBeInlined(signature));
    return primMethodNode;
  }

  protected final void installInstancePrimitive(final String selector,
      final NodeFactory<? extends ExpressionNode> nodeFactory) {
    SSymbol signature = universe.symbolFor(selector);
    SInvokable oldPrim = holder.lookupInvokable(signature);

    SInvokable prim = constructPrimitive(signature, nodeFactory, universe, holder, oldPrim.isUnenforced());

    // Install the given primitive as an instance primitive in the holder class
    holder.addInstancePrimitive(prim);
  }

  protected final void installClassPrimitive(final String selector,
      final NodeFactory<? extends ExpressionNode> nodeFactory) {
    SSymbol signature = universe.symbolFor(selector);
    SInvokable oldPrim = holder.getSOMClass().lookupInvokable(signature);

    SInvokable prim = constructPrimitive(signature, nodeFactory, universe, holder, oldPrim.isUnenforced());

    // Install the given primitive as an instance primitive in the class of
    // the holder class
    holder.getSOMClass().addInstancePrimitive(prim);
  }

  protected SClass holder;

  public static Invokable getEmptyPrimitive(final String selector,
      final Universe universe, final boolean unenforced) {
    SSymbol signature = universe.symbolFor(selector);
    return constructEmptyPrimitive(signature, universe, unenforced);
  }
}
