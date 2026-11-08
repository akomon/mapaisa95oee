// Reconciliació no destructiva del mapa antic amb el workspace.
// Contracte: specs/redesign/spec.md, secció 13.2.

import 'legacy_migration.dart';
import 'workspace_codec.dart';
import 'workspace_model.dart';

class LegacyReconciliation {
  const LegacyReconciliation({
    required this.workspace,
    required this.changed,
    required this.rejected,
    this.conflictIds = const [],
    this.message,
  });

  final Workspace workspace;
  final bool changed;
  final bool rejected;
  final List<String> conflictIds;
  final String? message;
}

const String legacyRejectedMessage =
    'El text legacy nou no és vàlid. No s\'ha aplicat. El model anterior i la còpia original es conserven.';

const String legacyConflictMessage =
    'El model canònic s\'ha conservat allà on ja hi havia canvis propis. El text legacy original i el més recent es poden descarregar. Les instantànies i els registres OEE no s\'han modificat.';

LegacyReconciliation reconcileLegacyWorkspace({
  required Workspace workspace,
  required String? currentLegacy,
  required DateTime now,
}) {
  final current = currentLegacy == null || currentLegacy.isEmpty
      ? null
      : currentLegacy;
  if (current == null ||
      current == workspace.reconciledLegacyRaw ||
      (workspace.reconciledLegacyRaw == null &&
          current == workspace.legacyRaw)) {
    return LegacyReconciliation(
      workspace: workspace,
      changed: false,
      rejected: false,
    );
  }

  final projected = migrateLegacyPlant(current, migratedAt: now);
  if (!projected.isValid || projected.workspace == null) {
    final alreadyStored = workspace.latestLegacyRaw == current;
    final next = alreadyStored
        ? workspace
        : workspace.copyWith(latestLegacyRaw: current);
    return LegacyReconciliation(
      workspace: next,
      changed: !alreadyStored,
      rejected: true,
      message: legacyRejectedMessage,
    );
  }

  final incoming = projected.workspace!;
  final baselineRaw = workspace.reconciledLegacyRaw ?? workspace.legacyRaw;
  Workspace? baseline;
  if (baselineRaw != null && baselineRaw.isNotEmpty) {
    final parsed = migrateLegacyPlant(baselineRaw, migratedAt: now);
    if (parsed.isValid) {
      baseline = parsed.workspace;
    }
  }

  final conflicts = <String>[];
  var organizations = [...workspace.organizations];
  var assets = [...workspace.assets];
  var reviews = [...workspace.migrationReviews];

  bool idTaken(String id) {
    return organizations.any((item) => item.id == id) ||
        assets.any((item) => item.id == id) ||
        findSystem(workspace, id) != null ||
        findFlow(workspace, id) != null ||
        workspace.schemas.any((item) => item.id == id) ||
        workspace.versions.any((item) => item.id == id) ||
        workspace.oeeRecords.any((item) => item.id == id);
  }

  void addReview(MigrationReview review) {
    if (reviews.any((item) => item.id == review.id)) {
      return;
    }
    reviews.add(
      MigrationReview(
        id: review.id,
        entityId: review.entityId,
        legacyKind: review.legacyKind,
        legacyFunctionalLevel: review.legacyFunctionalLevel,
        legacyFunctionalLevelLabel: review.legacyFunctionalLevelLabel,
        promoted: false,
        status: ReviewStatus.pendingReview,
      ),
    );
  }

  MigrationReview? reviewFor(String entityId) {
    for (final review in incoming.migrationReviews) {
      if (review.entityId == entityId) {
        return review;
      }
    }
    return null;
  }

  for (final incomingOrg in incoming.organizations) {
    final index = organizations.indexWhere((item) => item.id == incomingOrg.id);
    if (index >= 0) {
      final live = organizations[index];
      final base = baseline == null
          ? null
          : findOrganization(baseline, incomingOrg.id);
      final sameAsLive =
          live.name == incomingOrg.name &&
          live.description == incomingOrg.description;
      final untouched =
          base != null &&
          live.name == base.name &&
          live.description == base.description;
      if (!sameAsLive && untouched) {
        organizations[index] = live.copyWith(
          name: incomingOrg.name,
          description: incomingOrg.description,
          clearDescription: incomingOrg.description == null,
          updatedAt: now.toUtc(),
        );
      } else if (!sameAsLive) {
        conflicts.add(incomingOrg.id);
      }
      continue;
    }
    if (idTaken(incomingOrg.id)) {
      conflicts.add(incomingOrg.id);
      continue;
    }
    organizations.add(
      Organization(
        id: incomingOrg.id,
        name: incomingOrg.name,
        description: incomingOrg.description,
        createdAt: now.toUtc(),
        updatedAt: now.toUtc(),
      ),
    );
    final review = reviewFor(incomingOrg.id);
    if (review != null) {
      addReview(review);
    }
  }

  final orderedAssets = [...incoming.assets]
    ..sort((left, right) {
      return _depth(incoming, left).compareTo(_depth(incoming, right));
    });

  bool parentFits(AssetKind kind, String parentId) {
    switch (kind) {
      case AssetKind.plant:
        return organizations.any((item) => item.id == parentId);
      case AssetKind.area:
        return assets.any(
          (item) => item.id == parentId && item.kind == AssetKind.plant,
        );
      case AssetKind.line:
        return assets.any(
          (item) => item.id == parentId && item.kind == AssetKind.area,
        );
      case AssetKind.machine:
        return assets.any(
          (item) => item.id == parentId && item.kind == AssetKind.line,
        );
    }
  }

  bool parentCycles(String assetId, String parentId) {
    final byId = {for (final asset in assets) asset.id: asset};
    final seen = <String>{};
    var current = parentId;
    while (true) {
      if (current == assetId) {
        return true;
      }
      if (!seen.add(current)) {
        return true;
      }
      final parent = byId[current];
      if (parent == null) {
        return false;
      }
      current = parent.parentId;
    }
  }

  for (final incomingAsset in orderedAssets) {
    final index = assets.indexWhere((item) => item.id == incomingAsset.id);
    if (index >= 0) {
      final live = assets[index];
      if (live.kind != incomingAsset.kind) {
        conflicts.add(incomingAsset.id);
        continue;
      }
      final base = baseline == null
          ? null
          : findAsset(baseline, incomingAsset.id);
      final untouched =
          base != null &&
          live.name == base.name &&
          live.description == base.description &&
          live.parentId == base.parentId;
      final sameName =
          live.name == incomingAsset.name &&
          live.description == incomingAsset.description;
      final sameParent = live.parentId == incomingAsset.parentId;
      if (untouched && (!sameName || !sameParent)) {
        var parentId = live.parentId;
        if (!sameParent) {
          if (parentFits(live.kind, incomingAsset.parentId) &&
              !parentCycles(live.id, incomingAsset.parentId)) {
            parentId = incomingAsset.parentId;
          } else {
            conflicts.add(incomingAsset.id);
          }
        }
        assets[index] = live.copyWith(
          name: incomingAsset.name,
          description: incomingAsset.description,
          clearDescription: incomingAsset.description == null,
          parentId: parentId,
          updatedAt: now.toUtc(),
        );
      } else if (!sameName || !sameParent) {
        conflicts.add(incomingAsset.id);
      }
      continue;
    }
    if (idTaken(incomingAsset.id)) {
      conflicts.add(incomingAsset.id);
      continue;
    }
    if (!parentFits(incomingAsset.kind, incomingAsset.parentId) ||
        parentCycles(incomingAsset.id, incomingAsset.parentId)) {
      conflicts.add(incomingAsset.id);
      continue;
    }
    assets.add(
      Asset(
        id: incomingAsset.id,
        name: incomingAsset.name,
        description: incomingAsset.description,
        kind: incomingAsset.kind,
        parentId: incomingAsset.parentId,
        iconKey: defaultAssetIcon(incomingAsset.kind),
        createdAt: now.toUtc(),
        updatedAt: now.toUtc(),
      ),
    );
    final review = reviewFor(incomingAsset.id);
    if (review != null) {
      addReview(review);
    }
  }

  var counter = workspace.nextIdCounter < incoming.nextIdCounter
      ? incoming.nextIdCounter
      : workspace.nextIdCounter;
  for (final id in [
    ...organizations.map((item) => item.id),
    ...assets.map((item) => item.id),
    ...workspace.systems.map((item) => item.id),
    ...workspace.flows.map((item) => item.id),
  ]) {
    if (!id.startsWith('n')) {
      continue;
    }
    final parsed = int.tryParse(id.substring(1));
    if (parsed != null && parsed + 1 > counter) {
      counter = parsed + 1;
    }
  }

  final original = workspace.legacyRaw ?? current;
  final latest = current == original ? workspace.latestLegacyRaw : current;
  final next = workspace.copyWith(
    nextIdCounter: counter,
    organizations: organizations,
    assets: assets,
    migrationReviews: reviews,
    legacyRaw: original,
    latestLegacyRaw: latest,
    clearLatestLegacyRaw: latest == null && current == original,
    reconciledLegacyRaw: current,
  );
  final checked = workspaceFromJson(workspaceToJson(next));
  if (!checked.isValid || checked.workspace == null) {
    final stored = workspace.latestLegacyRaw == current;
    return LegacyReconciliation(
      workspace: stored
          ? workspace
          : workspace.copyWith(latestLegacyRaw: current),
      changed: !stored,
      rejected: true,
      message: legacyRejectedMessage,
    );
  }
  final distinct = conflicts.toSet().toList()..sort();
  return LegacyReconciliation(
    workspace: checked.workspace!,
    changed: workspaceToJson(checked.workspace!) != workspaceToJson(workspace),
    rejected: false,
    conflictIds: distinct,
    message: distinct.isEmpty ? null : legacyConflictMessage,
  );
}

int _depth(Workspace workspace, Asset asset) {
  var depth = 1;
  var parentId = asset.parentId;
  final seen = <String>{asset.id};
  while (seen.add(parentId)) {
    final parent = findAsset(workspace, parentId);
    if (parent == null) {
      return depth;
    }
    depth += 1;
    parentId = parent.parentId;
  }
  return depth;
}
