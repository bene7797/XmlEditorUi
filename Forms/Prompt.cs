using System.Windows.Forms;

namespace XmlEditorUi;

public static class Prompt
{
    public static string? ShowDialog(string text, string caption)
    {
        var prompt = new Form
        {
            Width = 400,
            Height = 160,
            Text = caption,
            StartPosition = FormStartPosition.CenterParent
        };

        var label = new Label
        {
            Left = 20,
            Top = 20,
            Width = 340,
            Text = text
        };

        var input = new TextBox
        {
            Left = 20,
            Top = 50,
            Width = 340
        };

        var confirmation = new Button
        {
            Text = "OK",
            Left = 200,
            Width = 75,
            Top = 85,
            DialogResult = DialogResult.OK
        };

        var cancel = new Button
        {
            Text = "Abbrechen",
            Left = 285,
            Width = 75,
            Top = 85,
            DialogResult = DialogResult.Cancel
        };

        prompt.Controls.Add(label);
        prompt.Controls.Add(input);
        prompt.Controls.Add(confirmation);
        prompt.Controls.Add(cancel);

        prompt.AcceptButton = confirmation;
        prompt.CancelButton = cancel;

        return prompt.ShowDialog() == DialogResult.OK
            ? input.Text
            : null;
    }
}