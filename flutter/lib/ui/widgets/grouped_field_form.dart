import 'package:flutter/material.dart';

import 'field_form_layout.dart';
import 'field_grid.dart';
import 'form_field_tile.dart';

class GroupedFieldForm extends StatelessWidget {
  const GroupedFieldForm({
    super.key,
    required this.rows,
    required this.onEdit,
  });

  final List<FieldGridRow> rows;
  final ValueChanged<FieldGridRow> onEdit;

  @override
  Widget build(BuildContext context) {
    final sections = FieldFormLayout.sectionsOf(rows);
    if (sections.isEmpty) {
      return const Center(child: Text('Keine Felder'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      itemCount: sections.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final section = sections[index];
        final color = Color(section.color);
        final pairs = FieldFormLayout.pairRows(section.rows);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  section.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < pairs.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  FormFieldRow(fields: pairs[i], onEdit: onEdit),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
