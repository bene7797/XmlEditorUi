using System.Xml;

namespace XmlEditorUi;

public class TemplateConfigurationManager
{
    private XmlDocument? currentTemplate;

    public void LoadMainTemplate(string templatePath) =>
        currentTemplate = XmlDocumentLoader.LoadFromFile(templatePath);

    public void ApplyLocationConfiguration(LocationProfile location, XmlNode? locationSource = null)
    {
        EnsureLoaded();
        ApplyLocationToService(currentTemplate!.DocumentElement!, location, locationSource);
    }

    public void ApplyCourseTypeConfiguration(CourseTypeProfile courseType, XmlNode? courseTypeSource = null)
    {
        EnsureLoaded();
        ApplyCourseTypeToService(currentTemplate!.DocumentElement!, courseType, courseTypeSource);
    }

    public static void ApplyLocationToService(
        XmlNode service,
        LocationProfile location,
        XmlNode? locationSource = null)
    {
        if (locationSource != null)
        {
            CopySubtree(
                service,
                locationSource,
                "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION");
        }

        if (TemplateFieldMapping.LookupValue(location.Values, "ZIPBOX") == null
            && TemplateFieldMapping.LookupValue(location.Values, "ZIP") is { } zip
            && !string.IsNullOrWhiteSpace(zip))
        {
            location.Values["ZIPBOX"] = zip;
        }

        if (TemplateFieldMapping.LookupValue(location.Values, "COUNTRY") == null)
            location.Values.TryAdd("COUNTRY", "DE");

        ApplyFieldMappings(
            service,
            TemplateFieldMapping.LocationFieldPaths,
            location.Values,
            locationSource);
    }

    public static void ApplyCourseTypeToService(
        XmlNode service,
        CourseTypeProfile courseType,
        XmlNode? courseTypeSource = null)
    {
        foreach (var mapping in TemplateFieldMapping.CourseTypeFieldPaths)
        {
            var value = TemplateFieldMapping.LookupValue(courseType.Values, mapping.Key)
                ?? courseTypeSource?.GetTextByPath(mapping.Value);
            if (value == null)
                continue;

            service.SetNodeByPath(mapping.Value, value);

            if (courseType.Attributes.TryGetValue(mapping.Key + "@type", out var attrValue)
                || (attrValue = courseTypeSource?.GetTextByPath($"{mapping.Value}@type")) != null)
            {
                service.SetNodeByPath($"{mapping.Value}@type", attrValue);
            }
        }

        foreach (var mapping in TemplateFieldMapping.CourseTypeFieldAttributes)
        {
            if (courseType.Attributes.TryGetValue(mapping.Key, out var attrValue)
                || (attrValue = courseTypeSource?.GetTextByPath(mapping.Value)) != null)
            {
                service.SetNodeByPath(mapping.Value, attrValue);
            }
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
        Dictionary<string, string> values,
        XmlNode? fallbackSource)
    {
        foreach (var mapping in mappings)
        {
            var value = TemplateFieldMapping.LookupValue(values, mapping.Key)
                ?? fallbackSource?.GetTextByPath(mapping.Value);
            if (value != null)
                service.SetNodeByPath(mapping.Value, value);
        }
    }

    private static void CopySubtree(XmlNode target, XmlNode source, string path)
    {
        var sourceNode = source.GetNodeByPath(path);
        if (sourceNode == null)
            return;

        var targetNode = target.GetNodeByPath(path);
        if (targetNode?.ParentNode == null || target.OwnerDocument == null)
            return;

        var imported = target.OwnerDocument.ImportNode(sourceNode, deep: true);
        targetNode.ParentNode.ReplaceChild(imported, targetNode);
    }

    private void EnsureLoaded()
    {
        if (currentTemplate?.DocumentElement == null)
            throw new InvalidOperationException("Kein Template geladen. LoadMainTemplate() aufrufen.");
    }
}
