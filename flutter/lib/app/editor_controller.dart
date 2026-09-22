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
import '../data/xml/xml_file_io.dart';
import '../data/xml/xml_path.dart';
import '../domain/catalog/catalog_session.dart';
import '../domain/catalog/course_list_filter.dart';
import '../domain/catalog/models.dart';
import '../domain/dates/date_field_rules.dart';
import '../domain/fields/important_fields.dart';
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
  String? lastXsdError;
  CourseListFilter courseFilter = const CourseListFilter();

  List<CourseListEntry> get sortedCourses {
    final services = session
        .getServiceNodes()
        .where(CatalogSession.isListTermin)
        .toList();
    services.sort((a, b) {
      final cmp = DateFieldRules.getCourseStartDateOrMax(a)
          .compareTo(DateFieldRules.getCourseStartDateOrMax(b));
      if (cmp != 0) return cmp;
      return (XmlPath.getChildText(a, 'PRODUCT_ID') ?? '')
          .compareTo(XmlPath.getChildText(b, 'PRODUCT_ID') ?? '');
    });

    final result = <CourseListEntry>[];
    for (var i = 0; i < services.length; i++) {
      final service = services[i];
      result.add(
        CourseListEntry(
          service,
          ServiceTitleBuilder.build(
            service,
            i,
            asTermin: true,
            compact: true,
          ),
          isVeranstaltung: true,
        ),
      );
    }
    return result;
  }

  List<CourseListEntry> get visibleCourses => CourseListFilter.apply(
        items: sortedCourses,
        serviceOf: (item) => item.service,
        isVeranstaltung: (item) => item.isVeranstaltung,
        filter: courseFilter,
      );

  List<CourseListEntry> get sortedAngebote {
    final angebote = session
        .getServiceNodes()
        .where(CatalogSession.isAngebot)
        .toList();
    angebote.sort((a, b) {
      final kind = CourseListFilter.educationKindOf(a).label.compareTo(
            CourseListFilter.educationKindOf(b).label,
          );
      if (kind != 0) return kind;
      return (XmlPath.getChildText(a, 'PRODUCT_ID') ?? '')
          .compareTo(XmlPath.getChildText(b, 'PRODUCT_ID') ?? '');
    });

    final result = <CourseListEntry>[];
    for (var i = 0; i < angebote.length; i++) {
      final service = angebote[i];
      result.add(
        CourseListEntry(
          service,
          ServiceTitleBuilder.build(
            service,
            i,
            includeStartDate: false,
            compact: true,
            neutral: true,
          ),
        ),
      );
    }
    return result;
  }

  List<CourseListEntry> get visibleAngebote => CourseListFilter.apply(
        items: sortedAngebote,
        serviceOf: (item) => item.service,
        isVeranstaltung: (item) => item.isVeranstaltung,
        filter: courseFilter.forAngebote,
      );

  List<String> get filterCities => CourseListFilter.uniqueCities(
        session.getServiceNodes(),
      );

  List<DateTime> get filterStartDates {
    final dates = CourseListFilter.uniqueStartDates(session.getServiceNodes());
    if (courseFilter.showExpired) return dates;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return dates.where((d) => !d.isBefore(today)).toList();
  }

  void setCourseFilter(CourseListFilter value) {
    courseFilter = value;
    notifyListeners();
  }

  void clearCourseFilter() {
    courseFilter = CourseListFilter(showExpired: courseFilter.showExpired);
    notifyListeners();
  }

  void loadXml(String path) {
    session.loadXml(path);
    loadedFilePath = path;
    selectedService = null;
    courseFilter = const CourseListFilter();
    lastXsdError = validateAgainstSchema(path);
    statusMessage = lastXsdError == null
        ? 'XML geladen, XSD-Prüfung erfolgreich: $path'
        : 'XML geladen. XSD-Prüfung fehlgeschlagen: $path';
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

  XmlElement? resolveAngebot(XmlElement? service) {
    if (service == null) return null;
    if (CatalogSession.isAngebot(service)) return service;
    final courseId = CatalogSession.educationCourseId(service);
    if (courseId == null || courseId.trim().isEmpty) return null;
    for (final node in session.getServiceNodes()) {
      if (!CatalogSession.isAngebot(node)) continue;
      if (XmlPath.getChildText(node, 'PRODUCT_ID') == courseId) return node;
    }
    return null;
  }

  XmlElement createService({
    required String mainVariant,
    Map<String, String> values = const {},
  }) {
    final isExtern = MainTemplateVariants.isExternenpruefung(mainVariant);
    final mainPath = templates.findMainTemplatePath(externenpruefung: isExtern);
    if (mainPath == null) {
      throw StateError('Haupttemplate nicht gefunden.');
    }

    final configurator = TemplateConfigurator()..loadMainTemplate(mainPath);
    final template = configurator.getConfiguredTemplate();
    TemplateConfigurator.stripTerminFields(template.rootElement);
    for (final entry in values.entries) {
      final raw = entry.value.trim();
      if (raw.isEmpty) continue;
      final value = entry.key == ImportantFields.pricePath
          ? NumberInput.normalizeDecimal(raw)
          : raw;
      XmlPath.setNodeByPath(template.rootElement, entry.key, value);
    }

    final created = session.addServiceFromConfiguredTemplate(
      template,
      applyDateDefaults: false,
      pendingFields: {
        ImportantFields.titlePath,
        ImportantFields.educationTypePath,
        ImportantFields.pricePath,
      },
    );
    selectedService = created;
    statusMessage = 'Bildungsangebot erstellt ($mainVariant).';
    notifyListeners();
    return created;
  }

  XmlElement copyWith({
    required XmlElement source,
    required LocationProfile location,
    CourseTypeProfile? courseType,
  }) {
    final copied = session.copyServiceWithConfiguration(
      source,
      location,
      courseType,
      locationSource: _locationSource(location),
      courseTypeSource: _courseTypeSource(courseType),
    );
    selectedService = copied;
    statusMessage =
        'Kopie erstellt für ${location.name} (${courseType?.name ?? 'unverändert'}).';
    notifyListeners();
    return copied;
  }

  XmlElement addVeranstaltung({
    XmlElement? source,
    required LocationProfile location,
    CourseTypeProfile? courseType,
  }) {
    final base = source ?? selectedService;
    if (base == null) {
      throw StateError('Bitte zuerst ein Bildungsangebot auswählen.');
    }
    final created = session.addVeranstaltungFrom(
      base,
      location: location,
      courseType: courseType,
      locationSource: _locationSource(location),
      courseTypeSource: _courseTypeSource(courseType),
    );
    selectedService = created;
    statusMessage =
        'Termin zum Angebot ${CatalogSession.educationCourseId(created)} angelegt (${location.name}'
        '${courseType == null ? '' : ', ${courseType.name}'}).';
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

  XmlElement? _locationSource(LocationProfile location) {
    final city = location.values['CITY'] ?? location.name;
    if (city.trim().isEmpty) return null;
    return templates.findTemplateByCity(city)?.service;
  }

  XmlElement? _courseTypeSource(CourseTypeProfile? courseType) {
    if (courseType == null) return null;
    return templates.findTemplateByFileNameContains(courseType.name)?.service;
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

  /// Validates the chosen XML file as-is (no export sanitizing).
  List<String> validateKursnetRulesFile(String path) {
    final doc = XmlFileIo.loadDocument(path);
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
    final checkPath = _utf8CopyForSchema(xmlPath);
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
        return validator.validate(checkPath, store.schemaPath);
      } catch (e) {
        lastError = e;
      }
    }

    return lastError?.toString() ??
        'XSD-Validator DLL nicht gefunden. Bitte unter native/ mit '
            '`dotnet publish -c Release -r win-x64 -o publish` bauen und '
            'xsd_validator.dll nach flutter/native/ kopieren.';
  }

  /// Native XmlReader cannot honor encoding="iso-8859-15".
  static String _utf8CopyForSchema(String xmlPath) {
    final text = XmlFileIo.readText(xmlPath).replaceFirst(
      RegExp(r'''encoding\s*=\s*["'][^"']+["']''', caseSensitive: false),
      'encoding="utf-8"',
    );
    final file = File(
      p.join(Directory.systemTemp.path, 'openqcat_xsd_check.xml'),
    );
    file.writeAsStringSync(text, encoding: utf8);
    return file.path;
  }

  List<String> get newServiceTitles {
    final list = <String>[];
    var i = 0;
    for (final entry in session.serviceStates.entries) {
      if (entry.value == ServiceState.neu && entry.key.parent != null) {
        list.add(ServiceTitleBuilder.build(entry.key, i, state: entry.value));
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
        list.add(ServiceTitleBuilder.build(entry.key, i, state: entry.value));
      }
      i++;
    }
    return list;
  }

  List<String> get deletedServiceTitles => session.deletedServices
      .map((d) => '${d.productId} | ${d.title}')
      .toList();
}
