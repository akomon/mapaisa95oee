import 'package:flutter_test/flutter_test.dart';
import 'package:mapaisa95oee/legacy_reconciliation.dart';
import 'package:mapaisa95oee/plant_model.dart';
import 'package:mapaisa95oee/plant_store.dart';
import 'package:mapaisa95oee/workspace_codec.dart';
import 'package:mapaisa95oee/workspace_database.dart';
import 'package:mapaisa95oee/workspace_database_memory.dart';
import 'package:mapaisa95oee/workspace_model.dart';
import 'package:mapaisa95oee/workspace_repository.dart';

void main() {
  final now = DateTime.utc(2026, 9, 1, 8);

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

  ArchitectureVersion sampleVersion() {
    final stamp = DateTime.utc(2026, 1, 1);
    return ArchitectureVersion(
      id: 'n40',
      schemaId: 'n41',
      createdAt: stamp,
      note: 'Captura',
      parentVersionId: null,
      snapshot: ArchitectureSnapshot(
        schema: WorkSchema(
          id: 'n41',
          name: 'Captura',
          createdAt: stamp,
          updatedAt: stamp,
        ),
      ),
    );
  }

  OeeRecord sampleRecord() {
    final stamp = DateTime.utc(2026, 3, 2);
    return OeeRecord(
      id: 'n42',
      productionDate: '2026-03-01',
      shift: 'Matí',
      lineId: 'n4',
      article: 'Iogurt',
      lot: null,
      plannedMinutes: 480,
      downtimeMinutes: 60,
      speedOriginal: 1,
      speedUnit: SpeedUnit.secondsPerUnit,
      idealCycleSeconds: 1,
      totalUnits: 24000,
      goodUnits: 22800,
      status: OeeRecordStatus.validated,
      formulaVersion: 'oee.v1',
      capturedLineName: 'Línia iogurt',
      capturedPlantName: 'Planta Girona',
      createdAt: stamp,
      updatedAt: stamp,
    );
  }

  test(
    'una clau tardana es projecta sense promoure ni inventar sistemes',
    () async {
      final legacy = <String, String>{};
      final database = MemoryWorkspaceDatabase();
      final first = repository(database: database, legacy: legacy);
      await first.open();
      expect(first.migrationStatus, 'noLegacyData');

      final raw = plantToJson(foodPlantExample());
      legacy[plantStorageKey] = raw;
      final second = repository(database: database, legacy: legacy);
      await second.open();

      expect(legacy[plantStorageKey], raw);
      expect(second.workspace.legacyRaw, raw);
      expect(second.workspace.latestLegacyRaw, isNull);
      expect(second.workspace.systems, isEmpty);
      expect(second.workspace.flows, isEmpty);
      expect(second.workspace.migrationReviews, hasLength(11));
      expect(
        second.workspace.migrationReviews.every((review) => !review.promoted),
        isTrue,
      );
      expect(
        second.workspace.assets.every((asset) => asset.functions.isEmpty),
        isTrue,
      );
      expect(findAsset(second.workspace, 'n11')!.kind, AssetKind.machine);
      expect(second.migrationStatus, 'migrated');
      expect(second.status, SaveStatus.saved);
    },
  );

  test('un canvi al mapa antic entra al model i la còpia, sense tocar OEE ni snapshots', () async {
    final original = plantToJson(foodPlantExample());
    final legacy = {plantStorageKey: original};
    final database = MemoryWorkspaceDatabase();
    final repo = repository(database: database, legacy: legacy);
    await repo.open();
    final withHistory = repo.workspace.copyWith(
      nextIdCounter: 43,
      versions: [sampleVersion()],
      oeeRecords: [sampleRecord()],
    );
    await repo.saveWorkspace(withHistory);
    final versionsBefore = architectureVersionsJson(repo.workspace);
    final oeeBefore = oeeRecordsJson(repo.workspace);

    final edited = updateNode(
      foodPlantExample(),
      id: 'n4',
      name: 'Línia iogurt nova',
      functionalLevel: FunctionalLevel.erp,
    ).plant!;
    final added = addChild(
      edited,
      parentId: 'n4',
      name: 'Etiquetadora',
      kind: PlantNodeKind.cell,
      functionalLevel: FunctionalLevel.process,
    ).plant!;
    legacy[plantStorageKey] = plantToJson(added);

    final again = repository(database: database, legacy: legacy);
    await again.open();

    expect(legacy[plantStorageKey], plantToJson(added));
    expect(again.workspace.legacyRaw, original);
    expect(again.workspace.latestLegacyRaw, plantToJson(added));
    expect(findAsset(again.workspace, 'n4')!.name, 'Línia iogurt nova');
    expect(findAsset(again.workspace, 'n4')!.functions, isEmpty);
    final machine = findAsset(again.workspace, 'n12')!;
    expect(machine.name, 'Etiquetadora');
    expect(machine.kind, AssetKind.machine);
    expect(machine.parentId, 'n4');
    expect(machine.functions, isEmpty);
    expect(machine.iconKey, IconKey.machine);
    expect(again.workspace.systems, isEmpty);
    expect(again.workspace.flows, isEmpty);
    expect(
      again.workspace.migrationReviews
          .where((review) => review.entityId == 'n12')
          .single
          .promoted,
      isFalse,
    );
    expect(architectureVersionsJson(again.workspace), versionsBefore);
    expect(oeeRecordsJson(again.workspace), oeeBefore);
    expect(again.workspace.oeeRecords.single.capturedLineName, 'Línia iogurt');

    final backup = again.exportBackupJson();
    expect(backup, contains('Línia iogurt nova'));
    expect(backup, contains('Etiquetadora'));
    final restored = workspaceFromJson(backup);
    expect(restored.isValid, isTrue);
    expect(restored.workspace!.legacyRaw, original);
    expect(restored.workspace!.latestLegacyRaw, plantToJson(added));
    expect(findAsset(restored.workspace!, 'n4')!.name, 'Línia iogurt nova');
    expect(oeeRecordsJson(restored.workspace!), oeeBefore);
    expect(architectureVersionsJson(restored.workspace!), versionsBefore);
  });

  test('si el model canònic ja ha canviat, el legacy no el pisa', () async {
    final original = plantToJson(foodPlantExample());
    final legacy = {plantStorageKey: original};
    final database = MemoryWorkspaceDatabase();
    final repo = repository(database: database, legacy: legacy);
    await repo.open();
    final renamed = updateAsset(
      repo.workspace,
      id: 'n4',
      name: 'Nom canònic',
      parentId: 'n3',
      now: now,
    );
    await repo.saveWorkspace(renamed.workspace!);
    final versions = architectureVersionsJson(repo.workspace);

    final legacyName = updateNode(
      foodPlantExample(),
      id: 'n4',
      name: 'Nom legacy',
      functionalLevel: FunctionalLevel.mes,
    ).plant!;
    legacy[plantStorageKey] = plantToJson(legacyName);
    final again = repository(database: database, legacy: legacy);
    await again.open();

    expect(findAsset(again.workspace, 'n4')!.name, 'Nom canònic');
    expect(findAsset(again.workspace, 'n4')!.functions, isEmpty);
    expect(again.workspace.legacyRaw, original);
    expect(again.workspace.latestLegacyRaw, plantToJson(legacyName));
    expect(again.banner, legacyConflictMessage);
    expect(again.workspace.systems, isEmpty);
    expect(architectureVersionsJson(again.workspace), versions);
    expect(again.status, SaveStatus.saved);
    expect(legacy[plantStorageKey], plantToJson(legacyName));
  });

  test('un legacy il·legible no substitueix el model ni diu Desat', () async {
    final original = plantToJson(foodPlantExample());
    final legacy = {plantStorageKey: original};
    final database = MemoryWorkspaceDatabase();
    final repo = repository(database: database, legacy: legacy);
    await repo.open();
    legacy[plantStorageKey] = '{bad';
    final again = repository(database: database, legacy: legacy);
    await again.open();

    expect(again.status, SaveStatus.error);
    expect(saveStatusText(again.status, quotaExceeded: false), isNot('Desat'));
    expect(again.workspace.organizations.single.name, 'Alimentària Demo');
    expect(again.workspace.legacyRaw, original);
    expect(again.workspace.latestLegacyRaw, '{bad');
    expect(again.workspace.assets, hasLength(10));
    expect(legacy[plantStorageKey], '{bad');
  });

  test('la represa no torna a aplicar el mateix text', () async {
    final legacy = {plantStorageKey: plantToJson(foodPlantExample())};
    final database = MemoryWorkspaceDatabase();
    final repo = repository(database: database, legacy: legacy);
    await repo.open();
    final stored = database.values[workspaceDocumentKey];
    final again = repository(database: database, legacy: legacy);
    await again.open();
    expect(database.values[workspaceDocumentKey], stored);
    expect(again.workspace.reconciledLegacyRaw, isNull);
  });
}
