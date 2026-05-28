using System.Text;
using System.Xml;

namespace XmlEditorUi;

internal static class MainTemplateBootstrap
{
    public static void EnsureExternenpruefungTemplate(string servicesFolder)
    {
        var targetPath = Path.Combine(servicesFolder, MainTemplateVariants.ExternFileName);
        if (File.Exists(targetPath))
            return;

        var mainPath = Path.Combine(servicesFolder, MainTemplateVariants.StandardFileName);
        var sourcePath = Path.Combine(servicesFolder, "Externenprüfung Kassel.xml");

        if (!File.Exists(mainPath) || !File.Exists(sourcePath))
            return;

        var mainDoc = XmlDocumentLoader.LoadFromFile(mainPath);
        var sourceDoc = XmlDocumentLoader.LoadFromFile(sourcePath);

        if (mainDoc.DocumentElement == null || sourceDoc.DocumentElement == null)
            return;

        var mainService = mainDoc.DocumentElement;
        var sourceService = sourceDoc.DocumentElement;

        foreach (XmlNode child in mainService.ChildNodes.Cast<XmlNode>().ToList())
        {
            if (child.NodeType == XmlNodeType.Element && child.LocalName.Equals("HEADER", StringComparison.OrdinalIgnoreCase))
                continue;

            mainService.RemoveChild(child);
        }

        foreach (XmlNode child in sourceService.ChildNodes)
        {
            if (child.NodeType != XmlNodeType.Element)
                continue;

            mainService.AppendChild(mainDoc.ImportNode(child, deep: true));
        }

        var settings = new XmlWriterSettings
        {
            Indent = true,
            IndentChars = "    ",
            Encoding = new UTF8Encoding(encoderShouldEmitUTF8Identifier: false),
            OmitXmlDeclaration = true
        };

        using var writer = XmlWriter.Create(targetPath, settings);
        mainDoc.Save(writer);
    }
}
