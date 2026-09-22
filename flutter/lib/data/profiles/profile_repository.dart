import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../../domain/catalog/models.dart';
import '../../domain/fields/template_field_mapping.dart';
import '../xml/xml_file_io.dart';
import '../xml/xml_path.dart';

class ProfileRepository {
  ProfileRepository(this.profilesFolder) {
    Directory(profilesFolder).createSync(recursive: true);
  }

  final String profilesFolder;

  List<LocationProfile> loadLocations() {
    final path = p.join(profilesFolder, 'locations.xml');
    final result = <LocationProfile>[];
    if (!File(path).existsSync()) return result;

    final doc = XmlFileIo.loadDocument(path);
    for (final node in doc.findAllElements('LOCATION_PROFILE')) {
      final profile = LocationProfile(
        name: node.getAttribute('name') ?? '',
      );
      for (final child in node.childElements) {
        profile.values[child.name.local] = child.innerText;
      }
      if (profile.name.trim().isNotEmpty) result.add(profile);
    }
    return result;
  }

  List<CourseTypeProfile> loadCourseTypes() {
    final path = p.join(profilesFolder, 'coursetypes.xml');
    final result = <CourseTypeProfile>[];
    if (!File(path).existsSync()) return result;

    final doc = XmlFileIo.loadDocument(path);
    for (final node in doc.findAllElements('COURSE_TYPE_PROFILE')) {
      final profile = CourseTypeProfile(
        name: node.getAttribute('name') ?? '',
      );
      for (final child in node.childElements) {
        profile.values[child.name.local] = child.innerText;
        final typeAttr = child.getAttribute('type');
        if (typeAttr != null) {
          profile.attributes['${child.name.local}@type'] = typeAttr;
        }
      }
      if (profile.name.trim().isNotEmpty) result.add(profile);
    }
    return result;
  }

  void upsertLocationFromService(XmlElement service) {
    final city = XmlPath.getTextByPath(
          service,
          TemplateFieldMapping.locationFieldPaths['CITY']!,
        ) ??
        '';
    if (city.trim().isEmpty) return;

    final profiles = loadLocations();
    var profile = profiles.cast<LocationProfile?>().firstWhere(
          (p) =>
              p!.name.toLowerCase() == city.toLowerCase() ||
              (p.values['CITY'] ?? '').toLowerCase() == city.toLowerCase(),
          orElse: () => null,
        );
    if (profile == null) {
      profile = LocationProfile(name: city);
      profiles.add(profile);
    }

    for (final mapping in TemplateFieldMapping.locationFieldPaths.entries) {
      final value = XmlPath.getTextByPath(service, mapping.value);
      if (value != null) profile.values[mapping.key] = value;
    }
    saveLocations(profiles);
  }

  void saveLocations(List<LocationProfile> profiles) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('LOCATIONS', nest: () {
      for (final profile in profiles) {
        builder.element('LOCATION_PROFILE', nest: () {
          builder.attribute('name', profile.name);
          for (final entry in profile.values.entries) {
            builder.element(entry.key, nest: entry.value);
          }
        });
      }
    });
    File(p.join(profilesFolder, 'locations.xml')).writeAsStringSync(
      builder.buildDocument().toXmlString(pretty: true, indent: '    '),
    );
  }

  void upsertCourseTypeFromService(XmlElement service, String name) {
    final profiles = loadCourseTypes();
    var profile = profiles.cast<CourseTypeProfile?>().firstWhere(
          (p) => p!.name.toLowerCase() == name.toLowerCase(),
          orElse: () => null,
        );
    if (profile == null) {
      profile = CourseTypeProfile(name: name);
      profiles.add(profile);
    }
    for (final mapping in TemplateFieldMapping.courseTypeFieldPaths.entries) {
      final value = XmlPath.getTextByPath(service, mapping.value);
      if (value != null) profile.values[mapping.key] = value;
      final typeValue = XmlPath.getTextByPath(service, '${mapping.value}@type');
      if (typeValue != null) {
        profile.attributes['${mapping.key}@type'] = typeValue;
      }
    }
    saveCourseTypes(profiles);
  }

  void saveCourseTypes(List<CourseTypeProfile> profiles) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('COURSE_TYPES', nest: () {
      for (final profile in profiles) {
        builder.element('COURSE_TYPE_PROFILE', nest: () {
          builder.attribute('name', profile.name);
          for (final entry in profile.values.entries) {
            builder.element(entry.key, nest: () {
              final type = profile.attributes['${entry.key}@type'];
              if (type != null) builder.attribute('type', type);
              if (entry.value.isNotEmpty) builder.text(entry.value);
            });
          }
        });
      }
    });
    File(p.join(profilesFolder, 'coursetypes.xml')).writeAsStringSync(
      builder.buildDocument().toXmlString(pretty: true, indent: '    '),
    );
  }
}
