package som.primitives;

import som.interpreter.nodes.ExpressionNode;
import som.interpreter.nodes.nary.UnaryExpressionNode;
import som.vm.Universe;

import com.oracle.truffle.api.frame.VirtualFrame;

public final class EmptyPrim extends UnaryExpressionNode {
  @Child private ExpressionNode receiver;
  private final boolean isUnenforced;

  private EmptyPrim(final ExpressionNode receiver, final boolean isUnenforced) {
    super(null, false);
    this.receiver = receiver;
    this.isUnenforced = isUnenforced;
  }

  public EmptyPrim(final EmptyPrim node) { this(node.receiver, node.isUnenforced); }

  @Override
  public Object executeGeneric(final VirtualFrame frame) {
    return executeEvaluated(frame, null);
  }

  @Override
  public void executeVoid(final VirtualFrame frame) {
    executeGeneric(frame);
  }

  @Override
  public Object executeEvaluated(final VirtualFrame frame, final Object receiver) {
    Universe.println("Warning: undefined primitive called");
    return null;
  }

  @Override
  public void executeEvaluatedVoid(final VirtualFrame frame,
      final Object receiver) { executeEvaluated(frame, receiver); }

  public static EmptyPrim create(final ExpressionNode receiver,
      final boolean isUnenforced) {
    return new EmptyPrim(receiver, isUnenforced);
  }
}
