using System.Collections.Generic;

namespace XmlEditorUi;

/// <summary>
/// Definiert die essentiellen Felder für Location-Vorlagen (Leipzig, Kassel, etc.).
/// Diese Felder werden im Template-Editor in der DataGrid angezeigt.
/// 
/// Leicht anpassbar - einfach hier neue Felder hinzufügen oder entfernen.
/// </summary>
public static class LocationTemplateFields
{
    /// <summary>
    /// Felder, die für alle Location-Vorlagen relevant sind.
    /// Format: (Label für UI, XPath im XML)
    /// </summary>
    public static readonly List<(string Label, string Path)> EssentialFields = new()
    {
        ("Name", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/NAME"),
        ("Name 2", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/NAME2"),
        ("Straße", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/STREET"),
        ("PLZ", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/ZIP"),
        ("Stadt", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/CITY"),
        ("Bundesland", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/STATE"),
        ("Telefon", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/PHONE"),
        ("Email", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/EMAIL"),
        ("URL", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/URL"),
        ("Adress Bemerkungen", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/ADDRESS_REMARKS"),
    };
}
