package som.primitives.arithmetic;

import java.math.BigInteger;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

import com.oracle.truffle.api.CompilerDirectives.TruffleBoundary;
import com.oracle.truffle.api.dsl.GenerateNodeFactory;
import com.oracle.truffle.api.dsl.Specialization;

import bd.primitives.Primitive;
import som.vmobjects.SClass;
import som.vmobjects.SSymbol;
import som.vmobjects.SType;


@GenerateNodeFactory
@Primitive(primitive = "int:add:")
@Primitive(primitive = "double:add:")
@Primitive(selector = "+")
public abstract class AdditionPrim extends ArithmeticPrim {
  @Specialization(rewriteOn = ArithmeticException.class)
  public final long doLong(final long left, final long argument) {
    return Math.addExact(left, argument);
  }

  @Specialization
  @TruffleBoundary
  public final BigInteger doLongWithOverflow(final long left, final long argument) {
    return BigInteger.valueOf(left).add(BigInteger.valueOf(argument));
  }

  @Specialization
  @TruffleBoundary
  public final Object doBigInteger(final BigInteger left, final BigInteger right) {
    BigInteger result = left.add(right);
    return reduceToLongIfPossible(result);
  }

  @Specialization
  public final double doDouble(final double left, final double right) {
    return right + left;
  }

  @Specialization
  @TruffleBoundary
  public final String doString(final String left, final String right) {
    return left + right;
  }

  @Specialization
  @TruffleBoundary
  public final String doSSymbol(final SSymbol left, final SSymbol right) {
    return left.getString() + right.getString();
  }

  @Specialization
  @TruffleBoundary
  public final String doSSymbol(final SSymbol left, final String right) {
    return left.getString() + right;
  }

  @Specialization
  @TruffleBoundary
  public final Object doLong(final long left, final BigInteger argument) {
    return doBigInteger(BigInteger.valueOf(left), argument);
  }

  @Specialization
  public final double doLong(final long left, final double argument) {
    return doDouble(left, argument);
  }

  @Specialization
  @TruffleBoundary
  public final Object doBigInteger(final BigInteger left, final long right) {
    return doBigInteger(left, BigInteger.valueOf(right));
  }

  @Specialization
  public final double doDouble(final double left, final long right) {
    return doDouble(left, (double) right);
  }

  @Specialization
  @TruffleBoundary
  public final String doString(final String left, final long right) {
    return left + right;
  }

  @Specialization
  @TruffleBoundary
  public final String doString(final String left, final SClass right) {
    return left + right.getName().getString();
  }

  @Specialization
  @TruffleBoundary
  public final String doString(final String left, final SSymbol right) {
    return left + right.getString();
  }

  /**
   * + is used for type union representing the methods that both types have.
   */
  @Specialization
  @TruffleBoundary
  public final SType doTypeUnion(final SType left, final SType right) {
    Set<SSymbol> signatures = new HashSet<>();
    signatures.addAll(Arrays.asList(left.getSignatures()));
    signatures.retainAll(Arrays.asList(right.getSignatures()));
    return new SType.InterfaceType(signatures.toArray(new SSymbol[signatures.size()]));
  }
}
