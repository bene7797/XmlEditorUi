import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:xml_editor_flutter/data/xml/xml_path.dart';
import 'package:xml_editor_flutter/domain/catalog/catalog_session.dart';
import 'package:xml_editor_flutter/domain/catalog/course_list_filter.dart';
import 'package:xml_editor_flutter/domain/catalog/models.dart';
import 'package:xml_editor_flutter/domain/dates/date_field_rules.dart';
import 'package:xml_editor_flutter/domain/fields/angebot_wizard_fields.dart';
import 'package:xml_editor_flutter/domain/fields/field_labels.dart';
import 'package:xml_editor_flutter/domain/fields/number_input.dart';
import 'package:xml_editor_flutter/domain/fields/template_field_collector.dart';
import 'package:xml_editor_flutter/domain/templates/template_configurator.dart';
import 'package:xml_editor_flutter/domain/titles/service_title_builder.dart';
import 'package:xml_editor_flutter/ui/widgets/field_form_layout.dart';
import 'package:xml_editor_flutter/ui/widgets/field_grid.dart';

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

    test('UI shows German day.month.year', () {
      expect(
        DateFieldRules.formatForUi('2027-06-01T00:00:00.000+01:00'),
        '01.06.2027',
      );
      expect(DateFieldRules.formatForUi('2026-03-14+01:00'), '14.03.2026');
    });

    test('parses German UI dates', () {
      expect(DateFieldRules.tryParse('01.06.2027'), DateTime(2027, 6, 1));
      expect(DateFieldRules.tryParse('14.03.2026'), DateTime(2026, 3, 14));
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

    test('copies ADDRESS_REMARKS from location template', () {
      const remarksPath =
          'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/ADDRESS_REMARKS';
      final service = XmlDocument.parse('''
        <SERVICE>
          <SERVICE_DETAILS><SERVICE_MODULE><EDUCATION><MODULE_COURSE>
            <LOCATION>
              <CITY>Leipzig</CITY>
              <ADDRESS_REMARKS>Leipzig alt</ADDRESS_REMARKS>
            </LOCATION>
          </MODULE_COURSE></EDUCATION></SERVICE_MODULE></SERVICE_DETAILS>
        </SERVICE>
      ''').rootElement;
      final source = XmlDocument.parse('''
        <SERVICE>
          <SERVICE_DETAILS><SERVICE_MODULE><EDUCATION><MODULE_COURSE>
            <LOCATION>
              <CITY>Kassel</CITY>
              <STREET>Richard-Roosen-Straße 9</STREET>
              <ADDRESS_REMARKS>Waldau</ADDRESS_REMARKS>
            </LOCATION>
          </MODULE_COURSE></EDUCATION></SERVICE_MODULE></SERVICE_DETAILS>
        </SERVICE>
      ''').rootElement;
      final location = LocationProfile(name: 'Kassel', values: {
        'CITY': 'Kassel',
        'STREET': 'Richard-Roosen-Straße 9',
      });
      TemplateConfigurator.applyLocationToService(
        service,
        location,
        locationSource: source,
      );
      expect(XmlPath.getTextByPath(service, remarksPath), 'Waldau');
      expect(
        XmlPath.getTextByPath(
          service,
          'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/CITY',
        ),
        'Kassel',
      );
    });

    test('overwrites existing location fields from template', () {
      const remarksPath =
          'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/ADDRESS_REMARKS';
      const barrierPath =
          'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/BARRIER_FREE_LOCATION';
      final service = XmlDocument.parse('''
        <SERVICE>
          <SERVICE_DETAILS><SERVICE_MODULE><EDUCATION><MODULE_COURSE>
            <LOCATION>
              <CITY>Leipzig</CITY>
              <ADDRESS_REMARKS>alt</ADDRESS_REMARKS>
              <BARRIER_FREE_LOCATION>true</BARRIER_FREE_LOCATION>
            </LOCATION>
          </MODULE_COURSE></EDUCATION></SERVICE_MODULE></SERVICE_DETAILS>
        </SERVICE>
      ''').rootElement;
      final source = XmlDocument.parse('''
        <SERVICE>
          <SERVICE_DETAILS><SERVICE_MODULE><EDUCATION><MODULE_COURSE>
            <LOCATION>
              <CITY>Kassel</CITY>
              <ADDRESS_REMARKS>Waldau</ADDRESS_REMARKS>
              <BARRIER_FREE_LOCATION>false</BARRIER_FREE_LOCATION>
            </LOCATION>
          </MODULE_COURSE></EDUCATION></SERVICE_MODULE></SERVICE_DETAILS>
        </SERVICE>
      ''').rootElement;
      TemplateConfigurator.applyLocationToService(
        service,
        LocationProfile(name: 'Kassel', values: {'CITY': 'Kassel'}),
        locationSource: source,
      );
      expect(XmlPath.getTextByPath(service, remarksPath), 'Waldau');
      expect(XmlPath.getTextByPath(service, barrierPath), 'false');
    });

    test('overwrites course type fields from template', () {
      const remarksPath =
          'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/INSTRUCTION_REMARKS';
      const formPath =
          'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_FORM';
      final service = XmlDocument.parse('''
        <SERVICE>
          <COURSE_TYPE>9</COURSE_TYPE>
          <SERVICE_DETAILS><SERVICE_MODULE><EDUCATION>
            <EXTENDED_INFO>
              <INSTRUCTION_TIME>Vollzeit</INSTRUCTION_TIME>
              <INSTRUCTION_FORM type="101">Präsenz</INSTRUCTION_FORM>
            </EXTENDED_INFO>
            <MODULE_COURSE>
              <INSTRUCTION_REMARKS>alt</INSTRUCTION_REMARKS>
            </MODULE_COURSE>
          </EDUCATION></SERVICE_MODULE></SERVICE_DETAILS>
        </SERVICE>
      ''').rootElement;
      final source = XmlDocument.parse('''
        <SERVICE>
          <COURSE_TYPE>1</COURSE_TYPE>
          <SERVICE_DETAILS><SERVICE_MODULE><EDUCATION>
            <EXTENDED_INFO>
              <INSTRUCTION_TIME type="2">Teilzeit</INSTRUCTION_TIME>
              <INSTRUCTION_FORM type="203">Online-Coaching</INSTRUCTION_FORM>
            </EXTENDED_INFO>
            <MODULE_COURSE>
              <INSTRUCTION_REMARKS>neu aus Template</INSTRUCTION_REMARKS>
              <DURATION type="8"/>
            </MODULE_COURSE>
          </EDUCATION></SERVICE_MODULE></SERVICE_DETAILS>
        </SERVICE>
      ''').rootElement;
      TemplateConfigurator.applyCourseTypeToService(
        service,
        CourseTypeProfile(
          name: 'Teilzeit',
          values: {
            'INSTRUCTION_TIME': 'Teilzeit',
            'INSTRUCTION_REMARKS': 'neu aus Profil',
          },
          attributes: {'INSTRUCTION_TIME@type': '2'},
        ),
        courseTypeSource: source,
      );
      expect(XmlPath.getTextByPath(service, remarksPath), 'neu aus Profil');
      expect(XmlPath.getTextByPath(service, formPath), 'Online-Coaching');
      expect(XmlPath.getTextByPath(service, '$formPath@type'), '203');
      expect(XmlPath.getTextByPath(service, 'COURSE_TYPE'), '1');
    });

    test('maps German profile key to ADDRESS_REMARKS', () {
      final service = XmlDocument.parse('<SERVICE><SERVICE_DETAILS/></SERVICE>')
          .rootElement;
      final location = LocationProfile(name: 'Kassel', values: {
        'Adress Bemerkungen': 'Waldau aus Profil',
        'CITY': 'Kassel',
      });
      TemplateConfigurator.applyLocationToService(service, location);
      expect(
        XmlPath.getTextByPath(
          service,
          'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/ADDRESS_REMARKS',
        ),
        'Waldau aus Profil',
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

    test('stripTerminFields clears location and dates on angebot', () {
      final service = _filterService(
        productId: '10',
        city: 'Leipzig',
        instructionTime: 'Vollzeit',
        educationType: 'Umschulung',
        start: '2027-02-05T00:00:00.000+01:00',
      );
      TemplateConfigurator.stripTerminFields(service);
      expect(CourseListFilter.cityOf(service), isEmpty);
      expect(
        XmlPath.getTextByPath(service, DateFieldRules.courseStartPath),
        anyOf(isNull, isEmpty),
      );
      expect(
        XmlPath.getTextByPath(service, DateFieldRules.instructionTimePath),
        anyOf(isNull, isEmpty),
      );
    });

    test('isListTermin hides angebote without start date', () {
      final stamm = _filterService(
        productId: '10',
        city: 'Leipzig',
        instructionTime: 'Vollzeit',
        educationType: 'Umschulung',
        start: '',
      );
      TemplateConfigurator.stripTerminFields(stamm);
      expect(CatalogSession.isAngebot(stamm), isTrue);
      expect(CatalogSession.isListTermin(stamm), isFalse);

      final withStart = _filterService(
        productId: '10',
        city: 'Leipzig',
        instructionTime: 'Vollzeit',
        educationType: 'Umschulung',
        start: '2027-02-05T00:00:00.000+01:00',
      );
      expect(CatalogSession.isListTermin(withStart), isTrue);

      final termin = _filterService(
        productId: '11',
        courseId: '10',
        city: 'Kassel',
        instructionTime: 'Teilzeit',
        educationType: 'Umschulung',
        start: '',
        angebot: false,
      );
      expect(CatalogSession.isListTermin(termin), isTrue);
    });

    test('addVeranstaltungFrom applies location to new termin', () {
      final session = CatalogSession(servicesTemplateFolder: '.');
      session.loadXmlString(_minimalCatalogXml());
      final angebot = session.getServiceNodes().first;
      TemplateConfigurator.stripTerminFields(angebot);
      final termin = session.addVeranstaltungFrom(
        angebot,
        location: LocationProfile(
          name: 'Kassel',
          values: {'CITY': 'Kassel', 'ZIP': '34123'},
        ),
      );
      expect(CatalogSession.isAngebot(termin), isFalse);
      expect(CourseListFilter.cityOf(termin), 'Kassel');
      expect(
        CatalogSession.educationCourseId(termin),
        XmlPath.getChildText(angebot, 'PRODUCT_ID'),
      );
    });
  });

  group('XmlPath', () {
    test('set and get attribute path', () {
      final doc = XmlDocument.parse('<SERVICE><EDUCATION/></SERVICE>');
      XmlPath.setNodeByPath(doc.rootElement, 'EDUCATION@type', 'true');
      expect(XmlPath.getTextByPath(doc.rootElement, 'EDUCATION@type'), 'true');
    });
  });

  group('CourseListFilter', () {
    test('matches city, instruction time, education kind and start date', () {
      final kassel = _filterService(
        city: 'Kassel',
        instructionTime: 'Teilzeit',
        educationType: 'Umschulung',
        start: '2027-06-01T00:00:00.000+01:00',
      );
      expect(
        const CourseListFilter(city: 'Kassel').matches(kassel),
        isTrue,
      );
      expect(
        const CourseListFilter(city: 'Leipzig').matches(kassel),
        isFalse,
      );
      expect(
        const CourseListFilter(instructionTime: InstructionTimeFilter.teilzeit)
            .matches(kassel),
        isTrue,
      );
      expect(
        const CourseListFilter(instructionTime: InstructionTimeFilter.vollzeit)
            .matches(kassel),
        isFalse,
      );
      expect(
        const CourseListFilter(educationKind: EducationKindFilter.umschulung)
            .matches(kassel),
        isTrue,
      );
      expect(
        const CourseListFilter(
          educationKind: EducationKindFilter.externenpruefung,
        ).matches(kassel),
        isFalse,
      );
      expect(
        CourseListFilter(startDate: DateTime(2027, 6, 1)).matches(kassel),
        isTrue,
      );
      expect(
        CourseListFilter(startDate: DateTime(2027, 7, 1)).matches(kassel),
        isFalse,
      );
    });

    test('keeps parent angebot when termin matches', () {
      final angebot = _filterService(
        productId: '10',
        city: 'Leipzig',
        instructionTime: 'Vollzeit',
        educationType: 'Umschulung',
        start: '2027-01-01T00:00:00.000+01:00',
        angebot: true,
      );
      final termin = _filterService(
        productId: '11',
        courseId: '10',
        city: 'Leipzig',
        instructionTime: 'Vollzeit',
        educationType: 'Umschulung',
        start: '2027-06-01T00:00:00.000+01:00',
        angebot: false,
      );
      final filtered = CourseListFilter.apply(
        items: [angebot, termin],
        serviceOf: (s) => s,
        isVeranstaltung: (s) => !CatalogSession.isAngebot(s),
        filter: CourseListFilter(startDate: DateTime(2027, 6, 1)),
      );
      expect(filtered, [angebot, termin]);
    });

    test('angebot filter ignores start date and expiry', () {
      final extern = _filterService(
        productId: '375057138',
        city: 'Kassel',
        instructionTime: 'Vollzeit',
        educationType: 'Nachholen des Berufsabschlusses',
        start: '2026-11-06T00:00:00.000+01:00',
        angebot: true,
      );
      final umschulung = _filterService(
        productId: '375057134',
        city: 'Leipzig',
        instructionTime: 'Vollzeit',
        educationType: 'Umschulung',
        start: '2027-02-05T00:00:00.000+01:00',
        angebot: true,
      );
      expect(CatalogSession.isAngebot(extern), isTrue);

      final filtered = CourseListFilter.apply(
        items: [extern, umschulung],
        serviceOf: (s) => s,
        isVeranstaltung: (_) => false,
        filter: CourseListFilter(
          startDate: DateTime(2027, 2, 5),
          todayOverride: DateTime(2026, 12, 1),
        ).forAngebote,
      );
      expect(filtered, [extern, umschulung]);
    });

    test('hides expired courses unless showExpired is set', () {
      final past = _filterService(
        city: 'Kassel',
        instructionTime: 'Vollzeit',
        educationType: 'Umschulung',
        start: '2026-01-01T00:00:00.000+01:00',
      );
      final future = _filterService(
        productId: '2',
        city: 'Kassel',
        instructionTime: 'Vollzeit',
        educationType: 'Umschulung',
        start: '2027-06-01T00:00:00.000+01:00',
      );
      final hidden = CourseListFilter(
        todayOverride: DateTime(2026, 9, 22),
      );
      expect(hidden.matches(past), isFalse);
      expect(hidden.matches(future), isTrue);

      final shown = CourseListFilter(
        showExpired: true,
        todayOverride: DateTime(2026, 9, 22),
      );
      expect(shown.matches(past), isTrue);
      expect(shown.matches(future), isTrue);
    });
  });

  group('ServiceTitleBuilder', () {
    test('neutral angebot title has only kind and id', () {
      final angebot = _filterService(
        productId: '375057134',
        city: 'Leipzig',
        instructionTime: 'Vollzeit',
        educationType: 'Umschulung',
        start: '2027-02-05T00:00:00.000+01:00',
      );
      expect(
        ServiceTitleBuilder.build(
          angebot,
          0,
          compact: true,
          neutral: true,
          includeStartDate: false,
        ),
        'Umschulung · ID: 375057134',
      );
    });
  });

  group('AngebotSuggestionIndex', () {
    test('groups identical field values from existing angebote', () {
      final first = _filterService(
        productId: '10',
        city: 'Leipzig',
        instructionTime: 'Vollzeit',
        educationType: 'Umschulung',
        start: '2027-01-01T00:00:00.000+01:00',
      );
      XmlPath.setNodeByPath(
        first,
        AngebotWizardFields.title.path,
        'Umschulung Fachinformatiker',
      );
      final index = AngebotSuggestionIndex([first]);
      final suggestions = index.forPath(AngebotWizardFields.title.path);
      expect(suggestions.single.value, 'Umschulung Fachinformatiker');
      expect(suggestions.single.sources.single, contains('ID 10'));
    });
  });

  group('FieldFormLayout', () {
    test('assigns filled fields to form sections', () {
      expect(
        FieldFormLayout.sectionIdFor(
          'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/CITY',
        ),
        'location',
      );
      expect(
        FieldFormLayout.sectionIdFor('SERVICE_DETAILS/SERVICE_DATE/START_DATE'),
        'dates',
      );
      expect(FieldFormLayout.sectionIdFor('PRODUCT_ID'), 'identity');
      expect(
        FieldFormLayout.sectionIdFor('SERVICE_DETAILS/DESCRIPTION_LONG'),
        'texts',
      );
      expect(
        FieldFormLayout.sectionIdFor(
          'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/DEGREE/DEGREE_TITLE',
        ),
        'education',
      );
      expect(
        FieldFormLayout.sectionIdFor('HEADER/CATALOG/CATALOG_NAME'),
        'header',
      );
      expect(
        FieldFormLayout.sectionIdFor('HEADER/DOCUMENT_CREATOR/LAST_NAME'),
        'header_creator',
      );
      expect(
        FieldFormLayout.sectionIdFor('HEADER/RECIPIENT/RECIPIENT_NAME'),
        'header_recipient',
      );
      expect(
        FieldFormLayout.sectionIdFor('HEADER/SUPPLIER/SUPPLIER_NAME'),
        'header_supplier',
      );
    });

    test('sorts identity fields before other leaves', () {
      FieldGridRow row(String path) => FieldGridRow(
            label: path,
            path: path,
            value: 'x',
            color: FieldRowColor.normal,
          );
      final sections = FieldFormLayout.sectionsOf([
        row('SERVICE_DETAILS/TITLE'),
        row('COURSE_ID'),
        row('PRODUCT_ID'),
      ]);
      expect(sections.first.id, 'identity');
      expect(sections.first.rows.map((r) => r.path), [
        'PRODUCT_ID',
        'COURSE_ID',
      ]);
    });

    test('pairs start/end and zip/city in one form row', () {
      FieldGridRow row(String path) => FieldGridRow(
            label: path,
            path: path,
            value: 'x',
            color: FieldRowColor.normal,
          );
      final pairs = FieldFormLayout.pairRows([
        row('SERVICE_DETAILS/SERVICE_DATE/START_DATE'),
        row('SERVICE_DETAILS/SERVICE_DATE/END_DATE'),
        row('LOCATION/ZIP'),
        row('LOCATION/CITY'),
      ]);
      expect(pairs, hasLength(2));
      expect(pairs[0].map((r) => r.path), [
        'SERVICE_DETAILS/SERVICE_DATE/START_DATE',
        'SERVICE_DETAILS/SERVICE_DATE/END_DATE',
      ]);
      expect(pairs[1].map((r) => r.path), ['LOCATION/ZIP', 'LOCATION/CITY']);
    });
  });

  group('FieldLabels', () {
    test('ADDRESS_REMARKS uses the same German name as the location template', () {
      const path =
          'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/ADDRESS_REMARKS';
      expect(FieldLabels.forPath(path), 'Adress Bemerkungen');
      expect(FieldLabels.forPath('ADDRESS_REMARKS'), 'Adress Bemerkungen');

      final service = XmlDocument.parse('''
        <SERVICE>
          <SERVICE_DETAILS>
            <SERVICE_MODULE>
              <EDUCATION>
                <MODULE_COURSE>
                  <LOCATION>
                    <ADDRESS_REMARKS>Haltestelle Torgauer Platz</ADDRESS_REMARKS>
                  </LOCATION>
                </MODULE_COURSE>
              </EDUCATION>
            </SERVICE_MODULE>
          </SERVICE_DETAILS>
        </SERVICE>
      ''').rootElement;
      final rows = TemplateFieldCollector.collectFilledFields(service);
      expect(
        rows.singleWhere((r) => r.path.toUpperCase().endsWith('ADDRESS_REMARKS')).label,
        'Adress Bemerkungen',
      );
    });
  });
}

XmlElement _filterService({
  String productId = '1',
  String? courseId,
  required String city,
  required String instructionTime,
  required String educationType,
  required String start,
  bool angebot = true,
}) {
  return XmlDocument.parse('''
    <SERVICE>
      <PRODUCT_ID>$productId</PRODUCT_ID>
      <SERVICE_DETAILS>
        <SERVICE_DATE>
          <START_DATE>$start</START_DATE>
        </SERVICE_DATE>
        <SERVICE_MODULE>
          <EDUCATION type="${angebot ? 'true' : 'false'}">
            <COURSE_ID>${courseId ?? productId}</COURSE_ID>
            <EXTENDED_INFO>
              <INSTRUCTION_TIME>$instructionTime</INSTRUCTION_TIME>
              <EDUCATION_TYPE>$educationType</EDUCATION_TYPE>
            </EXTENDED_INFO>
            <MODULE_COURSE>
              <LOCATION>
                <CITY>$city</CITY>
              </LOCATION>
            </MODULE_COURSE>
          </EDUCATION>
        </SERVICE_MODULE>
      </SERVICE_DETAILS>
    </SERVICE>
  ''').rootElement;
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
