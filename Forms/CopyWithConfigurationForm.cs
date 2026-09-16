using System.Windows.Forms;
using System.Xml;

namespace XmlEditorUi;

/// <summary>
/// Dialog zum Kopieren eines Services mit neuem Ort und optionaler Beschäftigungsart.
/// </summary>
public class CopyWithConfigurationForm : Form
{
    private readonly ComboBox locationCombo = new();
    private readonly Label courseTypeLabel = new();
    private readonly ComboBox courseTypeCombo = new();
    private readonly Button okButton = new();
    private readonly Button cancelButton = new();

    private readonly List<LocationProfile> locations;
    private readonly List<CourseTypeProfile> courseTypes;
    private readonly bool showCourseType;

    public LocationProfile? SelectedLocation { get; private set; }
    public CourseTypeProfile? SelectedCourseType { get; private set; }

    public CopyWithConfigurationForm(
        List<LocationProfile> locations,
        List<CourseTypeProfile> courseTypes,
        XmlNode? sourceService = null)
    {
        this.locations = locations;
        this.courseTypes = courseTypes;
        showCourseType = !IsExternenpruefung(sourceService);

        Text = "Kopieren mit…";
        Width = 420;
        Height = showCourseType ? 220 : 170;
        StartPosition = FormStartPosition.CenterParent;
        FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = false;
        MinimizeBox = false;

        var locationLabel = new Label { Text = "Ort:", Left = 20, Top = 20, Width = 120, Height = 20 };
        locationCombo.SetBounds(140, 18, 250, 25);
        locationCombo.DropDownStyle = ComboBoxStyle.DropDownList;
        locationCombo.Items.AddRange(locations.Select(l => l.Name).ToArray());

        courseTypeLabel.Text = "Beschäftigungsart:";
        courseTypeLabel.SetBounds(20, 58, 120, 20);
        courseTypeCombo.SetBounds(140, 56, 250, 25);
        courseTypeCombo.DropDownStyle = ComboBoxStyle.DropDownList;
        courseTypeCombo.Items.AddRange(courseTypes.Select(c => c.Name).ToArray());

        courseTypeLabel.Visible = showCourseType;
        courseTypeCombo.Visible = showCourseType;

        var buttonTop = showCourseType ? 110 : 70;
        okButton.Text = "Kopieren";
        okButton.SetBounds(220, buttonTop, 150, 30);
        okButton.Click += OkButton_Click;

        cancelButton.Text = "Abbrechen";
        cancelButton.SetBounds(60, buttonTop, 150, 30);
        cancelButton.Click += (_, _) => DialogResult = DialogResult.Cancel;

        Controls.AddRange([
            locationLabel, locationCombo,
            courseTypeLabel, courseTypeCombo,
            okButton, cancelButton
        ]);

        PreselectFromSource(sourceService);
    }

    private void PreselectFromSource(XmlNode? sourceService)
    {
        var city = sourceService?.GetTextByPath(
            "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/CITY");
        var locationIndex = FindLocationIndex(city);
        locationCombo.SelectedIndex = locationIndex >= 0 ? locationIndex : (locationCombo.Items.Count > 0 ? 0 : -1);

        if (!showCourseType || courseTypeCombo.Items.Count == 0)
            return;

        var instructionTime = sourceService?.GetTextByPath(
            "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_TIME");
        var courseTypeIndex = FindCourseTypeIndex(instructionTime);
        courseTypeCombo.SelectedIndex = courseTypeIndex >= 0 ? courseTypeIndex : 0;
    }

    private int FindLocationIndex(string? city)
    {
        if (string.IsNullOrWhiteSpace(city))
            return -1;

        for (var i = 0; i < locations.Count; i++)
        {
            if (locations[i].Name.Equals(city, StringComparison.OrdinalIgnoreCase))
                return i;

            if (locations[i].Values.TryGetValue("CITY", out var profileCity)
                && profileCity.Equals(city, StringComparison.OrdinalIgnoreCase))
                return i;
        }

        return -1;
    }

    private int FindCourseTypeIndex(string? instructionTime)
    {
        if (string.IsNullOrWhiteSpace(instructionTime))
            return -1;

        for (var i = 0; i < courseTypes.Count; i++)
        {
            if (courseTypes[i].Name.Equals(instructionTime, StringComparison.OrdinalIgnoreCase))
                return i;

            if (courseTypes[i].Values.TryGetValue("INSTRUCTION_TIME", out var value)
                && value.Equals(instructionTime, StringComparison.OrdinalIgnoreCase))
                return i;
        }

        return -1;
    }

    private static bool IsExternenpruefung(XmlNode? service)
    {
        if (service == null)
            return false;

        var educationType = service.GetTextByPath(
            "SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/EDUCATION_TYPE") ?? "";

        return educationType.Contains("Nachholen", StringComparison.OrdinalIgnoreCase)
            || educationType.Contains("Extern", StringComparison.OrdinalIgnoreCase);
    }

    private void OkButton_Click(object? sender, EventArgs e)
    {
        if (locationCombo.SelectedIndex < 0)
        {
            MessageBox.Show("Bitte Ort auswählen.");
            return;
        }

        if (showCourseType && courseTypeCombo.SelectedIndex < 0)
        {
            MessageBox.Show("Bitte Beschäftigungsart auswählen.");
            return;
        }

        SelectedLocation = locations[locationCombo.SelectedIndex];
        SelectedCourseType = showCourseType ? courseTypes[courseTypeCombo.SelectedIndex] : null;

        DialogResult = DialogResult.OK;
        Close();
    }
}
