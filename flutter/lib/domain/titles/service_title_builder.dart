import 'package:xml/xml.dart';

import '../../data/xml/xml_path.dart';
import '../catalog/catalog_session.dart';
import '../catalog/models.dart';

class ServiceTitleBuilder {
  static String build(XmlElement service, int index, [ServiceState? state]) {
    final kind = CatalogSession.isAngebot(service) ? 'Angebot' : 'Termin';
    final title = _buildCore(service, index);
    final withKind = '[$kind] $title';
    return switch (state) {
      ServiceState.neu => '[NEU] $withKind',
      ServiceState.updated => '[UPDATE] $withKind',
      _ => withKind,
    };
  }

  static String _buildCore(XmlElement service, int index) {
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
    if (startDate != null && startDate.trim().isNotEmpty) {
      parts.add('Start: ${_shortDate(startDate)}');
    }
    if (title != null && title.trim().isNotEmpty) parts.add(title);

    return parts.isNotEmpty ? parts.join(' | ') : 'SERVICE #${index + 1}';
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
      value.length >= 10 ? value.substring(0, 10) : value;
}
