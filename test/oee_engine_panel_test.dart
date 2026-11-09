import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapaisa95oee/main.dart';
import 'package:mapaisa95oee/oee_engine.dart';
import 'package:mapaisa95oee/oee_engine_panel.dart';
import 'package:mapaisa95oee/oee_form.dart';
import 'package:mapaisa95oee/plant_store.dart';
import 'package:mapaisa95oee/workspace_database_memory.dart';
import 'package:mapaisa95oee/workspace_page.dart';
import 'package:mapaisa95oee/workspace_repository.dart';

void main() {
  Future<void> surface(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> enter(WidgetTester tester, Key key, String value) async {
    final finder = find.byKey(key, skipOffstage: false);
    await tester.ensureVisible(finder);
    await tester.enterText(finder, value);
    await tester.pump();
  }

  Future<void> fill(
    WidgetTester tester, {
    required String planned,
    required String downtime,
    required String speed,
    required String total,
    required String good,
  }) async {
    await enter(tester, enginePlannedKey, planned);
    await enter(tester, engineDowntimeKey, downtime);
    await enter(tester, engineSpeedKey, speed);
    await enter(tester, engineTotalKey, total);
    await enter(tester, engineGoodKey, good);
  }

  Widget page() {
    return const MaterialApp(home: OeeEnginePage());
  }

  testWidgets('la referència mostra els quatre indicadors i el pastís', (
    tester,
  ) async {
    await surface(tester, const Size(1280, 800));
    await tester.pumpWidget(page());
    expect(find.text('Càlcul OEE'), findsOneWidget);
    expect(find.text('Fórmula oee.v1'), findsOneWidget);
    expect(find.text('Activa: s/unitat'), findsOneWidget);
    expect(find.textContaining('OEE:'), findsNothing);

    await fill(
      tester,
      planned: '480',
      downtime: '60',
      speed: '1',
      total: '24000',
      good: '22800',
    );

    expect(find.text('Disponibilitat: 87.5 %'), findsOneWidget);
    expect(find.text('Rendiment: 95.238095 %'), findsOneWidget);
    expect(find.text('Qualitat: 95 %'), findsOneWidget);
    expect(find.text('OEE: 79.166667 %'), findsOneWidget);
    expect(find.text('Productiu: 380 min'), findsOneWidget);
    expect(find.text('Disponibilitat: 60 min'), findsOneWidget);
    expect(find.text('Rendiment: 20 min'), findsOneWidget);
    expect(find.text('Qualitat: 20 min'), findsOneWidget);
    expect(find.text('Total: 480 min'), findsOneWidget);
    expect(find.text(pieExplanation), findsOneWidget);
    expect(find.byKey(enginePieKey), findsOneWidget);
    expect(find.text(calculationNotStoredMessage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('canviar d\'unitat conserva l\'OEE i no encadena el text', (
    tester,
  ) async {
    await tester.pumpWidget(page());
    await fill(
      tester,
      planned: '1',
      downtime: '0',
      speed: '0,4',
      total: '100',
      good: '90',
    );
    expect(find.text('OEE: 60 %'), findsOneWidget);

    for (var turn = 0; turn < 4; turn++) {
      await tester.ensureVisible(find.byKey(engineUnitRateKey));
      await tester.tap(find.byKey(engineUnitRateKey));
      await tester.pump();
      expect(find.text('Activa: unitats/s'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byKey(engineSpeedKey)).controller!.text,
        '2.5',
      );
      expect(find.text('OEE: 60 %'), findsOneWidget);

      await tester.ensureVisible(find.byKey(engineUnitSecondsKey));
      await tester.tap(find.byKey(engineUnitSecondsKey));
      await tester.pump();
      expect(find.text('Activa: s/unitat'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byKey(engineSpeedKey)).controller!.text,
        '0.4',
      );
      expect(find.text('OEE: 60 %'), findsOneWidget);
    }
  });

  testWidgets(
    'la qualitat superior al 100 % i el rendiment excessiu no enganyen',
    (tester) async {
      await tester.pumpWidget(page());
      await fill(
        tester,
        planned: '60',
        downtime: '0',
        speed: '30',
        total: '10',
        good: '11',
      );
      expect(
        find.text('Les unitats bones no poden superar les unitats totals.'),
        findsOneWidget,
      );
      expect(find.textContaining('OEE:'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      expect(find.byKey(enginePieKey), findsNothing);

      await fill(
        tester,
        planned: '60',
        downtime: '0',
        speed: '30',
        total: '150',
        good: '150',
      );
      expect(find.text('Rendiment: 125 %'), findsOneWidget);
      expect(find.text('OEE: 125 %'), findsOneWidget);
      expect(find.text('Rendiment: 100 %'), findsNothing);
      expect(find.text(performanceAboveIdealMessage), findsOneWidget);
      expect(find.text(validationBlockedMessage), findsOneWidget);
      expect(find.text(pieNegativeMessage), findsOneWidget);
      expect(find.byKey(enginePieKey), findsNothing);
    },
  );

  testWidgets('zeros, NaN i separadors ambigus es veuen al camp', (
    tester,
  ) async {
    await tester.pumpWidget(page());
    await fill(
      tester,
      planned: '0',
      downtime: '0',
      speed: '1',
      total: '0',
      good: '0',
    );
    expect(
      find.text('El temps planificat ha de ser més gran que zero.'),
      findsOneWidget,
    );
    expect(find.textContaining('OEE:'), findsNothing);

    await fill(
      tester,
      planned: '10',
      downtime: '10',
      speed: '1',
      total: '4',
      good: '1',
    );
    expect(
      find.text('No hi pot haver producció amb temps operatiu zero.'),
      findsOneWidget,
    );
    expect(find.textContaining('OEE:'), findsNothing);
    expect(find.byKey(enginePieKey), findsNothing);

    await enter(tester, engineSpeedKey, 'Infinity');
    expect(find.text('La velocitat no és un nombre finit.'), findsOneWidget);

    await enter(tester, enginePlannedKey, '1.234,56');
    expect(
      find.text('El temps planificat té separadors de milers ambigus.'),
      findsOneWidget,
    );

    await enter(tester, engineTotalKey, '10.5');
    expect(
      find.text(
        'Les unitats totals han de ser un enter, sense decimals ni separadors de milers.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'a 360 px i a escriptori el quadre no desborda i el focus es veu',
    (tester) async {
      await surface(tester, const Size(360, 800));
      await tester.pumpWidget(page());
      await fill(
        tester,
        planned: '480',
        downtime: '60',
        speed: '1',
        total: '24000',
        good: '22800',
      );
      expect(tester.takeException(), isNull);
      expect(find.text('OEE: 79.166667 %'), findsOneWidget);
      for (final key in [
        enginePlannedKey,
        engineDowntimeKey,
        engineSpeedKey,
        engineTotalKey,
        engineGoodKey,
        engineUnitSecondsKey,
        engineUnitRateKey,
      ]) {
        await tester.ensureVisible(find.byKey(key));
        final size = tester.getSize(find.byKey(key));
        expect(size.height, greaterThanOrEqualTo(48));
        expect(size.width, lessThanOrEqualTo(360));
      }

      final planned = tester.widget<TextField>(find.byKey(enginePlannedKey));
      planned.focusNode!.requestFocus();
      await tester.pump();
      expect(planned.focusNode!.hasFocus, isTrue);
      final theme = Theme.of(tester.element(find.byKey(enginePlannedKey)));
      final focused =
          theme.inputDecorationTheme.focusedBorder! as OutlineInputBorder;
      expect(focused.borderSide.width, 2);

      final rate = tester.widget<OutlinedButton>(find.byKey(engineUnitRateKey));
      rate.focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.text('Activa: unitats/s'), findsOneWidget);
      expect(find.text('OEE: 79.166667 %'), findsOneWidget);

      await surface(tester, const Size(1280, 800));
      await tester.pumpWidget(page());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('el calculador US-1 segueix al 79.2 % i obre el motor nou', (
    tester,
  ) async {
    await tester.pumpWidget(OeeApp(store: MemoryPlantStore()));
    expect(find.text('Càlcul amb unitats'), findsOneWidget);
    await tester.tap(find.text('Càlcul amb unitats'));
    await tester.pumpAndSettle();
    expect(find.text('Càlcul OEE'), findsOneWidget);

    await tester.tap(find.text('Calculador US-1'));
    await tester.pumpAndSettle();
    expect(find.text('Calculador OEE'), findsOneWidget);

    Future<void> type(Key key, String value) async {
      await tester.enterText(find.byKey(key), value);
      await tester.pump();
    }

    await type(plannedMinutesKey, '480');
    await type(downtimeMinutesKey, '60');
    await type(idealCycleSecondsKey, '60');
    await type(totalUnitsKey, '400');
    await type(goodUnitsKey, '380');
    expect(find.text('OEE: 79.2 %'), findsOneWidget);
  });

  testWidgets('la línia mostra el quadre sense escriure un registre', (
    tester,
  ) async {
    final repo = WorkspaceRepository(
      database: MemoryWorkspaceDatabase(),
      readLegacy: () async => null,
      now: () => DateTime.utc(2026, 9, 2),
    );
    await repo.open();
    await repo.loadExample(confirm: true);
    await surface(tester, const Size(1280, 800));
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
    final tile = find.byKey(const Key('tree-n4'));
    await tester.ensureVisible(tile);
    tester.widget<ListTile>(tile).onTap!.call();
    await tester.pumpAndSettle();

    expect(
      find.text('Obre el calculador', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text(
        'Línia: Línia iogurt. La velocitat ideal correspon a aquesta línia.',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(find.text('Fórmula oee.v1', skipOffstage: false), findsOneWidget);
    expect(repo.workspace.oeeRecords, isEmpty);

    await fill(
      tester,
      planned: '480',
      downtime: '60',
      speed: '1',
      total: '24000',
      good: '22800',
    );
    expect(find.text('OEE: 79.166667 %', skipOffstage: false), findsOneWidget);
    expect(repo.workspace.oeeRecords, isEmpty);
    expect(tester.takeException(), isNull);

    await surface(tester, const Size(360, 800));
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
    await tester.ensureVisible(find.byKey(workspaceTreeToggleKey));
    await tester.tap(find.byKey(workspaceTreeToggleKey));
    await tester.pumpAndSettle();
    final narrowTile = find.byKey(const Key('tree-n4'), skipOffstage: false);
    await tester.ensureVisible(narrowTile);
    tester.widget<ListTile>(narrowTile).onTap!.call();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(workspaceInspectorToggleKey));
    await tester.tap(find.byKey(workspaceInspectorToggleKey));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Línia: Línia iogurt. La velocitat ideal correspon a aquesta línia.',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    final speed = find.byKey(engineSpeedKey, skipOffstage: false);
    await tester.ensureVisible(speed);
    expect(tester.getSize(speed).width, lessThanOrEqualTo(360));
  });
}
