namespace XmlEditorUi;

public static class DateFieldHelper
{
    public static bool IsDatePath(string path) =>
        path.Contains("START_DATE", StringComparison.OrdinalIgnoreCase)
        || path.Contains("END_DATE", StringComparison.OrdinalIgnoreCase);

    public static bool TryParse(string? value, out DateTime date)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            date = DateTime.Now;
            return false;
        }

        var clean = value.Trim();

        if (clean.Contains('T'))
        {
            var main = clean.Split('+')[0];
            return DateTime.TryParse(main, out date);
        }

        if (clean.Contains('+'))
            clean = clean.Split('+')[0];

        return DateTime.TryParse(clean, out date);
    }

    public static string Format(DateTime date, bool includeTime) =>
        includeTime
            ? date.ToString("yyyy-MM-dd'T'HH:mm:ss.000+01:00")
            : date.ToString("yyyy-MM-dd+01:00");

    public static bool IsCourseDatePath(string path) =>
        path.Contains("SERVICE_DATE", StringComparison.OrdinalIgnoreCase);
}
