using System.Xml;

namespace XmlEditorUi;

public class TemplateConfigurationManager
{
    private XmlDocument? currentTemplate;

    public void LoadMainTemplate(string templatePath) =>
        currentTemplate = XmlDocumentLoader.LoadFromFile(templatePath);

    public void ApplyLocationConfiguration(LocationProfile location)
    {
        EnsureLoaded();
        ApplyLocationToService(currentTemplate!.DocumentElement!, location);
    }

    public void ApplyCourseTypeConfiguration(CourseTypeProfile courseType)
    {
        EnsureLoaded();
        ApplyCourseTypeToService(currentTemplate!.DocumentElement!, courseType);
    }

    public static void ApplyLocationToService(XmlNode service, LocationProfile location)
    {
        if (!location.Values.ContainsKey("ZIPBOX")
            && location.Values.TryGetValue("ZIP", out var zip)
            && !string.IsNullOrWhiteSpace(zip))
        {
            location.Values["ZIPBOX"] = zip;
        }

        ApplyFieldMappings(service, TemplateFieldMapping.LocationFieldPaths, location.Values);
    }

    public static void ApplyCourseTypeToService(XmlNode service, CourseTypeProfile courseType)
    {
        foreach (var mapping in TemplateFieldMapping.CourseTypeFieldPaths)
        {
            if (!courseType.Values.TryGetValue(mapping.Key, out var value))
                continue;

            service.SetNodeByPath(mapping.Value, value);

            if (courseType.Attributes.TryGetValue(mapping.Key + "@type", out var attrValue))
                service.SetNodeByPath($"{mapping.Value}@type", attrValue);
        }

        foreach (var mapping in TemplateFieldMapping.CourseTypeFieldAttributes)
        {
            if (courseType.Attributes.TryGetValue(mapping.Key, out var attrValue))
                service.SetNodeByPath(mapping.Value, attrValue);
        }
    }

    public XmlDocument GetConfiguredTemplate()
    {
        EnsureLoaded();
        return currentTemplate!;
    }

    private static void ApplyFieldMappings(
        XmlNode service,
        Dictionary<string, string> mappings,
        Dictionary<string, string> values)
    {
        foreach (var mapping in mappings)
        {
            if (values.TryGetValue(mapping.Key, out var value))
                service.SetNodeByPath(mapping.Value, value);
        }
    }

    private void EnsureLoaded()
    {
        if (currentTemplate?.DocumentElement == null)
            throw new InvalidOperationException("Kein Template geladen. LoadMainTemplate() aufrufen.");
    }
}
