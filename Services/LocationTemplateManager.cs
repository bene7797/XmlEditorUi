using System;
using System.Collections.Generic;
using System.Xml;

namespace XmlEditorUi;

/// <summary>
/// Hilfsklasse zur Verwaltung von Ort-Vorlagen (Leipzig, Kassel, etc.).
/// Ermöglicht einfaches Laden und Speichern dieser Vorlagen.
/// </summary>
public class LocationTemplateManager
{
    private readonly ServiceTemplateRepository templateRepository;

    public LocationTemplateManager(ServiceTemplateRepository templateRepository)
    {
        this.templateRepository = templateRepository;
    }

    /// <summary>
    /// Findet oder erstellt eine Vorlage für einen bestimmten Ort.
    /// </summary>
    public (string path, XmlDocument doc)? GetOrCreateLocationTemplate(string locationName)
    {
        var templates = templateRepository.GetTemplateFiles();

        // Versuche, eine passende Vorlage zu finden
        foreach (var file in templates)
        {
            if (Path.GetFileNameWithoutExtension(file).Contains(locationName, StringComparison.OrdinalIgnoreCase))
            {
                var doc = new XmlDocument();
                doc.PreserveWhitespace = true;
                doc.Load(file);
                return (file, doc);
            }
        }

        // Falls nicht gefunden, kann null zurückgegeben werden
        return null;
    }

    /// <summary>
    /// Gibt alle verfügbaren Ort-Vorlagen zurück.
    /// </summary>
    public List<string> GetAvailableLocationNames()
    {
        var names = new List<string>();
        var templates = templateRepository.GetTemplateFiles();

        foreach (var file in templates)
        {
            var doc = new XmlDocument();
            doc.Load(file);

            if (doc.DocumentElement == null)
                continue;

            var city = doc.DocumentElement.GetTextByPath(
                "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/CITY") ?? "";

            if (!string.IsNullOrWhiteSpace(city) && !city.Equals("Ort ?", StringComparison.OrdinalIgnoreCase))
                names.Add(city);
        }

        return new List<string>(new HashSet<string>(names));
    }

    /// <summary>
    /// Speichert eine modifizierte Ort-Vorlage.
    /// </summary>
    public void SaveLocationTemplate(string path, XmlDocument doc)
    {
        doc.Save(path);
    }
}
