import 'field_grid.dart';

class FieldFormSection {
  const FieldFormSection({
    required this.id,
    required this.title,
    required this.color,
    required this.rows,
  });

  final String id;
  final String title;
  final ColorValue color;
  final List<FieldGridRow> rows;
}

typedef ColorValue = int;

class FieldFormLayout {
  static const _order = [
    'identity',
    'header',
    'header_creator',
    'header_recipient',
    'header_supplier',
    'texts',
    'dates',
    'location',
    'contact',
    'education',
    'price',
    'other',
  ];

  static const titles = {
    'identity': 'Identität',
    'header': 'Katalog',
    'header_creator': 'Ersteller',
    'header_recipient': 'Empfänger',
    'header_supplier': 'Anbieter',
    'texts': 'Texte',
    'dates': 'Termine',
    'location': 'Ort',
    'contact': 'Kontakt',
    'education': 'Bildung',
    'price': 'Preis',
    'other': 'Weitere Felder',
  };

  static const colors = {
    'identity': 0xFF1B4F72,
    'header': 0xFF2874A6,
    'header_creator': 0xFF1A5276,
    'header_recipient': 0xFF5D6D7E,
    'header_supplier': 0xFF154360,
    'texts': 0xFF1A5276,
    'dates': 0xFF0E6655,
    'location': 0xFFB9770E,
    'contact': 0xFF6C3483,
    'education': 0xFF1E8449,
    'price': 0xFFB7950B,
    'other': 0xFF5D6D7E,
  };

  static const _leafOrder = [
    'PRODUCT_ID',
    'COURSE_ID',
    'COURSE_TYPE',
    'SUPPLIER_ID',
    'GENERATOR_INFO',
    'LANGUAGE',
    'CATALOG_ID',
    'CATALOG_VERSION',
    'CATALOG_NAME',
    'GENERATION_DATE',
    'FIRST_NAME',
    'LAST_NAME',
    'SALUTATION',
    'CONTACT_ROLE',
    'TITLE',
    'KEYWORD',
    'DESCRIPTION',
    'DESCRIPTION_LONG',
    'REQUIREMENTS',
    'TARGET_GROUP',
    'TERMS_AND_CONDITIONS',
    'REMARKS',
    'START_DATE',
    'END_DATE',
    'NAME',
    'NAME2',
    'STREET',
    'ZIP',
    'ZIPBOX',
    'CITY',
    'STATE',
    'COUNTRY',
    'PHONE',
    'MOBILE',
    'EMAIL',
    'URL',
    'ADDRESS_REMARKS',
    'CONTACT_REMARKS',
    'EDUCATION_TYPE',
    'INSTRUCTION_TIME',
    'INSTRUCTION_FORM',
    'INSTRUCTION_REMARKS',
    'DURATION',
    'MIN_PARTICIPANTS',
    'MAX_PARTICIPANTS',
    'FLEXIBLE_START',
    'DEGREE_TITLE',
    'PRICE_AMOUNT',
    'PRICE_CURRENCY',
  ];

  static List<FieldFormSection> sectionsOf(List<FieldGridRow> rows) {
    final buckets = <String, List<FieldGridRow>>{
      for (final id in _order) id: <FieldGridRow>[],
    };
    for (final row in rows) {
      buckets[sectionIdFor(row.path)]!.add(row);
    }
    return [
      for (final id in _order)
        if (buckets[id]!.isNotEmpty)
          FieldFormSection(
            id: id,
            title: titles[id]!,
            color: colors[id]!,
            rows: _sorted(buckets[id]!),
          ),
    ];
  }

  static String sectionIdFor(String path) {
    final p = path.toUpperCase().replaceAll('/@', '@');
    if (p.contains('DOCUMENT_CREATOR')) return 'header_creator';
    if (p.contains('HEADER/RECIPIENT')) return 'header_recipient';
    if (p.contains('HEADER/SUPPLIER')) return 'header_supplier';
    if (p.startsWith('HEADER') || p.contains('/HEADER/')) return 'header';
    if (p.contains('/LOCATION') || p.endsWith('/LOCATION')) return 'location';
    if (p.contains('/CONTACT')) return 'contact';
    if (p.contains('SERVICE_DATE') ||
        p.contains('/ANNOUNCEMENT') ||
        p.contains('REGISTRATION_DATE')) {
      return 'dates';
    }
    if (p.contains('PRICE')) return 'price';
    if (p.contains('DESCRIPTION') ||
        p.contains('KEYWORD') ||
        p.contains('REQUIREMENTS') ||
        p.contains('TARGET_GROUP') ||
        p.contains('TERMS_AND') ||
        (p.endsWith('TITLE') && !p.contains('DEGREE'))) {
      return 'texts';
    }
    if (p.contains('PRODUCT_ID') ||
        p.contains('COURSE_ID') ||
        p.contains('SUPPLIER_ID') ||
        p.contains('COURSE_TYPE')) {
      return 'identity';
    }
    if (p.contains('/EDUCATION') ||
        p.contains('DEGREE') ||
        p.contains('CERTIFICATE') ||
        p.contains('SUBSIDY') ||
        p.contains('INSTRUCTION') ||
        p.contains('DURATION') ||
        p.contains('MODULE_COURSE')) {
      return 'education';
    }
    return 'other';
  }

  static List<List<FieldGridRow>> pairRows(List<FieldGridRow> rows) {
    final used = <String>{};
    final pending = <FieldGridRow>[];
    final groups = <List<FieldGridRow>>[];

    void flush() {
      if (pending.isEmpty) return;
      groups.add(List<FieldGridRow>.from(pending));
      pending.clear();
    }

    for (final row in rows) {
      final key = row.path.toUpperCase();
      if (used.contains(key)) continue;

      final pair = _pairFor(row, rows);
      if (pair != null) {
        flush();
        used
          ..add(key)
          ..add(pair.path.toUpperCase());
        groups.add([row, pair]);
        continue;
      }

      if (isWide(row)) {
        flush();
        used.add(key);
        groups.add([row]);
        continue;
      }

      used.add(key);
      pending.add(row);
      if (pending.length == 2) flush();
    }
    flush();
    return groups;
  }

  static bool isWide(FieldGridRow row) {
    final path = row.path.toUpperCase();
    return path.endsWith('/TITLE') ||
        path.contains('DESCRIPTION') ||
        path.contains('REQUIREMENTS') ||
        path.contains('TARGET_GROUP') ||
        path.contains('TERMS_AND') ||
        path.contains('REMARKS') ||
        path.contains('KEYWORD');
  }

  static FieldGridRow? _pairFor(FieldGridRow row, List<FieldGridRow> rows) {
    final path = row.path.toUpperCase();
    final leaf = path.split('/').last.split('@').first;
    final expectedLeaf = switch (leaf) {
      'START_DATE' => 'END_DATE',
      'ZIP' => 'CITY',
      'PHONE' => 'MOBILE',
      'NAME' => 'NAME2',
      'FIRST_NAME' => 'LAST_NAME',
      'PRODUCT_ID' => 'COURSE_ID',
      'MIN_PARTICIPANTS' => 'MAX_PARTICIPANTS',
      'CATALOG_ID' => 'CATALOG_VERSION',
      _ => null,
    };
    if (expectedLeaf == null) return null;
    for (final other in rows) {
      final otherLeaf =
          other.path.toUpperCase().split('/').last.split('@').first;
      if (otherLeaf == expectedLeaf) return other;
    }
    return null;
  }

  static List<FieldGridRow> _sorted(List<FieldGridRow> rows) {
    final copy = List<FieldGridRow>.from(rows);
    copy.sort((a, b) {
      final cmp = _rank(a.path).compareTo(_rank(b.path));
      if (cmp != 0) return cmp;
      return a.path.toLowerCase().compareTo(b.path.toLowerCase());
    });
    return copy;
  }

  static int _rank(String path) {
    final leaf =
        path.toUpperCase().replaceAll('/@', '@').split('/').last.split('@').first;
    final index = _leafOrder.indexOf(leaf);
    return index < 0 ? 1000 : index;
  }
}
