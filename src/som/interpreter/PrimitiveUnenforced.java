package som.interpreter;

import som.interpreter.nodes.ExpressionNode;
import som.primitives.EmptyPrim;

import com.oracle.truffle.api.CompilerAsserts;
import com.oracle.truffle.api.frame.FrameDescriptor;
import com.oracle.truffle.api.nodes.RootNode;


public final class PrimitiveUnenforced extends InvokableUnenforced {

  public PrimitiveUnenforced(final ExpressionNode primitiveUnenforced,
      final FrameDescriptor frameDescriptor) {
    super(null, frameDescriptor, primitiveUnenforced);
  }

  @Override
  public AbstractInvokable cloneWithNewLexicalContext(final LexicalContext outerContext) {
    FrameDescriptor inlinedFrameDescriptor = getFrameDescriptor().copy();
    LexicalContext  inlinedContext = new LexicalContext(inlinedFrameDescriptor,
        outerContext);
    ExpressionNode  inlinedUnenforcedBody = Inliner.doInline(
        uninitializedUnenforcedBody, inlinedContext);
    return new PrimitiveUnenforced(inlinedUnenforcedBody,
        inlinedFrameDescriptor);
  }

  @Override
  public RootNode split() {
    return cloneWithNewLexicalContext(null);
  }

  @Override
  public boolean isBlock() {
    return false;
  }

  @Override
  public boolean isEmptyPrimitive() {
    return uninitializedUnenforcedBody instanceof EmptyPrim;
  }

  @Override
  public String toString() {
    return "Primitive " + unenforcedBody.getClass().getSimpleName() + "@" + Integer.toHexString(hashCode());
  }

  @Override
  public void propagateLoopCountThroughoutLexicalScope(final long count) {
    Primitive.propagateLoopCount(count);
  }

  @Override
  public void setOuterContextMethod(final AbstractInvokable method) {
    CompilerAsserts.neverPartOfCompilation("PrimitiveUnenforced");
    throw new UnsupportedOperationException("Only supported on methods");
  }
}
