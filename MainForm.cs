using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Windows.Forms;
using System.Xml;
using System.Xml.Schema;
using System.Drawing;

namespace XmlEditorUi;

public class MainForm : Form
{
    private enum ServiceState
    {
        Unchanged,
        New,
        Updated
    }

    private record DeletedServiceInfo(string ProductId, string Title);

    private readonly Button openButton = new();
    private readonly Button exportButton = new();
    private readonly Button validateButton = new();

    private readonly ListBox courseList = new();
    private readonly PropertyGrid courseGrid = new();

    private readonly Button addCourseButton = new();
    private readonly Button removeCourseButton = new();
    private readonly Button saveTemplateButton = new();
    private readonly Button addFromTemplateButton = new();
    private readonly TabControl mainTabs = new();
    private readonly TabPage serviceEditorTab = new("Service bearbeiten");
    private readonly TabPage templateEditorTab = new("Vorlagen bearbeiten");

    private readonly TreeView templateTree = new();
    private readonly DataGridView templateQuickGrid = new();
    private readonly PropertyGrid templatePropertyGrid = new();

    private readonly Button saveTemplateChangesButton = new();
    private readonly Button reloadTemplatesButton = new();

    private readonly string servicesTemplateFolder =
        Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "templates", "services");

    private readonly string profilesFolder =
        Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "templates", "profiles");

    private TemplateProfileManager? profileManager;
    private List<LocationProfile> locationProfiles = new();
    private List<CourseTypeProfile> courseTypeProfiles = new();

    private XmlDocument? selectedTemplateDoc;
    private string? selectedTemplatePath;
    private XmlNode? selectedTemplateService;
    private readonly TabControl statusTabs = new();
    private readonly ListBox newServicesList = new();
    private readonly ListBox updatedServicesList = new();
    private readonly ListBox deletedServicesList = new();
    private readonly DataGridView quickFieldsGrid = new();

    private readonly Button refreshViewButton = new();

    private readonly Dictionary<XmlNode, HashSet<string>> pendingTemplateFields = new();
    private readonly Dictionary<XmlNode, HashSet<string>> changedImportantFields = new();

    private readonly Dictionary<XmlNode, ServiceState> serviceStates = new();
    private readonly List<DeletedServiceInfo> deletedServices = new();
    private static readonly List<QuickFieldDefinition> ImportantFields = new()
{
    new("Produkt-ID", "PRODUCT_ID"),
    //new("Course-ID", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/COURSE_ID"),

   // new("Kurstitel", "SERVICE_DETAILS/TITLE"),

    new("Startdatum Kurs", "SERVICE_DETAILS/SERVICE_DATE/START_DATE"),
    new("Enddatum Kurs", "SERVICE_DETAILS/SERVICE_DATE/END_DATE"),

    new("Ankündigung Start", "SERVICE_DETAILS/ANNOUNCEMENT/START_DATE"),
    new("Ankündigung Ende", "SERVICE_DETAILS/ANNOUNCEMENT/END_DATE"),

    new("Min. Teilnehmer", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/MIN_PARTICIPANTS"),
    new("Max. Teilnehmer", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/MAX_PARTICIPANTS"),

    new("Preis", "SERVICE_PRICE_DETAILS/SERVICE_PRICE/PRICE_AMOUNT"),

   // new("Ort Name", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/NAME"),
    //new("Straße", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/STREET"),
    //new("PLZ", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/ZIP"),
    //new("Stadt", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/CITY"),
    //new("Bundesland", "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/STATE")
};

    private record QuickFieldDefinition(string Label, string Path);
    private XmlDocument? document;
    private XmlNode? selectedCourse;

    private readonly string templateFolder =
        Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "templates");

    public MainForm()
    {
        Text = "XML Service Editor";
        Width = 1200;
        Height = 820;
        mainTabs.Dock = DockStyle.Fill;

        mainTabs.TabPages.Add(serviceEditorTab);
        mainTabs.TabPages.Add(templateEditorTab);

        Controls.Add(mainTabs);

        Directory.CreateDirectory(templateFolder);

        openButton.Text = "XML öffnen";
        openButton.Left = 10;
        openButton.Top = 10;
        openButton.Width = 120;
        openButton.Click += OpenXml;

        exportButton.Text = "Exportieren";
        exportButton.Left = 140;
        exportButton.Top = 10;
        exportButton.Width = 120;
        exportButton.Click += ExportXml;

        validateButton.Text = "Gegen XSD prüfen";
        validateButton.Left = 270;
        validateButton.Top = 10;
        validateButton.Width = 140;
        validateButton.Click += ValidateXml;

        courseList.Left = 10;
        courseList.Top = 60;
        courseList.Width = 420;
        courseList.Height = 530;
        courseList.SelectedIndexChanged += CourseList_SelectedIndexChanged;

        courseGrid.Left = 450;
        courseGrid.Top = 60;
        courseGrid.Width = 700;
        courseGrid.Height = 450;
        courseGrid.PropertyValueChanged += CourseGrid_PropertyValueChanged;
        courseGrid.ToolbarVisible = false;
        courseGrid.PropertySort = PropertySort.NoSort;
        courseGrid.HelpVisible = false;

        addCourseButton.Text = "Neuer Service";
        addCourseButton.Left = 450;
        addCourseButton.Top = 525;
        addCourseButton.Width = 130;
        addCourseButton.Click += AddEmptyCourse;

        addFromTemplateButton.Text = "Aus Vorlage";
        addFromTemplateButton.Left = 590;
        addFromTemplateButton.Top = 525;
        addFromTemplateButton.Width = 130;
        addFromTemplateButton.Click += AddCourseFromTemplate;

        saveTemplateButton.Text = "Vorlage speichern";
        saveTemplateButton.Left = 730;
        saveTemplateButton.Top = 525;
        saveTemplateButton.Width = 150;
        saveTemplateButton.Click += SaveTemplate;

        removeCourseButton.Text = "Service entfernen";
        removeCourseButton.Left = 890;
        removeCourseButton.Top = 525;
        removeCourseButton.Width = 150;
        removeCourseButton.Click += RemoveCourse;

        statusTabs.Left = 10;
        statusTabs.Top = 610;
        statusTabs.Width = 1140;
        statusTabs.Height = 150;

        AddStatusTab("Neu hinzugefügt", newServicesList);
        AddStatusTab("Geändert / Update", updatedServicesList);
        AddStatusTab("Gelöscht", deletedServicesList);

        serviceEditorTab.Controls.Add(openButton);
        serviceEditorTab.Controls.Add(exportButton);
        serviceEditorTab.Controls.Add(validateButton);
        serviceEditorTab.Controls.Add(courseList);
        serviceEditorTab.Controls.Add(courseGrid);
        serviceEditorTab.Controls.Add(addCourseButton);
        serviceEditorTab.Controls.Add(addFromTemplateButton);
        serviceEditorTab.Controls.Add(saveTemplateButton);
        serviceEditorTab.Controls.Add(removeCourseButton);
        serviceEditorTab.Controls.Add(statusTabs);
        serviceEditorTab.Controls.Add(quickFieldsGrid);

        quickFieldsGrid.Left = 450;
        quickFieldsGrid.Top = 60;
        quickFieldsGrid.Width = 700;
        quickFieldsGrid.Height = 210;
        quickFieldsGrid.AllowUserToAddRows = false;
        quickFieldsGrid.AllowUserToDeleteRows = false;
        quickFieldsGrid.RowHeadersVisible = false;
        quickFieldsGrid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
        quickFieldsGrid.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
        quickFieldsGrid.Columns.Add("Field", "Feld");
        quickFieldsGrid.Columns.Add("Value", "Wert");
        quickFieldsGrid.Columns["Field"]!.ReadOnly = true;
        quickFieldsGrid.CellValueChanged += QuickFieldsGrid_CellValueChanged;
        quickFieldsGrid.CurrentCellDirtyStateChanged += (_, _) =>
        {
            if (quickFieldsGrid.IsCurrentCellDirty)
                quickFieldsGrid.CommitEdit(DataGridViewDataErrorContexts.Commit);
        };

        courseGrid.Left = 450;
        courseGrid.Top = 285;
        courseGrid.Width = 700;
        courseGrid.Height = 225;

        refreshViewButton.Text = "Ansicht aktualisieren";
        refreshViewButton.Left = 1050;
        refreshViewButton.Top = 525;
        refreshViewButton.Width = 130;
        refreshViewButton.Click += (_, _) =>
        {
            courseGrid.SelectedObject = selectedCourse == null
                ? null
                : new CourseEditableObject(selectedCourse, onlyFilledFields: true);

            RefreshSelectedCourseTitle();
            RefreshStatusLists();
        };

        Controls.Add(refreshViewButton);
        quickFieldsGrid.CellClick += QuickFieldsGrid_CellClick;

        Directory.CreateDirectory(servicesTemplateFolder);
        Directory.CreateDirectory(profilesFolder);

        profileManager = new TemplateProfileManager(profilesFolder);

        BuildTemplateEditorTab();
        LoadTemplateProfilesAndTree();
    }

    private void BuildTemplateEditorTab()
    {
        templateTree.Left = 10;
        templateTree.Top = 10;
        templateTree.Width = 330;
        templateTree.Height = 650;
        templateTree.AfterSelect += TemplateTree_AfterSelect;

        reloadTemplatesButton.Text = "Vorlagen neu laden";
        reloadTemplatesButton.Left = 360;
        reloadTemplatesButton.Top = 10;
        reloadTemplatesButton.Width = 150;
        reloadTemplatesButton.Click += (_, _) => LoadTemplateProfilesAndTree();

        saveTemplateChangesButton.Text = "Vorlage speichern";
        saveTemplateChangesButton.Left = 520;
        saveTemplateChangesButton.Top = 10;
        saveTemplateChangesButton.Width = 150;
        saveTemplateChangesButton.Click += SaveSelectedTemplate;

        templateQuickGrid.Left = 360;
        templateQuickGrid.Top = 50;
        templateQuickGrid.Width = 760;
        templateQuickGrid.Height = 230;
        templateQuickGrid.AllowUserToAddRows = false;
        templateQuickGrid.AllowUserToDeleteRows = false;
        templateQuickGrid.RowHeadersVisible = false;
        templateQuickGrid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
        templateQuickGrid.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
        templateQuickGrid.Columns.Add("Field", "Feld");
        templateQuickGrid.Columns.Add("Value", "Wert");
        templateQuickGrid.Columns["Field"]!.ReadOnly = true;
        templateQuickGrid.CellValueChanged += TemplateQuickGrid_CellValueChanged;

        templatePropertyGrid.Left = 360;
        templatePropertyGrid.Top = 300;
        templatePropertyGrid.Width = 760;
        templatePropertyGrid.Height = 360;
        templatePropertyGrid.ToolbarVisible = false;
        templatePropertyGrid.HelpVisible = false;

        templateEditorTab.Controls.Add(templateTree);
        templateEditorTab.Controls.Add(reloadTemplatesButton);
        templateEditorTab.Controls.Add(saveTemplateChangesButton);
        templateEditorTab.Controls.Add(templateQuickGrid);
        templateEditorTab.Controls.Add(templatePropertyGrid);
    }

    private void LoadTemplateProfilesAndTree()
    {
        if (profileManager == null)
            return;

        locationProfiles = profileManager.LoadLocations();
        courseTypeProfiles = profileManager.LoadCourseTypes();

        templateTree.Nodes.Clear();

        var root = new TreeNode("Vorlagen");
        templateTree.Nodes.Add(root);

        var files = Directory.GetFiles(servicesTemplateFolder, "*.xml");

        foreach (var file in files)
        {
            var doc = new XmlDocument();
            doc.Load(file);

            if (doc.DocumentElement == null)
                continue;

            var service = doc.DocumentElement;

            var city = GetTextByPath(service,
                "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/CITY") ?? "Ort ?";

            var time = GetTextByPath(service,
                "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_TIME") ?? "Zeit ?";

            var educationType = GetTextByPath(service,
                "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/EDUCATION_TYPE") ?? "";

            var typeName = educationType.Contains("Extern", StringComparison.OrdinalIgnoreCase)
                ? "Externenprüfung"
                : time;

            var cityNode = FindOrCreateTreeNode(root, city);
            var typeNode = FindOrCreateTreeNode(cityNode, typeName);

            var templateNode = new TreeNode(Path.GetFileNameWithoutExtension(file))
            {
                Tag = file
            };

            typeNode.Nodes.Add(templateNode);
        }

        root.Expand();
    }

    private static TreeNode FindOrCreateTreeNode(TreeNode parent, string text)
    {
        foreach (TreeNode child in parent.Nodes)
        {
            if (child.Text.Equals(text, StringComparison.OrdinalIgnoreCase))
                return child;
        }

        var node = new TreeNode(text);
        parent.Nodes.Add(node);
        return node;
    }

    private void TemplateTree_AfterSelect(object? sender, TreeViewEventArgs e)
    {
        if (e.Node?.Tag is not string path)
            return;

        selectedTemplatePath = path;
        selectedTemplateDoc = new XmlDocument();
        selectedTemplateDoc.PreserveWhitespace = true;
        selectedTemplateDoc.Load(path);

        selectedTemplateService = selectedTemplateDoc.DocumentElement;

        LoadTemplateQuickFields();

        if (selectedTemplateService != null)
            templatePropertyGrid.SelectedObject =
                new CourseEditableObject(selectedTemplateService, onlyFilledFields: true);
    }

    private void LoadTemplateQuickFields()
    {
        templateQuickGrid.Rows.Clear();

        if (selectedTemplateService == null)
            return;

        foreach (var field in ImportantFields)
        {
            var value = GetTextByPath(selectedTemplateService, field.Path) ?? "";

            var rowIndex = templateQuickGrid.Rows.Add(field.Label, value);
            var row = templateQuickGrid.Rows[rowIndex];
            row.Tag = field.Path;
        }
    }

    private void TemplateQuickGrid_CellValueChanged(object? sender, DataGridViewCellEventArgs e)
    {
        if (selectedTemplateService == null)
            return;

        if (e.RowIndex < 0 || e.ColumnIndex != 1)
            return;

        var row = templateQuickGrid.Rows[e.RowIndex];

        if (row.Tag is not string path)
            return;

        var newValue = row.Cells[1].Value?.ToString() ?? "";

        SetNodeByPath(selectedTemplateService, path, newValue);

        // Wenn Standortdaten geändert werden, auf alle Vorlagen mit gleichem Ort anwenden
        if (path.Contains("/LOCATION/", StringComparison.OrdinalIgnoreCase))
        {
            var city = GetTextByPath(selectedTemplateService,
                "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/CITY");

            if (!string.IsNullOrWhiteSpace(city))
                ApplyLocationChangeToAllTemplates(city, path, newValue);
        }

        // Wenn Vollzeit/Teilzeit geändert wird, nur Kurszeit-Profil aktualisieren
        if (path.Contains("INSTRUCTION_TIME", StringComparison.OrdinalIgnoreCase))
        {
            var instructionTime = newValue.Trim();
            ApplyInstructionTimeToMatchingTemplates(instructionTime, newValue);
        }

        templatePropertyGrid.SelectedObject =
            new CourseEditableObject(selectedTemplateService, onlyFilledFields: true);
    }

    private void ApplyLocationChangeToAllTemplates(string city, string changedPath, string newValue)
    {
        var files = Directory.GetFiles(servicesTemplateFolder, "*.xml");

        foreach (var file in files)
        {
            if (file == selectedTemplatePath)
                continue;

            var doc = new XmlDocument();
            doc.PreserveWhitespace = true;
            doc.Load(file);

            if (doc.DocumentElement == null)
                continue;

            var service = doc.DocumentElement;

            var templateCity = GetTextByPath(service,
                "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/CITY");

            if (!string.Equals(templateCity, city, StringComparison.OrdinalIgnoreCase))
                continue;

            SetNodeByPathForDocument(doc, service, changedPath, newValue);
            doc.Save(file);
        }
    }

    private void ApplyInstructionTimeToMatchingTemplates(string instructionTime, string newValue)
    {
        var files = Directory.GetFiles(servicesTemplateFolder, "*.xml");

        foreach (var file in files)
        {
            if (file == selectedTemplatePath)
                continue;

            var doc = new XmlDocument();
            doc.PreserveWhitespace = true;
            doc.Load(file);

            if (doc.DocumentElement == null)
                continue;

            var service = doc.DocumentElement;

            var current = GetTextByPath(service,
                "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_TIME");

            if (!string.Equals(current, instructionTime, StringComparison.OrdinalIgnoreCase))
                continue;

            SetNodeByPathForDocument(doc, service,
                "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_TIME",
                newValue);

            doc.Save(file);
        }
    }

    private void SaveSelectedTemplate(object? sender, EventArgs e)
    {
        if (selectedTemplateDoc == null || string.IsNullOrWhiteSpace(selectedTemplatePath))
        {
            MessageBox.Show("Bitte Vorlage auswählen.");
            return;
        }

        selectedTemplateDoc.Save(selectedTemplatePath);
        MessageBox.Show("Vorlage gespeichert.");

        LoadTemplateProfilesAndTree();
    }

    private static XmlNode SetNodeByPathForDocument(XmlDocument doc, XmlNode startNode, string path, string value)
    {
        var current = startNode;

        foreach (var part in path.Split('/'))
        {
            var next = current.ChildNodes
                .Cast<XmlNode>()
                .FirstOrDefault(n => n.LocalName.Equals(part, StringComparison.OrdinalIgnoreCase));

            if (next == null)
            {
                next = doc.CreateElement(part);
                current.AppendChild(next);
            }

            current = next;
        }

        current.InnerText = value;
        return current;
    }
    private void QuickFieldsGrid_CellClick(object? sender, DataGridViewCellEventArgs e)
    {
        if (selectedCourse == null)
            return;

        if (e.RowIndex < 0 || e.ColumnIndex != 1)
            return;

        var row = quickFieldsGrid.Rows[e.RowIndex];

        if (row.Tag is not string path)
            return;

        if (!IsDateField(path))
            return;

        ShowDatePicker(row, path);
    }
    private bool IsDateField(string path)
    {
        return path.Contains("START_DATE") || path.Contains("END_DATE");
    }
    private void ShowDatePicker(DataGridViewRow row, string path)
    {
        if (selectedCourse == null)
            return;

        bool isCourseDate = path.Contains("SERVICE_DATE", StringComparison.OrdinalIgnoreCase);

        var currentValue = row.Cells[1].Value?.ToString();

        if (!TryParseDate(currentValue, out var initialDate))
            initialDate = DateTime.Now;

        using var popup = new DateTimePickerPopup(initialDate, includeTime: isCourseDate);

        if (popup.ShowDialog(this) != DialogResult.OK)
            return;

        string formatted = isCourseDate
            ? popup.SelectedValue.ToString("yyyy-MM-dd'T'HH:mm:ss.000+01:00")
            : popup.SelectedValue.ToString("yyyy-MM-dd+01:00");

        row.Cells[1].Value = formatted;

        SetNodeByPath(selectedCourse, path, formatted);
        MarkFieldAsChanged(selectedCourse, path);

        ApplyQuickFieldColor(row, selectedCourse, path);
    }
    private bool TryParseDate(string? value, out DateTime dt)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            dt = DateTime.Now;
            return false;
        }

        var clean = value.Trim();

        if (clean.Contains("T"))
        {
            var main = clean.Split('+')[0];
            return DateTime.TryParse(main, out dt);
        }

        if (clean.Contains("+"))
            clean = clean.Split('+')[0];

        return DateTime.TryParse(clean, out dt);
    }
    private void MarkFieldAsChanged(XmlNode service, string path)
    {
        if (!changedImportantFields.ContainsKey(service))
            changedImportantFields[service] = new HashSet<string>();

        changedImportantFields[service].Add(path);

        if (pendingTemplateFields.TryGetValue(service, out var pending))
            pending.Remove(path);

        if (!serviceStates.ContainsKey(service))
            serviceStates[service] = ServiceState.Unchanged;

        if (serviceStates[service] == ServiceState.Unchanged)
            serviceStates[service] = ServiceState.Updated;

        LoadQuickFields();
        RefreshStatusLists();
    }
    private string GenerateNewProductId()
    {
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
    private bool ProductIdExists(string productId)
    {
        return document!
            .GetElementsByTagName("*")
            .Cast<XmlNode>()
            .Where(n => n.LocalName.Equals("PRODUCT_ID", StringComparison.OrdinalIgnoreCase))
            .Any(n => n.InnerText.Trim() == productId);
    }
    private void AddStatusTab(string title, ListBox listBox)
    {
        var tab = new TabPage(title);
        listBox.Dock = DockStyle.Fill;
        tab.Controls.Add(listBox);
        statusTabs.TabPages.Add(tab);
    }

    private void OpenXml(object? sender, EventArgs e)
    {
        using var dialog = new OpenFileDialog();
        dialog.Filter = "XML Dateien (*.xml)|*.xml|Alle Dateien (*.*)|*.*";

        if (dialog.ShowDialog() != DialogResult.OK)
            return;

        document = new XmlDocument();
        document.PreserveWhitespace = true;
        document.Load(dialog.FileName);

        serviceStates.Clear();
        deletedServices.Clear();

        LoadCourses();
        RefreshStatusLists();
    }

    private void LoadCourses()
    {
        courseList.Items.Clear();
        courseGrid.SelectedObject = null;
        selectedCourse = null;

        if (document?.DocumentElement == null)
            return;

        var services = document
            .GetElementsByTagName("*")
            .Cast<XmlNode>()
            .Where(IsServiceNode)
            .ToList();

        foreach (var service in services)
        {
            if (!serviceStates.ContainsKey(service))
                serviceStates[service] = ServiceState.Unchanged;
        }

        if (services.Count == 0)
        {
            MessageBox.Show("XML geladen, aber keine SERVICE-Einträge außerhalb von DELETE gefunden.");
            return;
        }

        for (int i = 0; i < services.Count; i++)
        {
            courseList.Items.Add(new CourseListItem(services[i], BuildServiceTitleWithState(services[i], i)));
        }
    }
    private void LoadQuickFields()
    {
        quickFieldsGrid.Rows.Clear();

        if (selectedCourse == null)
            return;

        foreach (var field in ImportantFields)
        {
            var value = GetNodeByPath(selectedCourse, field.Path)?.InnerText ?? "";

            var rowIndex = quickFieldsGrid.Rows.Add(field.Label, value);
            var row = quickFieldsGrid.Rows[rowIndex];
            row.Tag = field.Path;

            ApplyQuickFieldColor(row, selectedCourse, field.Path);
        }
    }

    private void ApplyQuickFieldColor(DataGridViewRow row, XmlNode service, string path)
    {
        if (pendingTemplateFields.TryGetValue(service, out var pending)
            && pending.Contains(path))
        {
            row.DefaultCellStyle.BackColor = Color.LightCoral;
            return;
        }

        if (changedImportantFields.TryGetValue(service, out var changed)
            && changed.Contains(path))
        {
            row.DefaultCellStyle.BackColor = Color.LightGreen;
            return;
        }

        row.DefaultCellStyle.BackColor = Color.LightBlue;
    }

    private void QuickFieldsGrid_CellValueChanged(object? sender, DataGridViewCellEventArgs e)
    {
        if (selectedCourse == null)
            return;

        if (e.RowIndex < 0 || e.ColumnIndex != 1)
            return;

        var row = quickFieldsGrid.Rows[e.RowIndex];

        if (row.Tag is not string path)
            return;

        var newValue = row.Cells[1].Value?.ToString() ?? "";

        SetNodeByPath(selectedCourse, path, newValue);

        if (!changedImportantFields.ContainsKey(selectedCourse))
            changedImportantFields[selectedCourse] = new HashSet<string>();

        changedImportantFields[selectedCourse].Add(path);

        if (pendingTemplateFields.TryGetValue(selectedCourse, out var pending))
            pending.Remove(path);

        if (!serviceStates.ContainsKey(selectedCourse))
            serviceStates[selectedCourse] = ServiceState.Unchanged;

        if (serviceStates[selectedCourse] == ServiceState.Unchanged)
            serviceStates[selectedCourse] = ServiceState.Updated;

        ApplyQuickFieldColor(row, selectedCourse, path);

        // courseGrid.SelectedObject = new CourseEditableObject(selectedCourse, onlyFilledFields: true);

        //        RefreshSelectedCourseTitle();
        //      RefreshStatusLists();
    }

    private XmlNode? GetNodeByPath(XmlNode startNode, string path)
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

    private XmlNode SetNodeByPath(XmlNode startNode, string path, string value)
    {
        var current = startNode;

        foreach (var part in path.Split('/'))
        {
            var next = current.ChildNodes
                .Cast<XmlNode>()
                .FirstOrDefault(n => n.LocalName.Equals(part, StringComparison.OrdinalIgnoreCase));

            if (next == null)
            {
                next = document!.CreateElement(part);
                current.AppendChild(next);
            }

            current = next;
        }

        current.InnerText = value;
        return current;
    }
    private void CourseList_SelectedIndexChanged(object? sender, EventArgs e)
    {
        if (courseList.SelectedItem is not CourseListItem item)
            return;

        selectedCourse = item.Node;
        courseGrid.SelectedObject = new CourseEditableObject(selectedCourse, onlyFilledFields: true);
        LoadQuickFields();
    }

    private void CourseGrid_PropertyValueChanged(object s, PropertyValueChangedEventArgs e)
    {
        if (selectedCourse != null)
        {
            if (!serviceStates.ContainsKey(selectedCourse))
                serviceStates[selectedCourse] = ServiceState.Unchanged;

            if (serviceStates[selectedCourse] == ServiceState.Unchanged)
                serviceStates[selectedCourse] = ServiceState.Updated;
        }

        RefreshSelectedCourseTitle();
        RefreshStatusLists();
    }

    private void RefreshSelectedCourseTitle()
    {
        if (courseList.SelectedIndex < 0 || selectedCourse == null)
            return;

        int index = courseList.SelectedIndex;
        courseList.Items[index] = new CourseListItem(selectedCourse, BuildServiceTitleWithState(selectedCourse, index));
        courseList.SelectedIndex = index;
    }

    private void RefreshStatusLists()
    {
        newServicesList.Items.Clear();
        updatedServicesList.Items.Clear();
        deletedServicesList.Items.Clear();

        int index = 0;

        foreach (var entry in serviceStates.ToList())
        {
            if (entry.Key.ParentNode == null)
                continue;

            var title = BuildServiceTitle(entry.Key, index++);

            if (entry.Value == ServiceState.New)
                newServicesList.Items.Add(title);

            if (entry.Value == ServiceState.Updated)
                updatedServicesList.Items.Add(title);
        }

        foreach (var deleted in deletedServices)
        {
            deletedServicesList.Items.Add($"{deleted.ProductId} | {deleted.Title}");
        }

        statusTabs.TabPages[0].Text = $"Neu hinzugefügt ({newServicesList.Items.Count})";
        statusTabs.TabPages[1].Text = $"Geändert / Update ({updatedServicesList.Items.Count})";
        statusTabs.TabPages[2].Text = $"Gelöscht ({deletedServicesList.Items.Count})";
    }

    private string BuildServiceTitleWithState(XmlNode service, int index)
    {
        var title = BuildServiceTitle(service, index);

        if (!serviceStates.TryGetValue(service, out var state))
            return title;

        return state switch
        {
            ServiceState.New => "[NEU] " + title,
            ServiceState.Updated => "[UPDATE] " + title,
            _ => title
        };
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

    private static string BuildServiceTitle(XmlNode service, int index)
    {
        var productId = GetChildText(service, "PRODUCT_ID");

        var title = GetTextByPath(service, "SERVICE_DETAILS/TITLE");

        var city = GetTextByPath(service,
            "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/CITY");

        var instructionTime = GetTextByPath(service,
            "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_TIME");

        var educationType = GetTextByPath(service,
            "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/EDUCATION_TYPE");

        var startDate = GetTextByPath(service,
            "SERVICE_DETAILS/SERVICE_DATE/START_DATE");

        var category = BuildCourseCategory(city, instructionTime, educationType);

        var parts = new List<string>();

        if (!string.IsNullOrWhiteSpace(category))
            parts.Add($"[{category}]");

        if (!string.IsNullOrWhiteSpace(productId))
            parts.Add($"ID: {productId}");

        if (!string.IsNullOrWhiteSpace(startDate))
            parts.Add($"Start: {ShortDate(startDate)}");

        if (!string.IsNullOrWhiteSpace(title))
            parts.Add(title);

        return parts.Count > 0
            ? string.Join(" | ", parts)
            : $"SERVICE #{index + 1}";
    }
    private static string BuildCourseCategory(string? city, string? instructionTime, string? educationType)
    {
        var cityText = string.IsNullOrWhiteSpace(city) ? "Ort ?" : city.Trim();
        var timeText = string.IsNullOrWhiteSpace(instructionTime) ? "Zeit ?" : instructionTime.Trim();

        var isExternenpruefung =
            (educationType ?? "").Contains("Nachholen", StringComparison.OrdinalIgnoreCase)
            || (educationType ?? "").Contains("Extern", StringComparison.OrdinalIgnoreCase);

        if (isExternenpruefung)
            return $"Externenprüfung - {cityText} - {timeText}";

        return $"{cityText} - {timeText}";
    }

    private static string? GetTextByPath(XmlNode startNode, string path)
    {
        var current = startNode;

        foreach (var part in path.Split('/'))
        {
            var next = current.ChildNodes
                .Cast<XmlNode>()
                .FirstOrDefault(n => n.LocalName.Equals(part, StringComparison.OrdinalIgnoreCase));

            if (next == null)
                return null;

            current = next;
        }

        return current.InnerText?.Trim();
    }

    private static string ShortDate(string value)
    {
        if (string.IsNullOrWhiteSpace(value))
            return "";

        if (value.Length >= 10)
            return value[..10];

        return value;
    }
    private void AddEmptyCourse(object? sender, EventArgs e)
    {
        if (document == null)
        {
            MessageBox.Show("Bitte zuerst XML öffnen.");
            return;
        }

        var existingService = document
            .GetElementsByTagName("*")
            .Cast<XmlNode>()
            .FirstOrDefault(IsServiceNode);

        if (existingService == null)
        {
            MessageBox.Show("Kein SERVICE als Strukturvorlage gefunden.");
            return;
        }

        var insertParent = GetServiceInsertParent();

        if (insertParent == null)
        {
            MessageBox.Show("Weder NEW_CATALOG noch UPDATE_CATALOG gefunden.");
            return;
        }

        try
        {
            var newService = existingService.CloneNode(deep: true);
            ClearValues(newService);

            var newProductId = GenerateNewProductId();
            SetChildText(newService, "PRODUCT_ID", newProductId);

            if (GetUpdateCatalogNode() != null)
                SetAttribute(newService, "mode", "new");

            insertParent.AppendChild(newService);
            serviceStates[newService] = ServiceState.New;
            pendingTemplateFields[newService] =
                ImportantFields.Select(f => f.Path).ToHashSet();
            LoadCourses();
            courseList.SelectedIndex = courseList.Items.Count - 1;
            RefreshStatusLists();
        }
        catch (Exception ex)
        {
            MessageBox.Show(ex.Message);
        }
    }

    private void AddCourseFromTemplate(object? sender, EventArgs e)
    {
        if (document == null)
        {
            MessageBox.Show("Bitte zuerst XML öffnen.");
            return;
        }

        var templates = Directory.GetFiles(servicesTemplateFolder, "*.xml");

        if (templates.Length == 0)
        {
            MessageBox.Show("Noch keine Vorlagen vorhanden.");
            return;
        }

        using var picker = new TemplatePickerForm(templates);

        if (picker.ShowDialog() != DialogResult.OK || picker.SelectedTemplatePath == null)
            return;

        var insertParent = GetServiceInsertParent();

        if (insertParent == null)
        {
            MessageBox.Show("Weder NEW_CATALOG noch UPDATE_CATALOG gefunden.");
            return;
        }

        try
        {
            var templateDoc = new XmlDocument();
            templateDoc.PreserveWhitespace = true;
            templateDoc.Load(picker.SelectedTemplatePath);

            if (templateDoc.DocumentElement == null)
                return;

            var importedService = document.ImportNode(templateDoc.DocumentElement, deep: true);

            var newProductId = GenerateNewProductId();
            SetChildText(importedService, "PRODUCT_ID", newProductId);

            if (GetUpdateCatalogNode() != null)
                SetAttribute(importedService, "mode", "new");

            insertParent.AppendChild(importedService);
            serviceStates[importedService] = ServiceState.New;
            pendingTemplateFields[importedService] =
                ImportantFields.Select(f => f.Path).ToHashSet();
            LoadCourses();
            courseList.SelectedIndex = courseList.Items.Count - 1;
            RefreshStatusLists();

            MessageBox.Show("Service aus Vorlage hinzugefügt. Jetzt variable Daten anpassen.");
        }
        catch (Exception ex)
        {
            MessageBox.Show(ex.Message);
        }
    }

    private void RemoveCourse(object? sender, EventArgs e)
    {
        if (selectedCourse == null)
        {
            MessageBox.Show("Bitte Service auswählen.");
            return;
        }

        var productId = GetChildText(selectedCourse, "PRODUCT_ID");

        if (string.IsNullOrWhiteSpace(productId))
        {
            MessageBox.Show("Dieser SERVICE hat keine PRODUCT_ID und kann nicht sauber gelöscht werden.");
            return;
        }

        var title = BuildServiceTitle(selectedCourse, courseList.SelectedIndex);

        var result = MessageBox.Show(
            $"Service mit PRODUCT_ID '{productId}' löschen?",
            "Service löschen",
            MessageBoxButtons.YesNo,
            MessageBoxIcon.Warning
        );

        if (result != DialogResult.Yes)
            return;

        var isNewService = serviceStates.TryGetValue(selectedCourse, out var state)
            && state == ServiceState.New;

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

            selectedCourse.ParentNode?.RemoveChild(selectedCourse);
            serviceStates.Remove(selectedCourse);

            MessageBox.Show("SERVICE wurde entfernt und als DELETE/SERVICE vorgemerkt.");
        }
        else
        {
            selectedCourse.ParentNode?.RemoveChild(selectedCourse);
            serviceStates.Remove(selectedCourse);

            if (!isNewService)
                deletedServices.Add(new DeletedServiceInfo(productId, title));

            MessageBox.Show("SERVICE wurde entfernt.");
        }

        LoadCourses();
        RefreshStatusLists();
    }

    private void SaveTemplate(object? sender, EventArgs e)
    {
        if (selectedCourse == null)
        {
            MessageBox.Show("Bitte Service auswählen.");
            return;
        }

        string? name = Prompt.ShowDialog("Name der Vorlage:", "Vorlage speichern");

        if (string.IsNullOrWhiteSpace(name))
            return;

        var safeName = string.Join("_", name.Split(Path.GetInvalidFileNameChars()));
        var path = Path.Combine(servicesTemplateFolder, safeName + ".xml");

        var templateDoc = new XmlDocument();
        var imported = templateDoc.ImportNode(selectedCourse, deep: true);
        templateDoc.AppendChild(imported);
        templateDoc.Save(path);

        MessageBox.Show($"Vorlage gespeichert:\n{path}");
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

    private XmlNode? GetNewCatalogNode()
    {
        return FindCatalogNode("NEW_CATALOG");
    }

    private XmlNode? GetUpdateCatalogNode()
    {
        return FindCatalogNode("UPDATE_CATALOG");
    }

    private XmlNode GetOrCreateUpdateChild(string childName)
    {
        var updateCatalog = GetUpdateCatalogNode();

        if (updateCatalog == null)
            throw new Exception("Kein UPDATE_CATALOG gefunden.");

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

        if (updateCatalog != null)
            return GetOrCreateUpdateChild("NEW");

        return null;
    }

    private static string? GetChildText(XmlNode node, string childName)
    {
        var child = node.ChildNodes
            .Cast<XmlNode>()
            .FirstOrDefault(n => n.LocalName.Equals(childName, StringComparison.OrdinalIgnoreCase));

        return child?.InnerText?.Trim();
    }

    private void SetChildText(XmlNode node, string childName, string value)
    {
        var child = node.ChildNodes
            .Cast<XmlNode>()
            .FirstOrDefault(n => n.LocalName.Equals(childName, StringComparison.OrdinalIgnoreCase));

        if (child == null)
        {
            child = document!.CreateElement(childName);
            node.AppendChild(child);
        }

        child.InnerText = value;
    }

    private void SetAttribute(XmlNode node, string name, string value)
    {
        if (document == null)
            return;

        var attr = node.Attributes?[name];

        if (attr == null)
        {
            attr = document.CreateAttribute(name);
            node.Attributes?.Append(attr);
        }

        attr.Value = value;
    }

    private string AskForProductId()
    {
        var productId = Prompt.ShowDialog("Neue PRODUCT_ID:", "PRODUCT_ID setzen");

        if (string.IsNullOrWhiteSpace(productId))
            throw new Exception("PRODUCT_ID darf nicht leer sein.");

        return productId.Trim();
    }

    private static void ClearValues(XmlNode node)
    {
        foreach (XmlNode child in node.ChildNodes)
        {
            if (child.NodeType != XmlNodeType.Element)
                continue;

            if (HasElementChildren(child))
                ClearValues(child);
            else
                child.InnerText = "";
        }

        if (node.Attributes != null)
        {
            foreach (XmlAttribute attr in node.Attributes)
                attr.Value = "";
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
    private XmlDocument BuildExportDocument()
    {
        if (document?.DocumentElement == null)
            throw new Exception("Kein XML geladen.");

        bool hasDeletes = deletedServices.Count > 0;

        return hasDeletes
            ? BuildUpdateCatalogExport()
            : BuildNewCatalogExport();
    }

    private XmlDocument BuildNewCatalogExport()
    {
        var exportDoc = new XmlDocument();

        var declaration = exportDoc.CreateXmlDeclaration("1.0", "utf-8", null);
        exportDoc.AppendChild(declaration);

        var root = exportDoc.CreateElement("NEW_CATALOG");
        root.SetAttribute("FULLCATALOG", "true");
        exportDoc.AppendChild(root);

        var services = GetActiveServices();

        foreach (var service in services)
        {
            var imported = exportDoc.ImportNode(service, deep: true);
            SetAttributeForDocument(exportDoc, imported, "mode", "new");
            root.AppendChild(imported);
        }

        return exportDoc;
    }

    private XmlDocument BuildUpdateCatalogExport()
    {
        var exportDoc = new XmlDocument();

        var declaration = exportDoc.CreateXmlDeclaration("1.0", "utf-8", null);
        exportDoc.AppendChild(declaration);

        var root = exportDoc.CreateElement("UPDATE_CATALOG");
        root.SetAttribute("seq_number", "1");
        exportDoc.AppendChild(root);

        var deleteNode = exportDoc.CreateElement("DELETE");
        root.AppendChild(deleteNode);

        foreach (var deleted in deletedServices)
        {
            var deleteService = exportDoc.CreateElement("SERVICE");

            var productIdNode = exportDoc.CreateElement("PRODUCT_ID");
            productIdNode.InnerText = deleted.ProductId;

            deleteService.AppendChild(productIdNode);
            deleteNode.AppendChild(deleteService);
        }

        var newNode = exportDoc.CreateElement("NEW");
        root.AppendChild(newNode);

        var servicesToExport = GetActiveServices()
            .Where(service =>
                serviceStates.TryGetValue(service, out var state)
                && (state == ServiceState.New || state == ServiceState.Updated))
            .ToList();

        foreach (var service in servicesToExport)
        {
            var imported = exportDoc.ImportNode(service, deep: true);
            SetAttributeForDocument(exportDoc, imported, "mode", "new");
            newNode.AppendChild(imported);
        }

        return exportDoc;
    }

    private List<XmlNode> GetActiveServices()
    {
        if (document == null)
            return new List<XmlNode>();

        return document
            .GetElementsByTagName("*")
            .Cast<XmlNode>()
            .Where(IsServiceNode)
            .Where(n => n.ParentNode != null)
            .ToList();
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
    private void ExportXml(object? sender, EventArgs e)
    {
        if (document == null)
        {
            MessageBox.Show("Bitte zuerst XML öffnen.");
            return;
        }

        using var dialog = new SaveFileDialog();
        dialog.Filter = "XML Dateien (*.xml)|*.xml";
        dialog.FileName = "output.xml";

        if (dialog.ShowDialog() != DialogResult.OK)
            return;

        try
        {
            var exportDoc = BuildExportDocument();
            exportDoc.Save(dialog.FileName);

            MessageBox.Show("XML exportiert.");
        }
        catch (Exception ex)
        {
            MessageBox.Show("Export-Fehler:\n" + ex.Message);
        }
    }

    private void ValidateXml(object? sender, EventArgs e)
    {
        if (document == null)
        {
            MessageBox.Show("Bitte zuerst XML öffnen.");
            return;
        }

        using var dialog = new OpenFileDialog();
        dialog.Filter = "XSD Dateien (*.xsd)|*.xsd|Alle Dateien (*.*)|*.*";

        if (dialog.ShowDialog() != DialogResult.OK)
            return;

        try
        {
            var schemas = new XmlSchemaSet();
            schemas.Add(null, dialog.FileName);

            document.Schemas = schemas;
            document.Validate((_, args) =>
            {
                throw new Exception(args.Message);
            });

            MessageBox.Show("XML ist gültig laut XSD.");
        }
        catch (Exception ex)
        {
            MessageBox.Show("XSD-Fehler:\n" + ex.Message);
        }
    }
}

public class CourseListItem
{
    public XmlNode Node { get; }

    private readonly string title;

    public CourseListItem(XmlNode node, string title)
    {
        Node = node;
        this.title = title;
    }

    public override string ToString()
    {
        return title;
    }
}