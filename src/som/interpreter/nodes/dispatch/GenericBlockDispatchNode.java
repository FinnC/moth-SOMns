package som.interpreter.nodes.dispatch;

import som.vmobjects.SBlock;
import som.vmobjects.SObject;

import com.oracle.truffle.api.frame.VirtualFrame;


public final class GenericBlockDispatchNode extends AbstractDispatchNode {

  @Override
  public Object executeDispatch(final VirtualFrame frame, final SObject domain,
      final boolean enforced, final Object[] arguments) {
    SBlock rcvr = (SBlock) arguments[0];
    return rcvr.getMethod().invoke(domain, rcvr.isEnforced() || enforced, arguments);
  }

  @Override
  public int lengthOfDispatchChain() {
    return 1000;
  }
}
