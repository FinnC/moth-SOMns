# Repository and Code Layout

This section gives a brief overview over the most relevant elements of the
repository.

## Repository Root

```bash
.gitlab-ci.yml   # Configuration for the SOFT Build Server
.travis.yml      # Configuration for the Travis Build Service
CHANGELOG.md     # The changelog contains a high-level change overview
build.xml        # The Ant build description
codespeed.conf   # Benchmark configuration, based on ReBench
core-lib         # All SOMns code, including standard lib, tests, and benchmarks
docs             # Documentation
libs             # Libraries and dependencies of SOMns
som              # Launcher script
src              # Java sources
src_gen          # Java sources generated by the Truffle DSL
tests            # Java unit tests and tests for DynamicMetrics tool
tools            # Contains the Kompos Web Debugger
```

## Code Layout: Java

```bash
som
|- compiler          # Parser, AST creation, and source representation
|- instrumentation   # AST instrumentation support, used e.g. by DynamicMetrics tool
|- interop           # Interoperability with Truffle languages, only minimally implemented
|- interpreter       # Dynamic SOMns language semantics, i.e., interpreter and AST nodes
   |- nodes                           # AST and dispatch node implementations
   |- objectstorage                   # SOMns object model implementation
   |- actors, processes, transactions # core elements of concurrency models
|- primitives        # Basic operations, exposed via vmMirror object to SOMns
|- vm                # Basic VM setup, startup, and object system initialization
|- vmobjects         # Representation for build-in object and arrays
|- VM.java           # Java entry point and bridge between interpreter and tools

tools
|- debugger          # Connection to the Kompos Web Debugger
```

## Code Layout: Tests

```bash
tests
|- dym               # Tests for the DynamicMetrics tool
|- java              # JUnit tests for interpreter, including runner for BasicInterpreterTests
|- replay            # Tests for the deterministic replay feature
|- superinstructions # Tests for the super-instruction candidate detector
```

## Code Layout: SOMns

```bash
core-lib
|- Benchmarks       # Collection of various benchmarks
|- TestSuite        # Collection of tests
   |- BasicInterpreterTests  # Minimal tests only executable as JUnit tests
   |- Minitest.ns            # Newspeak's Minitest framework
   |- *Tests.ns              # Various test suites
|- Actors.ns                 # Actor and promise classes
|- Collections.ns            # Sets, Dictionaries, etc
|- Hello.ns                  # Hello World program
|- Kernel.ns                 # Core classes: Integer, Boolean, String, Array etc
|- Mirrors.ns                # Minimal and incomplete mirror API
|- Platform.ns               # Application loader
|- Processes.ns              # Communicating Sequential Processes classes
|- System.ns                 # Minimal API to access system functionality
|- Threading.ns              # Threading and fork/join-related classes
|- Transactions.ns           # Software transactional memory classes
```
