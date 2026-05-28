namespace XmlEditorUi;

public static class MainTemplateFields
{
    public const string KeywordsContainerPath = "SERVICE_DETAILS";

    private static readonly TemplateFieldDefinition[] MainOnlyFields =
    [
        new("Description Long", "SERVICE_DETAILS/DESCRIPTION_LONG"),
    ];

    public static IReadOnlyList<TemplateFieldDefinition> EssentialFields { get; } =
    [
        ..CourseTypeTemplateFields.EssentialFields,
        ..LocationTemplateFields.EssentialFields,
        ..MainOnlyFields,
    ];
}
