import 'package:flutter/material.dart';

import 'legacy_key_probe.dart';
import 'plant_io.dart' as plant_io;
import 'workspace_model.dart';
import 'workspace_repository.dart';
import 'workspace_shell.dart';

const Key saveStatusKey = Key('saveStatus');
const Key backupJsonFieldKey = Key('backupJsonField');
const Key prepareReplaceKey = Key('prepareReplace');
const Key exportBackupKey = Key('exportBackup');
const Key downloadLegacyKey = Key('downloadLegacy');
const Key downloadLatestLegacyKey = Key('downloadLatestLegacy');
const Key loadFoodExampleKey = Key('loadFoodExample');
const Key confirmReplaceKey = Key('confirmReplace');
const Key cancelReplaceKey = Key('cancelReplace');
const Key downloadPriorKey = Key('downloadPrior');
const Key confirmExampleKey = Key('confirmExample');
const Key cancelExampleKey = Key('cancelExample');
const Key legacyKeyStatusKey = Key('legacyKeyStatus');

const ButtonStyle touchButtonStyle = ButtonStyle(
  minimumSize: WidgetStatePropertyAll(Size(48, 48)),
);

typedef WorkspaceJsonExporter = Future<void> Function(
  String filename,
  String json,
);
typedef WorkspaceJsonImporter = Future<String?> Function();

class DataFoundationPage extends StatefulWidget {
  const DataFoundationPage({
    super.key,
    required this.repository,
    this.onOpenOee,
    this.onOpenEngine,
    this.onOpenMap,
    this.exportJson,
    this.importJson,
  });

  final WorkspaceRepository repository;
  final VoidCallback? onOpenOee;
  final VoidCallback? onOpenEngine;
  final VoidCallback? onOpenMap;
  final WorkspaceJsonExporter? exportJson;
  final WorkspaceJsonImporter? importJson;

  @override
  State<DataFoundationPage> createState() => _DataFoundationPageState();
}

class _DataFoundationPageState extends State<DataFoundationPage> {
  final TextEditingController _json = TextEditingController();
  String? _pendingRaw;

  @override
  void initState() {
    super.initState();
    widget.repository.addListener(_changed);
  }

  @override
  void dispose() {
    widget.repository.removeListener(_changed);
    _json.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _export(String filename, String json) {
    final exporter = widget.exportJson ?? plant_io.downloadJsonFile;
    return exporter(filename, json);
  }

  Future<void> _prepare() async {
    final parsed = widget.repository.previewBackup(_json.text);
    if (!parsed.isValid || parsed.workspace == null) {
      widget.repository.rejectImport(parsed.issues);
      return;
    }
    _pendingRaw = _json.text;
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => _ReplaceDialog(
        workspace: parsed.workspace!,
        onDownloadPrior: () => _export(
          'mapaisa95oee-backup.json',
          widget.repository.exportBackupJson(),
        ),
        onCancel: () => Navigator.of(context).pop(),
        onConfirm: () async {
          Navigator.of(context).pop();
          final raw = _pendingRaw;
          if (raw == null) {
            return;
          }
          await widget.repository.replaceWithBackup(raw, confirm: true);
        },
      ),
    );
  }

  Future<void> _loadExample() async {
    if (!widget.repository.exampleNeedsConfirm) {
      await widget.repository.loadExample(confirm: true);
      return;
    }
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Carrega exemple alimentari'),
        content: const Text(
          'Carregar l\'exemple substitueix les dades d\'aquest navegador.',
        ),
        actions: [
          TextButton(
            key: cancelExampleKey,
            style: touchButtonStyle,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel·la'),
          ),
          TextButton(
            key: confirmExampleKey,
            style: touchButtonStyle,
            onPressed: () async {
              Navigator.of(context).pop();
              await widget.repository.loadExample(confirm: true);
            },
            child: const Text('Carrega exemple'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = widget.repository;
    final workspace = repository.workspace;
    final browserKey = legacyBrowserKeyPresent();
    final status = saveStatusText(
      repository.status,
      quotaExceeded: repository.quotaExceeded,
    );
    final actions = <Widget>[
      if (widget.onOpenOee != null)
        workspaceBarButton(
          label: 'Calculador OEE',
          onPressed: widget.onOpenOee,
        ),
      if (widget.onOpenMap != null)
        workspaceBarButton(label: 'Mapa ISA-95', onPressed: widget.onOpenMap),
    ];
    return WorkspaceShell(
      current: WorkspaceSection.data,
      onOpenCalculator: widget.onOpenOee,
      onOpenEngine: widget.onOpenEngine,
      onOpenMap: widget.onOpenMap,
      header: const WorkspaceHeader(title: 'Dades locals'),
      bottom: actions.isEmpty ? null : WorkspaceBottomBar(children: actions),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  key: saveStatusKey,
                  liveRegion: true,
                  label: status,
                  child: Text(
                    status,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (repository.banner != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    repository.banner!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Text(storageLimitationMessage),
                const SizedBox(height: 12),
                Text(
                  repository.legacyKeyPresent
                      ? 'Clau legacy mapaisa95oee.plant.v1: present (${repository.legacyCharCount} caràcters).'
                      : 'Clau legacy mapaisa95oee.plant.v1: absent.',
                  key: legacyKeyStatusKey,
                ),
                if (browserKey != null)
                  Text(
                    browserKey
                        ? 'localStorage $legacyBrowserStorageKey: present.'
                        : 'localStorage $legacyBrowserStorageKey: absent.',
                  ),
                if (repository.legacyKeyPresent)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'La clau legacy no s\'esborra ni es reescriu. Si el text divergeix, es reconcilia amb el model canònic sense promoure nivells antics i sense modificar instantànies ni registres OEE.',
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  'Organitzacions: ${workspace.organizations.length} · Actius: ${workspace.assets.length} · Sistemes: ${workspace.systems.length} · Fluxos: ${workspace.flows.length} · Esquemes: ${workspace.schemas.length} · Versions: ${workspace.versions.length} · Registres OEE: ${workspace.oeeRecords.length}',
                ),
                const SizedBox(height: 8),
                const Text('Els registres OEE no formen part dels snapshots.'),
                if (workspace.migrationReviews.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Revisions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (final review in workspace.migrationReviews)
                    _ReviewTile(
                      review: review,
                      name: _entityName(workspace, review.entityId),
                      enabled: repository.status != SaveStatus.saving,
                      onAcknowledge: () => repository.acknowledge(review.id),
                    ),
                ],
                const SizedBox(height: 16),
                for (final organization in workspace.organizations)
                  Text('${organization.name} · Sense funció ISA-95'),
                for (final asset in workspace.assets)
                  Text(
                    '${asset.name} · ${assetKindLabel(asset.kind)} · ${asset.functions.isEmpty ? 'Sense funcions' : asset.functions.map(isaFunctionLabel).join(', ')}',
                  ),
                for (final system in workspace.systems)
                  Text(
                    '${system.name} · ${systemTypeLabel(system.systemType)} · ${system.functions.isEmpty ? 'Sense funcions' : system.functions.map(isaFunctionLabel).join(', ')} · ${itOtZoneLabel(system.zone)} · abast ${_scopeNames(workspace, system)}',
                  ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      key: exportBackupKey,
                      style: touchButtonStyle,
                      onPressed: repository.status == SaveStatus.saving
                          ? null
                          : () => _export(
                              'mapaisa95oee-backup.json',
                              repository.exportBackupJson(),
                            ),
                      child: const Text('Exporta còpia'),
                    ),
                    if (repository.recoverableLegacyRaw != null)
                      OutlinedButton(
                        key: downloadLegacyKey,
                        style: touchButtonStyle,
                        onPressed: () => _export(
                          'mapaisa95oee-legacy-plant.json',
                          repository.recoverableLegacyRaw!,
                        ),
                        child: const Text('Descarrega la còpia legacy'),
                      ),
                    if (workspace.latestLegacyRaw != null)
                      OutlinedButton(
                        key: downloadLatestLegacyKey,
                        style: touchButtonStyle,
                        onPressed: () => _export(
                          'mapaisa95oee-legacy-latest.json',
                          workspace.latestLegacyRaw!,
                        ),
                        child: const Text('Descarrega el legacy més recent'),
                      ),
                    OutlinedButton(
                      key: loadFoodExampleKey,
                      style: touchButtonStyle,
                      onPressed: repository.status == SaveStatus.saving
                          ? null
                          : _loadExample,
                      child: const Text('Carrega exemple alimentari'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  key: backupJsonFieldKey,
                  controller: _json,
                  minLines: 3,
                  maxLines: 6,
                  style: const TextStyle(fontSize: 16, height: 1.25),
                  decoration: const InputDecoration(
                    labelText: 'JSON de la còpia',
                    constraints: BoxConstraints(minHeight: 48),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      key: prepareReplaceKey,
                      style: touchButtonStyle,
                      onPressed: repository.status == SaveStatus.saving
                          ? null
                          : _prepare,
                      child: const Text('Prepara substitució'),
                    ),
                    OutlinedButton(
                      style: touchButtonStyle,
                      onPressed: repository.status == SaveStatus.saving
                          ? null
                          : () async {
                              final importer =
                                  widget.importJson ?? plant_io.pickJsonFile;
                              final raw = await importer();
                              if (raw == null) {
                                return;
                              }
                              _json.text = raw;
                            },
                      child: const Text('Tria un fitxer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReplaceDialog extends StatelessWidget {
  const _ReplaceDialog({
    required this.workspace,
    required this.onDownloadPrior,
    required this.onCancel,
    required this.onConfirm,
  });

  final Workspace workspace;
  final VoidCallback onDownloadPrior;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Substitució completa'),
      content: Text(
        'Aquesta acció substitueix totes les dades locals d\'IndexedDB. No fusiona identificadors.\n'
        'Organitzacions: ${workspace.organizations.length}, actius: ${workspace.assets.length}, sistemes: ${workspace.systems.length}, fluxos: ${workspace.flows.length}, esquemes: ${workspace.schemas.length}, versions: ${workspace.versions.length}, registres OEE: ${workspace.oeeRecords.length}.',
      ),
      actions: [
        TextButton(
          key: downloadPriorKey,
          style: touchButtonStyle,
          onPressed: onDownloadPrior,
          child: const Text('Descarrega la còpia prèvia'),
        ),
        TextButton(
          key: cancelReplaceKey,
          style: touchButtonStyle,
          onPressed: onCancel,
          child: const Text('Cancel·la'),
        ),
        TextButton(
          key: confirmReplaceKey,
          style: touchButtonStyle,
          onPressed: onConfirm,
          child: const Text('Substitueix les dades'),
        ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.review,
    required this.name,
    required this.enabled,
    required this.onAcknowledge,
  });

  final MigrationReview review;
  final String name;
  final bool enabled;
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final state = review.status == ReviewStatus.pendingReview
        ? 'pendent'
        : 'revisat';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$name · ${review.legacyKind} · nivell antic ${review.legacyFunctionalLevel} (${review.legacyFunctionalLevelLabel}) · no promogut · $state',
          ),
          if (review.status == ReviewStatus.pendingReview)
            OutlinedButton(
              key: Key('acknowledge-${review.id}'),
              style: touchButtonStyle,
              onPressed: enabled ? onAcknowledge : null,
              child: const Text('Marca com a revisada'),
            ),
        ],
      ),
    );
  }
}

String _entityName(Workspace workspace, String id) {
  return findOrganization(workspace, id)?.name ??
      findAsset(workspace, id)?.name ??
      id;
}

String _scopeNames(Workspace workspace, WorkSystem system) {
  if (system.scopeIds.isEmpty) {
    return 'cap';
  }
  return [
    for (final id in system.scopeIds) findAsset(workspace, id)?.name ?? id,
  ].join(', ');
}
