using System;
using System.IO;
using System.Windows.Forms;

namespace XmlEditorUi;

public class TemplatePickerForm : Form
{
    private readonly ListBox list = new();
    private readonly Button okButton = new();
    private readonly Button deleteButton = new();
    private string[] templates;

    public string? SelectedTemplatePath { get; private set; }

    public TemplatePickerForm(string[] templates)
    {
        this.templates = templates;

        Text = "Vorlage auswählen";
        Width = 430;
        Height = 320;
        StartPosition = FormStartPosition.CenterParent;

        list.Left = 10;
        list.Top = 10;
        list.Width = 390;
        list.Height = 210;

        okButton.Text = "Laden";
        okButton.Left = 300;
        okButton.Top = 235;
        okButton.Width = 100;
        okButton.Click += OkButton_Click;

        deleteButton.Text = "Löschen";
        deleteButton.Left = 190;
        deleteButton.Top = 235;
        deleteButton.Width = 100;
        deleteButton.Click += DeleteButton_Click;

        Controls.Add(list);
        Controls.Add(okButton);
        Controls.Add(deleteButton);

        RefreshList();
    }

    private void RefreshList()
    {
        list.Items.Clear();

        for (int i = 0; i < templates.Length; i++)
        {
            list.Items.Add(Path.GetFileNameWithoutExtension(templates[i]));
        }
    }

    private void OkButton_Click(object? sender, EventArgs e)
    {
        if (list.SelectedIndex < 0)
        {
            MessageBox.Show("Bitte Vorlage auswählen.");
            return;
        }

        SelectedTemplatePath = templates[list.SelectedIndex];
        DialogResult = DialogResult.OK;
        Close();
    }

    private void DeleteButton_Click(object? sender, EventArgs e)
    {
        if (list.SelectedIndex < 0)
        {
            MessageBox.Show("Bitte Vorlage auswählen.");
            return;
        }

        var path = templates[list.SelectedIndex];
        var name = Path.GetFileNameWithoutExtension(path);

        var result = MessageBox.Show(
            $"Vorlage '{name}' wirklich löschen?",
            "Vorlage löschen",
            MessageBoxButtons.YesNo,
            MessageBoxIcon.Warning
        );

        if (result != DialogResult.Yes)
            return;

        try
        {
            File.Delete(path);

            templates = Directory.GetFiles(
                Path.GetDirectoryName(path)!,
                "*.xml"
            );

            RefreshList();

            MessageBox.Show("Vorlage gelöscht.");
        }
        catch (Exception ex)
        {
            MessageBox.Show("Fehler beim Löschen:\n" + ex.Message);
        }
    }
}