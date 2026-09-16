import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../../app/editor_controller.dart';
import '../../data/xml/xml_path.dart';
import '../../domain/catalog/models.dart';
import '../../domain/dates/date_field_rules.dart';
import '../../domain/fields/important_fields.dart';
import '../../domain/fields/template_field_collector.dart';
import '../dialogs/common_dialogs.dart';
import '../dialogs/service_dialogs.dart';
import '../widgets/field_grid.dart';

class ServiceEditorPage extends StatefulWidget {
  const ServiceEditorPage({super.key, required this.controller});

  final EditorController controller;

  @override
  State<ServiceEditorPage> createState() => _ServiceEditorPageState();
}

class _ServiceEditorPageState extends State<ServiceEditorPage> {
  EditorController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.addListener(_onChanged);
  }

  @override
  void dispose() {
    c.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  Future<void> _openXml() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xml'],
    );
    if (result == null || result.files.single.path == null) return;
    try {
      c.loadXml(result.files.single.path!);
    } catch (e) {
      if (mounted) _showError('$e');
    }
  }

  Future<void> _exportXml() async {
    if (!c.session.isLoaded) {
      _showError('Bitte zuerst XML öffnen.');
      return;
    }
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Exportieren',
      fileName: 'output.xml',
      type: FileType.custom,
      allowedExtensions: ['xml'],
    );
    if (path == null) return;
    try {
      c.exportXml(path.endsWith('.xml') ? path : '$path.xml');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(c.statusMessage ?? 'Exportiert')),
        );
      }
    } catch (e) {
      _showError('$e');
    }
  }

  Future<void> _validateXml() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xml'],
    );
    if (result == null || result.files.single.path == null) return;
    final error = c.validateAgainstSchema(result.files.single.path!);
    if (!mounted) return;
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('XSD-Prüfung erfolgreich.')),
      );
    } else {
      _showError(error);
    }
  }

  Future<void> _createService() async {
    if (!c.session.isLoaded) {
      _showError('Bitte zuerst XML öffnen.');
      return;
    }
    final locations = c.profiles.loadLocations();
    final courseTypes = c.profiles
        .loadCourseTypes()
        .where((t) => !t.name.toLowerCase().contains('extern'))
        .toList();
    final result = await showCreateServiceDialog(
      context,
      locations: locations,
      courseTypes: courseTypes,
    );
    if (result == null) return;
    try {
      c.createService(
        location: result.location,
        mainVariant: result.variant,
        courseType: result.courseType,
      );
    } catch (e) {
      _showError('$e');
    }
  }

  Future<void> _copyWith() async {
    final source = c.selectedService;
    if (!c.session.isLoaded) {
      _showError('Bitte zuerst XML öffnen.');
      return;
    }
    if (source == null) {
      _showError('Bitte Service auswählen, der kopiert werden soll.');
      return;
    }

    final locations = c.profiles.loadLocations();
    final courseTypes = c.profiles
        .loadCourseTypes()
        .where((t) => !t.name.toLowerCase().contains('extern'))
        .toList();

    final educationType = XmlPath.getTextByPath(
          source,
          'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/EDUCATION_TYPE',
        ) ??
        '';
    final isExtern = educationType.toLowerCase().contains('nachholen') ||
        educationType.toLowerCase().contains('extern');

    final city = XmlPath.getTextByPath(
      source,
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/MODULE_COURSE/LOCATION/CITY',
    );
    final instruction = XmlPath.getTextByPath(
      source,
      'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_TIME',
    );

    LocationProfile? preLoc;
    for (final l in locations) {
      if (l.name.toLowerCase() == city?.toLowerCase() ||
          l.values['CITY']?.toLowerCase() == city?.toLowerCase()) {
        preLoc = l;
        break;
      }
    }
    CourseTypeProfile? preType;
    for (final t in courseTypes) {
      if (t.name.toLowerCase() == instruction?.toLowerCase() ||
          t.values['INSTRUCTION_TIME']?.toLowerCase() ==
              instruction?.toLowerCase()) {
        preType = t;
        break;
      }
    }

    final result = await showCopyWithDialog(
      context,
      locations: locations,
      courseTypes: courseTypes,
      showCourseType: !isExtern,
      preselectedLocation: preLoc,
      preselectedCourseType: preType,
    );
    if (result == null) return;
    try {
      c.copyWith(
        source: source,
        location: result.location,
        courseType: result.courseType,
      );
    } catch (e) {
      _showError('$e');
    }
  }

  Future<void> _deleteService() async {
    if (c.selectedService == null) {
      _showError('Bitte Service auswählen.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Service löschen'),
        content: Text(
          "Service mit PRODUCT_ID '${XmlPath.getChildText(c.selectedService!, 'PRODUCT_ID')}' löschen?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nein'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ja'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      c.deleteSelected();
    } catch (e) {
      _showError('$e');
    }
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fehler'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  List<FieldGridRow> _quickRows(XmlElement service) {
    return ImportantFields.list.map((field) {
      final value = XmlPath.getTextByPath(service, field.path) ?? '';
      FieldRowColor color = FieldRowColor.normal;
      final pending = c.session.pendingTemplateFields[service];
      final changed = c.session.changedImportantFields[service];
      if (pending != null && pending.contains(field.path)) {
        color = FieldRowColor.pending;
      } else if (changed != null && changed.contains(field.path)) {
        color = FieldRowColor.changed;
      }
      return FieldGridRow(
        label: field.label,
        path: field.path,
        value: value,
        color: color,
        isDate: DateFieldRules.isDatePath(field.path),
      );
    }).toList();
  }

  List<FieldGridRow> _detailRows(XmlElement service) {
    return TemplateFieldCollector.collectFilledFields(service).map((field) {
      final value = XmlPath.getTextByPath(service, field.path) ?? '';
      return FieldGridRow(
        label: field.label,
        path: field.path,
        value: value,
        color: FieldRowColor.normal,
        isDate: DateFieldRules.isDatePath(field.path),
      );
    }).toList();
  }

  Future<void> _editRow(XmlElement service, FieldGridRow row) async {
    if (row.isDate) {
      final initial =
          DateFieldRules.tryParse(row.value) ?? DateTime.now();
      final picked = await showDateTimePickerDialog(
        context,
        initial: initial,
        includeTime: DateFieldRules.isCourseDatePath(row.path),
      );
      if (picked == null) return;
      final formatted = DateFieldRules.format(
        picked,
        includeTime: DateFieldRules.isCourseDatePath(row.path),
      );
      c.setFieldValue(service, row.path, formatted);
      return;
    }

    final edited = await showTextEditorDialog(
      context,
      title: row.label,
      initialValue: row.value,
    );
    if (edited == null) return;
    c.setFieldValue(service, row.path, edited);
  }

  @override
  Widget build(BuildContext context) {
    final courses = c.sortedCourses;
    final selected = c.selectedService;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _openXml,
                icon: const Icon(Icons.folder_open),
                label: const Text('XML öffnen'),
              ),
              FilledButton.tonalIcon(
                onPressed: _exportXml,
                icon: const Icon(Icons.save_alt),
                label: const Text('Exportieren'),
              ),
              OutlinedButton.icon(
                onPressed: _validateXml,
                icon: const Icon(Icons.rule),
                label: const Text('Gegen XSD prüfen'),
              ),
              OutlinedButton(
                onPressed: _createService,
                child: const Text('Neuer Service'),
              ),
              OutlinedButton(
                onPressed: _copyWith,
                child: const Text('Kopieren mit…'),
              ),
              OutlinedButton(
                onPressed: _deleteService,
                child: const Text('Service Löschen'),
              ),
            ],
          ),
          if (c.statusMessage != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                c.statusMessage!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 380,
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListView.builder(
                      itemCount: courses.length,
                      itemBuilder: (context, index) {
                        final item = courses[index];
                        final isSelected =
                            identical(item.service, selected);
                        return ListTile(
                          selected: isSelected,
                          dense: true,
                          title: Text(
                            item.title,
                            style: const TextStyle(fontSize: 12),
                          ),
                          onTap: () => c.selectService(item.service),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: selected == null
                      ? const Center(
                          child: Text('Service auswählen oder XML öffnen'),
                        )
                      : Column(
                          children: [
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Schnellbearbeitung',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 220,
                              child: Card(
                                clipBehavior: Clip.antiAlias,
                                child: FieldGrid(
                                  rows: _quickRows(selected),
                                  onEdit: (row, _) =>
                                      _editRow(selected, row),
                                  onDateTap: (row) =>
                                      _editRow(selected, row),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Alle gefüllten Felder',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: Card(
                                clipBehavior: Clip.antiAlias,
                                child: FieldGrid(
                                  rows: _detailRows(selected),
                                  onEdit: (row, _) =>
                                      _editRow(selected, row),
                                  onDateTap: (row) =>
                                      _editRow(selected, row),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 140,
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(
                        text:
                            'Neu hinzugefügt (${c.newServiceTitles.length})',
                      ),
                      Tab(
                        text:
                            'Geändert / Update (${c.updatedServiceTitles.length})',
                      ),
                      Tab(
                        text: 'Gelöscht (${c.deletedServiceTitles.length})',
                      ),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _StatusList(items: c.newServiceTitles),
                        _StatusList(items: c.updatedServiceTitles),
                        _StatusList(items: c.deletedServiceTitles),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusList extends StatelessWidget {
  const _StatusList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('—'));
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (_, i) => ListTile(
        dense: true,
        title: Text(items[i], style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
