// Mock/Stub classes for desktop-only features on Web
import 'dart:async';

enum ChannelMode { unidirectional, bidirectional }

class WindowController {
  final String windowId;
  final String arguments;

  WindowController({required this.windowId, this.arguments = ''});

  static Future<WindowController> fromCurrentEngine() async =>
      WindowController(windowId: '0');
  static Future<WindowController> create(WindowConfiguration config) async =>
      WindowController(windowId: '0', arguments: config.arguments);
  static WindowController fromWindowId(String id) =>
      WindowController(windowId: id);
  static Future<List<WindowController>> getAll() async => [];

  Future<void> show() async {}
  Future<void> hide() async {}
  Future<dynamic> invokeMethod(String method, [dynamic arguments]) async =>
      null;
  Future<void> setWindowMethodHandler(
    Future<dynamic> Function(dynamic call)? handler,
  ) async {}
}

class WindowConfiguration {
  final String arguments;
  final bool hiddenAtLaunch;

  const WindowConfiguration({
    this.arguments = '',
    this.hiddenAtLaunch = false,
  });
}

class WindowMethodChannel {
  final String name;
  final ChannelMode mode;

  const WindowMethodChannel(
    this.name, {
    this.mode = ChannelMode.bidirectional,
  });

  Future<void> setMethodCallHandler(
    Future<dynamic> Function(dynamic call)? handler,
  ) async {}

  Future<T?> invokeMethod<T>(String method, [dynamic arguments]) async => null;
}

final Stream<void> onWindowsChanged = const Stream.empty();
