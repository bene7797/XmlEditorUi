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
        SyncCourseIdWithProductId(newService);

        ApplyServiceModeForWorkingCopy(newService);

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
        SyncCourseIdWithProductId(importedService);

        ApplyServiceModeForWorkingCopy(importedService);

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
        SyncCourseIdWithProductId(importedService);

        ApplyServiceModeForWorkingCopy(importedService);

        var insertParent = GetServiceInsertParent();

        if (insertParent == null)
            throw new InvalidOperationException("Weder NEW_CATALOG noch UPDATE_CATALOG gefunden.");

        insertParent.AppendChild(importedService);
        serviceStates[importedService] = ServiceState.New;
        pendingTemplateFields[importedService] = importantFields.Select(f => f.Path).ToHashSet();

        return importedService;
    }

    /// <summary>
    /// Klont einen bestehenden SERVICE, vergibt eine neue PRODUCT_ID und überschreibt Ort
    /// sowie optional Beschäftigungsart (Vollzeit/Teilzeit).
    /// </summary>
    public XmlNode CopyServiceWithConfiguration(
        XmlNode sourceService,
        LocationProfile location,
        CourseTypeProfile? courseType)
    {
        EnsureDocumentLoaded();

        var insertParent = GetServiceInsertParent();
        if (insertParent == null)
            throw new InvalidOperationException("Weder NEW_CATALOG noch UPDATE_CATALOG gefunden.");

        var copiedService = sourceService.CloneNode(deep: true);

        var newProductId = GenerateNewProductId();
        copiedService.SetChildText("PRODUCT_ID", newProductId);
        SyncCourseIdWithProductId(copiedService);
        ApplyServiceModeForWorkingCopy(copiedService);

        TemplateConfigurationManager.ApplyLocationToService(copiedService, location);
        if (courseType != null)
            TemplateConfigurationManager.ApplyCourseTypeToService(copiedService, courseType);

        insertParent.AppendChild(copiedService);
        serviceStates[copiedService] = ServiceState.New;
        pendingTemplateFields[copiedService] = importantFields.Select(f => f.Path).ToHashSet();

        return copiedService;
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

        return ShouldUseUpdateCatalogExport()
            ? BuildUpdateCatalogExport()
            : BuildNewCatalogExport();
    }

    /// <summary>
    /// XSD: OPENQCAT enthält entweder NEW_CATALOG oder UPDATE_CATALOG (xsd:choice).
    /// UPDATE_CATALOG nur bei tatsächlichen Änderungen (neu/geändert/gelöscht).
    /// </summary>
    private bool ShouldUseUpdateCatalogExport()
    {
        if (deletedServices.Count > 0)
            return true;

        return serviceStates.Values.Any(s => s is ServiceState.New or ServiceState.Updated);
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

        AppendExportHeader(exportDoc, root);

        var catalog = exportDoc.CreateElement("NEW_CATALOG");
        catalog.SetAttribute("FULLCATALOG", "true");
        root.AppendChild(catalog);

        var services = GetActiveServices();

        foreach (var service in services)
        {
            var imported = exportDoc.ImportNode(service, deep: true);
            SanitizeServiceForExport(imported);
            ApplyServiceModeForExport(imported, isUpdateCatalogExport: false);
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

        AppendExportHeader(exportDoc, root);

        var catalog = exportDoc.CreateElement("UPDATE_CATALOG");
        catalog.SetAttribute("seq_number", GetNextUpdateCatalogSeqNumber().ToString());
        root.AppendChild(catalog);

        if (deletedServices.Count > 0)
        {
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
        }

        var servicesToExport = GetActiveServices()
            .Where(service =>
                serviceStates.TryGetValue(service, out var state)
                && (state == ServiceState.New || state == ServiceState.Updated))
            .ToList();

        if (servicesToExport.Count > 0)
        {
            var newNode = exportDoc.CreateElement("NEW");
            catalog.AppendChild(newNode);

            foreach (var service in servicesToExport)
            {
                var imported = exportDoc.ImportNode(service, deep: true);
                SanitizeServiceForExport(imported);
                serviceStates.TryGetValue(service, out var state);
                ApplyServiceModeForExport(imported, isUpdateCatalogExport: true, state);
                newNode.AppendChild(imported);
            }
        }

        return exportDoc;
    }

    private int GetNextUpdateCatalogSeqNumber()
    {
        var updateCatalog = GetUpdateCatalogNode();
        if (updateCatalog?.Attributes?["seq_number"]?.Value is { } value
            && int.TryParse(value, out var current))
            return current + 1;

        return 1;
    }

    private void ApplyServiceModeForWorkingCopy(XmlNode service)
    {
        if (GetUpdateCatalogNode() != null)
            service.SetAttribute("mode", "new");
        else
            RemoveServiceModeAttribute(service);
    }

    /// <summary>
    /// mode="new" ist laut OpenQCat optional (fixed="new"). Nur bei UPDATE_CATALOG/NEW für
    /// wirklich neue Services setzen – nicht bei Vollkatalog oder Updates bestehender Angebote.
    /// </summary>
    private static void ApplyServiceModeForExport(
        XmlNode service,
        bool isUpdateCatalogExport,
        ServiceState? state = null)
    {
        if (!isUpdateCatalogExport)
        {
            RemoveServiceModeAttribute(service);
            return;
        }

        if (state == ServiceState.New)
            service.SetAttribute("mode", "new");
        else
            RemoveServiceModeAttribute(service);
    }

    private static void RemoveServiceModeAttribute(XmlNode service)
    {
        service.Attributes?.RemoveNamedItem("mode");
    }

    private void AppendExportHeader(XmlDocument exportDoc, XmlElement root)
    {
        if (headerTemplate == null)
            return;

        var importedHeader = exportDoc.ImportNode(headerTemplate, deep: true);
        EnsureSupplierRequiredContent(importedHeader);
        SanitizeKursnetHeader(importedHeader);
        ApplyExportGenerationDate(importedHeader);
        headerTemplate = importedHeader.CloneNode(deep: true);
        root.AppendChild(importedHeader);
    }

    /// <summary>
    /// XSD requires SUPPLIER/EXTENDED_INFO (minOccurs=1). Incomplete headers from
    /// older exports are enriched from Main.xml when possible.
    /// </summary>
    private void EnsureSupplierRequiredContent(XmlNode header)
    {
        var supplier = header.ChildNodes
            .Cast<XmlNode>()
            .FirstOrDefault(n => n.LocalName.Equals("SUPPLIER", StringComparison.OrdinalIgnoreCase));
        if (supplier == null)
            return;

        var hasExtendedInfo = supplier.ChildNodes
            .Cast<XmlNode>()
            .Any(n => n.LocalName.Equals("EXTENDED_INFO", StringComparison.OrdinalIgnoreCase));
        var hasKeyword = supplier.ChildNodes
            .Cast<XmlNode>()
            .Any(n => n.LocalName.Equals("KEYWORD", StringComparison.OrdinalIgnoreCase));
        if (hasExtendedInfo && hasKeyword)
            return;

        var templateSupplier = LoadMainTemplateSupplier();
        var owner = supplier.OwnerDocument;
        if (templateSupplier != null && owner != null)
        {
            if (!hasKeyword)
            {
                foreach (XmlNode keyword in templateSupplier.ChildNodes)
                {
                    if (!keyword.LocalName.Equals("KEYWORD", StringComparison.OrdinalIgnoreCase))
                        continue;
                    supplier.AppendChild(owner.ImportNode(keyword, deep: true));
                }
            }

            if (!hasExtendedInfo)
            {
                var extended = templateSupplier.ChildNodes
                    .Cast<XmlNode>()
                    .FirstOrDefault(n =>
                        n.LocalName.Equals("EXTENDED_INFO", StringComparison.OrdinalIgnoreCase));
                if (extended != null)
                {
                    supplier.AppendChild(owner.ImportNode(extended, deep: true));
                    return;
                }
            }
            else
            {
                return;
            }
        }

        if (hasExtendedInfo || owner == null)
            return;

        var supplierId = supplier.GetChildText("SUPPLIER_ID")?.Trim() ?? "";
        var extendedInfo = owner.CreateElement("EXTENDED_INFO");
        var inputType = owner.CreateAttribute("input_type");
        inputType.Value = "0";
        extendedInfo.Attributes.Append(inputType);

        if (!string.IsNullOrEmpty(supplierId))
        {
            var institutionNumber = owner.CreateElement("INSTITUTION_NUMBER");
            institutionNumber.InnerText = supplierId;
            extendedInfo.AppendChild(institutionNumber);
        }

        var organizationalForm = owner.CreateElement("ORGANIZATIONAL_FORM");
        var typeAttr = owner.CreateAttribute("type");
        typeAttr.Value = "2";
        organizationalForm.Attributes.Append(typeAttr);
        organizationalForm.InnerText = "Private Bildungseinrichtung";
        extendedInfo.AppendChild(organizationalForm);

        supplier.AppendChild(extendedInfo);
    }

    private XmlNode? LoadMainTemplateSupplier()
    {
        var mainPath = Path.Combine(servicesTemplateFolder, "Main.xml");
        if (!File.Exists(mainPath))
            return null;

        try
        {
            var doc = new XmlDocument { PreserveWhitespace = true };
            doc.Load(mainPath);
            var header = doc.DocumentElement?.ChildNodes
                .Cast<XmlNode>()
                .FirstOrDefault(n => n.LocalName.Equals("HEADER", StringComparison.OrdinalIgnoreCase));
            return header?.ChildNodes
                .Cast<XmlNode>()
                .FirstOrDefault(n => n.LocalName.Equals("SUPPLIER", StringComparison.OrdinalIgnoreCase));
        }
        catch
        {
            return null;
        }
    }

    private static void ApplyExportGenerationDate(XmlNode header)
    {
        var catalog = header.ChildNodes
            .Cast<XmlNode>()
            .FirstOrDefault(n => n.LocalName.Equals("CATALOG", StringComparison.OrdinalIgnoreCase));

        if (catalog == null)
            return;

        var generationDate = catalog.ChildNodes
            .Cast<XmlNode>()
            .FirstOrDefault(n => n.LocalName.Equals("GENERATION_DATE", StringComparison.OrdinalIgnoreCase));

        var value = FormatGenerationDate(DateTime.Now);

        if (generationDate != null)
        {
            generationDate.InnerText = value;
            return;
        }

        var doc = catalog.OwnerDocument;
        if (doc == null)
            return;

        var newNode = doc.CreateElement("GENERATION_DATE");
        newNode.InnerText = value;
        catalog.AppendChild(newNode);
    }

    private static string FormatGenerationDate(DateTime dateTime)
    {
        var offset = TimeZoneInfo.Local.GetUtcOffset(dateTime);
        return new DateTimeOffset(dateTime, offset).ToString("yyyy-MM-dd'T'HH:mm:ss.fffzzz");
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
        SyncCourseIdWithProductId(service);
        SanitizeKursnetSubtree(service);
    }

    private static void SanitizeKursnetHeader(XmlNode header)
    {
        SanitizeKursnetSubtree(header);
        EnsureDocumentCreatorFields(header);
        EnsureSupplierContactRole(header);
    }

    private static void SanitizeKursnetSubtree(XmlNode node)
    {
        var children = node.ChildNodes.Cast<XmlNode>().ToList();
        foreach (var child in children)
        {
            if (child.NodeType != XmlNodeType.Element)
                continue;

            if (child.LocalName.Equals("COUNTRY", StringComparison.OrdinalIgnoreCase))
            {
                var value = (child.InnerText ?? "").Trim().ToLowerInvariant();
                if (value is "deutschland" or "germany" or "d" or "de")
                    child.InnerText = "DE";
            }

            if (child.LocalName.Equals("PHONE", StringComparison.OrdinalIgnoreCase) ||
                child.LocalName.Equals("FAX", StringComparison.OrdinalIgnoreCase) ||
                child.LocalName.Equals("MOBILE", StringComparison.OrdinalIgnoreCase))
            {
                if (string.IsNullOrWhiteSpace(child.InnerText))
                {
                    child.ParentNode?.RemoveChild(child);
                    continue;
                }
            }

            if (child.LocalName.Equals("CERT_VALIDITY", StringComparison.OrdinalIgnoreCase) &&
                string.IsNullOrWhiteSpace(child.InnerText) &&
                !child.HasChildNodes)
            {
                child.ParentNode?.RemoveChild(child);
                continue;
            }

            SanitizeKursnetSubtree(child);
        }
    }

    private static void EnsureDocumentCreatorFields(XmlNode header)
    {
        var creator = header.ChildNodes.Cast<XmlNode>().FirstOrDefault(n =>
            n.LocalName.Equals("DOCUMENT_CREATOR", StringComparison.OrdinalIgnoreCase));
        if (creator?.OwnerDocument == null)
            return;

        if (!creator.ChildNodes.Cast<XmlNode>().Any(n =>
                n.LocalName.Equals("SALUTATION", StringComparison.OrdinalIgnoreCase)))
        {
            var salutation = creator.OwnerDocument.CreateElement("SALUTATION");
            salutation.InnerText = "m";
            var first = creator.ChildNodes.Cast<XmlNode>().FirstOrDefault(n =>
                n.LocalName.Equals("FIRST_NAME", StringComparison.OrdinalIgnoreCase));
            if (first != null)
                creator.InsertBefore(salutation, first);
            else
                creator.PrependChild(salutation);
        }

        var emails = creator.ChildNodes.Cast<XmlNode>().FirstOrDefault(n =>
            n.LocalName.Equals("EMAILS", StringComparison.OrdinalIgnoreCase));
        if (emails != null)
            return;

        var emailsNode = creator.OwnerDocument.CreateElement("EMAILS");
        var email = creator.OwnerDocument.CreateElement("EMAIL");
        email.InnerText = "info@cdemy.de";
        emailsNode.AppendChild(email);
        var phone = creator.ChildNodes.Cast<XmlNode>().FirstOrDefault(n =>
            n.LocalName.Equals("PHONE", StringComparison.OrdinalIgnoreCase));
        if (phone?.NextSibling != null)
            creator.InsertAfter(emailsNode, phone);
        else
            creator.AppendChild(emailsNode);
    }

    private static void EnsureSupplierContactRole(XmlNode header)
    {
        var supplier = header.ChildNodes.Cast<XmlNode>().FirstOrDefault(n =>
            n.LocalName.Equals("SUPPLIER", StringComparison.OrdinalIgnoreCase));
        if (supplier == null)
            return;

        var contacts = supplier.ChildNodes.Cast<XmlNode>()
            .Where(n => n.LocalName.Equals("CONTACT", StringComparison.OrdinalIgnoreCase))
            .ToList();
        if (contacts.Count == 0)
            return;

        var hasRequired = contacts.Any(c =>
        {
            var role = c.ChildNodes.Cast<XmlNode>().FirstOrDefault(n =>
                n.LocalName.Equals("CONTACT_ROLE", StringComparison.OrdinalIgnoreCase));
            var type = role?.Attributes?["type"]?.Value;
            return type is "2" or "3";
        });
        if (hasRequired)
            return;

        var first = contacts[0];
        var existingRole = first.ChildNodes.Cast<XmlNode>().FirstOrDefault(n =>
            n.LocalName.Equals("CONTACT_ROLE", StringComparison.OrdinalIgnoreCase));
        if (existingRole == null)
        {
            if (first.OwnerDocument == null)
                return;
            var role = first.OwnerDocument.CreateElement("CONTACT_ROLE");
            var attr = first.OwnerDocument.CreateAttribute("type");
            attr.Value = "3";
            role.Attributes.Append(attr);
            role.InnerText = "Leiter des Betriebs";
            first.PrependChild(role);
            return;
        }

        var typeAttr = existingRole.Attributes?["type"];
        if (typeAttr != null)
            typeAttr.Value = "3";
        existingRole.InnerText = "Leiter des Betriebs";
    }

    private static void SyncCourseIdWithProductId(XmlNode service)
    {
        var education = service.GetNodeByPath("SERVICE_DETAILS/SERVICE_MODULE/EDUCATION");
        if (education == null)
            return;

        var typeAttr = education.Attributes?["type"]?.Value;
        if (!string.Equals(typeAttr, "true", StringComparison.OrdinalIgnoreCase))
            return;

        var productId = service.GetChildText("PRODUCT_ID");
        if (string.IsNullOrWhiteSpace(productId))
            return;

        education.SetChildText("COURSE_ID", productId);
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
