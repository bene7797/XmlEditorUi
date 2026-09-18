import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../data/assets/app_data_store.dart';
import '../data/kursnet/kursnet_client.dart';
import '../data/profiles/profile_repository.dart';
import '../data/reference/openq_reference.dart';
import '../data/templates/service_template_repository.dart';
import '../data/xml/xml_path.dart';
import '../domain/catalog/catalog_session.dart';
import '../domain/catalog/models.dart';
import '../domain/dates/date_field_rules.dart';
import '../domain/fields/number_input.dart';
import '../domain/kursnet/kursnet_rules.dart';
import '../domain/templates/main_template_variants.dart';
import '../domain/templates/template_configurator.dart';
import '../domain/titles/service_title_builder.dart';
import '../ffi/xsd_validator.dart';

class CourseListEntry {
  CourseListEntry(
    this.service,
    this.title, {
    this.isVeranstaltung = false,
  });

  final XmlElement service;
  final String title;
  final bool isVeranstaltung;
}

/// App-wide session state for the Flutter editor.
class EditorController extends ChangeNotifier {
  EditorController(this.store)
      : session = CatalogSession(servicesTemplateFolder: store.servicesFolder),
        templates = ServiceTemplateRepository(store.servicesFolder),
        profiles = ProfileRepository(store.profilesFolder),
        reference = OpenqReference.load(store.referenceFolder);

  final AppDataStore store;
  final CatalogSession session;
  final ServiceTemplateRepository templates;
  final ProfileRepository profiles;
  final OpenqReference reference;
  final KursnetClient kursnetClient = KursnetClient();

  XmlElement? selectedService;
  String? loadedFilePath;
  String? statusMessage;

  List<CourseListEntry> get sortedCourses {
    final services = session.getServiceNodes();
    final angebote = <XmlElement>[];
    final childrenByCourseId = <String, List<XmlElement>>{};
    final others = <XmlElement>[];

    for (final service in services) {
      if (CatalogSession.isAngebot(service)) {
        angebote.add(service);
        continue;
      }
      final courseId = CatalogSession.educationCourseId(service) ?? '';
      if (courseId.isEmpty) {
        others.add(service);
      } else {
        childrenByCourseId.putIfAbsent(courseId, () => []).add(service);
      }
    }

    int byStart(XmlElement a, XmlElement b) {
      final cmp = DateFieldRules.getCourseStartDateOrMax(a)
          .compareTo(DateFieldRules.getCourseStartDateOrMax(b));
      if (cmp != 0) return cmp;
      return (XmlPath.getChildText(a, 'PRODUCT_ID') ?? '')
          .compareTo(XmlPath.getChildText(b, 'PRODUCT_ID') ?? '');
    }

    angebote.sort(byStart);
    for (final children in childrenByCourseId.values) {
      children.sort(byStart);
    }
    others.sort(byStart);

    final ordered = <XmlElement>[];
    final used = <XmlElement>{};
    for (final angebot in angebote) {
      ordered.add(angebot);
      final id = XmlPath.getChildText(angebot, 'PRODUCT_ID') ?? '';
      final kids = childrenByCourseId[id] ?? const <XmlElement>[];
      ordered.addAll(kids);
      used.addAll(kids);
    }
    for (final children in childrenByCourseId.values) {
      for (final child in children) {
        if (!used.contains(child)) ordered.add(child);
      }
    }
    ordered.addAll(others);

    final result = <CourseListEntry>[];
    for (var i = 0; i < ordered.length; i++) {
      final service = ordered[i];
      result.add(
        CourseListEntry(
          service,
          ServiceTitleBuilder.build(service, i, session.serviceStates[service]),
          isVeranstaltung: !CatalogSession.isAngebot(service),
        ),
      );
    }
    return result;
  }

  void loadXml(String path) {
    session.loadXml(path);
    loadedFilePath = path;
    selectedService = null;
    statusMessage = 'XML geladen: $path';
    notifyListeners();
  }

  void selectService(XmlElement? service) {
    selectedService = service;
    notifyListeners();
  }

  void setFieldValue(XmlElement service, String path, String value) {
    if (!DateFieldRules.isDatePath(path)) {
      value = NumberInput.normalizeDecimal(value);
    }
    XmlPath.setNodeByPath(service, path, value);
    session.markFieldAsChanged(service, path);

    if (DateFieldRules.isCourseStartPath(path)) {
      for (final changed in DateFieldRules.applyCourseStartDefaults(
        service,
        courseStartValue: value,
      )) {
        session.markFieldAsChanged(service, changed);
      }
    }

    notifyListeners();
  }

  void setCodedValue(XmlElement service, String path, CodedValue value) {
    final elementPath = path.contains('@')
        ? path.split('@').first.replaceAll(RegExp(r'/+$'), '')
        : path;
    final upper = elementPath.toUpperCase();
    if (upper.endsWith('CERTIFICATE_STATUS') ||
        upper.endsWith('CERTIFIER_NUMBER') ||
        upper.endsWith('COUNTRY')) {
      XmlPath.setNodeByPath(service, elementPath, value.id);
    } else {
      XmlPath.setNodeByPath(service, '$elementPath@type', value.id);
      if (!upper.endsWith('DURATION')) {
        final node = XmlPath.getNodeByPath(service, elementPath);
        if (node == null || !XmlPath.hasElementChildren(node)) {
          XmlPath.setNodeByPath(service, elementPath, value.label);
        }
      }
    }
    session.markFieldAsChanged(service, path);
    notifyListeners();
  }

  void setSystematik(XmlElement service, String fnamePath, CodedValue value) {
    XmlPath.setNodeByPath(service, fnamePath, value.id);
    final valuePath = fnamePath.replaceFirst(
      RegExp(r'FNAME$', caseSensitive: false),
      'FVALUE',
    );
    XmlPath.setNodeByPath(service, valuePath, value.label);
    session.markAsUpdated(service);
    notifyListeners();
  }

  void markDetailEdited(XmlElement service) {
    session.markAsUpdated(service);
    notifyListeners();
  }

  XmlElement createService({
    required LocationProfile location,
    required String mainVariant,
    CourseTypeProfile? courseType,
  }) {
    final isExtern = MainTemplateVariants.isExternenpruefung(mainVariant);
    final mainPath = templates.findMainTemplatePath(externenpruefung: isExtern);
    if (mainPath == null) {
      throw StateError('Haupttemplate nicht gefunden.');
    }

    final configurator = TemplateConfigurator()..loadMainTemplate(mainPath);
    configurator.applyLocationConfiguration(location);
    if (courseType != null) {
      configurator.applyCourseTypeConfiguration(courseType);
    }

    final created =
        session.addServiceFromConfiguredTemplate(configurator.getConfiguredTemplate());
    selectedService = created;
    statusMessage =
        'Bildungsangebot erstellt für ${location.name} ($mainVariant, ${courseType?.name ?? 'ohne Vollzeit/Teilzeit'}).';
    notifyListeners();
    return created;
  }

  XmlElement copyWith({
    required XmlElement source,
    required LocationProfile location,
    CourseTypeProfile? courseType,
  }) {
    final copied =
        session.copyServiceWithConfiguration(source, location, courseType);
    selectedService = copied;
    statusMessage =
        'Kopie erstellt für ${location.name} (${courseType?.name ?? 'unverändert'}).';
    notifyListeners();
    return copied;
  }

  XmlElement addVeranstaltung({XmlElement? source}) {
    final base = source ?? selectedService;
    if (base == null) {
      throw StateError('Bitte zuerst ein Bildungsangebot auswählen.');
    }
    final created = session.addVeranstaltungFrom(base);
    selectedService = created;
    statusMessage =
        'Veranstaltung/Termin zum Angebot ${CatalogSession.educationCourseId(created)} angelegt.';
    notifyListeners();
    return created;
  }

  void deleteSelected() {
    final service = selectedService;
    if (service == null) {
      throw StateError('Bitte Service auswählen.');
    }
    final productId = XmlPath.getChildText(service, 'PRODUCT_ID');
    if (productId == null || productId.trim().isEmpty) {
      throw StateError(
        'Dieser SERVICE hat keine PRODUCT_ID und kann nicht sauber gelöscht werden.',
      );
    }
    final title = ServiceTitleBuilder.build(service, 0);
    session.removeService(service, title);
    selectedService = null;
    statusMessage = 'SERVICE wurde entfernt.';
    notifyListeners();
  }

  XmlDocument buildValidatedExport() {
    if (session.headerTemplate == null) {
      final main = templates.loadMainTemplateSession();
      if (main != null) {
        final header = main.service.childElements.cast<XmlElement?>().firstWhere(
              (n) => n!.name.local.toLowerCase() == 'header',
              orElse: () => null,
            );
        if (header != null) session.setHeaderTemplate(header.copy());
      }
    }
    final doc = session.buildExportDocument();
    final errors = KursnetRules.validateDocument(
      doc.rootElement,
      reference: reference,
    );
    if (errors.isNotEmpty) {
      throw StateError(errors.join('\n'));
    }
    return doc;
  }

  void exportXml(String path) {
    final doc = buildValidatedExport();
    session.writeExportFile(path, doc);
    statusMessage = 'Exportiert: $path';
    notifyListeners();
  }

  List<String> validateKursnetRules() {
    final doc = session.buildExportDocument();
    return KursnetRules.validateDocument(
      doc.rootElement,
      reference: reference,
    );
  }

  Future<String> uploadToKursnet({
    required String user,
    required String password,
    required int action,
  }) async {
    final doc = buildValidatedExport();
    final temp = File(
      p.join(Directory.systemTemp.path, 'openqcat_upload.xml'),
    );
    session.writeExportFile(temp.path, doc);
    final bytes = temp.readAsBytesSync();
    final result = await kursnetClient.upload(
      xmlBytes: bytes,
      user: user,
      password: password,
      action: action,
    );
    statusMessage = action == 1
        ? 'KURSNET-Prüfung abgeschlossen.'
        : 'KURSNET-Upload abgeschlossen.';
    notifyListeners();
    return result;
  }

  Future<void> saveKursnetUser(String user) async {
    final file = File(store.credentialsPath);
    await file.writeAsString(jsonEncode({'user': user}));
  }

  String? loadSavedKursnetUser() {
    final file = File(store.credentialsPath);
    if (!file.existsSync()) return null;
    try {
      final data = jsonDecode(file.readAsStringSync());
      return data['user'] as String?;
    } catch (_) {
      return null;
    }
  }

  String? validateAgainstSchema(String xmlPath) {
    final candidates = <String>[
      XsdValidator.defaultDllPath(store.nativeDllFolder),
      p.join(Directory.current.path, 'native', 'xsd_validator.dll'),
      p.join(Directory.current.path, 'windows', 'xsd_validator.dll'),
      p.join(
        Directory.current.path,
        '..',
        'native',
        'publish',
        'xsd_validator.dll',
      ),
      p.join(p.dirname(Platform.resolvedExecutable), 'xsd_validator.dll'),
      p.join(
        p.dirname(Platform.resolvedExecutable),
        'native',
        'xsd_validator.dll',
      ),
    ];

    Object? lastError;
    for (final dllPath in candidates) {
      final normalized = p.normalize(dllPath);
      if (!File(normalized).existsSync()) continue;
      try {
        final validator = XsdValidator(normalized);
        validator.load();
        return validator.validate(xmlPath, store.schemaPath);
      } catch (e) {
        lastError = e;
      }
    }

    return lastError?.toString() ??
        'XSD-Validator DLL nicht gefunden. Bitte unter native/ mit '
            '`dotnet publish -c Release -r win-x64 -o publish` bauen und '
            'xsd_validator.dll nach flutter/native/ kopieren.';
  }

  List<String> get newServiceTitles {
    final list = <String>[];
    var i = 0;
    for (final entry in session.serviceStates.entries) {
      if (entry.value == ServiceState.neu && entry.key.parent != null) {
        list.add(ServiceTitleBuilder.build(entry.key, i, entry.value));
      }
      i++;
    }
    return list;
  }

  List<String> get updatedServiceTitles {
    final list = <String>[];
    var i = 0;
    for (final entry in session.serviceStates.entries) {
      if (entry.value == ServiceState.updated && entry.key.parent != null) {
        list.add(ServiceTitleBuilder.build(entry.key, i, entry.value));
      }
      i++;
    }
    return list;
  }

  List<String> get deletedServiceTitles => session.deletedServices
      .map((d) => '${d.productId} | ${d.title}')
      .toList();
}
