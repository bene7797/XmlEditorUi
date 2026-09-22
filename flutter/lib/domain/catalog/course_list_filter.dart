import 'package:xml/xml.dart';

import '../../data/xml/xml_path.dart';
import '../dates/date_field_rules.dart';
import 'catalog_session.dart';

enum InstructionTimeFilter { vollzeit, teilzeit }

enum EducationKindFilter { umschulung, externenpruefung }

class CourseListFilter {
  const CourseListFilter({
    this.startDate,
    this.city,
    this.instructionTime,
    this.educationKind,
    this.showExpired = false,
    this.todayOverride,
  });

  final DateTime? startDate;
  final String? city;
  final InstructionTimeFilter? instructionTime;
  final EducationKindFilter? educationKind;
  final bool showExpired;
  final DateTime? todayOverride;

  bool get hasCriteria =>
      startDate != null ||
      city != null ||
      instructionTime != null ||
      educationKind != null;

  bool get isActive => hasCriteria || !showExpired;

  /// Angebote have no list start date; Termin/Abgelaufen apply only to Kurse.
  CourseListFilter get forAngebote => copyWith(
        showExpired: true,
        clearStartDate: true,
      );

  CourseListFilter copyWith({
    DateTime? startDate,
    String? city,
    InstructionTimeFilter? instructionTime,
    EducationKindFilter? educationKind,
    bool? showExpired,
    DateTime? todayOverride,
    bool clearStartDate = false,
    bool clearCity = false,
    bool clearInstructionTime = false,
    bool clearEducationKind = false,
  }) {
    return CourseListFilter(
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      city: clearCity ? null : (city ?? this.city),
      instructionTime:
          clearInstructionTime ? null : (instructionTime ?? this.instructionTime),
      educationKind:
          clearEducationKind ? null : (educationKind ?? this.educationKind),
      showExpired: showExpired ?? this.showExpired,
      todayOverride: todayOverride ?? this.todayOverride,
    );
  }

  bool matches(XmlElement service) {
    if (city != null && cityOf(service) != city) return false;

    if (instructionTime != null &&
        instructionTimeOf(service) != instructionTime) {
      return false;
    }

    if (educationKind != null && educationKindOf(service) != educationKind) {
      return false;
    }

    if (startDate != null) {
      final date = startDateOf(service);
      if (date == null || !_sameDay(date, startDate!)) return false;
    }

    if (!showExpired) {
      final date = startDateOf(service);
      if (date != null && date.isBefore(_today)) return false;
    }
    return true;
  }

  DateTime get _today {
    final now = todayOverride ?? DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static String cityOf(XmlElement service) =>
      (XmlPath.getTextByPath(
            service,
            'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/CITY',
          ) ??
          '')
          .trim();

  static InstructionTimeFilter? instructionTimeOf(XmlElement service) {
    final text = (XmlPath.getTextByPath(
          service,
          DateFieldRules.instructionTimePath,
        ) ??
        '')
        .toLowerCase();
    if (text.contains('teilzeit')) return InstructionTimeFilter.teilzeit;
    if (text.contains('vollzeit')) return InstructionTimeFilter.vollzeit;
    return null;
  }

  static EducationKindFilter educationKindOf(XmlElement service) {
    final edu = XmlPath.getTextByPath(
          service,
          'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/EDUCATION_TYPE',
        ) ??
        '';
    final lower = edu.toLowerCase();
    if (lower.contains('nachholen') || lower.contains('extern')) {
      return EducationKindFilter.externenpruefung;
    }
    return EducationKindFilter.umschulung;
  }

  static DateTime? startDateOf(XmlElement service) {
    final raw = XmlPath.getTextByPath(service, DateFieldRules.courseStartPath);
    final parsed = DateFieldRules.tryParse(raw);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static List<String> uniqueCities(Iterable<XmlElement> services) {
    final cities = services
        .map(cityOf)
        .where((c) => c.isNotEmpty && c.toLowerCase() != 'ort ?')
        .toSet()
        .toList()
      ..sort();
    return cities;
  }

  static List<DateTime> uniqueStartDates(Iterable<XmlElement> services) {
    final dates = services
        .map(startDateOf)
        .whereType<DateTime>()
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort();
    return dates;
  }

  static List<T> apply<T>({
    required List<T> items,
    required XmlElement Function(T item) serviceOf,
    required bool Function(T item) isVeranstaltung,
    required CourseListFilter filter,
  }) {
    if (!filter.isActive) return items;

    final matching = <XmlElement>{};
    for (final item in items) {
      final service = serviceOf(item);
      if (filter.matches(service)) matching.add(service);
    }

    final visible = <XmlElement>{...matching};
    for (final item in items) {
      if (!isVeranstaltung(item)) continue;
      final service = serviceOf(item);
      if (!matching.contains(service)) continue;
      final courseId = CatalogSession.educationCourseId(service) ?? '';
      if (courseId.isEmpty) continue;
      for (final parent in items) {
        if (isVeranstaltung(parent)) continue;
        final id = XmlPath.getChildText(serviceOf(parent), 'PRODUCT_ID') ?? '';
        if (id == courseId) visible.add(serviceOf(parent));
      }
    }

    return items.where((item) => visible.contains(serviceOf(item))).toList();
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

extension InstructionTimeFilterLabel on InstructionTimeFilter {
  String get label => switch (this) {
        InstructionTimeFilter.vollzeit => 'Vollzeit',
        InstructionTimeFilter.teilzeit => 'Teilzeit',
      };
}

extension EducationKindFilterLabel on EducationKindFilter {
  String get label => switch (this) {
        EducationKindFilter.umschulung => 'Umschulung',
        EducationKindFilter.externenpruefung => 'Externenprüfung',
      };
}
