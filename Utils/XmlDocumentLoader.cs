using System.Xml;

namespace XmlEditorUi;

public static class XmlDocumentLoader
{
    public static XmlDocument LoadFromFile(string path)
    {
        var doc = new XmlDocument { PreserveWhitespace = true };
        doc.Load(path);
        return doc;
    }
}
