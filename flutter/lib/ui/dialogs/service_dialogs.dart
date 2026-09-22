import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../../domain/catalog/models.dart';

Future<XmlElement?> showAngebotPickerDialog(
  BuildContext context, {
  required List<({XmlElement service, String title})> angebote,
  XmlElement? preselected,
}) async {
  if (angebote.isEmpty) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => const AlertDialog(
        title: Text('Kein Angebot'),
        content: Text(
          'Es gibt noch kein Bildungsangebot. '
          'Bitte zuerst „Neues Angebot“ anlegen.',
        ),
      ),
    );
    return null;
  }

  return showDialog<XmlElement>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Angebot wählen'),
        content: SizedBox(
          width: 460,
          height: 360,
          child: ListView.separated(
            itemCount: angebote.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = angebote[index];
              final selected = identical(item.service, preselected);
              return ListTile(
                selected: selected,
                title: Text(item.title),
                trailing: selected ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(ctx, item.service),
              );
            },
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
}

Future<({LocationProfile location, CourseTypeProfile? courseType})?>
    showCopyWithDialog(
  BuildContext context, {
  required List<LocationProfile> locations,
  required List<CourseTypeProfile> courseTypes,
  required bool showCourseType,
  LocationProfile? preselectedLocation,
  CourseTypeProfile? preselectedCourseType,
  String title = 'Kopieren mit…',
  String confirmLabel = 'Kopieren',
}) {
  return showLocationAndCourseTypeDialog(
    context,
    locations: locations,
    courseTypes: courseTypes,
    showCourseType: showCourseType,
    preselectedLocation: preselectedLocation,
    preselectedCourseType: preselectedCourseType,
    title: title,
    confirmLabel: confirmLabel,
  );
}

Future<({LocationProfile location, CourseTypeProfile? courseType})?>
    showAddTerminDialog(
  BuildContext context, {
  required List<LocationProfile> locations,
  required List<CourseTypeProfile> courseTypes,
  required bool showCourseType,
  LocationProfile? preselectedLocation,
  CourseTypeProfile? preselectedCourseType,
}) {
  return showLocationAndCourseTypeDialog(
    context,
    locations: locations,
    courseTypes: courseTypes,
    showCourseType: showCourseType,
    preselectedLocation: preselectedLocation,
    preselectedCourseType: preselectedCourseType,
    title: 'Termin zum Angebot',
    confirmLabel: 'Termin anlegen',
  );
}

Future<({LocationProfile location, CourseTypeProfile? courseType})?>
    showLocationAndCourseTypeDialog(
  BuildContext context, {
  required List<LocationProfile> locations,
  required List<CourseTypeProfile> courseTypes,
  required bool showCourseType,
  LocationProfile? preselectedLocation,
  CourseTypeProfile? preselectedCourseType,
  required String title,
  required String confirmLabel,
}) async {
  if (locations.isEmpty) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => const AlertDialog(
        title: Text('Fehler'),
        content: Text('Orte nicht konfiguriert.'),
      ),
    );
    return null;
  }

  var location = preselectedLocation ?? locations.first;
  CourseTypeProfile? courseType =
      preselectedCourseType ?? (courseTypes.isNotEmpty ? courseTypes.first : null);

  return showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Ort'),
                  DropdownButton<LocationProfile>(
                    isExpanded: true,
                    value: location,
                    items: locations
                        .map(
                          (l) => DropdownMenuItem(
                            value: l,
                            child: Text(l.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => location = v!),
                  ),
                  if (showCourseType) ...[
                    const SizedBox(height: 12),
                    const Text('Beschäftigungsart'),
                    DropdownButton<CourseTypeProfile>(
                      isExpanded: true,
                      value: courseType,
                      items: courseTypes
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => courseType = v),
                    ),
                  ],
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
                  location: location,
                  courseType: showCourseType ? courseType : null,
                )),
                child: Text(confirmLabel),
              ),
            ],
          );
        },
      );
    },
  );
}
