using System.Collections.Generic;

namespace XmlEditorUi;

/// <summary>
/// Definiert die essentiellen Felder für CourseType-Vorlagen (Vollzeit, Teilzeit, Externenprüfung).
/// Diese Felder werden im Template-Editor in der DataGrid angezeigt.
/// 
/// Leicht anpassbar - einfach hier neue Felder hinzufügen oder entfernen.
/// </summary>
public static class CourseTypeTemplateFields
{
    /// <summary>
    /// Felder, die für alle CourseType-Vorlagen relevant sind.
    /// Format: (Label für UI, XPath im XML)
    /// </summary>
    public static readonly List<(string Label, string Path)> EssentialFields = new()
    {
        ("Beschäftigungsart", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_TIME"),
        ("Beschäftigungsart (type)", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_TIME@type"),
        ("Dauer (type)", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/DURATION@type"),
        ("Instrucion Remarks", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/INSTRUCTION_REMARKS"),
        ("Course Type", "COURSE_TYPE"),
        ("Education Type", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/EDUCATION_TYPE"),
    };
}
