namespace XmlEditorUi;

public static class ExternenpruefungMainTemplateFields
{
    private const string Ext = "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO";
    private const string Mc = "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE";

    private static readonly TemplateFieldDefinition[] ExternOnlyFields =
    [
        new("Titel", "SERVICE_DETAILS/TITLE"),
        new("Description Long", "SERVICE_DETAILS/DESCRIPTION_LONG"),
        new("Requirements", "SERVICE_DETAILS/REQUIREMENTS"),
        new("Target Group", "SERVICE_DETAILS/TARGET_GROUP/TARGET_GROUP_TEXT"),
        new("Date Remarks", "SERVICE_DETAILS/SERVICE_DATE/DATE_REMARKS"),
        new("Education Type", $"{Ext}/EDUCATION_TYPE"),
        new("Education Type (type)", $"{Ext}/EDUCATION_TYPE@type"),
        new("Institution", $"{Ext}/INSTITUTION"),
        new("Institution (type)", $"{Ext}/INSTITUTION@type"),
        new("Instruction Form", $"{Ext}/INSTRUCTION_FORM"),
        new("Instruction Form (type)", $"{Ext}/INSTRUCTION_FORM@type"),
        new("Instruction Time", $"{Ext}/INSTRUCTION_TIME"),
        new("Instruction Time (type)", $"{Ext}/INSTRUCTION_TIME@type"),
        new("Digital Accessibility", $"{Ext}/DIGITAL_ACCESSIBILITY"),
        new("Credits", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/CREDITS"),
        new("Subsidy Description", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/SUBSIDY/SUBSIDY_DESCRIPTION"),
        new("Degree Title", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/DEGREE/DEGREE_TITLE"),
        new("Min Participants", $"{Mc}/MIN_PARTICIPANTS"),
        new("Max Participants", $"{Mc}/MAX_PARTICIPANTS"),
        new("Instruction Remarks", $"{Mc}/INSTRUCTION_REMARKS"),
        new("Duration (type)", $"{Mc}/DURATION@type"),
        new("Price", "SERVICE_PRICE_DETAILS/SERVICE_PRICE/PRICE_AMOUNT"),
        new("MIME URL (Service)", "MIME_INFO/MIME_ELEMENT/MIME_SOURCE"),
        new("Classification FNAME", "SERVICE_CLASSIFICATION/FEATURE/FNAME"),
        new("Classification FVALUE", "SERVICE_CLASSIFICATION/FEATURE/FVALUE"),
        new("Announcement Start", "SERVICE_DETAILS/ANNOUNCEMENT/START_DATE"),
        new("Announcement End", "SERVICE_DETAILS/ANNOUNCEMENT/END_DATE"),
    ];

    public static IReadOnlyList<TemplateFieldDefinition> EssentialFields { get; } =
    [
        ..LocationTemplateFields.EssentialFields,
        ..ExternOnlyFields,
    ];
}
