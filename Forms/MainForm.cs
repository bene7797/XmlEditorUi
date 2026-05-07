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

    private readonly TabControl statusTabs = new();
    private readonly ListBox newServicesList = new();
    private readonly ListBox updatedServicesList = new();
    private readonly ListBox deletedServicesList = new();
    private readonly DataGridView quickFieldsGrid = new();

    private readonly Button refreshViewButton = new();

    private readonly XmlServiceManager serviceManager;
    private readonly ServiceTemplateRepository templateRepository;

    private XmlDocument? selectedTemplateDoc;
    private string? selectedTemplatePath;
    private XmlNode? selectedTemplateService;
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

        templateRepository = new ServiceTemplateRepository(servicesTemplateFolder);
        serviceManager = new XmlServiceManager(servicesTemplateFolder, ImportantFields.List);
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

        var files = templateRepository.GetTemplateFiles();

        foreach (var file in files)
        {
            var doc = new XmlDocument();
            doc.Load(file);

            if (doc.DocumentElement == null)
                continue;

            var service = doc.DocumentElement;

            var city = service.GetTextByPath(
                "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/CITY") ?? "Ort ?";

            var time = service.GetTextByPath(
                "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_TIME") ?? "Zeit ?";

            var educationType = service.GetTextByPath(
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

        foreach (var field in ImportantFields.List)
        {
            var value = selectedTemplateService.GetTextByPath(field.Path) ?? string.Empty;

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

        selectedTemplateService.SetNodeByPath(path, newValue);

        // Wenn Standortdaten geändert werden, auf alle Vorlagen mit gleichem Ort anwenden
        if (path.Contains("/LOCATION/", StringComparison.OrdinalIgnoreCase))
        {
            var city = selectedTemplateService.GetTextByPath(
                "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/CITY");

            if (!string.IsNullOrWhiteSpace(city) && !string.IsNullOrWhiteSpace(selectedTemplatePath))
                templateRepository.ApplyLocationChangeToAllTemplates(selectedTemplatePath, city, path, newValue);
        }

        // Wenn Vollzeit/Teilzeit geändert wird, nur Kurszeit-Profil aktualisieren
        if (path.Contains("INSTRUCTION_TIME", StringComparison.OrdinalIgnoreCase)
            && !string.IsNullOrWhiteSpace(selectedTemplatePath))
        {
            var instructionTime = newValue.Trim();
            templateRepository.ApplyInstructionTimeToMatchingTemplates(selectedTemplatePath, instructionTime, newValue);
        }

        templatePropertyGrid.SelectedObject =
            new CourseEditableObject(selectedTemplateService, onlyFilledFields: true);
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

        selectedCourse.SetNodeByPath(path, formatted);
        serviceManager.MarkFieldAsChanged(selectedCourse, path);

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

        serviceManager.LoadXml(dialog.FileName);
        document = serviceManager.Document;

        LoadCourses();
        RefreshStatusLists();
    }

    private void LoadCourses()
    {
        courseList.Items.Clear();
        courseGrid.SelectedObject = null;
        selectedCourse = null;

        var services = serviceManager.GetServiceNodes().ToList();

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

        foreach (var field in ImportantFields.List)
        {
            var value = selectedCourse.GetNodeByPath(field.Path)?.InnerText ?? string.Empty;

            var rowIndex = quickFieldsGrid.Rows.Add(field.Label, value);
            var row = quickFieldsGrid.Rows[rowIndex];
            row.Tag = field.Path;

            ApplyQuickFieldColor(row, selectedCourse, field.Path);
        }
    }

    private void ApplyQuickFieldColor(DataGridViewRow row, XmlNode service, string path)
    {
        if (serviceManager.PendingTemplateFields.TryGetValue(service, out var pending)
            && pending.Contains(path))
        {
            row.DefaultCellStyle.BackColor = Color.LightCoral;
            return;
        }

        if (serviceManager.ChangedImportantFields.TryGetValue(service, out var changed)
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

        var newValue = row.Cells[1].Value?.ToString() ?? string.Empty;

        selectedCourse.SetNodeByPath(path, newValue);
        serviceManager.MarkFieldAsChanged(selectedCourse, path);

        ApplyQuickFieldColor(row, selectedCourse, path);
    }

    private void CourseList_SelectedIndexChanged(object? sender, EventArgs e)
    {
        if (courseList.SelectedItem is not CourseListItem item)
            return;

        selectedCourse = item.Node;
        courseGrid.SelectedObject = new CourseEditableObject(selectedCourse, onlyFilledFields: true);
        LoadQuickFields();
    }

    private void CourseGrid_PropertyValueChanged(object? s, PropertyValueChangedEventArgs e)
    {
        if (selectedCourse != null)
            serviceManager.MarkAsUpdated(selectedCourse);

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

        foreach (var entry in serviceManager.ServiceStates.ToList())
        {
            if (entry.Key.ParentNode == null)
                continue;

            var title = BuildServiceTitle(entry.Key, index++);

            if (entry.Value == ServiceState.New)
                newServicesList.Items.Add(title);

            if (entry.Value == ServiceState.Updated)
                updatedServicesList.Items.Add(title);
        }

        foreach (var deleted in serviceManager.DeletedServices)
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

        if (!serviceManager.ServiceStates.TryGetValue(service, out var state))
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
        var productId = service.GetChildText("PRODUCT_ID");

        var title = service.GetTextByPath("SERVICE_DETAILS/TITLE");

        var city = service.GetTextByPath(
            "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/CITY");

        var instructionTime = service.GetTextByPath(
            "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_TIME");

        var educationType = service.GetTextByPath(
            "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/EDUCATION_TYPE");

        var startDate = service.GetTextByPath(
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

    private static string ShortDate(string value)
    {
        if (string.IsNullOrWhiteSpace(value))
            return string.Empty;

        return value.Length >= 10 ? value[..10] : value;
    }

    private void AddEmptyCourse(object? sender, EventArgs e)
    {
        if (serviceManager.Document == null)
        {
            MessageBox.Show("Bitte zuerst XML öffnen.");
            return;
        }

        var existingService = serviceManager.GetServiceNodes().FirstOrDefault();

        if (existingService == null)
        {
            MessageBox.Show("Kein SERVICE als Strukturvorlage gefunden.");
            return;
        }

        try
        {
            serviceManager.AddEmptyService(existingService);
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
        if (serviceManager.Document == null)
        {
            MessageBox.Show("Bitte zuerst XML öffnen.");
            return;
        }

        var templates = templateRepository.GetTemplateFiles();

        if (templates.Length == 0)
        {
            MessageBox.Show("Noch keine Vorlagen vorhanden.");
            return;
        }

        using var picker = new TemplatePickerForm(templates);

        if (picker.ShowDialog() != DialogResult.OK || picker.SelectedTemplatePath == null)
            return;

        try
        {
            serviceManager.AddServiceFromTemplate(picker.SelectedTemplatePath);
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

        var productId = selectedCourse.GetChildText("PRODUCT_ID");

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

        try
        {
            serviceManager.RemoveService(selectedCourse, title);
            MessageBox.Show("SERVICE wurde entfernt.");
            LoadCourses();
            RefreshStatusLists();
        }
        catch (Exception ex)
        {
            MessageBox.Show(ex.Message);
        }
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


    private XmlDocument BuildExportDocument()
    {
        return serviceManager.BuildExportDocument();
    }
    private void ExportXml(object? sender, EventArgs e)
    {
        if (serviceManager.Document == null)
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
        if (serviceManager.Document == null)
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
            serviceManager.ValidateWithSchema(dialog.FileName);
            MessageBox.Show("XML ist gültig laut XSD.");
        }
        catch (Exception ex)
        {
            MessageBox.Show("XSD-Fehler:\n" + ex.Message);
        }
    }
}

