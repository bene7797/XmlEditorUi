import 'package:xml/xml.dart';

import '../../data/xml/xml_file_io.dart';
import '../../data/xml/xml_path.dart';
import '../catalog/models.dart';
import '../fields/template_field_mapping.dart';

class TemplateConfigurator {
  XmlDocument? _currentTemplate;

  void loadMainTemplate(String templatePath) {
    _currentTemplate = XmlFileIo.loadDocument(templatePath);
  }

  void loadMainTemplateDocument(XmlDocument document) {
    _currentTemplate = document;
  }

  void applyLocationConfiguration(LocationProfile location) {
    _ensureLoaded();
    applyLocationToService(_currentTemplate!.rootElement, location);
  }

  void applyCourseTypeConfiguration(CourseTypeProfile courseType) {
    _ensureLoaded();
    applyCourseTypeToService(_currentTemplate!.rootElement, courseType);
  }

  static void applyLocationToService(
    XmlElement service,
    LocationProfile location,
  ) {
    if (!location.values.containsKey('ZIPBOX')) {
      final zip = location.values['ZIP'];
      if (zip != null && zip.trim().isNotEmpty) {
        location.values['ZIPBOX'] = zip;
      }
    }
    _applyFieldMappings(
      service,
      TemplateFieldMapping.locationFieldPaths,
      location.values,
    );
  }

  static void applyCourseTypeToService(
    XmlElement service,
    CourseTypeProfile courseType,
  ) {
    for (final mapping in TemplateFieldMapping.courseTypeFieldPaths.entries) {
      final value = courseType.values[mapping.key];
      if (value == null) continue;
      XmlPath.setNodeByPath(service, mapping.value, value);
      final attrValue = courseType.attributes['${mapping.key}@type'];
      if (attrValue != null) {
        XmlPath.setNodeByPath(service, '${mapping.value}@type', attrValue);
      }
    }
    for (final mapping
        in TemplateFieldMapping.courseTypeFieldAttributes.entries) {
      final attrValue = courseType.attributes[mapping.key];
      if (attrValue != null) {
        XmlPath.setNodeByPath(service, mapping.value, attrValue);
      }
    }
  }

  XmlDocument getConfiguredTemplate() {
    _ensureLoaded();
    return _currentTemplate!;
  }

  static void _applyFieldMappings(
    XmlElement service,
    Map<String, String> mappings,
    Map<String, String> values,
  ) {
    for (final mapping in mappings.entries) {
      final value = values[mapping.key];
      if (value != null) {
        XmlPath.setNodeByPath(service, mapping.value, value);
      }
    }
  }

  void _ensureLoaded() {
    if (_currentTemplate?.rootElement == null) {
      throw StateError('Kein Template geladen. LoadMainTemplate() aufrufen.');
    }
  }
}
