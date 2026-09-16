import 'package:flutter/material.dart';

import '../../app/editor_controller.dart';
import '../../data/templates/service_template_repository.dart';
import '../../data/xml/xml_path.dart';
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
              _MainTemplateTab(repo: widget.controller.templates),
              _CourseTypeTab(repo: widget.controller.templates),
              _LocationTab(repo: widget.controller.templates),
              _HeaderTab(repo: widget.controller.templates),
            ],
          ),
        ),
      ],
    );
  }
}

class _MainTemplateTab extends StatefulWidget {
  const _MainTemplateTab({required this.repo});
  final ServiceTemplateRepository repo;

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
    _session = widget.repo.loadMainTemplateSession(_variant);
    setState(() {});
  }

  Future<void> _edit(FieldGridRow row) async {
    final session = _session;
    if (session == null) return;
    final edited = await showTextEditorDialog(
      context,
      title: row.label,
      initialValue: row.value,
    );
    if (edited == null) return;
    XmlPath.setNodeByPath(session.service, row.path, edited);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final rows = session == null
        ? <FieldGridRow>[]
        : TemplateFieldCollector.collectFromService(session.service)
            .map(
              (f) => FieldGridRow(
                label: f.label,
                path: f.path,
                value: XmlPath.getTextByPath(session.service, f.path) ?? '',
                color: FieldRowColor.normal,
              ),
            )
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
  const _CourseTypeTab({required this.repo});
  final ServiceTemplateRepository repo;

  @override
  State<_CourseTypeTab> createState() => _CourseTypeTabState();
}

class _CourseTypeTabState extends State<_CourseTypeTab> {
  String? _selected;
  TemplateDocumentSession? _session;

  @override
  void initState() {
    super.initState();
    final names = widget.repo.getDistinctCourseTypeNames();
    if (names.isNotEmpty) {
      _selected = names.first;
      _session = widget.repo.findTemplateByFileNameContains(_selected!);
    }
  }

  Future<void> _edit(FieldGridRow row) async {
    final session = _session;
    if (session == null) return;
    final edited = await showTextEditorDialog(
      context,
      title: row.label,
      initialValue: row.value,
    );
    if (edited == null) return;
    XmlPath.setNodeByPath(session.service, row.path, edited);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final names = widget.repo.getDistinctCourseTypeNames();
    final session = _session;
    final rows = session == null
        ? <FieldGridRow>[]
        : CourseTypeTemplateFields.essentialFields
            .map(
              (f) => FieldGridRow(
                label: f.label,
                path: f.path,
                value: XmlPath.getTextByPath(session.service, f.path) ?? '',
                color: FieldRowColor.normal,
              ),
            )
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
                    _session =
                        widget.repo.findTemplateByFileNameContains(v!);
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
  const _LocationTab({required this.repo});
  final ServiceTemplateRepository repo;

  @override
  State<_LocationTab> createState() => _LocationTabState();
}

class _LocationTabState extends State<_LocationTab> {
  String? _selected;
  TemplateDocumentSession? _session;

  @override
  void initState() {
    super.initState();
    final names = widget.repo.getDistinctLocationNames();
    if (names.isNotEmpty) {
      _selected = names.first;
      _session = widget.repo.findTemplateByCity(_selected!);
    }
  }

  Future<void> _edit(FieldGridRow row) async {
    final session = _session;
    if (session == null) return;
    final edited = await showTextEditorDialog(
      context,
      title: row.label,
      initialValue: row.value,
    );
    if (edited == null) return;
    XmlPath.setNodeByPath(session.service, row.path, edited);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final names = widget.repo.getDistinctLocationNames();
    final session = _session;
    final rows = session == null
        ? <FieldGridRow>[]
        : LocationTemplateFields.essentialFields
            .map(
              (f) => FieldGridRow(
                label: f.label,
                path: f.path,
                value: XmlPath.getTextByPath(session.service, f.path) ?? '',
                color: FieldRowColor.normal,
              ),
            )
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
                    _session = widget.repo.findTemplateByCity(v!);
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
  const _HeaderTab({required this.repo});
  final ServiceTemplateRepository repo;

  @override
  State<_HeaderTab> createState() => _HeaderTabState();
}

class _HeaderTabState extends State<_HeaderTab> {
  TemplateDocumentSession? _session;

  @override
  void initState() {
    super.initState();
    _session = widget.repo.loadMainTemplateSession();
  }

  Future<void> _edit(FieldGridRow row) async {
    final session = _session;
    if (session == null) return;
    final edited = await showTextEditorDialog(
      context,
      title: row.label,
      initialValue: row.value,
    );
    if (edited == null) return;
    XmlPath.setNodeByPath(session.service, row.path, edited);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final rows = session == null
        ? <FieldGridRow>[]
        : HeaderTemplateFields.essentialFields
            .map(
              (f) => FieldGridRow(
                label: f.label,
                path: f.path,
                value: XmlPath.getTextByPath(session.service, f.path) ?? '',
                color: FieldRowColor.normal,
              ),
            )
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
