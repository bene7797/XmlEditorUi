using System.Windows.Forms;
using System.Xml;

namespace XmlEditorUi;

public sealed class TemplateFieldGridBinder
{
    private readonly DataGridView _grid;
    private readonly TabPage _tab;
    private readonly PropertyGrid? _propertyGrid;
    private readonly Form _owner;
    public TemplateFieldGridBinder(Form owner, TabPage tab, DataGridView grid, PropertyGrid? propertyGrid = null)
    {
        _owner = owner;
        _tab = tab;
        _grid = grid;
        _propertyGrid = propertyGrid;

        _ = new FieldGridEditHelper(_grid, _owner, () =>
        {
            if (GetSession() is not { } session)
                return null;

            return new FieldEditContext
            {
                Node = session.Service,
                AfterEdit = (_, _) =>
                {
                    if (_propertyGrid != null)
                        _propertyGrid.SelectedObject = new CourseEditableObject(session.Service, onlyFilledFields: true);
                }
            };
        });

        _grid.CellValueChanged += OnCellValueChanged;
        _grid.CellClick += OnCellClick;
        _grid.CurrentCellDirtyStateChanged += (_, _) =>
        {
            if (_grid.IsCurrentCellDirty)
                _grid.CommitEdit(DataGridViewDataErrorContexts.Commit);
        };
    }

    public void BindSession(TemplateDocumentSession session) =>
        _tab.Tag = session;

    public TemplateDocumentSession? GetSession() =>
        _tab.Tag as TemplateDocumentSession;

    public void LoadFields(XmlNode service, IEnumerable<TemplateFieldDefinition> fields)
    {
        _grid.Rows.Clear();

        foreach (var field in fields)
        {
            var raw = service.GetTextByPath(field.Path) ?? string.Empty;
            var rowIndex = _grid.Rows.Add(field.Label, FieldValueFormatter.ForGridDisplay(raw, field.Path));
            var row = _grid.Rows[rowIndex];
            row.Tag = field.Path;
            row.Cells["Value"].ReadOnly = !DateFieldHelper.IsDatePath(field.Path);
        }

        if (_propertyGrid != null)
            _propertyGrid.SelectedObject = new CourseEditableObject(service, onlyFilledFields: true);
    }

    public void SaveDocument(string successMessage, Action? reload = null)
    {
        if (GetSession() is not { } session)
        {
            MessageBox.Show("Kein Template geladen");
            return;
        }

        try
        {
            session.Save();
            MessageBox.Show(successMessage);
            reload?.Invoke();
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Fehler beim Speichern: {ex.Message}");
        }
    }

    private void OnCellValueChanged(object? sender, DataGridViewCellEventArgs e)
    {
        if (e.RowIndex < 0 || e.ColumnIndex != 1)
            return;

        if (GetSession() is not { } session)
            return;

        var row = _grid.Rows[e.RowIndex];
        if (row.Tag is not string fieldPath)
            return;

        var newValue = row.Cells[1].Value?.ToString() ?? string.Empty;
        session.Service.SetNodeByPath(fieldPath, newValue);
    }

    private void OnCellClick(object? sender, DataGridViewCellEventArgs e)
    {
        if (GetSession() is not { } session)
            return;

        if (e.RowIndex < 0 || e.ColumnIndex != 1)
            return;

        var row = _grid.Rows[e.RowIndex];
        if (row.Tag is not string fieldPath || !DateFieldHelper.IsDatePath(fieldPath))
            return;

        ShowDatePicker(row, fieldPath, session.Service);
    }

    private void ShowDatePicker(DataGridViewRow row, string path, XmlNode service)
    {
        var currentValue = row.Cells[1].Value?.ToString();
        if (!DateFieldHelper.TryParse(currentValue, out var initialDate))
            initialDate = DateTime.Now;

        using var popup = new DateTimePickerPopup(initialDate, includeTime: DateFieldHelper.IsCourseDatePath(path));

        if (popup.ShowDialog(_owner) != DialogResult.OK)
            return;

        var formatted = DateFieldHelper.Format(popup.SelectedValue, DateFieldHelper.IsCourseDatePath(path));
        row.Cells[1].Value = formatted;
        service.SetNodeByPath(path, formatted);
    }
}
