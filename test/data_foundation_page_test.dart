import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapaisa95oee/data_foundation_page.dart';
import 'package:mapaisa95oee/plant_model.dart';
import 'package:mapaisa95oee/plant_store.dart';
import 'package:mapaisa95oee/workspace_database_memory.dart';
import 'package:mapaisa95oee/workspace_repository.dart';

void main() {
  final now = DateTime.utc(2026, 8, 1);

  Future<WorkspaceRepository> open({
    Map<String, String>? legacy,
    MemoryWorkspaceDatabase? database,
  }) async {
    final repo = WorkspaceRepository(
      database: database ?? MemoryWorkspaceDatabase(),
      readLegacy: () async => legacy?[plantStorageKey],
      now: () => now,
    );
    await repo.open();
    return repo;
  }

  Future<void> pumpPage(WidgetTester tester, WorkspaceRepository repo) async {
    await tester.pumpWidget(
      MaterialApp(home: DataFoundationPage(repository: repo)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mostra la migració sense promoure i conserva la clau', (
    tester,
  ) async {
    final legacy = {plantStorageKey: plantToJson(foodPlantExample())};
    final repo = await open(legacy: legacy);
    await pumpPage(tester, repo);

    expect(
      find.textContaining('no promogut', skipOffstage: false),
      findsWidgets,
    );
    expect(
      find.textContaining('nivell antic 4 (ERP)', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('ERP corporatiu', skipOffstage: false), findsNothing);
    expect(
      find.textContaining('Sense funció ISA-95', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.textContaining('Clau legacy mapaisa95oee.plant.v1: present'),
      findsOneWidget,
    );
    expect(legacy[plantStorageKey], plantToJson(foodPlantExample()));

    final acknowledge = find.byKey(
      const Key('acknowledge-review-n1'),
      skipOffstage: false,
    );
    await tester.ensureVisible(acknowledge);
    await tester.tap(acknowledge);
    await tester.pumpAndSettle();
    expect(find.textContaining('revisat'), findsOneWidget);
    expect(repo.workspace.systems, isEmpty);
    expect(repo.workspace.migrationReviews.first.promoted, isFalse);
    expect(legacy[plantStorageKey], plantToJson(foodPlantExample()));
  });

  testWidgets(
    'l\'exemple no presenta empresa = L4 i sobreviu a la cancel·lació',
    (tester) async {
      final repo = await open();
      await pumpPage(tester, repo);

      await tester.ensureVisible(
        find.byKey(loadFoodExampleKey, skipOffstage: false),
      );
      await tester.tap(find.byKey(loadFoodExampleKey));
      await tester.pumpAndSettle();
      expect(find.text('Desat'), findsOneWidget);
      expect(
        find.textContaining(
          'Alimentària Demo · Sense funció ISA-95',
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Línia iogurt · Línia · Sense funcions',
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'ERP corporatiu · ERP · Planificació empresarial · IT · abast Planta Girona, Planta Lleida',
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(find.textContaining('empresa = L4'), findsNothing);

      final exported = repo.exportBackupJson();
      await tester.ensureVisible(
        find.byKey(backupJsonFieldKey, skipOffstage: false),
      );
      await tester.enterText(find.byKey(backupJsonFieldKey), '{');
      await tester.ensureVisible(
        find.byKey(prepareReplaceKey, skipOffstage: false),
      );
      await tester.tap(find.byKey(prepareReplaceKey));
      await tester.pumpAndSettle();
      expect(find.text('El JSON no és vàlid.'), findsOneWidget);
      expect(find.text('Desat'), findsOneWidget);
      expect(repo.workspace.organizations.single.name, 'Alimentària Demo');

      await tester.ensureVisible(
        find.byKey(backupJsonFieldKey, skipOffstage: false),
      );
      await tester.enterText(find.byKey(backupJsonFieldKey), exported);
      await tester.ensureVisible(
        find.byKey(prepareReplaceKey, skipOffstage: false),
      );
      await tester.tap(find.byKey(prepareReplaceKey));
      await tester.pumpAndSettle();
      expect(find.text('Substitució completa'), findsOneWidget);
      await tester.tap(find.byKey(cancelReplaceKey));
      await tester.pumpAndSettle();
      expect(repo.workspace.organizations.single.name, 'Alimentària Demo');

      await tester.ensureVisible(
        find.byKey(exportBackupKey, skipOffstage: false),
      );
      final size = tester.getSize(find.byKey(exportBackupKey));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
    },
  );

  testWidgets('a 360 px no hi ha overflow i l\'error de desament es conserva', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = MemoryWorkspaceDatabase();
    final repo = await open(database: database);
    await pumpPage(tester, repo);
    expect(tester.takeException(), isNull);

    database.failWrites = 1;
    await tester.ensureVisible(
      find.byKey(loadFoodExampleKey, skipOffstage: false),
    );
    await tester.tap(find.byKey(loadFoodExampleKey));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Error de desament'), findsOneWidget);
    expect(find.text('Desat'), findsNothing);
    expect(repo.workspace.organizations, isEmpty);
  });
}
