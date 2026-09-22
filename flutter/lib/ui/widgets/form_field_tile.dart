import 'package:flutter/material.dart';

import 'field_grid.dart';

class FormFieldTile extends StatelessWidget {
  const FormFieldTile({
    super.key,
    required this.row,
    required this.onEdit,
  });

  final FieldGridRow row;
  final ValueChanged<FieldGridRow> onEdit;

  @override
  Widget build(BuildContext context) {
    final bg = switch (row.color) {
      FieldRowColor.pending => const Color(0xFFFFE0E0),
      FieldRowColor.changed => const Color(0xFFE3F6E3),
      FieldRowColor.normal => const Color(0xFFF4F7FA),
    };
    final border = switch (row.color) {
      FieldRowColor.pending => const Color(0xFFE57373),
      FieldRowColor.changed => const Color(0xFF66BB6A),
      FieldRowColor.normal => const Color(0xFFB0BEC5),
    };
    final shown = (row.displayValue ?? row.value).trim();

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onEdit(row),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: row.label,
            isDense: true,
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: border),
            ),
            suffixIcon: Icon(
              row.isDate ? Icons.event : Icons.edit_outlined,
              size: 16,
              color: border,
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 28,
            ),
          ),
          child: Text(
            shown.isEmpty ? '—' : shown,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ),
    );
  }
}

class FormFieldRow extends StatelessWidget {
  const FormFieldRow({
    super.key,
    required this.fields,
    required this.onEdit,
  });

  final List<FieldGridRow> fields;
  final ValueChanged<FieldGridRow> onEdit;

  @override
  Widget build(BuildContext context) {
    if (fields.length == 1) {
      return FormFieldTile(row: fields.first, onEdit: onEdit);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: FormFieldTile(row: fields[i], onEdit: onEdit),
          ),
        ],
      ],
    );
  }
}
