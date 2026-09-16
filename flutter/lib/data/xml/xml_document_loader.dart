import 'dart:io';

import 'package:xml/xml.dart';

import 'xml_file_io.dart';

class XmlDocumentLoader {
  static XmlDocument loadFromFile(String path) => XmlFileIo.loadDocument(path);

  static void saveToFile(XmlDocument document, String path, {bool indent = true}) {
    final file = File(path);
    file.parent.createSync(recursive: true);
    if (indent) {
      file.writeAsStringSync(document.toXmlString(pretty: true, indent: '    '));
    } else {
      file.writeAsStringSync(document.toXmlString());
    }
  }
}
