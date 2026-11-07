import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'legacy_migration.dart';
import 'workspace_codec.dart';
import 'workspace_database.dart';
import 'workspace_model.dart';

enum SaveStatus { saving, saved, error }

const String storageLimitationMessage =
    'IndexedDB és local a aquest origen i perfil del navegador. No és una còpia de seguretat. Esborrar dades, canviar de dispositiu, el mode privat o l\'expulsió d\'emmagatzematge pot perdre informació. Un error de quota no vol dir que s\'hagi desat. El JSON descarregable és la via de recuperació. No hi ha sincronització ni durabilitat garantida.';

String saveStatusText(SaveStatus status, {required bool quotaExceeded}) {
  switch (status) {
    case SaveStatus.saving:
      return 'Desant…';
    case SaveStatus.saved:
      return 'Desat';
    case SaveStatus.error:
      const base = 'Error de desament. Les dades anteriors es conserven.';
      if (!quotaExceeded) {
        return base;
      }
      return '$base La quota d\'emmagatzematge s\'ha exhaurit.';
  }
}

class WorkspaceRepository extends ChangeNotifier {
  WorkspaceRepository({
    required this.database,
    required this.readLegacy,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final WorkspaceDatabase database;
  final Future<String?> Function() readLegacy;
  final DateTime Function() _now;

  SaveStatus status = SaveStatus.saving;
  String? banner;
  bool quotaExceeded = false;
  bool ready = false;
  Workspace workspace = createEmptyWorkspace();
  String migrationStatus = 'noLegacyData';
  String? migrationLegacyRaw;
  bool legacyKeyPresent = false;
  int legacyCharCount = 0;

  DateTime get now => _now().toUtc();

  String? get recoverableLegacyRaw => workspace.legacyRaw ?? migrationLegacyRaw;

  bool get exampleNeedsConfirm =>
      workspace.hasDomainData || migrationStatus == 'rejected';

  Future<void> open() async {
    status = SaveStatus.saving;
    banner = null;
    quotaExceeded = false;
    notifyListeners();
    try {
      final existing = await database.read(workspaceDocumentKey);
      final legacy = await readLegacy();
      legacyKeyPresent = legacy != null && legacy.isNotEmpty;
      legacyCharCount = legacy?.length ?? 0;
      _readMigrationState(await database.read(migrationStateKey));
      if (existing != null) {
        final parsed = workspaceFromJson(existing);
        if (!parsed.isValid || parsed.workspace == null) {
          status = SaveStatus.error;
          banner = _firstMessage(parsed.issues);
          ready = true;
          notifyListeners();
          return;
        }
        workspace = parsed.workspace!;
        status = SaveStatus.saved;
        ready = true;
        notifyListeners();
        return;
      }
      if (legacy == null || legacy.isEmpty) {
        await _writeInitial(
          createEmptyWorkspace(),
          statusName: 'noLegacyData',
          legacyRaw: null,
          messages: const [],
        );
        return;
      }
      final migrated = migrateLegacyPlant(legacy, migratedAt: now);
      if (!migrated.isValid || migrated.workspace == null) {
        await _writeMigrationOnly(
          statusName: 'rejected',
          legacyRaw: legacy,
          messages: [
            for (final issue in migrated.issues)
              workspaceIssueMessage(issue.code),
          ],
        );
        workspace = createEmptyWorkspace();
        migrationStatus = 'rejected';
        migrationLegacyRaw = legacy;
        status = SaveStatus.error;
        quotaExceeded = false;
        banner = _firstMessage(migrated.issues);
        ready = true;
        notifyListeners();
        return;
      }
      await _writeInitial(
        migrated.workspace!,
        statusName: 'migrated',
        legacyRaw: legacy,
        messages: const [],
      );
    } catch (error) {
      _markWriteFailed(error);
      ready = true;
      notifyListeners();
    }
  }

  WorkspaceImport previewBackup(String raw) => workspaceFromJson(raw);

  void rejectImport(List<WorkspaceIssue> issues) {
    banner = _firstMessage(issues);
    notifyListeners();
  }

  Future<void> replaceWithBackup(String raw, {required bool confirm}) async {
    final parsed = workspaceFromJson(raw);
    if (!parsed.isValid || parsed.workspace == null) {
      banner = _firstMessage(parsed.issues);
      notifyListeners();
      return;
    }
    if (!confirm) {
      return;
    }
    final prior = workspaceToJson(workspace);
    await _commit(parsed.workspace!, priorJson: prior);
  }

  Future<void> loadExample({required bool confirm}) async {
    final needsConfirm =
        workspace.hasDomainData || migrationStatus == 'rejected';
    if (needsConfirm && !confirm) {
      return;
    }
    final prior = workspace.hasDomainData ? workspaceToJson(workspace) : null;
    final example = foodIndustryExample().copyWith(
      legacyRaw: workspace.legacyRaw ?? migrationLegacyRaw,
    );
    await _commit(example, priorJson: prior);
  }

  Future<void> acknowledge(String id) async {
    final mutation = acknowledgeReview(workspace, id: id);
    if (!mutation.isValid || mutation.workspace == null) {
      banner = _firstMessage(mutation.issues);
      notifyListeners();
      return;
    }
    await _commit(mutation.workspace!);
  }

  String exportBackupJson() {
    return workspaceToBackupJson(workspace, exportedAt: now);
  }

  Future<void> _writeInitial(
    Workspace next, {
    required String statusName,
    required String? legacyRaw,
    required List<String> messages,
  }) async {
    final encoded = workspaceToJson(next);
    final checked = workspaceFromJson(encoded);
    if (!checked.isValid || checked.workspace == null) {
      status = SaveStatus.error;
      banner = _firstMessage(checked.issues);
      ready = true;
      notifyListeners();
      return;
    }
    await database.write({
      workspaceDocumentKey: encoded,
      migrationStateKey: _migrationJson(
        statusName: statusName,
        legacyRaw: legacyRaw,
        messages: messages,
      ),
    });
    workspace = checked.workspace!;
    migrationStatus = statusName;
    migrationLegacyRaw = legacyRaw;
    status = SaveStatus.saved;
    banner = null;
    quotaExceeded = false;
    ready = true;
    notifyListeners();
  }

  Future<void> _writeMigrationOnly({
    required String statusName,
    required String legacyRaw,
    required List<String> messages,
  }) async {
    await database.write({
      migrationStateKey: _migrationJson(
        statusName: statusName,
        legacyRaw: legacyRaw,
        messages: messages,
      ),
    });
  }

  Future<void> _commit(Workspace next, {String? priorJson}) async {
    final previous = workspace;
    final encoded = workspaceToJson(next);
    final checked = workspaceFromJson(encoded);
    if (!checked.isValid || checked.workspace == null) {
      status = SaveStatus.error;
      banner = _firstMessage(checked.issues);
      notifyListeners();
      return;
    }
    status = SaveStatus.saving;
    banner = null;
    quotaExceeded = false;
    notifyListeners();
    try {
      await database.write({
        workspaceDocumentKey: encoded,
        priorBackupKey: ?priorJson,
      });
      workspace = checked.workspace!;
      status = SaveStatus.saved;
      banner = null;
      quotaExceeded = false;
    } catch (error) {
      workspace = previous;
      _markWriteFailed(error);
    }
    notifyListeners();
  }

  void _markWriteFailed(Object error) {
    status = SaveStatus.error;
    quotaExceeded = error.toString().toLowerCase().contains('quota');
    banner = null;
  }

  void _readMigrationState(String? raw) {
    if (raw == null || raw.isEmpty) {
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return;
      }
      final statusName = decoded['status'];
      if (statusName is String && statusName.isNotEmpty) {
        migrationStatus = statusName;
      }
      final legacy = decoded['legacyRaw'];
      if (legacy is String) {
        migrationLegacyRaw = legacy;
      }
    } on FormatException {
      return;
    }
  }

  String _migrationJson({
    required String statusName,
    required String? legacyRaw,
    required List<String> messages,
  }) {
    return jsonEncode({
      'status': statusName,
      'legacyRaw': legacyRaw,
      'messages': messages,
      'capturedAt': encodeTimestamp(now),
    });
  }

  String _firstMessage(List<WorkspaceIssue> issues) {
    if (issues.isEmpty) {
      return workspaceIssueMessage(WorkspaceIssueCode.invalidJson);
    }
    return workspaceIssueMessage(issues.first.code);
  }
}
