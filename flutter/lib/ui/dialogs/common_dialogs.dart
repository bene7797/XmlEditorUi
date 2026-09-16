import 'package:flutter/material.dart';

Future<String?> showTextEditorDialog(
  BuildContext context, {
  required String title,
  required String initialValue,
}) {
  final controller = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 520,
        child: TextField(
          controller: controller,
          maxLines: 12,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Future<DateTime?> showDateTimePickerDialog(
  BuildContext context, {
  required DateTime initial,
  required bool includeTime,
}) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );
  if (date == null || !context.mounted) return null;
  if (!includeTime) return DateTime(date.year, date.month, date.day);

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (time == null) return DateTime(date.year, date.month, date.day);
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
