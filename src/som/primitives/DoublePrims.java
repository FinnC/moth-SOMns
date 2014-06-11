package som.primitives;

import som.interpreter.nodes.nary.UnaryExpressionNode.UnarySideEffectFreeExpressionNode;

import com.oracle.truffle.api.dsl.Specialization;


public abstract class DoublePrims  {

  public abstract static class RoundPrim extends UnarySideEffectFreeExpressionNode {
    public RoundPrim() { super(false); } /* TODO: enforced!!! */

    @Specialization
    public final long doDouble(final double receiver) {
      return Math.round(receiver);
    }
  }
}
