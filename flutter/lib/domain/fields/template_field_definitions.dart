import '../catalog/models.dart';

class LocationTemplateFields {
  static const List<TemplateFieldDefinition> essentialFields = [
    TemplateFieldDefinition(
      'Name',
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/NAME',
    ),
    TemplateFieldDefinition(
      'Name 2',
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/NAME2',
    ),
    TemplateFieldDefinition(
      'Strasse',
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/STREET',
    ),
    TemplateFieldDefinition(
      'PLZ',
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/ZIP',
    ),
    TemplateFieldDefinition(
      'PLZ Postfach',
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/ZIPBOX',
    ),
    TemplateFieldDefinition(
      'Stadt',
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/CITY',
    ),
    TemplateFieldDefinition(
      'Bundesland',
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/STATE',
    ),
    TemplateFieldDefinition(
      'Land',
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/COUNTRY',
    ),
    TemplateFieldDefinition(
      'Telefon',
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/PHONE',
    ),
    TemplateFieldDefinition(
      'Mobil',
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/MOBILE',
    ),
    TemplateFieldDefinition(
      'Email',
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/EMAILS/EMAIL',
    ),
    TemplateFieldDefinition(
      'URL',
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/URL',
    ),
    TemplateFieldDefinition(
      'Adress Bemerkungen',
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/ADDRESS_REMARKS',
    ),
  ];
}

class CourseTypeTemplateFields {
  static const List<TemplateFieldDefinition> essentialFields = [
    TemplateFieldDefinition(
      'Beschäftigungsart',
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_TIME',
    ),
    TemplateFieldDefinition(
      'Beschäftigungsart-Code',
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_TIME@type',
    ),
    TemplateFieldDefinition(
      'Dauer-Code',
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/DURATION@type',
    ),
    TemplateFieldDefinition(
      'Unterrichtsbemerkungen',
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/INSTRUCTION_REMARKS',
    ),
    TemplateFieldDefinition('Kurstyp', 'COURSE_TYPE'),
    TemplateFieldDefinition(
      'Angebot oder Termin',
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION@type',
    ),
    TemplateFieldDefinition(
      'Bildungsart',
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/EDUCATION_TYPE',
    ),
  ];
}

class HeaderTemplateFields {
  static const List<TemplateFieldDefinition> essentialFields = [
    TemplateFieldDefinition('Generator', 'HEADER/GENERATOR_INFO'),
    TemplateFieldDefinition('Katalogsprache', 'HEADER/CATALOG/LANGUAGE'),
    TemplateFieldDefinition('Katalog-ID', 'HEADER/CATALOG/CATALOG_ID'),
    TemplateFieldDefinition('Katalogversion', 'HEADER/CATALOG/CATALOG_VERSION'),
    TemplateFieldDefinition('Katalogname', 'HEADER/CATALOG/CATALOG_NAME'),
    TemplateFieldDefinition('Erstellungsdatum', 'HEADER/CATALOG/GENERATION_DATE'),
    TemplateFieldDefinition(
      'Ersteller Vorname',
      'HEADER/DOCUMENT_CREATOR/FIRST_NAME',
    ),
    TemplateFieldDefinition(
      'Ersteller Nachname',
      'HEADER/DOCUMENT_CREATOR/LAST_NAME',
    ),
    TemplateFieldDefinition('Ersteller Telefon', 'HEADER/DOCUMENT_CREATOR/PHONE'),
    TemplateFieldDefinition('Ersteller-ID', 'HEADER/DOCUMENT_CREATOR/ID_DB'),
    TemplateFieldDefinition(
      'Ersteller Name',
      'HEADER/DOCUMENT_CREATOR/ADDRESS/NAME',
    ),
    TemplateFieldDefinition(
      'Ersteller Strasse',
      'HEADER/DOCUMENT_CREATOR/ADDRESS/STREET',
    ),
    TemplateFieldDefinition(
      'Ersteller PLZ',
      'HEADER/DOCUMENT_CREATOR/ADDRESS/ZIP',
    ),
    TemplateFieldDefinition(
      'Ersteller Stadt',
      'HEADER/DOCUMENT_CREATOR/ADDRESS/CITY',
    ),
    TemplateFieldDefinition(
      'Ersteller Land',
      'HEADER/DOCUMENT_CREATOR/ADDRESS/COUNTRY',
    ),
    TemplateFieldDefinition(
      'Ersteller URL',
      'HEADER/DOCUMENT_CREATOR/ADDRESS/URL',
    ),
    TemplateFieldDefinition(
      'Ersteller Adress-ID',
      'HEADER/DOCUMENT_CREATOR/ADDRESS/ID_DB',
    ),
    TemplateFieldDefinition(
      'Ersteller Bemerkungen',
      'HEADER/DOCUMENT_CREATOR/CONTACT_REMARKS',
    ),
    TemplateFieldDefinition('Empfänger-ID', 'HEADER/RECIPIENT/RECIPIENT_ID'),
    TemplateFieldDefinition('Empfänger Name', 'HEADER/RECIPIENT/RECIPIENT_NAME'),
    TemplateFieldDefinition(
      'Empfänger Adresse',
      'HEADER/RECIPIENT/ADDRESS/NAME',
    ),
    TemplateFieldDefinition(
      'Empfänger Strasse',
      'HEADER/RECIPIENT/ADDRESS/STREET',
    ),
    TemplateFieldDefinition(
      'Empfänger PLZ',
      'HEADER/RECIPIENT/ADDRESS/ZIP',
    ),
    TemplateFieldDefinition(
      'Empfänger Stadt',
      'HEADER/RECIPIENT/ADDRESS/CITY',
    ),
    TemplateFieldDefinition(
      'Empfänger Land',
      'HEADER/RECIPIENT/ADDRESS/COUNTRY',
    ),
    TemplateFieldDefinition(
      'Empfänger URL',
      'HEADER/RECIPIENT/ADDRESS/URL',
    ),
    TemplateFieldDefinition('Anbieter-ID', 'HEADER/SUPPLIER/SUPPLIER_ID'),
    TemplateFieldDefinition('Anbieter Name', 'HEADER/SUPPLIER/SUPPLIER_NAME'),
    TemplateFieldDefinition(
      'Anbieter Adresse',
      'HEADER/SUPPLIER/ADDRESS/NAME',
    ),
    TemplateFieldDefinition(
      'Anbieter Adresse 2',
      'HEADER/SUPPLIER/ADDRESS/NAME2',
    ),
    TemplateFieldDefinition(
      'Anbieter Strasse',
      'HEADER/SUPPLIER/ADDRESS/STREET',
    ),
    TemplateFieldDefinition(
      'Anbieter PLZ',
      'HEADER/SUPPLIER/ADDRESS/ZIP',
    ),
    TemplateFieldDefinition(
      'Anbieter Stadt',
      'HEADER/SUPPLIER/ADDRESS/CITY',
    ),
    TemplateFieldDefinition(
      'Anbieter Bundesland',
      'HEADER/SUPPLIER/ADDRESS/STATE',
    ),
    TemplateFieldDefinition(
      'Anbieter Land',
      'HEADER/SUPPLIER/ADDRESS/COUNTRY',
    ),
    TemplateFieldDefinition(
      'Anbieter Telefon',
      'HEADER/SUPPLIER/ADDRESS/PHONE',
    ),
    TemplateFieldDefinition(
      'Anbieter Mobil',
      'HEADER/SUPPLIER/ADDRESS/MOBILE',
    ),
    TemplateFieldDefinition(
      'Anbieter Email',
      'HEADER/SUPPLIER/ADDRESS/EMAILS/EMAIL',
    ),
    TemplateFieldDefinition(
      'Anbieter URL',
      'HEADER/SUPPLIER/ADDRESS/URL',
    ),
    TemplateFieldDefinition(
      'Kontakt Rolle',
      'HEADER/SUPPLIER/CONTACT/CONTACT_ROLE',
    ),
    TemplateFieldDefinition(
      'Kontakt Rolle (Code)',
      'HEADER/SUPPLIER/CONTACT/CONTACT_ROLE@type',
    ),
    TemplateFieldDefinition(
      'Kontakt Anrede',
      'HEADER/SUPPLIER/CONTACT/SALUTATION',
    ),
    TemplateFieldDefinition(
      'Kontakt Vorname',
      'HEADER/SUPPLIER/CONTACT/FIRST_NAME',
    ),
    TemplateFieldDefinition(
      'Kontakt Nachname',
      'HEADER/SUPPLIER/CONTACT/LAST_NAME',
    ),
    TemplateFieldDefinition(
      'Kontakt Telefon',
      'HEADER/SUPPLIER/CONTACT/PHONE',
    ),
    TemplateFieldDefinition(
      'Kontakt Mobil',
      'HEADER/SUPPLIER/CONTACT/MOBILE',
    ),
    TemplateFieldDefinition(
      'Kontakt Email',
      'HEADER/SUPPLIER/CONTACT/EMAILS/EMAIL',
    ),
    TemplateFieldDefinition(
      'Kontakt URL',
      'HEADER/SUPPLIER/CONTACT/URL',
    ),
    TemplateFieldDefinition(
      'Kontakt-ID',
      'HEADER/SUPPLIER/CONTACT/ID_DB',
    ),
    TemplateFieldDefinition(
      'Kontakt Bemerkungen',
      'HEADER/SUPPLIER/CONTACT/CONTACT_REMARKS',
    ),
    TemplateFieldDefinition(
      'Anbieter Eingabeart',
      'HEADER/SUPPLIER/EXTENDED_INFO@input_type',
    ),
    TemplateFieldDefinition(
      'Institutionsnummer',
      'HEADER/SUPPLIER/EXTENDED_INFO/INSTITUTION_NUMBER',
    ),
    TemplateFieldDefinition(
      'Organisationsform',
      'HEADER/SUPPLIER/EXTENDED_INFO/ORGANIZATIONAL_FORM',
    ),
    TemplateFieldDefinition(
      'Organisationsform-Code',
      'HEADER/SUPPLIER/EXTENDED_INFO/ORGANIZATIONAL_FORM@type',
    ),
    TemplateFieldDefinition(
      'Betriebsnummer',
      'HEADER/SUPPLIER/EXTENDED_INFO/STANDARD_COMPANY_NUMBER',
    ),
  ];
}
