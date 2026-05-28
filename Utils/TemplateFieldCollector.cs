using System.Collections.Generic;
using System.Linq;
using System.Xml;

namespace XmlEditorUi;

public static class TemplateFieldCollector
{
    private static readonly HashSet<string> ExcludedPaths = BuildExcludedPaths();

    public static IReadOnlyList<TemplateFieldDefinition> CollectFromService(XmlNode service)
    {
        var paths = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        CollectFields(service, string.Empty, paths);

        return paths
            .OrderBy(p => p, StringComparer.OrdinalIgnoreCase)
            .Select(p => new TemplateFieldDefinition(FormatLabel(p), p))
            .ToList();
    }

    private static HashSet<string> BuildExcludedPaths()
    {
        var set = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        foreach (var field in LocationTemplateFields.EssentialFields)
            set.Add(field.Path);

        foreach (var field in CourseTypeTemplateFields.EssentialFields)
            set.Add(field.Path);

        foreach (var field in ImportantFields.List)
            set.Add(field.Path);

        return set;
    }

    private static void CollectFields(XmlNode node, string prefix, HashSet<string> paths)
    {
        if (node.Attributes != null)
        {
            foreach (XmlAttribute attr in node.Attributes)
            {
                var path = string.IsNullOrEmpty(prefix)
                    ? $"@{attr.Name}"
                    : $"{prefix}@{attr.Name}";

                if (!IsExcluded(path))
                    paths.Add(path);
            }
        }

        foreach (XmlNode child in node.ChildNodes)
        {
            if (child.NodeType != XmlNodeType.Element)
                continue;

            if (child.LocalName.Equals("HEADER", StringComparison.OrdinalIgnoreCase))
                continue;

            if (child.LocalName.Equals("KEYWORD", StringComparison.OrdinalIgnoreCase))
                continue;

            var childPath = string.IsNullOrEmpty(prefix)
                ? child.Name
                : $"{prefix}/{child.Name}";

            if (child.HasElementChildren())
            {
                CollectFields(child, childPath, paths);
            }
            else if (!IsExcluded(childPath))
            {
                paths.Add(childPath);
            }
        }
    }

    private static bool IsExcluded(string path)
    {
        if (ExcludedPaths.Contains(path))
            return true;

        if (path.Contains("/LOCATION/", StringComparison.OrdinalIgnoreCase))
            return true;

        if (path.Contains("/KEYWORD", StringComparison.OrdinalIgnoreCase)
            || path.EndsWith("/KEYWORD", StringComparison.OrdinalIgnoreCase))
            return true;

        return false;
    }

    private static string FormatLabel(string path)
    {
        if (path.Contains('@', StringComparison.Ordinal))
        {
            var parts = path.Split('@', 2);
            var element = parts[0].Split('/').Last();
            return $"{ToWords(element)} ({parts[1]})";
        }

        return ToWords(path.Split('/').Last());
    }

    private static string ToWords(string name) =>
        string.Join(' ', name.Split('_', StringSplitOptions.RemoveEmptyEntries));
}
