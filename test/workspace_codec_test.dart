import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mapaisa95oee/workspace_codec.dart';
import 'package:mapaisa95oee/workspace_model.dart';

void main() {
  test('la fixture fa la volta sencera', () {
    final original = foodIndustryExample();
    final raw = workspaceToJson(original);
    final imported = workspaceFromJson(raw);
    expect(
      imported.isValid,
      isTrue,
      reason: imported.issues
          .map((issue) => '${issue.code.name}:${issue.field}')
          .join(','),
    );
    expect(workspaceToJson(imported.workspace!), raw);
    final backup = workspaceToBackupJson(
      original,
      exportedAt: DateTime.utc(2026, 2, 2),
    );
    final fromBackup = workspaceFromJson(backup);
    expect(fromBackup.isValid, isTrue);
    expect(fromBackup.workspace!.organizations.single.name, 'Alimentària Demo');
    expect(backup, contains('"formatVersion": 1'));
    expect(backup, contains('"exportedAt"'));
  });

  test('rebutja JSON invàlid, versió desconeguda i el mapa antic', () {
    expect(
      workspaceFromJson('{').issues.single.code,
      WorkspaceIssueCode.invalidJson,
    );
    expect(
      workspaceFromJson('{"formatVersion": 2}').issues.single.code,
      WorkspaceIssueCode.unsupportedVersion,
    );
    expect(
      workspaceFromJson('{"version":1,"nodes":[]}').issues.single.code,
      WorkspaceIssueCode.legacyFileNeedsMigration,
    );
    expect(
      workspaceIssueMessage(WorkspaceIssueCode.legacyFileNeedsMigration),
      contains('mapa antic'),
    );
  });

  test('rebutja IDs duplicats, orfes i cicles de jerarquia', () {
    final workspace = foodIndustryExample();
    final raw = workspaceToJson(workspace);
    final duplicate = raw.replaceFirst('"id": "n12"', '"id": "n1"');
    final duplicateImport = workspaceFromJson(duplicate);
    expect(duplicateImport.workspace, isNull);
    expect(
      duplicateImport.issues.map((issue) => issue.code),
      contains(WorkspaceIssueCode.duplicateId),
    );

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final systems = decoded['systems'] as List<dynamic>;
    (systems.first as Map<String, dynamic>)['scopeIds'] = ['missing'];
    final orphan = workspaceFromJson(jsonEncode(decoded));
    expect(orphan.workspace, isNull);
    expect(
      orphan.issues.map((issue) => issue.code),
      contains(WorkspaceIssueCode.orphanReference),
    );

    final cycled = jsonDecode(
      workspaceToJson(createEmptyWorkspace()),
    ) as Map<String, dynamic>;
    final stamp = '2026-01-01T00:00:00.000Z';
    cycled['assets'] = [
      {
        'id': 'n1',
        'name': 'A',
        'description': null,
        'kind': 'plant',
        'parentId': 'n2',
        'iconKey': 'plant',
        'functions': <String>[],
        'createdAt': stamp,
        'updatedAt': stamp,
      },
      {
        'id': 'n2',
        'name': 'B',
        'description': null,
        'kind': 'plant',
        'parentId': 'n1',
        'iconKey': 'plant',
        'functions': <String>[],
        'createdAt': stamp,
        'updatedAt': stamp,
      },
    ];
    final cycle = workspaceFromJson(jsonEncode(cycled));
    expect(cycle.workspace, isNull);
    expect(
      cycle.issues.map((issue) => issue.code),
      contains(WorkspaceIssueCode.cycle),
    );
  });

  test('accepta un cicle de flux i separa OEE del snapshot', () {
    final stamp = DateTime.utc(2026, 1, 1);
    final workspace = Workspace(
      nextIdCounter: 8,
      organizations: [
        Organization(
          id: 'n1',
          name: 'Acme',
          createdAt: stamp,
          updatedAt: stamp,
        ),
      ],
      assets: [
        Asset(
          id: 'n2',
          name: 'Girona',
          kind: AssetKind.plant,
          parentId: 'n1',
          iconKey: IconKey.plant,
          createdAt: stamp,
          updatedAt: stamp,
        ),
      ],
      systems: [
        WorkSystem(
          id: 'n3',
          name: 'ERP',
          systemType: SystemType.erp,
          iconKey: IconKey.erp,
          scopeIds: const ['n2'],
          functions: const [IsaFunction.l4],
          zone: ItOtZone.it,
          createdAt: stamp,
          updatedAt: stamp,
        ),
        WorkSystem(
          id: 'n4',
          name: 'MES',
          systemType: SystemType.mes,
          iconKey: IconKey.mes,
          scopeIds: const ['n2'],
          functions: const [IsaFunction.l3],
          zone: ItOtZone.boundary,
          createdAt: stamp,
          updatedAt: stamp,
        ),
      ],
      flows: [
        ExchangeFlow(
          id: 'n5',
          name: 'Anada',
          sourceId: 'n3',
          targetId: 'n4',
          exchangedData: 'Ordres',
          protocol: null,
          purpose: 'Enviar',
          status: FlowStatus.suggested,
          createdAt: stamp,
          updatedAt: stamp,
        ),
        ExchangeFlow(
          id: 'n6',
          name: 'Tornada',
          sourceId: 'n4',
          targetId: 'n3',
          exchangedData: 'Confirmació',
          protocol: 'OPC UA',
          purpose: 'Retornar',
          status: FlowStatus.confirmed,
          createdAt: stamp,
          updatedAt: stamp,
        ),
      ],
      oeeRecords: [
        OeeRecord(
          id: 'n7',
          productionDate: '2026-03-01',
          shift: 'Matí',
          lineId: 'retirada',
          article: 'Iogurt',
          lot: null,
          plannedMinutes: 480,
          downtimeMinutes: 0,
          speedOriginal: 1,
          speedUnit: SpeedUnit.secondsPerUnit,
          idealCycleSeconds: 1,
          totalUnits: 10,
          goodUnits: 9,
          status: OeeRecordStatus.draft,
          formulaVersion: 'oee.v1',
          capturedLineName: 'Línia antiga',
          capturedPlantName: 'Girona',
          createdAt: stamp,
          updatedAt: stamp,
        ),
      ],
    );
    final imported = workspaceFromJson(workspaceToJson(workspace));
    expect(
      imported.isValid,
      isTrue,
      reason: imported.issues.map((issue) => issue.code.name).join(','),
    );
    expect(imported.workspace!.flows, hasLength(2));
    expect(imported.workspace!.oeeRecords.single.lineId, 'retirada');

    final decoded =
        jsonDecode(workspaceToJson(workspace)) as Map<String, dynamic>;
    decoded['architectureVersions'] = [
      {
        'id': 'n8',
        'schemaId': 'n9',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'note': 'Nota',
        'parentVersionId': null,
        'snapshot': {
          'schema': {
            'id': 'n9',
            'name': 'Antic',
            'description': null,
            'plantIds': <String>[],
            'assetIds': <String>[],
            'systemIds': <String>[],
            'flowIds': <String>[],
            'layout': <String, Object>{},
            'createdAt': '2026-01-01T00:00:00.000Z',
            'updatedAt': '2026-01-01T00:00:00.000Z',
          },
          'organizations': <Object>[],
          'assets': <Object>[],
          'systems': <Object>[],
          'flows': <Object>[],
          'oeeRecords': <Object>[],
        },
      },
    ];
    final mixed = workspaceFromJson(jsonEncode(decoded));
    expect(mixed.workspace, isNull);
    expect(
      mixed.issues.map((issue) => issue.code),
      contains(WorkspaceIssueCode.invalidField),
    );
  });

  test('les instantànies i la restauració fan la volta sencera', () {
    final now = DateTime.utc(2026, 6, 1);
    final created = createVersion(
      foodIndustryExample(),
      schemaId: 'n20',
      note: 'Base',
      now: now,
    ).workspace!;
    final source = created.versions.single.id;
    final deleted = deleteEntity(created, id: 'n5', confirm: true).workspace!;
    final restored = restoreVersion(
      deleted,
      versionId: source,
      note: 'Torna',
      now: now,
      confirm: true,
    ).workspace!;
    final raw = workspaceToJson(restored);
    final imported = workspaceFromJson(raw);
    expect(
      imported.isValid,
      isTrue,
      reason: imported.issues
          .map((issue) => '${issue.code.name}:${issue.field}')
          .join(','),
    );
    expect(workspaceToJson(imported.workspace!), raw);
    expect(imported.workspace!.versions, hasLength(2));
    expect(imported.workspace!.schemas, hasLength(2));
    expect(findAsset(imported.workspace!, 'n5'), isNotNull);
  });
}
