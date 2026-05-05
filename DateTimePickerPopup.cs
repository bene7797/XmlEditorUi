using System;
using System.Drawing;
using System.Windows.Forms;

namespace XmlEditorUi;

public class DateTimePickerPopup : Form
{
    private readonly MonthCalendar calendar = new();
    private readonly NumericUpDown hourBox = new();
    private readonly NumericUpDown minuteBox = new();
    private readonly Button todayButton = new();
    private readonly Button okButton = new();
    private readonly Button cancelButton = new();

    private readonly bool includeTime;

    public DateTime SelectedValue { get; private set; }

    public DateTimePickerPopup(DateTime initialValue, bool includeTime)
    {
        this.includeTime = includeTime;
        SelectedValue = initialValue;

        Text = includeTime ? "Datum und Uhrzeit wählen" : "Datum wählen";
        Width = 360;
        Height = includeTime ? 390 : 330;
        StartPosition = FormStartPosition.CenterParent;
        FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = false;
        MinimizeBox = false;
        KeyPreview = true;

        calendar.Left = 20;
        calendar.Top = 20;
        calendar.MaxSelectionCount = 1;
        calendar.SetDate(initialValue);

        todayButton.Text = "Heute";
        todayButton.Left = 20;
        todayButton.Top = 210;
        todayButton.Width = 90;
        todayButton.Click += (_, _) => calendar.SetDate(DateTime.Today);

        Controls.Add(calendar);
        Controls.Add(todayButton);

        if (includeTime)
        {
            var timeLabel = new Label
            {
                Text = "Uhrzeit:",
                Left = 20,
                Top = 255,
                Width = 70
            };

            hourBox.Left = 90;
            hourBox.Top = 250;
            hourBox.Width = 60;
            hourBox.Minimum = 0;
            hourBox.Maximum = 23;
            hourBox.Value = initialValue.Hour;
            hourBox.Font = new Font("Segoe UI", 11);

            var colonLabel = new Label
            {
                Text = ":",
                Left = 155,
                Top = 254,
                Width = 10,
                Font = new Font("Segoe UI", 12, FontStyle.Bold)
            };

            minuteBox.Left = 170;
            minuteBox.Top = 250;
            minuteBox.Width = 60;
            minuteBox.Minimum = 0;
            minuteBox.Maximum = 59;
            minuteBox.Value = initialValue.Minute;
            minuteBox.Font = new Font("Segoe UI", 11);

            Controls.Add(timeLabel);
            Controls.Add(hourBox);
            Controls.Add(colonLabel);
            Controls.Add(minuteBox);
        }

        okButton.Text = "OK";
        okButton.Left = 155;
        okButton.Top = includeTime ? 310 : 250;
        okButton.Width = 80;
        okButton.DialogResult = DialogResult.OK;
        okButton.Click += (_, _) => Confirm();

        cancelButton.Text = "Abbrechen";
        cancelButton.Left = 245;
        cancelButton.Top = includeTime ? 310 : 250;
        cancelButton.Width = 90;
        cancelButton.DialogResult = DialogResult.Cancel;

        Controls.Add(okButton);
        Controls.Add(cancelButton);

        AcceptButton = okButton;
        CancelButton = cancelButton;

        KeyDown += (_, e) =>
        {
            if (e.KeyCode == Keys.Enter)
            {
                Confirm();
                DialogResult = DialogResult.OK;
                Close();
            }

            if (e.KeyCode == Keys.Escape)
            {
                DialogResult = DialogResult.Cancel;
                Close();
            }
        };
    }

    private void Confirm()
    {
        var date = calendar.SelectionStart.Date;

        if (includeTime)
        {
            date = date
                .AddHours((double)hourBox.Value)
                .AddMinutes((double)minuteBox.Value);
        }

        SelectedValue = date;
    }
}