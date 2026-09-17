import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../../app/editor_controller.dart';
import '../../data/reference/openq_reference.dart';
import '../../data/templates/service_template_repository.dart';
import '../../data/xml/xml_path.dart';
import '../../domain/catalog/models.dart';
import '../../domain/fields/template_field_collector.dart';
import '../../domain/fields/template_field_definitions.dart';
import '../../domain/templates/main_template_variants.dart';
import '../dialogs/common_dialogs.dart';
import '../widgets/field_grid.dart';

class TemplateEditorPage extends StatefulWidget {
  const TemplateEditorPage({super.key, required this.controller});

  final EditorController controller;

  @override
  State<TemplateEditorPage> createState() => _TemplateEditorPageState();
}

class _TemplateEditorPageState extends State<TemplateEditorPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Main Template'),
            Tab(text: 'Beschäftigungsart'),
            Tab(text: 'Ort'),
            Tab(text: 'Header'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _MainTemplateTab(controller: widget.controller),
              _CourseTypeTab(controller: widget.controller),
              _LocationTab(controller: widget.controller),
              _HeaderTab(controller: widget.controller),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> _editTemplateField(
  BuildContext context, {
  required XmlElement service,
  required FieldGridRow row,
  required OpenqReference reference,
}) async {
  if (reference.isSystematikPath(row.path)) {
    final selected = await showSystematikPickerDialog(
      context,
      reference: reference,
      currentId: row.value,
    );
    if (selected == null) return;
    XmlPath.setNodeByPath(service, row.path, selected.id);
    final valuePath = row.path.replaceFirst(
      RegExp(r'FNAME$', caseSensitive: false),
      'FVALUE',
    );
    XmlPath.setNodeByPath(service, valuePath, selected.label);
    return;
  }

  final options = reference.optionsForPath(row.path);
  if (options != null && options.isNotEmpty) {
    final selected = await showCodedPickerDialog(
      context,
      title: row.label,
      options: options,
      currentId: XmlPath.getTextByPath(
            service,
            row.path.contains('@') ? row.path : '${row.path}@type',
          ) ??
          row.value,
    );
    if (selected == null) return;
    _applyCodedValue(service, row.path, selected);
    return;
  }

  final edited = await showTextEditorDialog(
    context,
    title: row.label,
    initialValue: row.value,
  );
  if (edited == null) return;
  XmlPath.setNodeByPath(service, row.path, edited);
}

void _applyCodedValue(XmlElement service, String path, CodedValue value) {
  final elementPath = path.contains('@')
      ? path.split('@').first.replaceAll(RegExp(r'/+$'), '')
      : path;
  final upper = elementPath.toUpperCase();
  if (upper.endsWith('CERTIFICATE_STATUS') ||
      upper.endsWith('CERTIFIER_NUMBER') ||
      upper.endsWith('COUNTRY')) {
    XmlPath.setNodeByPath(service, elementPath, value.id);
  } else {
    XmlPath.setNodeByPath(service, '$elementPath@type', value.id);
    if (!upper.endsWith('DURATION')) {
      final node = XmlPath.getNodeByPath(service, elementPath);
      if (node == null || !XmlPath.hasElementChildren(node)) {
        XmlPath.setNodeByPath(service, elementPath, value.label);
      }
    }
  }
}

class _MainTemplateTab extends StatefulWidget {
  const _MainTemplateTab({required this.controller});
  final EditorController controller;

  @override
  State<_MainTemplateTab> createState() => _MainTemplateTabState();
}

class _MainTemplateTabState extends State<_MainTemplateTab> {
  String _variant = MainTemplateVariants.standard;
  TemplateDocumentSession? _session;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _session = widget.controller.templates.loadMainTemplateSession(_variant);
    setState(() {});
  }

  Future<void> _edit(FieldGridRow row) async {
    final session = _session;
    if (session == null) return;
    await _editTemplateField(
      context,
      service: session.service,
      row: row,
      reference: widget.controller.reference,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final rows = session == null
        ? <FieldGridRow>[]
        : TemplateFieldCollector.collectFromService(session.service)
            .map((f) => _typedRow(widget.controller.reference, session.service, f))
            .toList();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Main-Template-Typ:'),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _variant,
                items: MainTemplateVariants.all
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) {
                  _variant = v!;
                  _reload();
                },
              ),
              const Spacer(),
              FilledButton(
                onPressed: session == null
                    ? null
                    : () {
                        session.save();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Main Template gespeichert'),
                          ),
                        );
                      },
                child: const Text('Main Template speichern'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: FieldGrid(rows: rows, onEdit: (row, _) => _edit(row)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseTypeTab extends StatefulWidget {
  const _CourseTypeTab({required this.controller});
  final EditorController controller;

  @override
  State<_CourseTypeTab> createState() => _CourseTypeTabState();
}

class _CourseTypeTabState extends State<_CourseTypeTab> {
  String? _selected;
  TemplateDocumentSession? _session;

  @override
  void initState() {
    super.initState();
    final names = widget.controller.templates.getDistinctCourseTypeNames();
    if (names.isNotEmpty) {
      _selected = names.first;
      _session =
          widget.controller.templates.findTemplateByFileNameContains(_selected!);
    }
  }

  Future<void> _edit(FieldGridRow row) async {
    final session = _session;
    if (session == null) return;
    await _editTemplateField(
      context,
      service: session.service,
      row: row,
      reference: widget.controller.reference,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final names = widget.controller.templates.getDistinctCourseTypeNames();
    final session = _session;
    final rows = session == null
        ? <FieldGridRow>[]
        : CourseTypeTemplateFields.essentialFields
            .map((f) => _typedRow(widget.controller.reference, session.service, f))
            .toList();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              DropdownButton<String>(
                value: _selected,
                hint: const Text('Beschäftigungsart'),
                items: names
                    .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selected = v;
                    _session = widget.controller.templates
                        .findTemplateByFileNameContains(v!);
                  });
                },
              ),
              const Spacer(),
              FilledButton(
                onPressed: session == null
                    ? null
                    : () {
                        session.save();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gespeichert')),
                        );
                      },
                child: const Text('Speichern'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: FieldGrid(rows: rows, onEdit: (row, _) => _edit(row)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationTab extends StatefulWidget {
  const _LocationTab({required this.controller});
  final EditorController controller;

  @override
  State<_LocationTab> createState() => _LocationTabState();
}

class _LocationTabState extends State<_LocationTab> {
  String? _selected;
  TemplateDocumentSession? _session;

  @override
  void initState() {
    super.initState();
    final names = widget.controller.templates.getDistinctLocationNames();
    if (names.isNotEmpty) {
      _selected = names.first;
      _session = widget.controller.templates.findTemplateByCity(_selected!);
    }
  }

  Future<void> _edit(FieldGridRow row) async {
    final session = _session;
    if (session == null) return;
    await _editTemplateField(
      context,
      service: session.service,
      row: row,
      reference: widget.controller.reference,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final names = widget.controller.templates.getDistinctLocationNames();
    final session = _session;
    final rows = session == null
        ? <FieldGridRow>[]
        : LocationTemplateFields.essentialFields
            .map((f) => _typedRow(widget.controller.reference, session.service, f))
            .toList();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              DropdownButton<String>(
                value: _selected,
                hint: const Text('Ort'),
                items: names
                    .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selected = v;
                    _session =
                        widget.controller.templates.findTemplateByCity(v!);
                  });
                },
              ),
              const Spacer(),
              FilledButton(
                onPressed: session == null
                    ? null
                    : () {
                        session.save();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gespeichert')),
                        );
                      },
                child: const Text('Speichern'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: FieldGrid(rows: rows, onEdit: (row, _) => _edit(row)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderTab extends StatefulWidget {
  const _HeaderTab({required this.controller});
  final EditorController controller;

  @override
  State<_HeaderTab> createState() => _HeaderTabState();
}

class _HeaderTabState extends State<_HeaderTab> {
  TemplateDocumentSession? _session;

  @override
  void initState() {
    super.initState();
    _session = widget.controller.templates.loadMainTemplateSession();
  }

  Future<void> _edit(FieldGridRow row) async {
    final session = _session;
    if (session == null) return;
    await _editTemplateField(
      context,
      service: session.service,
      row: row,
      reference: widget.controller.reference,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final rows = session == null
        ? <FieldGridRow>[]
        : HeaderTemplateFields.essentialFields
            .map((f) => _typedRow(widget.controller.reference, session.service, f))
            .toList();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: session == null
                  ? null
                  : () {
                      session.save();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Header / Main gespeichert'),
                        ),
                      );
                    },
              child: const Text('Header speichern'),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: FieldGrid(rows: rows, onEdit: (row, _) => _edit(row)),
            ),
          ),
        ],
      ),
    );
  }
}

FieldGridRow _typedRow(
  OpenqReference reference,
  XmlElement service,
  TemplateFieldDefinition field,
) {
  final value = XmlPath.getTextByPath(service, field.path) ?? '';
  final coded = _codedRaw(service, field.path, value);
  return FieldGridRow(
    label: field.label,
    path: field.path,
    value: value,
    color: FieldRowColor.normal,
    tooltip: reference.tooltipFor(field.path, coded),
    displayValue: reference.displayFor(field.path, coded),
  );
}

String _codedRaw(XmlElement service, String path, String value) {
  if (path.contains('@')) return value;
  final typeAttr = XmlPath.getTextByPath(service, '$path@type');
  if (typeAttr != null && typeAttr.trim().isNotEmpty) return typeAttr;
  return value;
}
