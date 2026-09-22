import 'package:flutter/material.dart';

import 'field_form_layout.dart';
import 'field_grid.dart';
import 'form_field_tile.dart';

class QuickEditForm extends StatelessWidget {
  const QuickEditForm({
    super.key,
    required this.rows,
    required this.onEdit,
  });

  final List<FieldGridRow> rows;
  final ValueChanged<FieldGridRow> onEdit;

  @override
  Widget build(BuildContext context) {
    final groups = FieldFormLayout.pairRows(rows);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < groups.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              FormFieldRow(fields: groups[i], onEdit: onEdit),
            ],
          ],
        ),
      ),
    );
  }
}
