using System;
using System.Linq;
using System.Xml;

namespace XmlEditorUi;

public static class XmlHelper
{
    public static XmlNode? GetNodeByPath(this XmlNode startNode, string path)
    {
        var current = startNode;

        foreach (var part in path.Split('/'))
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
        return startNode.GetNodeByPath(path)?.InnerText?.Trim();
    }

    public static XmlNode SetNodeByPath(this XmlNode startNode, string path, string value)
    {
        var current = startNode;
        var document = startNode.OwnerDocument ?? (startNode as XmlDocument);

        if (document == null)
            throw new InvalidOperationException("Kein XmlDocument verfügbar.");

        foreach (var part in path.Split('/'))
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
}
