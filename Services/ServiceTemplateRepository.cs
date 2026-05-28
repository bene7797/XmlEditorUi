using System.Xml;

namespace XmlEditorUi;

public class ServiceTemplateRepository
{
    private readonly string servicesTemplateFolder;

    public ServiceTemplateRepository(string servicesTemplateFolder)
    {
        this.servicesTemplateFolder = servicesTemplateFolder;
        Directory.CreateDirectory(servicesTemplateFolder);
        MainTemplateBootstrap.EnsureExternenpruefungTemplate(servicesTemplateFolder);
    }

    public static bool IsMainTemplateFile(string filePath)
    {
        var name = Path.GetFileName(filePath);
        return name.Equals(MainTemplateVariants.StandardFileName, StringComparison.OrdinalIgnoreCase)
            || name.Equals(MainTemplateVariants.ExternFileName, StringComparison.OrdinalIgnoreCase);
    }

    public static bool IsExternenpruefungTemplateFile(string filePath) =>
        Path.GetFileName(filePath).Contains("Extern", StringComparison.OrdinalIgnoreCase);

    public string[] GetTemplateFiles() => Directory.GetFiles(servicesTemplateFolder, "*.xml");

    public XmlDocument LoadTemplateDocument(string path) => XmlDocumentLoader.LoadFromFile(path);

    public string? FindMainTemplatePath(bool externenpruefung = false)
    {
        var preferred = externenpruefung
            ? MainTemplateVariants.ExternFileName
            : MainTemplateVariants.StandardFileName;

        var path = GetTemplateFiles().FirstOrDefault(f =>
            Path.GetFileName(f).Equals(preferred, StringComparison.OrdinalIgnoreCase));

        if (path != null)
            return path;

        return GetTemplateFiles().FirstOrDefault(f =>
            Path.GetFileName(f).Equals(MainTemplateVariants.StandardFileName, StringComparison.OrdinalIgnoreCase))
            ?? GetTemplateFiles().FirstOrDefault();
    }

    public TemplateDocumentSession? FindTemplateByFileNameContains(string text)
    {
        var path = GetTemplateFiles().FirstOrDefault(f =>
            Path.GetFileNameWithoutExtension(f).Contains(text, StringComparison.OrdinalIgnoreCase)
            && !IsMainTemplateFile(f)
            && !IsExternenpruefungTemplateFile(f));

        return path == null ? null : TemplateDocumentSession.Load(this, path);
    }

    public TemplateDocumentSession? FindTemplateByCity(string cityName)
    {
        foreach (var file in GetTemplateFiles())
        {
            var session = TemplateDocumentSession.Load(this, file);
            var city = session.Service.GetTextByPath(
                "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/CITY");

            if (string.Equals(city, cityName, StringComparison.OrdinalIgnoreCase))
                return session;
        }

        return FindTemplateByFileNameContains(cityName);
    }

    public TemplateDocumentSession? LoadMainTemplateSession(string variant = MainTemplateVariants.Standard)
    {
        var path = FindMainTemplatePath(MainTemplateVariants.IsExternenpruefung(variant));
        return path == null ? null : TemplateDocumentSession.Load(this, path);
    }

    public IReadOnlyList<string> GetDistinctCourseTypeNames()
    {
        var names = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        foreach (var file in GetTemplateFiles())
        {
            if (IsMainTemplateFile(file) || IsExternenpruefungTemplateFile(file))
                continue;

            var fileName = Path.GetFileNameWithoutExtension(file);

            if (fileName.Contains("Vollzeit", StringComparison.OrdinalIgnoreCase))
                names.Add("Vollzeit");
            else if (fileName.Contains("Teilzeit", StringComparison.OrdinalIgnoreCase))
                names.Add("Teilzeit");
        }

        return names.OrderBy(n => n).ToList();
    }

    public IReadOnlyList<string> GetDistinctLocationNames()
    {
        var names = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        foreach (var file in GetTemplateFiles())
        {
            var doc = LoadTemplateDocument(file);
            if (doc.DocumentElement == null)
                continue;

            var city = doc.DocumentElement.GetTextByPath(
                "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/CITY") ?? "";

            if (!string.IsNullOrWhiteSpace(city) && !city.Equals("Ort ?", StringComparison.OrdinalIgnoreCase))
                names.Add(city);
        }

        return names.OrderBy(n => n).ToList();
    }

    public void SaveTemplate(XmlNode service, string templateName)
    {
        var safeName = string.Join("_", templateName.Split(Path.GetInvalidFileNameChars()));
        var path = Path.Combine(servicesTemplateFolder, safeName + ".xml");

        var templateDoc = new XmlDocument();
        templateDoc.AppendChild(templateDoc.ImportNode(service, deep: true));
        templateDoc.Save(path);
    }

    public void ApplyLocationChangeToAllTemplates(string currentTemplatePath, string city, string changedPath, string newValue)
    {
        foreach (var file in GetTemplateFiles())
        {
            if (file.Equals(currentTemplatePath, StringComparison.OrdinalIgnoreCase))
                continue;

            var doc = LoadTemplateDocument(file);
            if (doc.DocumentElement == null)
                continue;

            var service = doc.DocumentElement;
            var templateCity = service.GetTextByPath("SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/CITY");

            if (!string.Equals(templateCity, city, StringComparison.OrdinalIgnoreCase))
                continue;

            service.SetNodeByPath(changedPath, newValue);
            doc.Save(file);
        }
    }

    public void ApplyInstructionTimeToMatchingTemplates(string currentTemplatePath, string instructionTime, string newValue)
    {
        const string instructionPath = "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_TIME";

        foreach (var file in GetTemplateFiles())
        {
            if (file.Equals(currentTemplatePath, StringComparison.OrdinalIgnoreCase))
                continue;

            var doc = LoadTemplateDocument(file);
            if (doc.DocumentElement == null)
                continue;

            var service = doc.DocumentElement;
            var currentValue = service.GetTextByPath(instructionPath);

            if (!string.Equals(currentValue, instructionTime, StringComparison.OrdinalIgnoreCase))
                continue;

            service.SetNodeByPath(instructionPath, newValue);
            doc.Save(file);
        }
    }
}
