import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../../app/editor_controller.dart';
import '../../debug/xml_file_diff.dart';
import '../../data/xml/xml_path.dart';
import '../../domain/catalog/catalog_session.dart';
import '../../domain/catalog/course_list_filter.dart';
import '../../domain/catalog/models.dart';
import '../../domain/dates/date_field_rules.dart';
import '../../domain/fields/important_fields.dart';
import '../../domain/fields/template_field_collector.dart';
import '../dialogs/angebot_wizard_dialog.dart';
import '../dialogs/common_dialogs.dart';
import '../dialogs/service_dialogs.dart';
import '../widgets/course_list_filter_bar.dart';
import '../widgets/field_grid.dart';
import '../widgets/grouped_field_form.dart';
import '../widgets/quick_edit_form.dart';

class ServiceEditorPage extends StatefulWidget {
  const ServiceEditorPage({super.key, required this.controller});

  final EditorController controller;

  @override
  State<ServiceEditorPage> createState() => _ServiceEditorPageState();
}

class _ServiceEditorPageState extends State<ServiceEditorPage>
    with SingleTickerProviderStateMixin {
  EditorController get c => widget.controller;
  late final TabController _courseTabs;

  @override
  void initState() {
    super.initState();
    c.addListener(_onChanged);
    _courseTabs = TabController(length: 2, vsync: this);
    _courseTabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _courseTabs.dispose();
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
      if (!mounted) return;
      if (c.lastXsdError != null) {
        _showError(c.lastXsdError!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('XML geladen, XSD-Prüfung erfolgreich.')),
        );
      }
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

  Future<void> _validateKursnet() async {
    if (!c.session.isLoaded) {
      _showError('Bitte zuerst XML öffnen.');
      return;
    }
    try {
      final errors = c.validateKursnetRules();
      if (!mounted) return;
      if (errors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('KURSNET-Regeln erfüllt.')),
        );
      } else {
        _showError(errors.join('\n'));
      }
    } catch (e) {
      _showError('$e');
    }
  }

  Future<void> _uploadKursnet() async {
    if (!c.session.isLoaded) {
      _showError('Bitte zuerst XML öffnen.');
      return;
    }
    final login = await showKursnetUploadDialog(
      context,
      savedUser: c.loadSavedKursnetUser(),
    );
    if (login == null) return;
    if (login.user.isEmpty || login.password.isEmpty) {
      _showError('Benutzer und Passwort sind erforderlich.');
      return;
    }
    try {
      await c.saveKursnetUser(login.user);
      final result = await c.uploadToKursnet(
        user: login.user,
        password: login.password,
        action: login.action,
      );
      if (!mounted) return;
      _showError(result.isEmpty ? 'KURSNET hat keine Rückmeldung geliefert.' : result);
    } catch (e) {
      _showError('$e');
    }
  }

  Future<void> _addVeranstaltung() async {
    if (!c.session.isLoaded) {
      _showError('Bitte zuerst XML öffnen.');
      return;
    }

    XmlElement? source = c.selectedService != null &&
            CatalogSession.isAngebot(c.selectedService!)
        ? c.selectedService
        : null;
    if (source == null) {
      source = await showAngebotPickerDialog(
        context,
        angebote: c.sortedAngebote
            .map((e) => (service: e.service, title: e.title))
            .toList(),
        preselected: c.resolveAngebot(c.selectedService),
      );
      if (source == null) return;
    }
    if (!mounted) return;

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

    final result = await showAddTerminDialog(
      context,
      locations: locations,
      courseTypes: courseTypes,
      showCourseType: !isExtern,
    );
    if (result == null) return;
    if (!mounted) return;
    try {
      c.addVeranstaltung(
        source: source,
        location: result.location,
        courseType: result.courseType,
      );
      _courseTabs.animateTo(0);
    } catch (e) {
      _showError('$e');
    }
  }

  Future<void> _createService() async {
    if (!c.session.isLoaded) {
      _showError('Bitte zuerst XML öffnen.');
      return;
    }
    final result = await showAngebotWizardDialog(
      context,
      existingAngebote: c.session
          .getServiceNodes()
          .where(CatalogSession.isAngebot)
          .toList(),
    );
    if (result == null) return;
    if (!mounted) return;
    try {
      c.createService(
        mainVariant: result.variant,
        values: result.values,
      );
      _courseTabs.animateTo(1);
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
        title: const Text('Hinweis'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(child: Text(message)),
        ),
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
    final fields = ImportantFields.forService(
      isAngebot: CatalogSession.isAngebot(service),
    );
    return fields.map((field) {
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
        tooltip: c.reference.tooltipFor(field.path, value),
        displayValue: DateFieldRules.isDatePath(field.path)
            ? DateFieldRules.formatForUi(value)
            : c.reference.displayFor(field.path, value),
      );
    }).toList();
  }

  List<FieldGridRow> _detailRows(XmlElement service) {
    return TemplateFieldCollector.collectFilledFields(service).map((field) {
      final value = XmlPath.getTextByPath(service, field.path) ?? '';
      final coded = field.path.contains('@')
          ? value
          : (XmlPath.getTextByPath(service, '${field.path}@type') ?? value);
      return FieldGridRow(
        label: field.label,
        path: field.path,
        value: value,
        color: FieldRowColor.normal,
        isDate: DateFieldRules.isDatePath(field.path),
        tooltip: c.reference.tooltipFor(field.path, coded),
        displayValue: DateFieldRules.isDatePath(field.path)
            ? DateFieldRules.formatForUi(value)
            : c.reference.displayFor(field.path, coded),
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

    if (c.reference.isSystematikPath(row.path)) {
      final selected = await showSystematikPickerDialog(
        context,
        reference: c.reference,
        currentId: row.value,
      );
      if (selected == null) return;
      c.setSystematik(service, row.path, selected);
      return;
    }

    final options = c.reference.optionsForPath(row.path);
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
      c.setCodedValue(service, row.path, selected);
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

  Future<void> _compareXmlFiles() async {
    final input = await FilePicker.platform.pickFiles(
      dialogTitle: 'Input-XML wählen',
      type: FileType.custom,
      allowedExtensions: ['xml'],
    );
    if (input == null || input.files.single.path == null) return;
    if (!mounted) return;

    final output = await FilePicker.platform.pickFiles(
      dialogTitle: 'Output-XML wählen',
      type: FileType.custom,
      allowedExtensions: ['xml'],
    );
    if (output == null || output.files.single.path == null) return;

    try {
      final result = XmlFileDiff.compareFiles(
        input.files.single.path!,
        output.files.single.path!,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            result.isIdentical
                ? 'XML identisch'
                : 'XML unterscheidet sich (${result.diffs.length}'
                    '${result.diffs.length >= XmlFileDiff.maxDiffs ? '+' : ''})',
          ),
          content: SizedBox(
            width: 720,
            height: 480,
            child: result.isIdentical
                ? const Text(
                    'Inhaltlich gleich (Formatierung, Kommentare und XML-Header ignoriert).',
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Input: ${result.leftPath}\nOutput: ${result.rightPath}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: SelectableText(result.diffs.join('\n')),
                        ),
                      ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showError('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = c.selectedService;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 400,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  TabBar(
                    controller: _courseTabs,
                    tabs: [
                      Tab(
                        text: _countLabel(
                          'Kurse',
                          c.visibleCourses.length,
                          c.sortedCourses.length,
                        ),
                      ),
                      Tab(
                        text: _countLabel(
                          'Angebote',
                          c.visibleAngebote.length,
                          c.sortedAngebote.length,
                        ),
                      ),
                    ],
                  ),
                  CourseListFilterBar(
                    filter: c.courseFilter,
                    cities: c.filterCities,
                    startDates: c.filterStartDates,
                    onChanged: c.setCourseFilter,
                    onClear: c.clearCourseFilter,
                    includeDateFilters: _courseTabs.index == 0,
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: TabBarView(
                      controller: _courseTabs,
                      children: [
                        _CourseList(
                          items: c.visibleCourses,
                          selected: selected,
                          onSelect: c.selectService,
                          emptyLabel: 'Keine Kurse für diesen Filter',
                        ),
                        _CourseList(
                          items: c.visibleAngebote,
                          selected: selected,
                          onSelect: c.selectService,
                          colorByKind: true,
                          emptyLabel: 'Keine Angebote für diesen Filter',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ActionToolbar(
                  onOpenXml: _openXml,
                  onExportXml: _exportXml,
                  onValidateXml: _validateXml,
                  onValidateKursnet: _validateKursnet,
                  onUploadKursnet: _uploadKursnet,
                  onCreateService: _createService,
                  onAddTermin: _addVeranstaltung,
                  onCopyWith: _copyWith,
                  onDelete: _deleteService,
                  onCompareXml: kDebugMode ? _compareXmlFiles : null,
                ),
                if (c.statusMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    c.statusMessage!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 10),
                if (selected == null)
                  const Expanded(
                    child: Center(
                      child: Text('Service auswählen oder XML öffnen'),
                    ),
                  )
                else ...[
                  const Text(
                    'Schnellbearbeitung',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  QuickEditForm(
                    rows: _quickRows(selected),
                    onEdit: (row) => _editRow(selected, row),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Alle gefüllten Felder',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: GroupedFieldForm(
                        rows: _detailRows(selected),
                        onEdit: (row) => _editRow(selected, row),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        TabBar(
                          tabs: [
                            Tab(
                              text: 'Neu (${c.newServiceTitles.length})',
                            ),
                            Tab(
                              text:
                                  'Update (${c.updatedServiceTitles.length})',
                            ),
                            Tab(
                              text:
                                  'Gelöscht (${c.deletedServiceTitles.length})',
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
          ),
        ],
      ),
    );
  }

  String _countLabel(String label, int visible, int total) =>
      visible == total ? '$label ($visible)' : '$label ($visible/$total)';
}

class _ActionToolbar extends StatelessWidget {
  const _ActionToolbar({
    required this.onOpenXml,
    required this.onExportXml,
    required this.onValidateXml,
    required this.onValidateKursnet,
    required this.onUploadKursnet,
    required this.onCreateService,
    required this.onAddTermin,
    required this.onCopyWith,
    required this.onDelete,
    this.onCompareXml,
  });

  final VoidCallback onOpenXml;
  final VoidCallback onExportXml;
  final VoidCallback onValidateXml;
  final VoidCallback onValidateKursnet;
  final VoidCallback onUploadKursnet;
  final VoidCallback onCreateService;
  final VoidCallback onAddTermin;
  final VoidCallback onCopyWith;
  final VoidCallback onDelete;
  final VoidCallback? onCompareXml;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ActionGroup(
          label: 'Datei',
          color: const Color(0xFF1B4F72),
          children: [
            _groupButton(
              color: const Color(0xFF1B4F72),
              icon: Icons.folder_open,
              label: 'XML öffnen',
              onPressed: onOpenXml,
            ),
            _groupButton(
              color: const Color(0xFF1B4F72),
              icon: Icons.save_alt,
              label: 'Exportieren',
              onPressed: onExportXml,
            ),
          ],
        ),
        _ActionGroup(
          label: 'Prüfung',
          color: const Color(0xFF0E6655),
          children: [
            _groupButton(
              color: const Color(0xFF0E6655),
              icon: Icons.rule,
              label: 'XSD',
              onPressed: onValidateXml,
            ),
            _groupButton(
              color: const Color(0xFF0E6655),
              icon: Icons.fact_check,
              label: 'KURSNET',
              onPressed: onValidateKursnet,
            ),
            _groupButton(
              color: const Color(0xFF0E6655),
              icon: Icons.cloud_upload,
              label: 'Upload',
              onPressed: onUploadKursnet,
            ),
          ],
        ),
        _ActionGroup(
          label: 'Katalog',
          color: const Color(0xFF6C3483),
          children: [
            _groupButton(
              color: const Color(0xFF6C3483),
              icon: Icons.add_box_outlined,
              label: 'Neues Angebot',
              onPressed: onCreateService,
            ),
            _groupButton(
              color: const Color(0xFF6C3483),
              icon: Icons.event_available,
              label: 'Termin zum Angebot',
              onPressed: onAddTermin,
            ),
            _groupButton(
              color: const Color(0xFF6C3483),
              icon: Icons.copy_all,
              label: 'Kopieren mit…',
              onPressed: onCopyWith,
            ),
            _groupButton(
              color: const Color(0xFFB03A2E),
              icon: Icons.delete_outline,
              label: 'Löschen',
              onPressed: onDelete,
            ),
          ],
        ),
        if (onCompareXml != null)
          _ActionGroup(
            label: 'Debug',
            color: const Color(0xFF5D6D7E),
            children: [
              _groupButton(
                color: const Color(0xFF5D6D7E),
                icon: Icons.compare_arrows,
                label: 'XML vergleichen',
                onPressed: onCompareXml!,
              ),
            ],
          ),
      ],
    );
  }

  Widget _groupButton({
    required Color color,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return FilledButton.tonalIcon(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(color.withValues(alpha: 0.12)),
        foregroundColor: WidgetStatePropertyAll(color),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _ActionGroup extends StatelessWidget {
  const _ActionGroup({
    required this.label,
    required this.color,
    required this.children,
  });

  final String label;
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: children,
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseList extends StatelessWidget {
  const _CourseList({
    required this.items,
    required this.selected,
    required this.onSelect,
    this.colorByKind = false,
    this.emptyLabel = 'Keine Einträge für diesen Filter',
  });

  final List<CourseListEntry> items;
  final XmlElement? selected;
  final ValueChanged<XmlElement> onSelect;
  final bool colorByKind;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(emptyLabel, textAlign: TextAlign.center),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = identical(item.service, selected);
        final color = _courseAccentColor(
          item.service,
          byKind: colorByKind,
        );
        return Material(
          color: color.withValues(alpha: isSelected ? 0.16 : 0.05),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onSelect(item.service),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? color : color.withValues(alpha: 0.65),
                  width: isSelected ? 2 : 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Color _courseAccentColor(XmlElement service, {required bool byKind}) {
  if (byKind || CourseListFilter.cityOf(service).isEmpty) {
    return CourseListFilter.educationKindOf(service) ==
            EducationKindFilter.externenpruefung
        ? const Color(0xFF6C3483)
        : const Color(0xFF1E8449);
  }
  final city = CourseListFilter.cityOf(service).toLowerCase();
  if (city.contains('leipzig')) return const Color(0xFFB9770E);
  if (city.contains('kassel')) return const Color(0xFF1B4F72);
  return const Color(0xFF1A5276);
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
