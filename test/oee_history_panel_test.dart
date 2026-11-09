import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapaisa95oee/oee_engine.dart';
import 'package:mapaisa95oee/oee_engine_panel.dart';
import 'package:mapaisa95oee/oee_history.dart';
import 'package:mapaisa95oee/oee_history_panel.dart';
import 'package:mapaisa95oee/workspace_database_memory.dart';
import 'package:mapaisa95oee/workspace_model.dart';
import 'package:mapaisa95oee/workspace_page.dart';
import 'package:mapaisa95oee/workspace_repository.dart';

void main() {
  final now = DateTime.utc(2026, 3, 2, 8);

  Future<WorkspaceRepository> open(MemoryWorkspaceDatabase database) async {
    final repo = WorkspaceRepository(
      database: database,
      readLegacy: () async => null,
      now: () => now,
    );
    await repo.open();
    await repo.loadExample(confirm: true);
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
    WorkspaceRepository repo,
    Size size,
  ) async {
    await surface(tester, size);
    await tester.pumpWidget(
      MaterialApp(
        home: WorkspacePage(
          repository: repo,
          onOpenOee: () {},
          onOpenData: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> selectLine(WidgetTester tester) async {
    final tile = find.byKey(const Key('tree-n4'), skipOffstage: false);
    await tester.ensureVisible(tile);
    tester.widget<ListTile>(tile).onTap!.call();
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, Key key, String value) async {
    final finder = find.byKey(key, skipOffstage: false);
    await tester.ensureVisible(finder);
    await tester.enterText(finder, value);
    await tester.pump();
  }

  Future<Finder> reveal(WidgetTester tester, Key key) async {
    final finder = find.byKey(key, skipOffstage: false);
    for (var step = 0; step < 12; step++) {
      final rect = tester.getRect(finder);
      if (rect.top >= 64 && rect.bottom <= 620) {
        return finder;
      }
      await tester.drag(
        find.byKey(workspaceInspectorKey),
        Offset(0, rect.bottom > 620 ? -280 : 280),
      );
      await tester.pumpAndSettle();
    }
    return finder;
  }

  Future<void> press(WidgetTester tester, Key key) async {
    final finder = await reveal(tester, key);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> fillReference(WidgetTester tester) async {
    await enter(tester, oeeDateKey, '2026-03-01');
    await enter(tester, oeeShiftKey, 'Matí');
    await enter(tester, oeeArticleKey, 'Iogurt natural');
    await enter(tester, oeeLotKey, '');
    await enter(tester, enginePlannedKey, '480');
    await enter(tester, engineDowntimeKey, '60');
    await enter(tester, engineSpeedKey, '1');
    await enter(tester, engineTotalKey, '24000');
    await enter(tester, engineGoodKey, '22800');
  }

  testWidgets('desa, filtra i obre el registre sense agregar', (tester) async {
    final database = MemoryWorkspaceDatabase();
    final repo = await open(database);
    await pumpPage(tester, repo, const Size(1280, 800));
    await selectLine(tester);
    await fillReference(tester);

    expect(find.text(calculationNotStoredMessage), findsNothing);
    final validate = await reveal(tester, saveOeeValidatedKey);
    expect(tester.getSize(validate).height, greaterThanOrEqualTo(48));
    await tester.tap(validate);
    await tester.pumpAndSettle();

    final record = repo.workspace.oeeRecords.single;
    expect(record.status, OeeRecordStatus.validated);
    expect(record.lot, isNull);
    expect(record.idealCycleSeconds, 1);
    expect(record.capturedLineName, 'Línia iogurt');
    expect(find.text('Estat: Validat'), findsOneWidget);
    expect(find.text('Lot: Sense lot'), findsOneWidget);
    expect(find.text('OEE: 79.166667 %'), findsOneWidget);
    expect(find.text('Productiu: 380 min'), findsOneWidget);
    expect(find.text('Total: 480 min'), findsOneWidget);
    expect(find.text(oeeNoAggregationMessage), findsOneWidget);
    expect(find.textContaining('Mitjana'), findsNothing);
    expect(find.text('Desat'), findsWidgets);

    await press(tester, oeeCloseRecordKey);
    await press(tester, oeeCalculationModeKey);
    await enter(tester, oeeArticleKey, 'Formatge');
    await enter(tester, enginePlannedKey, '1');
    await enter(tester, engineDowntimeKey, '0');
    await enter(tester, engineSpeedKey, '1');
    await enter(tester, engineTotalKey, '100');
    await enter(tester, engineGoodKey, '100');
    final blocked = tester.widget<OutlinedButton>(
      find.byKey(saveOeeValidatedKey, skipOffstage: false),
    );
    expect(blocked.onPressed, isNull);
    final draft = tester.widget<FilledButton>(
      find.byKey(saveOeeDraftKey, skipOffstage: false),
    );
    draft.focusNode!.requestFocus();
    await tester.pump();
    expect(tester.binding.focusManager.primaryFocus, draft.focusNode);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(repo.workspace.oeeRecords, hasLength(2));
    await press(tester, oeeCloseRecordKey);
    expect(find.textContaining('Formatge'), findsNothing);

    await press(tester, oeeScopeDraftKey);
    final draftRecord = repo.workspace.oeeRecords.singleWhere(
      (item) => item.status == OeeRecordStatus.draft,
    );
    await press(tester, oeeOpenRecordKey(draftRecord.id));
    expect(find.text(pieNegativeMessage, skipOffstage: false), findsOneWidget);
    expect(find.byKey(enginePieKey), findsNothing);

    final reloaded = WorkspaceRepository(
      database: database,
      readLegacy: () async => null,
      now: () => now,
    );
    await reloaded.open();
    expect(reloaded.workspace.oeeRecords, hasLength(2));
    await pumpPage(tester, reloaded, const Size(360, 800));
    await tester.ensureVisible(find.byKey(workspaceTreeToggleKey, skipOffstage: false));
    await tester.tap(find.byKey(workspaceTreeToggleKey));
    await tester.pumpAndSettle();
    await selectLine(tester);
    await tester.ensureVisible(
      find.byKey(workspaceInspectorToggleKey, skipOffstage: false),
    );
    await tester.tap(find.byKey(workspaceInspectorToggleKey));
    await tester.pumpAndSettle();
    await press(tester, oeeHistoryModeKey);
    expect(find.text('Històric OEE'), findsWidgets);
    final article = await reveal(tester, oeeFilterArticleKey);
    expect(tester.getSize(article).width, lessThanOrEqualTo(360));
    expect(tester.getSize(find.byKey(oeeScopeValidatedKey)).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
    await tester.enterText(article, 'Iogurt');
    await tester.pumpAndSettle();
    expect(find.textContaining('Iogurt natural', skipOffstage: false), findsWidgets);
    expect(find.textContaining('Formatge'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('corregir conserva el validat i la revisió anterior', (tester) async {
    final repo = await open(MemoryWorkspaceDatabase());
    await pumpPage(tester, repo, const Size(1280, 800));
    await selectLine(tester);
    await fillReference(tester);
    await press(tester, saveOeeValidatedKey);
    final original = repo.workspace.oeeRecords.single;
    await press(tester, oeeCloseRecordKey);
    await press(tester, oeeOpenRecordKey(original.id));
    await press(tester, oeeCorrectKey);
    expect(
      find.text('Correcció. El registre validat no es modifica.'),
      findsOneWidget,
    );
    await enter(tester, oeeArticleKey, 'Corregit');
    await press(tester, saveOeeValidatedKey);
    expect(repo.workspace.oeeRecords, hasLength(2));
    final kept = repo.workspace.oeeRecords.singleWhere((item) => item.id == original.id);
    expect(kept.article, 'Iogurt natural');
    expect(kept.idealCycleSeconds, original.idealCycleSeconds);
    expect(kept.updatedAt, original.updatedAt);
    expect(find.text('Revisió anterior'), findsOneWidget);
    await press(tester, oeePreviousRevisionKey);
    expect(find.text('Article: Iogurt natural'), findsOneWidget);
    expect(
      find.textContaining('Aquesta revisió s\'ha conservat.'),
      findsOneWidget,
    );
  });
}
