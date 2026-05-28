using System.Xml;

namespace XmlEditorUi;

public class TemplateConfigurationManager
{
    private XmlDocument? currentTemplate;

    public void LoadMainTemplate(string templatePath) =>
        currentTemplate = XmlDocumentLoader.LoadFromFile(templatePath);

    public void ApplyLocationConfiguration(LocationProfile location) =>
        ApplyFieldMappings(TemplateFieldMapping.LocationFieldPaths, location.Values);

    public void ApplyCourseTypeConfiguration(CourseTypeProfile courseType)
    {
        EnsureLoaded();
        var service = currentTemplate!.DocumentElement!;

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

    private void ApplyFieldMappings(Dictionary<string, string> mappings, Dictionary<string, string> values)
    {
        EnsureLoaded();

        foreach (var mapping in mappings)
        {
            if (values.TryGetValue(mapping.Key, out var value))
                currentTemplate!.DocumentElement!.SetNodeByPath(mapping.Value, value);
        }
    }

    private void EnsureLoaded()
    {
        if (currentTemplate?.DocumentElement == null)
            throw new InvalidOperationException("Kein Template geladen. LoadMainTemplate() aufrufen.");
    }
}
