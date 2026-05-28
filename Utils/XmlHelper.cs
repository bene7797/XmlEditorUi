using System;
using System.Linq;
using System.Xml;

namespace XmlEditorUi;

public static class XmlHelper
{
    public static XmlNode? GetNodeByPath(this XmlNode startNode, string path)
    {
        // Behandle Attribut-Selektor
        if (path.Contains("@"))
        {
            var parts = path.Split('@');
            var elementPath = parts[0].TrimEnd('/');

            if (string.IsNullOrEmpty(elementPath))
                return startNode;

            return startNode.GetNodeByPath(elementPath);
        }

        var current = startNode;

        foreach (var part in path.Split('/').Where(p => !string.IsNullOrEmpty(p)))
        {
            current = current.ChildNodes
                .Cast<XmlNode>()
                .FirstOrDefault(n => n.LocalName.Equals(part, StringComparison.OrdinalIgnoreCase));

            if (current == null)
                return null;
        }

        return current;
    }

    public static string? GetTextByPath(this XmlNode startNode, string path)
    {
        // Behandle Attribut-Selektor
        if (path.Contains("@"))
        {
            var parts = path.Split('@');
            var elementPath = parts[0].TrimEnd('/');
            var attributeName = parts[1];

            var element = startNode.GetNodeByPath(elementPath);
            if (element?.Attributes?[attributeName] != null)
                return element.Attributes[attributeName].Value;

            return null;
        }

        return startNode.GetNodeByPath(path)?.InnerText?.Trim();
    }

    public static XmlNode SetNodeByPath(this XmlNode startNode, string path, string value)
    {
        var current = startNode;
        var document = startNode.OwnerDocument ?? (startNode as XmlDocument);

        if (document == null)
            throw new InvalidOperationException("Kein XmlDocument verfügbar.");

        // Behandle Attribut-Selektor
        if (path.Contains("@"))
        {
            var parts = path.Split('@');
            var elementPath = parts[0].TrimEnd('/');
            var attributeName = parts[1];

            // Navigiere zum Element
            if (!string.IsNullOrEmpty(elementPath))
            {
                foreach (var part in elementPath.Split('/').Where(p => !string.IsNullOrEmpty(p)))
                {
                    var next = current.ChildNodes
                        .Cast<XmlNode>()
                        .FirstOrDefault(n => n.LocalName.Equals(part, StringComparison.OrdinalIgnoreCase));

                    if (next == null)
                    {
                        next = document.CreateElement(part);
                        current.AppendChild(next);
                    }

                    current = next;
                }
            }

            // Setze das Attribut
            current.SetAttribute(attributeName, value);
            return current;
        }

        // Normaler Element-Pfad
        foreach (var part in path.Split('/').Where(p => !string.IsNullOrEmpty(p)))
        {
            var next = current.ChildNodes
                .Cast<XmlNode>()
                .FirstOrDefault(n => n.LocalName.Equals(part, StringComparison.OrdinalIgnoreCase));

            if (next == null)
            {
                next = document.CreateElement(part);
                current.AppendChild(next);
            }

            current = next;
        }

        current.InnerText = value;
        return current;
    }

    public static XmlNode? FindChild(this XmlNode node, string childName)
    {
        return node.ChildNodes
            .Cast<XmlNode>()
            .FirstOrDefault(n => n.LocalName.Equals(childName, StringComparison.OrdinalIgnoreCase));
    }

    public static string? GetChildText(this XmlNode node, string childName)
    {
        return node.FindChild(childName)?.InnerText?.Trim();
    }

    public static XmlNode SetChildText(this XmlNode node, string childName, string value)
    {
        var document = node.OwnerDocument ?? (node as XmlDocument);

        if (document == null)
            throw new InvalidOperationException("Kein XmlDocument verfügbar.");

        var child = node.FindChild(childName);

        if (child == null)
        {
            child = document.CreateElement(childName);
            node.AppendChild(child);
        }

        child.InnerText = value;
        return child;
    }

    public static void SetAttribute(this XmlNode node, string name, string value)
    {
        var document = node.OwnerDocument ?? (node as XmlDocument);

        if (document == null)
            throw new InvalidOperationException("Kein XmlDocument verfügbar.");

        if (node.Attributes == null)
            throw new InvalidOperationException("XmlNode kann keine Attribute haben.");

        var attr = node.Attributes?[name];

        if (attr == null)
        {
            attr = document.CreateAttribute(name);
            node.Attributes.Append(attr);
        }

        attr.Value = value;
    }

    public static void ClearValues(this XmlNode node)
    {
        foreach (XmlNode child in node.ChildNodes)
        {
            if (child.NodeType != XmlNodeType.Element)
                continue;

            if (child.HasElementChildren())
            {
                child.ClearValues();
            }
            else
            {
                child.InnerText = string.Empty;
            }
        }

        if (node.Attributes != null)
        {
            foreach (XmlAttribute attr in node.Attributes)
                attr.Value = string.Empty;
        }
    }

    public static bool HasElementChildren(this XmlNode node)
    {
        return node.ChildNodes.Cast<XmlNode>().Any(child => child.NodeType == XmlNodeType.Element);
    }

    public static IEnumerable<string> GetRepeatingChildTexts(this XmlNode parent, string elementName)
    {
        return parent.ChildNodes
            .Cast<XmlNode>()
            .Where(n => n.NodeType == XmlNodeType.Element
                && n.LocalName.Equals(elementName, StringComparison.OrdinalIgnoreCase))
            .Select(n => n.InnerText.Trim())
            .Where(v => !string.IsNullOrEmpty(v));
    }

    public static void SetRepeatingChildElements(
        this XmlNode parent,
        string elementName,
        IEnumerable<string> values,
        string? insertAfterLocalName = null,
        string? insertBeforeLocalName = null)
    {
        var document = parent.OwnerDocument ?? (parent as XmlDocument)
            ?? throw new InvalidOperationException("Kein XmlDocument verfügbar.");

        var existing = parent.ChildNodes
            .Cast<XmlNode>()
            .Where(n => n.NodeType == XmlNodeType.Element
                && n.LocalName.Equals(elementName, StringComparison.OrdinalIgnoreCase))
            .ToList();

        foreach (var node in existing)
            parent.RemoveChild(node);

        var insertAfter = insertAfterLocalName == null
            ? null
            : parent.ChildNodes
                .Cast<XmlNode>()
                .LastOrDefault(n => n.LocalName.Equals(insertAfterLocalName, StringComparison.OrdinalIgnoreCase));

        var insertBefore = insertBeforeLocalName == null
            ? null
            : parent.ChildNodes
                .Cast<XmlNode>()
                .FirstOrDefault(n => n.LocalName.Equals(insertBeforeLocalName, StringComparison.OrdinalIgnoreCase));

        foreach (var value in values)
        {
            if (string.IsNullOrWhiteSpace(value))
                continue;

            var element = document.CreateElement(elementName);
            element.InnerText = value.Trim();

            if (insertAfter != null)
            {
                parent.InsertAfter(element, insertAfter);
                insertAfter = element;
            }
            else if (insertBefore != null)
                parent.InsertBefore(element, insertBefore);
            else
                parent.AppendChild(element);
        }
    }
}
