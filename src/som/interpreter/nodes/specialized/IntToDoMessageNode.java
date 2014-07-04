package som.interpreter.nodes.specialized;

import som.interpreter.Invokable;
import som.interpreter.SArguments;
import som.interpreter.nodes.ExpressionNode;
import som.interpreter.nodes.PreevaluatedExpression;
import som.interpreter.nodes.nary.TernaryExpressionNode;
import som.vmobjects.SBlock;
import som.vmobjects.SInvokable;
import som.vmobjects.SObject;

import com.oracle.truffle.api.CompilerAsserts;
import com.oracle.truffle.api.CompilerDirectives;
import com.oracle.truffle.api.CompilerDirectives.SlowPath;
import com.oracle.truffle.api.Truffle;
import com.oracle.truffle.api.dsl.Specialization;
import com.oracle.truffle.api.frame.VirtualFrame;
import com.oracle.truffle.api.nodes.DirectCallNode;
import com.oracle.truffle.api.nodes.Node;
import com.oracle.truffle.api.nodes.RootNode;


public abstract class IntToDoMessageNode extends TernaryExpressionNode
    implements PreevaluatedExpression {

  private final SInvokable blockMethod;
  @Child private DirectCallNode valueSend;
  private final boolean blockEnforced;

  public IntToDoMessageNode(final ExpressionNode orignialNode,
      final SBlock block, final boolean executesEnforced) {
    super(orignialNode.getSourceSection(), executesEnforced);
    blockMethod = block.getMethod();
    valueSend = Truffle.getRuntime().createDirectCallNode(
                    blockMethod.getCallTarget());
    blockEnforced = block.isEnforced();
  }

  public IntToDoMessageNode(final IntToDoMessageNode node) {
    super(node.getSourceSection(), node.executesEnforced);
    this.blockMethod = node.blockMethod;
    this.valueSend   = node.valueSend;
    this.blockEnforced = node.blockEnforced;
  }

  @Override
  public final Object doPreEvaluated(final VirtualFrame frame,
      final Object[] arguments) {
    return executeEvaluated(frame, arguments[0], arguments[1], arguments[2]);
  }

  protected final boolean isSameBlockLong(final long receiver, final long limit, final SBlock block) {
    return block.getMethod() == blockMethod;
  }

  @Specialization(guards = "isSameBlockLong")
  public final long doIntToDo(final VirtualFrame frame, final long receiver, final long limit, final SBlock block) {
    try {
      SObject domain = SArguments.domain(frame);
      for (long i = receiver; i <= limit; i++) {
        valueSend.call(frame, SArguments.createSArguments(domain, blockEnforced, new Object[] {block, i}));
      }
    } finally {
      if (CompilerDirectives.inInterpreter() && (limit - receiver) > 0) {
        reportLoopCount(limit - receiver);
      }
    }
    return receiver;
  }

  protected final boolean isSameBlockDouble(final long receiver, final double limit, final SBlock block) {
    return block.getMethod() == blockMethod;
  }

  @Specialization(guards = "isSameBlockDouble")
  public final long doIntToDo(final VirtualFrame frame, final long receiver, final double limit, final SBlock block) {
    try {
      SObject domain = SArguments.domain(frame);
      for (long i = receiver; i <= limit; i++) {
        valueSend.call(frame, SArguments.createSArguments(domain, blockEnforced, new Object[] {block, i}));
      }
    } finally {
      if (CompilerDirectives.inInterpreter()) {
        reportLoopCount((int) limit - receiver);
      }
    }
    return receiver;
  }

  @SlowPath
  private void reportLoopCount(final long count) {
    CompilerAsserts.neverPartOfCompilation("reportLoopCount");
    Node current = getParent();
    while (current != null && !(current instanceof RootNode)) {
      current = current.getParent();
    }
    if (current != null) {
      ((Invokable) current).propagateLoopCountThroughoutLexicalScope(count);
    }
  }
}
