using System.Collections.Generic;

namespace XmlEditorUi;

public static class ImportantFields
{
    public static readonly List<QuickFieldDefinition> List = new()
    {
        new("Produkt-ID", "PRODUCT_ID"),
        new("Startdatum Kurs", "SERVICE_DETAILS/SERVICE_DATE/START_DATE"),
        new("Enddatum Kurs", "SERVICE_DETAILS/SERVICE_DATE/END_DATE"),
        new("Ankündigung Start", "SERVICE_DETAILS/ANNOUNCEMENT/START_DATE"),
        new("Ankündigung Ende", "SERVICE_DETAILS/ANNOUNCEMENT/END_DATE"),
        new("Min. Teilnehmer", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/MIN_PARTICIPANTS"),
        new("Max. Teilnehmer", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/MAX_PARTICIPANTS"),
        new("Preis", "SERVICE_PRICE_DETAILS/SERVICE_PRICE/PRICE_AMOUNT")
    };
}
