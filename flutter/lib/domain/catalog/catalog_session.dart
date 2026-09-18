import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../../data/xml/xml_file_io.dart';
import '../../data/xml/xml_path.dart';
import '../dates/date_field_rules.dart';
import '../fields/important_fields.dart';
import '../kursnet/kursnet_rules.dart';
import '../templates/template_configurator.dart';
import 'models.dart';

/// Port of C# XmlServiceManager — catalog load, CRUD, export, sanitizing.
class CatalogSession {
  CatalogSession({
    required this.servicesTemplateFolder,
    List<QuickFieldDefinition>? importantFields,
  }) : importantFields = importantFields ?? ImportantFields.list;

  static const _invalidEducationExtendedInfoElements = [
    'DURATION',
    'INSTRUCTION_REMARKS',
  ];

  static const _addressElementOrder = [
    'NAME',
    'NAME2',
    'NAME3',
    'STREET',
    'ZIP',
    'BOXNO',
    'ZIPBOX',
    'CITY',
    'DISTRICT',
    'STATE',
    'COUNTRY_CODED',
    'COUNTRY',
    'PHONE',
    'MOBILE',
    'FAX',
    'EMAILS',
    'URL',
    'ADDRESS_REMARKS',
    'BARRIER_FREE_LOCATION',
    'ID_DB',
  ];

  final String servicesTemplateFolder;
  final List<QuickFieldDefinition> importantFields;

  final Map<XmlElement, ServiceState> serviceStates = {};
  final List<DeletedServiceInfo> deletedServices = [];
  final Map<XmlElement, Set<String>> pendingTemplateFields = {};
  final Map<XmlElement, Set<String>> changedImportantFields = {};

  XmlDocument? document;
  XmlElement? headerTemplate;

  bool get isLoaded => document != null;

  void setHeaderTemplate(XmlElement? header) => headerTemplate = header;

  void loadXml(String path) {
    document = XmlFileIo.loadDocument(path);
    serviceStates.clear();
    deletedServices.clear();
    pendingTemplateFields.clear();
    changedImportantFields.clear();
    _captureHeaderFromDocument();
  }

  /// Test/helper: load from XML string.
  void loadXmlString(String xml) {
    document = XmlDocument.parse(xml);
    serviceStates.clear();
    deletedServices.clear();
    pendingTemplateFields.clear();
    changedImportantFields.clear();
    _captureHeaderFromDocument();
  }

  List<XmlElement> getServiceNodes() {
    if (document == null) return [];
    return XmlPath.descendantElements(document!)
        .where(XmlPath.isServiceNode)
        .toList();
  }

  List<XmlElement> getActiveServices() {
    _ensureLoaded();
    return XmlPath.descendantElements(document!)
        .where(XmlPath.isServiceNode)
        .where((n) => n.parent != null)
        .toList();
  }

  XmlElement addServiceFromConfiguredTemplate(XmlDocument configuredTemplate) {
    _ensureLoaded();
    final imported = configuredTemplate.rootElement.copy();

    final newProductId = generateNewProductId();
    XmlPath.setChildText(imported, 'PRODUCT_ID', newProductId);
    _syncCourseIdWithProductId(imported);
    _applyServiceModeForWorkingCopy(imported);

    final insertParent = _getServiceInsertParent();
    if (insertParent == null) {
      throw StateError('Weder NEW_CATALOG noch UPDATE_CATALOG gefunden.');
    }
    insertParent.children.add(imported);

    serviceStates[imported] = ServiceState.neu;
    pendingTemplateFields[imported] =
        importantFields.map((f) => f.path).toSet();
    _applyStartDateDefaults(imported);
    return imported;
  }

  XmlElement copyServiceWithConfiguration(
    XmlElement sourceService,
    LocationProfile location,
    CourseTypeProfile? courseType,
  ) {
    _ensureLoaded();
    final insertParent = _getServiceInsertParent();
    if (insertParent == null) {
      throw StateError('Weder NEW_CATALOG noch UPDATE_CATALOG gefunden.');
    }

    final copied = sourceService.copy();
    final newProductId = generateNewProductId();
    XmlPath.setChildText(copied, 'PRODUCT_ID', newProductId);
    _syncCourseIdWithProductId(copied);
    _applyServiceModeForWorkingCopy(copied);

    TemplateConfigurator.applyLocationToService(copied, location);
    if (courseType != null) {
      TemplateConfigurator.applyCourseTypeToService(copied, courseType);
    }

    insertParent.children.add(copied);
    serviceStates[copied] = ServiceState.neu;
    pendingTemplateFields[copied] =
        importantFields.map((f) => f.path).toSet();
    _applyStartDateDefaults(copied);
    return copied;
  }

  static bool isAngebot(XmlElement service) {
    final education = XmlPath.getNodeByPath(
      service,
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION',
    );
    return (education?.getAttribute('type') ?? 'true').toLowerCase() == 'true';
  }

  static String? educationCourseId(XmlElement service) => XmlPath.getTextByPath(
        service,
        'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/COURSE_ID',
      );

  XmlElement addVeranstaltungFrom(XmlElement source) {
    _ensureLoaded();
    final insertParent = _getServiceInsertParent();
    if (insertParent == null) {
      throw StateError('Weder NEW_CATALOG noch UPDATE_CATALOG gefunden.');
    }

    final parentProductId = isAngebot(source)
        ? (XmlPath.getChildText(source, 'PRODUCT_ID') ?? '')
        : (educationCourseId(source) ?? '');
    if (parentProductId.trim().isEmpty) {
      throw StateError(
        'Kein Bildungsangebot gefunden, dem die Veranstaltung zugeordnet werden kann.',
      );
    }

    final copied = source.copy();
    final newProductId = generateNewProductId();
    XmlPath.setChildText(copied, 'PRODUCT_ID', newProductId);

    final education = XmlPath.getNodeByPath(
      copied,
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION',
    );
    if (education == null) {
      throw StateError('SERVICE hat kein EDUCATION-Element.');
    }
    education.setAttribute('type', 'false');
    XmlPath.setChildText(education, 'COURSE_ID', parentProductId);
    _applyServiceModeForWorkingCopy(copied);

    insertParent.children.add(copied);
    serviceStates[copied] = ServiceState.neu;
    pendingTemplateFields[copied] = {
      'SERVICE_DETAILS/SERVICE_DATE/START_DATE',
      'SERVICE_DETAILS/SERVICE_DATE/END_DATE',
      'SERVICE_DETAILS/ANNOUNCEMENT/START_DATE',
      'SERVICE_DETAILS/ANNOUNCEMENT/END_DATE',
    };
    return copied;
  }

  void removeService(XmlElement service, String title) {
    _ensureLoaded();
    final productId = XmlPath.getChildText(service, 'PRODUCT_ID');
    if (productId == null || productId.trim().isEmpty) {
      throw StateError(
        'Dieser SERVICE hat keine PRODUCT_ID und kann nicht sauber gelöscht werden.',
      );
    }

    final isNewService = serviceStates[service] == ServiceState.neu;
    final updateCatalog = _getUpdateCatalogNode();

    if (updateCatalog != null && !isNewService) {
      final deleteNode = _getOrCreateUpdateChild('DELETE');
      deleteNode.children.add(
        XmlElement(XmlName('SERVICE'), [], [
          XmlElement(XmlName('PRODUCT_ID'), [], [XmlText(productId)]),
        ]),
      );
      deletedServices.add(DeletedServiceInfo(productId, title));
      service.parent?.children.remove(service);
      serviceStates.remove(service);
      return;
    }

    service.parent?.children.remove(service);
    serviceStates.remove(service);
    if (!isNewService) {
      deletedServices.add(DeletedServiceInfo(productId, title));
    }
  }

  void markFieldAsChanged(XmlElement service, String path) {
    changedImportantFields.putIfAbsent(service, () => <String>{}).add(path);
    pendingTemplateFields[service]?.remove(path);
    serviceStates.putIfAbsent(service, () => ServiceState.unchanged);
    if (serviceStates[service] == ServiceState.unchanged) {
      serviceStates[service] = ServiceState.updated;
    }
  }

  void markAsUpdated(XmlElement service) {
    serviceStates.putIfAbsent(service, () => ServiceState.unchanged);
    if (serviceStates[service] == ServiceState.unchanged) {
      serviceStates[service] = ServiceState.updated;
    }
  }

  String generateNewProductId() {
    _ensureLoaded();
    final existingIds = <int>{};
    for (final node in XmlPath.descendantElements(document!)) {
      if (node.name.local.toLowerCase() != 'product_id') continue;
      final v = int.tryParse(node.innerText.trim());
      if (v != null) existingIds.add(v);
    }
    if (existingIds.isEmpty) return '1';
    var nextId = existingIds.reduce((a, b) => a > b ? a : b) + 1;
    while (existingIds.contains(nextId)) {
      nextId++;
    }
    return nextId.toString();
  }

  XmlDocument buildExportDocument() {
    _ensureLoaded();
    return _shouldUseUpdateCatalogExport()
        ? _buildUpdateCatalogExport()
        : _buildNewCatalogExport();
  }

  /// Writes export with iso-8859-15 declaration (latin1-compatible body).
  void writeExportFile(String path, XmlDocument exportDoc) {
    var xml = exportDoc.toXmlString(pretty: true, indent: '  ');
    if (!xml.startsWith('<?xml')) {
      xml =
          '<?xml version="1.0" encoding="iso-8859-15" standalone="yes"?>\n$xml';
    } else {
      xml = xml.replaceFirst(
        RegExp(r'<\?xml[^?]*\?>'),
        '<?xml version="1.0" encoding="iso-8859-15" standalone="yes"?>',
      );
    }
    File(path).writeAsBytesSync(latin1.encode(xml));
  }

  bool _shouldUseUpdateCatalogExport() {
    if (deletedServices.isNotEmpty) return true;
    return serviceStates.values
        .any((s) => s == ServiceState.neu || s == ServiceState.updated);
  }

  XmlDocument _buildNewCatalogExport() {
    final exportDoc = _createExportShell();
    final root = exportDoc.rootElement;
    _appendExportHeader(exportDoc, root);

    final catalog = XmlElement(XmlName('NEW_CATALOG'));
    catalog.setAttribute('FULLCATALOG', 'true');
    root.children.add(catalog);

    for (final service in getActiveServices()) {
      final imported = service.copy();
      _sanitizeServiceForExport(imported);
      _applyServiceModeForExport(imported, isUpdateCatalogExport: false);
      catalog.children.add(imported);
    }
    return exportDoc;
  }

  XmlDocument _buildUpdateCatalogExport() {
    final exportDoc = _createExportShell();
    final root = exportDoc.rootElement;
    _appendExportHeader(exportDoc, root);

    final catalog = XmlElement(XmlName('UPDATE_CATALOG'));
    catalog.setAttribute('seq_number', '${_getNextUpdateCatalogSeqNumber()}');
    root.children.add(catalog);

    if (deletedServices.isNotEmpty) {
      final deleteNode = XmlElement(XmlName('DELETE'));
      catalog.children.add(deleteNode);
      for (final deleted in deletedServices) {
        deleteNode.children.add(
          XmlElement(XmlName('SERVICE'), [], [
            XmlElement(
              XmlName('PRODUCT_ID'),
              [],
              [XmlText(deleted.productId)],
            ),
          ]),
        );
      }
    }

    final servicesToExport = getActiveServices().where((service) {
      final state = serviceStates[service];
      return state == ServiceState.neu || state == ServiceState.updated;
    }).toList();

    if (servicesToExport.isNotEmpty) {
      final newNode = XmlElement(XmlName('NEW'));
      catalog.children.add(newNode);
      for (final service in servicesToExport) {
        final imported = service.copy();
        _sanitizeServiceForExport(imported);
        _applyServiceModeForExport(
          imported,
          isUpdateCatalogExport: true,
          state: serviceStates[service],
        );
        newNode.children.add(imported);
      }
    }
    return exportDoc;
  }

  XmlDocument _createExportShell() {
    final root = XmlElement(XmlName('OPENQCAT'), [
      XmlAttribute(XmlName('version'), '1.1'),
      XmlAttribute(
        XmlName('xmlns:xsi'),
        'http://www.w3.org/2001/XMLSchema-instance',
      ),
      XmlAttribute(
        XmlName('xsi:noNamespaceSchemaLocation'),
        'openQ-cat.V1.1.xsd',
      ),
    ]);
    return XmlDocument([
      XmlProcessing('xml', 'version="1.0" encoding="iso-8859-15" standalone="yes"'),
      root,
    ]);
  }

  int _getNextUpdateCatalogSeqNumber() {
    final updateCatalog = _getUpdateCatalogNode();
    final value = updateCatalog?.getAttribute('seq_number');
    if (value != null) {
      final current = int.tryParse(value);
      if (current != null) return current + 1;
    }
    return 1;
  }

  void _applyServiceModeForWorkingCopy(XmlElement service) {
    if (_getUpdateCatalogNode() != null) {
      service.setAttribute('mode', 'new');
    } else {
      service.removeAttribute('mode');
    }
  }

  void _applyServiceModeForExport(
    XmlElement service, {
    required bool isUpdateCatalogExport,
    ServiceState? state,
  }) {
    if (!isUpdateCatalogExport) {
      service.removeAttribute('mode');
      return;
    }
    if (state == ServiceState.neu) {
      service.setAttribute('mode', 'new');
    } else {
      service.removeAttribute('mode');
    }
  }

  void _appendExportHeader(XmlDocument exportDoc, XmlElement root) {
    if (headerTemplate == null) return;
    final importedHeader = headerTemplate!.copy();
    _ensureSupplierRequiredContent(importedHeader);
    KursnetRules.sanitizeHeader(importedHeader);
    _applyExportGenerationDate(importedHeader);
    // Keep the in-memory header in sync so re-exports stay complete.
    headerTemplate = importedHeader.copy();
    root.children.insert(0, importedHeader);
  }

  /// XSD requires SUPPLIER/EXTENDED_INFO (minOccurs=1). Incomplete headers
  /// from older exports or stale AppData templates are enriched from Main.xml.
  void _ensureSupplierRequiredContent(XmlElement header) {
    final supplier = header.childElements.cast<XmlElement?>().firstWhere(
          (n) => n!.name.local.toLowerCase() == 'supplier',
          orElse: () => null,
        );
    if (supplier == null) return;

    final hasExtendedInfo = supplier.childElements.any(
      (n) => n.name.local.toLowerCase() == 'extended_info',
    );
    final hasKeyword = supplier.childElements.any(
      (n) => n.name.local.toLowerCase() == 'keyword',
    );
    if (hasExtendedInfo && hasKeyword) return;

    final templateSupplier = _loadMainTemplateSupplier();
    if (templateSupplier != null) {
      if (!hasKeyword) {
        for (final keyword in templateSupplier.childElements.where(
          (n) => n.name.local.toLowerCase() == 'keyword',
        )) {
          supplier.children.add(keyword.copy());
        }
      }
      if (!hasExtendedInfo) {
        final extended = templateSupplier.childElements.cast<XmlElement?>().firstWhere(
              (n) => n!.name.local.toLowerCase() == 'extended_info',
              orElse: () => null,
            );
        if (extended != null) {
          supplier.children.add(extended.copy());
          return;
        }
      } else {
        return;
      }
    }

    if (hasExtendedInfo) return;

    final supplierId =
        XmlPath.getChildText(supplier, 'SUPPLIER_ID')?.trim() ?? '';
    supplier.children.add(
      XmlElement(
        XmlName('EXTENDED_INFO'),
        [XmlAttribute(XmlName('input_type'), '0')],
        [
          if (supplierId.isNotEmpty)
            XmlElement(
              XmlName('INSTITUTION_NUMBER'),
              [],
              [XmlText(supplierId)],
            ),
          XmlElement(
            XmlName('ORGANIZATIONAL_FORM'),
            [XmlAttribute(XmlName('type'), '2')],
            [XmlText('Private Bildungseinrichtung')],
          ),
        ],
      ),
    );
  }

  XmlElement? _loadMainTemplateSupplier() {
    final file = File(p.join(servicesTemplateFolder, 'Main.xml'));
    if (!file.existsSync()) return null;
    try {
      final doc = XmlDocument.parse(file.readAsStringSync());
      final service = doc.rootElement;
      final header = service.childElements.cast<XmlElement?>().firstWhere(
            (n) => n!.name.local.toLowerCase() == 'header',
            orElse: () => null,
          );
      if (header == null) return null;
      return header.childElements.cast<XmlElement?>().firstWhere(
            (n) => n!.name.local.toLowerCase() == 'supplier',
            orElse: () => null,
          );
    } catch (_) {
      return null;
    }
  }

  void _applyExportGenerationDate(XmlElement header) {
    final catalog = header.childElements.cast<XmlElement?>().firstWhere(
          (n) => n!.name.local.toLowerCase() == 'catalog',
          orElse: () => null,
        );
    if (catalog == null) return;

    final value = _formatGenerationDate(DateTime.now());
    final generationDate =
        catalog.childElements.cast<XmlElement?>().firstWhere(
              (n) => n!.name.local.toLowerCase() == 'generation_date',
              orElse: () => null,
            );
    if (generationDate != null) {
      generationDate.children
        ..clear()
        ..add(XmlText(value));
      return;
    }
    catalog.children.add(
      XmlElement(XmlName('GENERATION_DATE'), [], [XmlText(value)]),
    );
  }

  String _formatGenerationDate(DateTime dateTime) {
    final offset = dateTime.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final mins = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final y = dateTime.year.toString().padLeft(4, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final d = dateTime.day.toString().padLeft(2, '0');
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    final ss = dateTime.second.toString().padLeft(2, '0');
    final ms = dateTime.millisecond.toString().padLeft(3, '0');
    return '$y-$m-$d'
        'T$hh:$mm:$ss.$ms$sign$hours:$mins';
  }

  void _captureHeaderFromDocument() {
    final root = document?.rootElement;
    if (root == null) return;
    if (root.name.local.toLowerCase() != 'openqcat') return;
    final header = root.childElements.cast<XmlElement?>().firstWhere(
          (n) => n!.name.local.toLowerCase() == 'header',
          orElse: () => null,
        );
    if (header != null) headerTemplate = header.copy();
  }

  void _sanitizeServiceForExport(XmlElement service) {
    _removeHeaderFromService(service);
    _removeInvalidEducationExtendedInfoElements(service);
    _normalizeLocationEmailElements(service);
    _syncCourseIdWithProductId(service);
    KursnetRules.sanitizeService(service);
  }

  void _syncCourseIdWithProductId(XmlElement service) {
    final education = XmlPath.getNodeByPath(
      service,
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION',
    );
    if (education == null) return;
    final typeAttr = education.getAttribute('type');
    if (typeAttr == null || typeAttr.toLowerCase() != 'true') return;
    final productId = XmlPath.getChildText(service, 'PRODUCT_ID');
    if (productId == null || productId.trim().isEmpty) return;
    XmlPath.setChildText(education, 'COURSE_ID', productId);
  }

  void _removeHeaderFromService(XmlElement service) {
    for (final header in service.childElements
        .where((n) => n.name.local.toLowerCase() == 'header')
        .toList()) {
      service.children.remove(header);
    }
  }

  void _removeInvalidEducationExtendedInfoElements(XmlElement service) {
    final extendedInfo = XmlPath.getNodeByPath(
      service,
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO',
    );
    if (extendedInfo == null) return;
    for (final node in extendedInfo.childElements
        .where(
          (n) => _invalidEducationExtendedInfoElements
              .any((e) => e.toLowerCase() == n.name.local.toLowerCase()),
        )
        .toList()) {
      extendedInfo.children.remove(node);
    }
  }

  void _normalizeLocationEmailElements(XmlElement service) {
    final locations = XmlPath.descendantElements(service)
        .where((n) => n.name.local.toLowerCase() == 'location')
        .toList();

    for (final location in locations) {
      for (final emailNode in location.childElements
          .where((n) => n.name.local.toLowerCase() == 'email')
          .toList()) {
        final emailValue = emailNode.innerText;
        location.children.remove(emailNode);
        if (emailValue.trim().isEmpty) continue;

        var emailsContainer = XmlPath.findChild(location, 'EMAILS');
        if (emailsContainer == null) {
          emailsContainer = XmlElement(XmlName('EMAILS'));
          _insertAddressElementBefore(location, emailsContainer, 'URL');
        }

        final hasEmail = emailsContainer.childElements
            .any((n) => n.name.local.toLowerCase() == 'email');
        if (!hasEmail) {
          emailsContainer.children.add(
            XmlElement(XmlName('EMAIL'), [], [XmlText(emailValue)]),
          );
        }
      }
    }
  }

  void _insertAddressElementBefore(
    XmlElement location,
    XmlElement newElement,
    String beforeElementName,
  ) {
    final beforeIndex =
        _addressElementOrder.indexOf(beforeElementName.toUpperCase());
    if (beforeIndex < 0) {
      location.children.add(newElement);
      return;
    }

    XmlElement? insertBefore;
    for (final child in location.childElements) {
      final childIndex =
          _addressElementOrder.indexOf(child.name.local.toUpperCase());
      if (childIndex >= 0 && childIndex >= beforeIndex) {
        insertBefore = child;
        break;
      }
    }

    if (insertBefore != null) {
      final index = location.children.indexOf(insertBefore);
      location.children.insert(index, newElement);
    } else {
      location.children.add(newElement);
    }
  }

  XmlElement? _findCatalogNode(String name) {
    if (document == null) return null;
    return XmlPath.descendantElements(document!).cast<XmlElement?>().firstWhere(
          (n) => n!.name.local.toLowerCase() == name.toLowerCase(),
          orElse: () => null,
        );
  }

  XmlElement? _getNewCatalogNode() => _findCatalogNode('NEW_CATALOG');
  XmlElement? _getUpdateCatalogNode() => _findCatalogNode('UPDATE_CATALOG');

  XmlElement _getOrCreateUpdateChild(String childName) {
    final updateCatalog = _getUpdateCatalogNode();
    if (updateCatalog == null) {
      throw StateError('Kein UPDATE_CATALOG gefunden.');
    }

    final existing = updateCatalog.childElements.cast<XmlElement?>().firstWhere(
          (n) => n!.name.local.toLowerCase() == childName.toLowerCase(),
          orElse: () => null,
        );
    if (existing != null) return existing;

    final newNode = XmlElement(XmlName(childName));
    if (childName.toLowerCase() == 'delete') {
      final newElement =
          updateCatalog.childElements.cast<XmlElement?>().firstWhere(
                (n) => n!.name.local.toLowerCase() == 'new',
                orElse: () => null,
              );
      if (newElement != null) {
        final index = updateCatalog.children.indexOf(newElement);
        updateCatalog.children.insert(index, newNode);
      } else {
        updateCatalog.children.add(newNode);
      }
    } else {
      updateCatalog.children.add(newNode);
    }
    return newNode;
  }

  XmlElement? _getServiceInsertParent() {
    final newCatalog = _getNewCatalogNode();
    if (newCatalog != null) return newCatalog;

    final updateCatalog = _getUpdateCatalogNode();
    if (updateCatalog == null) return null;

    final existingNew =
        updateCatalog.childElements.cast<XmlElement?>().firstWhere(
              (n) => n!.name.local.toLowerCase() == 'new',
              orElse: () => null,
            );
    if (existingNew != null) return existingNew;

    final created = XmlElement(XmlName('NEW'));
    updateCatalog.children.add(created);
    return created;
  }

  void _applyStartDateDefaults(XmlElement service) {
    for (final path in DateFieldRules.applyCourseStartDefaults(service)) {
      markFieldAsChanged(service, path);
    }
  }

  void _ensureLoaded() {
    if (document == null) {
      throw StateError('Bitte zuerst XML öffnen.');
    }
  }
}
