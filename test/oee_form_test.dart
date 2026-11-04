import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapaisa95oee/main.dart';
import 'package:mapaisa95oee/oee_calculator.dart';
import 'package:mapaisa95oee/oee_form.dart';

void main() {
  Future<void> setSurface(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> enter(WidgetTester tester, Key key, String value) async {
    final finder = find.byKey(key);
    await tester.ensureVisible(finder);
    await tester.enterText(finder, value);
    await tester.pump();
  }

  Future<void> fill(
    WidgetTester tester, {
    required String planned,
    required String downtime,
    required String cycle,
    required String total,
    required String good,
  }) async {
    await enter(tester, plannedMinutesKey, planned);
    await enter(tester, downtimeMinutesKey, downtime);
    await enter(tester, idealCycleSecondsKey, cycle);
    await enter(tester, totalUnitsKey, total);
    await enter(tester, goodUnitsKey, good);
  }

  testWidgets('mostra el torn de referència en viu i sense botó', (
    tester,
  ) async {
    await tester.pumpWidget(const OeeApp());

    expect(find.text('Calculador OEE'), findsOneWidget);
    expect(find.text(incompleteOeeMessage), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);

    await fill(
      tester,
      planned: '480',
      downtime: '60',
      cycle: '60',
      total: '400',
      good: '380',
    );

    expect(find.text('OEE: 79.2 %'), findsOneWidget);
    expect(find.text('Disponibilitat: 87.5 %'), findsOneWidget);
    expect(find.text('Rendiment: 95.2 %'), findsOneWidget);
    expect(find.text('Qualitat: 95.0 %'), findsOneWidget);
    expect(find.text('Pèrdua principal: Disponibilitat.'), findsOneWidget);
    expect(find.text(performanceWarningMessage), findsNothing);
    expect(find.text(incompleteOeeMessage), findsNothing);

    await enter(tester, goodUnitsKey, '400');
    expect(find.text('OEE: 83.3 %'), findsOneWidget);
    expect(find.text('Qualitat: 100.0 %'), findsOneWidget);
  });

  testWidgets('valida negatius, parades, temps operatiu i nombres invàlids', (
    tester,
  ) async {
    await tester.pumpWidget(const OeeApp());

    await enter(tester, plannedMinutesKey, '-1');
    expect(find.text('Els valors no poden ser negatius.'), findsOneWidget);
    expect(find.text(incompleteOeeMessage), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);

    await fill(
      tester,
      planned: '100',
      downtime: '120',
      cycle: '60',
      total: '10',
      good: '10',
    );
    expect(
      find.text('El temps de parades no pot superar el temps planificat.'),
      findsOneWidget,
    );
    expect(find.textContaining('OEE:'), findsNothing);

    await fill(
      tester,
      planned: '30',
      downtime: '30',
      cycle: '10',
      total: '5',
      good: '5',
    );
    expect(
      find.text('El temps operatiu és zero; no es pot calcular el rendiment.'),
      findsOneWidget,
    );

    await enter(tester, idealCycleSecondsKey, 'abc');
    expect(find.text('Introdueix un nombre vàlid.'), findsOneWidget);
    expect(
      find.text('El temps operatiu és zero; no es pot calcular el rendiment.'),
      findsNothing,
    );
  });

  testWidgets('avisa quan el rendiment supera el 100 %', (tester) async {
    await tester.pumpWidget(const OeeApp());
    await fill(
      tester,
      planned: '60',
      downtime: '0',
      cycle: '30,0',
      total: '150',
      good: '150',
    );

    expect(find.text('OEE: 125.0 %'), findsOneWidget);
    expect(find.text('Rendiment: 125.0 %'), findsOneWidget);
    expect(find.text(performanceWarningMessage), findsOneWidget);
    expect(
      find.text('Pèrdua principal: Disponibilitat i Qualitat.'),
      findsOneWidget,
    );
  });

  testWidgets('cap a 360 px i a escriptori sense overflow', (tester) async {
    await setSurface(tester, const Size(360, 800));
    await tester.pumpWidget(const OeeApp());
    await fill(
      tester,
      planned: '480',
      downtime: '60',
      cycle: '60',
      total: '400',
      good: '380',
    );
    expect(tester.takeException(), isNull);
    expect(find.text('OEE: 79.2 %'), findsOneWidget);
    for (final key in [
      plannedMinutesKey,
      downtimeMinutesKey,
      idealCycleSecondsKey,
      totalUnitsKey,
      goodUnitsKey,
    ]) {
      await tester.ensureVisible(find.byKey(key));
      expect(tester.getSize(find.byKey(key)).height, greaterThanOrEqualTo(48));
    }

    await setSurface(tester, const Size(1280, 800));
    await tester.pumpWidget(const OeeApp());
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('OEE: 79.2 %'), findsOneWidget);
  });
}
