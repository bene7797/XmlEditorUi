using System.Text.RegularExpressions;

namespace XmlEditorUi;

/// Converts German decimal commas to XML/XSD dots, e.g. 1234,56 → 1234.56
public static class NumberInputHelper
{
    public static string NormalizeDecimal(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
            return value ?? string.Empty;

        var trimmed = value.Trim();

        if (Regex.IsMatch(trimmed, @"^-?\d{1,3}(\.\d{3})+,\d+$"))
            return trimmed.Replace(".", "").Replace(",", ".");

        if (Regex.IsMatch(trimmed, @"^-?\d+,\d+$"))
            return trimmed.Replace(",", ".");

        return value;
    }
}
