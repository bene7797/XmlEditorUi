import 'package:xml/xml.dart';

import '../../data/xml/xml_path.dart';
import '../catalog/catalog_session.dart';
import '../catalog/course_list_filter.dart';
import '../catalog/models.dart';
import '../dates/date_field_rules.dart';

class ServiceTitleBuilder {
  static String build(
    XmlElement service,
    int index, {
    ServiceState? state,
    bool asTermin = false,
    bool includeStartDate = true,
    bool compact = false,
    bool neutral = false,
  }) {
    if (compact) {
      return _buildCompact(
        service,
        index,
        includeStartDate: includeStartDate,
        neutral: neutral,
      );
    }

    final kind = asTermin || !CatalogSession.isAngebot(service)
        ? 'Termin'
        : 'Angebot';
    final title = _buildCore(
      service,
      index,
      includeStartDate: includeStartDate,
    );
    final withKind = '[$kind] $title';
    return switch (state) {
      ServiceState.neu => '[NEU] $withKind',
      ServiceState.updated => '[UPDATE] $withKind',
      _ => withKind,
    };
  }

  static String _buildCompact(
    XmlElement service,
    int index, {
    required bool includeStartDate,
    bool neutral = false,
  }) {
    if (neutral) {
      final kind = CourseListFilter.educationKindOf(service).label;
      final productId = XmlPath.getChildText(service, 'PRODUCT_ID');
      final parts = <String>[kind];
      if (productId != null && productId.trim().isNotEmpty) {
        parts.add('ID: ${productId.trim()}');
      }
      return parts.join(' · ');
    }

    final city = _text(
      XmlPath.getTextByPath(
        service,
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/CITY',
      ),
      fallback: 'Ort ?',
    );
    final art = _text(
      XmlPath.getTextByPath(
        service,
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_TIME',
      ),
      fallback: 'Art ?',
    );
    final kind = CourseListFilter.educationKindOf(service).label;
    final productId = XmlPath.getChildText(service, 'PRODUCT_ID');
    final startDate =
        XmlPath.getTextByPath(service, 'SERVICE_DETAILS/SERVICE_DATE/START_DATE');

    final parts = <String>[city, kind, art];
    if (productId != null && productId.trim().isNotEmpty) {
      parts.add('ID: ${productId.trim()}');
    }
    if (includeStartDate &&
        startDate != null &&
        startDate.trim().isNotEmpty) {
      parts.add('Start: ${_shortDate(startDate)}');
    }
    return parts.isNotEmpty ? parts.join(' · ') : 'SERVICE #${index + 1}';
  }

  static String _buildCore(
    XmlElement service,
    int index, {
    required bool includeStartDate,
  }) {
    final productId = XmlPath.getChildText(service, 'PRODUCT_ID');
    final title = XmlPath.getTextByPath(service, 'SERVICE_DETAILS/TITLE');
    final city = XmlPath.getTextByPath(
      service,
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/CITY',
    );
    final instructionTime = XmlPath.getTextByPath(
      service,
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_TIME',
    );
    final educationType = XmlPath.getTextByPath(
      service,
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/EDUCATION_TYPE',
    );
    final startDate =
        XmlPath.getTextByPath(service, 'SERVICE_DETAILS/SERVICE_DATE/START_DATE');
    final category = _buildCategory(city, instructionTime, educationType);

    final parts = <String>[];
    if (category.trim().isNotEmpty) parts.add('[$category]');
    if (productId != null && productId.trim().isNotEmpty) {
      parts.add('ID: $productId');
    }
    if (includeStartDate &&
        startDate != null &&
        startDate.trim().isNotEmpty) {
      parts.add('Start: ${_shortDate(startDate)}');
    }
    if (title != null && title.trim().isNotEmpty) parts.add(title);

    return parts.isNotEmpty ? parts.join(' | ') : 'SERVICE #${index + 1}';
  }

  static String _text(String? value, {required String fallback}) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? fallback : trimmed;
  }

  static String _buildCategory(
    String? city,
    String? instructionTime,
    String? educationType,
  ) {
    final cityText =
        (city == null || city.trim().isEmpty) ? 'Ort ?' : city.trim();
    final timeText = (instructionTime == null || instructionTime.trim().isEmpty)
        ? 'Zeit ?'
        : instructionTime.trim();

    final edu = educationType ?? '';
    final isExtern = edu.toLowerCase().contains('nachholen') ||
        edu.toLowerCase().contains('extern');

    return isExtern
        ? 'Externenprüfung - $cityText - $timeText'
        : '$cityText - $timeText';
  }

  static String _shortDate(String value) =>
      DateFieldRules.formatForUi(value);
}
