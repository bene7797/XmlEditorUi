using System.Xml;

namespace XmlEditorUi;

public sealed class TemplateDocumentSession
{
    public TemplateDocumentSession(string path, XmlDocument document)
    {
        Path = path;
        Document = document;
    }

    public string Path { get; }
    public XmlDocument Document { get; }
    public XmlNode Service => Document.DocumentElement
        ?? throw new InvalidOperationException("Template enthält kein SERVICE-Element.");

    public static TemplateDocumentSession Load(ServiceTemplateRepository repository, string path) =>
        new(path, repository.LoadTemplateDocument(path));

    public void Save() => Document.Save(Path);
}
