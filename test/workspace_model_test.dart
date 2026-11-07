import 'package:flutter_test/flutter_test.dart';
import 'package:mapaisa95oee/workspace_codec.dart';
import 'package:mapaisa95oee/workspace_model.dart';

void main() {
  final now = DateTime.utc(2026, 6, 1);

  Workspace apply(WorkspaceMutation mutation) {
    expect(
      mutation.issues,
      isEmpty,
      reason: mutation.issues.map((issue) => issue.code).join(','),
    );
    return mutation.workspace!;
  }

  test('rebutja el nom buit i no muta', () {
    final workspace = createEmptyWorkspace();
    final mutation = addOrganization(workspace, name: '   ', now: now);
    expect(mutation.workspace, isNull);
    expect(mutation.issues, [
      const WorkspaceIssue(WorkspaceIssueCode.emptyName, field: 'name'),
    ]);
    expect(workspace.organizations, isEmpty);
  });

  test('rebutja un pare incompatible i un cicle', () {
    var workspace = apply(
      addOrganization(createEmptyWorkspace(), name: 'Acme', now: now),
    );
    final area = addAsset(
      workspace,
      kind: AssetKind.area,
      parentId: 'n1',
      name: 'Envasat',
      now: now,
    );
    expect(
      area.issues,
      contains(
        const WorkspaceIssue(
          WorkspaceIssueCode.incompatibleParent,
          field: 'parentId',
        ),
      ),
    );
    expect(area.workspace, isNull);

    workspace = Workspace(
      nextIdCounter: 3,
      assets: [
        Asset(
          id: 'n1',
          name: 'A',
          kind: AssetKind.plant,
          parentId: 'n2',
          iconKey: IconKey.plant,
          createdAt: now,
          updatedAt: now,
        ),
        Asset(
          id: 'n2',
          name: 'B',
          kind: AssetKind.plant,
          parentId: 'n1',
          iconKey: IconKey.plant,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
    final cycle = updateAsset(
      workspace,
      id: 'n1',
      name: 'A',
      parentId: 'n2',
      now: now,
    );
    expect(cycle.workspace, isNull);
    expect(
      cycle.issues.map((issue) => issue.code),
      contains(WorkspaceIssueCode.cycle),
    );
    expect(
      cycle.issues.map((issue) => issue.code),
      contains(WorkspaceIssueCode.incompatibleParent),
    );
  });

  test('l\'ID es manté en reanomenar', () {
    var workspace = apply(
      addOrganization(createEmptyWorkspace(), name: 'Acme', now: now),
    );
    workspace = apply(
      updateOrganization(
        workspace,
        id: 'n1',
        name: 'Acme Nord',
        description: 'Nota',
        now: now,
      ),
    );
    expect(workspace.organizations.single.id, 'n1');
    expect(workspace.organizations.single.name, 'Acme Nord');
    expect(workspace.nextIdCounter, 2);
  });

  test('un ERP o MES amb abast a dues línies no mou els actius', () {
    var workspace = apply(
      addOrganization(createEmptyWorkspace(), name: 'Acme', now: now),
    );
    workspace = apply(
      addAsset(
        workspace,
        kind: AssetKind.plant,
        parentId: 'n1',
        name: 'Girona',
        now: now,
      ),
    );
    workspace = apply(
      addAsset(
        workspace,
        kind: AssetKind.plant,
        parentId: 'n1',
        name: 'Lleida',
        now: now,
      ),
    );
    workspace = apply(
      addAsset(
        workspace,
        kind: AssetKind.area,
        parentId: 'n2',
        name: 'Envasat',
        now: now,
      ),
    );
    workspace = apply(
      addAsset(
        workspace,
        kind: AssetKind.area,
        parentId: 'n3',
        name: 'Elaboració',
        now: now,
      ),
    );
    workspace = apply(
      addAsset(
        workspace,
        kind: AssetKind.line,
        parentId: 'n4',
        name: 'Línia A',
        now: now,
      ),
    );
    workspace = apply(
      addAsset(
        workspace,
        kind: AssetKind.line,
        parentId: 'n5',
        name: 'Línia B',
        now: now,
      ),
    );
    final parents = {
      for (final asset in workspace.assets) asset.id: asset.parentId,
    };
    workspace = apply(
      addSystem(
        workspace,
        name: 'MES compartit',
        systemType: SystemType.mes,
        scopeIds: const ['n6', 'n7'],
        functions: const [IsaFunction.l1, IsaFunction.l3],
        zone: ItOtZone.ot,
        now: now,
      ),
    );
    final system = workspace.systems.single;
    expect(system.systemType, SystemType.mes);
    expect(system.functions, [IsaFunction.l1, IsaFunction.l3]);
    expect(system.scopeIds, ['n6', 'n7']);
    workspace = apply(
      updateSystemScope(
        workspace,
        id: system.id,
        scopeIds: const ['n6'],
        now: now,
      ),
    );
    expect(workspace.systems.single.scopeIds, ['n6']);
    expect(workspace.systems.single.functions, [
      IsaFunction.l1,
      IsaFunction.l3,
    ]);
    expect({
      for (final asset in workspace.assets) asset.id: asset.parentId,
    }, parents);

    final blocked = assignFunctions(
      workspace,
      id: 'n1',
      functions: const [IsaFunction.l4],
      now: now,
    );
    expect(blocked.workspace, isNull);
    expect(
      blocked.issues.single.code,
      WorkspaceIssueCode.functionsNotAssignable,
    );
    expect(findOrganization(workspace, 'n1'), isNotNull);
    expect(
      workspace.systems.where((item) => item.systemType == SystemType.erp),
      isEmpty,
    );
  });

  test('canviar la icona no assigna funcions ni fluxos', () {
    var workspace = apply(
      addOrganization(createEmptyWorkspace(), name: 'Acme', now: now),
    );
    workspace = apply(
      addAsset(
        workspace,
        kind: AssetKind.plant,
        parentId: 'n1',
        name: 'Girona',
        now: now,
      ),
    );
    workspace = apply(
      addAsset(
        workspace,
        kind: AssetKind.area,
        parentId: 'n2',
        name: 'Envasat',
        now: now,
      ),
    );
    workspace = apply(
      addAsset(
        workspace,
        kind: AssetKind.line,
        parentId: 'n3',
        name: 'Línia',
        now: now,
      ),
    );
    workspace = apply(
      addAsset(
        workspace,
        kind: AssetKind.machine,
        parentId: 'n4',
        name: 'Omplidora',
        now: now,
      ),
    );
    workspace = apply(
      updateAsset(
        workspace,
        id: 'n5',
        name: 'Omplidora',
        description: null,
        iconKey: IconKey.line,
        now: now,
      ),
    );
    final machine = findAsset(workspace, 'n5')!;
    expect(machine.kind, AssetKind.machine);
    expect(machine.iconKey, IconKey.line);
    expect(machine.functions, isEmpty);
    expect(workspace.flows, isEmpty);
  });

  test('eliminar exigeix confirmació i no deixa orfes actius', () {
    var workspace = apply(
      addOrganization(createEmptyWorkspace(), name: 'Acme', now: now),
    );
    workspace = apply(
      addAsset(
        workspace,
        kind: AssetKind.plant,
        parentId: 'n1',
        name: 'Girona',
        now: now,
      ),
    );
    workspace = apply(
      addAsset(
        workspace,
        kind: AssetKind.area,
        parentId: 'n2',
        name: 'Envasat',
        now: now,
      ),
    );
    workspace = apply(
      addAsset(
        workspace,
        kind: AssetKind.line,
        parentId: 'n3',
        name: 'Línia iogurt',
        now: now,
      ),
    );
    workspace = apply(
      addAsset(
        workspace,
        kind: AssetKind.machine,
        parentId: 'n4',
        name: 'Omplidora',
        now: now,
      ),
    );
    workspace = apply(
      addSystem(
        workspace,
        name: 'PLC',
        systemType: SystemType.plc,
        scopeIds: const ['n5'],
        functions: const [IsaFunction.l1],
        zone: ItOtZone.ot,
        now: now,
      ),
    );
    workspace = apply(
      addFlow(
        workspace,
        name: 'Consigne',
        sourceId: 'n6',
        targetId: 'n5',
        exchangedData: 'Consigne',
        purpose: 'Comandar',
        now: now,
      ),
    );
    final stamp = now;
    final schema = WorkSchema(
      id: 'n8',
      name: 'Esquema',
      assetIds: const ['n4', 'n5'],
      systemIds: const ['n6'],
      flowIds: const ['n7'],
      createdAt: stamp,
      updatedAt: stamp,
    );
    final snapshotSchema = WorkSchema(
      id: 'n8',
      name: 'Esquema',
      assetIds: const ['n4'],
      createdAt: stamp,
      updatedAt: stamp,
    );
    final version = ArchitectureVersion(
      id: 'n9',
      schemaId: 'n8',
      createdAt: stamp,
      note: 'Captura',
      parentVersionId: null,
      snapshot: ArchitectureSnapshot(
        schema: snapshotSchema,
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
          Asset(
            id: 'n3',
            name: 'Envasat',
            kind: AssetKind.area,
            parentId: 'n2',
            iconKey: IconKey.area,
            createdAt: stamp,
            updatedAt: stamp,
          ),
          Asset(
            id: 'n4',
            name: 'Línia iogurt',
            kind: AssetKind.line,
            parentId: 'n3',
            iconKey: IconKey.line,
            createdAt: stamp,
            updatedAt: stamp,
          ),
        ],
      ),
    );
    final record = OeeRecord(
      id: 'n10',
      productionDate: '2026-06-01',
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
      status: OeeRecordStatus.draft,
      formulaVersion: 'oee.v1',
      capturedLineName: 'Línia iogurt',
      capturedPlantName: 'Planta Girona',
      createdAt: stamp,
      updatedAt: stamp,
    );
    workspace = workspace.copyWith(
      nextIdCounter: 11,
      schemas: [schema],
      versions: [version],
      oeeRecords: [record],
    );
    final versionsBefore = architectureVersionsJson(workspace);
    final oeeBefore = oeeRecordsJson(workspace);
    final cancelled = deleteEntity(workspace, id: 'n4');
    expect(cancelled.workspace, isNull);
    expect(
      cancelled.issues.single.code,
      WorkspaceIssueCode.confirmationRequired,
    );
    expect(cancelled.dependencies!.childIds, ['n5']);
    expect(cancelled.dependencies!.flowIds, ['n7']);
    expect(cancelled.dependencies!.schemaIds, ['n8']);
    expect(cancelled.dependencies!.retainedOeeRecordIds, ['n10']);
    expect(cancelled.dependencies!.retainedSnapshotIds, ['n9']);
    expect(architectureVersionsJson(workspace), versionsBefore);
    expect(oeeRecordsJson(workspace), oeeBefore);

    final removed = apply(deleteEntity(workspace, id: 'n4', confirm: true));
    expect(findAsset(removed, 'n4'), isNull);
    expect(findAsset(removed, 'n5'), isNull);
    expect(findFlow(removed, 'n7'), isNull);
    expect(findSystem(removed, 'n6')!.scopeIds, isEmpty);
    expect(removed.schemas.single.assetIds, isEmpty);
    expect(removed.schemas.single.flowIds, isEmpty);
    expect(removed.oeeRecords.single.capturedLineName, 'Línia iogurt');
    expect(architectureVersionsJson(removed), versionsBefore);
    expect(oeeRecordsJson(removed), oeeBefore);
    final reloaded = workspaceFromJson(workspaceToJson(removed));
    expect(
      reloaded.isValid,
      isTrue,
      reason: reloaded.issues.map((issue) => issue.code.name).join(','),
    );
  });

  test('reanomenar una línia no reescriu captures', () {
    final stamp = now;
    final workspace = Workspace(
      nextIdCounter: 5,
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
        Asset(
          id: 'n3',
          name: 'Envasat',
          kind: AssetKind.area,
          parentId: 'n2',
          iconKey: IconKey.area,
          createdAt: stamp,
          updatedAt: stamp,
        ),
        Asset(
          id: 'n4',
          name: 'Línia iogurt',
          kind: AssetKind.line,
          parentId: 'n3',
          iconKey: IconKey.line,
          createdAt: stamp,
          updatedAt: stamp,
        ),
      ],
      oeeRecords: [
        OeeRecord(
          id: 'n5',
          productionDate: '2026-06-01',
          shift: 'Matí',
          lineId: 'n4',
          article: 'Iogurt',
          lot: 'L-1',
          plannedMinutes: 1,
          downtimeMinutes: 0,
          speedOriginal: 1,
          speedUnit: SpeedUnit.unitsPerSecond,
          idealCycleSeconds: 1,
          totalUnits: 1,
          goodUnits: 1,
          status: OeeRecordStatus.validated,
          formulaVersion: 'oee.v1',
          capturedLineName: 'Línia iogurt',
          capturedPlantName: 'Girona',
          createdAt: stamp,
          updatedAt: stamp,
        ),
      ],
    );
    final before = oeeRecordsJson(workspace);
    final renamed = apply(
      updateAsset(workspace, id: 'n4', name: 'Línia nova', now: now),
    );
    expect(findAsset(renamed, 'n4')!.name, 'Línia nova');
    expect(findAsset(renamed, 'n4')!.id, 'n4');
    expect(oeeRecordsJson(renamed), before);
  });

  test('la fixture alimentaria no iguala empresa amb L4 ni línia amb L2', () {
    final workspace = foodIndustryExample();
    final organization = workspace.organizations.single;
    expect(organization.id, 'n1');
    expect(organization.name, 'Alimentària Demo');
    expect(workspace.systems.map((system) => system.id), isNot(contains('n1')));
    expect(findAsset(workspace, 'n4')!.functions, isEmpty);
    expect(findAsset(workspace, 'n11')!.kind, AssetKind.machine);
    expect(findAsset(workspace, 'n11')!.functions, isEmpty);
    final erp = findSystem(workspace, 'n16')!;
    expect(erp.systemType, SystemType.erp);
    expect(erp.scopeIds, ['n2', 'n12']);
    expect(erp.functions, [IsaFunction.l4]);
    final mes = findSystem(workspace, 'n17')!;
    expect(mes.scopeIds, ['n4', 'n7']);
    expect(mes.functions, [IsaFunction.l3]);
    expect(findSystem(workspace, 'n18')!.functions, [
      IsaFunction.l1,
      IsaFunction.l2,
    ]);
    expect(findSystem(workspace, 'n19')!.systemType, SystemType.other);
    expect(findSystem(workspace, 'n19')!.functions, [
      IsaFunction.l2,
      IsaFunction.l3,
    ]);
    expect(workspace.flows, isEmpty);
    expect(workspace.versions, isEmpty);
    expect(workspace.oeeRecords, isEmpty);
    expect(isaFunctionLabel(IsaFunction.l4), isNot('ERP'));
    expect(isaFunctionLabel(IsaFunction.l3), isNot('MES'));
    for (final asset in workspace.assets) {
      expect(asset.functions, isEmpty);
    }
  });
}
