package som.vm;

import som.vmobjects.SObject;


public final class Nil {
  public static final SObject nilObject;

  static {
    nilObject = SObject.create(null, 0);
  }
}
