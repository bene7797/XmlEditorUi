import 'package:xml/xml.dart';

import '../../data/xml/xml_path.dart';
import '../catalog/course_list_filter.dart';
import 'important_fields.dart';

class AngebotWizardField {
  const AngebotWizardField({
    required this.label,
    required this.path,
    required this.hint,
    this.maxLines = 4,
    this.isPrice = false,
  });

  final String label;
  final String path;
  final String hint;
  final int maxLines;
  final bool isPrice;
}

class AngebotWizardFields {
  static const title = AngebotWizardField(
    label: 'Titel',
    path: ImportantFields.titlePath,
    hint: 'Kurzname des Bildungsangebots, ohne Ort und ohne Starttermin.',
    maxLines: 3,
  );

  static const description = AngebotWizardField(
    label: 'Beschreibung',
    path: 'SERVICE_DETAILS/DESCRIPTION_LONG',
    hint: 'Inhalt und Ablauf des Angebots. Gilt für alle späteren Termine.',
    maxLines: 10,
  );

  static const targetGroup = AngebotWizardField(
    label: 'Zielgruppe',
    path: 'SERVICE_DETAILS/TARGET_GROUP/TARGET_GROUP_TEXT',
    hint: 'Für wen ist das Angebot gedacht?',
    maxLines: 5,
  );

  static const requirements = AngebotWizardField(
    label: 'Voraussetzungen',
    path: 'SERVICE_DETAILS/REQUIREMENTS',
    hint: 'Zugangsvoraussetzungen, Eignungstest, Abschlüsse.',
    maxLines: 5,
  );

  static const degree = AngebotWizardField(
    label: 'Abschluss',
    path: 'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/DEGREE/DEGREE_TITLE',
    hint: 'Bezeichnung des angestrebten Abschlusses.',
    maxLines: 3,
  );

  static const subsidy = AngebotWizardField(
    label: 'Förderung',
    path:
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/SUBSIDY/SUBSIDY_DESCRIPTION',
    hint: 'Hinweis zu Bildungsgutschein und anderen Förderungen.',
    maxLines: 4,
  );

  static const price = AngebotWizardField(
    label: 'Preis',
    path: ImportantFields.pricePath,
    hint: 'Gesamtpreis des Angebots. Komma wird zu Punkt.',
    maxLines: 1,
    isPrice: true,
  );

  static const List<AngebotWizardField> pages = [
    title,
    description,
    targetGroup,
    requirements,
    degree,
    subsidy,
    price,
  ];
}

class AngebotFieldSuggestion {
  const AngebotFieldSuggestion({
    required this.value,
    required this.sources,
  });

  final String value;
  final List<String> sources;
}

class AngebotSuggestionIndex {
  AngebotSuggestionIndex(this.angebote);

  final List<XmlElement> angebote;

  List<AngebotFieldSuggestion> forPath(String path) {
    final grouped = <String, List<String>>{};
    for (final service in angebote) {
      final value = (XmlPath.getTextByPath(service, path) ?? '').trim();
      if (value.isEmpty) continue;
      grouped.putIfAbsent(value, () => []).add(_sourceLabel(service));
    }
    final result = grouped.entries
        .map(
          (e) => AngebotFieldSuggestion(value: e.key, sources: e.value),
        )
        .toList()
      ..sort((a, b) => a.sources.first.compareTo(b.sources.first));
    return result;
  }

  static String _sourceLabel(XmlElement service) {
    final kind = CourseListFilter.educationKindOf(service).label;
    final id = (XmlPath.getChildText(service, 'PRODUCT_ID') ?? '').trim();
    return id.isEmpty ? kind : '$kind · ID $id';
  }
}
