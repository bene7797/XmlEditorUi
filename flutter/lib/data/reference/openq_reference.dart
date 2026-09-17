import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

class CodedValue {
  const CodedValue(this.id, this.label);

  final String id;
  final String label;

  String get display => '$id — $label';
}

/// KURSNET value lists shipped with the official OpenQCat download.
class OpenqReference {
  OpenqReference({
    required this.contactRoles,
    required this.instructionTimes,
    required this.instructionForms,
    required this.educationTypes,
    required this.durations,
    required this.fundingFederal,
    required this.fundingRegional,
    required this.certStatus,
    required this.orgForms,
    required this.institutions,
    required this.courseTypes,
    required this.segmentTypes,
    required this.certifiers,
    required this.systematics,
    required this.places,
  });

  final List<CodedValue> contactRoles;
  final List<CodedValue> instructionTimes;
  final List<CodedValue> instructionForms;
  final List<CodedValue> educationTypes;
  final List<CodedValue> durations;
  final List<CodedValue> fundingFederal;
  final List<CodedValue> fundingRegional;
  final List<CodedValue> certStatus;
  final List<CodedValue> orgForms;
  final List<CodedValue> institutions;
  final List<CodedValue> courseTypes;
  final List<CodedValue> segmentTypes;
  final List<CodedValue> certifiers;
  final List<CodedValue> systematics;
  final Set<String> places;

  static OpenqReference load(String folder) {
    final wb = p.join(folder, 'wertebereiche');
    return OpenqReference(
      contactRoles: _loadDat(p.join(wb, 'ansprechpartner.dat')),
      instructionTimes: _loadDat(p.join(wb, 'unterrichtszeit.dat')),
      instructionForms: _loadDat(p.join(wb, 'unterrichtsform.dat')),
      educationTypes: _loadDat(p.join(wb, 'bildungsart.dat')),
      durations: _loadDat(p.join(wb, 'dauerklassen.dat')),
      fundingFederal: _loadDat(p.join(wb, 'foerderartenbund.dat')),
      fundingRegional: _loadDat(p.join(wb, 'foerderartenland.dat')),
      certStatus: _loadDat(p.join(wb, 'zertstatus.dat')),
      orgForms: _loadDat(p.join(wb, 'zugehoerig.dat')),
      institutions: _loadDat(p.join(wb, 'schulart.dat')),
      courseTypes: _loadDat(p.join(wb, 'angebotstyp.dat')),
      segmentTypes: _loadDat(p.join(wb, 'vgstrukturart.dat')),
      certifiers: _loadCsv(p.join(folder, 'Zertifizierer.csv'), idIndex: 0, labelIndex: 1),
      systematics: _loadCsv(p.join(folder, 'Systematik.csv'), idIndex: 0, labelIndex: 1),
      places: _loadPlaces(p.join(folder, 'Orte.csv')),
    );
  }

  List<CodedValue>? optionsForPath(String path) {
    final upper = path.toUpperCase();
    if (upper.contains('CONTACT_ROLE')) return contactRoles;
    if (upper.contains('INSTRUCTION_TIME')) return instructionTimes;
    if (upper.contains('INSTRUCTION_FORM_NAME')) return null;
    if (upper.contains('INSTRUCTION_FORM')) return instructionForms;
    if (upper.contains('EDUCATION_TYPE')) return educationTypes;
    if (_isEducationFlagPath(upper)) return educationFlags;
    if (upper.contains('COURSE_TYPE')) return courseTypes;
    if (upper.contains('SEGMENT_TYPE')) return segmentTypes;
    if (upper.contains('/DURATION') || upper.endsWith('DURATION')) {
      return durations;
    }
    if (upper.contains('FUNDING_TYPES_FEDERAL')) return fundingFederal;
    if (upper.contains('FUNDING_TYPES_REGIONAL')) return fundingRegional;
    if (upper.contains('CERTIFICATE_STATUS')) return certStatus;
    if (upper.contains('ORGANIZATIONAL_FORM')) return orgForms;
    if (upper.contains('CERTIFIER_NUMBER')) return certifiers;
    if (upper.contains('EXTENDED_INFO/INSTITUTION') &&
        !upper.contains('INSTITUTION_NUMBER')) {
      return institutions;
    }
    if (upper.endsWith('/COUNTRY') || upper.endsWith('COUNTRY')) {
      return const [CodedValue('DE', 'Deutschland')];
    }
    return null;
  }

  static const List<CodedValue> educationFlags = [
    CodedValue('true', 'Bildungsangebot (PRODUCT_ID = COURSE_ID)'),
    CodedValue('false', 'Veranstaltung/Termin (COURSE_ID zeigt auf das Angebot)'),
  ];

  bool isSystematikPath(String path) =>
      path.toUpperCase().contains('FEATURE/FNAME');

  /// Pretty value for grids, e.g. `3 — Leiter des Betriebs`.
  String displayFor(String path, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    if (isSystematikPath(path)) {
      return _match(systematics, trimmed)?.display ?? trimmed;
    }
    final match = _match(optionsForPath(path) ?? const [], trimmed);
    return match?.display ?? trimmed;
  }

  /// Human-readable meaning of a type/code value for tooltips.
  String? tooltipFor(String path, String value) {
    final trimmed = value.trim();
    final upper = path.toUpperCase();
    final hint = _fieldHint(upper);

    if (isSystematikPath(path)) {
      final match = _match(systematics, trimmed);
      if (match == null && hint == null) return null;
      final buffer = StringBuffer();
      if (hint != null) buffer.writeln(hint);
      if (match != null) {
        if (hint != null) buffer.writeln();
        buffer.writeln('${match.id} = ${match.label}');
      }
      return buffer.toString().trim();
    }

    final options = optionsForPath(path);
    if (options == null || options.isEmpty) return hint;

    final match = _match(options, trimmed);
    final buffer = StringBuffer();
    if (hint != null) {
      buffer.writeln(hint);
      buffer.writeln();
    }
    if (match != null) {
      buffer.writeln('type="${match.id}" = ${match.label}');
    } else if (trimmed.isNotEmpty) {
      buffer.writeln('Aktueller Wert: $trimmed');
    } else {
      buffer.writeln('Noch kein type gesetzt.');
    }
    if (options.length <= 35) {
      buffer.writeln();
      buffer.writeln('Mögliche Werte:');
      for (final option in options) {
        buffer.writeln('${option.id} = ${option.label}');
      }
    }
    return buffer.toString().trim();
  }

  static String? _fieldHint(String upper) {
    if (upper.contains('CONTACT_ROLE')) {
      return 'Rolle des Ansprechpartners (type im XML).\n'
          'Im HEADER/SUPPLIER sind nur type 2 (Gesamtansprechpartner) '
          'oder 3 (Leiter des Betriebs) zulässig.';
    }
    if (upper.contains('INSTRUCTION_TIME')) {
      return 'Unterrichtszeit: type 1 = Vollzeit, type 2 = Teilzeit.';
    }
    if (upper.contains('INSTRUCTION_FORM_NAME')) return null;
    if (upper.contains('INSTRUCTION_FORM')) {
      return 'Unterrichtsform laut BA-Wertebereich.';
    }
    if (upper.contains('EDUCATION_TYPE')) {
      return 'Bildungsart laut BA-Wertebereich.';
    }
    if (_isEducationFlagPath(upper)) {
      return 'EDUCATION type unterscheidet Angebot und Termin:\n'
          'true = Bildungsangebot, false = Veranstaltung.';
    }
    if (upper.contains('COURSE_TYPE')) {
      return 'Angebotstyp laut BA-Wertebereich.';
    }
    if (upper.contains('SEGMENT_TYPE')) {
      return 'Strukturart der Veranstaltung.';
    }
    if (upper.contains('DURATION')) {
      return 'Dauerklasse (type am DURATION-Element).';
    }
    if (upper.contains('ORGANIZATIONAL_FORM')) {
      return 'Organisationsform des Trägers.';
    }
    if (upper.contains('CERTIFICATE_STATUS')) {
      return 'Status der AZAV-Zertifizierung.';
    }
    if (upper.endsWith('COUNTRY')) {
      return 'Länderkennzeichen, für KURSNET in der Regel DE.';
    }
    return null;
  }

  static bool _isEducationFlagPath(String upper) {
    if (upper.contains('EDUCATION_TYPE')) return false;
    return upper.endsWith('EDUCATION@TYPE') ||
        upper.endsWith('EDUCATION/@TYPE');
  }

  static CodedValue? _match(List<CodedValue> options, String value) {
    if (value.isEmpty) return null;
    final lower = value.toLowerCase();
    for (final option in options) {
      if (option.id.toLowerCase() == lower ||
          option.label.toLowerCase() == lower) {
        return option;
      }
    }
    return null;
  }

  bool isKnownPlace(String zip, String city) {
    if (zip.trim().isEmpty || city.trim().isEmpty) return false;
    return places.contains(_placeKey(zip, city));
  }

  List<CodedValue> searchSystematik(String query, {int limit = 40}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return systematics.take(limit).toList();
    return systematics
        .where(
          (v) =>
              v.id.toLowerCase().contains(q) ||
              v.label.toLowerCase().contains(q),
        )
        .take(limit)
        .toList();
  }

  static List<CodedValue> _loadDat(String path) {
    final file = File(path);
    if (!file.existsSync()) return const [];
    final lines = latin1.decode(file.readAsBytesSync()).split(RegExp(r'\r?\n'));
    final result = <CodedValue>[];
    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final parts = line.contains('|') ? line.split('|') : line.split('\t');
      if (parts.isEmpty) continue;
      final id = parts[0].trim();
      final label = parts.length > 1 ? parts[1].trim() : id;
      if (id.isEmpty) continue;
      result.add(CodedValue(id, label));
    }
    return result;
  }

  static List<CodedValue> _loadCsv(
    String path, {
    required int idIndex,
    required int labelIndex,
  }) {
    final file = File(path);
    if (!file.existsSync()) return const [];
    final lines = latin1.decode(file.readAsBytesSync()).split(RegExp(r'\r?\n'));
    final result = <CodedValue>[];
    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final parts = line.split('|');
      if (parts.length <= idIndex) continue;
      final id = parts[idIndex].trim();
      final label = parts.length > labelIndex ? parts[labelIndex].trim() : id;
      if (id.isEmpty) continue;
      result.add(CodedValue(id, label));
    }
    return result;
  }

  static Set<String> _loadPlaces(String path) {
    final file = File(path);
    if (!file.existsSync()) return <String>{};
    final lines = latin1.decode(file.readAsBytesSync()).split(RegExp(r'\r?\n'));
    final result = <String>{};
    for (final raw in lines) {
      final parts = raw.split('|');
      if (parts.length < 2) continue;
      final zip = parts[0].trim();
      final city = parts[1].trim();
      if (zip.isEmpty || city.isEmpty) continue;
      result.add(_placeKey(zip, city));
    }
    return result;
  }

  static String _placeKey(String zip, String city) =>
      '${zip.trim()}|${city.trim().toLowerCase()}';
}
