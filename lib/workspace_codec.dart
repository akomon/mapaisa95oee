// Còpia JSON formatVersion 1. Sense Flutter.
// Contracte: specs/redesign/spec.md

import 'dart:convert';

import 'workspace_model.dart';

class WorkspaceImport {
  const WorkspaceImport.success(this.workspace) : issues = const [];

  const WorkspaceImport.failure(this.issues) : workspace = null;

  final Workspace? workspace;
  final List<WorkspaceIssue> issues;

  bool get isValid => workspace != null;
}

String encodeTimestamp(DateTime value) => value.toUtc().toIso8601String();

String workspaceToJson(Workspace workspace) {
  return _encode(workspace, exportedAt: null);
}

String workspaceToBackupJson(
  Workspace workspace, {
  required DateTime exportedAt,
}) {
  return _encode(workspace, exportedAt: exportedAt.toUtc());
}

String architectureVersionsJson(Workspace workspace) {
  return const JsonEncoder.withIndent('  ').convert([
    for (final version in workspace.versions) _versionToJson(version),
  ]);
}

String oeeRecordsJson(Workspace workspace) {
  return const JsonEncoder.withIndent('  ')
      .convert([for (final record in workspace.oeeRecords) _oeeToJson(record)]);
}

String _encode(Workspace workspace, {required DateTime? exportedAt}) {
  final map = <String, Object?>{
    'formatVersion': 1,
    if (exportedAt != null) 'exportedAt': encodeTimestamp(exportedAt),
    'nextIdCounter': workspace.nextIdCounter,
    'organizations': [
      for (final item in workspace.organizations) _organizationToJson(item),
    ],
    'assets': [for (final item in workspace.assets) _assetToJson(item)],
    'systems': [for (final item in workspace.systems) _systemToJson(item)],
    'flows': [for (final item in workspace.flows) _flowToJson(item)],
    'schemas': [for (final item in workspace.schemas) _schemaToJson(item)],
    'architectureVersions': [
      for (final item in workspace.versions) _versionToJson(item),
    ],
    'oeeRecords': [for (final item in workspace.oeeRecords) _oeeToJson(item)],
    'migrationReviews': [
      for (final item in workspace.migrationReviews) _reviewToJson(item),
    ],
    'legacyRaw': workspace.legacyRaw,
    'latestLegacyRaw': workspace.latestLegacyRaw,
    'reconciledLegacyRaw': workspace.reconciledLegacyRaw,
  };
  return const JsonEncoder.withIndent('  ').convert(map);
}

Map<String, Object?> _organizationToJson(Organization item) {
  return {
    'id': item.id,
    'name': item.name,
    'description': item.description,
    'iconKey': item.iconKey.name,
    'createdAt': encodeTimestamp(item.createdAt),
    'updatedAt': encodeTimestamp(item.updatedAt),
  };
}

Map<String, Object?> _assetToJson(Asset item) {
  return {
    'id': item.id,
    'name': item.name,
    'description': item.description,
    'kind': item.kind.name,
    'parentId': item.parentId,
    'iconKey': item.iconKey.name,
    'functions': [for (final function in item.functions) function.name],
    'createdAt': encodeTimestamp(item.createdAt),
    'updatedAt': encodeTimestamp(item.updatedAt),
  };
}

Map<String, Object?> _systemToJson(WorkSystem item) {
  return {
    'id': item.id,
    'name': item.name,
    'description': item.description,
    'systemType': item.systemType.name,
    'iconKey': item.iconKey.name,
    'scopeIds': item.scopeIds,
    'functions': [for (final function in item.functions) function.name],
    'zone': item.zone.name,
    'createdAt': encodeTimestamp(item.createdAt),
    'updatedAt': encodeTimestamp(item.updatedAt),
  };
}

Map<String, Object?> _flowToJson(ExchangeFlow item) {
  return {
    'id': item.id,
    'name': item.name,
    'description': item.description,
    'sourceId': item.sourceId,
    'targetId': item.targetId,
    'exchangedData': item.exchangedData,
    'protocol': item.protocol,
    'purpose': item.purpose,
    'status': item.status.name,
    'createdAt': encodeTimestamp(item.createdAt),
    'updatedAt': encodeTimestamp(item.updatedAt),
  };
}

Map<String, Object?> _schemaToJson(WorkSchema item) {
  return {
    'id': item.id,
    'name': item.name,
    'description': item.description,
    'plantIds': item.plantIds,
    'assetIds': item.assetIds,
    'systemIds': item.systemIds,
    'flowIds': item.flowIds,
    'layout': {
      for (final entry in item.layout.entries)
        entry.key: {'x': entry.value.x, 'y': entry.value.y},
    },
    'createdAt': encodeTimestamp(item.createdAt),
    'updatedAt': encodeTimestamp(item.updatedAt),
  };
}

Map<String, Object?> _snapshotToJson(ArchitectureSnapshot snapshot) {
  return {
    'schema': _schemaToJson(snapshot.schema),
    'organizations': [
      for (final item in snapshot.organizations) _organizationToJson(item),
    ],
    'assets': [for (final item in snapshot.assets) _assetToJson(item)],
    'systems': [for (final item in snapshot.systems) _systemToJson(item)],
    'flows': [for (final item in snapshot.flows) _flowToJson(item)],
  };
}

Map<String, Object?> _versionToJson(ArchitectureVersion item) {
  return {
    'id': item.id,
    'schemaId': item.schemaId,
    'createdAt': encodeTimestamp(item.createdAt),
    'note': item.note,
    'parentVersionId': item.parentVersionId,
    'snapshot': _snapshotToJson(item.snapshot),
  };
}

Map<String, Object?> _oeeToJson(OeeRecord item) {
  return {
    'id': item.id,
    'productionDate': item.productionDate,
    'shift': item.shift,
    'lineId': item.lineId,
    'article': item.article,
    'lot': item.lot,
    'plannedMinutes': item.plannedMinutes,
    'downtimeMinutes': item.downtimeMinutes,
    'speedOriginal': item.speedOriginal,
    'speedUnit': item.speedUnit.name,
    'idealCycleSeconds': item.idealCycleSeconds,
    'totalUnits': item.totalUnits,
    'goodUnits': item.goodUnits,
    'status': item.status.name,
    'formulaVersion': item.formulaVersion,
    'capturedLineName': item.capturedLineName,
    'capturedPlantName': item.capturedPlantName,
    'createdAt': encodeTimestamp(item.createdAt),
    'updatedAt': encodeTimestamp(item.updatedAt),
    if (item.replacesId != null) 'replacesId': item.replacesId,
  };
}

Map<String, Object?> _reviewToJson(MigrationReview item) {
  return {
    'id': item.id,
    'entityId': item.entityId,
    'legacyKind': item.legacyKind,
    'legacyFunctionalLevel': item.legacyFunctionalLevel,
    'legacyFunctionalLevelLabel': item.legacyFunctionalLevelLabel,
    'promoted': item.promoted,
    'status': item.status.name,
  };
}

WorkspaceImport workspaceFromJson(String raw) {
  final parser = _Parser();
  final decoded = parser.decodeObject(raw);
  if (decoded == null) {
    return parser.finish();
  }
  if (!decoded.containsKey('formatVersion') &&
      decoded['version'] == 1 &&
      decoded['nodes'] is List) {
    parser.add(WorkspaceIssueCode.legacyFileNeedsMigration);
    return parser.finish(only: true);
  }
  if (decoded['formatVersion'] != 1) {
    parser.add(WorkspaceIssueCode.unsupportedVersion);
    return parser.finish(only: true);
  }
  if (decoded.containsKey('exportedAt')) {
    parser.timestamp(decoded['exportedAt'], 'exportedAt');
  }
  final counter = parser.counter(decoded['nextIdCounter']);
  parser.requireKeys(decoded, const [
    'nextIdCounter',
    'organizations',
    'assets',
    'systems',
    'flows',
    'schemas',
    'architectureVersions',
    'oeeRecords',
    'migrationReviews',
    'legacyRaw',
  ]);
  final organizations = parser.organizations(decoded['organizations']);
  final assets = parser.assets(decoded['assets']);
  final systems = parser.systems(decoded['systems']);
  final flows = parser.flows(decoded['flows']);
  final schemas = parser.schemas(decoded['schemas']);
  final versions = parser.versions(decoded['architectureVersions']);
  final records = parser.records(decoded['oeeRecords']);
  final reviews = parser.reviews(decoded['migrationReviews']);
  final legacyRaw = parser.legacyRaw(decoded['legacyRaw']);
  final latestLegacyRaw = parser.optionalLegacy(decoded, 'latestLegacyRaw');
  final reconciledLegacyRaw = parser.optionalLegacy(
    decoded,
    'reconciledLegacyRaw',
  );
  if (parser.failed || counter == null) {
    return parser.finish();
  }
  parser.validateBundle(
    organizations: organizations,
    assets: assets,
    systems: systems,
    flows: flows,
    schemas: schemas,
  );
  parser.validateVersions(
    versions: versions,
    liveSchemaIds: {for (final schema in schemas) schema.id},
  );
  parser.validateRecords(records: records, assets: assets);
  parser.validateReviews(
    reviews: reviews,
    organizations: organizations,
    assets: assets,
  );
  parser.validateLiveIds(
    organizations: organizations,
    assets: assets,
    systems: systems,
    flows: flows,
    schemas: schemas,
    versions: versions,
    records: records,
  );
  if (parser.failed) {
    return parser.finish();
  }
  return WorkspaceImport.success(
    Workspace(
      nextIdCounter: counter,
      organizations: organizations,
      assets: assets,
      systems: systems,
      flows: flows,
      schemas: schemas,
      versions: versions,
      oeeRecords: records,
      migrationReviews: reviews,
      legacyRaw: legacyRaw,
      latestLegacyRaw: latestLegacyRaw,
      reconciledLegacyRaw: reconciledLegacyRaw,
    ),
  );
}

class _Parser {
  final issues = <WorkspaceIssue>[];

  bool get failed => issues.isNotEmpty;

  void add(WorkspaceIssueCode code, {String? field, String? entityId}) {
    issues.add(WorkspaceIssue(code, field: field, entityId: entityId));
  }

  WorkspaceImport finish({bool only = false}) {
    final unique = <String, WorkspaceIssue>{};
    for (final issue in issues) {
      unique.putIfAbsent(
        '${issue.code.name}|${issue.field}|${issue.entityId}',
        () => issue,
      );
    }
    final ordered = unique.values.toList()
      ..sort((left, right) => left.code.index.compareTo(right.code.index));
    if (only && ordered.length > 1) {
      return WorkspaceImport.failure([ordered.first]);
    }
    return WorkspaceImport.failure(List.unmodifiable(ordered));
  }

  Map<String, dynamic>? decodeObject(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } on FormatException {
      add(WorkspaceIssueCode.invalidJson);
      return null;
    }
    add(WorkspaceIssueCode.invalidJson);
    return null;
  }

  void requireKeys(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (!map.containsKey(key)) {
        add(WorkspaceIssueCode.invalidJson, field: key);
      }
    }
  }

  Map<String, dynamic>? mapValue(Object? value, String field) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    add(WorkspaceIssueCode.invalidJson, field: field);
    return null;
  }

  List<Map<String, dynamic>>? mapList(Object? value, String field) {
    if (value is! List) {
      add(WorkspaceIssueCode.invalidJson, field: field);
      return null;
    }
    final result = <Map<String, dynamic>>[];
    for (final item in value) {
      if (item is Map) {
        result.add(Map<String, dynamic>.from(item));
      } else {
        add(WorkspaceIssueCode.invalidJson, field: field);
      }
    }
    return result;
  }

  String? text(Object? value, String field, {bool name = false}) {
    if (value is! String) {
      add(WorkspaceIssueCode.invalidJson, field: field);
      return null;
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      add(
        name ? WorkspaceIssueCode.emptyName : WorkspaceIssueCode.invalidField,
        field: field,
      );
      return null;
    }
    return trimmed;
  }

  String? idText(Object? value, String field) {
    if (value is! String || value.isEmpty) {
      add(WorkspaceIssueCode.invalidJson, field: field);
      return null;
    }
    return value;
  }

  DateTime? timestamp(Object? value, String field) {
    if (value is! String || !value.endsWith('Z')) {
      add(WorkspaceIssueCode.invalidField, field: field);
      return null;
    }
    try {
      final parsed = DateTime.parse(value);
      if (!parsed.isUtc) {
        add(WorkspaceIssueCode.invalidField, field: field);
        return null;
      }
      return parsed;
    } on FormatException {
      add(WorkspaceIssueCode.invalidField, field: field);
      return null;
    }
  }

  int? counter(Object? value) {
    if (value is! int || value < 1) {
      add(WorkspaceIssueCode.invalidField, field: 'nextIdCounter');
      return null;
    }
    return value;
  }

  double? finite(Object? value, String field) {
    if (value is int) {
      return value.toDouble();
    }
    if (value is double && value.isFinite) {
      return value;
    }
    add(WorkspaceIssueCode.invalidField, field: field);
    return null;
  }

  int? integer(Object? value, String field) {
    if (value is int) {
      return value;
    }
    if (value is double && value.isFinite && value == value.roundToDouble()) {
      return value.toInt();
    }
    add(WorkspaceIssueCode.invalidField, field: field);
    return null;
  }

  T? enumValue<T extends Enum>(List<T> values, Object? raw, String field) {
    if (raw is! String) {
      add(WorkspaceIssueCode.invalidField, field: field);
      return null;
    }
    for (final value in values) {
      if (value.name == raw) {
        return value;
      }
    }
    add(WorkspaceIssueCode.invalidField, field: field);
    return null;
  }

  String? optionalDescription(Map<String, dynamic> map) {
    if (!map.containsKey('description')) {
      add(WorkspaceIssueCode.invalidJson, field: 'description');
      return null;
    }
    final value = map['description'];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      add(WorkspaceIssueCode.invalidJson, field: 'description');
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void rejectForbidden(
    Map<String, dynamic> map,
    Set<String> forbidden,
    WorkspaceIssueCode code,
  ) {
    for (final key in forbidden) {
      if (map.containsKey(key)) {
        add(code, field: key);
      }
    }
  }

  List<String> stringList(Object? value, String field) {
    if (value is! List) {
      add(WorkspaceIssueCode.invalidJson, field: field);
      return const [];
    }
    final result = <String>[];
    for (final item in value) {
      if (item is String && item.isNotEmpty) {
        result.add(item);
      } else {
        add(WorkspaceIssueCode.invalidField, field: field);
      }
    }
    return result;
  }

  List<IsaFunction> functionsOf(Object? value) {
    if (value is! List) {
      add(WorkspaceIssueCode.invalidJson, field: 'functions');
      return const [];
    }
    final result = <IsaFunction>[];
    for (final item in value) {
      final function = enumValue(IsaFunction.values, item, 'functions');
      if (function != null) {
        result.add(function);
      }
    }
    if (result.toSet().length != result.length) {
      add(WorkspaceIssueCode.invalidField, field: 'functions');
    }
    final selected = result.toSet();
    return [
      for (final function in IsaFunction.values)
        if (selected.contains(function)) function,
    ];
  }

  List<Organization> organizations(Object? value) {
    final rows = mapList(value, 'organizations');
    if (rows == null) {
      return const [];
    }
    final result = <Organization>[];
    for (final row in rows) {
      rejectForbidden(row, const {
        'functions',
        'functionalLevel',
        'parentId',
        'systemType',
        'zone',
      }, WorkspaceIssueCode.functionsNotAssignable);
      final id = idText(row['id'], 'id');
      final name = text(row['name'], 'name', name: true);
      final createdAt = timestamp(row['createdAt'], 'createdAt');
      final updatedAt = timestamp(row['updatedAt'], 'updatedAt');
      final icon = enumValue(IconKey.values, row['iconKey'], 'iconKey');
      final description = optionalDescription(row);
      if (icon != null && icon != IconKey.organization) {
        add(WorkspaceIssueCode.invalidField, field: 'iconKey', entityId: id);
      }
      if (id == null ||
          name == null ||
          createdAt == null ||
          updatedAt == null ||
          icon == null) {
        continue;
      }
      result.add(
        Organization(
          id: id,
          name: name.trim().isEmpty ? name : name.trim(),
          description: description,
          iconKey: IconKey.organization,
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      );
    }
    return result;
  }

  List<Asset> assets(Object? value) {
    final rows = mapList(value, 'assets');
    if (rows == null) {
      return const [];
    }
    final result = <Asset>[];
    for (final row in rows) {
      if (row.containsKey('functionalLevel')) {
        add(
          WorkspaceIssueCode.functionsNotAssignable,
          field: 'functionalLevel',
        );
      }
      final id = idText(row['id'], 'id');
      final name = text(row['name'], 'name', name: true);
      final kind = enumValue(AssetKind.values, row['kind'], 'kind');
      final parentId = idText(row['parentId'], 'parentId');
      final icon = enumValue(IconKey.values, row['iconKey'], 'iconKey');
      final createdAt = timestamp(row['createdAt'], 'createdAt');
      final updatedAt = timestamp(row['updatedAt'], 'updatedAt');
      final functions = functionsOf(row['functions']);
      final description = optionalDescription(row);
      if (icon != null && !assetIconKeys.contains(icon)) {
        add(WorkspaceIssueCode.invalidField, field: 'iconKey', entityId: id);
      }
      if (id == null ||
          name == null ||
          kind == null ||
          parentId == null ||
          icon == null ||
          createdAt == null ||
          updatedAt == null ||
          !assetIconKeys.contains(icon)) {
        continue;
      }
      result.add(
        Asset(
          id: id,
          name: name.trim().isEmpty ? name : name.trim(),
          description: description,
          kind: kind,
          parentId: parentId,
          iconKey: icon,
          functions: functions,
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      );
    }
    return result;
  }

  List<WorkSystem> systems(Object? value) {
    final rows = mapList(value, 'systems');
    if (rows == null) {
      return const [];
    }
    final result = <WorkSystem>[];
    for (final row in rows) {
      if (row.containsKey('parentId') || row.containsKey('functionalLevel')) {
        add(
          WorkspaceIssueCode.invalidField,
          field: row.containsKey('parentId') ? 'parentId' : 'functionalLevel',
        );
      }
      final id = idText(row['id'], 'id');
      final name = text(row['name'], 'name', name: true);
      final type = enumValue(
        SystemType.values,
        row['systemType'],
        'systemType',
      );
      final icon = enumValue(IconKey.values, row['iconKey'], 'iconKey');
      final zone = enumValue(ItOtZone.values, row['zone'], 'zone');
      final createdAt = timestamp(row['createdAt'], 'createdAt');
      final updatedAt = timestamp(row['updatedAt'], 'updatedAt');
      final scopeIds = stringList(row['scopeIds'], 'scopeIds');
      final functions = functionsOf(row['functions']);
      final description = optionalDescription(row);
      if (icon != null && !systemIconKeys.contains(icon)) {
        add(WorkspaceIssueCode.invalidField, field: 'iconKey', entityId: id);
      }
      if (id == null ||
          name == null ||
          type == null ||
          icon == null ||
          zone == null ||
          createdAt == null ||
          updatedAt == null ||
          !systemIconKeys.contains(icon)) {
        continue;
      }
      result.add(
        WorkSystem(
          id: id,
          name: name.trim().isEmpty ? name : name.trim(),
          description: description,
          systemType: type,
          iconKey: icon,
          scopeIds: scopeIds,
          functions: functions,
          zone: zone,
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      );
    }
    return result;
  }

  List<ExchangeFlow> flows(Object? value) {
    final rows = mapList(value, 'flows');
    if (rows == null) {
      return const [];
    }
    final result = <ExchangeFlow>[];
    for (final row in rows) {
      final id = idText(row['id'], 'id');
      final name = text(row['name'], 'name', name: true);
      final sourceId = idText(row['sourceId'], 'sourceId');
      final targetId = idText(row['targetId'], 'targetId');
      final data = text(row['exchangedData'], 'exchangedData');
      final purpose = text(row['purpose'], 'purpose');
      final status = enumValue(FlowStatus.values, row['status'], 'status');
      final createdAt = timestamp(row['createdAt'], 'createdAt');
      final updatedAt = timestamp(row['updatedAt'], 'updatedAt');
      final description = optionalDescription(row);
      String? protocol;
      var protocolOk = true;
      if (!row.containsKey('protocol')) {
        add(WorkspaceIssueCode.invalidJson, field: 'protocol');
        protocolOk = false;
      } else if (row['protocol'] == null) {
        protocol = null;
      } else if (row['protocol'] is String &&
          (row['protocol'] as String).trim().isNotEmpty) {
        protocol = (row['protocol'] as String).trim();
      } else {
        add(WorkspaceIssueCode.invalidField, field: 'protocol');
        protocolOk = false;
      }
      if (data != null && data.trim().isEmpty) {
        add(WorkspaceIssueCode.invalidField, field: 'exchangedData');
      }
      if (purpose != null && purpose.trim().isEmpty) {
        add(WorkspaceIssueCode.invalidField, field: 'purpose');
      }
      if (id == null ||
          name == null ||
          sourceId == null ||
          targetId == null ||
          data == null ||
          purpose == null ||
          status == null ||
          createdAt == null ||
          updatedAt == null ||
          !protocolOk ||
          data.trim().isEmpty ||
          purpose.trim().isEmpty) {
        continue;
      }
      result.add(
        ExchangeFlow(
          id: id,
          name: name.trim().isEmpty ? name : name.trim(),
          description: description,
          sourceId: sourceId,
          targetId: targetId,
          exchangedData: data.trim(),
          protocol: protocol,
          purpose: purpose.trim(),
          status: status,
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      );
    }
    return result;
  }

  WorkSchema? schemaMap(Map<String, dynamic> row) {
    final id = idText(row['id'], 'id');
    final name = text(row['name'], 'name', name: true);
    final createdAt = timestamp(row['createdAt'], 'createdAt');
    final updatedAt = timestamp(row['updatedAt'], 'updatedAt');
    final description = optionalDescription(row);
    final plantIds = stringList(row['plantIds'], 'plantIds');
    final assetIds = stringList(row['assetIds'], 'assetIds');
    final systemIds = stringList(row['systemIds'], 'systemIds');
    final flowIds = stringList(row['flowIds'], 'flowIds');
    final layout = <String, LayoutPoint>{};
    final rawLayout = row['layout'];
    if (rawLayout is! Map) {
      add(WorkspaceIssueCode.invalidJson, field: 'layout');
    } else {
      for (final entry in rawLayout.entries) {
        if (entry.key is! String || entry.value is! Map) {
          add(WorkspaceIssueCode.invalidField, field: 'layout');
          continue;
        }
        final point = Map<String, dynamic>.from(entry.value as Map);
        final x = finite(point['x'], 'layout');
        final y = finite(point['y'], 'layout');
        if (x == null || y == null) {
          continue;
        }
        layout[entry.key as String] = LayoutPoint(x, y);
      }
    }
    if (id == null ||
        name == null ||
        createdAt == null ||
        updatedAt == null ||
        rawLayout is! Map) {
      return null;
    }
    return WorkSchema(
      id: id,
      name: name.trim().isEmpty ? name : name.trim(),
      description: description,
      plantIds: plantIds,
      assetIds: assetIds,
      systemIds: systemIds,
      flowIds: flowIds,
      layout: layout,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  List<WorkSchema> schemas(Object? value) {
    final rows = mapList(value, 'schemas');
    if (rows == null) {
      return const [];
    }
    final result = <WorkSchema>[];
    for (final row in rows) {
      final parsed = schemaMap(row);
      if (parsed != null) {
        result.add(parsed);
      }
    }
    return result;
  }

  ArchitectureSnapshot? snapshot(Object? value) {
    final row = mapValue(value, 'snapshot');
    if (row == null) {
      return null;
    }
    const allowed = {'schema', 'organizations', 'assets', 'systems', 'flows'};
    for (final key in row.keys) {
      if (!allowed.contains(key)) {
        add(WorkspaceIssueCode.invalidField, field: 'snapshot');
      }
    }
    final schemaRow = mapValue(row['schema'], 'schema');
    final schema = schemaRow == null ? null : schemaMap(schemaRow);
    final organizations = this.organizations(row['organizations']);
    final assets = this.assets(row['assets']);
    final systems = this.systems(row['systems']);
    final flows = this.flows(row['flows']);
    if (schema == null) {
      return null;
    }
    validateBundle(
      organizations: organizations,
      assets: assets,
      systems: systems,
      flows: flows,
      schemas: [schema],
    );
    return ArchitectureSnapshot(
      schema: schema,
      organizations: organizations,
      assets: assets,
      systems: systems,
      flows: flows,
    );
  }

  List<ArchitectureVersion> versions(Object? value) {
    final rows = mapList(value, 'architectureVersions');
    if (rows == null) {
      return const [];
    }
    final result = <ArchitectureVersion>[];
    for (final row in rows) {
      final id = idText(row['id'], 'id');
      final schemaId = idText(row['schemaId'], 'schemaId');
      final createdAt = timestamp(row['createdAt'], 'createdAt');
      final note = row['note'];
      final parent = row['parentVersionId'];
      final snap = snapshot(row['snapshot']);
      if (note is! String) {
        add(WorkspaceIssueCode.invalidField, field: 'note');
      }
      String? parentId;
      if (parent != null && parent is! String) {
        add(WorkspaceIssueCode.invalidField, field: 'parentVersionId');
      } else {
        parentId = parent as String?;
      }
      if (schemaId != null && snap != null && snap.schema.id != schemaId) {
        add(WorkspaceIssueCode.invalidField, field: 'schemaId', entityId: id);
      }
      if (id == null ||
          schemaId == null ||
          createdAt == null ||
          note is! String ||
          snap == null) {
        continue;
      }
      result.add(
        ArchitectureVersion(
          id: id,
          schemaId: schemaId,
          createdAt: createdAt,
          note: note,
          parentVersionId: parentId,
          snapshot: snap,
        ),
      );
    }
    return result;
  }

  bool productionDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) {
      return false;
    }
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime.utc(year, month, day);
    return date.year == year && date.month == month && date.day == day;
  }

  List<OeeRecord> records(Object? value) {
    final rows = mapList(value, 'oeeRecords');
    if (rows == null) {
      return const [];
    }
    final result = <OeeRecord>[];
    for (final row in rows) {
      final id = idText(row['id'], 'id');
      final production = row['productionDate'];
      final shift = text(row['shift'], 'shift');
      final lineId = idText(row['lineId'], 'lineId');
      final article = text(row['article'], 'article');
      final planned = finite(row['plannedMinutes'], 'plannedMinutes');
      final downtime = finite(row['downtimeMinutes'], 'downtimeMinutes');
      final speed = finite(row['speedOriginal'], 'speedOriginal');
      final unit = enumValue(SpeedUnit.values, row['speedUnit'], 'speedUnit');
      final cycle = finite(row['idealCycleSeconds'], 'idealCycleSeconds');
      final total = integer(row['totalUnits'], 'totalUnits');
      final good = integer(row['goodUnits'], 'goodUnits');
      final status = enumValue(OeeRecordStatus.values, row['status'], 'status');
      final formula = text(row['formulaVersion'], 'formulaVersion');
      final lineName = text(row['capturedLineName'], 'capturedLineName');
      final plantName = text(row['capturedPlantName'], 'capturedPlantName');
      final createdAt = timestamp(row['createdAt'], 'createdAt');
      final updatedAt = timestamp(row['updatedAt'], 'updatedAt');
      String? replacesId;
      var replacesOk = true;
      if (row.containsKey('replacesId') && row['replacesId'] != null) {
        replacesId = idText(row['replacesId'], 'replacesId');
        if (replacesId == null) {
          replacesOk = false;
        }
      }
      if (production is! String || !productionDate(production)) {
        add(WorkspaceIssueCode.invalidField, field: 'productionDate');
      }
      String? lot;
      var lotOk = true;
      if (!row.containsKey('lot')) {
        add(WorkspaceIssueCode.invalidJson, field: 'lot');
        lotOk = false;
      } else if (row['lot'] == null) {
        lot = null;
      } else if (row['lot'] is String &&
          (row['lot'] as String).trim().isNotEmpty) {
        lot = (row['lot'] as String).trim();
      } else {
        add(WorkspaceIssueCode.invalidField, field: 'lot');
        lotOk = false;
      }
      if (id == null ||
          production is! String ||
          !productionDate(production) ||
          shift == null ||
          lineId == null ||
          article == null ||
          planned == null ||
          downtime == null ||
          speed == null ||
          unit == null ||
          cycle == null ||
          total == null ||
          good == null ||
          status == null ||
          formula == null ||
          lineName == null ||
          plantName == null ||
          createdAt == null ||
          updatedAt == null ||
          !lotOk ||
          !replacesOk ||
          shift.trim().isEmpty ||
          article.trim().isEmpty ||
          formula.trim().isEmpty ||
          lineName.trim().isEmpty ||
          plantName.trim().isEmpty) {
        continue;
      }
      result.add(
        OeeRecord(
          id: id,
          productionDate: production,
          shift: shift.trim(),
          lineId: lineId,
          article: article.trim(),
          lot: lot,
          plannedMinutes: planned,
          downtimeMinutes: downtime,
          speedOriginal: speed,
          speedUnit: unit,
          idealCycleSeconds: cycle,
          totalUnits: total,
          goodUnits: good,
          status: status,
          formulaVersion: formula.trim(),
          capturedLineName: lineName.trim(),
          capturedPlantName: plantName.trim(),
          createdAt: createdAt,
          updatedAt: updatedAt,
          replacesId: replacesId,
        ),
      );
    }
    return result;
  }

  List<MigrationReview> reviews(Object? value) {
    final rows = mapList(value, 'migrationReviews');
    if (rows == null) {
      return const [];
    }
    final result = <MigrationReview>[];
    for (final row in rows) {
      final id = idText(row['id'], 'id');
      final entityId = idText(row['entityId'], 'entityId');
      final kind = row['legacyKind'];
      final level = row['legacyFunctionalLevel'];
      final label = row['legacyFunctionalLevelLabel'];
      final promoted = row['promoted'];
      final status = enumValue(ReviewStatus.values, row['status'], 'status');
      if (kind is! String || !legacyKindNames.contains(kind)) {
        add(WorkspaceIssueCode.invalidField, field: 'legacyKind');
      }
      if (level is! int || level < 0 || level > 4) {
        add(WorkspaceIssueCode.invalidField, field: 'legacyFunctionalLevel');
      } else if (label != legacyFunctionalLevelLabels[level]) {
        add(
          WorkspaceIssueCode.invalidField,
          field: 'legacyFunctionalLevelLabel',
        );
      }
      if (promoted is! bool) {
        add(WorkspaceIssueCode.invalidField, field: 'promoted');
      }
      if (id == null ||
          entityId == null ||
          kind is! String ||
          !legacyKindNames.contains(kind) ||
          level is! int ||
          level < 0 ||
          level > 4 ||
          label != legacyFunctionalLevelLabels[level] ||
          promoted is! bool ||
          status == null) {
        continue;
      }
      result.add(
        MigrationReview(
          id: id,
          entityId: entityId,
          legacyKind: kind,
          legacyFunctionalLevel: level,
          legacyFunctionalLevelLabel: label as String,
          promoted: promoted,
          status: status,
        ),
      );
    }
    return result;
  }

  String? legacyRaw(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    add(WorkspaceIssueCode.invalidField, field: 'legacyRaw');
    return null;
  }

  String? optionalLegacy(Map<String, dynamic> map, String field) {
    if (!map.containsKey(field) || map[field] == null) {
      return null;
    }
    final value = map[field];
    if (value is String) {
      return value.isEmpty ? null : value;
    }
    add(WorkspaceIssueCode.invalidField, field: field);
    return null;
  }

  void validateBundle({
    required List<Organization> organizations,
    required List<Asset> assets,
    required List<WorkSystem> systems,
    required List<ExchangeFlow> flows,
    required List<WorkSchema> schemas,
  }) {
    final orgIds = {for (final item in organizations) item.id};
    final assetsById = {for (final item in assets) item.id: item};
    final systemIds = {for (final item in systems) item.id};
    final flowIds = {for (final item in flows) item.id};
    final seen = <String>{};
    void claim(String id) {
      if (!seen.add(id)) {
        add(WorkspaceIssueCode.duplicateId, entityId: id);
      }
    }

    for (final item in organizations) {
      claim(item.id);
      if (item.name.trim().isEmpty) {
        add(WorkspaceIssueCode.emptyName, field: 'name', entityId: item.id);
      }
    }
    for (final item in assets) {
      claim(item.id);
      if (item.name.trim().isEmpty) {
        add(WorkspaceIssueCode.emptyName, field: 'name', entityId: item.id);
      }
      final parentIsOrg = orgIds.contains(item.parentId);
      final parent = assetsById[item.parentId];
      final fits = switch (item.kind) {
        AssetKind.plant => parentIsOrg,
        AssetKind.area => parent?.kind == AssetKind.plant,
        AssetKind.line => parent?.kind == AssetKind.area,
        AssetKind.machine => parent?.kind == AssetKind.line,
      };
      if (!fits) {
        add(
          WorkspaceIssueCode.incompatibleParent,
          field: 'parentId',
          entityId: item.id,
        );
      }
      final chain = <String>{item.id};
      var current = item.parentId;
      while (assetsById.containsKey(current)) {
        if (!chain.add(current)) {
          add(WorkspaceIssueCode.cycle, field: 'parentId', entityId: item.id);
          break;
        }
        current = assetsById[current]!.parentId;
      }
      if (!parentIsOrg && parent == null) {
        add(
          WorkspaceIssueCode.orphanReference,
          field: 'parentId',
          entityId: item.id,
        );
      }
    }
    for (final item in systems) {
      claim(item.id);
      if (item.scopeIds.toSet().length != item.scopeIds.length) {
        add(
          WorkspaceIssueCode.duplicateId,
          field: 'scopeIds',
          entityId: item.id,
        );
      }
      for (final scopeId in item.scopeIds) {
        if (!assetsById.containsKey(scopeId)) {
          add(
            orgIds.contains(scopeId) ||
                    systemIds.contains(scopeId) ||
                    flowIds.contains(scopeId)
                ? WorkspaceIssueCode.invalidField
                : WorkspaceIssueCode.orphanReference,
            field: 'scopeIds',
            entityId: scopeId,
          );
        }
      }
    }
    for (final item in flows) {
      claim(item.id);
      void endpoint(String endpoint, String field) {
        if (assetsById.containsKey(endpoint) || systemIds.contains(endpoint)) {
          return;
        }
        add(
          orgIds.contains(endpoint) || flowIds.contains(endpoint)
              ? WorkspaceIssueCode.invalidEndpoint
              : WorkspaceIssueCode.orphanReference,
          field: field,
          entityId: endpoint,
        );
      }

      endpoint(item.sourceId, 'sourceId');
      endpoint(item.targetId, 'targetId');
    }
    final schemaRefs = <String>{...assetsById.keys, ...systemIds, ...flowIds};
    for (final item in schemas) {
      claim(item.id);
      void refs(
        List<String> values,
        bool Function(String id) ok,
        String field,
      ) {
        if (values.toSet().length != values.length) {
          add(WorkspaceIssueCode.duplicateId, field: field, entityId: item.id);
        }
        for (final id in values) {
          if (!ok(id)) {
            add(
              schemaRefs.contains(id) || orgIds.contains(id)
                  ? WorkspaceIssueCode.invalidField
                  : WorkspaceIssueCode.orphanReference,
              field: field,
              entityId: id,
            );
          }
        }
      }

      refs(
        item.plantIds,
        (id) => assetsById[id]?.kind == AssetKind.plant,
        'plantIds',
      );
      refs(item.assetIds, assetsById.containsKey, 'assetIds');
      refs(item.systemIds, systemIds.contains, 'systemIds');
      refs(item.flowIds, flowIds.contains, 'flowIds');
      final cited = {
        ...item.plantIds,
        ...item.assetIds,
        ...item.systemIds,
        ...item.flowIds,
      };
      for (final key in item.layout.keys) {
        if (!cited.contains(key)) {
          add(
            WorkspaceIssueCode.orphanReference,
            field: 'layout',
            entityId: key,
          );
        }
      }
    }
  }

  void validateVersions({
    required List<ArchitectureVersion> versions,
    required Set<String> liveSchemaIds,
  }) {
    final ids = {for (final version in versions) version.id};
    for (final version in versions) {
      if (version.schemaId != version.snapshot.schema.id) {
        add(
          WorkspaceIssueCode.invalidField,
          field: 'schemaId',
          entityId: version.id,
        );
      }
      if (!liveSchemaIds.contains(version.schemaId) &&
          version.snapshot.schema.name.trim().isEmpty) {
        add(
          WorkspaceIssueCode.orphanReference,
          field: 'schemaId',
          entityId: version.id,
        );
      }
      if (version.parentVersionId != null &&
          !ids.contains(version.parentVersionId)) {
        add(
          WorkspaceIssueCode.orphanReference,
          field: 'parentVersionId',
          entityId: version.parentVersionId,
        );
      }
      final seen = <String>{version.id};
      var current = version.parentVersionId;
      while (current != null) {
        if (!seen.add(current)) {
          add(
            WorkspaceIssueCode.cycle,
            field: 'parentVersionId',
            entityId: version.id,
          );
          break;
        }
        current = versions
            .where((item) => item.id == current)
            .firstOrNull
            ?.parentVersionId;
      }
    }
  }

  void validateRecords({
    required List<OeeRecord> records,
    required List<Asset> assets,
  }) {
    final lines = {for (final asset in assets) asset.id: asset};
    for (final record in records) {
      final asset = lines[record.lineId];
      if (asset == null) {
        if (record.capturedLineName.trim().isEmpty ||
            record.capturedPlantName.trim().isEmpty) {
          add(
            WorkspaceIssueCode.orphanReference,
            field: 'lineId',
            entityId: record.lineId,
          );
        }
      } else if (asset.kind != AssetKind.line) {
        add(
          WorkspaceIssueCode.invalidField,
          field: 'lineId',
          entityId: record.lineId,
        );
      }
    }
    final byId = {for (final record in records) record.id: record};
    for (final record in records) {
      final replacesId = record.replacesId;
      if (replacesId == null) {
        continue;
      }
      if (!byId.containsKey(replacesId)) {
        add(
          WorkspaceIssueCode.orphanReference,
          field: 'replacesId',
          entityId: replacesId,
        );
        continue;
      }
      final seen = <String>{record.id};
      String? current = replacesId;
      while (current != null && byId.containsKey(current)) {
        if (!seen.add(current)) {
          add(
            WorkspaceIssueCode.cycle,
            field: 'replacesId',
            entityId: record.id,
          );
          break;
        }
        current = byId[current]!.replacesId;
      }
    }
  }

  void validateReviews({
    required List<MigrationReview> reviews,
    required List<Organization> organizations,
    required List<Asset> assets,
  }) {
    final ids = <String>{};
    final entities = {
      for (final item in organizations) item.id,
      for (final item in assets) item.id,
    };
    for (final review in reviews) {
      if (!ids.add(review.id)) {
        add(WorkspaceIssueCode.duplicateId, entityId: review.id);
      }
      if (!entities.contains(review.entityId)) {
        add(
          WorkspaceIssueCode.orphanReference,
          field: 'entityId',
          entityId: review.entityId,
        );
      }
    }
  }

  void validateLiveIds({
    required List<Organization> organizations,
    required List<Asset> assets,
    required List<WorkSystem> systems,
    required List<ExchangeFlow> flows,
    required List<WorkSchema> schemas,
    required List<ArchitectureVersion> versions,
    required List<OeeRecord> records,
  }) {
    final seen = <String>{};
    void claim(String id) {
      if (!seen.add(id)) {
        add(WorkspaceIssueCode.duplicateId, entityId: id);
      }
    }

    for (final item in organizations) {
      claim(item.id);
    }
    for (final item in assets) {
      claim(item.id);
    }
    for (final item in systems) {
      claim(item.id);
    }
    for (final item in flows) {
      claim(item.id);
    }
    for (final item in schemas) {
      claim(item.id);
    }
    for (final item in versions) {
      claim(item.id);
    }
    for (final item in records) {
      claim(item.id);
    }
  }
}
