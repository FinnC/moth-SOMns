package som.interpreter.nodes.nary;

import som.interpreter.TruffleCompiler;
import som.interpreter.nodes.ExpressionNode;
import som.interpreter.nodes.MessageSendNode;
import som.interpreter.nodes.MessageSendNode.AbstractMessageSendNode;
import som.vmobjects.SSymbol;

import com.oracle.truffle.api.dsl.UnsupportedSpecializationException;
import com.oracle.truffle.api.frame.VirtualFrame;
import com.oracle.truffle.api.utilities.BranchProfile;


public final class EagerTernaryPrimitiveNode extends TernaryExpressionNode {

  @Child private ExpressionNode receiver;
  @Child private ExpressionNode argument1;
  @Child private ExpressionNode argument2;
  @Child private TernaryExpressionNode primitive;

  private final BranchProfile unsupportedSpecialization;
  private final SSymbol selector;

  public EagerTernaryPrimitiveNode(
      final SSymbol selector,
      final ExpressionNode receiver,
      final ExpressionNode argument1,
      final ExpressionNode argument2,
      final TernaryExpressionNode primitive, final boolean executesEnforced) {
    super(null, executesEnforced);
    this.receiver  = receiver;
    this.argument1 = argument1;
    this.argument2 = argument2;
    this.primitive = primitive;

    this.unsupportedSpecialization = new BranchProfile();
    this.selector = selector;
  }

  @Override
  public Object executeGeneric(final VirtualFrame frame) {
    Object rcvr = receiver.executeGeneric(frame);
    Object arg1 = argument1.executeGeneric(frame);
    Object arg2 = argument2.executeGeneric(frame);

    return executeEvaluated(frame, rcvr, arg1, arg2);
  }

  @Override
  public void executeVoid(final VirtualFrame frame) {
    Object rcvr = receiver.executeGeneric(frame);
    Object arg1 = argument1.executeGeneric(frame);
    Object arg2 = argument2.executeGeneric(frame);

    executeEvaluatedVoid(frame, rcvr, arg1, arg2);
  }

  @Override
  public Object executeEvaluated(final VirtualFrame frame,
    final Object receiver, final Object argument1, final Object argument2) {
    try {
      return primitive.executeEvaluated(frame, receiver, argument1, argument2);
    } catch (UnsupportedSpecializationException e) {
      unsupportedSpecialization.enter();
      TruffleCompiler.transferToInterpreterAndInvalidate("Eager Primitive with unsupported specialization.");
      return makeGenericSend().doPreEvaluated(frame,
          new Object[] {receiver, argument1, argument2});
    }
  }

  @Override
  public void executeEvaluatedVoid(final VirtualFrame frame,
    final Object receiver, final Object argument1, final Object argument2) {
    try {
      primitive.executeEvaluatedVoid(frame, receiver, argument1, argument2);
    } catch (UnsupportedSpecializationException e) {
      unsupportedSpecialization.enter();
      TruffleCompiler.transferToInterpreterAndInvalidate("Eager Primitive with unsupported specialization.");
      makeGenericSend().doPreEvaluated(frame,
          new Object[] {receiver, argument1, argument2});
    }
  }

  private AbstractMessageSendNode makeGenericSend() {
    AbstractMessageSendNode node = MessageSendNode.createGeneric(selector,
        new ExpressionNode[] {receiver, argument1, argument2}, getSourceSection(), executesEnforced);
    return replace(node);
  }
}
