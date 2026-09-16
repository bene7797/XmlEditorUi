import 'package:flutter/material.dart';

import '../../domain/catalog/models.dart';
import '../../domain/templates/main_template_variants.dart';

Future<({LocationProfile location, String variant, CourseTypeProfile? courseType})?>
    showCreateServiceDialog(
  BuildContext context, {
  required List<LocationProfile> locations,
  required List<CourseTypeProfile> courseTypes,
}) async {
  if (locations.isEmpty || courseTypes.isEmpty) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => const AlertDialog(
        title: Text('Fehler'),
        content: Text('Orte oder Beschäftigungsarten nicht konfiguriert.'),
      ),
    );
    return null;
  }

  var location = locations.first;
  var variant = MainTemplateVariants.standard;
  CourseTypeProfile? courseType = courseTypes.first;

  return showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          final isExtern = MainTemplateVariants.isExternenpruefung(variant);
          return AlertDialog(
            title: const Text('Service erstellen'),
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
                  const SizedBox(height: 12),
                  const Text('Main-Template'),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: variant,
                    items: MainTemplateVariants.all
                        .map(
                          (v) => DropdownMenuItem(value: v, child: Text(v)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => variant = v!),
                  ),
                  if (!isExtern) ...[
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
                  variant: variant,
                  courseType: isExtern ? null : courseType,
                )),
                child: const Text('Erstellen'),
              ),
            ],
          );
        },
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
            title: const Text('Kopieren mit…'),
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
                child: const Text('Kopieren'),
              ),
            ],
          );
        },
      );
    },
  );
}
