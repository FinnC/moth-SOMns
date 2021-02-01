package som.primitives.bitops;

import java.math.BigInteger;

import com.oracle.truffle.api.CompilerDirectives.TruffleBoundary;
import com.oracle.truffle.api.dsl.GenerateNodeFactory;
import com.oracle.truffle.api.dsl.Specialization;

import bd.primitives.Primitive;
import som.primitives.arithmetic.ArithmeticPrim;
import som.vmobjects.SType;


@GenerateNodeFactory
@Primitive(primitive = "int:bitAnd:")
@Primitive(primitive = "double:bitAnd:")
@Primitive(selector = "&")
@Primitive(selector = "bitAnd:")
public abstract class BitAndPrim extends ArithmeticPrim {
  @Specialization
  public final long doLong(final long left, final long right) {
    return left & right;
  }

  @Specialization
  public final long doLong(final double left, final long right) {
    return ((long) left) & right;
  }

  @Specialization
  public final long doLong(final long left, final double right) {
    return left & ((long) right);
  }

  @Specialization
  public final long doDouble(final double left, final double right) {
    return ((long) left) & ((long) right);
  }

  @Specialization
  @TruffleBoundary
  public final Object doBigInteger(final BigInteger left, final BigInteger right) {
    return left.and(right);
  }

  @Specialization
  @TruffleBoundary
  public final Object doLong(final long left, final BigInteger right) {
    return doBigInteger(BigInteger.valueOf(left), right);
  }

  @Specialization
  @TruffleBoundary
  public final Object doBigInteger(final BigInteger left, final long right) {
    return doBigInteger(left, BigInteger.valueOf(right));
  }

  /**
   * & is also used as the operator for doing type intersections.
   */
  @Specialization
  @TruffleBoundary
  public final Object doTypeIntersection(final SType left, final SType right) {
    return new SType.IntersectionType(left, right);
  }
}
