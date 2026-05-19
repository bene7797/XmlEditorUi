using System;
using System.Collections.Generic;
using System.Linq;
using System.Windows.Forms;

namespace XmlEditorUi;

/// <summary>
/// Dialog zur Auswahl von Ort und Beschäftigungsart für neue Services.
/// 
/// Benutzer wählt:
/// 1. Ort (Leipzig/Kassel)
/// 2. Beschäftigungsart (Vollzeit/Teilzeit/Externenprüfung)
/// </summary>
public class ServiceConfigurationForm : Form
{
    private readonly ComboBox locationCombo = new();
    private readonly ComboBox courseTypeCombo = new();
    private readonly Button okButton = new();
    private readonly Button cancelButton = new();

    private readonly List<LocationProfile> locations;
    private readonly List<CourseTypeProfile> courseTypes;

    public LocationProfile? SelectedLocation { get; private set; }
    public CourseTypeProfile? SelectedCourseType { get; private set; }

    public ServiceConfigurationForm(List<LocationProfile> locations, List<CourseTypeProfile> courseTypes)
    {
        this.locations = locations;
        this.courseTypes = courseTypes;

        Text = "Service erstellen";
        Width = 400;
        Height = 250;
        StartPosition = FormStartPosition.CenterParent;
        FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = false;
        MinimizeBox = false;

        // Ort Label
        var locationLabel = new Label
        {
            Text = "Ort:",
            Left = 20,
            Top = 20,
            Width = 80,
            Height = 20
        };

        locationCombo.Left = 120;
        locationCombo.Top = 20;
        locationCombo.Width = 240;
        locationCombo.Height = 25;
        locationCombo.DropDownStyle = ComboBoxStyle.DropDownList;
        locationCombo.Items.AddRange(locations.Select(l => l.Name).ToArray());

        // Beschäftigungsart Label
        var courseTypeLabel = new Label
        {
            Text = "Beschäftigungsart:",
            Left = 20,
            Top = 60,
            Width = 100,
            Height = 20
        };

        courseTypeCombo.Left = 120;
        courseTypeCombo.Top = 60;
        courseTypeCombo.Width = 240;
        courseTypeCombo.Height = 25;
        courseTypeCombo.DropDownStyle = ComboBoxStyle.DropDownList;
        courseTypeCombo.Items.AddRange(courseTypes.Select(c => c.Name).ToArray());

        // OK Button
        okButton.Text = "Erstellen";
        okButton.Left = 210;
        okButton.Top = 130;
        okButton.Width = 150;
        okButton.Height = 30;
        okButton.Click += OkButton_Click;

        // Cancel Button
        cancelButton.Text = "Abbrechen";
        cancelButton.Left = 50;
        cancelButton.Top = 130;
        cancelButton.Width = 150;
        cancelButton.Height = 30;
        cancelButton.Click += (s, e) => DialogResult = DialogResult.Cancel;

        Controls.Add(locationLabel);
        Controls.Add(locationCombo);
        Controls.Add(courseTypeLabel);
        Controls.Add(courseTypeCombo);
        Controls.Add(okButton);
        Controls.Add(cancelButton);

        // Defaults
        if (locationCombo.Items.Count > 0)
            locationCombo.SelectedIndex = 0;
        if (courseTypeCombo.Items.Count > 0)
            courseTypeCombo.SelectedIndex = 0;
    }

    private void OkButton_Click(object? sender, EventArgs e)
    {
        if (locationCombo.SelectedIndex < 0)
        {
            MessageBox.Show("Bitte Ort auswählen.");
            return;
        }

        if (courseTypeCombo.SelectedIndex < 0)
        {
            MessageBox.Show("Bitte Beschäftigungsart auswählen.");
            return;
        }

        SelectedLocation = locations[locationCombo.SelectedIndex];
        SelectedCourseType = courseTypes[courseTypeCombo.SelectedIndex];

        DialogResult = DialogResult.OK;
        Close();
    }
}
