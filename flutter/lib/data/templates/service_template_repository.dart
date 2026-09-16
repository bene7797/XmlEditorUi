import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../../data/xml/xml_file_io.dart';
import '../../data/xml/xml_path.dart';
import '../../domain/templates/main_template_variants.dart';

class TemplateDocumentSession {
  TemplateDocumentSession(this.path, this.document);

  final String path;
  final XmlDocument document;

  XmlElement get service => document.rootElement;

  void save() {
    File(path).writeAsStringSync(
      document.toXmlString(pretty: true, indent: '    '),
    );
  }
}

class ServiceTemplateRepository {
  ServiceTemplateRepository(this.servicesTemplateFolder) {
    Directory(servicesTemplateFolder).createSync(recursive: true);
    _ensureExternenpruefungTemplate();
  }

  final String servicesTemplateFolder;

  static bool isMainTemplateFile(String filePath) {
    final name = p.basename(filePath);
    return name.toLowerCase() ==
            MainTemplateVariants.standardFileName.toLowerCase() ||
        name.toLowerCase() == MainTemplateVariants.externFileName.toLowerCase();
  }

  static bool isExternenpruefungTemplateFile(String filePath) =>
      p.basename(filePath).toLowerCase().contains('extern');

  List<String> getTemplateFiles() => Directory(servicesTemplateFolder)
      .listSync()
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.xml'))
      .map((f) => f.path)
      .toList();

  XmlDocument loadTemplateDocument(String path) =>
      XmlFileIo.loadDocument(path);

  String? findMainTemplatePath({bool externenpruefung = false}) {
    final preferred = externenpruefung
        ? MainTemplateVariants.externFileName
        : MainTemplateVariants.standardFileName;
    final files = getTemplateFiles();
    for (final f in files) {
      if (p.basename(f).toLowerCase() == preferred.toLowerCase()) return f;
    }
    for (final f in files) {
      if (p.basename(f).toLowerCase() ==
          MainTemplateVariants.standardFileName.toLowerCase()) {
        return f;
      }
    }
    return files.isEmpty ? null : files.first;
  }

  TemplateDocumentSession? findTemplateByFileNameContains(String text) {
    for (final file in getTemplateFiles()) {
      final name = p.basenameWithoutExtension(file);
      if (name.toLowerCase().contains(text.toLowerCase()) &&
          !isMainTemplateFile(file) &&
          !isExternenpruefungTemplateFile(file)) {
        return TemplateDocumentSession(file, loadTemplateDocument(file));
      }
    }
    return null;
  }

  TemplateDocumentSession? findTemplateByCity(String cityName) {
    for (final file in getTemplateFiles()) {
      final session =
          TemplateDocumentSession(file, loadTemplateDocument(file));
      final city = XmlPath.getTextByPath(
        session.service,
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/CITY',
      );
      if (city != null &&
          city.toLowerCase() == cityName.toLowerCase()) {
        return session;
      }
    }
    return findTemplateByFileNameContains(cityName);
  }

  TemplateDocumentSession? loadMainTemplateSession([
    String variant = MainTemplateVariants.standard,
  ]) {
    final path = findMainTemplatePath(
      externenpruefung: MainTemplateVariants.isExternenpruefung(variant),
    );
    if (path == null) return null;
    return TemplateDocumentSession(path, loadTemplateDocument(path));
  }

  List<String> getDistinctCourseTypeNames() {
    final names = <String>{};
    for (final file in getTemplateFiles()) {
      if (isMainTemplateFile(file) || isExternenpruefungTemplateFile(file)) {
        continue;
      }
      final fileName = p.basenameWithoutExtension(file);
      if (fileName.toLowerCase().contains('vollzeit')) {
        names.add('Vollzeit');
      } else if (fileName.toLowerCase().contains('teilzeit')) {
        names.add('Teilzeit');
      }
    }
    final list = names.toList()..sort();
    return list;
  }

  List<String> getDistinctLocationNames() {
    final names = <String>{};
    for (final file in getTemplateFiles()) {
      final doc = loadTemplateDocument(file);
      final city = XmlPath.getTextByPath(
            doc.rootElement,
            'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/CITY',
          ) ??
          '';
      if (city.trim().isNotEmpty &&
          city.toLowerCase() != 'ort ?') {
        names.add(city);
      }
    }
    final list = names.toList()..sort();
    return list;
  }

  void _ensureExternenpruefungTemplate() {
    final targetPath =
        p.join(servicesTemplateFolder, MainTemplateVariants.externFileName);
    if (File(targetPath).existsSync()) return;

    final mainPath =
        p.join(servicesTemplateFolder, MainTemplateVariants.standardFileName);
    final sourcePath =
        p.join(servicesTemplateFolder, 'Externenprüfung Kassel.xml');
    if (!File(mainPath).existsSync() || !File(sourcePath).existsSync()) {
      return;
    }

    final mainDoc = loadTemplateDocument(mainPath);
    final sourceDoc = loadTemplateDocument(sourcePath);
    final mainService = mainDoc.rootElement;
    final sourceService = sourceDoc.rootElement;

    final toRemove = mainService.childElements
        .where((c) => c.name.local.toLowerCase() != 'header')
        .toList();
    for (final child in toRemove) {
      mainService.children.remove(child);
    }

    for (final child in sourceService.childElements) {
      mainService.children.add(child.copy());
    }

    File(targetPath).writeAsStringSync(
      mainDoc.toXmlString(pretty: true, indent: '    '),
    );
  }
}
