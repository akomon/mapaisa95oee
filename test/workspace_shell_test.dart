import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapaisa95oee/main.dart';
import 'package:mapaisa95oee/plant_store.dart';
import 'package:mapaisa95oee/workspace_shell.dart';
import 'package:mapaisa95oee/workspace_theme.dart';

void main() {
  Widget app() => OeeApp(store: MemoryPlantStore());

  Future<void> surface(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'la barra lateral i la barra inferior acompanyen totes les vistes',
    (tester) async {
      await tester.pumpWidget(app());

      expect(find.byKey(workspaceRailKey), findsOneWidget);
      for (final key in [
        workspaceRailCalculatorKey,
        workspaceRailEngineKey,
        workspaceRailMapKey,
        workspaceRailDataKey,
      ]) {
        expect(find.byKey(key), findsOneWidget);
        expect(
          tester.getSize(find.byKey(key)).height,
          greaterThanOrEqualTo(48),
        );
      }

      final bottom = find.byKey(workspaceBottomBarKey);
      expect(bottom, findsOneWidget);
      expect(tester.widget<Material>(bottom).color, bottomBarSurface);
      expect(
        find.descendant(of: bottom, matching: find.text('Mapa ISA-95')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(workspaceRailMapKey));
      await tester.pumpAndSettle();
      expect(find.text('Mapa ISA-95'), findsOneWidget);
      expect(find.byKey(workspaceRailKey), findsOneWidget);

      await tester.tap(find.byKey(workspaceRailCalculatorKey));
      await tester.pumpAndSettle();
      expect(find.text('Calculador OEE'), findsOneWidget);
      expect(find.byKey(workspaceRailKey), findsOneWidget);
    },
  );

  testWidgets('a 360 px la barra lateral continua visible sense overflow', (
    tester,
  ) async {
    await surface(tester, const Size(360, 800));
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    final rail = find.byKey(workspaceRailKey);
    expect(rail, findsOneWidget);
    expect(tester.getSize(rail).width, workspaceRailWidthCompact);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(workspaceRailEngineKey));
    await tester.pumpAndSettle();
    expect(find.text('Càlcul OEE'), findsOneWidget);
    expect(rail, findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(workspaceRailMapKey));
    await tester.pumpAndSettle();
    expect(find.text('Mapa ISA-95'), findsOneWidget);
    expect(rail, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
