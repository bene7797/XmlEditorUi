using System.Windows.Forms;

namespace XmlEditorUi;

/// <summary>
/// Dialog zur Auswahl von Ort, Main-Template und optional Beschäftigungsart (nur bei Standard-Main-Template).
/// </summary>
public class ServiceConfigurationForm : Form
{
    private readonly ComboBox locationCombo = new();
    private readonly ComboBox mainTemplateCombo = new();
    private readonly Label courseTypeLabel = new();
    private readonly ComboBox courseTypeCombo = new();
    private readonly Button okButton = new();
    private readonly Button cancelButton = new();

    private readonly List<LocationProfile> locations;
    private readonly List<CourseTypeProfile> courseTypes;

    public LocationProfile? SelectedLocation { get; private set; }
    public CourseTypeProfile? SelectedCourseType { get; private set; }
    public string SelectedMainTemplateVariant { get; private set; } = MainTemplateVariants.Standard;

    public bool IsExternenpruefung =>
        MainTemplateVariants.IsExternenpruefung(SelectedMainTemplateVariant);

    public ServiceConfigurationForm(List<LocationProfile> locations, List<CourseTypeProfile> courseTypes)
    {
        this.locations = locations;
        this.courseTypes = courseTypes;

        Text = "Service erstellen";
        Width = 420;
        Height = 300;
        StartPosition = FormStartPosition.CenterParent;
        FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = false;
        MinimizeBox = false;

        var locationLabel = new Label { Text = "Ort:", Left = 20, Top = 20, Width = 120, Height = 20 };
        locationCombo.SetBounds(140, 18, 250, 25);
        locationCombo.DropDownStyle = ComboBoxStyle.DropDownList;
        locationCombo.Items.AddRange(locations.Select(l => l.Name).ToArray());

        var mainTemplateLabel = new Label { Text = "Main-Template:", Left = 20, Top = 58, Width = 120, Height = 20 };
        mainTemplateCombo.SetBounds(140, 56, 250, 25);
        mainTemplateCombo.DropDownStyle = ComboBoxStyle.DropDownList;
        mainTemplateCombo.Items.AddRange(MainTemplateVariants.All.Cast<object>().ToArray());
        mainTemplateCombo.SelectedIndexChanged += (_, _) => UpdateCourseTypeVisibility();

        courseTypeLabel.Text = "Beschäftigungsart:";
        courseTypeLabel.SetBounds(20, 96, 120, 20);
        courseTypeCombo.SetBounds(140, 94, 250, 25);
        courseTypeCombo.DropDownStyle = ComboBoxStyle.DropDownList;
        courseTypeCombo.Items.AddRange(courseTypes.Select(c => c.Name).ToArray());

        okButton.Text = "Erstellen";
        okButton.SetBounds(220, 180, 150, 30);
        okButton.Click += OkButton_Click;

        cancelButton.Text = "Abbrechen";
        cancelButton.SetBounds(60, 180, 150, 30);
        cancelButton.Click += (_, _) => DialogResult = DialogResult.Cancel;

        Controls.AddRange([
            locationLabel, locationCombo,
            mainTemplateLabel, mainTemplateCombo,
            courseTypeLabel, courseTypeCombo,
            okButton, cancelButton
        ]);

        if (locationCombo.Items.Count > 0)
            locationCombo.SelectedIndex = 0;
        if (mainTemplateCombo.Items.Count > 0)
            mainTemplateCombo.SelectedIndex = 0;

        UpdateCourseTypeVisibility();
    }

    private void UpdateCourseTypeVisibility()
    {
        var isExtern = mainTemplateCombo.SelectedItem is string variant
            && MainTemplateVariants.IsExternenpruefung(variant);

        courseTypeLabel.Visible = !isExtern;
        courseTypeCombo.Visible = !isExtern;
        courseTypeCombo.Enabled = !isExtern;

        if (!isExtern && courseTypeCombo.SelectedIndex < 0 && courseTypeCombo.Items.Count > 0)
            courseTypeCombo.SelectedIndex = 0;
    }

    private void OkButton_Click(object? sender, EventArgs e)
    {
        if (locationCombo.SelectedIndex < 0)
        {
            MessageBox.Show("Bitte Ort auswählen.");
            return;
        }

        if (mainTemplateCombo.SelectedItem is not string mainVariant)
        {
            MessageBox.Show("Bitte Main-Template auswählen.");
            return;
        }

        var isExtern = MainTemplateVariants.IsExternenpruefung(mainVariant);

        if (!isExtern && courseTypeCombo.SelectedIndex < 0)
        {
            MessageBox.Show("Bitte Beschäftigungsart auswählen.");
            return;
        }

        SelectedLocation = locations[locationCombo.SelectedIndex];
        SelectedMainTemplateVariant = mainVariant;
        SelectedCourseType = isExtern ? null : courseTypes[courseTypeCombo.SelectedIndex];

        DialogResult = DialogResult.OK;
        Close();
    }
}
