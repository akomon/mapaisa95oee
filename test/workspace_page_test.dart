import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapaisa95oee/plant_store.dart';
import 'package:mapaisa95oee/workspace_codec.dart';
import 'package:mapaisa95oee/workspace_database.dart';
import 'package:mapaisa95oee/workspace_database_memory.dart';
import 'package:mapaisa95oee/workspace_model.dart';
import 'package:mapaisa95oee/workspace_page.dart';
import 'package:mapaisa95oee/workspace_phase_c.dart';
import 'package:mapaisa95oee/workspace_repository.dart';

void main() {
  final now = DateTime.utc(2026, 9, 2, 9);

  Future<WorkspaceRepository> open({
    Map<String, String>? legacy,
    bool example = false,
    MemoryWorkspaceDatabase? database,
  }) async {
    final repo = WorkspaceRepository(
      database: database ?? MemoryWorkspaceDatabase(),
      readLegacy: () async => legacy?[plantStorageKey],
      now: () => now,
    );
    await repo.open();
    if (example) {
      await repo.loadExample(confirm: true);
    }
    return repo;
  }

  Future<void> surface(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> pumpPage(
    WidgetTester tester,
    WorkspaceRepository repo, {
    Size size = const Size(1280, 800),
    VoidCallback? onOpenOee,
  }) async {
    await surface(tester, size);
    await tester.pumpWidget(
      MaterialApp(
        home: WorkspacePage(
          repository: repo,
          onOpenOee: onOpenOee ?? () {},
          onOpenData: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<Finder> revealTree(WidgetTester tester, String id) async {
    final tile = find.byKey(Key('tree-$id'), skipOffstage: false);
    expect(tile, findsOneWidget);
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    return find.byKey(Key('tree-$id'));
  }

  Future<void> select(WidgetTester tester, String id) async {
    final tile = await revealTree(tester, id);
    tester.widget<ListTile>(tile).onTap!.call();
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('a 1280 el mapa mostra l\'exemple sense barrejar nivells', (
    tester,
  ) async {
    final repo = await open(example: true);
    await pumpPage(tester, repo);

    expect(find.byKey(workspaceTreeKey), findsOneWidget);
    expect(find.byKey(workspaceMapKey), findsOneWidget);
    expect(find.byKey(workspaceInspectorKey), findsOneWidget);
    final tree = tester.getRect(find.byKey(workspaceTreeKey));
    final map = tester.getRect(find.byKey(workspaceMapKey));
    final inspector = tester.getRect(find.byKey(workspaceInspectorKey));
    expect(tree.left, lessThan(map.left));
    expect(map.left, lessThan(inspector.left));
    expect(inspector.right, lessThanOrEqualTo(1280));

    final organization = tester.widget<ListTile>(
      find.byKey(const Key('tree-n1')),
    );
    expect((organization.subtitle as Text).data, 'Organització');
    final line = tester.widget<ListTile>(find.byKey(const Key('tree-n4')));
    expect((line.subtitle as Text).data, 'Línia');
    expect(find.byKey(mapL3ExplanationKey), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('map-n16')),
        matching: find.textContaining('Zona: IT'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('map-n16')),
        matching: find.textContaining('Planificació empresarial'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('map-n17')),
        matching: find.textContaining('Zona: Frontera'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('map-n18')),
        matching: find.textContaining('Sensat i actuació'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('map-n18')),
        matching: find.textContaining('Control'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('map-n19')),
        matching: find.textContaining('Zona: IT'),
      ),
      findsOneWidget,
    );
    expect(repo.workspace.flows, isEmpty);
    expect(
      find.textContaining('Un abast compartit no crea un flux.'),
      findsOneWidget,
    );
    expect(find.text('Desat'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(workspaceZoomInKey)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('canviar la selecció conserva planta i esquema', (tester) async {
    final repo = await open(example: true);
    await pumpPage(tester, repo);
    expect(find.text('Esquema: Esquema alimentari'), findsOneWidget);

    await select(tester, 'n4');
    expect(find.textContaining('Identificador n4'), findsOneWidget);
    expect(find.byKey(isaFunctionsKey), findsOneWidget);
    expect(find.text('Planta Girona'), findsWidgets);

    await select(tester, 'n1');
    expect(find.byKey(isaFunctionsKey), findsNothing);
    expect(find.textContaining('Sense funció ISA-95'), findsWidgets);
    expect(find.text('Esquema: Esquema alimentari'), findsOneWidget);
    expect(find.text('Planta Girona'), findsWidgets);

    await tester.tap(find.byType(DropdownButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Planta Lleida').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('map-n17')), findsNothing);
    expect(find.byKey(const Key('map-n16')), findsOneWidget);
    expect(find.textContaining('Identificador n1'), findsOneWidget);
  });

  testWidgets('el teclat selecciona, edita, confirma i cancel·la', (
    tester,
  ) async {
    final repo = await open(example: true);
    await pumpPage(tester, repo);

    final systemTile = await revealTree(tester, 'n16');
    final tile = tester.widget<ListTile>(systemTile);
    tile.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.textContaining('Identificador n16'), findsOneWidget);
    expect(find.byKey(isaFunctionsKey), findsOneWidget);

    await select(tester, 'n1');
    final name = tester.widget<TextField>(find.byKey(workspaceNameFieldKey));
    name.focusNode!.requestFocus();
    await tester.pump();
    expect(tester.binding.focusManager.primaryFocus, name.focusNode);
    await tester.enterText(find.byKey(workspaceNameFieldKey), 'Grup nou');
    final save = tester.widget<FilledButton>(find.byKey(workspaceSaveEditKey));
    save.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(findOrganization(repo.workspace, 'n1')!.name, 'Grup nou');
    expect(findOrganization(repo.workspace, 'n1')!.id, 'n1');

    await select(tester, 'n3');
    await reveal(tester, find.byKey(workspaceDeleteKey, skipOffstage: false));
    await tester.tap(find.byKey(workspaceDeleteKey));
    await tester.pumpAndSettle();
    expect(find.textContaining('Fills:'), findsOneWidget);
    expect(
      find.textContaining('No s\'esborren les instantànies'),
      findsOneWidget,
    );
    final cancel = tester.widget<TextButton>(
      find.byKey(workspaceCancelDeleteKey),
    );
    cancel.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(findAsset(repo.workspace, 'n3'), isNotNull);
    expect(findAsset(repo.workspace, 'n4'), isNotNull);

    await reveal(tester, find.byKey(workspaceDeleteKey, skipOffstage: false));
    await tester.tap(find.byKey(workspaceDeleteKey));
    await tester.pumpAndSettle();
    final confirm = tester.widget<TextButton>(
      find.byKey(workspaceConfirmDeleteKey),
    );
    confirm.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(findAsset(repo.workspace, 'n3'), isNull);
    expect(findAsset(repo.workspace, 'n4'), isNull);
    expect(repo.workspace.oeeRecords, isEmpty);
    expect(repo.workspace.versions, isEmpty);
    expect(find.text('Desat'), findsOneWidget);
  });

  testWidgets('rebutja el nom buit i el pare incompatible al camp', (
    tester,
  ) async {
    final repo = await open();
    await pumpPage(tester, repo);

    await tester.tap(find.byKey(workspaceAddKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Organització'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(workspaceSaveEditKey));
    await tester.pumpAndSettle();
    expect(find.textContaining('El nom no pot ser buit.'), findsOneWidget);
    expect(repo.workspace.organizations, isEmpty);

    await tester.enterText(find.byKey(workspaceNameFieldKey), 'Nova');
    await tester.tap(find.byKey(workspaceSaveEditKey));
    await tester.pumpAndSettle();
    expect(find.textContaining('Identificador n1'), findsOneWidget);
    await tester.enterText(
      find.byKey(workspaceNameFieldKey),
      'Nova planta mare',
    );
    final save = tester.widget<FilledButton>(find.byKey(workspaceSaveEditKey));
    save.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(findOrganization(repo.workspace, 'n1')!.name, 'Nova planta mare');

    await tester.tap(find.byKey(workspaceAddKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Màquina').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(workspaceNameFieldKey), 'Sense línia');
    await tester.scrollUntilVisible(
      find.byKey(workspaceSaveEditKey),
      120,
      scrollable: find
          .descendant(
            of: find.byKey(workspaceInspectorKey),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(workspaceSaveEditKey));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('El pare no és compatible amb aquest element.'),
      findsOneWidget,
    );
    expect(repo.workspace.assets, isEmpty);
  });

  testWidgets('l\'abast no mou actius i el flux no s\'inventa', (tester) async {
    final repo = await open(example: true);
    final parents = {
      for (final asset in repo.workspace.assets) asset.id: asset.parentId,
    };
    await pumpPage(tester, repo);
    await select(tester, 'n16');
    final scope = find.byKey(const Key('scope-n4'), skipOffstage: false);
    expect(scope, findsOneWidget);
    tester.widget<CheckboxListTile>(scope).onChanged!(true);
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(workspaceSaveEditKey, skipOffstage: false));
    await tester.tap(find.byKey(workspaceSaveEditKey));
    await tester.pumpAndSettle();
    expect(findSystem(repo.workspace, 'n16')!.scopeIds, contains('n4'));
    expect(findSystem(repo.workspace, 'n16')!.scopeIds, contains('n2'));
    expect(findSystem(repo.workspace, 'n16')!.scopeIds, contains('n12'));
    for (final asset in repo.workspace.assets) {
      expect(asset.parentId, parents[asset.id]);
    }
    expect(repo.workspace.flows, isEmpty);

    final addFlow = find.ancestor(
      of: find.text('Afegeix flux', skipOffstage: false),
      matching: find.byType(OutlinedButton),
    );
    tester.widget<OutlinedButton>(addFlow).onPressed!.call();
    await tester.pumpAndSettle();
    tester
            .widget<TextField>(
              find.byKey(workspaceNameFieldKey, skipOffstage: false),
            )
            .controller!
            .text =
        'Ordres';
    tester
            .widget<TextField>(
              find.byKey(workspaceFlowDataKey, skipOffstage: false),
            )
            .controller!
            .text =
        'Ordres de producció';
    tester
            .widget<TextField>(
              find.byKey(workspaceFlowPurposeKey, skipOffstage: false),
            )
            .controller!
            .text =
        'Enviar el pla';
    await tester.pump();
    expect(find.text('Protocol desconegut'), findsOneWidget);
    expect(find.text('Estat: Suggerit'), findsOneWidget);
    await reveal(tester, find.byKey(workspaceSaveEditKey, skipOffstage: false));
    await tester.tap(find.byKey(workspaceSaveEditKey));
    await tester.pumpAndSettle();

    expect(repo.workspace.flows, hasLength(1));
    final flow = repo.workspace.flows.single;
    expect(flow.sourceId, 'n16');
    expect(flow.targetId, 'n17');
    expect(flow.protocol, isNull);
    expect(flow.status, FlowStatus.suggested);
    expect(flow.exchangedData, 'Ordres de producció');
    expect(find.textContaining('Suggerit'), findsWidgets);

    tester
        .widget<OutlinedButton>(
          find.ancestor(
            of: find.text('Confirmat', skipOffstage: false),
            matching: find.byType(OutlinedButton),
          ),
        )
        .onPressed!
        .call();
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(workspaceSaveEditKey, skipOffstage: false));
    await tester.tap(find.byKey(workspaceSaveEditKey));
    await tester.pumpAndSettle();
    expect(repo.workspace.flows.single.status, FlowStatus.confirmed);
    expect(find.textContaining('Confirmat'), findsWidgets);
    expect(repo.workspace.flows.single.id, flow.id);
  });

  testWidgets('desa a IndexedDB i la clau legacy no es toca', (tester) async {
    final legacy = <String, String>{};
    final database = MemoryWorkspaceDatabase();
    final repo = await open(legacy: legacy, database: database);
    await pumpPage(tester, repo);
    await tester.tap(find.byKey(workspaceAddKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Organització'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(workspaceNameFieldKey), 'Persistida');
    await tester.tap(find.byKey(workspaceSaveEditKey));
    await tester.pumpAndSettle();

    expect(legacy, isEmpty);
    final again = WorkspaceRepository(
      database: database,
      readLegacy: () async => legacy[plantStorageKey],
      now: () => now,
    );
    await again.open();
    expect(again.workspace.organizations.single.name, 'Persistida');
    expect(again.workspace.organizations.single.id, 'n1');
    final backup = again.exportBackupJson();
    final restored = workspaceFromJson(backup);
    expect(restored.workspace!.organizations.single.name, 'Persistida');
  });

  testWidgets('a 360 els panells es pleguen i no hi ha overflow', (
    tester,
  ) async {
    final repo = await open(example: true);
    await pumpPage(tester, repo, size: const Size(360, 800));

    expect(tester.takeException(), isNull);
    expect(find.byKey(workspaceTreeKey), findsNothing);
    expect(find.byKey(workspaceInspectorKey), findsNothing);
    expect(find.byKey(workspaceMapKey), findsOneWidget);
    expect(find.byKey(workspaceTreeToggleKey), findsOneWidget);
    expect(find.byKey(workspaceInspectorToggleKey), findsOneWidget);

    await reveal(
      tester,
      find.byKey(workspaceTreeToggleKey, skipOffstage: false),
    );
    await tester.tap(find.byKey(workspaceTreeToggleKey));
    await tester.pumpAndSettle();
    expect(find.byKey(workspaceTreeKey), findsOneWidget);
    expect(find.byKey(workspaceMapKey), findsOneWidget);
    expect(tester.takeException(), isNull);

    await reveal(
      tester,
      find.byKey(workspaceInspectorToggleKey, skipOffstage: false),
    );
    await tester.tap(find.byKey(workspaceInspectorToggleKey));
    await tester.pumpAndSettle();
    expect(find.byKey(workspaceInspectorKey), findsOneWidget);
    final name = find.byKey(workspaceNameFieldKey);
    if (name.evaluate().isNotEmpty) {
      expect(tester.getSize(name).width, lessThan(360));
    }
    expect(tester.takeException(), isNull);
    expect(find.text('Desat'), findsOneWidget);
  });

  testWidgets('la plantilla es previsualitza i no assigna funcions ni fluxos', (
    tester,
  ) async {
    final repo = await open(example: true);
    await pumpPage(tester, repo);
    await select(tester, 'n4');
    await reveal(tester, find.byKey(workspaceTemplateKey, skipOffstage: false));
    await tester.tap(find.byKey(workspaceTemplateKey));
    await tester.pumpAndSettle();
    expect(find.text('Icona: Màquina'), findsWidgets);
    expect(find.textContaining('Omplidora'), findsWidgets);
    expect(find.textContaining('Taponadora'), findsWidgets);
    expect(
      tester.getSize(find.byKey(cancelTemplateKey)).height,
      greaterThanOrEqualTo(48),
    );

    final cancel = tester.widget<TextButton>(find.byKey(cancelTemplateKey));
    cancel.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(repo.workspace.assets, hasLength(14));
    expect(repo.workspace.flows, isEmpty);

    await reveal(tester, find.byKey(workspaceTemplateKey, skipOffstage: false));
    await tester.tap(find.byKey(workspaceTemplateKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(applyTemplateKey));
    await tester.pumpAndSettle();
    final created = repo.workspace.assets.where(
      (asset) => asset.id == 'n21' || asset.id == 'n22',
    );
    expect(created.map((asset) => asset.parentId), ['n4', 'n4']);
    expect(created.every((asset) => asset.functions.isEmpty), isTrue);
    expect(created.every((asset) => asset.iconKey == IconKey.machine), isTrue);
    expect(repo.workspace.flows, isEmpty);

    await select(tester, 'n21');
    final icon = find.byType(DropdownButton<IconKey>, skipOffstage: false);
    await reveal(tester, icon);
    tester.widget<DropdownButton<IconKey>>(icon).onChanged!(IconKey.line);
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(workspaceSaveEditKey, skipOffstage: false));
    await tester.tap(find.byKey(workspaceSaveEditKey));
    await tester.pumpAndSettle();
    expect(findAsset(repo.workspace, 'n21')!.iconKey, IconKey.line);
    expect(findAsset(repo.workspace, 'n21')!.functions, isEmpty);
    expect(findAsset(repo.workspace, 'n21')!.kind, AssetKind.machine);
    expect(repo.workspace.flows, isEmpty);
  });

  testWidgets('cada suggeriment es descarta o es confirma sol', (tester) async {
    final repo = await open(example: true);
    await pumpPage(tester, repo);
    await reveal(tester, find.byKey(workspaceSuggestKey, skipOffstage: false));
    await tester.tap(find.byKey(workspaceSuggestKey));
    await tester.pumpAndSettle();
    expect(repo.workspace.flows, isEmpty);
    expect(
      find.textContaining('Suggeriment: ERP corporatiu → Planta Girona'),
      findsOneWidget,
    );

    await reveal(
      tester,
      find.byKey(const Key('discard-suggestion-n16>n2'), skipOffstage: false),
    );
    await tester.tap(find.byKey(const Key('discard-suggestion-n16>n2')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Suggeriment: ERP corporatiu → Planta Girona'),
      findsNothing,
    );
    expect(repo.workspace.flows, isEmpty);
    expect(
      find.textContaining(
        'Suggeriment: ERP corporatiu → Planta Lleida',
        skipOffstage: false,
      ),
      findsOneWidget,
    );

    await reveal(
      tester,
      find.byKey(const Key('confirm-suggestion-n16>n12'), skipOffstage: false),
    );
    await tester.tap(find.byKey(const Key('confirm-suggestion-n16>n12')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(suggestionDataKey), 'Ordres');
    await tester.enterText(find.byKey(suggestionPurposeKey), 'Enviar el pla');
    await tester.tap(find.byKey(confirmSuggestionDialogKey));
    await tester.pumpAndSettle();
    expect(repo.workspace.flows, hasLength(1));
    expect(repo.workspace.flows.single.status, FlowStatus.confirmed);
    expect(repo.workspace.flows.single.sourceId, 'n16');
    expect(repo.workspace.flows.single.targetId, 'n12');
    expect(repo.workspace.flows.single.protocol, isNull);
    expect(
      find.textContaining('Suggeriment: MES envasat → Línia iogurt'),
      findsOneWidget,
    );
  });

  testWidgets('dos esquemes reobren la disposició i la selecció', (
    tester,
  ) async {
    final database = MemoryWorkspaceDatabase();
    final repo = await open(example: true, database: database);
    await pumpPage(tester, repo);
    await select(tester, 'n16');
    await reveal(tester, find.byKey(workspaceLayoutXKey, skipOffstage: false));
    await tester.enterText(find.byKey(workspaceLayoutXKey), '5000');
    await tester.enterText(find.byKey(workspaceLayoutYKey), '0');
    await tester.tap(find.byKey(workspaceSaveLayoutKey));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const Key('map-n16'))).left,
      greaterThan(tester.getRect(find.byKey(const Key('map-n19'))).left),
    );

    await select(tester, 'n4');
    await reveal(
      tester,
      find.byKey(workspaceNewSchemaKey, skipOffstage: false),
    );
    await tester.tap(find.byKey(workspaceNewSchemaKey));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(workspaceSchemaNameKey), 'Només Lleida');
    await tester.tap(find.byKey(const Key('schema-plant-n12')));
    await tester.tap(find.byKey(createSchemaKey));
    await tester.pumpAndSettle();
    expect(find.textContaining('Identificador n4'), findsNothing);
    expect(find.byKey(const Key('map-n17')), findsNothing);
    expect(find.byKey(const Key('map-n16')), findsOneWidget);
    expect(find.text('Línia'), findsWidgets);
    expect(find.textContaining('L2'), findsNothing);

    await reveal(
      tester,
      find.byKey(workspaceSchemaPickerKey, skipOffstage: false),
    );
    await tester.tap(find.byKey(workspaceSchemaPickerKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Esquema alimentari').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Identificador n4'), findsOneWidget);
    expect(find.byKey(const Key('map-n17')), findsOneWidget);

    final again = WorkspaceRepository(
      database: database,
      readLegacy: () async => null,
      now: () => now,
    );
    await again.open();
    final lleida = again.workspace.schemas.last;
    expect(lleida.name, 'Només Lleida');
    expect(lleida.plantIds, ['n12']);
    expect(lleida.flowIds, isEmpty);
    expect(findSchema(again.workspace, 'n20')!.layout['n16']!.x, 5000);
    await pumpPage(tester, again);
    expect(find.byKey(workspaceSchemaPickerKey), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const Key('map-n16'))).left,
      greaterThan(tester.getRect(find.byKey(const Key('map-n19'))).left),
    );
  });

  testWidgets(
    'restaurar una instantània no muta l\'OEE ni la versió d\'origen',
    (tester) async {
      final repo = await open(example: true);
      await repo.saveWorkspace(
        repo.workspace.copyWith(
          oeeRecords: [
            OeeRecord(
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
            ),
          ],
        ),
      );
      await pumpPage(tester, repo);
      await reveal(
        tester,
        find.byKey(workspaceSnapshotKey, skipOffstage: false),
      );
      await tester.tap(find.byKey(workspaceSnapshotKey));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Data: 2026-09-02T09:00:00.000Z'),
        findsOneWidget,
      );
      final cancel = tester.widget<TextButton>(find.byKey(cancelSnapshotKey));
      cancel.focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(repo.workspace.versions, isEmpty);

      await tester.tap(find.byKey(workspaceSnapshotKey));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(workspaceSnapshotNoteKey),
        'Primera captura',
      );
      await tester.tap(find.byKey(createSnapshotKey));
      await tester.pumpAndSettle();
      expect(repo.workspace.versions.single.note, 'Primera captura');
      expect(repo.workspace.oeeRecords.single.article, 'Iogurt natural');

      await select(tester, 'n4');
      await tester.enterText(find.byKey(workspaceNameFieldKey), 'Línia nova');
      final save = find.byKey(workspaceSaveEditKey, skipOffstage: false);
      await reveal(tester, save);
      tester.widget<FilledButton>(save).onPressed!.call();
      await tester.pumpAndSettle();

      await reveal(
        tester,
        find.byKey(workspaceVersionsKey, skipOffstage: false),
      );
      await tester.tap(find.byKey(workspaceVersionsKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('restore-n21')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('L\'inventari i l\'OEE no es modifiquen.'),
        findsOneWidget,
      );
      expect(find.textContaining('n4:'), findsOneWidget);
      await tester.tap(find.byKey(cancelRestoreKey));
      await tester.pumpAndSettle();
      expect(repo.workspace.versions, hasLength(1));
      expect(findAsset(repo.workspace, 'n4')!.name, 'Línia nova');

      await tester.tap(find.byKey(workspaceVersionsKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('restore-n21')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(workspaceRestoreNoteKey),
        'Restauració',
      );
      await tester.tap(find.byKey(confirmRestoreKey));
      await tester.pumpAndSettle();
      expect(repo.workspace.versions, hasLength(2));
      expect(repo.workspace.versions.first.note, 'Primera captura');
      expect(repo.workspace.versions.last.parentVersionId, 'n21');
      expect(repo.workspace.versions.last.note, 'Restauració');
      expect(findAsset(repo.workspace, 'n4')!.name, 'Línia nova');
      expect(repo.workspace.oeeRecords.single.capturedLineName, 'Línia iogurt');
      expect(repo.workspace.oeeRecords.single.idealCycleSeconds, 1);
      final versions =
          jsonDecode(architectureVersionsJson(repo.workspace)) as List;
      expect(
        (versions.first as Map)['snapshot'],
        (versions.last as Map)['snapshot'],
      );
    },
  );

  testWidgets(
    'la importació rebutjada o cancel·lada no deixa una base parcial',
    (tester) async {
      final database = MemoryWorkspaceDatabase();
      final repo = await open(example: true, database: database);
      await pumpPage(tester, repo);
      final before = workspaceToJson(repo.workspace);

      Future<void> openImport(String raw) async {
        await reveal(
          tester,
          find.byKey(workspaceImportKey, skipOffstage: false),
        );
        await tester.tap(find.byKey(workspaceImportKey));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(workspaceImportFieldKey), raw);
        await tester.tap(find.byKey(prepareWorkspaceImportKey));
        await tester.pumpAndSettle();
      }

      await openImport('{');
      expect(find.text('El JSON no és vàlid.'), findsOneWidget);
      expect(workspaceToJson(repo.workspace), before);
      expect(find.text('Desat'), findsOneWidget);

      await openImport(workspaceToJson(createEmptyWorkspace()));
      expect(find.text('Substitució completa'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(cancelWorkspaceReplaceKey)).height,
        greaterThanOrEqualTo(48),
      );
      await tester.tap(find.byKey(cancelWorkspaceReplaceKey));
      await tester.pumpAndSettle();
      expect(workspaceToJson(repo.workspace), before);

      database.failWrites = 1;
      await openImport(workspaceToJson(createEmptyWorkspace()));
      await tester.tap(find.byKey(confirmWorkspaceReplaceKey));
      await tester.pumpAndSettle();
      expect(find.textContaining('Error de desament'), findsOneWidget);
      expect(find.text('Desat'), findsNothing);
      expect(database.values[workspaceDocumentKey], before);
      expect(repo.workspace.organizations, isNotEmpty);

      await openImport(workspaceToJson(createEmptyWorkspace()));
      await tester.tap(find.byKey(confirmWorkspaceReplaceKey));
      await tester.pumpAndSettle();
      expect(repo.workspace.organizations, isEmpty);
      expect(find.text('Desat'), findsOneWidget);
      expect(database.values[priorBackupKey], before);
    },
  );

  testWidgets('a 360 la plantilla i el flux manual caben', (tester) async {
    final repo = await open(example: true);
    await pumpPage(tester, repo, size: const Size(360, 800));
    await tester.tap(find.byKey(workspaceTreeToggleKey));
    await tester.pumpAndSettle();
    await select(tester, 'n4');
    await reveal(
      tester,
      find.byKey(workspaceInspectorToggleKey, skipOffstage: false),
    );
    await tester.tap(find.byKey(workspaceInspectorToggleKey));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(workspaceTemplateKey, skipOffstage: false));
    await tester.tap(find.byKey(workspaceTemplateKey));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(applyTemplateKey)).height,
      greaterThanOrEqualTo(48),
    );
    await tester.tap(find.byKey(cancelTemplateKey));
    await tester.pumpAndSettle();

    await reveal(tester, find.byKey(workspaceAddKey, skipOffstage: false));
    await tester.tap(find.byKey(workspaceAddKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Flux').last);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('El flux és manual.', skipOffstage: false),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    expect(repo.workspace.flows, isEmpty);
  });
}
