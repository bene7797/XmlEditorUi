import 'dart:convert';
import 'dart:io';

import 'package:xml/xml.dart';

/// Reads OpenQCat XML files that may be UTF-8 or iso-8859-15 / latin1.
class XmlFileIo {
  XmlFileIo._();

  static String readText(String path) {
    final bytes = File(path).readAsBytesSync();

    // BOM UTF-8
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return utf8.decode(bytes.sublist(3));
    }

    try {
      return utf8.decode(bytes);
    } on FormatException {
      // OpenQCat exports use iso-8859-15; latin1 covers the common byte range.
      return latin1.decode(bytes);
    }
  }

  static XmlDocument loadDocument(String path) =>
      XmlDocument.parse(readText(path));
}
