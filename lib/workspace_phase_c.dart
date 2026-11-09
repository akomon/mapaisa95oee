import 'package:flutter/material.dart';

import 'workspace_model.dart';
import 'workspace_theme.dart';

const Key workspaceTemplateKey = Key('workspaceTemplate');
const Key templatePickerKey = Key('templatePicker');
const Key cancelTemplateKey = Key('cancelTemplate');
const Key applyTemplateKey = Key('applyTemplate');
const Key workspaceSuggestKey = Key('workspaceSuggest');
const Key workspaceNewSchemaKey = Key('workspaceNewSchema');
const Key workspaceSchemaNameKey = Key('workspaceSchemaName');
const Key createSchemaKey = Key('createSchema');
const Key cancelSchemaKey = Key('cancelSchema');
const Key workspaceCopySchemaKey = Key('workspaceCopySchema');
const Key workspaceSchemaPickerKey = Key('workspaceSchemaPicker');
const Key workspaceLayoutXKey = Key('workspaceLayoutX');
const Key workspaceLayoutYKey = Key('workspaceLayoutY');
const Key workspaceSaveLayoutKey = Key('workspaceSaveLayout');
const Key workspaceSnapshotKey = Key('workspaceSnapshot');
const Key workspaceSnapshotNoteKey = Key('workspaceSnapshotNote');
const Key createSnapshotKey = Key('createSnapshot');
const Key cancelSnapshotKey = Key('cancelSnapshot');
const Key workspaceVersionsKey = Key('workspaceVersions');
const Key workspaceRestoreNoteKey = Key('workspaceRestoreNote');
const Key confirmRestoreKey = Key('confirmRestore');
const Key cancelRestoreKey = Key('cancelRestore');
const Key workspaceExportKey = Key('workspaceExport');
const Key workspaceImportKey = Key('workspaceImport');
const Key workspaceImportFieldKey = Key('workspaceImportField');
const Key prepareWorkspaceImportKey = Key('prepareWorkspaceImport');
const Key cancelWorkspaceImportKey = Key('cancelWorkspaceImport');
const Key confirmWorkspaceReplaceKey = Key('confirmWorkspaceReplace');
const Key cancelWorkspaceReplaceKey = Key('cancelWorkspaceReplace');
const Key downloadWorkspacePriorKey = Key('downloadWorkspacePrior');
const Key suggestionNameKey = Key('suggestionName');
const Key suggestionDataKey = Key('suggestionData');
const Key suggestionPurposeKey = Key('suggestionPurpose');
const Key confirmSuggestionDialogKey = Key('confirmSuggestionDialog');
const Key cancelSuggestionDialogKey = Key('cancelSuggestionDialog');

class ConfirmedSuggestion {
  const ConfirmedSuggestion({
    required this.name,
    required this.exchangedData,
    required this.protocol,
    required this.purpose,
  });

  final String name;
  final String exchangedData;
  final String? protocol;
  final String purpose;
}

class SchemaDraft {
  const SchemaDraft({required this.name, required this.plantIds});

  final String name;
  final List<String> plantIds;
}

class _DialogFrame extends StatelessWidget {
  const _DialogFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(data: workspaceTheme(), child: child);
  }
}

class TemplatePreviewDialog extends StatefulWidget {
  const TemplatePreviewDialog({super.key, required this.lineName});

  final String lineName;

  @override
  State<TemplatePreviewDialog> createState() => _TemplatePreviewDialogState();
}

class _TemplatePreviewDialogState extends State<TemplatePreviewDialog> {
  late String _templateId = machineTemplates.first.id;
  final _cancelFocus = FocusNode();

  @override
  void dispose() {
    _cancelFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final template = findMachineTemplate(_templateId)!;
    return _DialogFrame(
      child: AlertDialog(
        title: const Text('Plantilla'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Línia: ${widget.lineName}'),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  key: templatePickerKey,
                  isExpanded: true,
                  value: _templateId,
                  items: [
                    for (final item in machineTemplates)
                      DropdownMenuItem(value: item.id, child: Text(item.name)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _templateId = value);
                    }
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'Màquines i icones que es crearan. Encara no s\'ha escrit res.',
                ),
                for (final machine in template.machines)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(iconFor(machine.iconKey)),
                    title: Text(machine.name),
                    subtitle: Text('Icona: ${iconKeyLabel(machine.iconKey)}'),
                  ),
                const Text(
                  'Les màquines hereten només la pertinença a la línia. No s\'assignen funcions ni fluxos.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            key: cancelTemplateKey,
            focusNode: _cancelFocus,
            style: workspaceControlStyle,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel·la'),
          ),
          TextButton(
            key: applyTemplateKey,
            style: workspaceControlStyle,
            onPressed: () => Navigator.of(context).pop(_templateId),
            child: const Text('Aplica plantilla'),
          ),
        ],
      ),
    );
  }
}

class SuggestionConfirmDialog extends StatefulWidget {
  const SuggestionConfirmDialog({
    super.key,
    required this.sourceLabel,
    required this.targetLabel,
  });

  final String sourceLabel;
  final String targetLabel;

  @override
  State<SuggestionConfirmDialog> createState() =>
      _SuggestionConfirmDialogState();
}

class _SuggestionConfirmDialogState extends State<SuggestionConfirmDialog> {
  late final TextEditingController _name = TextEditingController(
    text: 'Suggeriment: ${widget.sourceLabel} → ${widget.targetLabel}',
  );
  final _data = TextEditingController();
  final _purpose = TextEditingController();
  final _protocol = TextEditingController();
  final _cancelFocus = FocusNode();
  var _unknownProtocol = true;
  Map<String, String> _errors = {};

  @override
  void dispose() {
    _name.dispose();
    _data.dispose();
    _purpose.dispose();
    _protocol.dispose();
    _cancelFocus.dispose();
    super.dispose();
  }

  void _submit() {
    final errors = <String, String>{};
    if (_name.text.trim().isEmpty) {
      errors['name'] = 'El nom no pot ser buit.';
    }
    if (_data.text.trim().isEmpty) {
      errors['exchangedData'] = 'El camp no és vàlid.';
    }
    if (_purpose.text.trim().isEmpty) {
      errors['purpose'] = 'El camp no és vàlid.';
    }
    if (!_unknownProtocol && _protocol.text.trim().isEmpty) {
      errors['protocol'] = 'El camp no és vàlid.';
    }
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }
    Navigator.of(context).pop(
      ConfirmedSuggestion(
        name: _name.text.trim(),
        exchangedData: _data.text.trim(),
        protocol: _unknownProtocol ? null : _protocol.text.trim(),
        purpose: _purpose.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _DialogFrame(
      child: AlertDialog(
        title: const Text('Confirma el suggeriment'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggeriment: ${widget.sourceLabel} → ${widget.targetLabel}. Aquest diàleg només confirma aquesta parella.',
                ),
                TextField(
                  key: suggestionNameKey,
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                if (_errors['name'] != null) Text('Error: ${_errors['name']}'),
                TextField(
                  key: suggestionDataKey,
                  controller: _data,
                  decoration: const InputDecoration(
                    labelText: 'Dades intercanviades',
                  ),
                ),
                if (_errors['exchangedData'] != null)
                  Text('Error: ${_errors['exchangedData']}'),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Protocol desconegut'),
                  value: _unknownProtocol,
                  onChanged: (checked) =>
                      setState(() => _unknownProtocol = checked ?? false),
                ),
                if (!_unknownProtocol)
                  TextField(
                    controller: _protocol,
                    decoration: const InputDecoration(labelText: 'Protocol'),
                  ),
                TextField(
                  key: suggestionPurposeKey,
                  controller: _purpose,
                  decoration: const InputDecoration(labelText: 'Finalitat'),
                ),
                if (_errors['purpose'] != null)
                  Text('Error: ${_errors['purpose']}'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            key: cancelSuggestionDialogKey,
            focusNode: _cancelFocus,
            style: workspaceControlStyle,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel·la'),
          ),
          TextButton(
            key: confirmSuggestionDialogKey,
            style: workspaceControlStyle,
            onPressed: _submit,
            child: const Text('Confirma aquest flux'),
          ),
        ],
      ),
    );
  }
}

class SchemaDraftDialog extends StatefulWidget {
  const SchemaDraftDialog({
    super.key,
    required this.plants,
    this.initialName = '',
    this.title = 'Nou esquema',
    this.confirmLabel = 'Desa l\'esquema',
  });

  final List<Asset> plants;
  final String initialName;
  final String title;
  final String confirmLabel;

  @override
  State<SchemaDraftDialog> createState() => _SchemaDraftDialogState();
}

class _SchemaDraftDialogState extends State<SchemaDraftDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initialName,
  );
  final _plants = <String>{};
  final _cancelFocus = FocusNode();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _cancelFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DialogFrame(
      child: AlertDialog(
        title: Text(widget.title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  key: workspaceSchemaNameKey,
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                if (_error != null) Text('Error: $_error'),
                const SizedBox(height: 8),
                const Text('Plantes incloses'),
                for (final plant in widget.plants)
                  CheckboxListTile(
                    key: Key('schema-plant-${plant.id}'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(plant.name),
                    value: _plants.contains(plant.id),
                    onChanged: (checked) => setState(() {
                      if (checked ?? false) {
                        _plants.add(plant.id);
                      } else {
                        _plants.remove(plant.id);
                      }
                    }),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            key: cancelSchemaKey,
            focusNode: _cancelFocus,
            style: workspaceControlStyle,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel·la'),
          ),
          TextButton(
            key: createSchemaKey,
            style: workspaceControlStyle,
            onPressed: () {
              if (_name.text.trim().isEmpty) {
                setState(() => _error = 'El nom no pot ser buit.');
                return;
              }
              Navigator.of(context).pop(
                SchemaDraft(
                  name: _name.text.trim(),
                  plantIds: _plants.toList(),
                ),
              );
            },
            child: Text(widget.confirmLabel),
          ),
        ],
      ),
    );
  }
}

class NoteDialog extends StatefulWidget {
  const NoteDialog({
    super.key,
    required this.title,
    required this.dateLabel,
    required this.noteKey,
    required this.confirmKey,
    required this.cancelKey,
    required this.confirmLabel,
    this.body = const [],
  });

  final String title;
  final String dateLabel;
  final Key noteKey;
  final Key confirmKey;
  final Key cancelKey;
  final String confirmLabel;
  final List<Widget> body;

  @override
  State<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  final _note = TextEditingController();
  final _cancelFocus = FocusNode();

  @override
  void dispose() {
    _note.dispose();
    _cancelFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DialogFrame(
      child: AlertDialog(
        title: Text(widget.title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.dateLabel),
                ...widget.body,
                TextField(
                  key: widget.noteKey,
                  controller: _note,
                  decoration: const InputDecoration(labelText: 'Nota'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            key: widget.cancelKey,
            focusNode: _cancelFocus,
            style: workspaceControlStyle,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel·la'),
          ),
          TextButton(
            key: widget.confirmKey,
            style: workspaceControlStyle,
            onPressed: () => Navigator.of(context).pop(_note.text),
            child: Text(widget.confirmLabel),
          ),
        ],
      ),
    );
  }
}

class VersionListDialog extends StatelessWidget {
  const VersionListDialog({super.key, required this.versions});

  final List<ArchitectureVersion> versions;

  @override
  Widget build(BuildContext context) {
    return _DialogFrame(
      child: AlertDialog(
        title: const Text('Instantànies'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            child: versions.isEmpty
                ? const Text('Cap instantània.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final version in versions) ...[
                        Text(
                          '${version.createdAt.toUtc().toIso8601String()} · ${version.note.isEmpty ? 'Sense nota' : version.note}',
                        ),
                        Text(
                          version.parentVersionId == null
                              ? 'Esquema ${version.schemaId}'
                              : 'Esquema ${version.schemaId} · origen ${version.parentVersionId}',
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            key: Key('restore-${version.id}'),
                            style: workspaceControlStyle,
                            onPressed: () =>
                                Navigator.of(context).pop(version.id),
                            child: const Text('Restaura'),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
        actions: [
          TextButton(
            style: workspaceControlStyle,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tanca'),
          ),
        ],
      ),
    );
  }
}

class ImportJsonDialog extends StatefulWidget {
  const ImportJsonDialog({super.key, required this.onPickFile});

  final Future<String?> Function() onPickFile;

  @override
  State<ImportJsonDialog> createState() => _ImportJsonDialogState();
}

class _ImportJsonDialogState extends State<ImportJsonDialog> {
  final _json = TextEditingController();
  final _cancelFocus = FocusNode();

  @override
  void dispose() {
    _json.dispose();
    _cancelFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DialogFrame(
      child: AlertDialog(
        title: const Text('Importa còpia'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: TextField(
            key: workspaceImportFieldKey,
            controller: _json,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(labelText: 'JSON de la còpia'),
          ),
        ),
        actions: [
          TextButton(
            style: workspaceControlStyle,
            onPressed: () async {
              final raw = await widget.onPickFile();
              if (raw != null) {
                _json.text = raw;
              }
            },
            child: const Text('Tria un fitxer'),
          ),
          TextButton(
            key: cancelWorkspaceImportKey,
            focusNode: _cancelFocus,
            style: workspaceControlStyle,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel·la'),
          ),
          TextButton(
            key: prepareWorkspaceImportKey,
            style: workspaceControlStyle,
            onPressed: () => Navigator.of(context).pop(_json.text),
            child: const Text('Prepara substitució'),
          ),
        ],
      ),
    );
  }
}

class WorkspaceReplaceDialog extends StatelessWidget {
  const WorkspaceReplaceDialog({
    super.key,
    required this.workspace,
    required this.onDownloadPrior,
  });

  final Workspace workspace;
  final VoidCallback onDownloadPrior;

  @override
  Widget build(BuildContext context) {
    final workspaceCounts =
        'Organitzacions: ${workspace.organizations.length}, actius: ${workspace.assets.length}, sistemes: ${workspace.systems.length}, fluxos: ${workspace.flows.length}, esquemes: ${workspace.schemas.length}, versions: ${workspace.versions.length}, registres OEE: ${workspace.oeeRecords.length}.';
    return _DialogFrame(
      child: AlertDialog(
        title: const Text('Substitució completa'),
        content: Text(
          'Aquesta acció substitueix totes les dades locals d\'IndexedDB. No fusiona identificadors.\n$workspaceCounts',
        ),
        actions: [
          TextButton(
            key: downloadWorkspacePriorKey,
            style: workspaceControlStyle,
            onPressed: onDownloadPrior,
            child: const Text('Descarrega la còpia prèvia'),
          ),
          TextButton(
            key: cancelWorkspaceReplaceKey,
            style: workspaceControlStyle,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel·la'),
          ),
          TextButton(
            key: confirmWorkspaceReplaceKey,
            style: workspaceControlStyle,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Substitueix les dades'),
          ),
        ],
      ),
    );
  }
}
