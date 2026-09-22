import 'important_fields.dart';
import 'template_field_definitions.dart';

/// Shared UI names for XML fields so template and course views stay in sync.
class FieldLabels {
  static String forPath(String path) {
    final key = _normalize(path);
    final known = _byPath[key];
    if (known != null) return known;

    if (key.contains('@')) {
      final parts = key.split('@');
      final element = _leaf(parts.first);
      final elementLabel = _byLeaf[element] ?? _toWords(element);
      return '$elementLabel (${parts.last.toLowerCase()})';
    }

    final leaf = _leaf(key);
    return _byLeaf[leaf] ?? _toWords(leaf);
  }

  static final Map<String, String> _byPath = {
    for (final field in LocationTemplateFields.essentialFields)
      _normalize(field.path): field.label,
    for (final field in CourseTypeTemplateFields.essentialFields)
      _normalize(field.path): field.label,
    for (final field in HeaderTemplateFields.essentialFields)
      _normalize(field.path): field.label,
    for (final field in ImportantFields.list)
      _normalize(field.path): field.label,
  };

  static const Map<String, String> _byLeaf = {
    'ADDRESS_REMARKS': 'Adress Bemerkungen',
    'INSTRUCTION_REMARKS': 'Unterrichtsbemerkungen',
    'INSTRUCTION_TIME': 'Beschäftigungsart',
    'EDUCATION_TYPE': 'Bildungsart',
    'COURSE_TYPE': 'Kurstyp',
    'TITLE': 'Titel',
    'PRODUCT_ID': 'Product-ID',
    'COURSE_ID': 'Course-ID',
    'START_DATE': 'Startdatum',
    'END_DATE': 'Enddatum',
    'CITY': 'Stadt',
    'STREET': 'Strasse',
    'ZIP': 'PLZ',
    'ZIPBOX': 'PLZ Postfach',
    'STATE': 'Bundesland',
    'COUNTRY': 'Land',
    'PHONE': 'Telefon',
    'MOBILE': 'Mobil',
    'EMAIL': 'Email',
    'NAME': 'Name',
    'NAME2': 'Name 2',
    'DURATION': 'Dauer',
    'PRICE_AMOUNT': 'Preis',
    'CONTACT_REMARKS': 'Kontakt Bemerkungen',
  };

  static String _normalize(String path) => path
      .replaceAll('/@', '@')
      .replaceAll('\\', '/')
      .replaceAll(RegExp(r'^/+'), '')
      .toUpperCase();

  static String _leaf(String normalizedPath) {
    if (normalizedPath.contains('@')) {
      return normalizedPath.split('@').first.split('/').last;
    }
    return normalizedPath.split('/').last;
  }

  static String _toWords(String name) =>
      name.split('_').where((p) => p.isNotEmpty).join(' ');
}
