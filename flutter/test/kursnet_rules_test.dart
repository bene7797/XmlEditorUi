import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:xml_editor_flutter/domain/kursnet/kursnet_rules.dart';

void main() {
  group('KursnetRules HEADER', () {
    test('rejects OPENQCAT without HEADER', () {
      final doc = XmlDocument.parse('''
<OPENQCAT>
  <NEW_CATALOG>
    <SERVICE><PRODUCT_ID>1</PRODUCT_ID></SERVICE>
  </NEW_CATALOG>
</OPENQCAT>
''');
      final errors = KursnetRules.validateDocument(doc.rootElement);
      expect(
        errors.any((e) => e.contains('HEADER fehlt')),
        isTrue,
        reason: errors.join('\n'),
      );
    });

    test('does not treat SERVICE-HEADER as catalog HEADER', () {
      final doc = XmlDocument.parse('''
<OPENQCAT>
  <NEW_CATALOG>
    <SERVICE>
      <HEADER>
        <CATALOG><LANGUAGE>deu</LANGUAGE><CATALOG_ID>x</CATALOG_ID><CATALOG_VERSION>1</CATALOG_VERSION></CATALOG>
        <SUPPLIER>
          <SUPPLIER_NAME>Test</SUPPLIER_NAME>
          <ADDRESS><NAME>A</NAME><ZIP>34123</ZIP><CITY>Kassel</CITY></ADDRESS>
          <CONTACT>
            <CONTACT_ROLE type="5">Sonstige</CONTACT_ROLE>
            <SALUTATION>m</SALUTATION>
            <LAST_NAME>Höfer</LAST_NAME>
            <PHONE>+49.561.1</PHONE>
          </CONTACT>
          <EXTENDED_INFO input_type="0">
            <ORGANIZATIONAL_FORM type="2">Privat</ORGANIZATIONAL_FORM>
          </EXTENDED_INFO>
        </SUPPLIER>
      </HEADER>
      <PRODUCT_ID>1</PRODUCT_ID>
    </SERVICE>
  </NEW_CATALOG>
</OPENQCAT>
''');
      final errors = KursnetRules.validateDocument(doc.rootElement);
      expect(
        errors.any((e) => e.contains('HEADER fehlt')),
        isTrue,
        reason: errors.join('\n'),
      );
    });
  });
}
