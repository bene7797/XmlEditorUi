import 'package:xml/xml.dart';

import '../../data/xml/xml_path.dart';
import '../catalog/models.dart';
import 'field_labels.dart';
import 'important_fields.dart';
import 'template_field_definitions.dart';

class TemplateFieldCollector {
  static final Set<String> _excludedPaths = _buildExcludedPaths();

  static List<TemplateFieldDefinition> collectFromService(XmlElement service) {
    final paths = <String>{};
    _collectFields(service, '', paths);
    final sorted = paths.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sorted
        .map((p) => TemplateFieldDefinition(_formatLabel(p), p))
        .toList();
  }

  /// Filled leaf fields/attrs for the property-grid equivalent.
  static List<TemplateFieldDefinition> collectFilledFields(XmlElement service) {
    final paths = <String>{};
    _collectFilled(service, '', paths);
    final sorted = paths.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sorted
        .map((p) => TemplateFieldDefinition(_formatLabel(p), p))
        .toList();
  }

  static Set<String> _buildExcludedPaths() {
    final set = <String>{};
    for (final f in LocationTemplateFields.essentialFields) {
      set.add(f.path.toLowerCase());
    }
    for (final f in CourseTypeTemplateFields.essentialFields) {
      set.add(f.path.toLowerCase());
    }
    for (final f in ImportantFields.list) {
      set.add(f.path.toLowerCase());
    }
    return set;
  }

  static void _collectFields(
    XmlElement node,
    String prefix,
    Set<String> paths,
  ) {
    for (final attr in node.attributes) {
      final path =
          prefix.isEmpty ? '@${attr.name.local}' : '$prefix@${attr.name.local}';
      if (!_isExcluded(path)) paths.add(path);
    }

    for (final child in node.childElements) {
      if (child.name.local.toLowerCase() == 'header') continue;
      if (child.name.local.toLowerCase() == 'keyword') continue;

      final childPath =
          prefix.isEmpty ? child.name.local : '$prefix/${child.name.local}';

      if (XmlPath.hasElementChildren(child)) {
        _collectFields(child, childPath, paths);
      } else if (!_isExcluded(childPath)) {
        paths.add(childPath);
      }
    }
  }

  static void _collectFilled(
    XmlElement node,
    String prefix,
    Set<String> paths,
  ) {
    for (final attr in node.attributes) {
      if (attr.value.trim().isEmpty) continue;
      final path =
          prefix.isEmpty ? '@${attr.name.local}' : '$prefix/@${attr.name.local}';
      paths.add(path);
    }

    for (final child in node.childElements) {
      if (child.name.local.toLowerCase() == 'header') continue;
      final childPath =
          prefix.isEmpty ? child.name.local : '$prefix/${child.name.local}';
      if (XmlPath.hasElementChildren(child)) {
        _collectFilled(child, childPath, paths);
      } else if (child.innerText.trim().isNotEmpty) {
        paths.add(childPath);
      }
    }
  }

  static bool _isExcluded(String path) {
    if (_excludedPaths.contains(path.toLowerCase())) return true;
    if (path.toUpperCase().contains('/LOCATION/')) return true;
    if (path.toUpperCase().contains('/KEYWORD') ||
        path.toUpperCase().endsWith('/KEYWORD')) {
      return true;
    }
    return false;
  }

  static String _formatLabel(String path) => FieldLabels.forPath(path);
}
