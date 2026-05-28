using System.Xml;

namespace XmlEditorUi;

public static class ServiceTitleBuilder
{
    public static string Build(XmlNode service, int index, ServiceState? state = null)
    {
        var title = BuildCore(service, index);

        return state switch
        {
            ServiceState.New => "[NEU] " + title,
            ServiceState.Updated => "[UPDATE] " + title,
            _ => title
        };
    }

    private static string BuildCore(XmlNode service, int index)
    {
        var productId = service.GetChildText("PRODUCT_ID");
        var title = service.GetTextByPath("SERVICE_DETAILS/TITLE");
        var city = service.GetTextByPath("SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/CITY");
        var instructionTime = service.GetTextByPath("SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_TIME");
        var educationType = service.GetTextByPath("SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/EDUCATION_TYPE");
        var startDate = service.GetTextByPath("SERVICE_DETAILS/SERVICE_DATE/START_DATE");
        var category = BuildCategory(city, instructionTime, educationType);

        var parts = new List<string>();

        if (!string.IsNullOrWhiteSpace(category))
            parts.Add($"[{category}]");

        if (!string.IsNullOrWhiteSpace(productId))
            parts.Add($"ID: {productId}");

        if (!string.IsNullOrWhiteSpace(startDate))
            parts.Add($"Start: {ShortDate(startDate)}");

        if (!string.IsNullOrWhiteSpace(title))
            parts.Add(title);

        return parts.Count > 0 ? string.Join(" | ", parts) : $"SERVICE #{index + 1}";
    }

    private static string BuildCategory(string? city, string? instructionTime, string? educationType)
    {
        var cityText = string.IsNullOrWhiteSpace(city) ? "Ort ?" : city.Trim();
        var timeText = string.IsNullOrWhiteSpace(instructionTime) ? "Zeit ?" : instructionTime.Trim();

        var isExternenpruefung = (educationType ?? "").Contains("Nachholen", StringComparison.OrdinalIgnoreCase)
            || (educationType ?? "").Contains("Extern", StringComparison.OrdinalIgnoreCase);

        return isExternenpruefung
            ? $"Externenprüfung - {cityText} - {timeText}"
            : $"{cityText} - {timeText}";
    }

    private static string ShortDate(string value) =>
        value.Length >= 10 ? value[..10] : value;
}
