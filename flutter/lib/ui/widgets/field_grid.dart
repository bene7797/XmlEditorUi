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
        return ColoredBox(
          color: bg.withValues(alpha: 0.55),
          child: ListTile(
            dense: true,
            title: Text(row.label, style: const TextStyle(fontSize: 13)),
            subtitle: Text(
              row.value.isEmpty ? '—' : row.value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: () {
                if (row.isDate && onDateTap != null) {
                  onDateTap!(row);
                } else {
                  onEdit(row, row.value);
                }
              },
            ),
            onTap: () {
              if (row.isDate && onDateTap != null) {
                onDateTap!(row);
              } else {
                onEdit(row, row.value);
              }
            },
          ),
        );
      },
    );
  }
}

class FieldGridRow {
  FieldGridRow({
    required this.label,
    required this.path,
    required this.value,
    required this.color,
    this.isDate = false,
  });

  final String label;
  final String path;
  final String value;
  final FieldRowColor color;
  final bool isDate;
}
