import 'package:xml/xml.dart';

import '../../data/xml/xml_file_io.dart';
import '../../data/xml/xml_path.dart';
import '../catalog/models.dart';
import '../dates/date_field_rules.dart';
import '../fields/template_field_mapping.dart';

class TemplateConfigurator {
  XmlDocument? _currentTemplate;

  void loadMainTemplate(String templatePath) {
    _currentTemplate = XmlFileIo.loadDocument(templatePath);
  }

  void loadMainTemplateDocument(XmlDocument document) {
    _currentTemplate = document;
  }

  void applyLocationConfiguration(
    LocationProfile location, {
    XmlElement? locationSource,
  }) {
    _ensureLoaded();
    applyLocationToService(
      _currentTemplate!.rootElement,
      location,
      locationSource: locationSource,
    );
  }

  void applyCourseTypeConfiguration(
    CourseTypeProfile courseType, {
    XmlElement? courseTypeSource,
  }) {
    _ensureLoaded();
    applyCourseTypeToService(
      _currentTemplate!.rootElement,
      courseType,
      courseTypeSource: courseTypeSource,
    );
  }

  static void applyLocationToService(
    XmlElement service,
    LocationProfile location, {
    XmlElement? locationSource,
  }) {
    if (locationSource != null) {
      _overwriteSubtree(
        service,
        locationSource,
        TemplateFieldMapping.locationRoot,
      );
    }

    if (TemplateFieldMapping.lookupValue(location.values, 'ZIPBOX') == null) {
      final zip = TemplateFieldMapping.lookupValue(location.values, 'ZIP');
      if (zip != null && zip.trim().isNotEmpty) {
        location.values['ZIPBOX'] = zip;
      }
    }
    if (TemplateFieldMapping.lookupValue(location.values, 'COUNTRY') == null) {
      location.values.putIfAbsent('COUNTRY', () => 'DE');
    }

    _overwriteProfileValues(
      service,
      location.values,
      TemplateFieldMapping.pathForLocationKey,
    );
  }

  static void applyCourseTypeToService(
    XmlElement service,
    CourseTypeProfile courseType, {
    XmlElement? courseTypeSource,
  }) {
    if (courseTypeSource != null) {
      for (final path in TemplateFieldMapping.courseTypeFieldPaths.values) {
        _overwritePath(service, courseTypeSource, path);
      }
      for (final path in TemplateFieldMapping.courseTypeFieldAttributes.values) {
        _overwritePath(service, courseTypeSource, path);
      }
    }

    _overwriteProfileValues(
      service,
      courseType.values,
      TemplateFieldMapping.pathForCourseTypeKey,
    );
    for (final entry in courseType.attributes.entries) {
      final path = TemplateFieldMapping.courseTypeFieldAttributes[entry.key] ??
          '${TemplateFieldMapping.pathForCourseTypeKey(entry.key.split('@').first)}@type';
      XmlPath.setNodeByPath(service, path, entry.value);
    }
  }

  XmlDocument getConfiguredTemplate() {
    _ensureLoaded();
    return _currentTemplate!;
  }

  /// Angebot is abstract: no location, dates or instruction time.
  static void stripTerminFields(XmlElement service) {
    const extraPaths = [
      'SERVICE_DETAILS/SERVICE_DATE/DATE_REMARKS',
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/REGISTRATION_DATE',
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/INSTRUCTION_REMARKS',
    ];
    for (final path in [
      DateFieldRules.courseStartPath,
      DateFieldRules.courseEndPath,
      DateFieldRules.announcementStartPath,
      DateFieldRules.announcementEndPath,
      DateFieldRules.instructionTimePath,
      ...extraPaths,
    ]) {
      final node = XmlPath.getNodeByPath(service, path);
      if (node == null) continue;
      node.children.clear();
      node.removeAttribute('type');
    }

    final location = XmlPath.getNodeByPath(
      service,
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION',
    );
    location?.parent?.children.remove(location);
  }

  static void _overwriteProfileValues(
    XmlElement service,
    Map<String, String> values,
    String? Function(String key) pathForKey,
  ) {
    for (final entry in values.entries) {
      final path = pathForKey(entry.key);
      if (path == null || path.trim().isEmpty) continue;
      XmlPath.setNodeByPath(service, path, entry.value);
    }
  }

  static void _overwritePath(
    XmlElement target,
    XmlElement source,
    String path,
  ) {
    if (path.contains('@')) {
      final value = XmlPath.getTextByPath(source, path);
      if (value != null) {
        XmlPath.setNodeByPath(target, path, value);
      }
      return;
    }
    final sourceNode = XmlPath.getNodeByPath(source, path);
    if (sourceNode == null) return;
    if (XmlPath.hasElementChildren(sourceNode)) {
      _overwriteSubtree(target, source, path);
      return;
    }
    XmlPath.setNodeByPath(target, path, sourceNode.innerText);
    for (final attr in sourceNode.attributes) {
      XmlPath.setNodeByPath(target, '$path@${attr.name.local}', attr.value);
    }
  }

  static void _overwriteSubtree(
    XmlElement target,
    XmlElement source,
    String path,
  ) {
    final sourceNode = XmlPath.getNodeByPath(source, path);
    if (sourceNode == null) return;
    final targetNode = XmlPath.getNodeByPath(target, path);
    if (targetNode != null) {
      targetNode.replace(sourceNode.copy());
      return;
    }

    if (!path.contains('/')) {
      target.children.add(sourceNode.copy());
      return;
    }
    XmlPath.setNodeByPath(target, path, '');
    XmlPath.getNodeByPath(target, path)?.replace(sourceNode.copy());
  }

  void _ensureLoaded() {
    if (_currentTemplate?.rootElement == null) {
      throw StateError('Kein Template geladen. LoadMainTemplate() aufrufen.');
    }
  }
}
