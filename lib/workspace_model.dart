// Model del replantejament. Sense Flutter.
// Contracte: specs/redesign/spec.md

enum AssetKind { plant, area, line, machine }

enum IsaFunction { l0, l1, l2, l3, l4 }

enum ItOtZone { it, ot, boundary, undefined }

enum SystemType { erp, mes, scada, plc, other }

enum IconKey {
  organization,
  plant,
  area,
  line,
  machine,
  erp,
  mes,
  scada,
  plc,
  genericSystem,
}

enum FlowStatus { suggested, confirmed }

enum SpeedUnit { secondsPerUnit, unitsPerSecond }

enum OeeRecordStatus { draft, validated }

enum ReviewStatus { pendingReview, reviewed }

enum WorkspaceIssueCode {
  invalidJson,
  unsupportedVersion,
  legacyFileNeedsMigration,
  emptyName,
  duplicateId,
  incompatibleParent,
  cycle,
  orphanReference,
  invalidEndpoint,
  functionsNotAssignable,
  invalidField,
  confirmationRequired,
  notFound,
}

const List<String> legacyFunctionalLevelLabels = [
  'Procés',
  'Sensors',
  'Control',
  'MES',
  'ERP',
];

const Set<String> legacyKindNames = {
  'enterprise',
  'site',
  'area',
  'line',
  'cell',
};

const Set<IconKey> assetIconKeys = {
  IconKey.plant,
  IconKey.area,
  IconKey.line,
  IconKey.machine,
};

const Set<IconKey> systemIconKeys = {
  IconKey.erp,
  IconKey.mes,
  IconKey.scada,
  IconKey.plc,
  IconKey.genericSystem,
};

class WorkspaceIssue {
  const WorkspaceIssue(this.code, {this.field, this.entityId});

  final WorkspaceIssueCode code;
  final String? field;
  final String? entityId;

  @override
  bool operator ==(Object other) {
    return other is WorkspaceIssue &&
        other.code == code &&
        other.field == field &&
        other.entityId == entityId;
  }

  @override
  int get hashCode => Object.hash(code, field, entityId);
}

class Organization {
  Organization({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.iconKey = IconKey.organization,
  });

  final String id;
  final String name;
  final String? description;
  final IconKey iconKey;
  final DateTime createdAt;
  final DateTime updatedAt;

  Organization copyWith({
    String? name,
    String? description,
    bool clearDescription = false,
    DateTime? updatedAt,
  }) {
    return Organization(
      id: id,
      name: name ?? this.name,
      description: clearDescription ? null : (description ?? this.description),
      iconKey: iconKey,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Asset {
  Asset({
    required this.id,
    required this.name,
    required this.kind,
    required this.parentId,
    required this.iconKey,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    List<IsaFunction> functions = const [],
  }) : functions = List.unmodifiable(functions);

  final String id;
  final String name;
  final String? description;
  final AssetKind kind;
  final String parentId;
  final IconKey iconKey;
  final List<IsaFunction> functions;
  final DateTime createdAt;
  final DateTime updatedAt;

  Asset copyWith({
    String? name,
    String? description,
    bool clearDescription = false,
    String? parentId,
    IconKey? iconKey,
    List<IsaFunction>? functions,
    DateTime? updatedAt,
  }) {
    return Asset(
      id: id,
      name: name ?? this.name,
      description: clearDescription ? null : (description ?? this.description),
      kind: kind,
      parentId: parentId ?? this.parentId,
      iconKey: iconKey ?? this.iconKey,
      functions: functions ?? this.functions,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class WorkSystem {
  WorkSystem({
    required this.id,
    required this.name,
    required this.systemType,
    required this.iconKey,
    required this.zone,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    List<String> scopeIds = const [],
    List<IsaFunction> functions = const [],
  }) : scopeIds = List.unmodifiable(scopeIds),
       functions = List.unmodifiable(functions);

  final String id;
  final String name;
  final String? description;
  final SystemType systemType;
  final IconKey iconKey;
  final List<String> scopeIds;
  final List<IsaFunction> functions;
  final ItOtZone zone;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkSystem copyWith({
    String? name,
    String? description,
    bool clearDescription = false,
    SystemType? systemType,
    IconKey? iconKey,
    List<String>? scopeIds,
    List<IsaFunction>? functions,
    ItOtZone? zone,
    DateTime? updatedAt,
  }) {
    return WorkSystem(
      id: id,
      name: name ?? this.name,
      description: clearDescription ? null : (description ?? this.description),
      systemType: systemType ?? this.systemType,
      iconKey: iconKey ?? this.iconKey,
      scopeIds: scopeIds ?? this.scopeIds,
      functions: functions ?? this.functions,
      zone: zone ?? this.zone,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ExchangeFlow {
  const ExchangeFlow({
    required this.id,
    required this.name,
    required this.sourceId,
    required this.targetId,
    required this.exchangedData,
    required this.protocol,
    required this.purpose,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });

  final String id;
  final String name;
  final String? description;
  final String sourceId;
  final String targetId;
  final String exchangedData;
  final String? protocol;
  final String purpose;
  final FlowStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExchangeFlow copyWith({
    String? name,
    String? description,
    bool clearDescription = false,
    String? exchangedData,
    String? protocol,
    bool clearProtocol = false,
    String? purpose,
    FlowStatus? status,
    DateTime? updatedAt,
  }) {
    return ExchangeFlow(
      id: id,
      name: name ?? this.name,
      description: clearDescription ? null : (description ?? this.description),
      sourceId: sourceId,
      targetId: targetId,
      exchangedData: exchangedData ?? this.exchangedData,
      protocol: clearProtocol ? null : (protocol ?? this.protocol),
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class LayoutPoint {
  const LayoutPoint(this.x, this.y);

  final double x;
  final double y;
}

class WorkSchema {
  WorkSchema({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    List<String> plantIds = const [],
    List<String> assetIds = const [],
    List<String> systemIds = const [],
    List<String> flowIds = const [],
    Map<String, LayoutPoint> layout = const {},
  }) : plantIds = List.unmodifiable(plantIds),
       assetIds = List.unmodifiable(assetIds),
       systemIds = List.unmodifiable(systemIds),
       flowIds = List.unmodifiable(flowIds),
       layout = Map.unmodifiable(layout);

  final String id;
  final String name;
  final String? description;
  final List<String> plantIds;
  final List<String> assetIds;
  final List<String> systemIds;
  final List<String> flowIds;
  final Map<String, LayoutPoint> layout;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkSchema copyWith({
    String? name,
    List<String>? plantIds,
    List<String>? assetIds,
    List<String>? systemIds,
    List<String>? flowIds,
    Map<String, LayoutPoint>? layout,
    DateTime? updatedAt,
  }) {
    return WorkSchema(
      id: id,
      name: name ?? this.name,
      description: description,
      plantIds: plantIds ?? this.plantIds,
      assetIds: assetIds ?? this.assetIds,
      systemIds: systemIds ?? this.systemIds,
      flowIds: flowIds ?? this.flowIds,
      layout: layout ?? this.layout,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ArchitectureSnapshot {
  ArchitectureSnapshot({
    required this.schema,
    List<Organization> organizations = const [],
    List<Asset> assets = const [],
    List<WorkSystem> systems = const [],
    List<ExchangeFlow> flows = const [],
  }) : organizations = List.unmodifiable(organizations),
       assets = List.unmodifiable(assets),
       systems = List.unmodifiable(systems),
       flows = List.unmodifiable(flows);

  final WorkSchema schema;
  final List<Organization> organizations;
  final List<Asset> assets;
  final List<WorkSystem> systems;
  final List<ExchangeFlow> flows;
}

class ArchitectureVersion {
  const ArchitectureVersion({
    required this.id,
    required this.schemaId,
    required this.createdAt,
    required this.note,
    required this.parentVersionId,
    required this.snapshot,
  });

  final String id;
  final String schemaId;
  final DateTime createdAt;
  final String note;
  final String? parentVersionId;
  final ArchitectureSnapshot snapshot;
}

class OeeRecord {
  const OeeRecord({
    required this.id,
    required this.productionDate,
    required this.shift,
    required this.lineId,
    required this.article,
    required this.lot,
    required this.plannedMinutes,
    required this.downtimeMinutes,
    required this.speedOriginal,
    required this.speedUnit,
    required this.idealCycleSeconds,
    required this.totalUnits,
    required this.goodUnits,
    required this.status,
    required this.formulaVersion,
    required this.capturedLineName,
    required this.capturedPlantName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String productionDate;
  final String shift;
  final String lineId;
  final String article;
  final String? lot;
  final double plannedMinutes;
  final double downtimeMinutes;
  final double speedOriginal;
  final SpeedUnit speedUnit;
  final double idealCycleSeconds;
  final int totalUnits;
  final int goodUnits;
  final OeeRecordStatus status;
  final String formulaVersion;
  final String capturedLineName;
  final String capturedPlantName;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class MigrationReview {
  const MigrationReview({
    required this.id,
    required this.entityId,
    required this.legacyKind,
    required this.legacyFunctionalLevel,
    required this.legacyFunctionalLevelLabel,
    required this.promoted,
    required this.status,
  });

  final String id;
  final String entityId;
  final String legacyKind;
  final int legacyFunctionalLevel;
  final String legacyFunctionalLevelLabel;
  final bool promoted;
  final ReviewStatus status;

  MigrationReview copyWith({ReviewStatus? status}) {
    return MigrationReview(
      id: id,
      entityId: entityId,
      legacyKind: legacyKind,
      legacyFunctionalLevel: legacyFunctionalLevel,
      legacyFunctionalLevelLabel: legacyFunctionalLevelLabel,
      promoted: promoted,
      status: status ?? this.status,
    );
  }
}

class Workspace {
  Workspace({
    required this.nextIdCounter,
    List<Organization> organizations = const [],
    List<Asset> assets = const [],
    List<WorkSystem> systems = const [],
    List<ExchangeFlow> flows = const [],
    List<WorkSchema> schemas = const [],
    List<ArchitectureVersion> versions = const [],
    List<OeeRecord> oeeRecords = const [],
    List<MigrationReview> migrationReviews = const [],
    this.legacyRaw,
    this.latestLegacyRaw,
    this.reconciledLegacyRaw,
  }) : organizations = List.unmodifiable(organizations),
       assets = List.unmodifiable(assets),
       systems = List.unmodifiable(systems),
       flows = List.unmodifiable(flows),
       schemas = List.unmodifiable(schemas),
       versions = List.unmodifiable(versions),
       oeeRecords = List.unmodifiable(oeeRecords),
       migrationReviews = List.unmodifiable(migrationReviews);

  final int nextIdCounter;
  final List<Organization> organizations;
  final List<Asset> assets;
  final List<WorkSystem> systems;
  final List<ExchangeFlow> flows;
  final List<WorkSchema> schemas;
  final List<ArchitectureVersion> versions;
  final List<OeeRecord> oeeRecords;
  final List<MigrationReview> migrationReviews;
  final String? legacyRaw;
  final String? latestLegacyRaw;
  final String? reconciledLegacyRaw;

  bool get hasDomainData {
    return organizations.isNotEmpty ||
        assets.isNotEmpty ||
        systems.isNotEmpty ||
        flows.isNotEmpty ||
        schemas.isNotEmpty ||
        versions.isNotEmpty ||
        oeeRecords.isNotEmpty ||
        migrationReviews.isNotEmpty;
  }

  Workspace copyWith({
    int? nextIdCounter,
    List<Organization>? organizations,
    List<Asset>? assets,
    List<WorkSystem>? systems,
    List<ExchangeFlow>? flows,
    List<WorkSchema>? schemas,
    List<ArchitectureVersion>? versions,
    List<OeeRecord>? oeeRecords,
    List<MigrationReview>? migrationReviews,
    String? legacyRaw,
    bool clearLegacyRaw = false,
    String? latestLegacyRaw,
    bool clearLatestLegacyRaw = false,
    String? reconciledLegacyRaw,
    bool clearReconciledLegacyRaw = false,
  }) {
    return Workspace(
      nextIdCounter: nextIdCounter ?? this.nextIdCounter,
      organizations: organizations ?? this.organizations,
      assets: assets ?? this.assets,
      systems: systems ?? this.systems,
      flows: flows ?? this.flows,
      schemas: schemas ?? this.schemas,
      versions: versions ?? this.versions,
      oeeRecords: oeeRecords ?? this.oeeRecords,
      migrationReviews: migrationReviews ?? this.migrationReviews,
      legacyRaw: clearLegacyRaw ? null : (legacyRaw ?? this.legacyRaw),
      latestLegacyRaw: clearLatestLegacyRaw
          ? null
          : (latestLegacyRaw ?? this.latestLegacyRaw),
      reconciledLegacyRaw: clearReconciledLegacyRaw
          ? null
          : (reconciledLegacyRaw ?? this.reconciledLegacyRaw),
    );
  }
}

class DependencyReport {
  const DependencyReport({
    required this.entityId,
    this.childIds = const [],
    this.scopeSystemIds = const [],
    this.flowIds = const [],
    this.schemaIds = const [],
    this.retainedOeeRecordIds = const [],
    this.retainedSnapshotIds = const [],
  });

  final String entityId;
  final List<String> childIds;
  final List<String> scopeSystemIds;
  final List<String> flowIds;
  final List<String> schemaIds;
  final List<String> retainedOeeRecordIds;
  final List<String> retainedSnapshotIds;

  bool get requiresConfirmation {
    return childIds.isNotEmpty ||
        scopeSystemIds.isNotEmpty ||
        flowIds.isNotEmpty ||
        schemaIds.isNotEmpty;
  }
}

class WorkspaceMutation {
  const WorkspaceMutation.success(this.workspace, {this.dependencies})
    : issues = const [];

  const WorkspaceMutation.failure(this.issues, {this.dependencies})
    : workspace = null;

  final Workspace? workspace;
  final List<WorkspaceIssue> issues;
  final DependencyReport? dependencies;

  bool get isValid => workspace != null;
}

Workspace createEmptyWorkspace() => Workspace(nextIdCounter: 1);

String? normalizeOptionalText(String? raw) {
  if (raw == null) {
    return null;
  }
  final trimmed = raw.trim();
  return trimmed.isEmpty ? null : trimmed;
}

DateTime asUtc(DateTime value) => value.toUtc();

String isaFunctionLabel(IsaFunction function) {
  switch (function) {
    case IsaFunction.l0:
      return 'Procés';
    case IsaFunction.l1:
      return 'Sensat i actuació';
    case IsaFunction.l2:
      return 'Control';
    case IsaFunction.l3:
      return 'Operacions';
    case IsaFunction.l4:
      return 'Planificació empresarial';
  }
}

String itOtZoneLabel(ItOtZone zone) {
  switch (zone) {
    case ItOtZone.it:
      return 'IT';
    case ItOtZone.ot:
      return 'OT';
    case ItOtZone.boundary:
      return 'Frontera';
    case ItOtZone.undefined:
      return 'No definida';
  }
}

String systemTypeLabel(SystemType type) {
  switch (type) {
    case SystemType.erp:
      return 'ERP';
    case SystemType.mes:
      return 'MES';
    case SystemType.scada:
      return 'SCADA';
    case SystemType.plc:
      return 'PLC';
    case SystemType.other:
      return 'Altre';
  }
}

String assetKindLabel(AssetKind kind) {
  switch (kind) {
    case AssetKind.plant:
      return 'Planta';
    case AssetKind.area:
      return 'Àrea';
    case AssetKind.line:
      return 'Línia';
    case AssetKind.machine:
      return 'Màquina';
  }
}

String workspaceIssueMessage(WorkspaceIssueCode code) {
  switch (code) {
    case WorkspaceIssueCode.invalidJson:
      return 'El JSON no és vàlid.';
    case WorkspaceIssueCode.unsupportedVersion:
      return 'La versió del format no està suportada.';
    case WorkspaceIssueCode.legacyFileNeedsMigration:
      return 'Aquest JSON és del mapa antic. No s\'importa com a còpia nova; la migració llegeix la clau del navegador.';
    case WorkspaceIssueCode.emptyName:
      return 'El nom no pot ser buit.';
    case WorkspaceIssueCode.duplicateId:
      return 'Hi ha identificadors duplicats.';
    case WorkspaceIssueCode.incompatibleParent:
      return 'El pare no és compatible amb aquest element.';
    case WorkspaceIssueCode.cycle:
      return 'La jerarquia no pot contenir cicles.';
    case WorkspaceIssueCode.orphanReference:
      return 'Hi ha una referència orfe.';
    case WorkspaceIssueCode.invalidEndpoint:
      return 'L\'origen o el destí del flux no és un actiu ni un sistema.';
    case WorkspaceIssueCode.functionsNotAssignable:
      return 'L\'organització no té funcions ISA-95 ni es converteix en un sistema.';
    case WorkspaceIssueCode.invalidField:
      return 'El camp no és vàlid.';
    case WorkspaceIssueCode.confirmationRequired:
      return 'Cal confirmar l\'eliminació: hi ha dependències.';
    case WorkspaceIssueCode.notFound:
      return 'No s\'ha trobat l\'element.';
  }
}

IconKey defaultAssetIcon(AssetKind kind) {
  switch (kind) {
    case AssetKind.plant:
      return IconKey.plant;
    case AssetKind.area:
      return IconKey.area;
    case AssetKind.line:
      return IconKey.line;
    case AssetKind.machine:
      return IconKey.machine;
  }
}

IconKey defaultSystemIcon(SystemType type) {
  switch (type) {
    case SystemType.erp:
      return IconKey.erp;
    case SystemType.mes:
      return IconKey.mes;
    case SystemType.scada:
      return IconKey.scada;
    case SystemType.plc:
      return IconKey.plc;
    case SystemType.other:
      return IconKey.genericSystem;
  }
}

Organization? findOrganization(Workspace workspace, String id) {
  for (final organization in workspace.organizations) {
    if (organization.id == id) {
      return organization;
    }
  }
  return null;
}

Asset? findAsset(Workspace workspace, String id) {
  for (final asset in workspace.assets) {
    if (asset.id == id) {
      return asset;
    }
  }
  return null;
}

WorkSystem? findSystem(Workspace workspace, String id) {
  for (final system in workspace.systems) {
    if (system.id == id) {
      return system;
    }
  }
  return null;
}

ExchangeFlow? findFlow(Workspace workspace, String id) {
  for (final flow in workspace.flows) {
    if (flow.id == id) {
      return flow;
    }
  }
  return null;
}

Set<String> liveIds(Workspace workspace) {
  return {
    for (final item in workspace.organizations) item.id,
    for (final item in workspace.assets) item.id,
    for (final item in workspace.systems) item.id,
    for (final item in workspace.flows) item.id,
    for (final item in workspace.schemas) item.id,
    for (final item in workspace.versions) item.id,
    for (final item in workspace.oeeRecords) item.id,
  };
}

List<WorkspaceIssue> _sorted(List<WorkspaceIssue> issues) {
  final unique = <String, WorkspaceIssue>{};
  for (final issue in issues) {
    unique.putIfAbsent(
      '${issue.code.name}|${issue.field}|${issue.entityId}',
      () => issue,
    );
  }
  final ordered = unique.values.toList()
    ..sort((left, right) => left.code.index.compareTo(right.code.index));
  return List.unmodifiable(ordered);
}

WorkspaceMutation _failure(
  List<WorkspaceIssue> issues, {
  DependencyReport? report,
}) {
  return WorkspaceMutation.failure(_sorted(issues), dependencies: report);
}

String _allocateId(Workspace workspace, Set<String> used) {
  var counter = workspace.nextIdCounter < 1 ? 1 : workspace.nextIdCounter;
  while (used.contains('n$counter')) {
    counter += 1;
  }
  return 'n$counter';
}

int _counterAfter(String id, int current) {
  if (!id.startsWith('n')) {
    return current;
  }
  final parsed = int.tryParse(id.substring(1));
  if (parsed == null) {
    return current;
  }
  return parsed + 1 > current ? parsed + 1 : current;
}

bool _parentFits(Workspace workspace, AssetKind kind, String parentId) {
  switch (kind) {
    case AssetKind.plant:
      return findOrganization(workspace, parentId) != null;
    case AssetKind.area:
      return findAsset(workspace, parentId)?.kind == AssetKind.plant;
    case AssetKind.line:
      return findAsset(workspace, parentId)?.kind == AssetKind.area;
    case AssetKind.machine:
      return findAsset(workspace, parentId)?.kind == AssetKind.line;
  }
}

bool _parentChainCycles(Workspace workspace, String start) {
  final assets = {for (final asset in workspace.assets) asset.id: asset};
  final seen = <String>{};
  var current = start;
  while (assets.containsKey(current)) {
    if (!seen.add(current)) {
      return true;
    }
    current = assets[current]!.parentId;
  }
  return false;
}

bool _moveCreatesCycle(Workspace workspace, String assetId, String newParent) {
  final assets = {for (final asset in workspace.assets) asset.id: asset};
  final seen = <String>{};
  var current = newParent;
  while (true) {
    if (current == assetId) {
      return true;
    }
    if (!seen.add(current)) {
      return true;
    }
    final asset = assets[current];
    if (asset == null) {
      return false;
    }
    current = asset.parentId;
  }
}

List<IsaFunction>? _normalizeFunctions(
  List<IsaFunction> functions,
  List<WorkspaceIssue> issues,
) {
  if (functions.toSet().length != functions.length) {
    issues.add(
      const WorkspaceIssue(WorkspaceIssueCode.invalidField, field: 'functions'),
    );
    return null;
  }
  final selected = functions.toSet();
  return [
    for (final function in IsaFunction.values)
      if (selected.contains(function)) function,
  ];
}

List<String>? _normalizeScope(
  Workspace workspace,
  List<String> scopeIds,
  List<WorkspaceIssue> issues,
) {
  if (scopeIds.toSet().length != scopeIds.length) {
    issues.add(
      const WorkspaceIssue(WorkspaceIssueCode.duplicateId, field: 'scopeIds'),
    );
  }
  for (final id in scopeIds) {
    if (findAsset(workspace, id) != null) {
      continue;
    }
    if (findOrganization(workspace, id) != null ||
        findSystem(workspace, id) != null ||
        findFlow(workspace, id) != null) {
      issues.add(
        const WorkspaceIssue(
          WorkspaceIssueCode.invalidField,
          field: 'scopeIds',
        ),
      );
    } else {
      issues.add(
        WorkspaceIssue(
          WorkspaceIssueCode.orphanReference,
          field: 'scopeIds',
          entityId: id,
        ),
      );
    }
  }
  if (issues.isNotEmpty) {
    return null;
  }
  return List.unmodifiable(scopeIds);
}

bool _isEndpoint(Workspace workspace, String id) {
  return findAsset(workspace, id) != null || findSystem(workspace, id) != null;
}

void _checkEndpoint(
  Workspace workspace,
  String id,
  String field,
  List<WorkspaceIssue> issues,
) {
  if (_isEndpoint(workspace, id)) {
    return;
  }
  final exists =
      findOrganization(workspace, id) != null ||
      findFlow(workspace, id) != null ||
      workspace.schemas.any((schema) => schema.id == id) ||
      workspace.versions.any((version) => version.id == id) ||
      workspace.oeeRecords.any((record) => record.id == id);
  if (exists) {
    issues.add(
      WorkspaceIssue(
        WorkspaceIssueCode.invalidEndpoint,
        field: field,
        entityId: id,
      ),
    );
  } else {
    issues.add(
      WorkspaceIssue(
        WorkspaceIssueCode.orphanReference,
        field: field,
        entityId: id,
      ),
    );
  }
}

WorkspaceMutation addOrganization(
  Workspace workspace, {
  required String name,
  String? description,
  required DateTime now,
}) {
  final issues = <WorkspaceIssue>[];
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    issues.add(
      const WorkspaceIssue(WorkspaceIssueCode.emptyName, field: 'name'),
    );
  }
  if (issues.isNotEmpty) {
    return _failure(issues);
  }
  final stamp = asUtc(now);
  final used = liveIds(workspace);
  final id = _allocateId(workspace, used);
  final organization = Organization(
    id: id,
    name: trimmed,
    description: normalizeOptionalText(description),
    createdAt: stamp,
    updatedAt: stamp,
  );
  return WorkspaceMutation.success(
    workspace.copyWith(
      nextIdCounter: _counterAfter(id, workspace.nextIdCounter),
      organizations: [...workspace.organizations, organization],
    ),
  );
}

WorkspaceMutation updateOrganization(
  Workspace workspace, {
  required String id,
  required String name,
  String? description,
  required DateTime now,
}) {
  final current = findOrganization(workspace, id);
  final issues = <WorkspaceIssue>[];
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    issues.add(
      const WorkspaceIssue(WorkspaceIssueCode.emptyName, field: 'name'),
    );
  }
  if (current == null) {
    issues.add(WorkspaceIssue(WorkspaceIssueCode.notFound, entityId: id));
  }
  if (issues.isNotEmpty || current == null) {
    return _failure(issues);
  }
  final updated = current.copyWith(
    name: trimmed,
    description: normalizeOptionalText(description),
    clearDescription: normalizeOptionalText(description) == null,
    updatedAt: asUtc(now),
  );
  return WorkspaceMutation.success(
    workspace.copyWith(
      organizations: [
        for (final organization in workspace.organizations)
          if (organization.id == id) updated else organization,
      ],
    ),
  );
}

WorkspaceMutation addAsset(
  Workspace workspace, {
  required AssetKind kind,
  required String parentId,
  required String name,
  String? description,
  IconKey? iconKey,
  List<IsaFunction> functions = const [],
  required DateTime now,
}) {
  final issues = <WorkspaceIssue>[];
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    issues.add(
      const WorkspaceIssue(WorkspaceIssueCode.emptyName, field: 'name'),
    );
  }
  if (!_parentFits(workspace, kind, parentId)) {
    issues.add(
      const WorkspaceIssue(
        WorkspaceIssueCode.incompatibleParent,
        field: 'parentId',
      ),
    );
  }
  if (_parentChainCycles(workspace, parentId)) {
    issues.add(
      const WorkspaceIssue(WorkspaceIssueCode.cycle, field: 'parentId'),
    );
  }
  final icon = iconKey ?? defaultAssetIcon(kind);
  if (!assetIconKeys.contains(icon)) {
    issues.add(
      const WorkspaceIssue(WorkspaceIssueCode.invalidField, field: 'iconKey'),
    );
  }
  final normalized = _normalizeFunctions(functions, issues);
  if (issues.isNotEmpty || normalized == null) {
    return _failure(issues);
  }
  final stamp = asUtc(now);
  final id = _allocateId(workspace, liveIds(workspace));
  final asset = Asset(
    id: id,
    name: trimmed,
    description: normalizeOptionalText(description),
    kind: kind,
    parentId: parentId,
    iconKey: icon,
    functions: normalized,
    createdAt: stamp,
    updatedAt: stamp,
  );
  return WorkspaceMutation.success(
    workspace.copyWith(
      nextIdCounter: _counterAfter(id, workspace.nextIdCounter),
      assets: [...workspace.assets, asset],
    ),
  );
}

WorkspaceMutation updateAsset(
  Workspace workspace, {
  required String id,
  required String name,
  String? description,
  String? parentId,
  IconKey? iconKey,
  List<IsaFunction>? functions,
  required DateTime now,
}) {
  final current = findAsset(workspace, id);
  final issues = <WorkspaceIssue>[];
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    issues.add(
      const WorkspaceIssue(WorkspaceIssueCode.emptyName, field: 'name'),
    );
  }
  if (current == null) {
    issues.add(WorkspaceIssue(WorkspaceIssueCode.notFound, entityId: id));
    return _failure(issues);
  }
  final nextParent = parentId ?? current.parentId;
  if (!_parentFits(workspace, current.kind, nextParent)) {
    issues.add(
      const WorkspaceIssue(
        WorkspaceIssueCode.incompatibleParent,
        field: 'parentId',
      ),
    );
  }
  if (_moveCreatesCycle(workspace, id, nextParent)) {
    issues.add(
      const WorkspaceIssue(WorkspaceIssueCode.cycle, field: 'parentId'),
    );
  }
  if (iconKey != null && !assetIconKeys.contains(iconKey)) {
    issues.add(
      const WorkspaceIssue(WorkspaceIssueCode.invalidField, field: 'iconKey'),
    );
  }
  List<IsaFunction>? normalized;
  if (functions != null) {
    normalized = _normalizeFunctions(functions, issues);
  }
  if (issues.isNotEmpty) {
    return _failure(issues);
  }
  final updated = current.copyWith(
    name: trimmed,
    description: normalizeOptionalText(description),
    clearDescription: normalizeOptionalText(description) == null,
    parentId: nextParent,
    iconKey: iconKey,
    functions: normalized,
    updatedAt: asUtc(now),
  );
  return WorkspaceMutation.success(
    workspace.copyWith(
      assets: [
        for (final asset in workspace.assets)
          if (asset.id == id) updated else asset,
      ],
    ),
  );
}

WorkspaceMutation assignFunctions(
  Workspace workspace, {
  required String id,
  required List<IsaFunction> functions,
  required DateTime now,
}) {
  if (findOrganization(workspace, id) != null) {
    return _failure([
      WorkspaceIssue(WorkspaceIssueCode.functionsNotAssignable, entityId: id),
    ]);
  }
  final issues = <WorkspaceIssue>[];
  final normalized = _normalizeFunctions(functions, issues);
  final asset = findAsset(workspace, id);
  final system = findSystem(workspace, id);
  if (asset == null && system == null) {
    issues.add(WorkspaceIssue(WorkspaceIssueCode.notFound, entityId: id));
  }
  if (issues.isNotEmpty || normalized == null) {
    return _failure(issues);
  }
  final stamp = asUtc(now);
  if (asset != null) {
    return WorkspaceMutation.success(
      workspace.copyWith(
        assets: [
          for (final item in workspace.assets)
            if (item.id == id)
              item.copyWith(functions: normalized, updatedAt: stamp)
            else
              item,
        ],
      ),
    );
  }
  return WorkspaceMutation.success(
    workspace.copyWith(
      systems: [
        for (final item in workspace.systems)
          if (item.id == id)
            item.copyWith(functions: normalized, updatedAt: stamp)
          else
            item,
      ],
    ),
  );
}

WorkspaceMutation addSystem(
  Workspace workspace, {
  required String name,
  String? description,
  required SystemType systemType,
  IconKey? iconKey,
  List<String> scopeIds = const [],
  List<IsaFunction> functions = const [],
  required ItOtZone zone,
  required DateTime now,
}) {
  final issues = <WorkspaceIssue>[];
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    issues.add(
      const WorkspaceIssue(WorkspaceIssueCode.emptyName, field: 'name'),
    );
  }
  final icon = iconKey ?? defaultSystemIcon(systemType);
  if (!systemIconKeys.contains(icon)) {
    issues.add(
      const WorkspaceIssue(WorkspaceIssueCode.invalidField, field: 'iconKey'),
    );
  }
  final normalized = _normalizeFunctions(functions, issues);
  final scope = _normalizeScope(workspace, scopeIds, issues);
  if (issues.isNotEmpty || normalized == null || scope == null) {
    return _failure(issues);
  }
  final stamp = asUtc(now);
  final id = _allocateId(workspace, liveIds(workspace));
  final system = WorkSystem(
    id: id,
    name: trimmed,
    description: normalizeOptionalText(description),
    systemType: systemType,
    iconKey: icon,
    scopeIds: scope,
    functions: normalized,
    zone: zone,
    createdAt: stamp,
    updatedAt: stamp,
  );
  return WorkspaceMutation.success(
    workspace.copyWith(
      nextIdCounter: _counterAfter(id, workspace.nextIdCounter),
      systems: [...workspace.systems, system],
    ),
  );
}

WorkspaceMutation updateSystemScope(
  Workspace workspace, {
  required String id,
  required List<String> scopeIds,
  required DateTime now,
}) {
  final current = findSystem(workspace, id);
  if (current == null) {
    return _failure([
      WorkspaceIssue(WorkspaceIssueCode.notFound, entityId: id),
    ]);
  }
  final issues = <WorkspaceIssue>[];
  final scope = _normalizeScope(workspace, scopeIds, issues);
  if (issues.isNotEmpty || scope == null) {
    return _failure(issues);
  }
  return WorkspaceMutation.success(
    workspace.copyWith(
      systems: [
        for (final system in workspace.systems)
          if (system.id == id)
            system.copyWith(scopeIds: scope, updatedAt: asUtc(now))
          else
            system,
      ],
    ),
  );
}

WorkspaceMutation updateSystem(
  Workspace workspace, {
  required String id,
  required String name,
  String? description,
  SystemType? systemType,
  IconKey? iconKey,
  List<String>? scopeIds,
  List<IsaFunction>? functions,
  ItOtZone? zone,
  required DateTime now,
}) {
  final current = findSystem(workspace, id);
  final issues = <WorkspaceIssue>[];
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    issues.add(
      const WorkspaceIssue(WorkspaceIssueCode.emptyName, field: 'name'),
    );
  }
  if (current == null) {
    issues.add(WorkspaceIssue(WorkspaceIssueCode.notFound, entityId: id));
    return _failure(issues);
  }
  final icon = iconKey ?? current.iconKey;
  if (!systemIconKeys.contains(icon)) {
    issues.add(
      const WorkspaceIssue(WorkspaceIssueCode.invalidField, field: 'iconKey'),
    );
  }
  List<IsaFunction>? normalized;
  if (functions != null) {
    normalized = _normalizeFunctions(functions, issues);
  }
  List<String>? scope;
  if (scopeIds != null) {
    scope = _normalizeScope(workspace, scopeIds, issues);
  }
  if (issues.isNotEmpty) {
    return _failure(issues);
  }
  return WorkspaceMutation.success(
    workspace.copyWith(
      systems: [
        for (final system in workspace.systems)
          if (system.id == id)
            system.copyWith(
              name: trimmed,
              description: normalizeOptionalText(description),
              clearDescription: normalizeOptionalText(description) == null,
              systemType: systemType,
              iconKey: icon,
              scopeIds: scope,
              functions: normalized,
              zone: zone,
              updatedAt: asUtc(now),
            )
          else
            system,
      ],
    ),
  );
}

WorkspaceMutation updateSystemIcon(
  Workspace workspace, {
  required String id,
  required IconKey iconKey,
  required DateTime now,
}) {
  final current = findSystem(workspace, id);
  if (current == null) {
    return _failure([
      WorkspaceIssue(WorkspaceIssueCode.notFound, entityId: id),
    ]);
  }
  if (!systemIconKeys.contains(iconKey)) {
    return _failure(const [
      WorkspaceIssue(WorkspaceIssueCode.invalidField, field: 'iconKey'),
    ]);
  }
  return WorkspaceMutation.success(
    workspace.copyWith(
      systems: [
        for (final system in workspace.systems)
          if (system.id == id)
            system.copyWith(iconKey: iconKey, updatedAt: asUtc(now))
          else
            system,
      ],
    ),
  );
}

WorkspaceMutation addFlow(
  Workspace workspace, {
  required String name,
  String? description,
  required String sourceId,
  required String targetId,
  required String exchangedData,
  String? protocol,
  required String purpose,
  FlowStatus status = FlowStatus.suggested,
  required DateTime now,
}) {
  final issues = <WorkspaceIssue>[];
  final trimmed = name.trim();
  final data = exchangedData.trim();
  final goal = purpose.trim();
  if (trimmed.isEmpty) {
    issues.add(
      const WorkspaceIssue(WorkspaceIssueCode.emptyName, field: 'name'),
    );
  }
  if (data.isEmpty) {
    issues.add(
      const WorkspaceIssue(
        WorkspaceIssueCode.invalidField,
        field: 'exchangedData',
      ),
    );
  }
  if (goal.isEmpty) {
    issues.add(
      const WorkspaceIssue(WorkspaceIssueCode.invalidField, field: 'purpose'),
    );
  }
  final normalizedProtocol = normalizeOptionalText(protocol);
  if (protocol != null && normalizedProtocol == null) {
    issues.add(
      const WorkspaceIssue(WorkspaceIssueCode.invalidField, field: 'protocol'),
    );
  }
  _checkEndpoint(workspace, sourceId, 'sourceId', issues);
  _checkEndpoint(workspace, targetId, 'targetId', issues);
  if (issues.isNotEmpty) {
    return _failure(issues);
  }
  final stamp = asUtc(now);
  final id = _allocateId(workspace, liveIds(workspace));
  final flow = ExchangeFlow(
    id: id,
    name: trimmed,
    description: normalizeOptionalText(description),
    sourceId: sourceId,
    targetId: targetId,
    exchangedData: data,
    protocol: normalizedProtocol,
    purpose: goal,
    status: status,
    createdAt: stamp,
    updatedAt: stamp,
  );
  return WorkspaceMutation.success(
    workspace.copyWith(
      nextIdCounter: _counterAfter(id, workspace.nextIdCounter),
      flows: [...workspace.flows, flow],
    ),
  );
}

WorkspaceMutation updateFlow(
  Workspace workspace, {
  required String id,
  required String name,
  String? description,
  required String sourceId,
  required String targetId,
  required String exchangedData,
  String? protocol,
  required String purpose,
  required FlowStatus status,
  required DateTime now,
}) {
  final current = findFlow(workspace, id);
  final issues = <WorkspaceIssue>[];
  if (current == null) {
    issues.add(WorkspaceIssue(WorkspaceIssueCode.notFound, entityId: id));
  }
  final trimmed = name.trim();
  final data = exchangedData.trim();
  final goal = purpose.trim();
  if (trimmed.isEmpty) {
    issues.add(
      const WorkspaceIssue(WorkspaceIssueCode.emptyName, field: 'name'),
    );
  }
  if (data.isEmpty) {
    issues.add(
      const WorkspaceIssue(
        WorkspaceIssueCode.invalidField,
        field: 'exchangedData',
      ),
    );
  }
  if (goal.isEmpty) {
    issues.add(
      const WorkspaceIssue(WorkspaceIssueCode.invalidField, field: 'purpose'),
    );
  }
  final normalizedProtocol = normalizeOptionalText(protocol);
  if (protocol != null && normalizedProtocol == null) {
    issues.add(
      const WorkspaceIssue(WorkspaceIssueCode.invalidField, field: 'protocol'),
    );
  }
  _checkEndpoint(workspace, sourceId, 'sourceId', issues);
  _checkEndpoint(workspace, targetId, 'targetId', issues);
  if (issues.isNotEmpty || current == null) {
    return _failure(issues);
  }
  return WorkspaceMutation.success(
    workspace.copyWith(
      flows: [
        for (final flow in workspace.flows)
          if (flow.id == id)
            ExchangeFlow(
              id: flow.id,
              name: trimmed,
              description: normalizeOptionalText(description),
              sourceId: sourceId,
              targetId: targetId,
              exchangedData: data,
              protocol: normalizedProtocol,
              purpose: goal,
              status: status,
              createdAt: flow.createdAt,
              updatedAt: asUtc(now),
            )
          else
            flow,
      ],
    ),
  );
}

WorkspaceMutation confirmFlow(
  Workspace workspace, {
  required String id,
  required DateTime now,
}) {
  final current = findFlow(workspace, id);
  if (current == null) {
    return _failure([
      WorkspaceIssue(WorkspaceIssueCode.notFound, entityId: id),
    ]);
  }
  return WorkspaceMutation.success(
    workspace.copyWith(
      flows: [
        for (final flow in workspace.flows)
          if (flow.id == id)
            flow.copyWith(status: FlowStatus.confirmed, updatedAt: asUtc(now))
          else
            flow,
      ],
    ),
  );
}

WorkspaceMutation linkToSchema(
  Workspace workspace, {
  required String schemaId,
  String? assetId,
  String? systemId,
  String? flowId,
  LayoutPoint? at,
  required DateTime now,
}) {
  final schema = workspace.schemas
      .where((item) => item.id == schemaId)
      .firstOrNull;
  if (schema == null) {
    return _failure([
      WorkspaceIssue(WorkspaceIssueCode.notFound, entityId: schemaId),
    ]);
  }
  final issues = <WorkspaceIssue>[];
  if (at != null && (!at.x.isFinite || !at.y.isFinite)) {
    issues.add(
      const WorkspaceIssue(WorkspaceIssueCode.invalidField, field: 'layout'),
    );
  }
  if (assetId != null && findAsset(workspace, assetId) == null) {
    issues.add(
      WorkspaceIssue(
        WorkspaceIssueCode.orphanReference,
        field: 'assetIds',
        entityId: assetId,
      ),
    );
  }
  if (systemId != null && findSystem(workspace, systemId) == null) {
    issues.add(
      WorkspaceIssue(
        WorkspaceIssueCode.orphanReference,
        field: 'systemIds',
        entityId: systemId,
      ),
    );
  }
  if (flowId != null && findFlow(workspace, flowId) == null) {
    issues.add(
      WorkspaceIssue(
        WorkspaceIssueCode.orphanReference,
        field: 'flowIds',
        entityId: flowId,
      ),
    );
  }
  if (issues.isNotEmpty) {
    return _failure(issues);
  }
  final asset = assetId == null ? null : findAsset(workspace, assetId);
  List<String> append(List<String> values, String? id) {
    if (id == null || values.contains(id)) {
      return values;
    }
    return [...values, id];
  }

  final layout = Map<String, LayoutPoint>.of(schema.layout);
  void put(String? id) {
    if (id != null && at != null) {
      layout[id] = at;
    }
  }

  put(assetId);
  put(systemId);
  put(flowId);
  return WorkspaceMutation.success(
    workspace.copyWith(
      schemas: [
        for (final item in workspace.schemas)
          if (item.id == schemaId)
            item.copyWith(
              plantIds: append(
                schema.plantIds,
                asset?.kind == AssetKind.plant ? assetId : null,
              ),
              assetIds: append(schema.assetIds, assetId),
              systemIds: append(schema.systemIds, systemId),
              flowIds: append(schema.flowIds, flowId),
              layout: layout,
              updatedAt: asUtc(now),
            )
          else
            item,
      ],
    ),
  );
}

Set<String> _descendants(Workspace workspace, String id) {
  final children = <String, List<String>>{};
  for (final asset in workspace.assets) {
    children.putIfAbsent(asset.parentId, () => []).add(asset.id);
  }
  final result = <String>{};
  void walk(String current) {
    for (final child in children[current] ?? const []) {
      if (result.add(child)) {
        walk(child);
      }
    }
  }

  walk(id);
  return result;
}

bool _snapshotMentions(ArchitectureSnapshot snapshot, Set<String> ids) {
  bool listed(Iterable<String> values) => values.any(ids.contains);
  if (ids.contains(snapshot.schema.id) ||
      listed(snapshot.schema.plantIds) ||
      listed(snapshot.schema.assetIds) ||
      listed(snapshot.schema.systemIds) ||
      listed(snapshot.schema.flowIds) ||
      snapshot.schema.layout.keys.any(ids.contains)) {
    return true;
  }
  for (final organization in snapshot.organizations) {
    if (ids.contains(organization.id)) {
      return true;
    }
  }
  for (final asset in snapshot.assets) {
    if (ids.contains(asset.id) || ids.contains(asset.parentId)) {
      return true;
    }
  }
  for (final system in snapshot.systems) {
    if (ids.contains(system.id) || system.scopeIds.any(ids.contains)) {
      return true;
    }
  }
  for (final flow in snapshot.flows) {
    if (ids.contains(flow.id) ||
        ids.contains(flow.sourceId) ||
        ids.contains(flow.targetId)) {
      return true;
    }
  }
  return false;
}

WorkspaceMutation deleteEntity(
  Workspace workspace, {
  required String id,
  bool confirm = false,
}) {
  final organization = findOrganization(workspace, id);
  final asset = findAsset(workspace, id);
  final system = findSystem(workspace, id);
  final flow = findFlow(workspace, id);
  final schema = workspace.schemas.where((item) => item.id == id).firstOrNull;
  if (organization == null &&
      asset == null &&
      system == null &&
      flow == null &&
      schema == null) {
    if (workspace.versions.any((version) => version.id == id) ||
        workspace.oeeRecords.any((record) => record.id == id)) {
      return _failure(const [
        WorkspaceIssue(WorkspaceIssueCode.invalidField, field: 'id'),
      ]);
    }
    return _failure([
      WorkspaceIssue(WorkspaceIssueCode.notFound, entityId: id),
    ]);
  }

  final physical = <String>{
    ..._descendants(workspace, id),
    if (organization != null || asset != null) id,
  };
  final removedSystems = system == null ? <String>{} : {id};
  final endpoints = {...physical, ...removedSystems};
  final removedFlows = {
    for (final item in workspace.flows)
      if (item.id == id ||
          endpoints.contains(item.sourceId) ||
          endpoints.contains(item.targetId))
        item.id,
  };
  final removedSchemas = schema == null ? <String>{} : {id};
  final childIds = _descendants(workspace, id).toList();
  final scopeSystemIds = [
    for (final item in workspace.systems)
      if (!removedSystems.contains(item.id) &&
          item.scopeIds.any(physical.contains))
        item.id,
  ];
  final flowIds = [
    for (final flowId in removedFlows)
      if (flowId != id) flowId,
  ];
  final schemaIds = [
    for (final item in workspace.schemas)
      if (!removedSchemas.contains(item.id) &&
          (item.plantIds.any(physical.contains) ||
              item.assetIds.any(physical.contains) ||
              item.systemIds.any(removedSystems.contains) ||
              item.flowIds.any(removedFlows.contains) ||
              item.layout.keys.any(endpoints.contains)))
        item.id,
  ];
  final retainedOee = [
    for (final record in workspace.oeeRecords)
      if (physical.contains(record.lineId)) record.id,
  ];
  final removedIds = {
    ...physical,
    ...removedSystems,
    ...removedFlows,
    ...removedSchemas,
  };
  final retainedSnapshots = [
    for (final version in workspace.versions)
      if (_snapshotMentions(version.snapshot, removedIds)) version.id,
  ];
  final report = DependencyReport(
    entityId: id,
    childIds: childIds,
    scopeSystemIds: scopeSystemIds,
    flowIds: flowIds,
    schemaIds: schemaIds,
    retainedOeeRecordIds: retainedOee,
    retainedSnapshotIds: retainedSnapshots,
  );
  if (report.requiresConfirmation && !confirm) {
    return _failure(const [
      WorkspaceIssue(WorkspaceIssueCode.confirmationRequired),
    ], report: report);
  }

  bool gone(String entityId) => removedIds.contains(entityId);
  return WorkspaceMutation.success(
    workspace.copyWith(
      organizations: [
        for (final item in workspace.organizations)
          if (!gone(item.id)) item,
      ],
      assets: [
        for (final item in workspace.assets)
          if (!gone(item.id)) item,
      ],
      systems: [
        for (final item in workspace.systems)
          if (!gone(item.id))
            item.copyWith(
              scopeIds: [
                for (final scopeId in item.scopeIds)
                  if (!physical.contains(scopeId)) scopeId,
              ],
            ),
      ],
      flows: [
        for (final item in workspace.flows)
          if (!gone(item.id)) item,
      ],
      schemas: [
        for (final item in workspace.schemas)
          if (!gone(item.id))
            item.copyWith(
              plantIds: [
                for (final ref in item.plantIds)
                  if (!gone(ref)) ref,
              ],
              assetIds: [
                for (final ref in item.assetIds)
                  if (!gone(ref)) ref,
              ],
              systemIds: [
                for (final ref in item.systemIds)
                  if (!gone(ref)) ref,
              ],
              flowIds: [
                for (final ref in item.flowIds)
                  if (!gone(ref)) ref,
              ],
              layout: {
                for (final entry in item.layout.entries)
                  if (!gone(entry.key)) entry.key: entry.value,
              },
            ),
      ],
      migrationReviews: [
        for (final review in workspace.migrationReviews)
          if (!gone(review.entityId)) review,
      ],
    ),
    dependencies: report,
  );
}

WorkspaceMutation acknowledgeReview(Workspace workspace, {required String id}) {
  final current = workspace.migrationReviews
      .where((review) => review.id == id)
      .firstOrNull;
  if (current == null) {
    return _failure([
      WorkspaceIssue(WorkspaceIssueCode.notFound, entityId: id),
    ]);
  }
  return WorkspaceMutation.success(
    workspace.copyWith(
      migrationReviews: [
        for (final review in workspace.migrationReviews)
          if (review.id == id)
            review.copyWith(status: ReviewStatus.reviewed)
          else
            review,
      ],
    ),
  );
}

Workspace foodIndustryExample() {
  final stamp = DateTime.utc(2026, 1, 1);
  Organization org({
    required String id,
    required String name,
    String? description,
  }) {
    return Organization(
      id: id,
      name: name,
      description: description,
      createdAt: stamp,
      updatedAt: stamp,
    );
  }

  Asset asset({
    required String id,
    required String name,
    required AssetKind kind,
    required String parentId,
  }) {
    return Asset(
      id: id,
      name: name,
      kind: kind,
      parentId: parentId,
      iconKey: defaultAssetIcon(kind),
      createdAt: stamp,
      updatedAt: stamp,
    );
  }

  final organizations = [
    org(
      id: 'n1',
      name: 'Alimentària Demo',
      description: 'Grup alimentari d\'exemple. Contenidor organitzatiu, sense funció ISA-95.',
    ),
  ];
  final assets = [
    asset(
      id: 'n2',
      name: 'Planta Girona',
      kind: AssetKind.plant,
      parentId: 'n1',
    ),
    asset(id: 'n3', name: 'Envasat', kind: AssetKind.area, parentId: 'n2'),
    asset(id: 'n4', name: 'Línia iogurt', kind: AssetKind.line, parentId: 'n3'),
    asset(id: 'n5', name: 'Omplidora', kind: AssetKind.machine, parentId: 'n4'),
    asset(
      id: 'n6',
      name: 'Taponadora',
      kind: AssetKind.machine,
      parentId: 'n4',
    ),
    asset(
      id: 'n7',
      name: 'Línia formatge',
      kind: AssetKind.line,
      parentId: 'n3',
    ),
    asset(
      id: 'n8',
      name: 'Premsadora',
      kind: AssetKind.machine,
      parentId: 'n7',
    ),
    asset(
      id: 'n9',
      name: 'Emmagatzematge',
      kind: AssetKind.area,
      parentId: 'n2',
    ),
    asset(
      id: 'n10',
      name: 'Cambra freda',
      kind: AssetKind.line,
      parentId: 'n9',
    ),
    asset(
      id: 'n11',
      name: 'Sensor temperatura',
      kind: AssetKind.machine,
      parentId: 'n10',
    ),
    asset(
      id: 'n12',
      name: 'Planta Lleida',
      kind: AssetKind.plant,
      parentId: 'n1',
    ),
    asset(id: 'n13', name: 'Elaboració', kind: AssetKind.area, parentId: 'n12'),
    asset(id: 'n14', name: 'Línia llet', kind: AssetKind.line, parentId: 'n13'),
    asset(
      id: 'n15',
      name: 'Pasteuritzadora',
      kind: AssetKind.machine,
      parentId: 'n14',
    ),
  ];
  final systems = [
    WorkSystem(
      id: 'n16',
      name: 'ERP corporatiu',
      systemType: SystemType.erp,
      iconKey: IconKey.erp,
      scopeIds: const ['n2', 'n12'],
      functions: const [IsaFunction.l4],
      zone: ItOtZone.it,
      createdAt: stamp,
      updatedAt: stamp,
    ),
    WorkSystem(
      id: 'n17',
      name: 'MES envasat',
      systemType: SystemType.mes,
      iconKey: IconKey.mes,
      scopeIds: const ['n4', 'n7'],
      functions: const [IsaFunction.l3],
      zone: ItOtZone.boundary,
      createdAt: stamp,
      updatedAt: stamp,
    ),
    WorkSystem(
      id: 'n18',
      name: 'PLC omplidora',
      systemType: SystemType.plc,
      iconKey: IconKey.plc,
      scopeIds: const ['n5'],
      functions: const [IsaFunction.l1, IsaFunction.l2],
      zone: ItOtZone.ot,
      createdAt: stamp,
      updatedAt: stamp,
    ),
    WorkSystem(
      id: 'n19',
      name: 'Historian qualitat',
      systemType: SystemType.other,
      iconKey: IconKey.genericSystem,
      scopeIds: const ['n2'],
      functions: const [IsaFunction.l2, IsaFunction.l3],
      zone: ItOtZone.it,
      createdAt: stamp,
      updatedAt: stamp,
    ),
  ];
  final layoutIds = [
    ...assets.map((item) => item.id),
    ...systems.map((item) => item.id),
  ];
  final schema = WorkSchema(
    id: 'n20',
    name: 'Esquema alimentari',
    plantIds: const ['n2', 'n12'],
    assetIds: assets.map((item) => item.id).toList(),
    systemIds: systems.map((item) => item.id).toList(),
    layout: {
      for (var index = 0; index < layoutIds.length; index++)
        layoutIds[index]: LayoutPoint(index * 160.0, 0.0),
    },
    createdAt: stamp,
    updatedAt: stamp,
  );
  return Workspace(
    nextIdCounter: 21,
    organizations: organizations,
    assets: assets,
    systems: systems,
    schemas: [schema],
  );
}

class MachineTemplateItem {
  const MachineTemplateItem({required this.name, required this.iconKey});

  final String name;
  final IconKey iconKey;
}

class MachineTemplate {
  const MachineTemplate({
    required this.id,
    required this.name,
    required this.machines,
  });

  final String id;
  final String name;
  final List<MachineTemplateItem> machines;
}

const List<MachineTemplate> machineTemplates = [
  MachineTemplate(
    id: 'envasat',
    name: 'Envasat',
    machines: [
      MachineTemplateItem(name: 'Omplidora', iconKey: IconKey.machine),
      MachineTemplateItem(name: 'Taponadora', iconKey: IconKey.machine),
    ],
  ),
  MachineTemplate(
    id: 'cambra',
    name: 'Cambra',
    machines: [
      MachineTemplateItem(
        name: 'Sensor de temperatura',
        iconKey: IconKey.machine,
      ),
    ],
  ),
];

class InventoryDivergence {
  const InventoryDivergence({required this.entityId, required this.message});

  final String entityId;
  final String message;
}

MachineTemplate? findMachineTemplate(String id) {
  for (final template in machineTemplates) {
    if (template.id == id) {
      return template;
    }
  }
  return null;
}

WorkSchema? findSchema(Workspace workspace, String id) {
  for (final schema in workspace.schemas) {
    if (schema.id == id) {
      return schema;
    }
  }
  return null;
}

ArchitectureVersion? findVersion(Workspace workspace, String id) {
  for (final version in workspace.versions) {
    if (version.id == id) {
      return version;
    }
  }
  return null;
}

WorkspaceMutation applyMachineTemplate(
  Workspace workspace, {
  required String templateId,
  required String lineId,
  required DateTime now,
}) {
  final template = findMachineTemplate(templateId);
  if (template == null) {
    return _failure([
      WorkspaceIssue(WorkspaceIssueCode.notFound, entityId: templateId),
    ]);
  }
  final line = findAsset(workspace, lineId);
  if (line == null || line.kind != AssetKind.line) {
    return _failure(const [
      WorkspaceIssue(WorkspaceIssueCode.incompatibleParent, field: 'parentId'),
    ]);
  }
  var current = workspace;
  for (final item in template.machines) {
    final mutation = addAsset(
      current,
      kind: AssetKind.machine,
      parentId: lineId,
      name: item.name,
      iconKey: item.iconKey,
      functions: const [],
      now: now,
    );
    if (mutation.workspace == null) {
      return mutation;
    }
    current = mutation.workspace!;
  }
  return WorkspaceMutation.success(current);
}

WorkspaceMutation addSchema(
  Workspace workspace, {
  required String name,
  String? description,
  List<String> plantIds = const [],
  required DateTime now,
}) {
  final trimmed = name.trim();
  final issues = <WorkspaceIssue>[];
  if (trimmed.isEmpty) {
    issues.add(
      const WorkspaceIssue(WorkspaceIssueCode.emptyName, field: 'name'),
    );
  }
  final plants = <String>[];
  for (final id in plantIds) {
    if (plants.contains(id)) {
      issues.add(
        WorkspaceIssue(
          WorkspaceIssueCode.duplicateId,
          field: 'plantIds',
          entityId: id,
        ),
      );
      continue;
    }
    if (findAsset(workspace, id)?.kind != AssetKind.plant) {
      issues.add(
        WorkspaceIssue(
          WorkspaceIssueCode.invalidField,
          field: 'plantIds',
          entityId: id,
        ),
      );
      continue;
    }
    plants.add(id);
  }
  if (issues.isNotEmpty) {
    return _failure(issues);
  }
  final included = <Asset>[];
  void walk(String parentId) {
    for (final asset in workspace.assets) {
      if (asset.parentId == parentId) {
        included.add(asset);
        walk(asset.id);
      }
    }
  }

  for (final plantId in plants) {
    final plant = findAsset(workspace, plantId);
    if (plant != null) {
      included.add(plant);
      walk(plant.id);
    }
  }
  final assetIds = [for (final asset in included) asset.id];
  final assetSet = assetIds.toSet();
  final systems = [
    for (final system in workspace.systems)
      if (system.scopeIds.any(assetSet.contains)) system,
  ];
  final placed = [...assetIds, for (final system in systems) system.id];
  final stamp = asUtc(now);
  final id = _allocateId(workspace, liveIds(workspace));
  final schema = WorkSchema(
    id: id,
    name: trimmed,
    description: normalizeOptionalText(description),
    plantIds: plants,
    assetIds: assetIds,
    systemIds: [for (final system in systems) system.id],
    layout: {
      for (var index = 0; index < placed.length; index++)
        placed[index]: LayoutPoint(index * 160.0, 0),
    },
    createdAt: stamp,
    updatedAt: stamp,
  );
  return WorkspaceMutation.success(
    workspace.copyWith(
      nextIdCounter: _counterAfter(id, workspace.nextIdCounter),
      schemas: [...workspace.schemas, schema],
    ),
  );
}

WorkspaceMutation copySchema(
  Workspace workspace, {
  required String schemaId,
  required String name,
  required DateTime now,
}) {
  final schema = findSchema(workspace, schemaId);
  final trimmed = name.trim();
  final issues = <WorkspaceIssue>[];
  if (schema == null) {
    issues.add(WorkspaceIssue(WorkspaceIssueCode.notFound, entityId: schemaId));
  }
  if (trimmed.isEmpty) {
    issues.add(
      const WorkspaceIssue(WorkspaceIssueCode.emptyName, field: 'name'),
    );
  }
  if (issues.isNotEmpty || schema == null) {
    return _failure(issues);
  }
  final stamp = asUtc(now);
  final id = _allocateId(workspace, liveIds(workspace));
  final copy = WorkSchema(
    id: id,
    name: trimmed,
    description: schema.description,
    plantIds: schema.plantIds,
    assetIds: schema.assetIds,
    systemIds: schema.systemIds,
    flowIds: schema.flowIds,
    layout: {
      for (final entry in schema.layout.entries)
        entry.key: LayoutPoint(entry.value.x, entry.value.y),
    },
    createdAt: stamp,
    updatedAt: stamp,
  );
  return WorkspaceMutation.success(
    workspace.copyWith(
      nextIdCounter: _counterAfter(id, workspace.nextIdCounter),
      schemas: [...workspace.schemas, copy],
    ),
  );
}

WorkspaceMutation updateSchemaLayout(
  Workspace workspace, {
  required String schemaId,
  required String entityId,
  required LayoutPoint at,
  required DateTime now,
}) {
  final schema = findSchema(workspace, schemaId);
  if (schema == null) {
    return _failure([
      WorkspaceIssue(WorkspaceIssueCode.notFound, entityId: schemaId),
    ]);
  }
  if (!at.x.isFinite || !at.y.isFinite) {
    return _failure(const [
      WorkspaceIssue(WorkspaceIssueCode.invalidField, field: 'layout'),
    ]);
  }
  final cited = {
    ...schema.plantIds,
    ...schema.assetIds,
    ...schema.systemIds,
    ...schema.flowIds,
  };
  if (!cited.contains(entityId)) {
    return _failure([
      WorkspaceIssue(
        WorkspaceIssueCode.orphanReference,
        field: 'layout',
        entityId: entityId,
      ),
    ]);
  }
  final layout = Map<String, LayoutPoint>.of(schema.layout);
  layout[entityId] = at;
  return WorkspaceMutation.success(
    workspace.copyWith(
      schemas: [
        for (final item in workspace.schemas)
          if (item.id == schemaId)
            item.copyWith(layout: layout, updatedAt: asUtc(now))
          else
            item,
      ],
    ),
  );
}

ArchitectureSnapshot captureSchemaSnapshot(
  Workspace workspace,
  WorkSchema schema,
) {
  final assetIds = <String>{...schema.assetIds, ...schema.plantIds};
  final systemIds = <String>{...schema.systemIds};
  final flowIds = <String>{...schema.flowIds};
  for (final flowId in schema.flowIds) {
    final flow = findFlow(workspace, flowId);
    if (flow == null) {
      continue;
    }
    if (findAsset(workspace, flow.sourceId) != null) {
      assetIds.add(flow.sourceId);
    }
    if (findAsset(workspace, flow.targetId) != null) {
      assetIds.add(flow.targetId);
    }
    if (findSystem(workspace, flow.sourceId) != null) {
      systemIds.add(flow.sourceId);
    }
    if (findSystem(workspace, flow.targetId) != null) {
      systemIds.add(flow.targetId);
    }
  }
  for (final systemId in systemIds.toList()) {
    final system = findSystem(workspace, systemId);
    if (system == null) {
      continue;
    }
    for (final scopeId in system.scopeIds) {
      if (findAsset(workspace, scopeId) != null) {
        assetIds.add(scopeId);
      }
    }
  }
  final pending = assetIds.toList();
  for (var index = 0; index < pending.length; index++) {
    final asset = findAsset(workspace, pending[index]);
    if (asset == null) {
      continue;
    }
    if (findAsset(workspace, asset.parentId) != null &&
        assetIds.add(asset.parentId)) {
      pending.add(asset.parentId);
    }
  }
  final organizationIds = <String>{};
  for (final id in assetIds) {
    final asset = findAsset(workspace, id);
    if (asset != null && findOrganization(workspace, asset.parentId) != null) {
      organizationIds.add(asset.parentId);
    }
  }
  return ArchitectureSnapshot(
    schema: _cloneSchema(schema),
    organizations: [
      for (final item in workspace.organizations)
        if (organizationIds.contains(item.id)) item.copyWith(),
    ],
    assets: [
      for (final item in workspace.assets)
        if (assetIds.contains(item.id))
          item.copyWith(functions: [...item.functions]),
    ],
    systems: [
      for (final item in workspace.systems)
        if (systemIds.contains(item.id))
          item.copyWith(
            scopeIds: [...item.scopeIds],
            functions: [...item.functions],
          ),
    ],
    flows: [
      for (final item in workspace.flows)
        if (flowIds.contains(item.id)) item.copyWith(),
    ],
  );
}

WorkspaceMutation createSnapshot(
  Workspace workspace, {
  required String schemaId,
  required String note,
  required DateTime now,
}) {
  final schema = findSchema(workspace, schemaId);
  if (schema == null) {
    return _failure([
      WorkspaceIssue(WorkspaceIssueCode.notFound, entityId: schemaId),
    ]);
  }
  final id = _allocateId(workspace, liveIds(workspace));
  final version = ArchitectureVersion(
    id: id,
    schemaId: schema.id,
    createdAt: asUtc(now),
    note: note,
    parentVersionId: null,
    snapshot: captureSchemaSnapshot(workspace, schema),
  );
  return WorkspaceMutation.success(
    workspace.copyWith(
      nextIdCounter: _counterAfter(id, workspace.nextIdCounter),
      versions: [...workspace.versions, version],
    ),
  );
}

WorkspaceMutation restoreSnapshot(
  Workspace workspace, {
  required String versionId,
  required String note,
  required DateTime now,
}) {
  final origin = findVersion(workspace, versionId);
  if (origin == null) {
    return _failure([
      WorkspaceIssue(WorkspaceIssueCode.notFound, entityId: versionId),
    ]);
  }
  final id = _allocateId(workspace, liveIds(workspace));
  final version = ArchitectureVersion(
    id: id,
    schemaId: origin.snapshot.schema.id,
    createdAt: asUtc(now),
    note: note,
    parentVersionId: origin.id,
    snapshot: _cloneSnapshot(origin.snapshot),
  );
  return WorkspaceMutation.success(
    workspace.copyWith(
      nextIdCounter: _counterAfter(id, workspace.nextIdCounter),
      versions: [...workspace.versions, version],
    ),
  );
}

List<InventoryDivergence> snapshotDivergences(
  Workspace workspace,
  ArchitectureSnapshot snapshot,
) {
  final notes = <InventoryDivergence>[];
  void add(String id, String message) {
    notes.add(InventoryDivergence(entityId: id, message: message));
  }

  bool sameStrings(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }

  bool sameFunctions(List<IsaFunction> left, List<IsaFunction> right) {
    return sameStrings(
      [for (final item in left) item.name],
      [for (final item in right) item.name],
    );
  }

  for (final item in snapshot.organizations) {
    final live = findOrganization(workspace, item.id);
    if (live == null) {
      add(item.id, 'Absent de l\'inventari vigent.');
    } else if (live.name != item.name || live.description != item.description) {
      add(item.id, 'El nom o la descripció no coincideixen.');
    }
  }
  for (final item in snapshot.assets) {
    final live = findAsset(workspace, item.id);
    if (live == null) {
      add(item.id, 'Absent de l\'inventari vigent.');
    } else if (live.name != item.name ||
        live.kind != item.kind ||
        live.parentId != item.parentId ||
        live.iconKey != item.iconKey ||
        !sameFunctions(live.functions, item.functions)) {
      add(item.id, 'La pertinença, la icona o les funcions no coincideixen.');
    }
  }
  for (final item in snapshot.systems) {
    final live = findSystem(workspace, item.id);
    if (live == null) {
      add(item.id, 'Absent de l\'inventari vigent.');
    } else if (live.name != item.name ||
        live.systemType != item.systemType ||
        live.iconKey != item.iconKey ||
        live.zone != item.zone ||
        !sameStrings(live.scopeIds, item.scopeIds) ||
        !sameFunctions(live.functions, item.functions)) {
      add(item.id, 'L\'abast, les funcions o la zona no coincideixen.');
    }
  }
  for (final item in snapshot.flows) {
    final live = findFlow(workspace, item.id);
    if (live == null) {
      add(item.id, 'Absent de l\'inventari vigent.');
    } else if (live.sourceId != item.sourceId ||
        live.targetId != item.targetId ||
        live.exchangedData != item.exchangedData ||
        live.protocol != item.protocol ||
        live.purpose != item.purpose ||
        live.status != item.status) {
      add(item.id, 'Els extrems o l\'estat del flux no coincideixen.');
    }
  }
  final liveSchema = findSchema(workspace, snapshot.schema.id);
  if (liveSchema == null) {
    add(snapshot.schema.id, 'Absent de l\'inventari vigent.');
  } else if (liveSchema.name != snapshot.schema.name ||
      !sameStrings(liveSchema.plantIds, snapshot.schema.plantIds) ||
      !sameStrings(liveSchema.assetIds, snapshot.schema.assetIds) ||
      !sameStrings(liveSchema.systemIds, snapshot.schema.systemIds) ||
      !sameStrings(liveSchema.flowIds, snapshot.schema.flowIds) ||
      !_sameLayout(liveSchema.layout, snapshot.schema.layout)) {
    add(snapshot.schema.id, 'La disposició o la pertinença no coincideixen.');
  }
  return List.unmodifiable(notes);
}

bool _sameLayout(
  Map<String, LayoutPoint> left,
  Map<String, LayoutPoint> right,
) {
  if (left.length != right.length) {
    return false;
  }
  for (final entry in left.entries) {
    final other = right[entry.key];
    if (other == null || other.x != entry.value.x || other.y != entry.value.y) {
      return false;
    }
  }
  return true;
}

WorkSchema _cloneSchema(WorkSchema schema) {
  return WorkSchema(
    id: schema.id,
    name: schema.name,
    description: schema.description,
    plantIds: schema.plantIds,
    assetIds: schema.assetIds,
    systemIds: schema.systemIds,
    flowIds: schema.flowIds,
    layout: {
      for (final entry in schema.layout.entries)
        entry.key: LayoutPoint(entry.value.x, entry.value.y),
    },
    createdAt: schema.createdAt,
    updatedAt: schema.updatedAt,
  );
}

ArchitectureSnapshot _cloneSnapshot(ArchitectureSnapshot snapshot) {
  return ArchitectureSnapshot(
    schema: _cloneSchema(snapshot.schema),
    organizations: [for (final item in snapshot.organizations) item.copyWith()],
    assets: [
      for (final item in snapshot.assets)
        item.copyWith(functions: [...item.functions]),
    ],
    systems: [
      for (final item in snapshot.systems)
        item.copyWith(
          scopeIds: [...item.scopeIds],
          functions: [...item.functions],
        ),
    ],
    flows: [for (final item in snapshot.flows) item.copyWith()],
  );
}
