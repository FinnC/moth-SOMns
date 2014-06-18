/**
 * Copyright (c) 2013 Stefan Marr,   stefan.marr@vub.ac.be
 * Copyright (c) 2009 Michael Haupt, michael.haupt@hpi.uni-potsdam.de
 * Software Architecture Group, Hasso Plattner Institute, Potsdam, Germany
 * http://www.hpi.uni-potsdam.de/swa/
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

package som.vm;

import static som.vmobjects.SDomain.createStandardDomain;

import java.io.File;
import java.io.IOException;
import java.util.HashMap;
import java.util.StringTokenizer;

import som.compiler.Disassembler;
import som.interpreter.AbstractInvokable;
import som.interpreter.TruffleCompiler;
import som.vmobjects.SArray;
import som.vmobjects.SBlock;
import som.vmobjects.SClass;
import som.vmobjects.SDomain;
import som.vmobjects.SInvokable;
import som.vmobjects.SInvokable.SMethod;
import som.vmobjects.SInvokable.SPrimitive;
import som.vmobjects.SObject;
import som.vmobjects.SSymbol;

import com.oracle.truffle.api.CompilerDirectives.CompilationFinal;
import com.oracle.truffle.api.CompilerDirectives.SlowPath;
import com.oracle.truffle.api.Truffle;
import com.oracle.truffle.api.TruffleRuntime;
import com.oracle.truffle.api.frame.MaterializedFrame;

public class Universe {

  /**
   * Associations are handles for globals with a fixed
   * SSymbol and a mutable value.
   */
  public static final class Association {
    private final SSymbol    key;
    @CompilationFinal private Object  value;

    public Association(final SSymbol key, final Object value) {
      this.key   = key;
      this.value = value;
    }

    public SSymbol getKey() {
      return key;
    }

    public Object getValue() {
      return value;
    }

    public void setValue(final Object value) {
      TruffleCompiler.transferToInterpreterAndInvalidate("Changed global");
      this.value = value;
    }
  }

  public static void main(final String[] arguments) {
    Universe u = new Universe();

    try {
      u.interpret(arguments);
      u.exit(0);
    } catch (IllegalStateException e) {
      u.errorExit(e.getMessage());
    }
  }

  public Object interpret(String[] arguments) {
    // Check for command line switches
    arguments = handleArguments(arguments);

    // Initialize the known universe
    return execute(arguments);
  }

  public Universe() { this(false); }
  public Universe(final boolean avoidExit) {
    this.truffleRuntime = Truffle.getRuntime();
    this.globals      = new HashMap<SSymbol, Association>();
    this.symbolTable  = new HashMap<>();
    this.avoidExit    = avoidExit;
    this.lastExitCode = 0;

    this.blockClasses = new SClass[4];

    current = this;
  }

  public TruffleRuntime getTruffleRuntime() {
    return truffleRuntime;
  }

  @SlowPath
  public void exit(final int errorCode) {
    // Exit from the Java system
    if (!avoidExit) {
      System.exit(errorCode);
    } else {
      lastExitCode = errorCode;
    }
  }

  public int lastExitCode() {
    return lastExitCode;
  }

  @SlowPath
  public void errorExit(final String message) {
    errorPrintln("Runtime Error: " + message);
    exit(1);
  }

  @SlowPath
  public String[] handleArguments(String[] arguments) {
    boolean gotClasspath = false;
    String[] remainingArgs = new String[arguments.length];
    int cnt = 0;

    for (int i = 0; i < arguments.length; i++) {
      if (arguments[i].equals("-cp")) {
        if (i + 1 >= arguments.length) {
          printUsageAndExit();
        }
        setupClassPath(arguments[i + 1]);
        // Checkstyle: stop
        ++i; // skip class path
        // Checkstyle: resume
        gotClasspath = true;
      } else if (arguments[i].equals("-d")) {
        printAST = true;
      } else {
        remainingArgs[cnt++] = arguments[i];
      }
    }

    if (!gotClasspath) {
      // Get the default class path of the appropriate size
      classPath = setupDefaultClassPath(0);
    }

    // Copy the remaining elements from the original array into the new
    // array
    arguments = new String[cnt];
    System.arraycopy(remainingArgs, 0, arguments, 0, cnt);

    // check remaining args for class paths, and strip file extension
    for (int i = 0; i < arguments.length; i++) {
      String[] split = getPathClassExt(arguments[i]);

      if (!("".equals(split[0]))) { // there was a path
        String[] tmp = new String[classPath.length + 1];
        System.arraycopy(classPath, 0, tmp, 1, classPath.length);
        tmp[0] = split[0];
        classPath = tmp;
      }
      arguments[i] = split[1];
    }

    return arguments;
  }

  @SlowPath
  // take argument of the form "../foo/Test.som" and return
  // "../foo", "Test", "som"
  private String[] getPathClassExt(final String arg) {
    File file = new File(arg);

    String path = file.getParent();
    StringTokenizer tokenizer = new StringTokenizer(file.getName(), ".");

    if (tokenizer.countTokens() > 2) {
      println("Class with . in its name?");
      exit(1);
    }

    String[] result = new String[3];
    result[0] = (path == null) ? "" : path;
    result[1] = tokenizer.nextToken();
    result[2] = tokenizer.hasMoreTokens() ? tokenizer.nextToken() : "";

    return result;
  }

  @SlowPath
  public void setupClassPath(final String cp) {
    // Create a new tokenizer to split up the string of directories
    StringTokenizer tokenizer = new StringTokenizer(cp, File.pathSeparator);

    // Get the default class path of the appropriate size
    classPath = setupDefaultClassPath(tokenizer.countTokens());

    // Get the directories and put them into the class path array
    for (int i = 0; tokenizer.hasMoreTokens(); i++) {
      classPath[i] = tokenizer.nextToken();
    }
  }

  @SlowPath
  private String[] setupDefaultClassPath(final int directories) {
    // Get the default system class path
    String systemClassPath = System.getProperty("system.class.path");

    // Compute the number of defaults
    int defaults = (systemClassPath != null) ? 2 : 1;

    // Allocate an array with room for the directories and the defaults
    String[] result = new String[directories + defaults];

    // Insert the system class path into the defaults section
    if (systemClassPath != null) {
      result[directories] = systemClassPath;
    }

    // Insert the current directory into the defaults section
    result[directories + defaults - 1] = ".";

    // Return the class path
    return result;
  }

  @SlowPath
  private void printUsageAndExit() {
    // Print the usage
    println("Usage: som [-options] [args...]                          ");
    println("                                                         ");
    println("where options include:                                   ");
    println("    -cp <directories separated by " + File.pathSeparator
        + ">");
    println("                  set search path for application classes");
    println("    -d            enable disassembling");

    // Exit
    System.exit(0);
  }

  /**
   * Start interpretation by sending the selector to the given class.
   * This is mostly meant for testing currently.
   *
   * @param className
   * @param selector
   * @return
   */
  public Object interpret(final String className,
      final String selector) {
    initializeObjectSystem();

    SClass clazz = loadClass(symbolFor(className));

    // Lookup the initialize invokable on the system class
    SInvokable initialize = clazz.getSOMClass(this).
                                        lookupInvokable(symbolFor(selector));
    return initialize.invoke(standardDomain, false, clazz);
  }

  private Object execute(final String[] arguments) {
    initializeObjectSystem();

    // Start the shell if no filename is given
    if (arguments.length == 0) {
      Shell shell = new Shell(this);
      return shell.start();
    }

    // Lookup the initialize invokable on the system class
    SInvokable initialize = systemClass.
        lookupInvokable(symbolFor("initialize:"));

    return initialize.invoke(standardDomain, false, systemObject,
        SArray.newSArray(arguments, standardDomain));
  }

  @SlowPath
  protected void initializeObjectSystem() {
    // Allocate the nil object
    nilObject = SObject.create(null, null, 0);
    standardDomain = createStandardDomain(nilObject);
    nilObject.setDomain(standardDomain);

    // Allocate the Metaclass classes
    metaclassClass = newMetaclassClass(standardDomain);

    // Allocate the rest of the system classes
    objectClass     = newSystemClass(standardDomain);
    nilClass        = newSystemClass(standardDomain);
    classClass      = newSystemClass(standardDomain);
    arrayClass      = newSystemClass(standardDomain);
    symbolClass     = newSystemClass(standardDomain);
    methodClass     = newSystemClass(standardDomain);
    integerClass    = newSystemClass(standardDomain);
    primitiveClass  = newSystemClass(standardDomain);
    stringClass     = newSystemClass(standardDomain);
    doubleClass     = newSystemClass(standardDomain);
    domainClass     = newSystemClass(standardDomain, 1);

    // Setup the class reference for the nil object
    nilObject.setClass(nilClass, nilObject);
    standardDomain.setClass(domainClass, nilObject);

    // Initialize the system classes.
    initializeSystemClass(objectClass,            null, "Object");
    initializeSystemClass(classClass,      objectClass, "Class");
    initializeSystemClass(metaclassClass,   classClass, "Metaclass");
    initializeSystemClass(nilClass,        objectClass, "Nil");
    initializeSystemClass(arrayClass,      objectClass, "Array");
    initializeSystemClass(methodClass,      arrayClass, "Method");
    initializeSystemClass(symbolClass,     objectClass, "Symbol");
    initializeSystemClass(integerClass,    objectClass, "Integer");
    initializeSystemClass(primitiveClass,  objectClass, "Primitive");
    initializeSystemClass(stringClass,     objectClass, "String");
    initializeSystemClass(doubleClass,     objectClass, "Double");
    initializeSystemClass(domainClass,     objectClass, "Domain");

    // Load methods and fields into the system classes
    loadSystemClass(objectClass);
    loadSystemClass(classClass);
    loadSystemClass(metaclassClass);
    loadSystemClass(nilClass);
    loadSystemClass(arrayClass);
    loadSystemClass(methodClass);
    loadSystemClass(symbolClass);
    loadSystemClass(integerClass);
    loadSystemClass(primitiveClass);
    loadSystemClass(stringClass);
    loadSystemClass(doubleClass);
    loadSystemClass(domainClass);

    // Load the generic block class
    blockClasses[0] = loadClass(symbolFor("Block"));

    // Setup the true and false objects
    SSymbol trueClassName = symbolFor("True");
    trueClass             = loadClass(trueClassName);
    trueObject            = newInstance(trueClass, standardDomain);

    SSymbol falseClassName = symbolFor("False");
    falseClass             = loadClass(falseClassName);
    falseObject            = newInstance(falseClass, standardDomain);

    // Load the system class and create an instance of it
    systemClass  = loadClass(symbolFor("System"));
    systemObject = newInstance(systemClass, standardDomain);

    // Put special objects and classes into the dictionary of globals
    setGlobal(symbolFor("nil"),    nilObject);
    setGlobal(symbolFor("true"),   trueObject);
    setGlobal(symbolFor("false"),  falseObject);
    setGlobal(symbolFor("system"), systemObject);
    setGlobal(symbolFor("System"), systemClass);
    setGlobal(symbolFor("Block"),  blockClasses[0]);

    setGlobal(symbolFor("Nil"), nilClass);

    setGlobal(trueClassName,  trueClass);
    setGlobal(falseClassName, falseClass);

    SDomain.completeStandardDomainInitialization(standardDomain);

    objectSystemInitialized = true;
  }

  @SlowPath
  public SSymbol symbolFor(final String string) {
    String interned = string.intern();
    // Lookup the symbol in the symbol table
    SSymbol result = symbolTable.get(interned);
    if (result != null) { return result; }

    return newSymbol(interned);
  }

  public SBlock newBlock(final SMethod method, final MaterializedFrame context,
      final boolean capturedEnforced) {
    return SBlock.create(method, context, capturedEnforced);
  }

  @SlowPath
  public SClass newClass(final SClass classClass, final SObject domain) {
    // Allocate a new class and set its class to be the given class class
    return new SClass(domain, classClass, this);
  }

  @SlowPath
  public SInvokable newMethod(final SSymbol signature,
      final AbstractInvokable truffleInvokable, final boolean isPrimitive,
      final SMethod[] embeddedBlocks) {
    if (isPrimitive) {
      return new SPrimitive(signature, truffleInvokable);
    } else {
      return new SMethod(signature, truffleInvokable, embeddedBlocks);
    }
  }

  public SObject newInstance(final SClass instanceClass, final SObject domain) {
    return SObject.create(nilObject, domain, instanceClass);
  }

  @SlowPath
  public SClass newMetaclassClass(final SObject domain) {
    // Allocate the metaclass classes
    SClass result = new SClass(domain, 0, this);
    result.setClass(new SClass(domain, 0, this), nilObject);

    // Setup the metaclass hierarchy
    result.getSOMClass(this).setClass(result, nilObject);
    return result;
  }

  private SSymbol newSymbol(final String string) {
    // Allocate a new symbol and set its class to be the symbol class
    SSymbol result = new SSymbol(string);

    // Insert the new symbol into the symbol table
    symbolTable.put(string, result);

    // Return the freshly allocated symbol
    return result;
  }

  public SClass newSystemClass(final SObject domain) {
    return newSystemClass(domain, 0);
  }

  @SlowPath
  public SClass newSystemClass(final SObject domain, final int numberOfFields) {
    // Allocate the new system class
    SClass systemClass = new SClass(domain, numberOfFields, this);

    // Setup the metaclass hierarchy
    systemClass.setClass(new SClass(domain, numberOfFields, this), nilObject);
    systemClass.getSOMClass(this).setClass(metaclassClass, nilObject);

    // Return the freshly allocated system class
    return systemClass;
  }

  @SlowPath
  public void initializeSystemClass(final SClass systemClass, final SClass superClass,
      final String name) {
    // Initialize the superclass hierarchy
    if (superClass != null) {
      systemClass.setSuperClass(superClass);
      systemClass.getSOMClass(this).setSuperClass(superClass.getSOMClass(this));
    } else {
      systemClass.getSOMClass(this).setSuperClass(classClass);
    }

    // Initialize the array of instance fields
    systemClass.setInstanceFields(new SSymbol[0]);
    systemClass.getSOMClass(this).setInstanceFields(new SSymbol[0]);

    // Initialize the array of instance invokables
    systemClass.setInstanceInvokables(new SInvokable[0]);
    systemClass.getSOMClass(this).setInstanceInvokables(new SInvokable[0]);

    // Initialize the name of the system class
    systemClass.setName(symbolFor(name));
    systemClass.getSOMClass(this).setName(symbolFor(name + " class"));

    // Insert the system class into the dictionary of globals
    setGlobal(systemClass.getName(), systemClass);
  }

  @SlowPath
  public Object getGlobal(final SSymbol name) {
    Association assoc = globals.get(name);
    if (assoc == null) {
      return null;
    }
    return assoc.getValue();
  }

  @SlowPath
  public Association getGlobalsAssociation(final SSymbol name) {
    return globals.get(name);
  }

  @SlowPath
  public void setGlobal(final SSymbol name, final Object value) {
    Association assoc = globals.get(name);
    if (assoc == null) {
      assoc = new Association(name, value);
      globals.put(name, assoc);
    } else {
      assoc.setValue(value);
    }
  }

  public SClass getBlockClass(final int numberOfArguments) {
    SClass result = blockClasses[numberOfArguments];

    // the base class Block (i.e., without #value method is loaded explicitly
    if (result != null || numberOfArguments == 0) {
      return result;
    }

    // Compute the name of the block class with the given number of
    // arguments
    SSymbol name = symbolFor("Block" + numberOfArguments);

    // Lookup the specific block class in the dictionary of globals and
    // return it
    result = (SClass) getGlobal(name);

    if (result != null) {
      blockClasses[numberOfArguments] = result;
      return result;
    }

    // Get the block class for blocks with the given number of arguments
    result = loadClass(name, null);

    // Add the appropriate value primitive to the block class
    result.addInstancePrimitive(SBlock.getEvaluationPrimitive(numberOfArguments,
        this, result));

    // Insert the block class into the dictionary of globals
    setGlobal(name, result);

    blockClasses[numberOfArguments] = result;
    return result;
  }

  @SlowPath
  public SClass loadClass(final SSymbol name) {
    // Check if the requested class is already in the dictionary of globals
    SClass result = (SClass) getGlobal(name);
    if (result != null) { return result; }

    // Load the class
    result = loadClass(name, null);

    // Load primitives (if necessary) and return the resulting class
    if (result != null && result.hasPrimitives()) {
      result.loadPrimitives();
    }

    setGlobal(name, result);

    return result;
  }

  @SlowPath
  public void loadSystemClass(final SClass systemClass) {
    // Load the system class
    SClass result = loadClass(systemClass.getName(), systemClass);

    if (result == null) {
      throw new IllegalStateException(systemClass.getName().getString()
          + " class could not be loaded. "
          + "It is likely that the class path has not been initialized properly. "
          + "Please set system property 'system.class.path' or "
          + "pass the '-cp' command-line parameter.");
    }

    // Load primitives if necessary
    if (result.hasPrimitives()) { result.loadPrimitives(); }
  }

  @SlowPath
  public SClass loadClass(final SSymbol name, final SClass systemClass) {
    // Try loading the class from all different paths
    for (String cpEntry : classPath) {
      try {
        // Load the class from a file and return the loaded class
        SClass result = som.compiler.SourcecodeCompiler.compileClass(cpEntry,
            name.getString(), systemClass, this);
        if (printAST) {
          Disassembler.dump(result.getSOMClass(this));
          Disassembler.dump(result);
        }
        return result;

      } catch (IOException e) {
        // Continue trying different paths
      }
    }

    // The class could not be found.
    return null;
  }

  @SlowPath
  public SClass loadShellClass(final String stmt) throws IOException {
    // java.io.ByteArrayInputStream in = new
    // java.io.ByteArrayInputStream(stmt.getBytes());

    // Load the class from a stream and return the loaded class
    SClass result = som.compiler.SourcecodeCompiler.compileClass(stmt, null,
        this);
    if (printAST) { Disassembler.dump(result); }
    return result;
  }

  @SlowPath
  public static void errorPrint(final String msg) {
    // Checkstyle: stop
    System.err.print(msg);
    // Checkstyle: resume
  }

  @SlowPath
  public static void errorPrintln(final String msg) {
    // Checkstyle: stop
    System.err.println(msg);
    // Checkstyle: resume
  }

  @SlowPath
  public static void errorPrintln() {
    // Checkstyle: stop
    System.err.println();
    // Checkstyle: resume
  }

  @SlowPath
  public static void print(final String msg) {
    // Checkstyle: stop
    System.err.print(msg);
    // Checkstyle: resume
  }

  @SlowPath
  public static void println(final String msg) {
    // Checkstyle: stop
    System.err.println(msg);
    // Checkstyle: resume
  }

  @SlowPath
  public static void println() {
    // Checkstyle: stop
    System.err.println();
    // Checkstyle: resume
  }

  @CompilationFinal public SObject              nilObject;
  @CompilationFinal public SObject              trueObject;
  @CompilationFinal public SObject              falseObject;
  @CompilationFinal public SObject              systemObject;

  @CompilationFinal public SClass               objectClass;
  @CompilationFinal public SClass               classClass;
  @CompilationFinal public SClass               metaclassClass;

  @CompilationFinal public SClass               nilClass;
  @CompilationFinal public SClass               integerClass;
  @CompilationFinal public SClass               arrayClass;
  @CompilationFinal public SClass               methodClass;
  @CompilationFinal public SClass               symbolClass;
  @CompilationFinal public SClass               primitiveClass;
  @CompilationFinal public SClass               stringClass;
  @CompilationFinal public SClass               systemClass;
  @CompilationFinal public SClass               doubleClass;

  @CompilationFinal public SClass               trueClass;
  @CompilationFinal public SClass               falseClass;

  @CompilationFinal public SClass               domainClass;
  @CompilationFinal public SObject              standardDomain;


  private final HashMap<SSymbol, Association>   globals;

  private String[]                              classPath;
  @CompilationFinal private boolean             printAST;

  private final TruffleRuntime                  truffleRuntime;

  private final HashMap<String, SSymbol>        symbolTable;

  // TODO: this is not how it is supposed to be... it is just a hack to cope
  //       with the use of system.exit in SOM to enable testing
  private final boolean                         avoidExit;
  private int                                   lastExitCode;

  // Optimizations
  private final SClass[] blockClasses;

  // Latest instance
  // WARNING: this is problematic with multiple interpreters in the same VM...
  @CompilationFinal private static Universe current;

  @CompilationFinal private boolean objectSystemInitialized = false;

  public boolean isObjectSystemInitialized() {
    return objectSystemInitialized;
  }

  public static Universe current() {
    return current;
  }
}
