import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:idb_shim/idb_client_memory.dart';
import 'package:mapaisa95oee/plant_model.dart';
import 'package:mapaisa95oee/plant_store.dart';
import 'package:mapaisa95oee/workspace_database.dart';
import 'package:mapaisa95oee/workspace_database_memory.dart';
import 'package:mapaisa95oee/workspace_idb.dart';
import 'package:mapaisa95oee/workspace_model.dart';
import 'package:mapaisa95oee/workspace_repository.dart';

void main() {
  final now = DateTime.utc(2026, 7, 1, 8);

  WorkspaceRepository repository({
    required WorkspaceDatabase database,
    required Map<String, String> legacy,
  }) {
    return WorkspaceRepository(
      database: database,
      readLegacy: () async => legacy[plantStorageKey],
      now: () => now,
    );
  }

  test('migra una còpia i no escriu la clau legacy', () async {
    final legacy = {plantStorageKey: plantToJson(foodPlantExample())};
    final original = legacy[plantStorageKey];
    var legacyWrites = 0;
    final preferences = PreferencesPlantStore(
      read: (key) async => legacy[key],
      write: (key, value) async {
        legacyWrites += 1;
        legacy[key] = value;
      },
    );
    final database = MemoryWorkspaceDatabase();
    final repo = repository(database: database, legacy: legacy);

    await repo.open();

    expect(legacyWrites, 0);
    expect(legacy[plantStorageKey], original);
    expect(await preferences.load(), isNotNull);
    expect(repo.status, SaveStatus.saved);
    expect(repo.migrationStatus, 'migrated');
    expect(repo.workspace.systems, isEmpty);
    expect(repo.workspace.migrationReviews, hasLength(11));
    expect(repo.workspace.legacyRaw, original);
    expect(database.values[workspaceDocumentKey], contains('Alimentària Demo'));
    expect(database.values[migrationStateKey], contains('"status":"migrated"'));
    expect(repo.legacyKeyPresent, isTrue);

    legacy[plantStorageKey] = plantToJson(createEmptyPlant());
    await repo.open();
    expect(repo.workspace.organizations.single.name, 'Alimentària Demo');
    expect(legacyWrites, 0);
  });

  test('un legacy invàlid no aplica un document ni diu Desat', () async {
    final legacy = {plantStorageKey: '{bad'};
    final database = MemoryWorkspaceDatabase();
    final repo = repository(database: database, legacy: legacy);

    await repo.open();

    expect(repo.status, SaveStatus.error);
    expect(saveStatusText(repo.status, quotaExceeded: false), isNot('Desat'));
    expect(repo.workspace.organizations, isEmpty);
    expect(database.values.containsKey(workspaceDocumentKey), isFalse);
    expect(database.values[migrationStateKey], contains('rejected'));
    expect(legacy[plantStorageKey], '{bad');
    expect(repo.recoverableLegacyRaw, '{bad');
  });

  test(
    'una transacció fallida conserva el document i no anuncia èxit',
    () async {
      final database = MemoryWorkspaceDatabase();
      final repo = repository(database: database, legacy: {});
      await repo.open();
      expect(repo.status, SaveStatus.saved);

      database.failWrites = 1;
      await repo.loadExample(confirm: true);

      expect(repo.status, SaveStatus.error);
      expect(repo.quotaExceeded, isFalse);
      expect(repo.workspace.organizations, isEmpty);
      expect(
        saveStatusText(repo.status, quotaExceeded: false),
        contains('es conserven'),
      );

      database.failWrites = 1;
      database.errorToThrow = StateError('QuotaExceededError');
      await repo.loadExample(confirm: true);
      expect(repo.quotaExceeded, isTrue);
      expect(
        saveStatusText(repo.status, quotaExceeded: true),
        contains('quota'),
      );
      expect(repo.workspace.organizations, isEmpty);
    },
  );

  test('la substitució invàlida no escriu i la vàlida és atòmica', () async {
    final database = MemoryWorkspaceDatabase();
    final repo = repository(database: database, legacy: {});
    await repo.open();
    await repo.loadExample(confirm: true);
    final before = database.values[workspaceDocumentKey];

    await repo.replaceWithBackup('{', confirm: true);
    expect(repo.banner, 'El JSON no és vàlid.');
    expect(repo.status, SaveStatus.saved);
    expect(database.values[workspaceDocumentKey], before);
    expect(repo.workspace.organizations.single.name, 'Alimentària Demo');

    await repo.replaceWithBackup('{"version":1,"nodes":[]}', confirm: true);
    expect(repo.banner, contains('mapa antic'));
    expect(database.values[workspaceDocumentKey], before);

    final replacement = createEmptyWorkspace();
    final raw = repo.exportBackupJson();
    expect(raw, contains('"formatVersion": 1'));
    final emptyBackup = jsonDecode(raw) as Map<String, dynamic>;
    emptyBackup['organizations'] = <Object>[];
    emptyBackup['assets'] = <Object>[];
    emptyBackup['systems'] = <Object>[];
    emptyBackup['schemas'] = <Object>[];
    emptyBackup['nextIdCounter'] = replacement.nextIdCounter;

    await repo.replaceWithBackup(jsonEncode(emptyBackup), confirm: false);
    expect(database.values[workspaceDocumentKey], before);

    await repo.replaceWithBackup(jsonEncode(emptyBackup), confirm: true);
    expect(repo.status, SaveStatus.saved);
    expect(repo.workspace.organizations, isEmpty);
    expect(database.values[priorBackupKey], before);
    expect(
      jsonDecode(database.values[migrationStateKey]!)['status'],
      'noLegacyData',
    );
  });

  test('IndexedDB en memòria recupera el document', () async {
    final database = IdbWorkspaceDatabase(
      newIdbFactoryMemory(),
      name: 'mapaisa95oee-test',
    );
    final first = WorkspaceRepository(
      database: database,
      readLegacy: () async => null,
      now: () => now,
    );
    await first.open();
    await first.loadExample(confirm: true);
    final second = WorkspaceRepository(
      database: database,
      readLegacy: () async => plantToJson(foodPlantExample()),
      now: () => now,
    );
    await second.open();
    expect(second.workspace.organizations.single.name, 'Alimentària Demo');
    expect(second.workspace.systems, hasLength(4));
    expect(second.workspace.oeeRecords, isEmpty);
    expect(second.workspace.versions, isEmpty);
  });

  test('el desament passa per l\'estat Desant', () async {
    final database = MemoryWorkspaceDatabase();
    final repo = repository(database: database, legacy: {});
    await repo.open();
    final gate = Completer<void>();
    database.beforeWrite = () => gate.future;
    final statuses = <SaveStatus>[];
    repo.addListener(() => statuses.add(repo.status));
    final pending = repo.loadExample(confirm: true);
    await Future<void>.delayed(Duration.zero);
    expect(statuses, contains(SaveStatus.saving));
    gate.complete();
    await pending;
    expect(repo.status, SaveStatus.saved);
  });
}
