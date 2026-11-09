// Suggeriments a partir de l'abast ja declarat. Sense Flutter, sense xarxa.
// Contracte: specs/redesign/spec.md, secció 14.3

import 'workspace_model.dart';

class FlowSuggestion {
  const FlowSuggestion({required this.sourceId, required this.targetId});

  final String sourceId;
  final String targetId;

  String get key => '$sourceId>$targetId';
}

List<FlowSuggestion> suggestDeclaredScopes(
  Workspace workspace, {
  String? schemaId,
}) {
  final schema = schemaId == null
      ? null
      : workspace.schemas.where((item) => item.id == schemaId).firstOrNull;
  final existing = <String>{
    for (final flow in workspace.flows) '${flow.sourceId}>${flow.targetId}',
  };
  final suggestions = <FlowSuggestion>[];
  for (final system in workspace.systems) {
    if (schema != null && !schema.systemIds.contains(system.id)) {
      continue;
    }
    for (final scopeId in system.scopeIds) {
      final asset = findAsset(workspace, scopeId);
      if (asset == null) {
        continue;
      }
      if (schema != null &&
          !schema.assetIds.contains(asset.id) &&
          !schema.plantIds.contains(asset.id)) {
        continue;
      }
      final key = '${system.id}>${asset.id}';
      if (!existing.add(key)) {
        continue;
      }
      suggestions.add(FlowSuggestion(sourceId: system.id, targetId: asset.id));
    }
  }
  return List.unmodifiable(suggestions);
}
