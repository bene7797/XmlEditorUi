namespace XmlEditorUi;

public sealed class TextEditorPopup : Form
{
    private readonly TextBox textBox = new();

    public string EditedText { get; private set; } = string.Empty;

    public TextEditorPopup(string title, string initialText)
    {
        Text = title;
        Width = 640;
        Height = 480;
        StartPosition = FormStartPosition.CenterParent;
        FormBorderStyle = FormBorderStyle.Sizable;
        MinimizeBox = false;
        MaximizeBox = true;
        KeyPreview = true;

        textBox.Multiline = true;
        textBox.ScrollBars = ScrollBars.Both;
        textBox.WordWrap = true;
        textBox.AcceptsReturn = true;
        textBox.AcceptsTab = true;
        textBox.Dock = DockStyle.Fill;
        textBox.Font = new Font("Segoe UI", 10f);
        textBox.Text = initialText;

        var okButton = new Button { Text = "OK", DialogResult = DialogResult.OK, Width = 90, Height = 28 };
        var cancelButton = new Button { Text = "Abbrechen", DialogResult = DialogResult.Cancel, Width = 90, Height = 28 };

        var buttonPanel = new FlowLayoutPanel
        {
            Dock = DockStyle.Bottom,
            Height = 44,
            FlowDirection = FlowDirection.RightToLeft,
            Padding = new Padding(8, 6, 8, 6)
        };
        buttonPanel.Controls.Add(cancelButton);
        buttonPanel.Controls.Add(okButton);

        var mainPanel = new Panel { Dock = DockStyle.Fill, Padding = new Padding(10) };
        mainPanel.Controls.Add(textBox);

        Controls.Add(mainPanel);
        Controls.Add(buttonPanel);

        AcceptButton = okButton;
        CancelButton = cancelButton;
    }

    protected override void OnFormClosing(FormClosingEventArgs e)
    {
        if (DialogResult == DialogResult.OK)
            EditedText = textBox.Text;

        base.OnFormClosing(e);
    }

    public static bool TryEdit(IWin32Window owner, string title, string initialText, out string result)
    {
        using var popup = new TextEditorPopup(title, initialText);
        if (popup.ShowDialog(owner) != DialogResult.OK)
        {
            result = initialText;
            return false;
        }

        result = popup.EditedText;
        return true;
    }
}
