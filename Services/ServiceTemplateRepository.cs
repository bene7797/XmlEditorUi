using System;
using System.IO;
using System.Linq;
using System.Xml;

namespace XmlEditorUi;

public class ServiceTemplateRepository
{
    private readonly string servicesTemplateFolder;

    public ServiceTemplateRepository(string servicesTemplateFolder)
    {
        this.servicesTemplateFolder = servicesTemplateFolder;
        Directory.CreateDirectory(servicesTemplateFolder);
    }

    public string[] GetTemplateFiles()
    {
        return Directory.GetFiles(servicesTemplateFolder, "*.xml");
    }

    public XmlDocument LoadTemplateDocument(string path)
    {
        var doc = new XmlDocument();
        doc.PreserveWhitespace = true;
        doc.Load(path);
        return doc;
    }

    public void SaveTemplate(XmlNode service, string templateName)
    {
        var safeName = string.Join("_", templateName.Split(Path.GetInvalidFileNameChars()));
        var path = Path.Combine(servicesTemplateFolder, safeName + ".xml");

        var templateDoc = new XmlDocument();
        var imported = templateDoc.ImportNode(service, deep: true);
        templateDoc.AppendChild(imported);
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
        foreach (var file in GetTemplateFiles())
        {
            if (file.Equals(currentTemplatePath, StringComparison.OrdinalIgnoreCase))
                continue;

            var doc = LoadTemplateDocument(file);

            if (doc.DocumentElement == null)
                continue;

            var service = doc.DocumentElement;
            var currentValue = service.GetTextByPath("SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_TIME");

            if (!string.Equals(currentValue, instructionTime, StringComparison.OrdinalIgnoreCase))
                continue;

            service.SetNodeByPath("SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_TIME", newValue);
            doc.Save(file);
        }
    }
}
