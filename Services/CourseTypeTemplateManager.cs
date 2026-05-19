using System;
using System.Collections.Generic;
using System.Xml;

namespace XmlEditorUi;

/// <summary>
/// Hilfsklasse zur Verwaltung von Beschäftigungsart-Vorlagen (Vollzeit, Teilzeit, Externenprüfung).
/// Ermöglicht einfaches Laden und Speichern dieser Vorlagen.
/// </summary>
public class CourseTypeTemplateManager
{
    private readonly ServiceTemplateRepository templateRepository;

    public CourseTypeTemplateManager(ServiceTemplateRepository templateRepository)
    {
        this.templateRepository = templateRepository;
    }

    /// <summary>
    /// Findet oder erstellt eine Vorlage für einen bestimmten Beschäftigungsart-Namen.
    /// </summary>
    public (string path, XmlDocument doc)? GetOrCreateCourseTypeTemplate(string courseTypeName)
    {
        var templates = templateRepository.GetTemplateFiles();

        // Versuche, eine passende Vorlage zu finden
        foreach (var file in templates)
        {
            if (Path.GetFileNameWithoutExtension(file).Contains(courseTypeName, StringComparison.OrdinalIgnoreCase))
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
    /// Gibt alle verfügbaren Beschäftigungsart-Vorlagen zurück.
    /// </summary>
    public List<string> GetAvailableCourseTypeNames()
    {
        var names = new List<string>();
        var templates = templateRepository.GetTemplateFiles();

        foreach (var file in templates)
        {
            // Extrahiere Beschäftigungsart aus dem Namen
            var filename = Path.GetFileNameWithoutExtension(file);

            if (filename.Contains("Vollzeit", StringComparison.OrdinalIgnoreCase))
                names.Add("Vollzeit");
            else if (filename.Contains("Teilzeit", StringComparison.OrdinalIgnoreCase))
                names.Add("Teilzeit");
            else if (filename.Contains("Extern", StringComparison.OrdinalIgnoreCase))
                names.Add("Externenprüfung");
        }

        return new List<string>(new HashSet<string>(names));
    }

    /// <summary>
    /// Speichert eine modifizierte Beschäftigungsart-Vorlage.
    /// </summary>
    public void SaveCourseTypeTemplate(string path, XmlDocument doc)
    {
        doc.Save(path);
    }
}
