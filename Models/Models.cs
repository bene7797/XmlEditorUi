using System.Collections.Generic;
using System.Xml;

namespace XmlEditorUi;

public enum ServiceState
{
    Unchanged,
    New,
    Updated
}

public record DeletedServiceInfo(string ProductId, string Title);

public record QuickFieldDefinition(string Label, string Path);

public class CourseListItem
{
    public XmlNode Node { get; }
    private readonly string title;

    public CourseListItem(XmlNode node, string title)
    {
        Node = node;
        this.title = title;
    }

    public override string ToString() => title;
}
