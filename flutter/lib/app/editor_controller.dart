import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

import '../data/assets/app_data_store.dart';
import '../data/profiles/profile_repository.dart';
import '../data/templates/service_template_repository.dart';
import '../data/xml/xml_path.dart';
import '../domain/catalog/catalog_session.dart';
import '../domain/catalog/models.dart';
import '../domain/dates/date_field_rules.dart';
import '../domain/templates/main_template_variants.dart';
import '../domain/templates/template_configurator.dart';
import '../domain/titles/service_title_builder.dart';
import '../ffi/xsd_validator.dart';

class CourseListEntry {
  CourseListEntry(this.service, this.title);

  final XmlElement service;
  final String title;
}

/// App-wide session state for the Flutter editor.
class EditorController extends ChangeNotifier {
  EditorController(this.store)
      : session = CatalogSession(servicesTemplateFolder: store.servicesFolder),
        templates = ServiceTemplateRepository(store.servicesFolder),
        profiles = ProfileRepository(store.profilesFolder);

  final AppDataStore store;
  final CatalogSession session;
  final ServiceTemplateRepository templates;
  final ProfileRepository profiles;

  XmlElement? selectedService;
  String? loadedFilePath;
  String? statusMessage;

  List<CourseListEntry> get sortedCourses {
    final services = session.getServiceNodes();
    services.sort((a, b) {
      final da = DateFieldRules.getCourseStartDateOrMax(a);
      final db = DateFieldRules.getCourseStartDateOrMax(b);
      final cmp = da.compareTo(db);
      if (cmp != 0) return cmp;
      final idA = XmlPath.getChildText(a, 'PRODUCT_ID') ?? '';
      final idB = XmlPath.getChildText(b, 'PRODUCT_ID') ?? '';
      return idA.compareTo(idB);
    });

    final result = <CourseListEntry>[];
    for (var i = 0; i < services.length; i++) {
      final state = session.serviceStates[services[i]];
      result.add(
        CourseListEntry(
          services[i],
          ServiceTitleBuilder.build(services[i], i, state),
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
    XmlPath.setNodeByPath(service, path, value);
    session.markFieldAsChanged(service, path);

    if (DateFieldRules.isCourseStartPath(path)) {
      for (final changed
          in DateFieldRules.applyCourseStartDefaults(service, courseStartValue: value)) {
        session.markFieldAsChanged(service, changed);
      }
    }

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
        'Service erstellt für ${location.name} ($mainVariant, ${courseType?.name ?? 'ohne Vollzeit/Teilzeit'}).';
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

  void exportXml(String path) {
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
    session.writeExportFile(path, doc);
    statusMessage = 'Exportiert: $path';
    notifyListeners();
  }

  String? validateAgainstSchema(String xmlPath) {
    final validator = XsdValidator(
      XsdValidator.defaultDllPath(store.nativeDllFolder),
    );
    try {
      validator.load();
      return validator.validate(xmlPath, store.schemaPath);
    } catch (e) {
      return e.toString();
    }
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
