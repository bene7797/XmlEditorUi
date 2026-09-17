import 'package:flutter/material.dart';

import '../../data/reference/openq_reference.dart';

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

Future<CodedValue?> showCodedPickerDialog(
  BuildContext context, {
  required String title,
  required List<CodedValue> options,
  String? currentId,
}) {
  return showDialog<CodedValue>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 480,
        height: 460,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Der XML-Wert type="…" steht für:',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final option = options[i];
                  return ListTile(
                    selected: option.id.toLowerCase() ==
                        (currentId ?? '').toLowerCase(),
                    dense: true,
                    title: Text(option.display),
                    onTap: () => Navigator.pop(ctx, option),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Abbrechen'),
        ),
      ],
    ),
  );
}

Future<CodedValue?> showSystematikPickerDialog(
  BuildContext context, {
  required OpenqReference reference,
  String? currentId,
}) {
  var query = currentId ?? '';
  var results = reference.searchSystematik(query);

  return showDialog<CodedValue>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Kurssystematik'),
            content: SizedBox(
              width: 560,
              height: 480,
              child: Column(
                children: [
                  TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Suche (Code oder Bezeichnung)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      query = value;
                      setState(() {
                        results = reference.searchSystematik(query);
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (_, i) {
                        final option = results[i];
                        return ListTile(
                          selected: option.id == currentId,
                          dense: true,
                          title: Text(option.id),
                          subtitle: Text(option.label),
                          onTap: () => Navigator.pop(ctx, option),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Abbrechen'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<({String user, String password, int action})?> showKursnetUploadDialog(
  BuildContext context, {
  String? savedUser,
}) {
  final userController = TextEditingController(text: savedUser ?? '');
  final passwordController = TextEditingController();
  var action = 1;

  return showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('KURSNET-Upload'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: userController,
                    decoration: const InputDecoration(
                      labelText: 'Benutzer',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Passwort',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Aktion'),
                  ),
                  DropdownButton<int>(
                    isExpanded: true,
                    value: action,
                    items: const [
                      DropdownMenuItem(
                        value: 1,
                        child: Text('Nur prüfen (action=1)'),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Text('Prüfen und speichern (action=2)'),
                      ),
                    ],
                    onChanged: (v) => setState(() => action = v ?? 1),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, (
                  user: userController.text.trim(),
                  password: passwordController.text,
                  action: action,
                )),
                child: const Text('Senden'),
              ),
            ],
          );
        },
      );
    },
  );
}
