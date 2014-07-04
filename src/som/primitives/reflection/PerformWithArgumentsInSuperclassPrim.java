package som.primitives.reflection;

import som.interpreter.SArguments;
import som.interpreter.nodes.nary.QuaternaryExpressionNode;
import som.vmobjects.SArray;
import som.vmobjects.SClass;
import som.vmobjects.SInvokable;
import som.vmobjects.SObject;
import som.vmobjects.SSymbol;

import com.oracle.truffle.api.CompilerAsserts;
import com.oracle.truffle.api.dsl.Specialization;
import com.oracle.truffle.api.frame.VirtualFrame;

public abstract class PerformWithArgumentsInSuperclassPrim extends QuaternaryExpressionNode {
  public PerformWithArgumentsInSuperclassPrim(final boolean executesEnforced) { super(null, executesEnforced); }
  public PerformWithArgumentsInSuperclassPrim(final PerformWithArgumentsInSuperclassPrim node) { this(node.executesEnforced); }

  @Specialization
  public final Object doSAbstractObject(final VirtualFrame frame,
      final Object receiver, final SSymbol selector,
      final Object[] argArr, final SClass clazz) {
    CompilerAsserts.neverPartOfCompilation("PerformWithArgumentsInSuperclassPrim.doSAbstractObject()");
    SInvokable invokable = clazz.lookupInvokable(selector);
    SObject domain = SArguments.domain(frame);
    boolean enforced = SArguments.enforced(frame);
    return invokable.invoke(domain, enforced, SArray.fromSArrayToArgArrayWithReceiver(argArr, receiver));
  }

  public abstract static class PerformEnforcedWithArgumentsInSuperclassPrim extends QuaternaryExpressionNode {
    @Child private AbstractSymbolSuperDispatch dispatch;

    public PerformEnforcedWithArgumentsInSuperclassPrim(final boolean executesEnforced) {
      super(null, executesEnforced);
      dispatch = AbstractSymbolSuperDispatch.create(executesEnforced, true);
    }
    public PerformEnforcedWithArgumentsInSuperclassPrim(final PerformEnforcedWithArgumentsInSuperclassPrim node) { this(node.executesEnforced); }

    @Specialization
    public final Object doSAbstractObject(final VirtualFrame frame,
        final Object receiver, final SSymbol selector, final Object[] argArr, final SClass clazz) {
      CompilerAsserts.neverPartOfCompilation();
      return dispatch.executeDispatch(frame, receiver, selector, clazz, argArr);
    }
  }
}
