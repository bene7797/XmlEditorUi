import '../catalog/models.dart';

class ImportantFields {
  static const titlePath = 'SERVICE_DETAILS/TITLE';
  static const educationTypePath =
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/EDUCATION_TYPE';
  static const pricePath =
      'SERVICE_PRICE_DETAILS/SERVICE_PRICE/PRICE_AMOUNT';

  static const List<QuickFieldDefinition> list = [
    QuickFieldDefinition(
      'Startdatum Kurs',
      'SERVICE_DETAILS/SERVICE_DATE/START_DATE',
    ),
    QuickFieldDefinition(
      'Enddatum Kurs',
      'SERVICE_DETAILS/SERVICE_DATE/END_DATE',
    ),
    QuickFieldDefinition(
      'Ankündigung Start',
      'SERVICE_DETAILS/ANNOUNCEMENT/START_DATE',
    ),
    QuickFieldDefinition(
      'Ankündigung Ende',
      'SERVICE_DETAILS/ANNOUNCEMENT/END_DATE',
    ),
    QuickFieldDefinition('Preis', pricePath),
  ];

  static const List<QuickFieldDefinition> angebot = [
    QuickFieldDefinition('Titel', titlePath),
    QuickFieldDefinition('Bildungsart', educationTypePath),
    QuickFieldDefinition('Preis', pricePath),
  ];

  static List<QuickFieldDefinition> forService({required bool isAngebot}) =>
      isAngebot ? angebot : list;
}
