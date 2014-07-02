package som.interpreter.nodes;

import som.interpreter.TruffleCompiler;
import som.interpreter.TypesGen;
import som.interpreter.nodes.dispatch.AbstractDispatchNode;
import som.interpreter.nodes.dispatch.GenericDispatchNode;
import som.interpreter.nodes.dispatch.SuperDispatchNode;
import som.interpreter.nodes.dispatch.UninitializedDispatchNode;
import som.interpreter.nodes.enforced.EnforcedMessageSendNode;
import som.interpreter.nodes.literals.BlockNode;
import som.interpreter.nodes.nary.EagerBinaryPrimitiveNode;
import som.interpreter.nodes.nary.EagerUnaryPrimitiveNode;
import som.interpreter.nodes.specialized.AndMessageNodeFactory;
import som.interpreter.nodes.specialized.AndMessageNodeFactory.AndBoolMessageNodeFactory;
import som.interpreter.nodes.specialized.IfFalseMessageNodeFactory;
import som.interpreter.nodes.specialized.IfTrueIfFalseMessageNodeFactory;
import som.interpreter.nodes.specialized.IfTrueMessageNodeFactory;
import som.interpreter.nodes.specialized.IntToByDoMessageNodeFactory;
import som.interpreter.nodes.specialized.IntToDoMessageNodeFactory;
import som.interpreter.nodes.specialized.NotMessageNodeFactory;
import som.interpreter.nodes.specialized.OrMessageNodeFactory;
import som.interpreter.nodes.specialized.OrMessageNodeFactory.OrBoolMessageNodeFactory;
import som.interpreter.nodes.specialized.WhileWithDynamicBlocksNode.WhileFalseDynamicBlocksNode;
import som.interpreter.nodes.specialized.WhileWithDynamicBlocksNode.WhileTrueDynamicBlocksNode;
import som.interpreter.nodes.specialized.WhileWithStaticBlocksNode.WhileFalseStaticBlocksNode;
import som.interpreter.nodes.specialized.WhileWithStaticBlocksNode.WhileTrueStaticBlocksNode;
import som.primitives.ArrayPrimsFactory.AtPrimFactory;
import som.primitives.ArrayPrimsFactory.NewPrimFactory;
import som.primitives.BlockPrimsFactory.ValueNonePrimFactory;
import som.primitives.BlockPrimsFactory.ValueOnePrimFactory;
import som.primitives.EqualsEqualsPrimFactory;
import som.primitives.EqualsPrimFactory;
import som.primitives.IntegerPrimsFactory.LeftShiftPrimFactory;
import som.primitives.LengthPrimFactory;
import som.primitives.arithmetic.AdditionPrimFactory;
import som.primitives.arithmetic.BitXorPrimFactory;
import som.primitives.arithmetic.DividePrimFactory;
import som.primitives.arithmetic.DoubleDivPrimFactory;
import som.primitives.arithmetic.GreaterThanPrimFactory;
import som.primitives.arithmetic.LessThanOrEqualPrimFactory;
import som.primitives.arithmetic.LessThanPrimFactory;
import som.primitives.arithmetic.LogicAndPrimFactory;
import som.primitives.arithmetic.ModuloPrimFactory;
import som.primitives.arithmetic.MultiplicationPrimFactory;
import som.primitives.arithmetic.SubtractionPrimFactory;
import som.vm.Universe;
import som.vmobjects.SBlock;
import som.vmobjects.SClass;
import som.vmobjects.SSymbol;

import com.oracle.truffle.api.CompilerDirectives.SlowPath;
import com.oracle.truffle.api.SourceSection;
import com.oracle.truffle.api.frame.VirtualFrame;
import com.oracle.truffle.api.nodes.ExplodeLoop;
import com.oracle.truffle.api.nodes.NodeCost;
import com.oracle.truffle.api.nodes.NodeInfo;


public final class MessageSendNode {

  public static AbstractMessageSendNode create(final SSymbol selector,
      final ExpressionNode[] arguments, final SourceSection source, final boolean executesEnforced) {
    if (executesEnforced) {
      return new EnforcedMessageSendNode(selector, arguments, source);
    } else {
      return new UninitializedMessageSendNode(selector, arguments, source, executesEnforced);
    }
  }

  public static AbstractMessageSendNode createForPerformNodes(
      final SSymbol selector, final boolean executesEnforced) {
    return new UninitializedSymbolSendNode(selector, null, executesEnforced);
  }

  public static AbstractMessageSendNode createForPerformInSuperclassNodes(
      final SSymbol selector, final SClass lookupClass, final boolean executesEnforced) {
    return new GenericMessageSendNode(selector, null,
        SuperDispatchNode.create(selector, lookupClass, executesEnforced),
            null, executesEnforced);
  }

  @NodeInfo(shortName = "send")
  public abstract static class AbstractMessageSendNode extends ExpressionNode
      implements PreevaluatedExpression {

    @Children protected final ExpressionNode[] argumentNodes;

    protected AbstractMessageSendNode(final ExpressionNode[] arguments,
        final SourceSection source, final boolean executesEnforced) {
      super(source, executesEnforced);
      this.argumentNodes = arguments;
    }

    @Override
    public final Object executeGeneric(final VirtualFrame frame) {
      Object[] arguments = evaluateArguments(frame);
      return doPreEvaluated(frame, arguments);
    }

    @ExplodeLoop
    private Object[] evaluateArguments(final VirtualFrame frame) {
      Object[] arguments = new Object[argumentNodes.length];
      for (int i = 0; i < argumentNodes.length; i++) {
        arguments[i] = argumentNodes[i].executeGeneric(frame);
        assert arguments[i] != null;
      }
      return arguments;
    }

    @Override
    public final void executeVoid(final VirtualFrame frame) {
      executeGeneric(frame);
    }
  }

  private abstract static class AbstractUninitializedMessageSendNode extends AbstractMessageSendNode {
    protected final SSymbol selector;

    protected AbstractUninitializedMessageSendNode(final SSymbol selector,
        final ExpressionNode[] arguments, final SourceSection source,
        final boolean executesEnforced) {
      super(arguments, source, executesEnforced);
      this.selector = selector;
    }

    @Override
    public final Object doPreEvaluated(final VirtualFrame frame,
        final Object[] arguments) {
      return specialize(arguments).
          doPreEvaluated(frame, arguments);
    }

    protected PreevaluatedExpression specialize(final Object[] arguments) {
      TruffleCompiler.transferToInterpreterAndInvalidate("Specialize Symbol Send Node");

      // let's organize the specializations by number of arguments
      // perhaps not the best, but one simple way to just get some order into
      // the chaos.

      switch (arguments.length) {
        case  1: return specializeUnary(arguments);
        case  2: return specializeBinary(arguments);
        case  3: return specializeTernary(arguments);
        case  4: return specializeQuaternary(arguments);
      }
      return makeGenericSend();
    }

    private PreevaluatedExpression specializeUnary(final Object[] args) {
      Object receiver = args[0];
      switch (selector.getString()) {
        // eagerly but causious:
        case "value":
          if (receiver instanceof SBlock) {
            return replace(new EagerUnaryPrimitiveNode(selector,
                argumentNodes[0], ValueNonePrimFactory.create(null), executesEnforced));
          }
          break;
        case "length":
          if (receiver instanceof Object[]) {
            return replace(new EagerUnaryPrimitiveNode(selector,
                argumentNodes[0], LengthPrimFactory.create(null), executesEnforced));
          }
          break;
        case "not":
          if (receiver instanceof Boolean) {
            return replace(new EagerUnaryPrimitiveNode(selector,
                argumentNodes[0], NotMessageNodeFactory.create(getSourceSection(), executesEnforced, null), executesEnforced));
          }
          break;
      }
      return makeGenericSend();
    }

    protected PreevaluatedExpression specializeBinary(final Object[] arguments) {
      switch (selector.getString()) {
        case "ifTrue:":
          return replace(IfTrueMessageNodeFactory.create(arguments[0],
              arguments[1],
              Universe.current(), getSourceSection(), executesEnforced,
              argumentNodes[0], argumentNodes[1]));
        case "ifFalse:":
          return replace(IfFalseMessageNodeFactory.create(arguments[0],
              arguments[1],
              Universe.current(), getSourceSection(), executesEnforced,
              argumentNodes[0], argumentNodes[1]));

        // TODO: find a better way for primitives, use annotation or something
        case "<":
          return replace(new EagerBinaryPrimitiveNode(selector, argumentNodes[0],
              argumentNodes[1],
              LessThanPrimFactory.create(null, null), executesEnforced));
        case "<=":
          return replace(new EagerBinaryPrimitiveNode(selector, argumentNodes[0],
              argumentNodes[1],
              LessThanOrEqualPrimFactory.create(null, null), executesEnforced));
        case ">":
          return replace(new EagerBinaryPrimitiveNode(selector, argumentNodes[0],
              argumentNodes[1],
              GreaterThanPrimFactory.create(null, null), executesEnforced));
        case "+":
          return replace(new EagerBinaryPrimitiveNode(selector, argumentNodes[0],
              argumentNodes[1],
              AdditionPrimFactory.create(null, null), executesEnforced));
        case "value:":
          if (arguments[0] instanceof SBlock) {
            return replace(new EagerBinaryPrimitiveNode(selector, argumentNodes[0],
                argumentNodes[1],
                ValueOnePrimFactory.create(null, null), executesEnforced));
          }
          break;
        case "-":
          return replace(new EagerBinaryPrimitiveNode(selector, argumentNodes[0],
              argumentNodes[1],
              SubtractionPrimFactory.create(null, null), executesEnforced));
        case "*":
          return replace(new EagerBinaryPrimitiveNode(selector, argumentNodes[0],
              argumentNodes[1],
              MultiplicationPrimFactory.create(null, null), executesEnforced));
        case "=":
          return replace(new EagerBinaryPrimitiveNode(selector, argumentNodes[0],
              argumentNodes[1],
              EqualsPrimFactory.create(null, null), executesEnforced));
        case "==":
          return replace(new EagerBinaryPrimitiveNode(selector, argumentNodes[0],
              argumentNodes[1],
              EqualsEqualsPrimFactory.create(null, null), executesEnforced));
        case "bitXor:":
          return replace(new EagerBinaryPrimitiveNode(selector, argumentNodes[0],
              argumentNodes[1],
              BitXorPrimFactory.create(null, null), executesEnforced));
        case "//":
          return replace(new EagerBinaryPrimitiveNode(selector, argumentNodes[0],
              argumentNodes[1],
              DoubleDivPrimFactory.create(null, null), executesEnforced));
        case "%":
          return replace(new EagerBinaryPrimitiveNode(selector, argumentNodes[0],
              argumentNodes[1],
              ModuloPrimFactory.create(null, null), executesEnforced));
        case "/":
          return replace(new EagerBinaryPrimitiveNode(selector, argumentNodes[0],
              argumentNodes[1],
              DividePrimFactory.create(null, null), executesEnforced));
        case "&":
          return replace(new EagerBinaryPrimitiveNode(selector, argumentNodes[0],
              argumentNodes[1],
              LogicAndPrimFactory.create(null, null), executesEnforced));

        // eagerly but causious:
        case "<<":
          if (arguments[0] instanceof Long) {
            return replace(new EagerBinaryPrimitiveNode(selector, argumentNodes[0],
                argumentNodes[1],
                LeftShiftPrimFactory.create(null, null), executesEnforced));
          }
          break;
        case "at:":
          if (arguments[0] instanceof Object[]) {
            return replace(new EagerBinaryPrimitiveNode(selector, argumentNodes[0],
                argumentNodes[1],
                AtPrimFactory.create(null, null), executesEnforced));
          }
        case "new:":
          if (arguments[0] == Universe.current().arrayClass) {
            return replace(new EagerBinaryPrimitiveNode(selector, argumentNodes[0],
                argumentNodes[1],
                NewPrimFactory.create(null, null), executesEnforced));
          }
          break;
      }

      return makeGenericSend();
    }

    private PreevaluatedExpression specializeTernary(final Object[] arguments) {
      switch (selector.getString()) {
        case "ifTrue:ifFalse:":
          return replace(IfTrueIfFalseMessageNodeFactory.create(arguments[0],
              arguments[1], arguments[2], Universe.current(), executesEnforced,
              argumentNodes[0], argumentNodes[1], argumentNodes[2]));
        case "to:do:":
          if (TypesGen.TYPES.isLong(arguments[0]) &&
              (TypesGen.TYPES.isLong(arguments[1]) ||
                  TypesGen.TYPES.isDouble(arguments[1])) &&
              TypesGen.TYPES.isSBlock(arguments[2])) {
            return replace(IntToDoMessageNodeFactory.create(this,
                (SBlock) arguments[2], executesEnforced, argumentNodes[0],
                argumentNodes[1], argumentNodes[2]));
          }
          break;
      }
      return makeGenericSend();
    }

    private PreevaluatedExpression specializeQuaternary(
        final Object[] arguments) {
      switch (selector.getString()) {
        case "to:by:do:":
          return replace(IntToByDoMessageNodeFactory.create(this,
              (SBlock) arguments[3], executesEnforced, argumentNodes[0],
              argumentNodes[1], argumentNodes[2], argumentNodes[3]));
      }
      return makeGenericSend();
    }

    protected final GenericMessageSendNode makeGenericSend() {
      GenericMessageSendNode send = new GenericMessageSendNode(selector,
          argumentNodes,
          new UninitializedDispatchNode(selector, Universe.current(), executesEnforced),
          getSourceSection(), executesEnforced);
      return replace(send);
    }
  }

  private static final class UninitializedMessageSendNode
      extends AbstractUninitializedMessageSendNode {

    protected UninitializedMessageSendNode(final SSymbol selector,
        final ExpressionNode[] arguments, final SourceSection source,
        final boolean executesEnforced) {
      super(selector, arguments, source, executesEnforced);
    }

    @Override
    protected PreevaluatedExpression specialize(final Object[] arguments) {
      TruffleCompiler.transferToInterpreterAndInvalidate("Specialize Message Node");

      // first option is a super send, super sends are treated specially because
      // the receiver class is lexically determined
      if (argumentNodes[0] instanceof ISuperReadNode) {
        GenericMessageSendNode node = new GenericMessageSendNode(selector,
            argumentNodes, SuperDispatchNode.create(selector,
                (ISuperReadNode) argumentNodes[0], executesEnforced),
                getSourceSection(), executesEnforced);
        return replace(node);
      }

      // We treat super sends separately for simplicity, might not be the
      // optimal solution, especially in cases were the knowledge of the
      // receiver class also allows us to do more specific things, but for the
      // moment  we will leave it at this.
      // TODO: revisit, and also do more specific optimizations for super sends.

      return super.specialize(arguments);
    }

    @Override
    protected PreevaluatedExpression specializeBinary(final Object[] arguments) {
      switch (selector.getString()) {
        case "whileTrue:": {
          if (argumentNodes[1] instanceof BlockNode &&
              argumentNodes[0] instanceof BlockNode) {
            BlockNode argBlockNode = (BlockNode) argumentNodes[1];
            SBlock    argBlock     = (SBlock)    arguments[1];
            return replace(new WhileTrueStaticBlocksNode(
                (BlockNode) argumentNodes[0], argBlockNode,
                (SBlock) arguments[0],
                argBlock, Universe.current(), getSourceSection(), executesEnforced));
          }
          break; // use normal send
        }
        case "whileFalse:":
          if (argumentNodes[1] instanceof BlockNode &&
              argumentNodes[0] instanceof BlockNode) {
            BlockNode argBlockNode = (BlockNode) argumentNodes[1];
            SBlock    argBlock     = (SBlock)    arguments[1];
            return replace(new WhileFalseStaticBlocksNode(
                (BlockNode) argumentNodes[0], argBlockNode,
                (SBlock) arguments[0], argBlock, Universe.current(), getSourceSection(), executesEnforced));
          }
          break; // use normal send
        case "and:":
        case "&&":
          if (arguments[0] instanceof Boolean) {
            if (argumentNodes[1] instanceof BlockNode) {
              return replace(AndMessageNodeFactory.create((SBlock) arguments[1],
                  getSourceSection(), executesEnforced,
                  argumentNodes[0], argumentNodes[1]));
            } else if (arguments[1] instanceof Boolean) {
              return replace(AndBoolMessageNodeFactory.create(getSourceSection(),
                  executesEnforced,
                  argumentNodes[0], argumentNodes[1]));
            }
          }
          break;
        case "or:":
        case "||":
          if (arguments[0] instanceof Boolean) {
            if (argumentNodes[1] instanceof BlockNode) {
              return replace(OrMessageNodeFactory.create((SBlock) arguments[1],
                  getSourceSection(), executesEnforced,
                  argumentNodes[0], argumentNodes[1]));
            } else if (arguments[1] instanceof Boolean) {
              return replace(OrBoolMessageNodeFactory.create(
                  getSourceSection(), executesEnforced,
                  argumentNodes[0], argumentNodes[1]));
            }
          }
          break;
      }

      return super.specializeBinary(arguments);
    }
  }


  private static final class UninitializedSymbolSendNode
    extends AbstractUninitializedMessageSendNode {

    protected UninitializedSymbolSendNode(final SSymbol selector,
        final SourceSection source, final boolean executesEnforced) {
      super(selector, new ExpressionNode[0], source, executesEnforced);
    }

    @Override
    protected PreevaluatedExpression specializeBinary(final Object[] arguments) {
      switch (selector.getString()) {
        case "whileTrue:": {
          if (arguments[1] instanceof SBlock && arguments[0] instanceof SBlock) {
            SBlock argBlock = (SBlock) arguments[1];
            return replace(new WhileTrueDynamicBlocksNode((SBlock) arguments[0],
                argBlock, Universe.current(), getSourceSection(), executesEnforced));
          }
          break;
        }
        case "whileFalse:":
          if (arguments[1] instanceof SBlock && arguments[0] instanceof SBlock) {
            SBlock    argBlock     = (SBlock)    arguments[1];
            return replace(new WhileFalseDynamicBlocksNode(
                (SBlock) arguments[0], argBlock, Universe.current(), getSourceSection(), executesEnforced));
          }
          break; // use normal send
      }

      return super.specializeBinary(arguments);
    }
  }

  public static final class GenericMessageSendNode
      extends AbstractMessageSendNode {

    private final SSymbol selector;

    public static GenericMessageSendNode create(final SSymbol selector,
        final ExpressionNode[] argumentNodes, final SourceSection source,
        final boolean executesEnforced) {
      return new GenericMessageSendNode(selector, argumentNodes,
          new UninitializedDispatchNode(selector, Universe.current(), executesEnforced), source, executesEnforced);
    }

    @Child private AbstractDispatchNode dispatchNode;

    private GenericMessageSendNode(final SSymbol selector,
        final ExpressionNode[] arguments,
        final AbstractDispatchNode dispatchNode, final SourceSection source,
        final boolean executesEnforced) {
      super(arguments, source, executesEnforced);
      this.selector = selector;
      this.dispatchNode = dispatchNode;
    }

    @Override
    public Object doPreEvaluated(final VirtualFrame frame,
        final Object[] arguments) {
      return dispatchNode.executeDispatch(frame, arguments);
    }

    @SlowPath
    public AbstractDispatchNode getDispatchListHead() {
      return dispatchNode;
    }

    @SlowPath
    public void adoptNewDispatchListHead(final AbstractDispatchNode newHead) {
      dispatchNode = insert(newHead);
    }

    @SlowPath
    public void replaceDispatchListHead(
        final GenericDispatchNode replacement) {
      dispatchNode.replace(replacement);
    }

    @Override
    public String toString() {
      return "GMsgSend(" + selector.getString() + ")";
    }

    @Override
    public NodeCost getCost() {
      int dispatchChain = dispatchNode.lengthOfDispatchChain();
      if (dispatchChain == 0) {
        return NodeCost.UNINITIALIZED;
      } else if (dispatchChain == 1) {
        return NodeCost.MONOMORPHIC;
      } else if (dispatchChain <= AbstractDispatchNode.INLINE_CACHE_SIZE) {
        return NodeCost.POLYMORPHIC;
      } else {
        return NodeCost.MEGAMORPHIC;
      }
    }
  }
}
