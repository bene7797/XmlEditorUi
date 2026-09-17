import 'package:flutter/material.dart';

enum FieldRowColor { pending, changed, normal }

class FieldGrid extends StatelessWidget {
  const FieldGrid({
    super.key,
    required this.rows,
    required this.onEdit,
    this.onDateTap,
  });

  final List<FieldGridRow> rows;
  final void Function(FieldGridRow row, String newValue) onEdit;
  final void Function(FieldGridRow row)? onDateTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final row = rows[index];
        final bg = switch (row.color) {
          FieldRowColor.pending => const Color(0xFFF08080),
          FieldRowColor.changed => const Color(0xFF90EE90),
          FieldRowColor.normal => const Color(0xFFADD8E6),
        };
        final tile = ListTile(
          dense: true,
          title: Text(row.label, style: const TextStyle(fontSize: 13)),
          subtitle: Text(
            _visibleValue(row),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (row.tooltip != null)
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 18),
                  tooltip: row.tooltip,
                  onPressed: () => _showTooltipDialog(context, row),
                ),
              IconButton(
                icon: const Icon(Icons.more_horiz),
                onPressed: () => _activate(row),
              ),
            ],
          ),
          onTap: () => _activate(row),
        );
        return ColoredBox(
          color: bg.withValues(alpha: 0.55),
          child: Material(color: Colors.transparent, child: tile),
        );
      },
    );
  }

  String _visibleValue(FieldGridRow row) {
    final shown = (row.displayValue ?? row.value).trim();
    return shown.isEmpty ? '—' : shown;
  }

  void _showTooltipDialog(BuildContext context, FieldGridRow row) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(row.label),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(child: Text(row.tooltip ?? '')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _activate(FieldGridRow row) {
    if (row.isDate && onDateTap != null) {
      onDateTap!(row);
    } else {
      onEdit(row, row.value);
    }
  }
}

class FieldGridRow {
  FieldGridRow({
    required this.label,
    required this.path,
    required this.value,
    required this.color,
    this.isDate = false,
    this.tooltip,
    this.displayValue,
  });

  final String label;
  final String path;
  final String value;
  final FieldRowColor color;
  final bool isDate;
  final String? tooltip;
  final String? displayValue;
}
