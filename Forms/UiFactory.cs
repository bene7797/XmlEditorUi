namespace XmlEditorUi;

internal static class UiFactory
{
    public static DataGridView CreateFieldGrid(int top, int height = 240)
    {
        var grid = new DataGridView
        {
            Left = 10,
            Top = top,
            Width = 1160,
            Height = height
        };
        ConfigureFieldGrid(grid);
        return grid;
    }

    public static void ConfigureFieldGrid(DataGridView grid, int fieldWeight = 38, int valueWeight = 62)
    {
        grid.AllowUserToAddRows = false;
        grid.AllowUserToDeleteRows = false;
        grid.RowHeadersVisible = false;
        grid.MultiSelect = false;
        grid.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
        grid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
        grid.BorderStyle = BorderStyle.Fixed3D;
        grid.BackgroundColor = SystemColors.Window;
        grid.RowTemplate.Height = 28;
        grid.ColumnHeadersHeightSizeMode = DataGridViewColumnHeadersHeightSizeMode.DisableResizing;
        grid.ScrollBars = ScrollBars.Vertical;

        if (grid.Columns.Count == 0)
            AddFieldColumns(grid);

        grid.Columns["Field"]!.FillWeight = fieldWeight;
        grid.Columns["Value"]!.FillWeight = valueWeight;
        grid.Columns["Field"]!.MinimumWidth = 165;
        grid.Columns["Value"]!.MinimumWidth = 240;
        grid.Columns["Value"]!.DefaultCellStyle.WrapMode = DataGridViewTriState.False;
    }

    public static PropertyGrid CreatePropertyGrid(int top, int height = 330) => new()
    {
        Left = 10,
        Top = top,
        Width = 1160,
        Height = height,
        ToolbarVisible = false,
        HelpVisible = false
    };

    public static void AddFieldColumns(DataGridView grid)
    {
        grid.Columns.Add("Field", "Feld");
        grid.Columns.Add("Value", "Wert");
        grid.Columns["Field"]!.ReadOnly = true;
    }

    public static Button CreateButton(string text, int left, int top, int width, EventHandler click)
    {
        var button = new Button { Text = text, Left = left, Top = top, Width = width };
        button.Click += click;
        return button;
    }
}
