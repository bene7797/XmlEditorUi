import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../../domain/catalog/models.dart';
import '../xml/xml_file_io.dart';

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
}
