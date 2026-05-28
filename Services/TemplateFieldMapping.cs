using System.Collections.Generic;

namespace XmlEditorUi;

/// <summary>
/// Definiert, welche Felder für Location- und CourseType-Profile relevant sind
/// und wie sie im XML-Template aktualisiert werden.
/// 
/// Erleichtert die Anpassung des Templatesystems - einfach hier bearbeiten, welche Felder
/// für welche Konfiguration wichtig sind.
/// </summary>
public class TemplateFieldMapping
{
    /// <summary>
    /// XML-Pfade der Location-Felder, die aus den Location-Profilen angepasst werden.
    /// Format: "FieldName" -> "XPath im XML"
    /// 
    /// Beispiel: {"STREET"} -> wird angepasst in SERVICE_DETAILS/SERVICE_MODULE/.../LOCATION/STREET
    /// </summary>
    public static readonly Dictionary<string, string> LocationFieldPaths = new()
    {
        { "NAME", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/NAME" },
        { "NAME2", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/NAME2" },
        { "STREET", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/STREET" },
        { "ZIP", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/ZIP" },
        { "ZIPBOX", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/ZIPBOX" },
        { "CITY", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/CITY" },
        { "STATE", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/STATE" },
        { "PHONE", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/PHONE" },
        { "EMAIL", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/EMAILS/EMAIL" },
        { "URL", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/URL" },
        { "ADDRESS_REMARKS", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/ADDRESS_REMARKS" },
    };

    /// <summary>
    /// XML-Pfade der CourseType-Felder, die aus den CourseType-Profilen angepasst werden.
    /// </summary>
    public static readonly Dictionary<string, string> CourseTypeFieldPaths = new()
    {
        { "COURSE_TYPE", "COURSE_TYPE" },
        { "INSTRUCTION_TIME", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_TIME" },
        { "DURATION", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/DURATION" },
    };

    /// <summary>
    /// Attribute, die zusammen mit CourseType-Feldern angepasst werden.
    /// Format: "FieldName@AttributeName" 
    /// </summary>
    public static readonly Dictionary<string, string> CourseTypeFieldAttributes = new()
    {
        { "INSTRUCTION_TIME@type", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_TIME@type" },
        { "DURATION@type", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/DURATION@type" },
    };

    /// <summary>
    /// Gibt an, ob dieses Feld als Attribut behandelt werden soll.
    /// Nützlich für Fields wie type="7" in den XML-Elementen.
    /// </summary>
    public static bool IsAttributeField(string fieldName) => fieldName.Contains("@");

    /// <summary>
    /// Extrahiert den Element-Namen und Attribute-Namen aus einem Field-Namen.
    /// z.B. "INSTRUCTION_TIME@type" -> ("INSTRUCTION_TIME", "type")
    /// </summary>
    public static (string element, string? attribute) ParseFieldName(string fieldName)
    {
        var parts = fieldName.Split('@');
        return (parts[0], parts.Length > 1 ? parts[1] : null);
    }
}
