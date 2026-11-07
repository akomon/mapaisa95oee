import 'package:flutter_test/flutter_test.dart';
import 'package:mapaisa95oee/legacy_migration.dart';
import 'package:mapaisa95oee/plant_model.dart';
import 'package:mapaisa95oee/workspace_model.dart';

void main() {
  test('l\'exemple antic es projecta sense promoure nivells', () {
    final raw = plantToJson(foodPlantExample());
    final copy = raw;
    final result = migrateLegacyPlant(
      copy,
      migratedAt: DateTime.utc(2026, 5, 5, 12),
    );
    expect(
      result.isValid,
      isTrue,
      reason: result.issues.map((issue) => issue.code.name).join(','),
    );
    expect(copy, raw);
    final workspace = result.workspace!;
    expect(workspace.legacyRaw, raw);
    expect(workspace.nextIdCounter, 12);
    expect(workspace.systems, isEmpty);
    expect(workspace.flows, isEmpty);
    expect(workspace.schemas, isEmpty);
    expect(workspace.versions, isEmpty);
    expect(workspace.oeeRecords, isEmpty);
    expect(workspace.organizations.single.id, 'n1');
    expect(workspace.organizations.single.name, 'Alimentària Demo');
    expect(
      workspace.organizations.single.description,
      'Grup alimentari d\'exemple per a cursos.',
    );
    expect(workspace.organizations.single.iconKey, IconKey.organization);
    expect(findAsset(workspace, 'n1'), isNull);

    const expected = {
      'n2': (AssetKind.plant, 'n1', 'Planta Girona'),
      'n3': (AssetKind.area, 'n2', 'Envasat'),
      'n4': (AssetKind.line, 'n3', 'Línia iogurt'),
      'n5': (AssetKind.machine, 'n4', 'Omplidora'),
      'n6': (AssetKind.machine, 'n4', 'Taponadora'),
      'n7': (AssetKind.line, 'n3', 'Línia formatge'),
      'n8': (AssetKind.machine, 'n7', 'Premsadora'),
      'n9': (AssetKind.area, 'n2', 'Emmagatzematge'),
      'n10': (AssetKind.line, 'n9', 'Cambra freda'),
      'n11': (AssetKind.machine, 'n10', 'Sensor temperatura'),
    };
    expect(workspace.assets, hasLength(expected.length));
    for (final asset in workspace.assets) {
      final row = expected[asset.id]!;
      expect(asset.kind, row.$1);
      expect(asset.parentId, row.$2);
      expect(asset.name, row.$3);
      expect(asset.functions, isEmpty);
      expect(asset.iconKey, defaultAssetIcon(asset.kind));
      expect(asset.createdAt, DateTime.utc(2026, 5, 5, 12));
    }
    expect(findAsset(workspace, 'n11')!.iconKey, IconKey.machine);

    expect(workspace.migrationReviews, hasLength(11));
    final enterprise = workspace.migrationReviews.first;
    expect(enterprise.entityId, 'n1');
    expect(enterprise.legacyKind, 'enterprise');
    expect(enterprise.legacyFunctionalLevel, 4);
    expect(enterprise.legacyFunctionalLevelLabel, 'ERP');
    expect(enterprise.promoted, isFalse);
    expect(enterprise.status, ReviewStatus.pendingReview);
    final sensor = workspace.migrationReviews.last;
    expect(sensor.entityId, 'n11');
    expect(sensor.legacyKind, 'cell');
    expect(sensor.legacyFunctionalLevel, 0);
    expect(sensor.legacyFunctionalLevelLabel, 'Procés');
    expect(
      workspace.migrationReviews.every((review) => !review.promoted),
      isTrue,
    );

    final acknowledged = acknowledgeReview(workspace, id: 'review-n1');
    expect(acknowledged.isValid, isTrue);
    expect(
      acknowledged.workspace!.migrationReviews.first.status,
      ReviewStatus.reviewed,
    );
    expect(acknowledged.workspace!.migrationReviews.first.promoted, isFalse);
    expect(acknowledged.workspace!.systems, isEmpty);
  });

  test('un JSON antic invàlid no crea entitats', () {
    const raw = '{bad';
    final result = migrateLegacyPlant(
      raw,
      migratedAt: DateTime.utc(2026, 5, 5),
    );
    expect(result.workspace, isNull);
    expect(result.issues, isNotEmpty);
    expect(result.issues.first.code, WorkspaceIssueCode.invalidJson);
  });
}
