using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Xml;

namespace XmlEditorUi;

public class LocationProfile
{
    public string Name { get; set; } = "";
    public Dictionary<string, string> Values { get; set; } = new();
}

public class CourseTypeProfile
{
    public string Name { get; set; } = "";
    public Dictionary<string, string> Values { get; set; } = new();
    public Dictionary<string, string> Attributes { get; set; } = new();
}

public class TemplateProfileManager
{
    private readonly string profilesFolder;

    public TemplateProfileManager(string profilesFolder)
    {
        this.profilesFolder = profilesFolder;
        Directory.CreateDirectory(profilesFolder);
    }

    public List<LocationProfile> LoadLocations()
    {
        var path = Path.Combine(profilesFolder, "locations.xml");
        var result = new List<LocationProfile>();

        if (!File.Exists(path))
            return result;

        var doc = new XmlDocument();
        doc.Load(path);

        foreach (XmlNode node in doc.GetElementsByTagName("LOCATION_PROFILE"))
        {
            var profile = new LocationProfile
            {
                Name = node.Attributes?["name"]?.Value ?? ""
            };

            foreach (XmlNode child in node.ChildNodes)
            {
                if (child.NodeType == XmlNodeType.Element)
                    profile.Values[child.LocalName] = child.InnerText;
            }

            if (!string.IsNullOrWhiteSpace(profile.Name))
                result.Add(profile);
        }

        return result;
    }

    public void SaveLocations(List<LocationProfile> profiles)
    {
        var path = Path.Combine(profilesFolder, "locations.xml");

        var doc = new XmlDocument();
        var root = doc.CreateElement("LOCATIONS");
        doc.AppendChild(root);

        foreach (var profile in profiles)
        {
            var node = doc.CreateElement("LOCATION_PROFILE");
            node.SetAttribute("name", profile.Name);

            foreach (var pair in profile.Values)
            {
                var child = doc.CreateElement(pair.Key);
                child.InnerText = pair.Value;
                node.AppendChild(child);
            }

            root.AppendChild(node);
        }

        doc.Save(path);
    }

    public List<CourseTypeProfile> LoadCourseTypes()
    {
        var path = Path.Combine(profilesFolder, "courseTypes.xml");
        var result = new List<CourseTypeProfile>();

        if (!File.Exists(path))
            return result;

        var doc = new XmlDocument();
        doc.Load(path);

        foreach (XmlNode node in doc.GetElementsByTagName("COURSE_TYPE_PROFILE"))
        {
            var profile = new CourseTypeProfile
            {
                Name = node.Attributes?["name"]?.Value ?? ""
            };

            foreach (XmlNode child in node.ChildNodes)
            {
                if (child.NodeType != XmlNodeType.Element)
                    continue;

                profile.Values[child.LocalName] = child.InnerText;

                if (child.Attributes?["type"] != null)
                    profile.Attributes[child.LocalName + "@type"] = child.Attributes["type"]!.Value;
            }

            if (!string.IsNullOrWhiteSpace(profile.Name))
                result.Add(profile);
        }

        return result;
    }

    public void SaveCourseTypes(List<CourseTypeProfile> profiles)
    {
        var path = Path.Combine(profilesFolder, "courseTypes.xml");

        var doc = new XmlDocument();
        var root = doc.CreateElement("COURSE_TYPES");
        doc.AppendChild(root);

        foreach (var profile in profiles)
        {
            var node = doc.CreateElement("COURSE_TYPE_PROFILE");
            node.SetAttribute("name", profile.Name);

            foreach (var pair in profile.Values)
            {
                var child = doc.CreateElement(pair.Key);
                child.InnerText = pair.Value;

                if (profile.Attributes.TryGetValue(pair.Key + "@type", out var type))
                    child.SetAttribute("type", type);

                node.AppendChild(child);
            }

            root.AppendChild(node);
        }

        doc.Save(path);
    }
}