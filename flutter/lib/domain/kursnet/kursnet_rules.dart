import 'package:xml/xml.dart';

import '../../data/reference/openq_reference.dart';
import '../../data/xml/xml_path.dart';

/// Extra KURSNET rules beyond the XSD (Leitfaden + BA upload checks).
class KursnetRules {
  KursnetRules._();

  static final phonePattern = RegExp(r'^\+[0-9]+\.[0-9]+\.?[0-9]*$');

  static const _phoneNames = {'PHONE', 'FAX', 'MOBILE'};

  static void sanitizeDocument(XmlElement root) {
    for (final node in XmlPath.descendantElements(root).toList()) {
      _normalizeCountry(node);
      _removeEmptyPhoneFields(node);
      _removeEmptyCertValidity(node);
    }
    final header = XmlPath.findChild(root, 'HEADER');
    if (header != null) sanitizeHeader(header);
  }

  static void sanitizeHeader(XmlElement header) {
    _ensureDocumentCreator(header);
    _ensureSupplierContactRole(header);
    for (final node in XmlPath.descendantElements(header).toList()) {
      _normalizeCountry(node);
      _removeEmptyPhoneFields(node);
    }
  }

  static void sanitizeService(XmlElement service) {
    for (final node in XmlPath.descendantElements(service).toList()) {
      _normalizeCountry(node);
      _removeEmptyPhoneFields(node);
      _removeEmptyCertValidity(node);
    }
  }

  static List<String> validateDocument(
    XmlElement root, {
    OpenqReference? reference,
  }) {
    final errors = <String>[];
    if (root.name.local.toLowerCase() != 'openqcat') {
      errors.add(
        'Wurzelelement muss OPENQCAT sein (gefunden: <${root.name.local}>). '
        'Ohne Katalog-HEADER unter OPENQCAT ist die Datei für KURSNET ungültig.',
      );
    }

    // Only the HEADER directly under OPENQCAT counts — not HEADER inside SERVICE.
    final header = root.name.local.toLowerCase() == 'openqcat'
        ? XmlPath.findChild(root, 'HEADER')
        : null;
    if (header == null) {
      errors.add(
        'HEADER fehlt als Kind von OPENQCAT. '
        'Ein HEADER nur innerhalb eines SERVICE zählt nicht.',
      );
    } else {
      errors.addAll(validateHeader(header));
    }

    final services = XmlPath.descendantElements(root)
        .where(XmlPath.isServiceNode)
        .toList();
    for (final service in services) {
      errors.addAll(validateService(service, reference: reference));
    }
    return errors;
  }

  static List<String> validateHeader(XmlElement header) {
    final errors = <String>[];
    if (XmlPath.findChild(header, 'CATALOG') == null) {
      errors.add('HEADER/CATALOG fehlt.');
    }

    final creator = XmlPath.findChild(header, 'DOCUMENT_CREATOR');
    if (creator != null &&
        (XmlPath.getChildText(creator, 'LAST_NAME') ?? '').isEmpty) {
      errors.add('DOCUMENT_CREATOR/LAST_NAME darf nicht leer sein.');
    }

    final supplier = XmlPath.findChild(header, 'SUPPLIER');
    if (supplier == null) {
      errors.add('HEADER/SUPPLIER fehlt.');
      return errors;
    }

    _requireAddress(XmlPath.findChild(supplier, 'ADDRESS'), 'SUPPLIER/ADDRESS', errors);

    final contacts = supplier.childElements
        .where((n) => n.name.local.toLowerCase() == 'contact')
        .toList();
    if (contacts.isEmpty) {
      errors.add('HEADER/SUPPLIER/CONTACT fehlt.');
    } else {
      for (final contact in contacts) {
        _requireContactCore(contact, 'SUPPLIER/CONTACT', errors);
      }
    }

    final extended = XmlPath.findChild(supplier, 'EXTENDED_INFO');
    if (extended == null) {
      errors.add('HEADER/SUPPLIER/EXTENDED_INFO ist Pflicht.');
    } else if (extended.getAttribute('input_type') == null) {
      errors.add('HEADER/SUPPLIER/EXTENDED_INFO/@input_type ist Pflicht.');
    } else if (XmlPath.findChild(extended, 'ORGANIZATIONAL_FORM')
            ?.getAttribute('type') ==
        null) {
      errors.add(
        'HEADER/SUPPLIER/EXTENDED_INFO/ORGANIZATIONAL_FORM/@type ist Pflicht.',
      );
    }

    _collectPhoneErrors(header, 'HEADER', errors);
    return errors;
  }

  static List<String> validateService(
    XmlElement service, {
    OpenqReference? reference,
  }) {
    final errors = <String>[];
    final productId = XmlPath.getChildText(service, 'PRODUCT_ID') ?? '';
    final prefix = productId.isEmpty ? 'SERVICE' : 'SERVICE $productId';

    final education = XmlPath.getNodeByPath(
      service,
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION',
    );
    final typeAttr = education?.getAttribute('type')?.toLowerCase() ?? 'true';
    final isAngebot = typeAttr == 'true';
    final courseId = education == null
        ? null
        : XmlPath.getChildText(education, 'COURSE_ID');

    if (isAngebot) {
      if (courseId == null || courseId != productId) {
        errors.add(
          '$prefix: Bildungsangebot (EDUCATION/@type=true) braucht '
          'COURSE_ID = PRODUCT_ID.',
        );
      }
      final title = XmlPath.getTextByPath(service, 'SERVICE_DETAILS/TITLE');
      if (title == null || title.trim().isEmpty) {
        errors.add('$prefix: SERVICE_DETAILS/TITLE ist für Angebote Pflicht.');
      }
    } else if (courseId == null || courseId.isEmpty || courseId == productId) {
      errors.add(
        '$prefix: Veranstaltung (EDUCATION/@type=false) braucht COURSE_ID '
        'des zugehörigen Bildungsangebots, ungleich PRODUCT_ID.',
      );
    }

    for (final contact in XmlPath.descendantElements(service).where(
      (n) => n.name.local.toLowerCase() == 'contact',
    )) {
      _requireContactCore(contact, '$prefix/CONTACT', errors);
    }

    for (final address in XmlPath.descendantElements(service).where((n) {
      final name = n.name.local.toLowerCase();
      return name == 'address' || name == 'location';
    })) {
      _requireAddress(address, '$prefix/${address.name.local}', errors);
      if (reference != null && address.name.local.toLowerCase() == 'location') {
        final zip = XmlPath.getChildText(address, 'ZIP') ?? '';
        final city = XmlPath.getChildText(address, 'CITY') ?? '';
        if (zip.isNotEmpty &&
            city.isNotEmpty &&
            !reference.isKnownPlace(zip, city)) {
          errors.add(
            '$prefix: PLZ/Ort "$zip $city" steht nicht in der KURSNET-Ortsliste.',
          );
        }
      }
    }

    _collectPhoneErrors(service, prefix, errors);
    return errors;
  }

  static void _requireContactCore(
    XmlElement contact,
    String label,
    List<String> errors, {
    bool requireRole = true,
  }) {
    if (requireRole) {
      final role = XmlPath.findChild(contact, 'CONTACT_ROLE');
      if (role == null || (role.getAttribute('type') ?? '').isEmpty) {
        errors.add('$label/CONTACT_ROLE/@type ist Pflicht.');
      }
    }
    if ((XmlPath.getChildText(contact, 'SALUTATION') ?? '').isEmpty) {
      errors.add('$label/SALUTATION ist Pflicht.');
    }
    if ((XmlPath.getChildText(contact, 'LAST_NAME') ?? '').isEmpty) {
      errors.add('$label/LAST_NAME darf nicht leer sein.');
    }
    if ((XmlPath.getChildText(contact, 'PHONE') ?? '').isEmpty) {
      errors.add('$label/PHONE ist Pflicht.');
    }
  }

  static void _requireAddress(
    XmlElement? address,
    String label,
    List<String> errors,
  ) {
    if (address == null) {
      errors.add('$label fehlt.');
      return;
    }
    if ((XmlPath.getChildText(address, 'NAME') ?? '').isEmpty) {
      errors.add('$label/NAME ist Pflicht.');
    }
    if ((XmlPath.getChildText(address, 'CITY') ?? '').isEmpty) {
      errors.add('$label/CITY ist Pflicht.');
    }
    if ((XmlPath.getChildText(address, 'ZIP') ?? '').isEmpty) {
      errors.add('$label/ZIP ist Pflicht.');
    }
  }

  static void _collectPhoneErrors(
    XmlElement root,
    String prefix,
    List<String> errors,
  ) {
    for (final node in XmlPath.descendantElements(root)) {
      final name = node.name.local.toUpperCase();
      if (!_phoneNames.contains(name)) continue;
      final value = node.innerText.trim();
      if (value.isEmpty) {
        // KURSNET itself exports empty <FAX></FAX>; only filled numbers are checked.
        continue;
      }
      if (!phonePattern.hasMatch(value)) {
        errors.add(
          '$prefix: <$name> "$value" muss dem Muster +49.1234.5678 entsprechen.',
        );
      }
    }
  }

  static void _normalizeCountry(XmlElement node) {
    if (node.name.local.toLowerCase() != 'country') return;
    final value = node.innerText.trim().toLowerCase();
    if (value == 'deutschland' ||
        value == 'germany' ||
        value == 'd' ||
        value == 'de') {
      node.children
        ..clear()
        ..add(XmlText('DE'));
    }
  }

  static void _removeEmptyPhoneFields(XmlElement node) {
    final name = node.name.local.toUpperCase();
    if (!_phoneNames.contains(name)) return;
    if (node.innerText.trim().isNotEmpty) return;
    node.parent?.children.remove(node);
  }

  static void _removeEmptyCertValidity(XmlElement node) {
    if (node.name.local.toLowerCase() != 'cert_validity') return;
    if (node.innerText.trim().isNotEmpty || node.childElements.isNotEmpty) {
      return;
    }
    node.parent?.children.remove(node);
  }

  static void _ensureDocumentCreator(XmlElement header) {
    final creator = XmlPath.findChild(header, 'DOCUMENT_CREATOR');
    if (creator == null) return;
    if (XmlPath.findChild(creator, 'SALUTATION') == null) {
      final first = XmlPath.findChild(creator, 'FIRST_NAME');
      final salutation = XmlElement(
        XmlName('SALUTATION'),
        [],
        [XmlText('m')],
      );
      if (first != null) {
        creator.children.insert(creator.children.indexOf(first), salutation);
      } else {
        creator.children.insert(0, salutation);
      }
    }
    if (XmlPath.getTextByPath(creator, 'EMAILS/EMAIL')?.trim().isEmpty ??
        true) {
      final existingEmails = XmlPath.findChild(creator, 'EMAILS');
      if (existingEmails != null) {
        XmlPath.setNodeByPath(creator, 'EMAILS/EMAIL', 'info@cdemy.de');
      } else {
        final emails = XmlElement(XmlName('EMAILS'), [], [
          XmlElement(XmlName('EMAIL'), [], [XmlText('info@cdemy.de')]),
        ]);
        final phone = XmlPath.findChild(creator, 'PHONE');
        if (phone != null) {
          final index = creator.children.indexOf(phone);
          creator.children.insert(index + 1, emails);
        } else {
          creator.children.add(emails);
        }
      }
    }
  }

  static void _ensureSupplierContactRole(XmlElement header) {
    final supplier = XmlPath.findChild(header, 'SUPPLIER');
    if (supplier == null) return;
    final contacts = supplier.childElements
        .where((n) => n.name.local.toLowerCase() == 'contact')
        .toList();
    if (contacts.isEmpty) return;
    final hasRequired = contacts.any((c) {
      final type = XmlPath.findChild(c, 'CONTACT_ROLE')?.getAttribute('type');
      return type == '2' || type == '3';
    });
    if (hasRequired) return;
    final role = XmlPath.findChild(contacts.first, 'CONTACT_ROLE');
    if (role == null) {
      contacts.first.children.insert(
        0,
        XmlElement(
          XmlName('CONTACT_ROLE'),
          [XmlAttribute(XmlName('type'), '3')],
          [XmlText('Leiter des Betriebs')],
        ),
      );
      return;
    }
    role.setAttribute('type', '3');
    role.children
      ..clear()
      ..add(XmlText('Leiter des Betriebs'));
  }
}
