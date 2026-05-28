namespace XmlEditorUi;

public static class MainTemplateVariants
{
    public const string Standard = "Standard (Umschulung)";
    public const string Externenpruefung = "Externenprüfung";

    public const string StandardFileName = "Main.xml";
    public const string ExternFileName = "Main - Externenprüfung.xml";

    public static IReadOnlyList<string> All { get; } = [Standard, Externenpruefung];

    public static string GetFileName(string variant) =>
        IsExternenpruefung(variant) ? ExternFileName : StandardFileName;

    public static bool IsExternenpruefung(string? variant) =>
        string.Equals(variant, Externenpruefung, StringComparison.OrdinalIgnoreCase);
}
