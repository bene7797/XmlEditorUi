namespace XmlEditorUi;

public static class CourseTypeTemplateFields
{
    public static IReadOnlyList<TemplateFieldDefinition> EssentialFields { get; } =
    [
        new("Beschäftigungsart", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_TIME"),
        new("Beschäftigungsart (type)", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_TIME@type"),
        new("Dauer (type)", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/DURATION@type"),
        new("Instrucion Remarks", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/INSTRUCTION_REMARKS"),
        new("Course Type", "COURSE_TYPE"),
        new("Education Type", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/EDUCATION_TYPE"),
    ];
}
