using System.Xml;

namespace XmlEditorUi;

public static class DateFieldHelper
{
    public const string CourseStartPath = "SERVICE_DETAILS/SERVICE_DATE/START_DATE";
    public const string CourseEndPath = "SERVICE_DETAILS/SERVICE_DATE/END_DATE";
    public const string AnnouncementStartPath = "SERVICE_DETAILS/ANNOUNCEMENT/START_DATE";
    public const string AnnouncementEndPath = "SERVICE_DETAILS/ANNOUNCEMENT/END_DATE";
    public const string InstructionTimePath =
        "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_TIME";

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

    public static bool IsCourseStartPath(string? path) =>
        !string.IsNullOrWhiteSpace(path)
        && path.EndsWith("SERVICE_DATE/START_DATE", StringComparison.OrdinalIgnoreCase);

    public static bool IsTeilzeit(XmlNode service)
    {
        var instructionTime = service.GetTextByPath(InstructionTimePath) ?? string.Empty;
        return instructionTime.Contains("Teilzeit", StringComparison.OrdinalIgnoreCase);
    }

    /// <summary>
    /// Leitet abhängige Datumsfelder vom Maßnahme-Start ab:
    /// - Ankündigungsende = Maßnahme-Start
    /// - Ankündigungsstart = heute, oder Start−1 Jahr wenn Start noch &gt; 1 Jahr entfernt
    /// - bei Teilzeit: Enddatum = Start + 1 Jahr
    /// </summary>
    public static IReadOnlyList<string> ApplyCourseStartDefaults(
        XmlNode service,
        string? courseStartValue = null)
    {
        var changedPaths = new List<string>();
        var startValue = courseStartValue ?? service.GetTextByPath(CourseStartPath);
        if (!TryParse(startValue, out var startDate))
            return changedPaths;

        var startDay = startDate.Date;
        var today = DateTime.Today;

        service.SetNodeByPath(AnnouncementEndPath, Format(startDay, includeTime: false));
        changedPaths.Add(AnnouncementEndPath);

        var announcementStart = startDay > today.AddYears(1)
            ? startDay.AddYears(-1)
            : today;
        service.SetNodeByPath(AnnouncementStartPath, Format(announcementStart, includeTime: false));
        changedPaths.Add(AnnouncementStartPath);

        if (IsTeilzeit(service))
        {
            var endDate = startDay.AddYears(1);
            // Kurszeiten behalten ggf. die Uhrzeit des Starts bei.
            var courseEnd = startDate.TimeOfDay == TimeSpan.Zero
                ? endDate
                : endDate.Add(startDate.TimeOfDay);
            service.SetNodeByPath(CourseEndPath, Format(courseEnd, includeTime: true));
            changedPaths.Add(CourseEndPath);
        }

        return changedPaths;
    }

    public static DateTime GetCourseStartDateOrMax(XmlNode service)
    {
        var text = service.GetTextByPath(CourseStartPath);
        return TryParse(text, out var date) ? date : DateTime.MaxValue;
    }
}
