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
        { "COUNTRY", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/COUNTRY" },
        { "PHONE", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/PHONE" },
        { "MOBILE", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/MOBILE" },
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
        { "INSTRUCTION_REMARKS", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/INSTRUCTION_REMARKS" },
        { "EDUCATION_TYPE", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/EDUCATION_TYPE" },
    };

    /// <summary>
    /// Attribute, die zusammen mit CourseType-Feldern angepasst werden.
    /// Format: "FieldName@AttributeName" 
    /// </summary>
    public static readonly Dictionary<string, string> CourseTypeFieldAttributes = new()
    {
        { "INSTRUCTION_TIME@type", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_TIME@type" },
        { "DURATION@type", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/DURATION@type" },
        { "EDUCATION_TYPE@type", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/EDUCATION_TYPE@type" },
    };

    /// <summary>
    /// Gibt an, ob dieses Feld als Attribut behandelt werden soll.
    /// Nützlich für Fields wie type="7" in den XML-Elementen.
    /// </summary>
    public static bool IsAttributeField(string fieldName) => fieldName.Contains("@");

    public static string? LookupValue(IDictionary<string, string> values, string canonicalKey)
    {
        var wanted = CompactKey(canonicalKey);
        foreach (var pair in values)
        {
            if (CanonicalKey(pair.Key) == wanted)
                return pair.Value;
        }

        return null;
    }

    private static readonly Dictionary<string, string> FieldKeyAliases = new(StringComparer.OrdinalIgnoreCase)
    {
        ["ADRESS BEMERKUNGEN"] = "ADDRESS_REMARKS",
        ["ADRESSBEMERKUNGEN"] = "ADDRESS_REMARKS",
        ["ADRESSBEMERKUNG"] = "ADDRESS_REMARKS",
        ["ADDRESS_REMARK"] = "ADDRESS_REMARKS",
        ["STRASSE"] = "STREET",
        ["STRAßE"] = "STREET",
        ["STADT"] = "CITY",
        ["BUNDESLAND"] = "STATE",
        ["TELEFON"] = "PHONE",
        ["HANDY"] = "MOBILE",
        ["MOBIL"] = "MOBILE",
        ["PLZ POSTFACH"] = "ZIPBOX",
        ["PLZ_POSTFACH"] = "ZIPBOX",
        ["LAND"] = "COUNTRY",
        ["E-MAIL"] = "EMAIL",
        ["MAIL"] = "EMAIL",
        ["BESCHÄFTIGUNGSART"] = "INSTRUCTION_TIME",
        ["BESCHAEFTIGUNGSART"] = "INSTRUCTION_TIME",
        ["UNTERRICHTSZEIT"] = "INSTRUCTION_TIME",
        ["DAUER"] = "DURATION",
        ["UNTERRICHTS BEMERKUNGEN"] = "INSTRUCTION_REMARKS",
        ["UNTERRICHTSBEMERKUNGEN"] = "INSTRUCTION_REMARKS",
        ["BILDUNGSART"] = "EDUCATION_TYPE",
    };

    private static string CanonicalKey(string raw)
    {
        var upper = raw.Trim().ToUpperInvariant();
        return CompactKey(FieldKeyAliases.TryGetValue(upper, out var alias) ? alias : upper);
    }

    private static string CompactKey(string value) =>
        value.ToUpperInvariant().Replace(" ", "").Replace("_", "");

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
