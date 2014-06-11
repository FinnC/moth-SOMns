package som.primitives;

import java.math.BigInteger;

import som.interpreter.nodes.nary.UnaryExpressionNode.UnarySideEffectFreeExpressionNode;
import som.primitives.arithmetic.ArithmeticPrim;
import som.vm.Universe;
import som.vmobjects.SClass;

import com.oracle.truffle.api.dsl.Specialization;
import com.oracle.truffle.api.utilities.BranchProfile;

public abstract class IntegerPrims {

  public abstract static class RandomPrim extends UnarySideEffectFreeExpressionNode {
    public RandomPrim() { super(false); } /* TODO: enforced!!! */

    @Specialization
    public final long doLong(final long receiver) {
      return (long) (receiver * Math.random());
    }
  }

  public abstract static class FromStringPrim extends ArithmeticPrim {
    private final Universe universe;
    public FromStringPrim() { this.universe = Universe.current(); }

    protected final boolean receiverIsIntegerClass(final SClass receiver) {
      return receiver == universe.integerClass;
    }

    @Specialization(guards = "receiverIsIntegerClass")
    public final Object doSClass(final SClass receiver, final String argument) {
      return Long.parseLong(argument);
    }
  }

  public abstract static class LeftShiftPrim extends ArithmeticPrim {
    private final BranchProfile overflow = new BranchProfile();

    @Specialization(rewriteOn = ArithmeticException.class)
    public final long doLong(final long receiver, final long right) {
      assert right >= 0;  // currently not defined for negative values of right

      if (Long.SIZE - Long.numberOfLeadingZeros(receiver) + right > Long.SIZE - 1) {
        overflow.enter();
        throw new ArithmeticException("shift overflows long");
      }
      return receiver << right;
    }

    @Specialization
    public final BigInteger doLongWithOverflow(final long receiver, final long right) {
      assert right >= 0;  // currently not defined for negative values of right
      assert right <= Integer.MAX_VALUE;

      return BigInteger.valueOf(receiver).shiftLeft((int) right);
    }
  }
}
