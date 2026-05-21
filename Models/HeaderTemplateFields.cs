using System.Collections.Generic;

namespace XmlEditorUi;

/// <summary>
/// Definiert die essentiellen Felder für XML-Header (Metadaten des XML-Dokumentes).
/// Diese Felder werden im Template-Editor in der DataGrid angezeigt.
/// 
/// Header-Felder sind Metadaten des XML-Dokumentes selbst (nicht des Inhalts).
/// </summary>
public static class HeaderTemplateFields
{
    /// <summary>
    /// Felder für XML-Header und Metadaten.
    /// Format: (Label für UI, XPath im XML oder spezielle Kennzeichnung)
    /// </summary>
    public static readonly List<(string Label, string Path)> EssentialFields = new()
    {
        ("XML Version", "<?xml version?>"),
        ("Encoding", "<?xml encoding?>"),
        ("Standalone", "<?xml standalone?>"),
        ("Root Element", "root-element"),
    };
}
