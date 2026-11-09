import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mapaisa95oee/flow_suggestions.dart';
import 'package:mapaisa95oee/workspace_codec.dart';
import 'package:mapaisa95oee/workspace_database.dart';
import 'package:mapaisa95oee/workspace_database_memory.dart';
import 'package:mapaisa95oee/workspace_model.dart';
import 'package:mapaisa95oee/workspace_repository.dart';

void main() {
  final now = DateTime.utc(2026, 9, 2, 9);

  Map<String, Object?> stripVersions(Workspace workspace) {
    final decoded =
        jsonDecode(workspaceToJson(workspace)) as Map<String, Object?>;
    decoded.remove('architectureVersions');
    decoded.remove('nextIdCounter');
    return decoded;
  }

  OeeRecord sampleRecord() {
    return OeeRecord(
      id: 'n40',
      productionDate: '2026-03-01',
      shift: 'Matí',
      lineId: 'n4',
      article: 'Iogurt natural',
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
      createdAt: now,
      updatedAt: now,
    );
  }

  test('la plantilla previsualitza màquines i només hereta la línia', () {
    final template = findMachineTemplate('envasat')!;
    expect(
      template.machines.map((item) => '${item.name}:${item.iconKey.name}'),
      ['Omplidora:machine', 'Taponadora:machine'],
    );
    final line = findAsset(
      foodIndustryExample(),
      'n4',
    )!.copyWith(functions: const [IsaFunction.l2]);
    final workspace = foodIndustryExample().copyWith(
      assets: [
        for (final asset in foodIndustryExample().assets)
          if (asset.id == 'n4') line else asset,
      ],
    );
    final flowsBefore = workspace.flows.length;
    final applied = applyMachineTemplate(
      workspace,
      templateId: 'envasat',
      lineId: 'n4',
      now: now,
    );
    final next = applied.workspace!;
    final created = next.assets.where(
      (asset) => asset.id == 'n21' || asset.id == 'n22',
    );
    expect(created.map((asset) => asset.name), ['Omplidora', 'Taponadora']);
    for (final asset in created) {
      expect(asset.parentId, 'n4');
      expect(asset.kind, AssetKind.machine);
      expect(asset.iconKey, IconKey.machine);
      expect(asset.functions, isEmpty);
    }
    expect(next.flows, hasLength(flowsBefore));
    expect(findAsset(next, 'n4')!.functions, [IsaFunction.l2]);
    expect(findAsset(workspace, 'n21'), isNull);

    final icon = updateAsset(
      next,
      id: 'n21',
      name: 'Omplidora',
      parentId: 'n4',
      iconKey: IconKey.line,
      functions: const [],
      now: now,
    );
    expect(icon.workspace!.flows, isEmpty);
    expect(findAsset(icon.workspace!, 'n21')!.functions, isEmpty);
    expect(findAsset(icon.workspace!, 'n21')!.kind, AssetKind.machine);

    final rejected = applyMachineTemplate(
      workspace,
      templateId: 'envasat',
      lineId: 'n2',
      now: now,
    );
    expect(rejected.workspace, isNull);
    expect(rejected.issues.single.code, WorkspaceIssueCode.incompatibleParent);
  });

  test('els suggeriments no escriuen fluxos ni llegeixen la xarxa', () {
    final source = File('lib/flow_suggestions.dart').readAsStringSync();
    expect(source, isNot(contains('dart:io')));
    expect(source, isNot(contains('HttpClient')));
    expect(source, isNot(contains('Socket')));
    expect(source, isNot(contains('package:http')));

    final workspace = foodIndustryExample();
    final suggestions = suggestDeclaredScopes(workspace, schemaId: 'n20');
    expect(workspace.flows, isEmpty);
    expect(suggestions.map((item) => item.key), [
      'n16>n2',
      'n16>n12',
      'n17>n4',
      'n17>n7',
      'n18>n5',
      'n19>n2',
    ]);
    expect(
      suggestions.any(
        (item) => item.sourceId == 'n16' && item.targetId == 'n17',
      ),
      isFalse,
    );

    final withFlow = addFlow(
      workspace,
      name: 'Ja declarat',
      sourceId: 'n16',
      targetId: 'n2',
      exchangedData: 'Ordres',
      protocol: null,
      purpose: 'Enviar',
      status: FlowStatus.suggested,
      now: now,
    ).workspace!;
    final remaining = suggestDeclaredScopes(withFlow, schemaId: 'n20');
    expect(remaining.any((item) => item.key == 'n16>n2'), isFalse);
    expect(withFlow.flows, hasLength(1));
  });

  test('dos esquemes conserven disposició i no dupliquen OEE', () {
    final seeded = foodIndustryExample().copyWith(oeeRecords: [sampleRecord()]);
    final created = addSchema(
      seeded,
      name: 'Només Lleida',
      plantIds: const ['n12'],
      now: now,
    ).workspace!;
    final lleida = created.schemas.last;
    expect(lleida.plantIds, ['n12']);
    expect(lleida.assetIds, containsAll(['n12', 'n13', 'n14', 'n15']));
    expect(lleida.assetIds, isNot(contains('n4')));
    expect(lleida.systemIds, ['n16']);
    expect(lleida.flowIds, isEmpty);
    expect(created.oeeRecords.single.article, 'Iogurt natural');

    final copied = copySchema(
      created,
      schemaId: 'n20',
      name: 'Còpia alimentària',
      now: now,
    ).workspace!;
    final copy = copied.schemas.last;
    expect(
      copy.layout['n16']!.x,
      findSchema(foodIndustryExample(), 'n20')!.layout['n16']!.x,
    );
    final moved = updateSchemaLayout(
      copied,
      schemaId: copy.id,
      entityId: 'n16',
      at: const LayoutPoint(1, 9),
      now: now,
    ).workspace!;
    expect(findSchema(moved, 'n20')!.layout['n16']!.x, isNot(1));
    expect(findSchema(moved, copy.id)!.layout['n16']!.x, 1);
    expect(findSchema(moved, copy.id)!.layout['n16']!.y, 9);
    expect(oeeRecordsJson(moved), oeeRecordsJson(seeded));
    expect(findAsset(moved, 'n4')!.functions, isEmpty);

    final roundTrip = workspaceFromJson(workspaceToJson(moved));
    expect(
      roundTrip.isValid,
      isTrue,
      reason: roundTrip.issues.map((issue) => issue.code.name).join(','),
    );
    expect(findSchema(roundTrip.workspace!, copy.id)!.layout['n16']!.y, 9);
  });

  test('la instantània i la restauració no muten mestres ni OEE', () {
    final seeded = foodIndustryExample().copyWith(oeeRecords: [sampleRecord()]);
    final captured = createSnapshot(
      seeded,
      schemaId: 'n20',
      note: 'Primera captura',
      now: now,
    ).workspace!;
    final origin = captured.versions.single;
    expect(origin.note, 'Primera captura');
    expect(origin.createdAt, now);
    expect(origin.parentVersionId, isNull);
    expect(origin.snapshot.organizations.single.id, 'n1');
    expect(origin.snapshot.assets.map((asset) => asset.id), contains('n4'));
    expect(origin.snapshot.flows, isEmpty);
    final versionJson =
        (jsonDecode(architectureVersionsJson(captured)) as List).single
            as Map<String, Object?>;
    expect((versionJson['snapshot'] as Map).containsKey('oeeRecords'), isFalse);
    expect(workspaceFromJson(workspaceToJson(captured)).isValid, isTrue);

    final renamed = updateAsset(
      captured,
      id: 'n4',
      name: 'Línia reanomenada',
      parentId: 'n3',
      iconKey: IconKey.line,
      functions: const [IsaFunction.l3],
      now: now,
    ).workspace!;
    expect(
      findVersion(
        renamed,
        origin.id,
      )!.snapshot.assets.firstWhere((asset) => asset.id == 'n4').name,
      'Línia iogurt',
    );
    expect(
      findVersion(
        renamed,
        origin.id,
      )!.snapshot.assets.firstWhere((asset) => asset.id == 'n4').functions,
      isEmpty,
    );
    expect(renamed.oeeRecords.single.capturedLineName, 'Línia iogurt');

    final beforeReport = workspaceToJson(renamed);
    final report = snapshotDivergences(renamed, origin.snapshot);
    expect(report.map((item) => item.entityId), contains('n4'));
    expect(workspaceToJson(renamed), beforeReport);

    final restored = restoreSnapshot(
      renamed,
      versionId: origin.id,
      note: 'Restauració',
      now: now.add(const Duration(minutes: 5)),
    ).workspace!;
    expect(restored.versions, hasLength(2));
    expect(restored.versions.first.id, origin.id);
    expect(restored.versions.last.parentVersionId, origin.id);
    expect(restored.versions.last.schemaId, origin.schemaId);
    final originJson = jsonDecode(architectureVersionsJson(restored)) as List;
    expect(originJson.first['snapshot'], originJson.last['snapshot']);
    expect(stripVersions(restored), stripVersions(renamed));
    expect(oeeRecordsJson(restored), oeeRecordsJson(seeded));
    expect(findAsset(restored, 'n4')!.name, 'Línia reanomenada');
    expect(findAsset(restored, 'n4')!.functions, [IsaFunction.l3]);
  });

  test('un cicle de versions es rebutja i un cicle de flux es conserva', () {
    final workspace = foodIndustryExample();
    final decoded =
        jsonDecode(workspaceToJson(workspace)) as Map<String, Object?>;
    final stamp = '2026-01-01T00:00:00.000Z';
    decoded['architectureVersions'] = [
      {
        'id': 'n40',
        'schemaId': 'n20',
        'createdAt': stamp,
        'note': 'A',
        'parentVersionId': 'n41',
        'snapshot': _snapshotRow(workspace),
      },
      {
        'id': 'n41',
        'schemaId': 'n20',
        'createdAt': stamp,
        'note': 'B',
        'parentVersionId': 'n40',
        'snapshot': _snapshotRow(workspace),
      },
    ];
    decoded['nextIdCounter'] = 42;
    final cycled = workspaceFromJson(jsonEncode(decoded));
    expect(cycled.workspace, isNull);
    expect(
      cycled.issues.map((issue) => issue.code),
      contains(WorkspaceIssueCode.cycle),
    );

    final flows = addFlow(
      workspace,
      name: 'Anada',
      sourceId: 'n16',
      targetId: 'n17',
      exchangedData: 'Ordres',
      protocol: null,
      purpose: 'Enviar',
      now: now,
    ).workspace!;
    final back = addFlow(
      flows,
      name: 'Tornada',
      sourceId: 'n17',
      targetId: 'n16',
      exchangedData: 'Estat',
      protocol: null,
      purpose: 'Retornar',
      status: FlowStatus.confirmed,
      now: now,
    ).workspace!;
    final imported = workspaceFromJson(workspaceToJson(back));
    expect(
      imported.isValid,
      isTrue,
      reason: imported.issues.map((issue) => issue.code.name).join(','),
    );
    expect(imported.workspace!.flows, hasLength(2));
  });

  test('una substitució interrompuda conserva el document i l\'OEE', () async {
    final database = MemoryWorkspaceDatabase();
    final repo = WorkspaceRepository(
      database: database,
      readLegacy: () async => null,
      now: () => now,
    );
    await repo.open();
    await repo.loadExample(confirm: true);
    final withOee = repo.workspace.copyWith(oeeRecords: [sampleRecord()]);
    await repo.saveWorkspace(withOee);
    final before = database.values[workspaceDocumentKey];
    final oeeBefore = oeeRecordsJson(repo.workspace);

    final replacement = workspaceToJson(createEmptyWorkspace());
    await repo.replaceWithBackup(replacement, confirm: false);
    expect(database.values[workspaceDocumentKey], before);
    expect(repo.workspace.oeeRecords, hasLength(1));

    await repo.replaceWithBackup('{', confirm: true);
    expect(repo.banner, 'El JSON no és vàlid.');
    expect(repo.status, SaveStatus.saved);
    expect(oeeRecordsJson(repo.workspace), oeeBefore);

    database.failWrites = 1;
    await repo.replaceWithBackup(replacement, confirm: true);
    expect(repo.status, SaveStatus.error);
    expect(saveStatusText(repo.status, quotaExceeded: false), isNot('Desat'));
    expect(database.values[workspaceDocumentKey], before);
    expect(oeeRecordsJson(repo.workspace), oeeBefore);

    await repo.replaceWithBackup(replacement, confirm: true);
    expect(repo.status, SaveStatus.saved);
    expect(repo.workspace.oeeRecords, isEmpty);
    expect(database.values[priorBackupKey], before);
  });
}

Map<String, Object?> _snapshotRow(Workspace workspace) {
  final decoded =
      jsonDecode(workspaceToJson(workspace)) as Map<String, Object?>;
  final schemas = decoded['schemas'] as List<Object?>;
  return {
    'schema': schemas.first,
    'organizations': decoded['organizations'],
    'assets': decoded['assets'],
    'systems': decoded['systems'],
    'flows': decoded['flows'],
  };
}
