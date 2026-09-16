import '../catalog/models.dart';

class ImportantFields {
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
    QuickFieldDefinition(
      'Preis',
      'SERVICE_PRICE_DETAILS/SERVICE_PRICE/PRICE_AMOUNT',
    ),
  ];
}
