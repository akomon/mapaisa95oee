// Migració no destructiva del mapa ISA-95 antic.
// Contracte: specs/redesign/spec.md, secció 6.2.

import 'plant_model.dart';
import 'workspace_codec.dart';
import 'workspace_model.dart';

class LegacyMigrationResult {
  const LegacyMigrationResult.success(this.workspace) : issues = const [];

  const LegacyMigrationResult.failure(this.issues) : workspace = null;

  final Workspace? workspace;
  final List<WorkspaceIssue> issues;

  bool get isValid => workspace != null;
}

/// Projecta [raw] sense modificar-lo. El resultat només és vàlid si el
/// document nou supera el mateix validador que una còpia.
LegacyMigrationResult migrateLegacyPlant(
  String raw, {
  required DateTime migratedAt,
}) {
  final imported = plantFromJson(raw);
  if (!imported.isValid || imported.plant == null) {
    return LegacyMigrationResult.failure(_fromPlantIssues(imported.issues));
  }
  final plant = imported.plant!;
  final stamp = migratedAt.toUtc();
  final organizations = <Organization>[];
  final assets = <Asset>[];
  final reviews = <MigrationReview>[];

  void walk(PlantNode node, String? parentId) {
    reviews.add(
      MigrationReview(
        id: 'review-${node.id}',
        entityId: node.id,
        legacyKind: node.kind.name,
        legacyFunctionalLevel: node.functionalLevel.value,
        legacyFunctionalLevelLabel:
            legacyFunctionalLevelLabels[node.functionalLevel.value],
        promoted: false,
        status: ReviewStatus.pendingReview,
      ),
    );
    switch (node.kind) {
      case PlantNodeKind.enterprise:
        organizations.add(
          Organization(
            id: node.id,
            name: node.name,
            description: node.description,
            createdAt: stamp,
            updatedAt: stamp,
          ),
        );
      case PlantNodeKind.site:
      case PlantNodeKind.area:
      case PlantNodeKind.line:
      case PlantNodeKind.cell:
        final kind = switch (node.kind) {
          PlantNodeKind.site => AssetKind.plant,
          PlantNodeKind.area => AssetKind.area,
          PlantNodeKind.line => AssetKind.line,
          PlantNodeKind.cell => AssetKind.machine,
          PlantNodeKind.enterprise => AssetKind.plant,
        };
        assets.add(
          Asset(
            id: node.id,
            name: node.name,
            description: node.description,
            kind: kind,
            parentId: parentId ?? '',
            iconKey: defaultAssetIcon(kind),
            createdAt: stamp,
            updatedAt: stamp,
          ),
        );
    }
    for (final child in node.children) {
      walk(child, node.id);
    }
  }

  for (final root in plant.roots) {
    walk(root, null);
  }

  final candidate = Workspace(
    nextIdCounter: plant.nextIdCounter < 1 ? 1 : plant.nextIdCounter,
    organizations: organizations,
    assets: assets,
    migrationReviews: reviews,
    legacyRaw: raw,
  );
  final checked = workspaceFromJson(workspaceToJson(candidate));
  if (!checked.isValid || checked.workspace == null) {
    return LegacyMigrationResult.failure(
      checked.issues.isEmpty
          ? const [WorkspaceIssue(WorkspaceIssueCode.invalidJson)]
          : checked.issues,
    );
  }
  return LegacyMigrationResult.success(checked.workspace!);
}

List<WorkspaceIssue> _fromPlantIssues(List<PlantIssueCode> issues) {
  final mapped = [
    for (final issue in issues)
      WorkspaceIssue(switch (issue) {
        PlantIssueCode.emptyName => WorkspaceIssueCode.emptyName,
        PlantIssueCode.invalidFunctionalLevel =>
          WorkspaceIssueCode.invalidField,
        PlantIssueCode.invalidKind => WorkspaceIssueCode.invalidField,
        PlantIssueCode.hierarchyViolation =>
          WorkspaceIssueCode.incompatibleParent,
        PlantIssueCode.duplicateId => WorkspaceIssueCode.duplicateId,
        PlantIssueCode.nodeNotFound => WorkspaceIssueCode.notFound,
        PlantIssueCode.invalidJson => WorkspaceIssueCode.invalidJson,
      }),
  ];
  if (mapped.isEmpty) {
    return const [WorkspaceIssue(WorkspaceIssueCode.invalidJson)];
  }
  mapped.sort((left, right) => left.code.index.compareTo(right.code.index));
  return List.unmodifiable(mapped);
}
