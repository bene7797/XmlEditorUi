import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:xml_editor_flutter/data/xml/xml_path.dart';
import 'package:xml_editor_flutter/domain/catalog/catalog_session.dart';
import 'package:xml_editor_flutter/domain/catalog/models.dart';
import 'package:xml_editor_flutter/domain/dates/date_field_rules.dart';
import 'package:xml_editor_flutter/domain/fields/number_input.dart';
import 'package:xml_editor_flutter/domain/templates/template_configurator.dart';

void main() {
  group('DateFieldRules', () {
    test('announcement end equals course start day', () {
      final service = _teilzeitService();
      DateFieldRules.applyCourseStartDefaults(
        service,
        courseStartValue: '2027-06-01T00:00:00.000+01:00',
        todayOverride: DateTime(2026, 3, 1),
      );
      expect(
        XmlPath.getTextByPath(service, DateFieldRules.announcementEndPath),
        '2027-06-01+01:00',
      );
    });

    test('announcement start is today when start within one year', () {
      final service = _teilzeitService();
      DateFieldRules.applyCourseStartDefaults(
        service,
        courseStartValue: '2026-09-01T00:00:00.000+01:00',
        todayOverride: DateTime(2026, 3, 14),
      );
      expect(
        XmlPath.getTextByPath(service, DateFieldRules.announcementStartPath),
        '2026-03-14+01:00',
      );
    });

    test('announcement start is start-1y when start more than one year away', () {
      final service = _teilzeitService();
      DateFieldRules.applyCourseStartDefaults(
        service,
        courseStartValue: '2028-06-01T00:00:00.000+01:00',
        todayOverride: DateTime(2026, 3, 14),
      );
      expect(
        XmlPath.getTextByPath(service, DateFieldRules.announcementStartPath),
        '2027-06-01+01:00',
      );
    });

    test('teilzeit end date is start + 1 year', () {
      final service = _teilzeitService();
      DateFieldRules.applyCourseStartDefaults(
        service,
        courseStartValue: '2027-02-05T00:00:00.000+01:00',
        todayOverride: DateTime(2026, 3, 14),
      );
      expect(
        XmlPath.getTextByPath(service, DateFieldRules.courseEndPath),
        '2028-02-05T00:00:00.000+01:00',
      );
    });
  });

  group('NumberInput', () {
    test('converts comma decimal to dot', () {
      expect(NumberInput.normalizeDecimal('1234,56'), '1234.56');
    });

    test('converts german thousands to xml decimal', () {
      expect(NumberInput.normalizeDecimal('1.234,56'), '1234.56');
    });

    test('leaves text with commas alone', () {
      expect(NumberInput.normalizeDecimal('Montag, Dienstag'), 'Montag, Dienstag');
    });
  });

  group('TemplateConfigurator', () {
    test('applies location ZIPBOX fallback from ZIP', () {
      final service = XmlDocument.parse('<SERVICE><SERVICE_DETAILS/></SERVICE>')
          .rootElement;
      final location = LocationProfile(name: 'Leipzig', values: {
        'CITY': 'Leipzig',
        'ZIP': '04315',
      });
      TemplateConfigurator.applyLocationToService(service, location);
      expect(location.values['ZIPBOX'], '04315');
      expect(
        XmlPath.getTextByPath(
          service,
          'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/CITY',
        ),
        'Leipzig',
      );
    });
  });

  group('CatalogSession export', () {
    test('unchanged catalog exports NEW_CATALOG FULLCATALOG', () {
      final session = CatalogSession(servicesTemplateFolder: '.');
      session.loadXmlString(_minimalCatalogXml());
      final export = session.buildExportDocument();
      final catalog = export.rootElement.childElements
          .firstWhere((e) => e.name.local == 'NEW_CATALOG');
      expect(catalog.getAttribute('FULLCATALOG'), 'true');
      expect(export.rootElement.getAttribute('version'), '1.1');
    });

    test('new service triggers UPDATE_CATALOG export', () {
      final session = CatalogSession(servicesTemplateFolder: '.');
      session.loadXmlString(_minimalCatalogXml());
      final template = XmlDocument.parse('''
        <SERVICE>
          <PRODUCT_ID>1</PRODUCT_ID>
          <SERVICE_DETAILS>
            <SERVICE_MODULE>
              <EDUCATION type="true">
                <COURSE_ID>1</COURSE_ID>
              </EDUCATION>
            </SERVICE_MODULE>
          </SERVICE_DETAILS>
        </SERVICE>
      ''');
      session.addServiceFromConfiguredTemplate(template);
      final export = session.buildExportDocument();
      expect(
        export.rootElement.childElements
            .any((e) => e.name.local == 'UPDATE_CATALOG'),
        isTrue,
      );
    });

    test('sanitize removes EMAIL under LOCATION and creates EMAILS/EMAIL', () {
      final session = CatalogSession(servicesTemplateFolder: '.');
      session.loadXmlString(_catalogWithBareEmail());
      final services = session.getActiveServices();
      expect(services, isNotEmpty);
      // Force update export path with a mark
      session.markAsUpdated(services.first);
      final export = session.buildExportDocument();
      final service = export.findAllElements('SERVICE').first;
      final location = service.findAllElements('LOCATION').first;
      expect(
        location.childElements.any((e) => e.name.local == 'EMAIL'),
        isFalse,
      );
      expect(
        location.findAllElements('EMAIL').map((e) => e.innerText).toList(),
        ['info@cdemy.de'],
      );
    });

    test('product id increments', () {
      final session = CatalogSession(servicesTemplateFolder: '.');
      session.loadXmlString(_minimalCatalogXml());
      expect(session.generateNewProductId(), '2');
    });
  });

  group('XmlPath', () {
    test('set and get attribute path', () {
      final doc = XmlDocument.parse('<SERVICE><EDUCATION/></SERVICE>');
      XmlPath.setNodeByPath(doc.rootElement, 'EDUCATION@type', 'true');
      expect(XmlPath.getTextByPath(doc.rootElement, 'EDUCATION@type'), 'true');
    });
  });
}

XmlElement _teilzeitService() {
  return XmlDocument.parse('''
    <SERVICE>
      <SERVICE_DETAILS>
        <SERVICE_DATE>
          <START_DATE></START_DATE>
          <END_DATE></END_DATE>
        </SERVICE_DATE>
        <ANNOUNCEMENT>
          <START_DATE></START_DATE>
          <END_DATE></END_DATE>
        </ANNOUNCEMENT>
        <SERVICE_MODULE>
          <EDUCATION>
            <EXTENDED_INFO>
              <INSTRUCTION_TIME>Teilzeit</INSTRUCTION_TIME>
            </EXTENDED_INFO>
            <MODULE_COURSE/>
          </EDUCATION>
        </SERVICE_MODULE>
      </SERVICE_DETAILS>
    </SERVICE>
  ''').rootElement;
}

String _minimalCatalogXml() => '''
<?xml version="1.0" encoding="utf-8"?>
<OPENQCAT version="1.1">
  <HEADER>
    <CATALOG>
      <GENERATION_DATE>2026-01-01T00:00:00.000+01:00</GENERATION_DATE>
    </CATALOG>
  </HEADER>
  <NEW_CATALOG FULLCATALOG="true">
    <SERVICE>
      <PRODUCT_ID>1</PRODUCT_ID>
      <SERVICE_DETAILS>
        <TITLE>Test</TITLE>
        <SERVICE_DATE>
          <START_DATE>2027-01-01T00:00:00.000+01:00</START_DATE>
        </SERVICE_DATE>
        <SERVICE_MODULE>
          <EDUCATION type="true">
            <COURSE_ID>1</COURSE_ID>
            <MODULE_COURSE>
              <LOCATION>
                <CITY>Leipzig</CITY>
              </LOCATION>
            </MODULE_COURSE>
            <EXTENDED_INFO>
              <INSTRUCTION_TIME>Vollzeit</INSTRUCTION_TIME>
            </EXTENDED_INFO>
          </EDUCATION>
        </SERVICE_MODULE>
      </SERVICE_DETAILS>
    </SERVICE>
  </NEW_CATALOG>
</OPENQCAT>
''';

String _catalogWithBareEmail() => '''
<?xml version="1.0" encoding="utf-8"?>
<OPENQCAT version="1.1">
  <NEW_CATALOG FULLCATALOG="true">
    <SERVICE>
      <PRODUCT_ID>1</PRODUCT_ID>
      <SERVICE_DETAILS>
        <SERVICE_MODULE>
          <EDUCATION type="true">
            <COURSE_ID>1</COURSE_ID>
            <MODULE_COURSE>
              <LOCATION>
                <CITY>Leipzig</CITY>
                <EMAIL>info@cdemy.de</EMAIL>
                <URL>https://cdemy.de</URL>
              </LOCATION>
            </MODULE_COURSE>
          </EDUCATION>
        </SERVICE_MODULE>
      </SERVICE_DETAILS>
    </SERVICE>
  </NEW_CATALOG>
</OPENQCAT>
''';
