import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapaisa95oee/plant_map_page.dart';
import 'package:mapaisa95oee/plant_model.dart';
import 'package:mapaisa95oee/plant_store.dart';

void main() {
  testWidgets('carrega exemple i mostra nodes a l\'arbre', (tester) async {
    final store = MemoryPlantStore();
    await tester.pumpWidget(
      MaterialApp(home: PlantMapPage(store: store)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(plantMapLoadExampleKey));
    await tester.pumpAndSettle();

    expect(find.text('Alimentària Demo'), findsWidgets);
    expect(find.text('Omplidora'), findsOneWidget);

    final loaded = await store.load();
    expect(findNode(loaded, 'n1'), isNotNull);
  });

  testWidgets('esborrar node amb fills demana confirmació', (tester) async {
    final store = MemoryPlantStore(foodPlantExample());
    await tester.pumpWidget(
      MaterialApp(home: PlantMapPage(store: store)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Accions').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Esborra').last);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Aquest node té fills. Segur que vols esborrar-lo amb tot el subarbre?',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(plantConfirmDeleteKey));
    await tester.pumpAndSettle();

    final loaded = await store.load();
    expect(loaded.roots, isEmpty);
  });

  testWidgets('vista nivells mostra seccions 0–4', (tester) async {
    final store = MemoryPlantStore(foodPlantExample());
    await tester.pumpWidget(
      MaterialApp(home: PlantMapPage(store: store)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nivells'));
    await tester.pumpAndSettle();

    for (final label in [
      '0 - Procés',
      '1 - Sensors',
      '2 - Control',
      '3 - MES',
      '4 - ERP',
    ]) {
      await tester.scrollUntilVisible(
        find.text(label),
        200,
        scrollable: find
            .descendant(
              of: find.byType(TabBarView),
              matching: find.byType(Scrollable),
            )
            .last,
      );
      expect(find.text(label), findsOneWidget);
    }
    expect(
      find.textContaining('Alimentària Demo / Planta Girona'),
      findsWidgets,
    );
  });

  testWidgets('import JSON invàlid mostra missatge', (tester) async {
    final store = MemoryPlantStore();
    await tester.pumpWidget(
      MaterialApp(
        home: PlantMapPage(
          store: store,
          importJson: () async => '{"version":1}',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(plantMapImportKey));
    await tester.pumpAndSettle();

    expect(find.text('El fitxer JSON no és vàlid.'), findsWidgets);
  });

  testWidgets('a 360 px no hi ha overflow', (tester) async {
    final store = MemoryPlantStore(foodPlantExample());
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(home: PlantMapPage(store: store)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Mapa ISA-95'), findsOneWidget);
  });

  testWidgets('exporta JSON via callback', (tester) async {
    String? exported;
    final store = MemoryPlantStore(foodPlantExample());
    await tester.pumpWidget(
      MaterialApp(
        home: PlantMapPage(
          store: store,
          exportJson: (filename, json) async {
            exported = json;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(plantMapExportKey));
    await tester.pumpAndSettle();

    expect(exported, contains('"version": 1'));
    expect(exported, contains('Alimentària Demo'));
  });
}
