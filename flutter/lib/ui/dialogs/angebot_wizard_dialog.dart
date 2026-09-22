import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../../domain/fields/angebot_wizard_fields.dart';
import '../../domain/templates/main_template_variants.dart';

Future<({String variant, Map<String, String> values})?>
    showAngebotWizardDialog(
  BuildContext context, {
  required List<XmlElement> existingAngebote,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _AngebotWizardDialog(existingAngebote: existingAngebote),
  );
}

class _AngebotWizardDialog extends StatefulWidget {
  const _AngebotWizardDialog({required this.existingAngebote});

  final List<XmlElement> existingAngebote;

  @override
  State<_AngebotWizardDialog> createState() => _AngebotWizardDialogState();
}

class _AngebotWizardDialogState extends State<_AngebotWizardDialog> {
  static const _artPage = 0;

  var _page = 0;
  var _variant = MainTemplateVariants.standard;
  final _values = <String, String>{};
  final _controller = TextEditingController();
  late final AngebotSuggestionIndex _suggestions;

  int get _lastPage => AngebotWizardFields.pages.length;
  bool get _isArtPage => _page == _artPage;
  AngebotWizardField get _field => AngebotWizardFields.pages[_page - 1];

  @override
  void initState() {
    super.initState();
    _suggestions = AngebotSuggestionIndex(widget.existingAngebote);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _persistField() {
    if (_isArtPage) return;
    _values[_field.path] = _controller.text;
  }

  void _showPage(int page) {
    _persistField();
    setState(() {
      _page = page;
      if (!_isArtPage) {
        _controller.text = _values[_field.path] ?? '';
        _controller.selection = TextSelection.collapsed(
          offset: _controller.text.length,
        );
      }
    });
  }

  void _finish() {
    _persistField();
    Navigator.pop(context, (
      variant: _variant,
      values: Map<String, String>.from(_values),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(_isArtPage ? 'Neues Angebot' : _field.label),
      content: SizedBox(
        width: 640,
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: (_page + 1) / (_lastPage + 1),
            ),
            const SizedBox(height: 8),
            Text(
              'Schritt ${_page + 1} von ${_lastPage + 1}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isArtPage ? _artBody(theme) : _fieldBody(theme),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        if (_page > 0)
          TextButton(
            onPressed: () => _showPage(_page - 1),
            child: const Text('Zurück'),
          ),
        if (_page < _lastPage)
          FilledButton(
            onPressed: () => _showPage(_page + 1),
            child: const Text('Weiter'),
          )
        else
          FilledButton(
            onPressed: _finish,
            child: const Text('Angebot anlegen'),
          ),
      ],
    );
  }

  Widget _artBody(ThemeData theme) {
    return ListView(
      children: [
        Text(
          'Zuerst die Art des Stamms. Ort und Starttermin kommen erst '
          'später beim Anlegen eines Termins.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        ...MainTemplateVariants.all.map((variant) {
          final selected = variant == _variant;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: selected
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                selected: selected,
                title: Text(variant),
                subtitle: Text(
                  variant == MainTemplateVariants.externenpruefung
                      ? 'Vorbereitung auf die Externenprüfung'
                      : 'Umschulung als Bildungsangebot',
                ),
                leading: Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                ),
                onTap: () => setState(() => _variant = variant),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _fieldBody(ThemeData theme) {
    final suggestions = _suggestions.forPath(_field.path);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_field.hint, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          maxLines: _field.maxLines,
          decoration: InputDecoration(
            labelText: _field.label,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Vorschläge aus vorhandenen Angeboten',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: suggestions.isEmpty
              ? Center(
                  child: Text(
                    'Noch keine anderen Angebote mit diesem Feld.',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  itemCount: suggestions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = suggestions[index];
                    final selected = _controller.text == item.value;
                    return Material(
                      color: selected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() {
                          _controller.text = item.value;
                          _controller.selection = TextSelection.collapsed(
                            offset: item.value.length,
                          );
                        }),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.sources.join(' · '),
                                style: theme.textTheme.labelMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.value,
                                maxLines: 6,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  selected ? 'Übernommen' : 'Übernehmen',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
