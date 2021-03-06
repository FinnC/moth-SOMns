package tools.concurrency;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.lang.management.GarbageCollectorMXBean;
import java.lang.management.ManagementFactory;
import java.lang.management.MemoryPoolMXBean;
import java.lang.management.MemoryType;
import java.lang.management.MemoryUsage;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.LockSupport;

import javax.management.Notification;
import javax.management.NotificationEmitter;
import javax.management.NotificationListener;
import javax.management.openmbean.CompositeData;

import com.oracle.truffle.api.CompilerDirectives;
import com.oracle.truffle.api.CompilerDirectives.TruffleBoundary;
import com.sun.management.GarbageCollectionNotificationInfo;

import som.Output;
import som.interpreter.actors.Actor.ActorProcessingThread;
import som.vm.VmSettings;
import som.vm.constants.Classes;
import som.vm.constants.Nil;
import som.vmobjects.SArray;
import som.vmobjects.SArray.SImmutableArray;
import som.vmobjects.SSymbol;
import tools.debugger.FrontendConnector;
import tools.replay.StringWrapper;
import tools.replay.TwoDArrayWrapper;
import tools.replay.actors.ActorExecutionTrace;


/**
 * Tracing of the execution is done on a per-thread basis to minimize overhead
 * at run-time.
 *
 * <p>
 * To communicate detailed information about the system for debugging,
 * TraceWorkerThreads will capture the available data periodically and send it
 * to the debugger.
 *
 * <h4>Synchronization Strategy</h4>
 *
 * <p>
 * During normal execution with tracing, we do not need any synchronization,
 * because all operations on the buffers are initiated by the
 * TracingActivityThreads themselves. Thus, everything is thread-local. The
 * swapping of buffers is initiated from the TracingActivityThreads, too.
 * It requires synchronization only on the data structure where the buffers
 * are listed.
 *
 * <p>
 * During execution with the debugger however, the periodic data requests
 * cause higher synchronization requirements. Since this is about interactive
 * debugging the cost of synchronization is likely acceptable, and will simply
 * done on the buffer for all access.
 */
public class TracingBackend {
  private static final int BUFFER_POOL_SIZE =
      VmSettings.NUM_THREADS * VmSettings.BUFFERS_PER_THREAD;

  private static final int TRACE_TIMEOUT = 500;

  private static final List<GarbageCollectorMXBean> gcbeans =
      ManagementFactory.getGarbageCollectorMXBeans();

  private static final ArrayBlockingQueue<byte[]> emptyBuffers =
      new ArrayBlockingQueue<>(BUFFER_POOL_SIZE);

  // contains symbols that need to be written to file/sent to debugger,
  // e.g. actor type, message type
  private static final ArrayList<SSymbol> symbolsToWrite =
      new ArrayList<>();

  private static FrontendConnector front = null;

  private static long              collectedMemory = 0;
  /**
   * Used for writing the traces in normal actor Tracing.
   * When snapshoting, this points to the worker responsible for the trace
   * associated with the current snapshot.
   */
  private static TraceWorkerThread currentWorkerThread;
  /**
   * When snapshoting, this points to the worker that handles remaining
   * trace data belonging to the previous snapshot.
   */
  private static TraceWorkerThread previousWorkerThread;

  static {
    if (VmSettings.MEMORY_TRACING) {
      setUpGCMonitoring();
    }

    if (VmSettings.RECYCLE_BUFFERS
        && (VmSettings.ACTOR_TRACING || VmSettings.KOMPOS_TRACING)) {
      for (int i = 0; i < BUFFER_POOL_SIZE; i++) {
        emptyBuffers.add(new byte[VmSettings.BUFFER_SIZE]);
      }
    }
  }

  private static long getTotal(final Map<String, MemoryUsage> map) {
    return map.entrySet().stream().mapToLong(usage -> usage.getValue().getUsed()).sum();
  }

  public static void setUpGCMonitoring() {
    for (GarbageCollectorMXBean bean : gcbeans) {
      NotificationEmitter emitter = (NotificationEmitter) bean;
      NotificationListener listener = new NotificationListener() {
        @Override
        public void handleNotification(final Notification notification,
            final Object handback) {
          if (GarbageCollectionNotificationInfo.GARBAGE_COLLECTION_NOTIFICATION.equals(
              notification.getType())) {
            GarbageCollectionNotificationInfo info = GarbageCollectionNotificationInfo.from(
                (CompositeData) notification.getUserData());
            long after = getTotal(info.getGcInfo().getMemoryUsageAfterGc());
            long before = getTotal(info.getGcInfo().getMemoryUsageBeforeGc());
            collectedMemory += before - after;
          }
        }
      };
      emitter.addNotificationListener(listener, null, null);
    }
  }

  public static void reportPeakMemoryUsage() {
    List<MemoryPoolMXBean> pools = ManagementFactory.getMemoryPoolMXBeans();
    long totalHeap = 0;
    long totalNonHeap = 0;
    long gcTime = 0;
    for (MemoryPoolMXBean memoryPoolMXBean : pools) {
      long peakUsed = memoryPoolMXBean.getPeakUsage().getUsed();
      if (memoryPoolMXBean.getType() == MemoryType.HEAP) {
        totalHeap += peakUsed;
      } else if (memoryPoolMXBean.getType() == MemoryType.NON_HEAP) {
        totalNonHeap += peakUsed;
      }
    }
    for (GarbageCollectorMXBean garbageCollectorMXBean : ManagementFactory.getGarbageCollectorMXBeans()) {
      gcTime += garbageCollectorMXBean.getCollectionTime();
    }
    Output.println("[Memstat] Heap: " + totalHeap + "B\tNonHeap: " + totalNonHeap
        + "B\tCollected: " + collectedMemory + "B\tGC-Time: " + gcTime + "ms");
  }

  @TruffleBoundary
  public static byte[] getEmptyBuffer() {
    if (VmSettings.RECYCLE_BUFFERS) {
      try {
        return emptyBuffers.take();
      } catch (InterruptedException e) {
        CompilerDirectives.transferToInterpreter();
        throw new IllegalStateException("Failed to acquire a new Buffer!");
      }
    } else {
      return new byte[VmSettings.BUFFER_SIZE];
    }
  }

  static void returnBuffer(final byte[] buffer, final int pos) {
    if (buffer == null) {
      return;
    }

    returnBufferGlobally(new BufferAndLimit(buffer, pos));
  }

  static void returnBuffer(final byte[] buffer, final int pos, final byte snapshotVersion) {
    if (buffer == null) {
      return;
    }

    returnBufferGlobally(snapshotVersion,
        new BufferAndLimit(buffer, pos));
  }

  private static final class BufferAndLimit {
    final byte[] buffer;
    final int    limit;

    BufferAndLimit(final byte[] buffer, final int limit) {
      this.buffer = buffer;
      this.limit = limit;
    }

    public ByteBuffer getReadingFromStartBuffer() {
      return ByteBuffer.wrap(buffer, 0, limit);
    }
  }

  @TruffleBoundary
  private static void returnBufferGlobally(final BufferAndLimit buffer) {
    boolean inserted = currentWorkerThread.fullBuffers.offer(buffer);
    assert inserted;
  }

  @TruffleBoundary
  private static void returnBufferGlobally(final byte snapshotVersion,
      final BufferAndLimit buffer) {
    boolean inserted;
    if (snapshotVersion == currentWorkerThread.snapshotVersion) {
      inserted = currentWorkerThread.fullBuffers.offer(buffer);
    } else {
      inserted = previousWorkerThread.fullBuffers.offer(buffer);
    }
    assert inserted;
  }

  private static HashSet<TracingActivityThread> tracingThreads = new HashSet<>();

  public static void registerThread(final TracingActivityThread t) {
    synchronized (tracingThreads) {
      boolean added = tracingThreads.add(t);
      assert added;
    }
  }

  public static void unregisterThread(final TracingActivityThread t) {
    synchronized (tracingThreads) {
      boolean removed = tracingThreads.remove(t);
      assert removed;
      t.swapTracingBuffer = false;
    }
  }

  public static final void forceSwapBuffers() {
    assert VmSettings.ACTOR_TRACING
        || (VmSettings.TRUFFLE_DEBUGGER_ENABLED && VmSettings.KOMPOS_TRACING);
    TracingActivityThread[] result;
    synchronized (tracingThreads) {
      result = tracingThreads.toArray(new TracingActivityThread[0]);
    }

    // XXX: This is only safe because we assume that threads do not disappear
    // XXX: correction, I think this is all inherently racy, but hopefully good enough

    // signal threads to swap buffers
    for (TracingActivityThread t : result) {
      t.swapTracingBuffer = true;
    }

    int runningThreads = result.length;
    while (runningThreads > 1) {
      for (int i = 0; i < result.length; i += 1) {
        TracingActivityThread t = result[i];
        if (t == null) {
          continue;
        }

        if (!t.swapTracingBuffer) { // indicating that it was swapped
          runningThreads -= 1;
          result[i] = null;
        } else if (t instanceof ActorProcessingThread
            && (((ActorProcessingThread) t).getCurrentActor() == null)) {
          // if the thread is not currently having an actor, it is not executing
          runningThreads -= 1;
          result[i] = null;
          t.getBuffer().swapStorage();
        } else if (t.swapTracingBufferIfThreadSuspendedInDebugger()) {
          runningThreads -= 1;
          result[i] = null;
        } else if (isBlockedInJava(t)) {
          runningThreads -= 1;
          result[i] = null;
          t.getBuffer().swapStorage();
        }
      }
    }

    // forceSwap should only happen for kompos.
    // => only the first worker thread is used.
    while (!currentWorkerThread.fullBuffers.isEmpty()) {
      // wait until the worker thread processed all the buffers
      try {
        Thread.sleep(1);
      } catch (InterruptedException e) {
        throw new RuntimeException(e);
      }
    }
  }

  private static boolean isBlockedInJava(final Thread t) {
    Object blocker = LockSupport.getBlocker(t);
    return blocker != null;
  }

  public static final long[] getStatistics() {
    if (currentWorkerThread == null) {
      return new long[] {0, 0};
    }

    long[] stats =
        new long[] {currentWorkerThread.traceBytes, currentWorkerThread.externalBytes};

    currentWorkerThread.traceBytes = 0;
    currentWorkerThread.externalBytes = 0;
    return stats;
  }

  @TruffleBoundary
  public static final void addExternalData(final Object[] b,
      final TracingActivityThread thread) {
    assert b != null;

    if (VmSettings.SNAPSHOTS_ENABLED) {
      if (thread.getSnapshotId() == currentWorkerThread.snapshotVersion) {
        currentWorkerThread.externalData.add(b);
      } else {
        previousWorkerThread.externalData.add(b);
      }
    } else {
      currentWorkerThread.externalData.add(b);
    }
  }

  public static void startTracingBackend() {
    // start worker thread for trace processing
    currentWorkerThread = new TraceWorkerThread();
    currentWorkerThread.start();
  }

  /**
   * This Method notifies the TracingBackend that a new snapshot was triggered.
   * As a result we need to update the workers accordingly.
   */
  @TruffleBoundary
  public static void newSnapshot(final byte newSnapshotVersion) {
    TraceWorkerThread outDatedWorker;

    outDatedWorker = previousWorkerThread;
    previousWorkerThread = currentWorkerThread;
    currentWorkerThread = new TraceWorkerThread(newSnapshotVersion);
    currentWorkerThread.start();

    if (outDatedWorker != null) {
      // worker will terminate
      outDatedWorker.cont = false;
    }
  }

  /**
   * @param fc The FrontendConnector used to send data to the debugger.
   */
  public static void setFrontEnd(final FrontendConnector fc) {
    front = fc;
  }

  public static void logSymbol(final SSymbol symbol) {
    synchronized (symbolsToWrite) {
      symbolsToWrite.add(symbol);
    }
  }

  public static void waitForTrace() {
    if (currentWorkerThread != null) {
      currentWorkerThread.cont = false;
      try {
        currentWorkerThread.join(TRACE_TIMEOUT);
      } catch (InterruptedException e) {
        throw new RuntimeException(e);
      }
    }

    if (previousWorkerThread != null) {
      previousWorkerThread.cont = false;
      try {
        previousWorkerThread.join(TRACE_TIMEOUT);
      } catch (InterruptedException e) {
        throw new RuntimeException(e);
      }
    }
  }

  private static class TraceWorkerThread extends Thread {
    protected boolean cont = true;

    protected long traceBytes;
    protected long externalBytes;

    private final ArrayBlockingQueue<BufferAndLimit> fullBuffers  =
        new ArrayBlockingQueue<>(BUFFER_POOL_SIZE);
    private final ConcurrentLinkedQueue<Object[]>    externalData =
        new ConcurrentLinkedQueue<Object[]>();

    byte snapshotVersion;

    protected TraceWorkerThread(final byte snapshotVersion) {
      this.snapshotVersion = snapshotVersion;
    }

    protected TraceWorkerThread() {
      super("TraceWorkerThread");
    }

    private BufferAndLimit tryToObtainBuffer() {
      BufferAndLimit buffer;
      try {
        buffer =
            fullBuffers.poll(VmSettings.BUFFER_TIMEOUT, TimeUnit.MILLISECONDS);
        if (buffer == null) {
          return null;
        } else {
          return buffer;
        }
      } catch (InterruptedException e) {
        return null;
      }
    }

    private void writeExternalData(final FileOutputStream edfos) throws IOException {
      while (!externalData.isEmpty()) {
        Object[] external = externalData.poll();
        for (Object oo : external) {
          if (oo == null) {
            continue;
          }
          if (oo instanceof StringWrapper) {
            StringWrapper sw = (StringWrapper) oo;
            byte[] bytes = sw.s.getBytes();
            byte[] header =
                ActorExecutionTrace.getExtDataHeader(sw.actorId, sw.dataId, bytes.length);

            if (edfos != null) {
              edfos.getChannel().write(ByteBuffer.wrap(header));
              edfos.getChannel().write(ByteBuffer.wrap(bytes));
              edfos.flush();
            }
            externalBytes += bytes.length + 12;
          } else if (oo instanceof TwoDArrayWrapper) {
            writeArray((TwoDArrayWrapper) oo, edfos);
          } else {

            byte[] data = (byte[]) oo;
            externalBytes += data.length;
            if (edfos != null) {
              edfos.getChannel().write(ByteBuffer.wrap(data));
              edfos.flush();
            }
          }
        }
      }
    }

    private void writeArray(final TwoDArrayWrapper aw, final FileOutputStream edfos)
        throws IOException {
      SImmutableArray sia = aw.immArray;

      Object[] outer = sia.getObjectStorage();
      byte[][][] bouter = new byte[outer.length][][];
      byte[] endRow = {ENDROW};
      int numBytes = 0;
      for (int i = 0; i < outer.length; i++) {
        Object o = outer[i];
        SImmutableArray ia = (SImmutableArray) o;
        Object[] inner = ia.getObjectStorage();
        byte[][] binner = new byte[inner.length + 1][];
        for (int j = 0; j < inner.length; j++) {
          Object oo = inner[j];
          byte[] bytes = null;
          if (oo instanceof String) {
            byte[] sbytes = ((String) oo).getBytes();
            bytes = new byte[5 + sbytes.length];
            TraceBuffer.UNSAFE.putByte(bytes, TraceBuffer.BYTE_ARR_BASE_OFFSET, STRING);
            TraceBuffer.UNSAFE.putInt(bytes, TraceBuffer.BYTE_ARR_BASE_OFFSET + 1,
                sbytes.length);
            System.arraycopy(sbytes, 0, bytes, 5, sbytes.length);
          } else if (oo instanceof Long) {
            bytes = new byte[9];
            TraceBuffer.UNSAFE.putByte(bytes, TraceBuffer.BYTE_ARR_BASE_OFFSET, LONG);
            TraceBuffer.UNSAFE.putLong(bytes, TraceBuffer.BYTE_ARR_BASE_OFFSET + 1, (Long) oo);
          } else if (oo instanceof Double) {
            bytes = new byte[9];
            TraceBuffer.UNSAFE.putByte(bytes, TraceBuffer.BYTE_ARR_BASE_OFFSET, DOUBLE);
            TraceBuffer.UNSAFE.putDouble(bytes, TraceBuffer.BYTE_ARR_BASE_OFFSET + 1,
                (Double) oo);
          } else if (oo instanceof Boolean) {
            bytes = new byte[1];
            TraceBuffer.UNSAFE.putByte(bytes, TraceBuffer.BYTE_ARR_BASE_OFFSET + 1,
                ((Boolean) oo ? TRUE : FALSE));
          } else if (oo == Nil.nilObject) {
            bytes = new byte[1];
            TraceBuffer.UNSAFE.putByte(bytes, TraceBuffer.BYTE_ARR_BASE_OFFSET, NULL);
          } else {
            throw new UnsupportedOperationException("Unexpected DataType");
          }

          numBytes += bytes.length;
          binner[j] = bytes;
        }
        binner[binner.length - 1] = endRow;
        numBytes++;
        bouter[i] = binner;
      }

      byte[] header =
          ActorExecutionTrace.getExtDataHeader(aw.actorId, aw.dataId, numBytes);

      if (edfos != null) {
        edfos.getChannel().write(ByteBuffer.wrap(header));
        for (byte[][] baa : bouter) {
          for (byte[] ba : baa) {
            edfos.getChannel().write(ByteBuffer.wrap(ba));
          }
        }

        edfos.flush();
      }
      externalBytes += numBytes + 12;
    }

    private void writeSymbols(final BufferedWriter bw) throws IOException {
      synchronized (symbolsToWrite) {
        if (symbolsToWrite.isEmpty()) {
          return;
        }

        if (front != null) {
          front.sendSymbols(symbolsToWrite);
        }

        if (bw != null) {
          for (SSymbol s : symbolsToWrite) {
            bw.write(s.getSymbolId() + ":" + s.getString());
            bw.newLine();
          }
          bw.flush();
        }
        TracingBackend.symbolsToWrite.clear();
      }
    }

    private void writeAndRecycleBuffer(final FileOutputStream fos, final BufferAndLimit buffer)
        throws IOException {
      if (fos != null) {
        fos.getChannel().write(buffer.getReadingFromStartBuffer());
        fos.flush();
      }

      traceBytes += buffer.limit;
      if (VmSettings.RECYCLE_BUFFERS) {
        TracingBackend.emptyBuffers.add(buffer.buffer);
      }
    }

    private void processTraceData(final FileOutputStream traceDataStream,
        final FileOutputStream externalDataStream,
        final BufferedWriter symbolStream) throws IOException {
      while (cont || !fullBuffers.isEmpty() || !externalData.isEmpty()) {
        writeExternalData(externalDataStream);

        BufferAndLimit b = tryToObtainBuffer();
        if (b == null) {
          continue;
        }

        writeSymbols(symbolStream);
        if (front != null) {
          front.sendTracingData(b.getReadingFromStartBuffer());
        }

        writeAndRecycleBuffer(traceDataStream, b);
      }
    }

    @Override
    public void run() {
      String name =
          VmSettings.TRACE_FILE + (VmSettings.SNAPSHOTS_ENABLED ? "." + snapshotVersion : "");

      File f = new File(name + ".trace");
      File sf = new File(name + ".sym");
      File edf = new File(name + ".dat");
      f.getParentFile().mkdirs();

      try {
        if (VmSettings.DISABLE_TRACE_FILE) {
          processTraceData(null, null, null);
        } else {
          try (FileOutputStream traceDataStream = new FileOutputStream(f);
              FileOutputStream symbolStream = new FileOutputStream(sf);
              FileOutputStream externalDataStream = new FileOutputStream(edf);
              BufferedWriter symbolWriter =
                  new BufferedWriter(new OutputStreamWriter(symbolStream))) {
            processTraceData(traceDataStream, externalDataStream, symbolWriter);
          } catch (FileNotFoundException e) {
            throw new RuntimeException(e);
          }
        }
      } catch (IOException e) {
        throw new RuntimeException(e);
      }
    }
  }

  static final byte STRING = 0;
  static final byte LONG   = 1;
  static final byte DOUBLE = 2;
  static final byte TRUE   = 3;
  static final byte FALSE  = 4;
  static final byte NULL   = 5;
  static final byte ENDROW = 6;

  public static SArray parseArray(final ByteBuffer bb) {
    List<SArray> rows = new ArrayList<>();
    List<Object> currentRow = new ArrayList<>();

    while (bb.hasRemaining()) {
      byte type = bb.get();
      if (type == STRING) {
        int len = bb.getInt();
        byte[] bytes = new byte[len];
        bb.get(bytes);
        currentRow.add(new String(bytes));
      } else if (type == LONG) {
        currentRow.add(bb.getLong());
      } else if (type == DOUBLE) {
        currentRow.add(bb.getDouble());
      } else if (type == TRUE) {
        currentRow.add(true);
      } else if (type == FALSE) {
        currentRow.add(false);
      } else if (type == NULL) {
        currentRow.add(Nil.nilObject);
      } else if (type == ENDROW) {
        rows.add(new SImmutableArray(currentRow.toArray(), Classes.arrayClass));
        currentRow.clear();
      }
    }
    return new SImmutableArray(rows.toArray(), Classes.arrayClass);
  }
}
