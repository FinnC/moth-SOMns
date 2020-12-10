Moth - A Grace on top of SOMns
==============================

Moth is an interpreter for [Grace](http://gracelang.org/) programs. It is built
on top of [SOMns](https://github.com/smarr/SOMns/) and while it achieves great
peak-performance we still have some way to go before realizing a fully
compliant Grace implementation.


Status
------

Active development of Moth is currently happening on the [moth-SOMns](https://github.com/gracelang/moth-SOMns) repo.

The latest runnable version is reflected by the `moth` branch [![Build Status](https://travis-ci.com/gracelang/moth-SOMns.svg?branch=moth)](https://travis-ci.com/github/gracelang/moth-SOMns).

Changes and releases are documented in our [CHANGELOG.md][cl].

Although we are working toward a fully compliant Grace implementation, Moth
doesn't yet implement all of Grace's features. Nonetheless, Moth's peak
performance is comparable to [V8](https://developers.google.com/v8/) for the
AWFY benchmarks; more information can be found in our
[paper](https://arxiv.org/abs/1807.00661).

Getting Started
---------------

Moth is built on:

- [SOMns](https://github.com/richard-roberts/SOMns) - which we adapted to provide Grace support,
- [Kernan](http://gracelang.org/applications/grace-versions/kernan/) - of which we use the parser written in C#, and
- [GraceLibrary](https://github.com/richard-roberts/GraceLibrary) - a collection of Grace programs, tests, and benchmarks designed to be used in Moth.

To successfully build Kernan, you will need to have the
[xbuild](http://www.mono-project.com/docs/tools+libraries/tools/xbuild/)
installed on your machine. The best way to obtain this is to downloaded the
latest release of the [mono](https://www.mono-project.com/download/stable/) (an
umbrella project focuses on bringing better cross-platform tooling and support
to Microsoft products).

To successfully build Moth, you will need to have Apache's
[ant](https://ant.apache.org/) command line tool (easily installed through most
package managers) and
[Java](http://www.oracle.com/technetwork/java/javase/downloads/index.html).

Building Moth
-------------

To build Moth, run our [build script](./build.xml) by invoking `ant` from
Moth's root directory. You will first see information about Kernan being built
and then SOMns (the [Grace library](./grace-lib) does not need to be compiled).
Once everything has been built successfully, you should see something like the
following output in your command line:

```sh
Buildfile: .../Moth/build.xml

compile-kernan:
    [echo] Compiling Kernan
    ...
    [exec] Build succeeded.
    [exec]      0 Warning(s)
    [exec]      0 Error(s)
    [exec]
    [exec] Time Elapsed 00:00:06.2428680

compile-somns:
     [echo] Compiling SOMns
     [echo]
     [echo]         ant.java.version: 10
     [echo]         java.version:     10.0.1
     [echo]         is.atLeastJava9:  true
     ...
     compile:
     [echo] Compiling Moth

BUILD SUCCESSFUL
Total time: 2 minutes 7 seconds
```

Provided both Kernan and Moth compiled as expected, you can now run Grace
programs using the [moth](./moth) executable:

```sh
./moth grace-lib/hello.grace
```

Note that the `moth` executable will first set the `MOTH_HOME` environment variable to Moth's root directory and then start Kernan in the background before running Moth. When Moth is finished, the executable will conclude by terminating Kernan.

Running Grace
-------------

To run a Grace program, invoke the [moth](./moth) executable from the command
line, along with the path to your program as the argument. For example,
executing `./moth grace-lib/hello.grace` runs the hello world program.

We maintain a small test suite, which can be executed via the [Test
Runner](./Tests/testRunner.grace) using `./moth -tc
GraceLibrary/Tests/testRunner.grace` (the `-tc` argument turns on dynamic
type-checking, which is required for some of the tests to pass).

Finally, you may also run Moth in benchmarking mode. To do this, execute the
[harness](./grace-lib/Benchmarks/harness.grace) along with a [Grace
benchmark](./grace-lib/Benchmarks) and the iteration numbers you want to use.
For example, executing:

```sh
./moth grace-lib/Benchmarks/harness.grace grace-lib/Benchmarks/List.grace 100 50
```

Academic Work
-------------

Related papers:

 - [Transient Typechecks are (Almost) Free](https://stefan-marr.de/downloads/ecoop19-roberts-et-al-transient-typechecks-are-almost-free.pdf),
   R. Roberts, S. Marr, M. Homer, J. Noble; ECOOP'19.

 - [Efficient and Deterministic Record & Replay for Actor Languages](https://stefan-marr.de/downloads/manlang18-aumayr-et-al-efficient-and-deterministic-record-and-replay-for-actor-languages.pdf),
   D. Aumayr, S. Marr, C. Béra, E. Gonzalez Boix, H. Mössenböck; ManLang'18.

 - [Newspeak and Truffle: A Platform for Grace?](https://stefan-marr.de/downloads/grace18-marr-et-al-newspeak-and-truffle-a-platform-for-grace.pdf),
   S. Marr, R. Roberts, J. Noble; Grace'18.

 - [Few Versatile vs. Many Specialized Collections: How to design a collection library for exploratory programming?](https://stefan-marr.de/papers/px-marr-daloze-few-versatile-vs-many-specialized-collections/) S. Marr, B. Daloze; Programming Experience Workshop, PX/18.

 - [A Concurrency-Agnostic Protocol for Multi-Paradigm Concurrent Debugging Tools](https://stefan-marr.de/papers/dls-marr-et-al-concurrency-agnostic-protocol-for-debugging/),
   S. Marr, C. Torres Lopez, D. Aumayr, E. Gonzalez Boix, H. Mössenböck; Dynamic Language Symposium'17.

 - [Kómpos: A Platform for Debugging Complex Concurrent Applications](https://stefan-marr.de/downloads/progdemo-marr-et-al-kompos-a-platform-for-debugging-complex-concurrent-applications.pdf),
   S. Marr, C. Torres Lopez, D. Aumayr, E. Gonzalez Boix, H. Mössenböck; Demonstration at the &lt;Programming&gt;'17 conference.

 - [Toward Virtual Machine Adaption Rather than Reimplementation: Adapting SOMns for Grace](https://stefan-marr.de/downloads/morevms17-roberts-et-al-toward-virtual-machine-adaption.pdf),
   R. Roberts, S. Marr, M. Homer, J. Noble;
   Presentation at the MoreVMs'17 workshop at the &lt;Programming&gt;'17 conference.

 - [Optimizing Communicating Event-Loop Languages with Truffle](https://stefan-marr.de/2015/10/optimizing-communicating-event-loop-languages-with-truffle/),
    S. Marr, H. Mössenböck; Presentation at the AGERE!’15 Workshop, co-located with SPLASH’15.

 - [Cross-Language Compiler Benchmarking: Are We Fast Yet?](https://stefan-marr.de/papers/dls-marr-et-al-cross-language-compiler-benchmarking-are-we-fast-yet/)
    S. Marr, B. Daloze, H. Mössenböck at the 12th Symposium on
    Dynamic Languages co-located with SPLASH'16.

 [SOM]: http://som-st.github.io/
 [TSOM]:https://github.com/SOM-st/TruffleSOM
 [SOAI]:http://lafo.ssw.uni-linz.ac.at/papers/2012_DLS_SelfOptimizingASTInterpreters.pdf
 [T]:   http://ssw.uni-linz.ac.at/Research/Projects/JVM/Truffle.html
 [spec]:http://bracha.org/newspeak-spec.pdf
 [AWFY]:https://github.com/smarr/are-we-fast-yet
 [RTD]: http://somns.readthedocs.io/en/dev/
 [vscode]: https://marketplace.visualstudio.com/items?itemName=MetaConcProject.SOMns
 [cl]:  https://github.com/smarr/SOMns/blob/dev/CHANGELOG.md
