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
      'Telefon',
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/PHONE',
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
      'Beschäftigungsart (type)',
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_TIME@type',
    ),
    TemplateFieldDefinition(
      'Dauer (type)',
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/DURATION@type',
    ),
    TemplateFieldDefinition(
      'Instruction Remarks',
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/INSTRUCTION_REMARKS',
    ),
    TemplateFieldDefinition('Course Type', 'COURSE_TYPE'),
    TemplateFieldDefinition(
      'Education Type',
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/EDUCATION_TYPE',
    ),
  ];
}

class HeaderTemplateFields {
  static const List<TemplateFieldDefinition> essentialFields = [
    TemplateFieldDefinition('Generator Info', 'HEADER/GENERATOR_INFO'),
    TemplateFieldDefinition('Catalog Language', 'HEADER/CATALOG/LANGUAGE'),
    TemplateFieldDefinition('Catalog ID', 'HEADER/CATALOG/CATALOG_ID'),
    TemplateFieldDefinition('Catalog Version', 'HEADER/CATALOG/CATALOG_VERSION'),
    TemplateFieldDefinition('Catalog Name', 'HEADER/CATALOG/CATALOG_NAME'),
    TemplateFieldDefinition(
      'Generation Date',
      'HEADER/CATALOG/GENERATION_DATE',
    ),
    TemplateFieldDefinition(
      'Creator First Name',
      'HEADER/DOCUMENT_CREATOR/FIRST_NAME',
    ),
    TemplateFieldDefinition(
      'Creator Last Name',
      'HEADER/DOCUMENT_CREATOR/LAST_NAME',
    ),
    TemplateFieldDefinition('Creator Phone', 'HEADER/DOCUMENT_CREATOR/PHONE'),
    TemplateFieldDefinition('Creator ID', 'HEADER/DOCUMENT_CREATOR/ID_DB'),
    TemplateFieldDefinition(
      'Creator Address Name',
      'HEADER/DOCUMENT_CREATOR/ADDRESS/NAME',
    ),
    TemplateFieldDefinition(
      'Creator Address Street',
      'HEADER/DOCUMENT_CREATOR/ADDRESS/STREET',
    ),
    TemplateFieldDefinition(
      'Creator Address ZIP',
      'HEADER/DOCUMENT_CREATOR/ADDRESS/ZIP',
    ),
    TemplateFieldDefinition(
      'Creator Address City',
      'HEADER/DOCUMENT_CREATOR/ADDRESS/CITY',
    ),
    TemplateFieldDefinition(
      'Creator Address Country',
      'HEADER/DOCUMENT_CREATOR/ADDRESS/COUNTRY',
    ),
    TemplateFieldDefinition(
      'Creator Address URL',
      'HEADER/DOCUMENT_CREATOR/ADDRESS/URL',
    ),
    TemplateFieldDefinition(
      'Creator Address ID',
      'HEADER/DOCUMENT_CREATOR/ADDRESS/ID_DB',
    ),
    TemplateFieldDefinition(
      'Creator Contact Remarks',
      'HEADER/DOCUMENT_CREATOR/CONTACT_REMARKS',
    ),
    TemplateFieldDefinition('Recipient ID', 'HEADER/RECIPIENT/RECIPIENT_ID'),
    TemplateFieldDefinition('Recipient Name', 'HEADER/RECIPIENT/RECIPIENT_NAME'),
    TemplateFieldDefinition(
      'Recipient Address Name',
      'HEADER/RECIPIENT/ADDRESS/NAME',
    ),
    TemplateFieldDefinition(
      'Recipient Address Street',
      'HEADER/RECIPIENT/ADDRESS/STREET',
    ),
    TemplateFieldDefinition(
      'Recipient Address ZIP',
      'HEADER/RECIPIENT/ADDRESS/ZIP',
    ),
    TemplateFieldDefinition(
      'Recipient Address City',
      'HEADER/RECIPIENT/ADDRESS/CITY',
    ),
    TemplateFieldDefinition(
      'Recipient Address Country',
      'HEADER/RECIPIENT/ADDRESS/COUNTRY',
    ),
    TemplateFieldDefinition(
      'Recipient Address URL',
      'HEADER/RECIPIENT/ADDRESS/URL',
    ),
    TemplateFieldDefinition('Supplier ID', 'HEADER/SUPPLIER/SUPPLIER_ID'),
    TemplateFieldDefinition('Supplier Name', 'HEADER/SUPPLIER/SUPPLIER_NAME'),
    TemplateFieldDefinition(
      'Supplier Address Name',
      'HEADER/SUPPLIER/ADDRESS/NAME',
    ),
    TemplateFieldDefinition(
      'Supplier Address Name2',
      'HEADER/SUPPLIER/ADDRESS/NAME2',
    ),
    TemplateFieldDefinition(
      'Supplier Address Street',
      'HEADER/SUPPLIER/ADDRESS/STREET',
    ),
    TemplateFieldDefinition(
      'Supplier Address ZIP',
      'HEADER/SUPPLIER/ADDRESS/ZIP',
    ),
    TemplateFieldDefinition(
      'Supplier Address City',
      'HEADER/SUPPLIER/ADDRESS/CITY',
    ),
    TemplateFieldDefinition(
      'Supplier Address State',
      'HEADER/SUPPLIER/ADDRESS/STATE',
    ),
    TemplateFieldDefinition(
      'Supplier Address Country',
      'HEADER/SUPPLIER/ADDRESS/COUNTRY',
    ),
    TemplateFieldDefinition(
      'Supplier Address Phone',
      'HEADER/SUPPLIER/ADDRESS/PHONE',
    ),
    TemplateFieldDefinition(
      'Supplier Address Mobile',
      'HEADER/SUPPLIER/ADDRESS/MOBILE',
    ),
    TemplateFieldDefinition(
      'Supplier Address Email',
      'HEADER/SUPPLIER/ADDRESS/EMAILS/EMAIL',
    ),
    TemplateFieldDefinition(
      'Supplier Address URL',
      'HEADER/SUPPLIER/ADDRESS/URL',
    ),
    TemplateFieldDefinition(
      'Supplier Contact Role',
      'HEADER/SUPPLIER/CONTACT/CONTACT_ROLE',
    ),
    TemplateFieldDefinition(
      'Supplier Contact Salutation',
      'HEADER/SUPPLIER/CONTACT/SALUTATION',
    ),
    TemplateFieldDefinition(
      'Supplier Contact First Name',
      'HEADER/SUPPLIER/CONTACT/FIRST_NAME',
    ),
    TemplateFieldDefinition(
      'Supplier Contact Last Name',
      'HEADER/SUPPLIER/CONTACT/LAST_NAME',
    ),
    TemplateFieldDefinition(
      'Supplier Contact Phone',
      'HEADER/SUPPLIER/CONTACT/PHONE',
    ),
    TemplateFieldDefinition(
      'Supplier Contact Mobile',
      'HEADER/SUPPLIER/CONTACT/MOBILE',
    ),
    TemplateFieldDefinition(
      'Supplier Contact Email',
      'HEADER/SUPPLIER/CONTACT/EMAILS/EMAIL',
    ),
    TemplateFieldDefinition(
      'Supplier Contact URL',
      'HEADER/SUPPLIER/CONTACT/URL',
    ),
    TemplateFieldDefinition(
      'Supplier Contact ID',
      'HEADER/SUPPLIER/CONTACT/ID_DB',
    ),
    TemplateFieldDefinition(
      'Supplier Contact Remarks',
      'HEADER/SUPPLIER/CONTACT/CONTACT_REMARKS',
    ),
    TemplateFieldDefinition(
      'Supplier Extended Info Input Type',
      'HEADER/SUPPLIER/EXTENDED_INFO@input_type',
    ),
    TemplateFieldDefinition(
      'Supplier Institution Number',
      'HEADER/SUPPLIER/EXTENDED_INFO/INSTITUTION_NUMBER',
    ),
    TemplateFieldDefinition(
      'Supplier Organizational Form',
      'HEADER/SUPPLIER/EXTENDED_INFO/ORGANIZATIONAL_FORM',
    ),
    TemplateFieldDefinition(
      'Supplier Organizational Form Type',
      'HEADER/SUPPLIER/EXTENDED_INFO/ORGANIZATIONAL_FORM@type',
    ),
    TemplateFieldDefinition(
      'Supplier Standard Company Number',
      'HEADER/SUPPLIER/EXTENDED_INFO/STANDARD_COMPANY_NUMBER',
    ),
  ];
}
