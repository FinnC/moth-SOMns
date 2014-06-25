package som.interpreter.nodes.specialized;

import som.interpreter.nodes.nary.BinaryExpressionNode;
import som.vm.Universe;
import som.vmobjects.SBlock;
import som.vmobjects.SObject;

import com.oracle.truffle.api.CompilerAsserts;
import com.oracle.truffle.api.dsl.Specialization;
import com.oracle.truffle.api.frame.VirtualFrame;


public abstract class WhilePrimitiveNode extends BinaryExpressionNode {
  final boolean predicateBool;
  final Universe universe;

  protected WhilePrimitiveNode(final boolean predicateBool) {
    super(null, false); // TODO: enforced!!!
    universe = Universe.current();
    this.predicateBool = predicateBool;
  }

  protected WhilePrimitiveNode(final WhilePrimitiveNode node) {
    this(node.predicateBool);
  }

  private boolean obj2bool(final Object o) {
    if (o instanceof Boolean) {
      return (boolean) o;
    } else if (o == universe.trueObject) {
      return true;
    } else {
      assert o == universe.falseObject;
      return false;
    }
  }

  @Specialization
  protected SObject doWhileConditionally(final VirtualFrame frame,
      final SBlock loopCondition, final SBlock loopBody) {
    CompilerAsserts.neverPartOfCompilation(); // no caching, direct invokes, no loop count reporting...

    Object conditionResult = loopCondition.getMethod().invoke(loopCondition.getDomain(), loopCondition.isEnforced(), loopCondition);
    boolean loopConditionResult = obj2bool(conditionResult);


    // TODO: this is a simplification, we don't cover the case receiver isn't a boolean
    while (loopConditionResult == predicateBool) {
      loopBody.getMethod().invoke(loopBody.getDomain(), loopBody.isEnforced(), loopBody);
      conditionResult = loopCondition.getMethod().invoke(loopCondition.getDomain(), loopCondition.isEnforced(), loopCondition);
      loopConditionResult = obj2bool(conditionResult);
    }
    return universe.nilObject;
  }

  @Override
  public void executeVoid(final VirtualFrame frame) {
    executeGeneric(frame);
  }

  public abstract static class WhileTruePrimitiveNode extends WhilePrimitiveNode {
    public WhileTruePrimitiveNode() { super(true); }
  }

  public abstract static class WhileFalsePrimitiveNode extends WhilePrimitiveNode {
    public WhileFalsePrimitiveNode() { super(false); }
  }
}
