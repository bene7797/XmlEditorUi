using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Xml;

namespace XmlEditorUi;

public class CourseEditableObject : ICustomTypeDescriptor
{
    private readonly XmlNode courseNode;
    private readonly bool onlyFilledFields;

    public CourseEditableObject(XmlNode courseNode, bool onlyFilledFields)
    {
        this.courseNode = courseNode;
        this.onlyFilledFields = onlyFilledFields;
    }

    public PropertyDescriptorCollection GetProperties()
    {
        var descriptors = new List<PropertyDescriptor>();
        AddFields(courseNode, "", descriptors);
        return new PropertyDescriptorCollection(descriptors.ToArray());
    }

    private void AddFields(XmlNode node, string prefix, List<PropertyDescriptor> descriptors)
    {
        if (node.Attributes != null)
        {
            foreach (XmlAttribute attr in node.Attributes)
            {
                if (onlyFilledFields && string.IsNullOrWhiteSpace(attr.Value))
                    continue;

                var displayName = string.IsNullOrEmpty(prefix)
                    ? "@" + attr.Name
                    : prefix + "/@" + attr.Name;

                descriptors.Add(new XmlFieldDescriptor(displayName, attr));
            }
        }

        foreach (XmlNode child in node.ChildNodes)
        {
            if (child.NodeType != XmlNodeType.Element)
                continue;

            if (child.LocalName.Equals("HEADER", StringComparison.OrdinalIgnoreCase))
                continue;

            var childPath = string.IsNullOrEmpty(prefix)
                ? child.Name
                : prefix + "/" + child.Name;

            if (HasElementChildren(child))
            {
                AddFields(child, childPath, descriptors);
            }
            else
            {
                var value = child.InnerText?.Trim();

                if (onlyFilledFields && string.IsNullOrWhiteSpace(value))
                    continue;

                descriptors.Add(new XmlFieldDescriptor(childPath, child));
            }
        }
    }

    private static bool HasElementChildren(XmlNode node)
    {
        foreach (XmlNode child in node.ChildNodes)
        {
            if (child.NodeType == XmlNodeType.Element)
                return true;
        }

        return false;
    }

    public AttributeCollection GetAttributes() => AttributeCollection.Empty;
    public string? GetClassName() => "COURSE";
    public string? GetComponentName() => "COURSE";
    public TypeConverter GetConverter() => new TypeConverter();
    public EventDescriptor? GetDefaultEvent() => null;
    public PropertyDescriptor? GetDefaultProperty() => null;
    public object? GetEditor(Type editorBaseType) => null;
    public EventDescriptorCollection GetEvents(Attribute[]? attributes) => EventDescriptorCollection.Empty;
    public EventDescriptorCollection GetEvents() => EventDescriptorCollection.Empty;
    public PropertyDescriptorCollection GetProperties(Attribute[]? attributes) => GetProperties();
    public object? GetPropertyOwner(PropertyDescriptor? pd) => this;
}

public class XmlFieldDescriptor : PropertyDescriptor
{
    private readonly XmlNode node;

    public XmlFieldDescriptor(string name, XmlNode node) : base(name, null)
    {
        this.node = node;
    }

    public override Type ComponentType => typeof(CourseEditableObject);
    public override bool IsReadOnly => false;
    public override Type PropertyType => typeof(string);
    public override bool CanResetValue(object component) => false;
    public override void ResetValue(object component) { }
    public override bool ShouldSerializeValue(object component) => true;

    public override object? GetValue(object? component)
    {
        if (node is XmlAttribute attr)
            return attr.Value;

        return node.InnerText;
    }

    public override void SetValue(object? component, object? value)
    {
        var newValue = value?.ToString() ?? "";

        if (node is XmlAttribute attr)
            attr.Value = newValue;
        else
            node.InnerText = newValue;
    }
}