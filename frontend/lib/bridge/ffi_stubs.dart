// Mock/Stub for dart:ffi on Web
class Int32 {}

class Double {}

class Void {}

class Pointer<T> {
  final int address;
  const Pointer([this.address = 0]);
  factory Pointer.fromAddress(int address) => Pointer<T>(address);
  String toDartString() => '';
  Pointer<R> cast<R>() => Pointer<R>(address);
}

final Pointer<Never> nullptr = const Pointer<Never>(0);

class Utf8 {}

class NativeFunction<T> {}

class DynamicLibrary {
  static DynamicLibrary open(String path) => DynamicLibrary();
  F lookupFunction<T, F>(String symbol, {bool isLeaf = false}) =>
      throw UnimplementedError();
}

class NativeCallable<T> {
  static NativeCallable<T> listener<T>(dynamic fn) =>
      throw UnimplementedError();
  Pointer<NativeFunction<T>> get nativeFunction =>
      Pointer<NativeFunction<T>>(0);
  void close() {}
}

final malloc = Malloc();

class Malloc {
  Pointer<T> call<T>(int count) => Pointer<T>();
  void free(Pointer ptr) {}
}

extension StringToUtf8 on String {
  Pointer<Utf8> toNativeUtf8() => const Pointer<Utf8>(0);
}
