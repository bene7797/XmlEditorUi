using System.Drawing;
using System.Windows.Forms;
using System.Xml;

namespace XmlEditorUi;

public class MainForm : Form
{
    private readonly Button openButton = new();
    private readonly Button exportButton = new();
    private readonly Button validateButton = new();
    private readonly Button addCourseButton = new();
    private readonly Button removeCourseButton = new();
    private readonly Button refreshViewButton = new();

    private readonly ListBox courseList = new();
    private readonly PropertyGrid courseGrid = new();
    private readonly DataGridView quickFieldsGrid = new();
    private readonly Label quickFieldsLabel = new();

    private readonly TabControl mainTabs = new();
    private readonly TabPage serviceEditorTab = new("Service bearbeiten");
    private readonly TabPage templateEditorTab = new("Vorlagen bearbeiten");

    private readonly TabControl templateSubTabs = new();
    private readonly TabPage mainTemplateTab = new("Main Template");
    private readonly TabPage courseTypeTemplateTab = new("Beschäftigungsart");
    private readonly TabPage locationTemplateTab = new("Ort");
    private readonly TabPage headerTemplateTab = new("Header");

    private readonly ComboBox mainTemplateVariantCombo = new();
    private readonly DataGridView mainTemplateGrid = UiFactory.CreateFieldGrid(50, 220);
    private readonly DataGridView mainTemplateKeywordsGrid = new();
    private readonly PropertyGrid mainTemplatePropertyGrid = UiFactory.CreatePropertyGrid(410, 220);
    private readonly Button saveMainTemplateButton = new();

    private readonly ComboBox courseTypeCombo = new();
    private readonly DataGridView courseTypeQuickGrid = UiFactory.CreateFieldGrid(50);
    private readonly PropertyGrid courseTypePropertyGrid = UiFactory.CreatePropertyGrid(300);
    private readonly Button saveCourseTypeButton = new();

    private readonly ComboBox locationCombo = new();
    private readonly DataGridView locationQuickGrid = UiFactory.CreateFieldGrid(50);
    private readonly PropertyGrid locationPropertyGrid = UiFactory.CreatePropertyGrid(300);
    private readonly Button saveLocationButton = new();

    private readonly DataGridView headerGrid = UiFactory.CreateFieldGrid(50);
    private readonly PropertyGrid headerPropertyGrid = UiFactory.CreatePropertyGrid(300);
    private readonly Button saveHeaderTemplateButton = new();

    private readonly TabControl statusTabs = new();
    private readonly ListBox newServicesList = new();
    private readonly ListBox updatedServicesList = new();
    private readonly ListBox deletedServicesList = new();

    private readonly string servicesTemplateFolder;
    private readonly string profilesFolder;

    private readonly XmlServiceManager serviceManager;
    private readonly ServiceTemplateRepository templateRepository;
    private readonly TemplateProfileManager profileManager;

    private readonly TemplateFieldGridBinder mainTemplateBinder;
    private readonly TemplateFieldGridBinder courseTypeBinder;
    private readonly TemplateFieldGridBinder locationBinder;
    private readonly TemplateFieldGridBinder headerBinder;
    private FieldGridEditHelper? quickFieldsEditHelper;

    private XmlNode? selectedCourse;

    public MainForm()
    {
        Text = "XML Service Editor";
        Width = 1200;
        Height = 820;
        mainTabs.Dock = DockStyle.Fill;
        mainTabs.TabPages.Add(serviceEditorTab);
        mainTabs.TabPages.Add(templateEditorTab);
        Controls.Add(mainTabs);

        servicesTemplateFolder = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "templates", "services");
        profilesFolder = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "templates", "profiles");
        Directory.CreateDirectory(profilesFolder);

        templateRepository = new ServiceTemplateRepository(servicesTemplateFolder);
        serviceManager = new XmlServiceManager(servicesTemplateFolder, ImportantFields.List);
        profileManager = new TemplateProfileManager(profilesFolder);

        mainTemplateBinder = new TemplateFieldGridBinder(this, mainTemplateTab, mainTemplateGrid, mainTemplatePropertyGrid);
        courseTypeBinder = new TemplateFieldGridBinder(this, courseTypeTemplateTab, courseTypeQuickGrid, courseTypePropertyGrid);
        locationBinder = new TemplateFieldGridBinder(this, locationTemplateTab, locationQuickGrid, locationPropertyGrid);
        headerBinder = new TemplateFieldGridBinder(this, headerTemplateTab, headerGrid, headerPropertyGrid);

        BuildServiceEditorTab();
        BuildTemplateEditorTab();
        LoadAllTemplates();
    }

    private void BuildServiceEditorTab()
    {
        openButton.Text = "XML öffnen";
        openButton.SetBounds(10, 10, 120, 30);
        openButton.Click += OpenXml;

        exportButton.Text = "Exportieren";
        exportButton.SetBounds(140, 10, 120, 30);
        exportButton.Click += ExportXml;

        validateButton.Text = "Gegen XSD prüfen";
        validateButton.SetBounds(270, 10, 140, 30);
        validateButton.Click += ValidateXml;

        courseList.SetBounds(10, 60, 420, 530);
        courseList.SelectedIndexChanged += CourseList_SelectedIndexChanged;

        quickFieldsLabel.Text = "Schnellbearbeitung";
        quickFieldsLabel.SetBounds(450, 42, 300, 18);
        quickFieldsLabel.Font = new Font(Font.FontFamily, 9f, FontStyle.Bold);

        quickFieldsGrid.SetBounds(450, 60, 700, 218);
        UiFactory.AddFieldColumns(quickFieldsGrid);
        UiFactory.ConfigureFieldGrid(quickFieldsGrid, fieldWeight: 36, valueWeight: 64);
        quickFieldsGrid.CellValueChanged += QuickFieldsGrid_CellValueChanged;
        quickFieldsGrid.CellClick += QuickFieldsGrid_CellClick;
        quickFieldsGrid.CurrentCellDirtyStateChanged += (_, _) =>
        {
            if (quickFieldsGrid.IsCurrentCellDirty)
                quickFieldsGrid.CommitEdit(DataGridViewDataErrorContexts.Commit);
        };

        quickFieldsEditHelper = new FieldGridEditHelper(quickFieldsGrid, this, () =>
        {
            if (selectedCourse == null)
                return null;

            return new FieldEditContext
            {
                Node = selectedCourse,
                AfterEdit = (path, _) =>
                {
                    var row = quickFieldsGrid.Rows
                        .Cast<DataGridViewRow>()
                        .FirstOrDefault(r => r.Tag as string == path);

                    if (row != null)
                    {
                        ApplyQuickFieldColor(row, selectedCourse, path);
                        serviceManager.MarkFieldAsChanged(selectedCourse, path);
                    }

                    RefreshCourseView();
                }
            };
        });

        courseGrid.SetBounds(450, 288, 700, 222);
        courseGrid.PropertyValueChanged += CourseGrid_PropertyValueChanged;
        courseGrid.ToolbarVisible = false;
        courseGrid.PropertySort = PropertySort.NoSort;
        courseGrid.HelpVisible = false;

        addCourseButton.Text = "Neuer Service";
        addCourseButton.SetBounds(450, 525, 130, 30);
        addCourseButton.Click += AddCourseFromTemplate;

        removeCourseButton.Text = "Service Löschen";
        removeCourseButton.SetBounds(590, 525, 130, 30);
        removeCourseButton.Click += RemoveCourse;

        refreshViewButton.Text = "Ansicht aktualisieren";
        refreshViewButton.SetBounds(1050, 525, 130, 30);
        refreshViewButton.Click += (_, _) => RefreshCourseView();

        statusTabs.SetBounds(10, 610, 1140, 150);
        AddStatusTab("Neu hinzugefügt", newServicesList);
        AddStatusTab("Geändert / Update", updatedServicesList);
        AddStatusTab("Gelöscht", deletedServicesList);

        serviceEditorTab.Controls.AddRange([
            openButton, exportButton, validateButton,
            courseList, quickFieldsLabel, quickFieldsGrid, courseGrid,
            addCourseButton, removeCourseButton, refreshViewButton, statusTabs
        ]);
    }

    private void BuildTemplateEditorTab()
    {
        templateSubTabs.Dock = DockStyle.Fill;
        templateSubTabs.TabPages.AddRange([mainTemplateTab, courseTypeTemplateTab, locationTemplateTab, headerTemplateTab]);

        var variantLabel = new Label
        {
            Text = "Main-Template-Typ:",
            Left = 10,
            Top = 15,
            Width = 120,
            Height = 20
        };

        mainTemplateVariantCombo.SetBounds(130, 10, 260, 25);
        mainTemplateVariantCombo.DropDownStyle = ComboBoxStyle.DropDownList;
        mainTemplateVariantCombo.SelectedIndexChanged += (_, _) => LoadMainTemplate();

        saveMainTemplateButton.Text = "Main Template speichern";
        saveMainTemplateButton.SetBounds(400, 10, 170, 30);
        saveMainTemplateButton.Click += (_, _) => SaveMainTemplate();

        mainTemplateGrid.Top = 48;

        var keywordsLabel = new Label
        {
            Text = "Schlagwörter (KEYWORD) – eine Zeile pro Schlagwort:",
            Left = 10,
            Top = 278,
            Width = 500,
            Height = 20
        };

        mainTemplateKeywordsGrid.SetBounds(10, 300, 1160, 100);
        mainTemplateKeywordsGrid.AllowUserToAddRows = true;
        mainTemplateKeywordsGrid.AllowUserToDeleteRows = true;
        mainTemplateKeywordsGrid.RowHeadersVisible = false;
        mainTemplateKeywordsGrid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
        mainTemplateKeywordsGrid.Columns.Add("Keyword", "Schlagwort");
        mainTemplateKeywordsGrid.CellValueChanged += (_, _) => ApplyMainTemplateKeywords();
        mainTemplateKeywordsGrid.UserDeletedRow += (_, _) => ApplyMainTemplateKeywords();
        mainTemplateKeywordsGrid.CurrentCellDirtyStateChanged += (_, _) =>
        {
            if (mainTemplateKeywordsGrid.IsCurrentCellDirty)
                mainTemplateKeywordsGrid.CommitEdit(DataGridViewDataErrorContexts.Commit);
        };

        foreach (var variant in MainTemplateVariants.All)
            mainTemplateVariantCombo.Items.Add(variant);

        mainTemplateTab.Controls.AddRange([
            variantLabel, mainTemplateVariantCombo, saveMainTemplateButton,
            mainTemplateGrid, keywordsLabel, mainTemplateKeywordsGrid, mainTemplatePropertyGrid
        ]);

        BuildComboTemplateTab(
            courseTypeTemplateTab, "Beschäftigungsart:", courseTypeCombo, saveCourseTypeButton,
            "Template speichern", courseTypeQuickGrid, courseTypePropertyGrid,
            LoadCourseTypeTemplate,
            () => courseTypeBinder.SaveDocument("Template gespeichert", ReloadCourseTypeTemplate));

        BuildComboTemplateTab(
            locationTemplateTab, "Ort:", locationCombo, saveLocationButton,
            "Template speichern", locationQuickGrid, locationPropertyGrid,
            LoadLocationTemplate,
            () => locationBinder.SaveDocument("Template gespeichert", ReloadLocationTemplate));

        saveHeaderTemplateButton.Text = "Header speichern";
        saveHeaderTemplateButton.SetBounds(10, 10, 150, 30);
        saveHeaderTemplateButton.Click += (_, _) =>
            headerBinder.SaveDocument("Header gespeichert", LoadHeaderTemplate);

        headerTemplateTab.Controls.AddRange([saveHeaderTemplateButton, headerGrid, headerPropertyGrid]);

        templateEditorTab.Controls.Add(templateSubTabs);
    }

    private void BuildComboTemplateTab(
        TabPage tab, string labelText, ComboBox combo, Button saveButton, string saveText,
        DataGridView grid, PropertyGrid propertyGrid,
        EventHandler loadHandler, Action saveHandler)
    {
        var label = new Label { Text = labelText, Left = 10, Top = 15, Width = 120, Height = 20 };
        combo.SetBounds(130, 10, 200, 25);
        combo.DropDownStyle = ComboBoxStyle.DropDownList;
        combo.SelectedIndexChanged += loadHandler;

        saveButton.Text = saveText;
        saveButton.SetBounds(350, 10, 150, 30);
        saveButton.Click += (_, _) => saveHandler();

        tab.Controls.AddRange([label, combo, saveButton, grid, propertyGrid]);
    }

    private void LoadAllTemplates()
    {
        if (mainTemplateVariantCombo.SelectedIndex < 0 && mainTemplateVariantCombo.Items.Count > 0)
            mainTemplateVariantCombo.SelectedIndex = 0;
        else
            LoadMainTemplate();

        LoadHeaderTemplate();

        FillCombo(courseTypeCombo, templateRepository.GetDistinctCourseTypeNames());
        FillCombo(locationCombo, templateRepository.GetDistinctLocationNames());
    }

    private static void FillCombo(ComboBox combo, IReadOnlyList<string> items)
    {
        combo.Items.Clear();
        foreach (var item in items)
            combo.Items.Add(item);

        if (combo.Items.Count > 0)
            combo.SelectedIndex = 0;
    }

    private void LoadMainTemplate()
    {
        var variant = mainTemplateVariantCombo.SelectedItem as string ?? MainTemplateVariants.Standard;
        var session = templateRepository.LoadMainTemplateSession(variant);
        if (session == null)
        {
            MessageBox.Show($"{MainTemplateVariants.GetFileName(variant)} nicht gefunden");
            return;
        }

        var fields = MainTemplateVariants.IsExternenpruefung(variant)
            ? ExternenpruefungMainTemplateFields.EssentialFields
            : MainTemplateFields.EssentialFields;

        mainTemplateBinder.BindSession(session);
        mainTemplateBinder.LoadFields(session.Service, fields);
        LoadMainTemplateKeywords(session.Service);
    }

    private void LoadMainTemplateKeywords(XmlNode service)
    {
        mainTemplateKeywordsGrid.Rows.Clear();

        var container = service.GetNodeByPath(MainTemplateFields.KeywordsContainerPath);
        if (container == null)
            return;

        foreach (var keyword in container.GetRepeatingChildTexts("KEYWORD"))
            mainTemplateKeywordsGrid.Rows.Add(keyword);
    }

    private void ApplyMainTemplateKeywords()
    {
        if (mainTemplateBinder.GetSession() is not { } session)
            return;

        var container = session.Service.GetNodeByPath(MainTemplateFields.KeywordsContainerPath);
        if (container == null)
            return;

        var keywords = mainTemplateKeywordsGrid.Rows
            .Cast<DataGridViewRow>()
            .Where(r => !r.IsNewRow)
            .Select(r => r.Cells[0].Value?.ToString()?.Trim() ?? string.Empty)
            .Where(v => !string.IsNullOrWhiteSpace(v))
            .ToList();

        container.SetRepeatingChildElements(
            "KEYWORD", keywords, insertAfterLocalName: "SERVICE_DATE", insertBeforeLocalName: "TARGET_GROUP");
    }

    private void SaveMainTemplate()
    {
        if (mainTemplateBinder.GetSession() is not { } session)
        {
            MessageBox.Show("Kein Template geladen");
            return;
        }

        try
        {
            ApplyMainTemplateKeywords();
            session.Save();
            MessageBox.Show("Main Template gespeichert");
            LoadMainTemplate();
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Fehler beim Speichern: {ex.Message}");
        }
    }

    private void ReloadCourseTypeTemplate() => LoadCourseTypeTemplate(courseTypeCombo, EventArgs.Empty);
    private void ReloadLocationTemplate() => LoadLocationTemplate(locationCombo, EventArgs.Empty);

    private void LoadCourseTypeTemplate(object? sender, EventArgs e)
    {
        if (courseTypeCombo.SelectedItem is not string name)
            return;

        var session = templateRepository.FindTemplateByFileNameContains(name);
        if (session == null)
        {
            MessageBox.Show($"Template für {name} nicht gefunden");
            return;
        }

        courseTypeBinder.BindSession(session);
        courseTypeBinder.LoadFields(session.Service, CourseTypeTemplateFields.EssentialFields);
    }

    private void LoadLocationTemplate(object? sender, EventArgs e)
    {
        if (locationCombo.SelectedItem is not string name)
            return;

        var session = templateRepository.FindTemplateByCity(name);
        if (session == null)
        {
            MessageBox.Show($"Template für {name} nicht gefunden");
            return;
        }

        locationBinder.BindSession(session);
        locationBinder.LoadFields(session.Service, LocationTemplateFields.EssentialFields);
    }

    private void LoadHeaderTemplate()
    {
        var session = templateRepository.LoadMainTemplateSession();
        if (session == null)
        {
            MessageBox.Show("Main.xml nicht gefunden");
            return;
        }

        headerBinder.BindSession(session);
        headerBinder.LoadFields(session.Document.DocumentElement!, HeaderTemplateFields.EssentialFields);
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
        using var dialog = new OpenFileDialog { Filter = "XML Dateien (*.xml)|*.xml|Alle Dateien (*.*)|*.*" };
        if (dialog.ShowDialog() != DialogResult.OK)
            return;

        serviceManager.LoadXml(dialog.FileName);
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
            serviceManager.ServiceStates.TryGetValue(services[i], out var state);
            courseList.Items.Add(new CourseListItem(
                services[i], ServiceTitleBuilder.Build(services[i], i, state)));
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
            var rowIndex = quickFieldsGrid.Rows.Add(field.Label, FieldValueFormatter.ForGridDisplay(value, field.Path));
            var row = quickFieldsGrid.Rows[rowIndex];
            row.Tag = field.Path;
            row.Cells["Value"].ReadOnly = DateFieldHelper.IsDatePath(field.Path);
            ApplyQuickFieldColor(row, selectedCourse, field.Path);
        }
    }

    private void ApplyQuickFieldColor(DataGridViewRow row, XmlNode service, string path)
    {
        if (serviceManager.PendingTemplateFields.TryGetValue(service, out var pending) && pending.Contains(path))
            row.DefaultCellStyle.BackColor = Color.LightCoral;
        else if (serviceManager.ChangedImportantFields.TryGetValue(service, out var changed) && changed.Contains(path))
            row.DefaultCellStyle.BackColor = Color.LightGreen;
        else
            row.DefaultCellStyle.BackColor = Color.LightBlue;
    }

    private void QuickFieldsGrid_CellValueChanged(object? sender, DataGridViewCellEventArgs e)
    {
        if (selectedCourse == null || e.RowIndex < 0 || e.ColumnIndex != 1)
            return;

        var row = quickFieldsGrid.Rows[e.RowIndex];
        if (row.Tag is not string path)
            return;

        var newValue = row.Cells[1].Value?.ToString() ?? string.Empty;
        selectedCourse.SetNodeByPath(path, newValue);
        serviceManager.MarkFieldAsChanged(selectedCourse, path);
        ApplyQuickFieldColor(row, selectedCourse, path);
        RefreshCourseView();
    }

    private void QuickFieldsGrid_CellClick(object? sender, DataGridViewCellEventArgs e)
    {
        if (selectedCourse == null || e.RowIndex < 0 || e.ColumnIndex != 1)
            return;

        var row = quickFieldsGrid.Rows[e.RowIndex];
        if (row.Tag is not string path || !DateFieldHelper.IsDatePath(path))
            return;

        if (!DateFieldHelper.TryParse(row.Cells[1].Value?.ToString(), out var initialDate))
            initialDate = DateTime.Now;

        using var popup = new DateTimePickerPopup(initialDate, includeTime: DateFieldHelper.IsCourseDatePath(path));
        if (popup.ShowDialog(this) != DialogResult.OK)
            return;

        var formatted = DateFieldHelper.Format(popup.SelectedValue, DateFieldHelper.IsCourseDatePath(path));
        row.Cells[1].Value = formatted;
        selectedCourse.SetNodeByPath(path, formatted);
        serviceManager.MarkFieldAsChanged(selectedCourse, path);
        ApplyQuickFieldColor(row, selectedCourse, path);
        RefreshCourseView();
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

        RefreshCourseView();
    }

    private void RefreshCourseView()
    {
        if (selectedCourse != null)
            courseGrid.SelectedObject = new CourseEditableObject(selectedCourse, onlyFilledFields: true);

        RefreshSelectedCourseTitle();
        RefreshStatusLists();
    }

    private void RefreshSelectedCourseTitle()
    {
        if (courseList.SelectedIndex < 0 || selectedCourse == null)
            return;

        int index = courseList.SelectedIndex;
        serviceManager.ServiceStates.TryGetValue(selectedCourse, out var state);
        courseList.Items[index] = new CourseListItem(selectedCourse, ServiceTitleBuilder.Build(selectedCourse, index, state));
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

            var title = ServiceTitleBuilder.Build(entry.Key, index++);

            if (entry.Value == ServiceState.New)
                newServicesList.Items.Add(title);

            if (entry.Value == ServiceState.Updated)
                updatedServicesList.Items.Add(title);
        }

        foreach (var deleted in serviceManager.DeletedServices)
            deletedServicesList.Items.Add($"{deleted.ProductId} | {deleted.Title}");

        statusTabs.TabPages[0].Text = $"Neu hinzugefügt ({newServicesList.Items.Count})";
        statusTabs.TabPages[1].Text = $"Geändert / Update ({updatedServicesList.Items.Count})";
        statusTabs.TabPages[2].Text = $"Gelöscht ({deletedServicesList.Items.Count})";
    }

    private void AddCourseFromTemplate(object? sender, EventArgs e)
    {
        if (serviceManager.Document == null)
        {
            MessageBox.Show("Bitte zuerst XML öffnen.");
            return;
        }

        var locations = profileManager.LoadLocations();
        var courseTypes = profileManager.LoadCourseTypes()
            .Where(c => !c.Name.Contains("Extern", StringComparison.OrdinalIgnoreCase))
            .ToList();

        if (locations.Count == 0 || courseTypes.Count == 0)
        {
            MessageBox.Show("Orte oder Beschäftigungsarten (Vollzeit/Teilzeit) nicht konfiguriert.");
            return;
        }

        using var configForm = new ServiceConfigurationForm(locations, courseTypes);
        if (configForm.ShowDialog() != DialogResult.OK || configForm.SelectedLocation == null)
            return;

        if (!configForm.IsExternenpruefung && configForm.SelectedCourseType == null)
            return;

        try
        {
            var isExternenpruefung = configForm.IsExternenpruefung;

            var mainTemplatePath = templateRepository.FindMainTemplatePath(isExternenpruefung);
            if (mainTemplatePath == null)
            {
                var expected = isExternenpruefung
                    ? MainTemplateVariants.ExternFileName
                    : MainTemplateVariants.StandardFileName;
                MessageBox.Show($"Haupttemplate nicht gefunden. Erwartet: {expected}");
                return;
            }

            var configManager = new TemplateConfigurationManager();
            configManager.LoadMainTemplate(mainTemplatePath);
            configManager.ApplyLocationConfiguration(configForm.SelectedLocation);

            if (configForm.SelectedCourseType != null)
                configManager.ApplyCourseTypeConfiguration(configForm.SelectedCourseType);

            serviceManager.AddServiceFromConfiguredTemplate(configManager.GetConfiguredTemplate());
            LoadCourses();
            courseList.SelectedIndex = courseList.Items.Count - 1;
            RefreshStatusLists();

            var typeInfo = configForm.SelectedCourseType?.Name ?? "ohne Vollzeit/Teilzeit";
            MessageBox.Show(
                $"Service erstellt für {configForm.SelectedLocation.Name} " +
                $"({configForm.SelectedMainTemplateVariant}, {typeInfo}).\nBitte variable Daten anpassen.");
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Fehler beim Erstellen des Services: {ex.Message}");
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

        var title = ServiceTitleBuilder.Build(selectedCourse, courseList.SelectedIndex);
        if (MessageBox.Show(
                $"Service mit PRODUCT_ID '{productId}' löschen?",
                "Service löschen",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Warning) != DialogResult.Yes)
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

    private void ExportXml(object? sender, EventArgs e)
    {
        if (serviceManager.Document == null)
        {
            MessageBox.Show("Bitte zuerst XML öffnen.");
            return;
        }

        using var dialog = new SaveFileDialog { Filter = "XML Dateien (*.xml)|*.xml", FileName = "output.xml" };
        if (dialog.ShowDialog() != DialogResult.OK)
            return;

        try
        {
            if (serviceManager.GetHeaderTemplate() == null)
            {
                var session = templateRepository.LoadMainTemplateSession();
                var headerNode = session?.Document.DocumentElement?.SelectSingleNode("HEADER");
                if (headerNode != null)
                    serviceManager.SetHeaderTemplate(headerNode);
            }

            serviceManager.BuildExportDocument().Save(dialog.FileName);
            MessageBox.Show("XML exportiert.");
        }
        catch (Exception ex)
        {
            MessageBox.Show("Export-Fehler:\n" + ex.Message);
        }
    }

    private void ValidateXml(object? sender, EventArgs e)
    {
        using var dialog = new OpenFileDialog { Filter = "XML Dateien (*.xml)|*.xml|Alle Dateien (*.*)|*.*" };
        if (dialog.ShowDialog() != DialogResult.OK)
            return;

        try
        {
            var xsdPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "schema.xsd");
            serviceManager.ValidateWithSchema(dialog.FileName, xsdPath);
            MessageBox.Show("XML ist gültig laut eingebautem XSD.");
        }
        catch (Exception ex)
        {
            MessageBox.Show("Validierungsfehler:\n" + ex.Message);
        }
    }
}
