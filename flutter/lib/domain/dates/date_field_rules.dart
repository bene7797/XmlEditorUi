import 'package:xml/xml.dart';

import '../../data/xml/xml_path.dart';

/// Port of C# DateFieldHelper — same formats and defaults.
class DateFieldRules {
  static const courseStartPath = 'SERVICE_DETAILS/SERVICE_DATE/START_DATE';
  static const courseEndPath = 'SERVICE_DETAILS/SERVICE_DATE/END_DATE';
  static const announcementStartPath = 'SERVICE_DETAILS/ANNOUNCEMENT/START_DATE';
  static const announcementEndPath = 'SERVICE_DETAILS/ANNOUNCEMENT/END_DATE';
  static const instructionTimePath =
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_TIME';

  static bool isDatePath(String path) =>
      path.toUpperCase().contains('START_DATE') ||
      path.toUpperCase().contains('END_DATE');

  static bool isCourseDatePath(String path) =>
      path.toUpperCase().contains('SERVICE_DATE');

  static bool isCourseStartPath(String? path) =>
      path != null &&
      path.trim().isNotEmpty &&
      path.toUpperCase().endsWith('SERVICE_DATE/START_DATE');

  static DateTime? tryParse(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    var clean = value.trim();
    if (clean.contains('T')) {
      clean = clean.split('+').first;
    } else if (clean.contains('+')) {
      clean = clean.split('+').first;
    }
    return DateTime.tryParse(clean);
  }

  static String format(DateTime date, {required bool includeTime}) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    if (includeTime) {
      final hh = date.hour.toString().padLeft(2, '0');
      final mm = date.minute.toString().padLeft(2, '0');
      final ss = date.second.toString().padLeft(2, '0');
      return '$y-$m-$d'
          'T$hh:$mm:$ss.000+01:00';
    }
    return '$y-$m-$d+01:00';
  }

  static bool isTeilzeit(XmlElement service) {
    final instructionTime =
        XmlPath.getTextByPath(service, instructionTimePath) ?? '';
    return instructionTime.toLowerCase().contains('teilzeit');
  }

  /// Returns changed paths. Same rules as WinForms DateFieldHelper.
  static List<String> applyCourseStartDefaults(
    XmlElement service, {
    String? courseStartValue,
    DateTime? todayOverride,
  }) {
    final changedPaths = <String>[];
    final startValue =
        courseStartValue ?? XmlPath.getTextByPath(service, courseStartPath);
    final startDate = tryParse(startValue);
    if (startDate == null) return changedPaths;

    final startDay = DateTime(startDate.year, startDate.month, startDate.day);
    final now = todayOverride ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    XmlPath.setNodeByPath(
      service,
      announcementEndPath,
      format(startDay, includeTime: false),
    );
    changedPaths.add(announcementEndPath);

    final oneYearFromToday =
        DateTime(today.year + 1, today.month, today.day);
    final announcementStart = startDay.isAfter(oneYearFromToday)
        ? DateTime(startDay.year - 1, startDay.month, startDay.day)
        : today;
    XmlPath.setNodeByPath(
      service,
      announcementStartPath,
      format(announcementStart, includeTime: false),
    );
    changedPaths.add(announcementStartPath);

    if (isTeilzeit(service)) {
      var endDate =
          DateTime(startDay.year + 1, startDay.month, startDay.day);
      final timeOfDay = Duration(
        hours: startDate.hour,
        minutes: startDate.minute,
        seconds: startDate.second,
        milliseconds: startDate.millisecond,
      );
      if (timeOfDay != Duration.zero) {
        endDate = endDate.add(timeOfDay);
      }
      XmlPath.setNodeByPath(
        service,
        courseEndPath,
        format(endDate, includeTime: true),
      );
      changedPaths.add(courseEndPath);
    }

    return changedPaths;
  }

  static DateTime getCourseStartDateOrMax(XmlElement service) {
    final text = XmlPath.getTextByPath(service, courseStartPath);
    return tryParse(text) ?? DateTime(9999, 12, 31);
  }
}
