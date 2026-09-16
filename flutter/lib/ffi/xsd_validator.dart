import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

typedef _ValidateNative = Int32 Function(
  Pointer<Utf16> xmlPath,
  Pointer<Utf16> schemaPath,
  Pointer<Utf16> errorBuffer,
  Int32 errorBufferLen,
);
typedef _ValidateDart = int Function(
  Pointer<Utf16> xmlPath,
  Pointer<Utf16> schemaPath,
  Pointer<Utf16> errorBuffer,
  int errorBufferLen,
);

/// FFI wrapper around xsd_validator.dll (C# NativeAOT).
class XsdValidator {
  XsdValidator(this.dllPath);

  final String dllPath;
  DynamicLibrary? _lib;
  _ValidateDart? _validate;

  void load() {
    if (!File(dllPath).existsSync()) {
      throw StateError(
        'XSD-Validator DLL nicht gefunden: $dllPath\n'
        'Bitte native/ mit NativeAOT bauen und xsd_validator.dll nach flutter/native/ kopieren.',
      );
    }
    _lib = DynamicLibrary.open(dllPath);
    _validate = _lib!
        .lookupFunction<_ValidateNative, _ValidateDart>('ValidateXml');
  }

  /// Returns null on success, otherwise the validation error message.
  String? validate(String xmlPath, String schemaPath) {
    _validate ??= () {
      load();
      return _validate!;
    }();

    final xmlPtr = xmlPath.toNativeUtf16();
    final schemaPtr = schemaPath.toNativeUtf16();
    final errorPtr = calloc<Uint16>(2048).cast<Utf16>();
    try {
      final code = _validate!(xmlPtr, schemaPtr, errorPtr, 2048);
      if (code == 0) return null;
      return errorPtr.toDartString();
    } finally {
      calloc.free(xmlPtr);
      calloc.free(schemaPtr);
      calloc.free(errorPtr);
    }
  }

  static String defaultDllPath(String nativeFolder) =>
      p.join(nativeFolder, 'xsd_validator.dll');
}
