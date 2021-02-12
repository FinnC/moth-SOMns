package som.interpreter.nodes;

import com.oracle.truffle.api.CompilerDirectives;
import com.oracle.truffle.api.frame.VirtualFrame;
import com.oracle.truffle.api.instrumentation.GenerateWrapper;
import com.oracle.truffle.api.instrumentation.ProbeNode;
import com.oracle.truffle.api.instrumentation.Tag;
import com.oracle.truffle.api.nodes.InvalidAssumptionException;
import com.oracle.truffle.api.profiles.IntValueProfile;
import com.oracle.truffle.api.source.SourceSection;
import com.oracle.truffle.api.nodes.Node;

import som.interpreter.nodes.ExceptionSignalingNode;
import som.interpreter.nodes.dispatch.DispatchGuard.CheckSObject;
import som.interpreter.objectstorage.StorageAccessor.AbstractObjectAccessor;
import som.interpreter.objectstorage.StorageAccessor.AbstractPrimitiveAccessor;
import som.vm.Symbols;
import som.vm.constants.Nil;
import som.vmobjects.SObject;
import tools.dym.Tags.ClassRead;
import tools.dym.Tags.FieldRead;

import java.util.function.Consumer;

/**
 * Throws a FieldNotInitialisedException. Used when a field is read before being initialised.
 *
 * @author FinnC
 *
 */
public class UninitialisedFieldException {
  private static boolean ignoreError = false;
  public static void throwError(final SourceSection sourceSection, ExceptionSignalingNode exception, Consumer<ExceptionSignalingNode> insert) {
    CompilerDirectives.transferToInterpreter();

    // Ensures throwing exception doesn't trigger more errors that throw the same exception recursively
    if (ignoreError) {
      ignoreError = false;
      return;
    }

    // Create the exception node if it hasn't been already
    if (exception == null) {
      ExceptionSignalingNode exNode = ExceptionSignalingNode.createNode(
          Symbols.symbolFor("FieldNotInitialisedException"), sourceSection);
      insert.accept(exNode);
      exception = exNode;
    }

    // Get the human-readable version of the source location
    int line = sourceSection.getStartLine();
    int column = sourceSection.getStartColumn();
    String[] parts = sourceSection.getSource().getURI().getPath().split("/");

    // Newspeak allows reading of uninitialised values but Grace does not
    // This ignores the error when it occurs in .ns (Newspeak) files
    if (parts[parts.length - 1].endsWith(".ns")) {
      return;
    }

    String prefix = parts[parts.length - 1] + " [" + line + "," + column + "]";

    // Throw the exception
    ignoreError = true;
    exception.signal(prefix + " Attempted to read an uninitialised field");
  }
}
