import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapaisa95oee/plant_store.dart';
import 'package:mapaisa95oee/workspace_codec.dart';
import 'package:mapaisa95oee/workspace_database_memory.dart';
import 'package:mapaisa95oee/workspace_model.dart';
import 'package:mapaisa95oee/workspace_page.dart';
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
}
