using System;
using System.Collections.Generic;
using System.Xml;

namespace XmlEditorUi;

/// <summary>
/// Verwaltet die Anwendung von Location- und CourseType-Profilen auf XML-Templates.
/// 
/// Workflow:
/// 1. LoadMainTemplate(path) lädt das Basis-Template
/// 2. ApplyLocationConfiguration(locationProfile) passt Ort-Daten an
/// 3. ApplyCourseTypeConfiguration(courseTypeProfile) passt Beschäftigungsart-Daten an
/// </summary>
public class TemplateConfigurationManager
{
    private readonly TemplateProfileManager profileManager;
    private XmlDocument? currentTemplate;

    public TemplateConfigurationManager(TemplateProfileManager profileManager)
    {
        this.profileManager = profileManager;
    }

    /// <summary>
    /// Lädt das Basis-Template aus der angegebenen Datei.
    /// </summary>
    public void LoadMainTemplate(string templatePath)
    {
        currentTemplate = new XmlDocument();
        currentTemplate.PreserveWhitespace = true;
        currentTemplate.Load(templatePath);
    }

    /// <summary>
    /// Wendet ein Location-Profil auf das aktuell geladene Template an.
    /// Ändert alle Ort-Daten entsprechend.
    /// </summary>
    public void ApplyLocationConfiguration(LocationProfile location)
    {
        if (currentTemplate == null)
            throw new InvalidOperationException("Kein Template geladen. LoadMainTemplate() aufrufen.");

        foreach (var fieldMapping in TemplateFieldMapping.LocationFieldPaths)
        {
            var fieldName = fieldMapping.Key;

            if (!location.Values.TryGetValue(fieldName, out var value))
                continue;

            SetFieldValueByXPath(currentTemplate, fieldMapping.Value, value);
        }
    }

    /// <summary>
    /// Wendet ein CourseType-Profil auf das aktuell geladene Template an.
    /// Ändert alle Beschäftigungsart-Daten entsprechend.
    /// </summary>
    public void ApplyCourseTypeConfiguration(CourseTypeProfile courseType)
    {
        if (currentTemplate == null)
            throw new InvalidOperationException("Kein Template geladen. LoadMainTemplate() aufrufen.");

        // Wende Text-Werte an
        foreach (var fieldMapping in TemplateFieldMapping.CourseTypeFieldPaths)
        {
            var fieldName = fieldMapping.Key;

            if (!courseType.Values.TryGetValue(fieldName, out var value))
                continue;

            // Wenn auch ein Attribut vorhanden ist, setze beides
            var attributeName = fieldName + "@type";
            var attributeValue = courseType.Attributes.TryGetValue(attributeName, out var attr) ? attr : null;

            SetFieldValueByXPath(currentTemplate, fieldMapping.Value, value, attributeValue);
        }

        // Wende Attribute an (falls nicht über Values schon gemacht)
        foreach (var attrMapping in TemplateFieldMapping.CourseTypeFieldAttributes)
        {
            if (courseType.Attributes.TryGetValue(attrMapping.Key, out var attrValue))
            {
                SetAttributeByXPath(currentTemplate, attrMapping.Value, attrValue);
            }
        }
    }

    /// <summary>
    /// Gibt das konfigurierte Template als XmlDocument zurück.
    /// </summary>
    public XmlDocument GetConfiguredTemplate()
    {
        if (currentTemplate == null)
            throw new InvalidOperationException("Kein Template geladen.");

        return currentTemplate;
    }

    private void SetFieldValueByXPath(XmlDocument doc, string xpathWithField, string value, string? attributeValue = null)
    {
        // XPath Format: "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/STREET"
        var (xpath, attributeName) = ExtractAttributeFromPath(xpathWithField);

        // Baue den vollständigen XPath
        var fullXPath = "/SERVICE/" + xpath.TrimStart('/');
        var node = doc.SelectSingleNode(fullXPath);

        if (node == null)
        {
            // Falls Node nicht existiert, versuche sie zu erstellen
            node = CreateNodeByPath(doc, xpath);
        }

        if (node != null)
        {
            if (attributeName != null)
            {
                node.SetAttribute(attributeName, value);
            }
            else
            {
                node.InnerText = value;
            }
        }
    }

    private void SetAttributeByXPath(XmlDocument doc, string xpathWithAttribute, string value)
    {
        var (xpath, attributeName) = ExtractAttributeFromPath(xpathWithAttribute);

        if (attributeName == null)
            return;

        var fullXPath = "/SERVICE/" + xpath.TrimStart('/');
        var node = doc.SelectSingleNode(fullXPath);

        if (node != null)
        {
            node.SetAttribute(attributeName, value);
        }
    }

    private (string xpath, string? attribute) ExtractAttributeFromPath(string path)
    {
        var atIndex = path.LastIndexOf('@');

        if (atIndex > 0)
        {
            // Format: "PATH/ELEMENT@attribute"
            return (path[..atIndex], path[(atIndex + 1)..]);
        }

        return (path, null);
    }

    private XmlNode CreateNodeByPath(XmlDocument doc, string relativePath)
    {
        var serviceNode = doc.SelectSingleNode("/SERVICE") ?? throw new InvalidOperationException("SERVICE-Element nicht gefunden");
        var parts = relativePath.Split('/');
        var currentNode = serviceNode;

        foreach (var part in parts)
        {
            if (string.IsNullOrEmpty(part))
                continue;

            var nextNode = currentNode.SelectSingleNode(part);

            if (nextNode == null)
            {
                nextNode = doc.CreateElement(part);
                currentNode.AppendChild(nextNode);
            }

            currentNode = nextNode;
        }

        return currentNode;
    }
}
