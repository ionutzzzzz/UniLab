// Mock/Stub for dart:ffi on Web
class Int32 {}
class Double {}
class Void {}
class Pointer<T> {
  int get address => 0;
  String toDartString() => '';
  T cast<T>() => throw UnimplementedError();
}
class Utf8 {}
class NativeFunction<T> {}
class DynamicLibrary {
  static DynamicLibrary open(String path) => DynamicLibrary();
  T lookupFunction<T, U>(String symbol) => throw UnimplementedError();
}
class NativeCallable<T> {
  static NativeCallable<T> listener<T>(dynamic fn) => throw UnimplementedError();
  dynamic get nativeFunction => null;
}
final malloc = Malloc();
class Malloc {
  Pointer<T> call<T>(int count) => Pointer<T>();
  void free(Pointer ptr) {}
}
extension StringToUtf8 on String {
  Pointer<Utf8> toNativeUtf8() => Pointer<Utf8>();
}
