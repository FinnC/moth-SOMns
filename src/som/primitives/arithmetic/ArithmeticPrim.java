package som.primitives.arithmetic;

import java.math.BigInteger;

import som.interpreter.nodes.nary.BinaryExpressionNode.BinarySideEffectFreeExpressionNode;


public abstract class ArithmeticPrim extends BinarySideEffectFreeExpressionNode {
  public ArithmeticPrim(final boolean executesEnforced) { super(executesEnforced); }
  public ArithmeticPrim(final ArithmeticPrim node) { this(node.executesEnforced); }

  protected final Number reduceToIntIfPossible(final BigInteger result) {
    if (result.bitLength() > 31) {
      return result;
    } else {
      return result.intValue();
    }
  }
}
