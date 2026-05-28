namespace XmlEditorUi;

/// <summary>
/// Felder für das Main-Template (Beschäftigungsart, Ort, Schlagwörter).
/// </summary>
public static class MainTemplateFields
{
    public const string KeywordsContainerPath = "SERVICE_DETAILS";

    public static IEnumerable<(string Label, string Path)> EssentialFields =>
        CourseTypeTemplateFields.EssentialFields
            .Concat(LocationTemplateFields.EssentialFields);
}
