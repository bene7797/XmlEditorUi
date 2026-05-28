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

    // Template Editor - Neue Tab-Struktur
    private readonly TabControl templateSubTabs = new();
    private readonly TabPage mainTemplateTab = new("Main Template");
    private readonly TabPage courseTypeTemplateTab = new("Beschäftigungsart");
    private readonly TabPage locationTemplateTab = new("Ort");
    private readonly TabPage headerTemplateTab = new("Header");

    // Main Template Tab
    private readonly DataGridView mainTemplateGrid = new();
    private readonly DataGridView mainTemplateKeywordsGrid = new();
    private readonly PropertyGrid mainTemplatePropertyGrid = new();
    private readonly Button saveMainTemplateButton = new();

    // Beschäftigungsart Tab
    private readonly ComboBox courseTypeCombo = new();
    private readonly DataGridView courseTypeQuickGrid = new();
    private readonly PropertyGrid courseTypePropertyGrid = new();
    private readonly Button saveCourseTypeButton = new();

    // Ort Tab
    private readonly ComboBox locationCombo = new();
    private readonly DataGridView locationQuickGrid = new();
    private readonly PropertyGrid locationPropertyGrid = new();
    private readonly Button saveLocationButton = new();

    // Header Tab
    private readonly DataGridView headerGrid = new();
    private readonly PropertyGrid headerPropertyGrid = new();
    private readonly Button saveHeaderTemplateButton = new();

    // Alte Elemente (deprecated aber noch vorhanden für Kompatibilität)
    private readonly TreeView templateTree = new();
    private readonly DataGridView templateQuickGrid = new();
    private readonly PropertyGrid templatePropertyGrid = new();

    private readonly Button saveTemplateChangesButton = new();
    private readonly Button reloadTemplatesButton = new();

    // Manager für Template-Typen
    private CourseTypeTemplateManager? courseTypeTemplateManager;
    private LocationTemplateManager? locationTemplateManager;

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
        addCourseButton.Click += AddCourseFromTemplate;

        addFromTemplateButton.Text = "Service Löschen";
        addFromTemplateButton.Left = 590;
        addFromTemplateButton.Top = 525;
        addFromTemplateButton.Width = 130;
        addFromTemplateButton.Click += RemoveCourse;


        /*      saveTemplateButton.Text = "Vorlage speichern";
             saveTemplateButton.Left = 730;
             saveTemplateButton.Top = 525;
             saveTemplateButton.Width = 150;
             saveTemplateButton.Click += SaveTemplate;

             removeCourseButton.Text = "Service entfernen";
             removeCourseButton.Left = 890;
             removeCourseButton.Top = 525;
             removeCourseButton.Width = 150;
             removeCourseButton.Click += RemoveCourse; */

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
        // serviceEditorTab.Controls.Add(saveTemplateButton);
        // serviceEditorTab.Controls.Add(removeCourseButton);
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
        courseTypeTemplateManager = new CourseTypeTemplateManager(templateRepository);
        locationTemplateManager = new LocationTemplateManager(templateRepository);

        BuildTemplateEditorTab();
        LoadTemplateProfilesAndTree();
    }

    private void BuildTemplateEditorTab()
    {
        // Erstelle Sub-TabControl für die vier Template-Typen
        templateSubTabs.Dock = DockStyle.Fill;
        templateSubTabs.Alignment = TabAlignment.Top;

        // Initialisiere die vier Tabs
        templateSubTabs.TabPages.Add(mainTemplateTab);
        templateSubTabs.TabPages.Add(courseTypeTemplateTab);
        templateSubTabs.TabPages.Add(locationTemplateTab);
        templateSubTabs.TabPages.Add(headerTemplateTab);

        // Main Template Tab
        BuildMainTemplateTab();

        // Beschäftigungsart Tab
        BuildCourseTypeTemplateTab();

        // Ort Tab
        BuildLocationTemplateTab();

        // Header Tab
        BuildHeaderTemplateTab();

        templateEditorTab.Controls.Add(templateSubTabs);
    }

    private void BuildMainTemplateTab()
    {
        saveMainTemplateButton.Text = "Main Template speichern";
        saveMainTemplateButton.Left = 10;
        saveMainTemplateButton.Top = 10;
        saveMainTemplateButton.Width = 150;
        saveMainTemplateButton.Click += SaveMainTemplate;

        mainTemplateGrid.Left = 10;
        mainTemplateGrid.Top = 50;
        mainTemplateGrid.Width = 1160;
        mainTemplateGrid.Height = 180;
        mainTemplateGrid.AllowUserToAddRows = false;
        mainTemplateGrid.AllowUserToDeleteRows = false;
        mainTemplateGrid.RowHeadersVisible = false;
        mainTemplateGrid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
        mainTemplateGrid.Columns.Add("Field", "Feld");
        mainTemplateGrid.Columns.Add("Value", "Wert");
        mainTemplateGrid.Columns["Field"]!.ReadOnly = true;
        mainTemplateGrid.CellValueChanged += (s, e) => MainTemplateGrid_CellValueChanged(e);
        mainTemplateGrid.CellClick += MainTemplateGrid_CellClick;

        var keywordsLabel = new Label
        {
            Text = "Schlagwörter (KEYWORD) – eine Zeile pro Schlagwort:",
            Left = 10,
            Top = 238,
            Width = 500,
            Height = 20
        };

        mainTemplateKeywordsGrid.Left = 10;
        mainTemplateKeywordsGrid.Top = 260;
        mainTemplateKeywordsGrid.Width = 1160;
        mainTemplateKeywordsGrid.Height = 120;
        mainTemplateKeywordsGrid.AllowUserToAddRows = true;
        mainTemplateKeywordsGrid.AllowUserToDeleteRows = true;
        mainTemplateKeywordsGrid.RowHeadersVisible = false;
        mainTemplateKeywordsGrid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
        mainTemplateKeywordsGrid.Columns.Add("Keyword", "Schlagwort");
        mainTemplateKeywordsGrid.CellValueChanged += (_, _) => MainTemplateKeywordsGrid_Changed();
        mainTemplateKeywordsGrid.UserDeletedRow += (_, _) => MainTemplateKeywordsGrid_Changed();
        mainTemplateKeywordsGrid.CurrentCellDirtyStateChanged += (_, _) =>
        {
            if (mainTemplateKeywordsGrid.IsCurrentCellDirty)
                mainTemplateKeywordsGrid.CommitEdit(DataGridViewDataErrorContexts.Commit);
        };

        mainTemplatePropertyGrid.Left = 10;
        mainTemplatePropertyGrid.Top = 390;
        mainTemplatePropertyGrid.Width = 1160;
        mainTemplatePropertyGrid.Height = 240;
        mainTemplatePropertyGrid.ToolbarVisible = false;
        mainTemplatePropertyGrid.HelpVisible = false;

        mainTemplateTab.Controls.Add(saveMainTemplateButton);
        mainTemplateTab.Controls.Add(mainTemplateGrid);
        mainTemplateTab.Controls.Add(keywordsLabel);
        mainTemplateTab.Controls.Add(mainTemplateKeywordsGrid);
        mainTemplateTab.Controls.Add(mainTemplatePropertyGrid);
    }

    private void BuildCourseTypeTemplateTab()
    {
        var comboLabel = new Label { Text = "Beschäftigungsart:", Left = 10, Top = 15, Width = 120, Height = 20 };

        courseTypeCombo.Left = 130;
        courseTypeCombo.Top = 10;
        courseTypeCombo.Width = 200;
        courseTypeCombo.DropDownStyle = ComboBoxStyle.DropDownList;
        courseTypeCombo.SelectedIndexChanged += (s, e) => LoadCourseTypeTemplate();

        saveCourseTypeButton.Text = "Template speichern";
        saveCourseTypeButton.Left = 350;
        saveCourseTypeButton.Top = 10;
        saveCourseTypeButton.Width = 150;
        saveCourseTypeButton.Click += SaveCourseTypeTemplate;

        courseTypeQuickGrid.Left = 10;
        courseTypeQuickGrid.Top = 50;
        courseTypeQuickGrid.Width = 1160;
        courseTypeQuickGrid.Height = 240;
        courseTypeQuickGrid.AllowUserToAddRows = false;
        courseTypeQuickGrid.AllowUserToDeleteRows = false;
        courseTypeQuickGrid.RowHeadersVisible = false;
        courseTypeQuickGrid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
        courseTypeQuickGrid.Columns.Add("Field", "Feld");
        courseTypeQuickGrid.Columns.Add("Value", "Wert");
        courseTypeQuickGrid.Columns["Field"]!.ReadOnly = true;
        courseTypeQuickGrid.CellValueChanged += (s, e) => CourseTypeQuickGrid_CellValueChanged(e);
        courseTypeQuickGrid.CellClick += CourseTypeQuickGrid_CellClick;

        courseTypePropertyGrid.Left = 10;
        courseTypePropertyGrid.Top = 300;
        courseTypePropertyGrid.Width = 1160;
        courseTypePropertyGrid.Height = 330;
        courseTypePropertyGrid.ToolbarVisible = false;
        courseTypePropertyGrid.HelpVisible = false;

        courseTypeTemplateTab.Controls.Add(comboLabel);
        courseTypeTemplateTab.Controls.Add(courseTypeCombo);
        courseTypeTemplateTab.Controls.Add(saveCourseTypeButton);
        courseTypeTemplateTab.Controls.Add(courseTypeQuickGrid);
        courseTypeTemplateTab.Controls.Add(courseTypePropertyGrid);
    }

    private void BuildLocationTemplateTab()
    {
        var comboLabel = new Label { Text = "Ort:", Left = 10, Top = 15, Width = 120, Height = 20 };

        locationCombo.Left = 130;
        locationCombo.Top = 10;
        locationCombo.Width = 200;
        locationCombo.DropDownStyle = ComboBoxStyle.DropDownList;
        locationCombo.SelectedIndexChanged += (s, e) => LoadLocationTemplate();

        saveLocationButton.Text = "Template speichern";
        saveLocationButton.Left = 350;
        saveLocationButton.Top = 10;
        saveLocationButton.Width = 150;
        saveLocationButton.Click += SaveLocationTemplate;

        locationQuickGrid.Left = 10;
        locationQuickGrid.Top = 50;
        locationQuickGrid.Width = 1160;
        locationQuickGrid.Height = 240;
        locationQuickGrid.AllowUserToAddRows = false;
        locationQuickGrid.AllowUserToDeleteRows = false;
        locationQuickGrid.RowHeadersVisible = false;
        locationQuickGrid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
        locationQuickGrid.Columns.Add("Field", "Feld");
        locationQuickGrid.Columns.Add("Value", "Wert");
        locationQuickGrid.Columns["Field"]!.ReadOnly = true;
        locationQuickGrid.CellValueChanged += (s, e) => LocationQuickGrid_CellValueChanged(e);
        locationQuickGrid.CellClick += LocationQuickGrid_CellClick;

        locationPropertyGrid.Left = 10;
        locationPropertyGrid.Top = 300;
        locationPropertyGrid.Width = 1160;
        locationPropertyGrid.Height = 330;
        locationPropertyGrid.ToolbarVisible = false;
        locationPropertyGrid.HelpVisible = false;

        locationTemplateTab.Controls.Add(comboLabel);
        locationTemplateTab.Controls.Add(locationCombo);
        locationTemplateTab.Controls.Add(saveLocationButton);
        locationTemplateTab.Controls.Add(locationQuickGrid);
        locationTemplateTab.Controls.Add(locationPropertyGrid);
    }

    private void BuildHeaderTemplateTab()
    {
        saveHeaderTemplateButton.Text = "Header speichern";
        saveHeaderTemplateButton.Left = 10;
        saveHeaderTemplateButton.Top = 10;
        saveHeaderTemplateButton.Width = 150;
        saveHeaderTemplateButton.Click += SaveHeaderTemplate;

        headerGrid.Left = 10;
        headerGrid.Top = 50;
        headerGrid.Width = 1160;
        headerGrid.Height = 240;
        headerGrid.AllowUserToAddRows = false;
        headerGrid.AllowUserToDeleteRows = false;
        headerGrid.RowHeadersVisible = false;
        headerGrid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
        headerGrid.Columns.Add("Field", "Feld");
        headerGrid.Columns.Add("Value", "Wert");
        headerGrid.Columns["Field"]!.ReadOnly = true;
        headerGrid.CellValueChanged += (s, e) => HeaderGrid_CellValueChanged(e);
        headerGrid.CellClick += HeaderGrid_CellClick;

        headerPropertyGrid.Left = 10;
        headerPropertyGrid.Top = 300;
        headerPropertyGrid.Width = 1160;
        headerPropertyGrid.Height = 330;
        headerPropertyGrid.ToolbarVisible = false;
        headerPropertyGrid.HelpVisible = false;

        headerTemplateTab.Controls.Add(saveHeaderTemplateButton);
        headerTemplateTab.Controls.Add(headerGrid);
        headerTemplateTab.Controls.Add(headerPropertyGrid);
    }

    private void LoadTemplateProfilesAndTree()
    {
        if (profileManager == null || courseTypeTemplateManager == null || locationTemplateManager == null)
            return;

        locationProfiles = profileManager.LoadLocations();
        courseTypeProfiles = profileManager.LoadCourseTypes();

        // Lade Main Template
        LoadMainTemplate();

        // Lade Header
        LoadHeaderTemplate();

        // Lade Beschäftigungsart-Vorlagen
        var courseTypes = courseTypeTemplateManager.GetAvailableCourseTypeNames();
        courseTypeCombo.Items.Clear();
        foreach (var ct in courseTypes)
            courseTypeCombo.Items.Add(ct);
        if (courseTypeCombo.Items.Count > 0)
            courseTypeCombo.SelectedIndex = 0;

        // Lade Ort-Vorlagen
        var locations = locationTemplateManager.GetAvailableLocationNames();
        locationCombo.Items.Clear();
        foreach (var loc in locations)
            locationCombo.Items.Add(loc);
        if (locationCombo.Items.Count > 0)
            locationCombo.SelectedIndex = 0;

        // Alte TreeView (deprecated, aber noch vorhanden)
        templateTree.Nodes.Clear();
        var root = new TreeNode("Vorlagen");
        templateTree.Nodes.Add(root);
        root.Expand();
    }

    private void LoadMainTemplate()
    {
        var templates = templateRepository.GetTemplateFiles();
        var mainTemplate = templates.FirstOrDefault(t =>
            Path.GetFileName(t).Equals("Main.xml", StringComparison.OrdinalIgnoreCase));

        if (mainTemplate == null)
        {
            MessageBox.Show("Main.xml nicht gefunden");
            return;
        }

        var doc = new XmlDocument();
        doc.PreserveWhitespace = true;
        doc.Load(mainTemplate);

        if (doc.DocumentElement == null)
            return;

        var service = doc.DocumentElement;
        mainTemplateTab.Tag = (mainTemplate, doc);

        mainTemplateGrid.Rows.Clear();

        foreach (var field in MainTemplateFields.EssentialFields)
        {
            var value = service.GetTextByPath(field.Path) ?? string.Empty;
            var rowIndex = mainTemplateGrid.Rows.Add(field.Label, value);
            var row = mainTemplateGrid.Rows[rowIndex];
            row.Tag = field.Path;
        }

        LoadMainTemplateKeywords(service);
        mainTemplatePropertyGrid.SelectedObject = new CourseEditableObject(service, onlyFilledFields: true);
    }

    private void LoadMainTemplateKeywords(XmlNode service)
    {
        mainTemplateKeywordsGrid.Rows.Clear();

        var serviceDetails = service.GetNodeByPath(MainTemplateFields.KeywordsContainerPath);
        if (serviceDetails == null)
            return;

        foreach (var keyword in serviceDetails.GetRepeatingChildTexts("KEYWORD"))
            mainTemplateKeywordsGrid.Rows.Add(keyword);
    }

    private void ApplyMainTemplateKeywords(XmlNode service)
    {
        var serviceDetails = service.GetNodeByPath(MainTemplateFields.KeywordsContainerPath);
        if (serviceDetails == null)
            return;

        var keywords = mainTemplateKeywordsGrid.Rows
            .Cast<DataGridViewRow>()
            .Where(r => !r.IsNewRow)
            .Select(r => r.Cells[0].Value?.ToString()?.Trim() ?? string.Empty)
            .Where(v => !string.IsNullOrWhiteSpace(v))
            .ToList();

        serviceDetails.SetRepeatingChildElements(
            "KEYWORD",
            keywords,
            insertAfterLocalName: "SERVICE_DATE",
            insertBeforeLocalName: "TARGET_GROUP");
    }

    private void MainTemplateKeywordsGrid_Changed()
    {
        if (mainTemplateTab.Tag is not (_, XmlDocument doc) || doc.DocumentElement == null)
            return;

        ApplyMainTemplateKeywords(doc.DocumentElement);
    }

    private void LoadCourseTypeTemplate()
    {
        if (courseTypeCombo.SelectedItem is not string courseTypeName || courseTypeTemplateManager == null)
            return;

        var template = courseTypeTemplateManager.GetOrCreateCourseTypeTemplate(courseTypeName);

        if (template == null)
        {
            MessageBox.Show($"Template für {courseTypeName} nicht gefunden");
            return;
        }

        var (path, doc) = template.Value;

        if (doc.DocumentElement == null)
            return;

        // Speichere für Speichern
        courseTypeTemplateTab.Tag = (path, doc);

        // Lade Quick Fields
        courseTypeQuickGrid.Rows.Clear();
        var service = doc.DocumentElement;

        foreach (var field in CourseTypeTemplateFields.EssentialFields)
        {
            var value = service.GetTextByPath(field.Path) ?? string.Empty;
            var rowIndex = courseTypeQuickGrid.Rows.Add(field.Label, value);
            var row = courseTypeQuickGrid.Rows[rowIndex];
            row.Tag = field.Path;
        }

        courseTypePropertyGrid.SelectedObject = new CourseEditableObject(service, onlyFilledFields: true);
    }

    private void LoadLocationTemplate()
    {
        if (locationCombo.SelectedItem is not string locationName || locationTemplateManager == null)
            return;

        var template = locationTemplateManager.GetOrCreateLocationTemplate(locationName);

        if (template == null)
        {
            MessageBox.Show($"Template für {locationName} nicht gefunden");
            return;
        }

        var (path, doc) = template.Value;

        if (doc.DocumentElement == null)
            return;

        // Speichere für Speichern
        locationTemplateTab.Tag = (path, doc);

        // Lade Quick Fields
        locationQuickGrid.Rows.Clear();
        var service = doc.DocumentElement;

        foreach (var field in LocationTemplateFields.EssentialFields)
        {
            var value = service.GetTextByPath(field.Path) ?? string.Empty;
            var rowIndex = locationQuickGrid.Rows.Add(field.Label, value);
            var row = locationQuickGrid.Rows[rowIndex];
            row.Tag = field.Path;
        }

        locationPropertyGrid.SelectedObject = new CourseEditableObject(service, onlyFilledFields: true);
    }

    private void LoadHeaderTemplate()
    {
        var templates = templateRepository.GetTemplateFiles();
        var mainTemplate = templates.FirstOrDefault(t =>
            Path.GetFileName(t).Equals("Main.xml", StringComparison.OrdinalIgnoreCase));

        if (mainTemplate == null)
        {
            MessageBox.Show("Main.xml nicht gefunden");
            return;
        }

        var doc = new XmlDocument();
        doc.PreserveWhitespace = true;
        doc.Load(mainTemplate);

        if (doc == null || doc.DocumentElement == null)
            return;

        // Speichere für Speichern
        headerTemplateTab.Tag = (mainTemplate, doc);

        // Lade alle Header-Felder aus HeaderTemplateFields
        headerGrid.Rows.Clear();

        foreach (var field in HeaderTemplateFields.EssentialFields)
        {
            var value = doc.DocumentElement.GetTextByPath(field.Path) ?? string.Empty;
            var rowIndex = headerGrid.Rows.Add(field.Label, value);
            var row = headerGrid.Rows[rowIndex];
            row.Tag = field.Path;
        }

        headerPropertyGrid.SelectedObject = new CourseEditableObject(doc.DocumentElement, onlyFilledFields: true);
    }

    private void MainTemplateGrid_CellValueChanged(DataGridViewCellEventArgs e)
    {
        if (e.RowIndex < 0 || e.ColumnIndex != 1)
            return;

        if (!TryGetMainTemplateDocument(out var doc, out var path) || doc.DocumentElement == null)
            return;

        var row = mainTemplateGrid.Rows[e.RowIndex];
        if (row.Tag is not string fieldPath)
            return;

        var newValue = row.Cells[1].Value?.ToString() ?? "";
        doc.DocumentElement.SetNodeByPath(fieldPath, newValue);
        mainTemplateTab.Tag = (path!, doc);
    }

    private bool TryGetMainTemplateDocument(out XmlDocument doc, out string? path)
    {
        if (mainTemplateTab.Tag is (string p, XmlDocument d))
        {
            path = p;
            doc = d;
            return true;
        }

        var templates = templateRepository.GetTemplateFiles();
        path = templates.FirstOrDefault(t =>
            Path.GetFileName(t).Equals("Main.xml", StringComparison.OrdinalIgnoreCase));

        if (path == null)
        {
            doc = new XmlDocument();
            return false;
        }

        doc = new XmlDocument();
        doc.PreserveWhitespace = true;
        doc.Load(path);
        mainTemplateTab.Tag = (path, doc);
        return true;
    }

    private void CourseTypeQuickGrid_CellValueChanged(DataGridViewCellEventArgs e)
    {
        if (e.RowIndex < 0 || e.ColumnIndex != 1)
            return;

        if (courseTypeTemplateTab.Tag is not (string path, XmlDocument doc))
            return;

        var row = courseTypeQuickGrid.Rows[e.RowIndex];
        if (row.Tag is not string fieldPath)
            return;

        var newValue = row.Cells[1].Value?.ToString() ?? "";
        doc.DocumentElement?.SetNodeByPath(fieldPath, newValue);
    }

    private void LocationQuickGrid_CellValueChanged(DataGridViewCellEventArgs e)
    {
        if (e.RowIndex < 0 || e.ColumnIndex != 1)
            return;

        if (locationTemplateTab.Tag is not (string path, XmlDocument doc))
            return;

        var row = locationQuickGrid.Rows[e.RowIndex];
        if (row.Tag is not string fieldPath)
            return;

        var newValue = row.Cells[1].Value?.ToString() ?? "";
        doc.DocumentElement?.SetNodeByPath(fieldPath, newValue);
    }

    private void HeaderGrid_CellValueChanged(DataGridViewCellEventArgs e)
    {
        if (e.RowIndex < 0 || e.ColumnIndex != 1)
            return;

        if (headerTemplateTab.Tag is not (string path, XmlDocument doc))
            return;

        var row = headerGrid.Rows[e.RowIndex];
        if (row.Tag is not string fieldPath)
            return;

        var newValue = row.Cells[1].Value?.ToString() ?? "";

        // Setze den Wert im XML-Dokument
        if (doc.DocumentElement != null)
        {
            doc.DocumentElement.SetNodeByPath(fieldPath, newValue);
        }
    }

    private void SaveMainTemplate(object? sender, EventArgs e)
    {
        if (mainTemplateTab.Tag is not (string path, XmlDocument doc))
        {
            MessageBox.Show("Kein Template geladen");
            return;
        }

        try
        {
            if (doc.DocumentElement != null)
                ApplyMainTemplateKeywords(doc.DocumentElement);

            doc.Save(path);
            MessageBox.Show("Main Template gespeichert");
            LoadMainTemplate();
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Fehler beim Speichern: {ex.Message}");
        }
    }

    private void SaveCourseTypeTemplate(object? sender, EventArgs e)
    {
        if (courseTypeTemplateTab.Tag is not (string path, XmlDocument doc))
        {
            MessageBox.Show("Kein Template geladen");
            return;
        }

        try
        {
            doc.Save(path);
            MessageBox.Show("Template gespeichert");
            LoadCourseTypeTemplate();
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Fehler beim Speichern: {ex.Message}");
        }
    }

    private void SaveLocationTemplate(object? sender, EventArgs e)
    {
        if (locationTemplateTab.Tag is not (string path, XmlDocument doc))
        {
            MessageBox.Show("Kein Template geladen");
            return;
        }

        try
        {
            doc.Save(path);
            MessageBox.Show("Template gespeichert");
            LoadLocationTemplate();
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Fehler beim Speichern: {ex.Message}");
        }
    }

    private void SaveHeaderTemplate(object? sender, EventArgs e)
    {
        if (headerTemplateTab.Tag is not (string path, XmlDocument doc))
        {
            MessageBox.Show("Kein Template geladen");
            return;
        }

        try
        {
            doc.Save(path);
            MessageBox.Show("Header gespeichert");
            LoadHeaderTemplate();
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Fehler beim Speichern: {ex.Message}");
        }
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
        RefreshSelectedCourseTitle();
        RefreshStatusLists();
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

    // Template Grid CellClick Handler - für Datum-Felder
    private void MainTemplateGrid_CellClick(object? sender, DataGridViewCellEventArgs e)
    {
        if (mainTemplateTab.Tag is not (string path, XmlDocument doc))
            return;

        if (e.RowIndex < 0 || e.ColumnIndex != 1)
            return;

        var row = mainTemplateGrid.Rows[e.RowIndex];
        if (row.Tag is not string fieldPath)
            return;

        if (!IsDateField(fieldPath))
            return;

        ShowTemplateDatePicker(row, fieldPath, doc);
    }

    private void CourseTypeQuickGrid_CellClick(object? sender, DataGridViewCellEventArgs e)
    {
        if (courseTypeTemplateTab.Tag is not (string path, XmlDocument doc))
            return;

        if (e.RowIndex < 0 || e.ColumnIndex != 1)
            return;

        var row = courseTypeQuickGrid.Rows[e.RowIndex];
        if (row.Tag is not string fieldPath)
            return;

        if (!IsDateField(fieldPath))
            return;

        ShowTemplateDatePicker(row, fieldPath, doc);
    }

    private void LocationQuickGrid_CellClick(object? sender, DataGridViewCellEventArgs e)
    {
        if (locationTemplateTab.Tag is not (string path, XmlDocument doc))
            return;

        if (e.RowIndex < 0 || e.ColumnIndex != 1)
            return;

        var row = locationQuickGrid.Rows[e.RowIndex];
        if (row.Tag is not string fieldPath)
            return;

        if (!IsDateField(fieldPath))
            return;

        ShowTemplateDatePicker(row, fieldPath, doc);
    }

    private void HeaderGrid_CellClick(object? sender, DataGridViewCellEventArgs e)
    {
        // Header-Grid hat keine Datum-Felder
        return;
    }

    private void ShowTemplateDatePicker(DataGridViewRow row, string path, XmlDocument doc)
    {
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

        doc.DocumentElement?.SetNodeByPath(path, formatted);
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
        RefreshSelectedCourseTitle();
        RefreshStatusLists();
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

        // Lade die Profile für Ort und Beschäftigungsart
        var locations = profileManager!.LoadLocations();
        var courseTypes = profileManager.LoadCourseTypes();

        if (locations.Count == 0 || courseTypes.Count == 0)
        {
            MessageBox.Show("Orte oder Beschäftigungsarten nicht konfiguriert.");
            return;
        }

        // Öffne den Konfigurations-Dialog
        using var configForm = new ServiceConfigurationForm(locations, courseTypes);

        if (configForm.ShowDialog() != DialogResult.OK ||
            configForm.SelectedLocation == null ||
            configForm.SelectedCourseType == null)
            return;

        try
        {
            // Finde das Haupttemplate
            var mainTemplatePath = FindMainTemplate();

            if (mainTemplatePath == null)
            {
                MessageBox.Show("Haupttemplate nicht gefunden. Stelle sicher, dass 'Main.xml' existiert.");
                return;
            }

            // Lade und konfiguriere das Template
            var configManager = new TemplateConfigurationManager(profileManager);
            configManager.LoadMainTemplate(mainTemplatePath);
            configManager.ApplyLocationConfiguration(configForm.SelectedLocation);
            configManager.ApplyCourseTypeConfiguration(configForm.SelectedCourseType);

            // Füge den konfigurierten Service hinzu
            var configuredTemplate = configManager.GetConfiguredTemplate();
            serviceManager.AddServiceFromConfiguredTemplate(configuredTemplate);

            LoadCourses();
            courseList.SelectedIndex = courseList.Items.Count - 1;
            RefreshStatusLists();

            MessageBox.Show($"Service erstellt für {configForm.SelectedLocation.Name} ({configForm.SelectedCourseType.Name}).\nBitte variable Daten anpassen.");
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Fehler beim Erstellen des Services: {ex.Message}");
        }
    }

    private string? FindMainTemplate()
    {
        var templates = templateRepository.GetTemplateFiles();

        // Versuche, Main.xml zu finden
        var mainTemplate = templates.FirstOrDefault(t =>
            Path.GetFileName(t).Equals("Main.xml", StringComparison.OrdinalIgnoreCase));

        if (mainTemplate != null)
            return mainTemplate;

        // Falls nicht vorhanden, nutze das erste Template als Fallback
        return templates.FirstOrDefault();
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
            if (serviceManager.GetHeaderTemplate() == null)
            {
                var templates = templateRepository.GetTemplateFiles();
                var mainTemplate = templates.FirstOrDefault(t =>
                    Path.GetFileName(t).Equals("Main.xml", StringComparison.OrdinalIgnoreCase));

                if (mainTemplate != null)
                {
                    var headerDoc = templateRepository.LoadTemplateDocument(mainTemplate);
                    var headerElement = headerDoc.DocumentElement;
                    if (headerElement != null)
                    {
                        var headerNode = headerElement.SelectSingleNode("HEADER");
                        serviceManager.SetHeaderTemplate(headerNode);
                    }
                }
            }

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
        using var dialog = new OpenFileDialog();
        dialog.Filter = "XML Dateien (*.xml)|*.xml|Alle Dateien (*.*)|*.*";

        if (dialog.ShowDialog() != DialogResult.OK)
            return;

        try
        {
            string xmlPath = dialog.FileName;

            string xsdPath = Path.Combine(
                AppDomain.CurrentDomain.BaseDirectory,
                "schema.xsd"
            );

            serviceManager.ValidateWithSchema(xmlPath, xsdPath);

            MessageBox.Show("XML ist gültig laut eingebautem XSD.");
        }
        catch (Exception ex)
        {
            MessageBox.Show("Validierungsfehler:\n" + ex.Message);
        }
    }
}

