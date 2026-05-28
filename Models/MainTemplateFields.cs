using System.Xml;

namespace XmlEditorUi;

public static class MainTemplateFields
{
    public const string KeywordsContainerPath = "SERVICE_DETAILS";

    public static IReadOnlyList<TemplateFieldDefinition> GetFieldsForService(XmlNode service) =>
        TemplateFieldCollector.CollectFromService(service);
}
