import 'dart:ffi';
import 'package:ffi/ffi.dart';

// FFI function type definitions
typedef UniLabInitNative = Int32 Function(Pointer<Utf8> backendPath);
typedef UniLabInit = int Function(Pointer<Utf8> backendPath);

typedef UniLabCreateSessionNative = Pointer<Utf8> Function(Pointer<Utf8> username);
typedef UniLabCreateSession = Pointer<Utf8> Function(Pointer<Utf8> username);

typedef UniLabExecuteNative = Pointer<Utf8> Function(Pointer<Utf8> sessionId, Pointer<Utf8> code);
typedef UniLabExecute = Pointer<Utf8> Function(Pointer<Utf8> sessionId, Pointer<Utf8> code);

typedef UniLabGetWorkspaceNative = Pointer<Utf8> Function(Pointer<Utf8> sessionId);
typedef UniLabGetWorkspace = Pointer<Utf8> Function(Pointer<Utf8> sessionId);

typedef UniLabGetAutocompleteNative = Pointer<Utf8> Function(Pointer<Utf8> sessionId, Pointer<Utf8> text);
typedef UniLabGetAutocomplete = Pointer<Utf8> Function(Pointer<Utf8> sessionId, Pointer<Utf8> text);

typedef UniLabListFilesNative = Pointer<Utf8> Function(Pointer<Utf8> sessionId);
typedef UniLabListFiles = Pointer<Utf8> Function(Pointer<Utf8> sessionId);

typedef UniLabCreateFileNative = Pointer<Utf8> Function(
  Pointer<Utf8> sessionId,
  Pointer<Utf8> filename,
  Pointer<Utf8> content,
);
typedef UniLabCreateFile = Pointer<Utf8> Function(
  Pointer<Utf8> sessionId,
  Pointer<Utf8> filename,
  Pointer<Utf8> content,
);

typedef UniLabFreeStringNative = Void Function(Pointer<Utf8> ptr);
typedef UniLabFreeString = void Function(Pointer<Utf8> ptr);
