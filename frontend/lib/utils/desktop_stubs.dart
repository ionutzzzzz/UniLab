// Mock/Stub classes for desktop-only features on Web
import 'dart:async';

class WindowController {
  final int windowId;
  WindowController(this.windowId);
  
  static Future<WindowController> fromCurrentEngine() async => WindowController(0);
  static Future<WindowController> create(dynamic config) async => WindowController(0);
  static WindowController fromWindowId(String id) => WindowController(0);
  static Future<List<WindowController>> getAll() async => [];
  
  String get arguments => '';
  Future<void> show() async {}
  Future<void> hide() async {}
  Future<void> close() async {}
  Future<dynamic> invokeMethod(String method, [dynamic arguments]) async => null;
}

class WindowConfiguration {
  const WindowConfiguration({dynamic arguments, bool hiddenAtLaunch = false});
}

class WindowMethodChannel {
  final String name;
  WindowMethodChannel(this.name);
  void setMethodCallHandler(Future<dynamic> Function(dynamic call)? handler) {}
  Future<T?> invokeMethod<T>(String method, [dynamic arguments]) async => null;
}

final Stream<void> onWindowsChanged = const Stream.empty();
