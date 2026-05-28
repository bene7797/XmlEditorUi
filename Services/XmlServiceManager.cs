using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml;
using System.Xml.Linq;
using System.Xml.Schema;

namespace XmlEditorUi;

public class XmlServiceManager
{
    private static readonly string[] InvalidEducationExtendedInfoElements =
    {
        "DURATION",
        "INSTRUCTION_REMARKS"
    };

    private static readonly string[] AddressElementOrder =
    {
        "NAME", "NAME2", "NAME3", "STREET", "ZIP", "BOXNO", "ZIPBOX", "CITY", "DISTRICT", "STATE",
        "COUNTRY_CODED", "COUNTRY", "PHONE", "MOBILE", "FAX", "EMAILS", "URL", "ADDRESS_REMARKS",
        "BARRIER_FREE_LOCATION", "ID_DB"
    };

    private readonly string servicesTemplateFolder;
    private readonly List<QuickFieldDefinition> importantFields;
    private readonly Dictionary<XmlNode, ServiceState> serviceStates = new();
    private readonly List<DeletedServiceInfo> deletedServices = new();
    private readonly Dictionary<XmlNode, HashSet<string>> pendingTemplateFields = new();
    private readonly Dictionary<XmlNode, HashSet<string>> changedImportantFields = new();
    private XmlDocument? document;
    private XmlNode? headerTemplate;

    static XmlServiceManager()
    {
        Encoding.RegisterProvider(CodePagesEncodingProvider.Instance);
    }

    public XmlServiceManager(string servicesTemplateFolder, List<QuickFieldDefinition> importantFields)
    {
        this.servicesTemplateFolder = servicesTemplateFolder;
        this.importantFields = importantFields;
        Directory.CreateDirectory(servicesTemplateFolder);
    }

    public XmlDocument? Document => document;
    public IReadOnlyDictionary<XmlNode, ServiceState> ServiceStates => serviceStates;
    public IReadOnlyCollection<DeletedServiceInfo> DeletedServices => deletedServices;
    public IReadOnlyDictionary<XmlNode, HashSet<string>> PendingTemplateFields => pendingTemplateFields;
    public IReadOnlyDictionary<XmlNode, HashSet<string>> ChangedImportantFields => changedImportantFields;

    public void SetHeaderTemplate(XmlNode? header)
    {
        headerTemplate = header;
    }

    public XmlNode? GetHeaderTemplate() => headerTemplate;

    public void LoadXml(string path)
    {
        document = new XmlDocument();
        document.PreserveWhitespace = true;
        document.Load(path);

        serviceStates.Clear();
        deletedServices.Clear();
        pendingTemplateFields.Clear();
        changedImportantFields.Clear();

        CaptureHeaderFromDocument();
    }

    public IEnumerable<XmlNode> GetServiceNodes()
    {
        if (document?.DocumentElement == null)
            return Enumerable.Empty<XmlNode>();

        return document
            .GetElementsByTagName("*")
            .Cast<XmlNode>()
            .Where(IsServiceNode)
            .ToList();
    }

    public XmlNode AddEmptyService(XmlNode templateService)
    {
        EnsureDocumentLoaded();

        var insertParent = GetServiceInsertParent();

        if (insertParent == null)
            throw new InvalidOperationException("Weder NEW_CATALOG noch UPDATE_CATALOG gefunden.");

        var newService = templateService.CloneNode(deep: true);
        newService.ClearValues();

        var newProductId = GenerateNewProductId();
        newService.SetChildText("PRODUCT_ID", newProductId);

        if (GetUpdateCatalogNode() != null)
            newService.SetAttribute("mode", "new");

        insertParent.AppendChild(newService);
        serviceStates[newService] = ServiceState.New;
        pendingTemplateFields[newService] = importantFields.Select(f => f.Path).ToHashSet();

        return newService;
    }

    public XmlNode AddServiceFromTemplate(string templatePath)
    {
        EnsureDocumentLoaded();

        var templateDoc = new XmlDocument();
        templateDoc.PreserveWhitespace = true;
        templateDoc.Load(templatePath);

        var templateElement = templateDoc.DocumentElement;
        if (templateElement == null)
            throw new InvalidOperationException("Vorlage enthält kein SERVICE-Element.");

        var importedService = document!.ImportNode(templateElement, deep: true);

        var newProductId = GenerateNewProductId();
        importedService.SetChildText("PRODUCT_ID", newProductId);

        if (GetUpdateCatalogNode() != null)
            importedService.SetAttribute("mode", "new");

        var insertParent = GetServiceInsertParent();

        if (insertParent == null)
            throw new InvalidOperationException("Weder NEW_CATALOG noch UPDATE_CATALOG gefunden.");

        insertParent.AppendChild(importedService);
        serviceStates[importedService] = ServiceState.New;
        pendingTemplateFields[importedService] = importantFields.Select(f => f.Path).ToHashSet();

        return importedService;
    }

    public XmlNode AddServiceFromConfiguredTemplate(XmlDocument configuredTemplate)
    {
        EnsureDocumentLoaded();

        var templateElement = configuredTemplate.DocumentElement;
        if (templateElement == null)
            throw new InvalidOperationException("Konfigurierte Vorlage enthält kein SERVICE-Element.");

        var importedService = document!.ImportNode(templateElement, deep: true);

        var newProductId = GenerateNewProductId();
        importedService.SetChildText("PRODUCT_ID", newProductId);

        if (GetUpdateCatalogNode() != null)
            importedService.SetAttribute("mode", "new");

        var insertParent = GetServiceInsertParent();

        if (insertParent == null)
            throw new InvalidOperationException("Weder NEW_CATALOG noch UPDATE_CATALOG gefunden.");

        insertParent.AppendChild(importedService);
        serviceStates[importedService] = ServiceState.New;
        pendingTemplateFields[importedService] = importantFields.Select(f => f.Path).ToHashSet();

        return importedService;
    }

    public void RemoveService(XmlNode service, string title)
    {
        EnsureDocumentLoaded();

        var productId = service.GetChildText("PRODUCT_ID");

        if (string.IsNullOrWhiteSpace(productId))
            throw new InvalidOperationException("Dieser SERVICE hat keine PRODUCT_ID und kann nicht sauber gelöscht werden.");

        var isNewService = serviceStates.TryGetValue(service, out var state) && state == ServiceState.New;
        var updateCatalog = GetUpdateCatalogNode();

        if (updateCatalog != null && !isNewService)
        {
            var deleteNode = GetOrCreateUpdateChild("DELETE");
            var deleteService = document!.CreateElement("SERVICE");
            var productIdNode = document.CreateElement("PRODUCT_ID");
            productIdNode.InnerText = productId;
            deleteService.AppendChild(productIdNode);
            deleteNode.AppendChild(deleteService);

            deletedServices.Add(new DeletedServiceInfo(productId, title));
            service.ParentNode?.RemoveChild(service);
            serviceStates.Remove(service);
            return;
        }

        service.ParentNode?.RemoveChild(service);
        serviceStates.Remove(service);

        if (!isNewService)
            deletedServices.Add(new DeletedServiceInfo(productId, title));
    }

    public void MarkFieldAsChanged(XmlNode service, string path)
    {
        if (!changedImportantFields.TryGetValue(service, out var changed))
            changedImportantFields[service] = changed = new HashSet<string>();

        changed.Add(path);

        if (pendingTemplateFields.TryGetValue(service, out var pending))
            pending.Remove(path);

        if (!serviceStates.ContainsKey(service))
            serviceStates[service] = ServiceState.Unchanged;

        if (serviceStates[service] == ServiceState.Unchanged)
            serviceStates[service] = ServiceState.Updated;
    }

    public void MarkAsUpdated(XmlNode service)
    {
        if (!serviceStates.ContainsKey(service))
            serviceStates[service] = ServiceState.Unchanged;

        if (serviceStates[service] == ServiceState.Unchanged)
            serviceStates[service] = ServiceState.Updated;
    }

    public string GenerateNewProductId()
    {
        EnsureDocumentLoaded();

        var existingIds = document!
            .GetElementsByTagName("*")
            .Cast<XmlNode>()
            .Where(n => n.LocalName.Equals("PRODUCT_ID", StringComparison.OrdinalIgnoreCase))
            .Select(n => n.InnerText.Trim())
            .Where(v => long.TryParse(v, out _))
            .Select(long.Parse)
            .ToHashSet();

        if (existingIds.Count == 0)
            return "1";

        var nextId = existingIds.Max() + 1;

        while (existingIds.Contains(nextId))
            nextId++;

        return nextId.ToString();
    }

    public XmlDocument BuildExportDocument()
    {
        EnsureDocumentLoaded();

        return deletedServices.Count > 0
            ? BuildUpdateCatalogExport()
            : BuildNewCatalogExport();
    }

    public void ValidateWithSchema(string xmlPath, string schemaPath)
    {
        if (!File.Exists(xmlPath))
            throw new FileNotFoundException("XML-Datei wurde nicht gefunden.", xmlPath);

        if (!File.Exists(schemaPath))
            throw new FileNotFoundException("XSD-Datei wurde nicht gefunden.", schemaPath);

        var xmlDoc = XDocument.Load(xmlPath);

        var schemas = new XmlSchemaSet();
        schemas.Add(null, schemaPath);

        xmlDoc.Validate(schemas, (_, args) =>
        {
            throw new XmlSchemaValidationException(args.Message);
        });
    }

    public IEnumerable<XmlNode> GetActiveServices()
    {
        EnsureDocumentLoaded();

        return document!
            .GetElementsByTagName("*")
            .Cast<XmlNode>()
            .Where(IsServiceNode)
            .Where(n => n.ParentNode != null)
            .ToList();
    }

    private static bool IsServiceNode(XmlNode node)
    {
        return node.LocalName.Equals("SERVICE", StringComparison.OrdinalIgnoreCase)
            && !IsInsideDelete(node);
    }

    private static bool IsInsideDelete(XmlNode node)
    {
        var parent = node.ParentNode;

        while (parent != null)
        {
            if (parent.LocalName.Equals("DELETE", StringComparison.OrdinalIgnoreCase))
                return true;

            parent = parent.ParentNode;
        }

        return false;
    }

    private XmlNode? FindCatalogNode(string name)
    {
        if (document == null)
            return null;

        return document
            .GetElementsByTagName("*")
            .Cast<XmlNode>()
            .FirstOrDefault(n => n.LocalName.Equals(name, StringComparison.OrdinalIgnoreCase));
    }

    private XmlNode? GetNewCatalogNode() => FindCatalogNode("NEW_CATALOG");

    private XmlNode? GetUpdateCatalogNode() => FindCatalogNode("UPDATE_CATALOG");

    private XmlNode GetOrCreateUpdateChild(string childName)
    {
        var updateCatalog = GetUpdateCatalogNode() ?? throw new InvalidOperationException("Kein UPDATE_CATALOG gefunden.");

        var existing = updateCatalog.ChildNodes
            .Cast<XmlNode>()
            .FirstOrDefault(n => n.LocalName.Equals(childName, StringComparison.OrdinalIgnoreCase));

        if (existing != null)
            return existing;

        var newNode = document!.CreateElement(childName);

        if (childName.Equals("DELETE", StringComparison.OrdinalIgnoreCase))
        {
            var newElement = updateCatalog.ChildNodes
                .Cast<XmlNode>()
                .FirstOrDefault(n => n.LocalName.Equals("NEW", StringComparison.OrdinalIgnoreCase));

            if (newElement != null)
                updateCatalog.InsertBefore(newNode, newElement);
            else
                updateCatalog.AppendChild(newNode);
        }
        else
        {
            updateCatalog.AppendChild(newNode);
        }

        return newNode;
    }

    private XmlNode? GetServiceInsertParent()
    {
        var newCatalog = GetNewCatalogNode();

        if (newCatalog != null)
            return newCatalog;

        var updateCatalog = GetUpdateCatalogNode();

        return updateCatalog?.ChildNodes
            .Cast<XmlNode>()
            .FirstOrDefault(n => n.LocalName.Equals("NEW", StringComparison.OrdinalIgnoreCase))
            ?? updateCatalog?.AppendChild(document!.CreateElement("NEW"));
    }

    private XmlDocument BuildNewCatalogExport()
    {
        var exportDoc = new XmlDocument();
        var declaration = exportDoc.CreateXmlDeclaration("1.0", "iso-8859-15", "yes");
        exportDoc.AppendChild(declaration);

        var root = exportDoc.CreateElement("OPENQCAT");
        root.SetAttribute("version", "1.1");
        root.SetAttribute("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance");
        root.SetAttribute("noNamespaceSchemaLocation", "http://www.w3.org/2001/XMLSchema-instance", "openQ-cat.V1.1.xsd");

        exportDoc.AppendChild(root);

        // Add header template if available
        if (headerTemplate != null)
        {
            var importedHeader = exportDoc.ImportNode(headerTemplate, deep: true);
            root.AppendChild(importedHeader);
        }

        var catalog = exportDoc.CreateElement("NEW_CATALOG");
        catalog.SetAttribute("FULLCATALOG", "1");
        root.AppendChild(catalog);

        var services = GetActiveServices();

        foreach (var service in services)
        {
            var imported = exportDoc.ImportNode(service, deep: true);
            SanitizeServiceForExport(imported);
            SetAttributeForDocument(exportDoc, imported, "mode", "new");
            catalog.AppendChild(imported);
        }

        return exportDoc;
    }

    private XmlDocument BuildUpdateCatalogExport()
    {
        var exportDoc = new XmlDocument();
        var declaration = exportDoc.CreateXmlDeclaration("1.0", "iso-8859-15", "yes");
        exportDoc.AppendChild(declaration);

        var root = exportDoc.CreateElement("OPENQCAT");
        root.SetAttribute("version", "1.1");
        root.SetAttribute("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance");
        root.SetAttribute("noNamespaceSchemaLocation", "http://www.w3.org/2001/XMLSchema-instance", "openQ-cat.V1.1.xsd");
        exportDoc.AppendChild(root);

        // Add header template if available
        if (headerTemplate != null)
        {
            var importedHeader = exportDoc.ImportNode(headerTemplate, deep: true);
            root.AppendChild(importedHeader);
        }

        var catalog = exportDoc.CreateElement("UPDATE_CATALOG");
        catalog.SetAttribute("seq_number", "1");
        root.AppendChild(catalog);

        var deleteNode = exportDoc.CreateElement("DELETE");
        catalog.AppendChild(deleteNode);

        foreach (var deleted in deletedServices)
        {
            var deleteService = exportDoc.CreateElement("SERVICE");
            var productIdNode = exportDoc.CreateElement("PRODUCT_ID");
            productIdNode.InnerText = deleted.ProductId;
            deleteService.AppendChild(productIdNode);
            deleteNode.AppendChild(deleteService);
        }

        var newNode = exportDoc.CreateElement("NEW");
        catalog.AppendChild(newNode);

        var servicesToExport = GetActiveServices()
            .Where(service =>
                serviceStates.TryGetValue(service, out var state)
                && (state == ServiceState.New || state == ServiceState.Updated))
            .ToList();

        foreach (var service in servicesToExport)
        {
            var imported = exportDoc.ImportNode(service, deep: true);
            SanitizeServiceForExport(imported);
            SetAttributeForDocument(exportDoc, imported, "mode", "new");
            newNode.AppendChild(imported);
        }

        return exportDoc;
    }

    private static void SetAttributeForDocument(XmlDocument doc, XmlNode node, string name, string value)
    {
        var attr = node.Attributes?[name];

        if (attr == null)
        {
            attr = doc.CreateAttribute(name);
            node.Attributes?.Append(attr);
        }

        attr.Value = value;
    }

    private void CaptureHeaderFromDocument()
    {
        if (document?.DocumentElement == null)
            return;

        if (!document.DocumentElement.LocalName.Equals("OPENQCAT", StringComparison.OrdinalIgnoreCase))
            return;

        var header = document.DocumentElement.ChildNodes
            .Cast<XmlNode>()
            .FirstOrDefault(n => n.LocalName.Equals("HEADER", StringComparison.OrdinalIgnoreCase));

        if (header != null)
            headerTemplate = header;
    }

    private static void SanitizeServiceForExport(XmlNode service)
    {
        RemoveHeaderFromService(service);
        RemoveInvalidEducationExtendedInfoElements(service);
        NormalizeLocationEmailElements(service);
    }

    private static void RemoveHeaderFromService(XmlNode service)
    {
        var headerNodes = service.ChildNodes
            .Cast<XmlNode>()
            .Where(n => n.LocalName.Equals("HEADER", StringComparison.OrdinalIgnoreCase))
            .ToList();

        foreach (var header in headerNodes)
        {
            service.RemoveChild(header);
        }
    }

    private static void RemoveInvalidEducationExtendedInfoElements(XmlNode service)
    {
        var extendedInfo = service.GetNodeByPath("SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO");

        if (extendedInfo == null)
            return;

        var invalidNodes = extendedInfo.ChildNodes
            .Cast<XmlNode>()
            .Where(n => n.NodeType == XmlNodeType.Element
                && InvalidEducationExtendedInfoElements.Contains(
                    n.LocalName,
                    StringComparer.OrdinalIgnoreCase))
            .ToList();

        foreach (var node in invalidNodes)
            extendedInfo.RemoveChild(node);
    }

    private static void NormalizeLocationEmailElements(XmlNode service)
    {
        if (service.OwnerDocument is not XmlDocument doc)
            return;

        var locations = service.SelectNodes(".//LOCATION");
        if (locations == null)
            return;

        foreach (XmlNode location in locations)
        {
            var directEmailNodes = location.ChildNodes
                .Cast<XmlNode>()
                .Where(n => n.NodeType == XmlNodeType.Element
                    && n.LocalName.Equals("EMAIL", StringComparison.OrdinalIgnoreCase))
                .ToList();

            foreach (var emailNode in directEmailNodes)
            {
                var emailValue = emailNode.InnerText;
                location.RemoveChild(emailNode);

                if (string.IsNullOrWhiteSpace(emailValue))
                    continue;

                var emailsContainer = location.FindChild("EMAILS");
                if (emailsContainer == null)
                {
                    emailsContainer = doc.CreateElement("EMAILS");
                    InsertAddressElementBefore(location, emailsContainer, "URL");
                }

                var hasEmail = emailsContainer.ChildNodes
                    .Cast<XmlNode>()
                    .Any(n => n.NodeType == XmlNodeType.Element
                        && n.LocalName.Equals("EMAIL", StringComparison.OrdinalIgnoreCase));

                if (!hasEmail)
                {
                    var emailElement = doc.CreateElement("EMAIL");
                    emailElement.InnerText = emailValue;
                    emailsContainer.AppendChild(emailElement);
                }
            }
        }
    }

    private static void InsertAddressElementBefore(XmlNode location, XmlNode newElement, string beforeElementName)
    {
        var beforeIndex = Array.IndexOf(
            AddressElementOrder,
            beforeElementName.ToUpperInvariant());

        if (beforeIndex < 0)
        {
            location.AppendChild(newElement);
            return;
        }

        XmlNode? insertBefore = null;

        foreach (XmlNode child in location.ChildNodes)
        {
            if (child.NodeType != XmlNodeType.Element)
                continue;

            var childIndex = Array.IndexOf(
                AddressElementOrder,
                child.LocalName.ToUpperInvariant());

            if (childIndex >= 0 && childIndex >= beforeIndex)
            {
                insertBefore = child;
                break;
            }
        }

        if (insertBefore != null)
            location.InsertBefore(newElement, insertBefore);
        else
            location.AppendChild(newElement);
    }

    private void EnsureDocumentLoaded()
    {
        if (document == null)
            throw new InvalidOperationException("Bitte zuerst XML öffnen.");
    }
}
