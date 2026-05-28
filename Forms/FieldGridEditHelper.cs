using System.Windows.Forms;
using System.Xml;

namespace XmlEditorUi;

public sealed class FieldGridEditHelper
{
    public const string EditColumnName = "Edit";

    private readonly DataGridView _grid;
    private readonly Form _owner;
    private readonly Func<FieldEditContext?> _getContext;

    public FieldGridEditHelper(DataGridView grid, Form owner, Func<FieldEditContext?> getContext)
    {
        _grid = grid;
        _owner = owner;
        _getContext = getContext;
        EnsureEditColumn();
        _grid.CellContentClick += OnCellContentClick;
    }

    public static void EnsureEditColumn(DataGridView grid)
    {
        if (grid.Columns.Contains(EditColumnName))
            return;

        var editColumn = new DataGridViewButtonColumn
        {
            Name = EditColumnName,
            HeaderText = "",
            Text = "…",
            UseColumnTextForButtonValue = true,
            Width = 36,
            FlatStyle = FlatStyle.System,
            ReadOnly = true
        };

        grid.Columns.Add(editColumn);
        editColumn.DisplayIndex = grid.Columns.Count - 1;

        if (grid.Columns.Contains("Field"))
            grid.Columns["Field"]!.FillWeight = 32;
        if (grid.Columns.Contains("Value"))
            grid.Columns["Value"]!.FillWeight = 63;
        editColumn.FillWeight = 5;
    }

    private void EnsureEditColumn() => EnsureEditColumn(_grid);

    private void OnCellContentClick(object? sender, DataGridViewCellEventArgs e)
    {
        if (e.RowIndex < 0 || e.ColumnIndex != _grid.Columns[EditColumnName]!.Index)
            return;

        var row = _grid.Rows[e.RowIndex];
        if (row.Tag is not string fieldPath)
            return;

        if (_getContext() is not { } ctx)
            return;

        var label = row.Cells["Field"]?.Value?.ToString() ?? fieldPath;
        var currentValue = ctx.Node.GetTextByPath(fieldPath)
            ?? row.Cells["Value"]?.Value?.ToString()
            ?? string.Empty;

        if (!TextEditorPopup.TryEdit(_owner, label, currentValue, out var newValue))
            return;

        row.Cells["Value"].Value = FieldValueFormatter.ForGridDisplay(newValue);
        ctx.ApplyValue(fieldPath, newValue);
        ctx.AfterEdit?.Invoke(fieldPath, newValue);
    }
}

public sealed class FieldEditContext
{
    public required XmlNode Node { get; init; }
    public Action<string, string>? AfterEdit { get; init; }

    public void ApplyValue(string path, string value) => Node.SetNodeByPath(path, value);
}

public static class FieldValueFormatter
{
    public static string ForGridDisplay(string value, string? path = null)
    {
        if (string.IsNullOrEmpty(value))
            return value;

        if (path != null && DateFieldHelper.IsDatePath(path))
            return value;

        const int maxPreview = 120;
        var singleLine = value.Replace("\r\n", " ").Replace('\n', ' ').Replace('\r', ' ');
        return singleLine.Length <= maxPreview ? singleLine : singleLine[..maxPreview] + "…";
    }
}
