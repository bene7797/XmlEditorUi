import 'package:flutter/material.dart';

import '../../domain/catalog/course_list_filter.dart';
import '../../domain/dates/date_field_rules.dart';

class CourseListFilterBar extends StatelessWidget {
  const CourseListFilterBar({
    super.key,
    required this.filter,
    required this.cities,
    required this.startDates,
    required this.onChanged,
    required this.onClear,
    this.includeDateFilters = true,
  });

  final CourseListFilter filter;
  final List<String> cities;
  final List<DateTime> startDates;
  final ValueChanged<CourseListFilter> onChanged;
  final VoidCallback onClear;
  final bool includeDateFilters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (includeDateFilters)
            _dropdown<DateTime>(
              label: 'Termin',
              value: filter.startDate,
              items: startDates,
              itemLabel: (d) => DateFieldRules.formatUi(d, includeTime: false),
              onChanged: (v) => onChanged(
                filter.copyWith(startDate: v, clearStartDate: v == null),
              ),
            ),
          _dropdown<String>(
            label: 'Ort',
            value: filter.city,
            items: cities,
            itemLabel: (c) => c,
            onChanged: (v) => onChanged(
              filter.copyWith(city: v, clearCity: v == null),
            ),
          ),
          _dropdown<InstructionTimeFilter>(
            label: 'Beschäftigung',
            value: filter.instructionTime,
            items: InstructionTimeFilter.values,
            itemLabel: (v) => v.label,
            onChanged: (v) => onChanged(
              filter.copyWith(
                instructionTime: v,
                clearInstructionTime: v == null,
              ),
            ),
          ),
          _dropdown<EducationKindFilter>(
            label: 'Art',
            value: filter.educationKind,
            items: EducationKindFilter.values,
            itemLabel: (v) => v.label,
            onChanged: (v) => onChanged(
              filter.copyWith(
                educationKind: v,
                clearEducationKind: v == null,
              ),
            ),
          ),
          if (includeDateFilters)
            FilterChip(
              label: const Text('Abgelaufen'),
              selected: filter.showExpired,
              onSelected: (v) => onChanged(filter.copyWith(showExpired: v)),
            ),
          if (filter.hasCriteria)
            ActionChip(
              label: const Text('Zurücksetzen'),
              onPressed: onClear,
            ),
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T value) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      width: 168,
      child: DropdownButtonFormField<T>(
        isExpanded: true,
        isDense: true,
        value: value != null && items.contains(value) ? value : null,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
        items: [
          DropdownMenuItem<T>(
            value: null,
            child: Text('Alle'),
          ),
          ...items.map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
