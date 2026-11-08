import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'workspace_model.dart';
import 'workspace_repository.dart';
import 'workspace_theme.dart';

const Key workspaceTreeKey = Key('workspaceTree');
const Key workspaceInspectorKey = Key('workspaceInspector');
const Key workspaceSaveStatusKey = Key('workspaceSaveStatus');
const Key workspaceAddKey = Key('workspaceAdd');
const Key workspaceNameFieldKey = Key('workspaceName');
const Key workspaceSaveEditKey = Key('workspaceSaveEdit');
const Key workspaceDeleteKey = Key('workspaceDelete');
const Key workspaceConfirmDeleteKey = Key('workspaceConfirmDelete');
const Key workspaceCancelDeleteKey = Key('workspaceCancelDelete');
const Key workspaceTreeToggleKey = Key('workspaceTreeToggle');
const Key workspaceInspectorToggleKey = Key('workspaceInspectorToggle');
const Key workspaceFitKey = Key('workspaceFit');
const Key workspaceZoomInKey = Key('workspaceZoomIn');
const Key workspaceZoomOutKey = Key('workspaceZoomOut');
const Key workspaceLoadExampleKey = Key('workspaceLoadExample');
const Key workspaceParentFieldKey = Key('workspaceParent');
const Key workspaceUnknownProtocolKey = Key('workspaceUnknownProtocol');
const Key workspaceFlowDataKey = Key('workspaceFlowData');
const Key workspaceFlowPurposeKey = Key('workspaceFlowPurpose');
const Key workspaceFlowProtocolKey = Key('workspaceFlowProtocol');
const Key isaFunctionsKey = Key('isaFunctions');
const Key mapL3ExplanationKey = Key('mapL3Explanation');

final GlobalKey workspaceMapKey = GlobalKey(debugLabel: 'workspaceMap');

const String l3Explanation =
    'Franja d\'operacions L3 a la frontera. És una convenció visual, no una classificació universal de MES ni de cap producte.';

const String placementExplanation =
    'Els sistemes es col·loquen per la zona declarada. Les funcions i el tipus no es dedueixen. La jerarquia física és a l\'arbre.';

enum _Draft { organization, plant, area, line, machine, system, flow }

class WorkspacePage extends StatefulWidget {
  const WorkspacePage({
    super.key,
    required this.repository,
    this.onOpenOee,
    this.onOpenData,
  });

  final WorkspaceRepository repository;
  final VoidCallback? onOpenOee;
  final VoidCallback? onOpenData;

  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _data = TextEditingController();
  final _protocol = TextEditingController();
  final _purpose = TextEditingController();
  final _search = TextEditingController();
  final _transform = TransformationController();
  final _foci = <String, FocusNode>{};

  String? _selectedId;
  String? _plantId;
  String? _schemaId;
  _Draft? _creating;
  String? _parentId;
  IconKey _icon = IconKey.organization;
  SystemType _systemType = SystemType.other;
  ItOtZone _zone = ItOtZone.undefined;
  FlowStatus _flowStatus = FlowStatus.suggested;
  String? _flowSource;
  String? _flowTarget;
  bool _unknownProtocol = true;
  bool _treeOpen = false;
  bool _inspectorOpen = false;
  bool _fitted = false;
  final _functions = <IsaFunction>{};
  final _scope = <String>{};
  Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    widget.repository.addListener(_onRepo);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fit();
      }
    });
    _search.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    widget.repository.removeListener(_onRepo);
    _name.dispose();
    _description.dispose();
    _data.dispose();
    _protocol.dispose();
    _purpose.dispose();
    _search.dispose();
    _transform.dispose();
    for (final node in _foci.values) {
      node.dispose();
    }
    super.dispose();
  }

  FocusNode _node(String id) => _foci.putIfAbsent(id, FocusNode.new);

  void _onRepo() {
    if (!mounted) {
      return;
    }
    setState(() {});
    if (!_fitted && widget.repository.workspace.systems.isNotEmpty) {
      _fitted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fit();
        }
      });
    }
  }

  Workspace get _workspace => widget.repository.workspace;

  void _ensureContext() {
    final schemas = _workspace.schemas;
    if (_schemaId == null || schemas.every((item) => item.id != _schemaId)) {
      _schemaId = schemas.firstOrNull?.id;
    }
    final plants = [
      for (final asset in _workspace.assets)
        if (asset.kind == AssetKind.plant) asset,
    ];
    if (_plantId != null && plants.any((item) => item.id == _plantId)) {
      return;
    }
    final schema = schemas.where((item) => item.id == _schemaId).firstOrNull;
    final preferred = schema?.plantIds
        .where((id) => plants.any((plant) => plant.id == id))
        .firstOrNull;
    _plantId = preferred ?? plants.firstOrNull?.id;
  }

  void _select(String id) {
    setState(() {
      _selectedId = id;
      _creating = null;
      _errors = {};
      _loadForm();
    });
  }

  void _startCreate(_Draft draft) {
    setState(() {
      _creating = draft;
      _errors = {};
      _inspectorOpen = true;
      _loadForm();
    });
  }

  void _loadForm() {
    final workspace = _workspace;
    _name.text = '';
    _description.text = '';
    _data.text = '';
    _protocol.text = '';
    _purpose.text = '';
    _functions.clear();
    _scope.clear();
    _unknownProtocol = true;
    _flowStatus = FlowStatus.suggested;
    _parentId = null;
    _icon = IconKey.organization;
    _systemType = SystemType.other;
    _zone = ItOtZone.undefined;
    _flowSource = null;
    _flowTarget = null;

    if (_creating != null) {
      switch (_creating!) {
        case _Draft.organization:
          _icon = IconKey.organization;
        case _Draft.plant:
          _icon = IconKey.plant;
          _parentId = _selectedOrganization() ?? _firstOrganization();
        case _Draft.area:
          _icon = IconKey.area;
          _parentId = _selectedOfKind(AssetKind.plant) ?? _plantId;
        case _Draft.line:
          _icon = IconKey.line;
          _parentId = _selectedOfKind(AssetKind.area);
        case _Draft.machine:
          _icon = IconKey.machine;
          _parentId = _selectedOfKind(AssetKind.line);
        case _Draft.system:
          _icon = IconKey.genericSystem;
        case _Draft.flow:
          _flowSource = _selectedEndpoint();
          _flowTarget = _otherEndpoint(_flowSource);
      }
      return;
    }

    final id = _selectedId;
    if (id == null) {
      return;
    }
    final organization = findOrganization(workspace, id);
    if (organization != null) {
      _name.text = organization.name;
      _description.text = organization.description ?? '';
      _icon = organization.iconKey;
      return;
    }
    final asset = findAsset(workspace, id);
    if (asset != null) {
      _name.text = asset.name;
      _description.text = asset.description ?? '';
      _parentId = asset.parentId;
      _icon = asset.iconKey;
      _functions.addAll(asset.functions);
      return;
    }
    final system = findSystem(workspace, id);
    if (system != null) {
      _name.text = system.name;
      _description.text = system.description ?? '';
      _icon = system.iconKey;
      _systemType = system.systemType;
      _zone = system.zone;
      _functions.addAll(system.functions);
      _scope.addAll(system.scopeIds);
      return;
    }
    final flow = findFlow(workspace, id);
    if (flow != null) {
      _name.text = flow.name;
      _description.text = flow.description ?? '';
      _data.text = flow.exchangedData;
      _purpose.text = flow.purpose;
      _protocol.text = flow.protocol ?? '';
      _unknownProtocol = flow.protocol == null;
      _flowStatus = flow.status;
      _flowSource = flow.sourceId;
      _flowTarget = flow.targetId;
    }
  }

  String? _selectedOrganization() {
    final id = _selectedId;
    if (id != null && findOrganization(_workspace, id) != null) {
      return id;
    }
    return null;
  }

  String? _firstOrganization() {
    return _workspace.organizations.firstOrNull?.id;
  }

  String? _selectedOfKind(AssetKind kind) {
    final id = _selectedId;
    final asset = id == null ? null : findAsset(_workspace, id);
    if (asset != null && asset.kind == kind) {
      return asset.id;
    }
    return null;
  }

  String? _selectedEndpoint() {
    final id = _selectedId;
    if (id == null) {
      return null;
    }
    if (findAsset(_workspace, id) != null ||
        findSystem(_workspace, id) != null) {
      return id;
    }
    return null;
  }

  String? _otherEndpoint(String? source) {
    for (final system in _workspace.systems) {
      if (system.id != source) {
        return system.id;
      }
    }
    for (final asset in _workspace.assets) {
      if (asset.id != source) {
        return asset.id;
      }
    }
    return source;
  }

  Future<void> _save() async {
    final repo = widget.repository;
    final before = repo.workspace;
    final now = repo.now;
    final mutation = _mutation(before, now);
    if (!mutation.isValid || mutation.workspace == null) {
      setState(() => _errors = _issueMap(mutation.issues));
      return;
    }
    var next = mutation.workspace!;
    final added = _addedId(before, next);
    if (added != null && _schemaId != null) {
      final linked = linkToSchema(
        next,
        schemaId: _schemaId!,
        assetId: findAsset(next, added)?.id,
        systemId: findSystem(next, added)?.id,
        flowId: findFlow(next, added)?.id,
        at: const LayoutPoint(0, 0),
        now: now,
      );
      if (linked.workspace != null) {
        next = linked.workspace!;
      }
    }
    setState(() => _errors = {});
    await repo.saveWorkspace(next);
    if (!mounted) {
      return;
    }
    setState(() {
      if (repo.status == SaveStatus.saved && added != null) {
        _selectedId = added;
      }
      if (repo.status == SaveStatus.saved) {
        _creating = null;
        _loadForm();
      }
    });
  }

  WorkspaceMutation _mutation(Workspace before, DateTime now) {
    final description = _description.text;
    if (_creating == _Draft.organization) {
      return addOrganization(
        before,
        name: _name.text,
        description: description,
        now: now,
      );
    }
    if (_creating == _Draft.plant ||
        _creating == _Draft.area ||
        _creating == _Draft.line ||
        _creating == _Draft.machine) {
      return addAsset(
        before,
        kind: _draftKind(_creating!),
        parentId: _parentId ?? '',
        name: _name.text,
        description: description,
        iconKey: _icon,
        functions: _functions.toList(),
        now: now,
      );
    }
    if (_creating == _Draft.system) {
      return addSystem(
        before,
        name: _name.text,
        description: description,
        systemType: _systemType,
        iconKey: _icon,
        scopeIds: _scope.toList(),
        functions: _functions.toList(),
        zone: _zone,
        now: now,
      );
    }
    if (_creating == _Draft.flow) {
      return addFlow(
        before,
        name: _name.text,
        description: description,
        sourceId: _flowSource ?? '',
        targetId: _flowTarget ?? '',
        exchangedData: _data.text,
        protocol: _unknownProtocol ? null : _protocol.text,
        purpose: _purpose.text,
        status: _flowStatus,
        now: now,
      );
    }
    final id = _selectedId;
    if (id == null) {
      return const WorkspaceMutation.failure([
        WorkspaceIssue(WorkspaceIssueCode.notFound),
      ]);
    }
    if (findOrganization(before, id) != null) {
      return updateOrganization(
        before,
        id: id,
        name: _name.text,
        description: description,
        now: now,
      );
    }
    if (findAsset(before, id) != null) {
      return updateAsset(
        before,
        id: id,
        name: _name.text,
        description: description,
        parentId: _parentId,
        iconKey: _icon,
        functions: _functions.toList(),
        now: now,
      );
    }
    if (findSystem(before, id) != null) {
      return updateSystem(
        before,
        id: id,
        name: _name.text,
        description: description,
        systemType: _systemType,
        iconKey: _icon,
        scopeIds: _scope.toList(),
        functions: _functions.toList(),
        zone: _zone,
        now: now,
      );
    }
    return updateFlow(
      before,
      id: id,
      name: _name.text,
      description: description,
      sourceId: _flowSource ?? '',
      targetId: _flowTarget ?? '',
      exchangedData: _data.text,
      protocol: _unknownProtocol ? null : _protocol.text,
      purpose: _purpose.text,
      status: _flowStatus,
      now: now,
    );
  }

  AssetKind _draftKind(_Draft draft) {
    switch (draft) {
      case _Draft.plant:
        return AssetKind.plant;
      case _Draft.area:
        return AssetKind.area;
      case _Draft.line:
        return AssetKind.line;
      case _Draft.machine:
        return AssetKind.machine;
      case _Draft.organization:
      case _Draft.system:
      case _Draft.flow:
        return AssetKind.machine;
    }
  }

  String? _addedId(Workspace before, Workspace after) {
    final previous = liveIds(before);
    for (final id in liveIds(after)) {
      if (!previous.contains(id)) {
        return id;
      }
    }
    return null;
  }

  Map<String, String> _issueMap(List<WorkspaceIssue> issues) {
    final map = <String, String>{};
    for (final issue in issues) {
      map.putIfAbsent(
        issue.field ?? '_form',
        () => workspaceIssueMessage(issue.code),
      );
    }
    if (map.isEmpty) {
      map['_form'] = workspaceIssueMessage(WorkspaceIssueCode.invalidField);
    }
    return map;
  }

  Future<void> _delete() async {
    final id = _selectedId;
    if (id == null || _creating != null) {
      return;
    }
    final preview = deleteEntity(_workspace, id: id);
    if (preview.isValid && preview.workspace != null) {
      await widget.repository.saveWorkspace(preview.workspace!);
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedId = null;
        _loadForm();
      });
      return;
    }
    final report = preview.dependencies;
    if (report == null || !mounted) {
      setState(() => _errors = _issueMap(preview.issues));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) =>
          _DeleteDialog(workspace: _workspace, report: report),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final applied = deleteEntity(_workspace, id: id, confirm: true);
    if (applied.workspace == null) {
      setState(() => _errors = _issueMap(applied.issues));
      return;
    }
    await widget.repository.saveWorkspace(applied.workspace!);
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedId = null;
      _loadForm();
    });
  }

  Future<void> _confirmFlow(String id) async {
    final mutation = confirmFlow(
      _workspace,
      id: id,
      now: widget.repository.now,
    );
    if (mutation.workspace == null) {
      setState(() => _errors = _issueMap(mutation.issues));
      return;
    }
    await widget.repository.saveWorkspace(mutation.workspace!);
    if (!mounted) {
      return;
    }
    setState(_loadForm);
  }

  Future<void> _loadExample() async {
    final repo = widget.repository;
    if (repo.exampleNeedsConfirm) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Carrega exemple'),
          content: const Text(
            'Carregar l\'exemple substitueix les dades d\'aquest navegador.',
          ),
          actions: [
            TextButton(
              style: workspaceControlStyle,
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel·la'),
            ),
            TextButton(
              style: workspaceControlStyle,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Carrega exemple'),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        return;
      }
    }
    await repo.loadExample(confirm: true);
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedId = null;
      _creating = null;
      _plantId = null;
      _schemaId = null;
      _errors = {};
      _loadForm();
    });
  }

  void _zoom(double factor) {
    final matrix = _transform.value.clone();
    matrix.multiply(Matrix4.diagonal3Values(factor, factor, 1));
    _transform.value = matrix;
  }

  void _pan(double dx, double dy) {
    final matrix = _transform.value.clone();
    matrix.storage[12] += dx;
    matrix.storage[13] += dy;
    _transform.value = matrix;
  }

  void _fit() {
    final box =
        workspaceMapKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }
    final geometry = _geometry();
    final sx = box.size.width / geometry.size.width;
    final sy = box.size.height / geometry.size.height;
    final scale = math.min(sx, sy).clamp(0.35, 1.6).toDouble();
    _transform.value = Matrix4.diagonal3Values(scale, scale, 1);
  }

  Set<String> _plantSubtree(String? plantId) {
    if (plantId == null) {
      return {};
    }
    final ids = <String>{plantId};
    var growing = true;
    while (growing) {
      growing = false;
      for (final asset in _workspace.assets) {
        if (ids.contains(asset.parentId) && ids.add(asset.id)) {
          growing = true;
        }
      }
    }
    return ids;
  }

  WorkSchema? _activeSchema() {
    for (final schema in _workspace.schemas) {
      if (schema.id == _schemaId) {
        return schema;
      }
    }
    return null;
  }

  List<WorkSystem> _visibleSystems() {
    final schema = _activeSchema();
    final plant = _plantSubtree(_plantId);
    return [
      for (final system in _workspace.systems)
        if (_systemOnMap(system, schema, plant)) system,
    ];
  }

  bool _systemOnMap(WorkSystem system, WorkSchema? schema, Set<String> plant) {
    final assigned = _workspace.schemas.any(
      (item) => item.systemIds.contains(system.id),
    );
    if (schema != null && assigned && !schema.systemIds.contains(system.id)) {
      return false;
    }
    if (plant.isEmpty || system.scopeIds.isEmpty) {
      return true;
    }
    return system.scopeIds.any(plant.contains);
  }

  List<ExchangeFlow> _visibleFlows(Set<String> systemIds, Set<String> plant) {
    bool endpoint(String id) {
      if (systemIds.contains(id)) {
        return true;
      }
      final asset = findAsset(_workspace, id);
      if (asset == null) {
        return false;
      }
      return plant.isEmpty || plant.contains(asset.id);
    }

    return [
      for (final flow in _workspace.flows)
        if (endpoint(flow.sourceId) && endpoint(flow.targetId)) flow,
    ];
  }

  _Geometry _geometry() {
    final systems = _visibleSystems();
    final plant = _plantSubtree(_plantId);
    final flows = _visibleFlows({for (final item in systems) item.id}, plant);
    final cited = <Asset>[];
    for (final flow in flows) {
      for (final id in [flow.sourceId, flow.targetId]) {
        final asset = findAsset(_workspace, id);
        if (asset != null && cited.every((item) => item.id != asset.id)) {
          cited.add(asset);
        }
      }
    }
    final boxes = <String, _Box>{};
    var y = 56.0;
    var width = 680.0;

    void place(String band, List<String> ids, double header) {
      final top = y;
      for (var index = 0; index < ids.length; index++) {
        boxes[ids[index]] = _Box(
          ids[index],
          Rect.fromLTWH(8 + index * 218, top + header, 210, 128),
          band,
        );
      }
      width = math.max(width, 16 + math.max(1, ids.length) * 218);
      final body = ids.isEmpty ? 8.0 : 140.0;
      y += header + body;
    }

    List<String> ids(ItOtZone zone) => [
      for (final system in systems)
        if (system.zone == zone) system.id,
    ];
    place('it', ids(ItOtZone.it), 52);
    place('boundary', ids(ItOtZone.boundary), 86);
    place('ot', ids(ItOtZone.ot), 44);
    final undefined = ids(ItOtZone.undefined);
    if (undefined.isNotEmpty) {
      place('undefined', undefined, 44);
    }
    if (cited.isNotEmpty) {
      place('cited', [for (final asset in cited) asset.id], 52);
    }
    return _Geometry(boxes, Size(width, math.max(y + 12, 460)), flows);
  }

  String _query() => _search.text.trim().toLowerCase();

  bool _nameHit(String name) {
    final query = _query();
    return query.isEmpty || name.toLowerCase().contains(query);
  }

  bool _assetShown(Asset asset) {
    if (_nameHit(asset.name)) {
      return true;
    }
    return _workspace.assets
        .where((item) => item.parentId == asset.id)
        .any(_assetShown);
  }

  String _entityLabel(String id) {
    final organization = findOrganization(_workspace, id);
    if (organization != null) {
      return organization.name;
    }
    final asset = findAsset(_workspace, id);
    if (asset != null) {
      return asset.name;
    }
    final system = findSystem(_workspace, id);
    if (system != null) {
      return system.name;
    }
    final flow = findFlow(_workspace, id);
    if (flow != null) {
      return flow.name;
    }
    return id;
  }

  @override
  Widget build(BuildContext context) {
    _ensureContext();
    final status = saveStatusText(
      widget.repository.status,
      quotaExceeded: widget.repository.quotaExceeded,
    );
    return Theme(
      data: workspaceTheme(),
      child: Scaffold(
        backgroundColor: canvas,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1100;
              return Column(
                children: [
                  _header(wide),
                  Expanded(
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _rail(),
                              SizedBox(width: 248, child: _tree()),
                              Expanded(child: _map()),
                              SizedBox(width: 320, child: _inspector()),
                            ],
                          )
                        : Column(
                            children: [
                              if (_treeOpen) Expanded(flex: 5, child: _tree()),
                              Expanded(flex: 4, child: _map()),
                              if (_inspectorOpen)
                                Expanded(flex: 6, child: _inspector()),
                            ],
                          ),
                  ),
                  _bottom(status, wide),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(bool wide) {
    return Material(
      color: panel,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children:
              [
                    if (!wide) ...[
                      _toggle(
                        workspaceTreeToggleKey,
                        _treeOpen,
                        'Jerarquia',
                        'Tanca la jerarquia',
                        Icons.account_tree,
                        () => setState(() => _treeOpen = !_treeOpen),
                      ),
                      _toggle(
                        workspaceInspectorToggleKey,
                        _inspectorOpen,
                        'Inspector',
                        'Tanca l\'inspector',
                        Icons.tune,
                        () => setState(() => _inspectorOpen = !_inspectorOpen),
                      ),
                    ],
                    const Text(
                      'Mapa de planta',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.onOpenOee != null)
                      _nav(
                        Icons.calculate_outlined,
                        'Calculador OEE',
                        widget.onOpenOee!,
                      ),
                    if (widget.onOpenData != null)
                      _nav(
                        Icons.folder_outlined,
                        'Dades locals',
                        widget.onOpenData!,
                      ),
                    _addMenu(),
                    if (_workspace.organizations.isEmpty &&
                        _workspace.systems.isEmpty)
                      OutlinedButton.icon(
                        key: workspaceLoadExampleKey,
                        style: workspaceControlStyle,
                        onPressed: widget.repository.status == SaveStatus.saving
                            ? null
                            : _loadExample,
                        icon: const Icon(Icons.factory_outlined),
                        label: const Text('Carrega exemple alimentari'),
                      ),
                  ]
                  .map(
                    (child) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: child,
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }

  Widget _toggle(
    Key key,
    bool open,
    String closed,
    String opened,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      key: key,
      style: workspaceControlStyle,
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(open ? opened : closed),
    );
  }

  Widget _nav(IconData icon, String label, VoidCallback onPressed) {
    return OutlinedButton.icon(
      style: workspaceControlStyle,
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }

  Widget _addMenu() {
    return PopupMenuButton<_Draft>(
      key: workspaceAddKey,
      tooltip: 'Afegeix',
      onSelected: _startCreate,
      itemBuilder: (context) => const [
        PopupMenuItem(value: _Draft.organization, child: Text('Organització')),
        PopupMenuItem(value: _Draft.plant, child: Text('Planta')),
        PopupMenuItem(value: _Draft.area, child: Text('Àrea')),
        PopupMenuItem(value: _Draft.line, child: Text('Línia')),
        PopupMenuItem(value: _Draft.machine, child: Text('Màquina')),
        PopupMenuItem(value: _Draft.system, child: Text('Sistema')),
        PopupMenuItem(value: _Draft.flow, child: Text('Flux')),
      ],
      child: const SizedBox(
        height: 48,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(Icons.add), SizedBox(width: 6), Text('Afegeix')],
          ),
        ),
      ),
    );
  }

  Widget _rail() {
    return Container(
      width: 76,
      color: anthracite,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          if (widget.onOpenOee != null)
            _railButton(Icons.calculate_outlined, 'OEE', widget.onOpenOee!),
          _railButton(Icons.account_tree, 'Mapa', () {}),
          if (widget.onOpenData != null)
            _railButton(Icons.folder_outlined, 'Dades', widget.onOpenData!),
        ],
      ),
    );
  }

  Widget _railButton(IconData icon, String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: panel,
          minimumSize: const Size(64, 48),
          backgroundColor: label == 'Mapa'
              ? const Color(0xFF2A333C)
              : Colors.transparent,
        ),
        onPressed: onPressed,
        child: Column(
          children: [
            Icon(icon, size: 18, color: panel),
            Text(label, style: const TextStyle(fontSize: 11, color: panel)),
          ],
        ),
      ),
    );
  }

  Widget _tree() {
    final query = _query();
    final organizations = [
      for (final organization in _workspace.organizations)
        if (query.isEmpty ||
            _nameHit(organization.name) ||
            _workspace.assets.any(
              (asset) =>
                  asset.parentId == organization.id && _assetShown(asset),
            ))
          organization,
    ];
    return Material(
      key: workspaceTreeKey,
      color: panel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Text(
              'On és · Jerarquia física',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                labelText: 'Cerca',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              key: const Key('workspaceTreeList'),
              scrollCacheExtent: const ScrollCacheExtent.pixels(8000),
              children: [
                for (final organization in organizations) ...[
                  _treeTile(
                    id: organization.id,
                    title: organization.name,
                    subtitle: 'Organització',
                    icon: organization.iconKey,
                    depth: 0,
                  ),
                  for (final asset in _children(organization.id))
                    ..._assetTiles(asset, 1),
                ],
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: Text(
                    'Sistemes',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'No pengen de cap màquina. L\'abast no és una filiació.',
                    style: TextStyle(fontSize: 12, color: steel),
                  ),
                ),
                for (final system in _workspace.systems)
                  if (_nameHit(system.name))
                    _treeTile(
                      id: system.id,
                      title: system.name,
                      subtitle:
                          '${systemTypeLabel(system.systemType)} · ${itOtZoneLabel(system.zone)}',
                      icon: system.iconKey,
                      depth: 0,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Asset> _children(String parentId) {
    return [
      for (final asset in _workspace.assets)
        if (asset.parentId == parentId && _assetShown(asset)) asset,
    ];
  }

  List<Widget> _assetTiles(Asset asset, int depth) {
    return [
      _treeTile(
        id: asset.id,
        title: asset.name,
        subtitle: assetKindLabel(asset.kind),
        icon: asset.iconKey,
        depth: depth,
      ),
      for (final child in _children(asset.id)) ..._assetTiles(child, depth + 1),
    ];
  }

  Widget _treeTile({
    required String id,
    required String title,
    required String subtitle,
    required IconKey icon,
    required int depth,
  }) {
    final selected = _selectedId == id && _creating == null;
    final state = selected ? '$subtitle · Seleccionat' : subtitle;
    return Padding(
      padding: EdgeInsets.only(left: depth * 12),
      child: ListTile(
        key: Key('tree-$id'),
        focusNode: _node('tree-$id'),
        minTileHeight: 48,
        selected: selected,
        leading: Icon(iconFor(icon), color: ink),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(state, style: const TextStyle(color: steel)),
        onTap: () => _select(id),
      ),
    );
  }

  Widget _map() {
    final geometry = _geometry();
    final systems = {
      for (final system in _workspace.systems) system.id: system,
    };
    return ColoredBox(
      key: workspaceMapKey,
      color: canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                const Center(
                  child: Text(
                    'Què fa i què connecta',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                Center(child: _plantControl()),
                const SizedBox(width: 12),
                Center(child: _schemaControl()),
              ],
            ),
          ),
          Expanded(
            child: Focus(
              autofocus: false,
              onKeyEvent: _mapKeys,
              child: InteractiveViewer(
                transformationController: _transform,
                constrained: false,
                minScale: 0.35,
                maxScale: 2.5,
                boundaryMargin: const EdgeInsets.all(120),
                child: SizedBox(
                  width: geometry.size.width,
                  height: geometry.size.height,
                  child: Stack(
                    children: [
                      const Positioned(
                        left: 8,
                        top: 8,
                        width: 540,
                        child: Text(
                          '$placementExplanation Un abast compartit no crea un flux.',
                          style: TextStyle(fontSize: 12, color: steel),
                        ),
                      ),
                      Positioned(
                        left: 8,
                        top: _bandTop(geometry, 'it'),
                        right: 8,
                        height: 48,
                        child: const Text(
                          'IT · sistemes amb zona declarada IT',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Positioned(
                        left: 8,
                        top: _bandTop(geometry, 'boundary'),
                        width: 540,
                        child: const Text(
                          l3Explanation,
                          key: mapL3ExplanationKey,
                        ),
                      ),
                      Positioned(
                        left: 8,
                        top: _bandTop(geometry, 'ot'),
                        right: 8,
                        child: const Text(
                          'OT · sistemes amb zona declarada OT',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (geometry.boxes.values.any(
                        (box) => box.band == 'undefined',
                      ))
                        Positioned(
                          left: 8,
                          top: _bandTop(geometry, 'undefined'),
                          child: const Text('Zona no definida'),
                        ),
                      if (geometry.boxes.values.any(
                        (box) => box.band == 'cited',
                      ))
                        Positioned(
                          left: 8,
                          top: _bandTop(geometry, 'cited'),
                          right: 8,
                          child: const Text(
                            'Actius citats per fluxos. Això no és un nivell ISA-95.',
                          ),
                        ),
                      Positioned.fill(
                        child: CustomPaint(painter: _ArrowPainter(geometry)),
                      ),
                      for (final box in geometry.boxes.values)
                        Positioned.fromRect(
                          rect: box.rect,
                          child: systems.containsKey(box.id)
                              ? _systemCard(systems[box.id]!)
                              : _assetCard(findAsset(_workspace, box.id)!),
                        ),
                      for (final flow in geometry.flows)
                        if (geometry.boxes[flow.sourceId] != null &&
                            geometry.boxes[flow.targetId] != null)
                          _flowLabel(flow, geometry),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _bandTop(_Geometry geometry, String band) {
    for (final box in geometry.boxes.values) {
      if (box.band == band) {
        return math.max(0, box.rect.top - _headerOf(band));
      }
    }
    var y = 56.0;
    const order = ['it', 'boundary', 'ot', 'undefined', 'cited'];
    const headers = {
      'it': 52.0,
      'boundary': 86.0,
      'ot': 44.0,
      'undefined': 44.0,
      'cited': 52.0,
    };
    for (final name in order) {
      if (name == band) {
        return y;
      }
      final count = geometry.boxes.values
          .where((box) => box.band == name)
          .length;
      if (name == 'undefined' && count == 0) {
        continue;
      }
      if (name == 'cited' && count == 0) {
        continue;
      }
      y += (headers[name] ?? 40) + (count == 0 ? 8 : 140);
    }
    return y;
  }

  double _headerOf(String band) {
    switch (band) {
      case 'boundary':
        return 86;
      case 'it':
      case 'cited':
        return 52;
      default:
        return 44;
    }
  }

  KeyEventResult _mapKeys(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        _pan(48, 0);
      case LogicalKeyboardKey.arrowRight:
        _pan(-48, 0);
      case LogicalKeyboardKey.arrowUp:
        _pan(0, 48);
      case LogicalKeyboardKey.arrowDown:
        _pan(0, -48);
      case LogicalKeyboardKey.equal:
      case LogicalKeyboardKey.numpadAdd:
        _zoom(1.15);
      case LogicalKeyboardKey.minus:
      case LogicalKeyboardKey.numpadSubtract:
        _zoom(1 / 1.15);
      case LogicalKeyboardKey.keyF:
        _fit();
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  Widget _flowLabel(ExchangeFlow flow, _Geometry geometry) {
    final from = geometry.boxes[flow.sourceId]!.rect.center;
    final to = geometry.boxes[flow.targetId]!.rect.center;
    final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
    final left = mid.dx
        .clamp(0.0, math.max(0, geometry.size.width - 150))
        .toDouble();
    final top = mid.dy
        .clamp(0.0, math.max(0, geometry.size.height - 28))
        .toDouble();
    return Positioned(
      left: left,
      top: top,
      width: 140,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: panel,
            border: Border.all(color: steel),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              '${flow.exchangedData} · ${flowStatusLabel(flow.status)} →',
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ),
      ),
    );
  }

  Widget _systemCard(WorkSystem system) {
    final selected = _selectedId == system.id && _creating == null;
    final functions = system.functions.isEmpty
        ? 'Sense funcions'
        : system.functions.map(functionChip).join(', ');
    return _card(
      id: system.id,
      icon: system.iconKey,
      title: system.name,
      lines: [
        systemTypeLabel(system.systemType),
        functions,
        'Zona: ${itOtZoneLabel(system.zone)}',
        'Abast: ${_scopeLabel(system.scopeIds)}',
        if (selected) 'Seleccionat',
      ],
      band: system.zone,
    );
  }

  Widget _assetCard(Asset asset) {
    final selected = _selectedId == asset.id && _creating == null;
    return _card(
      id: asset.id,
      icon: asset.iconKey,
      title: asset.name,
      lines: [
        assetKindLabel(asset.kind),
        'Actiu citat per un flux',
        if (selected) 'Seleccionat',
      ],
      band: null,
    );
  }

  Widget _card({
    required String id,
    required IconKey icon,
    required String title,
    required List<String> lines,
    required ItOtZone? band,
  }) {
    final selected = _selectedId == id && _creating == null;
    return Material(
      color: panel,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: selected ? anthracite : steelLine,
          width: selected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        key: Key('map-$id'),
        focusNode: _node('map-$id'),
        onTap: () => _select(id),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(iconFor(icon), size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              for (final line in lines)
                Text(
                  line,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _scopeLabel(List<String> ids) {
    if (ids.isEmpty) {
      return 'Sense abast';
    }
    return ids.map(_entityLabel).join(', ');
  }

  Widget _plantControl() {
    final plants = [
      for (final asset in _workspace.assets)
        if (asset.kind == AssetKind.plant) asset,
    ];
    if (plants.isEmpty) {
      return const Text('Cap planta', style: TextStyle(color: steel));
    }
    return DropdownButton<String>(
      value: plants.any((item) => item.id == _plantId) ? _plantId : null,
      hint: const Text('Planta'),
      items: [
        for (final plant in plants)
          DropdownMenuItem(value: plant.id, child: Text(plant.name)),
      ],
      onChanged: (value) => setState(() => _plantId = value),
    );
  }

  Widget _schemaControl() {
    final schemas = _workspace.schemas;
    if (schemas.isEmpty) {
      return const Text('Cap esquema');
    }
    if (schemas.length == 1) {
      return Text('Esquema: ${schemas.single.name}');
    }
    return DropdownButton<String>(
      value: schemas.any((item) => item.id == _schemaId) ? _schemaId : null,
      items: [
        for (final schema in schemas)
          DropdownMenuItem(value: schema.id, child: Text(schema.name)),
      ],
      onChanged: (value) => setState(() => _schemaId = value),
    );
  }

  Widget _inspector() {
    return Material(
      key: workspaceInspectorKey,
      color: panel,
      child: ListView(
        scrollCacheExtent: const ScrollCacheExtent.pixels(8000),
        padding: const EdgeInsets.all(12),
        children: [
          const Text(
            'Què és · Selecció',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (widget.repository.banner != null) Text(widget.repository.banner!),
          if (_errors['_form'] != null) _error('_form'),
          ..._inspectorBody(),
        ],
      ),
    );
  }

  List<Widget> _inspectorBody() {
    if (_creating != null) {
      return _editor(creating: true);
    }
    final id = _selectedId;
    if (id == null) {
      return const [Text('Selecciona un element de l\'arbre o del mapa.')];
    }
    return _editor(creating: false);
  }

  List<Widget> _editor({required bool creating}) {
    final id = _selectedId;
    final organization = !creating && id != null
        ? findOrganization(_workspace, id)
        : null;
    final asset = !creating && id != null ? findAsset(_workspace, id) : null;
    final system = !creating && id != null ? findSystem(_workspace, id) : null;
    final flow = !creating && id != null ? findFlow(_workspace, id) : null;
    final draftingFlow = _creating == _Draft.flow || flow != null;
    final draftingSystem = _creating == _Draft.system || system != null;
    final draftingAsset =
        _creating == _Draft.plant ||
        _creating == _Draft.area ||
        _creating == _Draft.line ||
        _creating == _Draft.machine ||
        asset != null;
    final draftingOrg =
        _creating == _Draft.organization || organization != null;
    final children = <Widget>[
      if (!creating && id != null)
        Text('Identificador $id. Es conserva en reanomenar.'),
      _textField(workspaceNameFieldKey, _name, 'Nom', 'name'),
      _textField(null, _description, 'Descripció', null),
    ];
    if (draftingOrg) {
      children.add(
        const Text(
          'Sense funció ISA-95. L\'organització no té selector L0–L4 ni es converteix en un sistema.',
        ),
      );
      final review = _reviewFor(organization?.id);
      if (review != null) {
        children.add(
          Text(
            'Revisió ${review.status == ReviewStatus.pendingReview ? 'pendent' : 'revisada'}: etiqueta antiga ${review.legacyFunctionalLevelLabel}, no promoguda.',
          ),
        );
      }
    }
    if (draftingAsset) {
      children.add(_parentField());
      children.add(_iconField(assetIconKeys));
      children.add(
        const Text('Les funcions no es dedueixen del tipus d\'equip.'),
      );
      children.add(_functionField());
    }
    if (draftingSystem) {
      children.add(
        _enumField<SystemType>(
          label: 'Tipus',
          value: _systemType,
          values: SystemType.values,
          text: systemTypeLabel,
          onChanged: (value) => setState(() => _systemType = value),
        ),
      );
      children.add(
        _enumField<ItOtZone>(
          label: 'Zona',
          value: _zone,
          values: ItOtZone.values,
          text: itOtZoneLabel,
          onChanged: (value) => setState(() => _zone = value),
        ),
      );
      children.add(_iconField(systemIconKeys));
      children.add(
        const Text(
          'El tipus no assigna la funció ni la zona. L\'abast no mou els actius.',
        ),
      );
      children.add(_functionField());
      children.add(_scopeField());
    }
    if (draftingFlow) {
      children.addAll(_flowFields());
    }
    if (asset?.kind == AssetKind.line) {
      children.add(const SizedBox(height: 8));
      children.add(
        const Text(
          'El càlcul OEE d\'aquesta pantalla no és el de la secció 5. El calculador US-1 continua disponible.',
        ),
      );
      if (widget.onOpenOee != null) {
        children.add(
          OutlinedButton.icon(
            style: workspaceControlStyle,
            onPressed: widget.onOpenOee,
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Obre el calculador'),
          ),
        );
      }
    }
    children.add(const SizedBox(height: 8));
    children.add(
      FilledButton(
        key: workspaceSaveEditKey,
        style: workspaceControlStyle,
        focusNode: _node('save'),
        onPressed: widget.repository.status == SaveStatus.saving ? null : _save,
        child: const Text('Desa'),
      ),
    );
    if (creating) {
      children.add(
        OutlinedButton(
          style: workspaceControlStyle,
          onPressed: () => setState(() {
            _creating = null;
            _errors = {};
            _loadForm();
          }),
          child: const Text('Cancel·la'),
        ),
      );
    } else if (id != null) {
      children.add(
        OutlinedButton(
          key: workspaceDeleteKey,
          style: workspaceControlStyle,
          onPressed: widget.repository.status == SaveStatus.saving
              ? null
              : _delete,
          child: Text(flow == null ? 'Elimina' : 'Descarta'),
        ),
      );
    }
    if (!creating && (asset != null || system != null)) {
      children.addAll(_endpointFlows(id!));
    }
    return children;
  }

  MigrationReview? _reviewFor(String? id) {
    if (id == null) {
      return null;
    }
    for (final review in _workspace.migrationReviews) {
      if (review.entityId == id) {
        return review;
      }
    }
    return null;
  }

  Widget _textField(
    Key? key,
    TextEditingController controller,
    String label,
    String? field,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: key,
            controller: controller,
            focusNode: key == workspaceNameFieldKey ? _node('name') : null,
            decoration: InputDecoration(labelText: label),
          ),
          if (field != null) _error(field),
        ],
      ),
    );
  }

  Widget _error(String field) {
    final message = _errors[field];
    if (message == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        'Error: $message',
        style: const TextStyle(color: Color(0xFF8C3A3A)),
      ),
    );
  }

  Widget _parentField() {
    final options = <DropdownMenuItem<String>>[
      for (final organization in _workspace.organizations)
        DropdownMenuItem(
          key: Key('parent-option-${organization.id}'),
          value: organization.id,
          child: Text('${organization.name} · Organització'),
        ),
      for (final asset in _workspace.assets)
        DropdownMenuItem(
          key: Key('parent-option-${asset.id}'),
          value: asset.id,
          child: Text('${asset.name} · ${assetKindLabel(asset.kind)}'),
        ),
    ];
    final valid = options.any((item) => item.value == _parentId);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Pare'),
            child: DropdownButton<String>(
              key: workspaceParentFieldKey,
              value: valid ? _parentId : null,
              isExpanded: true,
              items: options,
              onChanged: (value) => setState(() => _parentId = value),
            ),
          ),
          _error('parentId'),
        ],
      ),
    );
  }

  Widget _iconField(Set<IconKey> allowed) {
    final value = allowed.contains(_icon) ? _icon : allowed.first;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Icona'),
        child: DropdownButton<IconKey>(
          key: ValueKey('icon-${_creating?.name}-$_selectedId'),
          value: value,
          isExpanded: true,
          items: [
            for (final icon in allowed)
              DropdownMenuItem(
                value: icon,
                child: Row(
                  children: [
                    Icon(iconFor(icon), size: 18),
                    const SizedBox(width: 8),
                    Text(iconKeyLabel(icon)),
                  ],
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _icon = value);
            }
          },
        ),
      ),
    );
  }

  Widget _functionField() {
    return Padding(
      key: isaFunctionsKey,
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Funcions declarades'),
          for (final function in IsaFunction.values)
            CheckboxListTile(
              key: Key('function-${function.name}'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(functionChip(function)),
              value: _functions.contains(function),
              onChanged: (checked) => setState(() {
                if (checked ?? false) {
                  _functions.add(function);
                } else {
                  _functions.remove(function);
                }
              }),
            ),
          _error('functions'),
        ],
      ),
    );
  }

  Widget _scopeField() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Abast'),
          for (final asset in _workspace.assets)
            CheckboxListTile(
              key: Key('scope-${asset.id}'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text('${asset.name} · ${assetKindLabel(asset.kind)}'),
              value: _scope.contains(asset.id),
              onChanged: (checked) => setState(() {
                if (checked ?? false) {
                  _scope.add(asset.id);
                } else {
                  _scope.remove(asset.id);
                }
              }),
            ),
          _error('scopeIds'),
        ],
      ),
    );
  }

  Widget _enumField<T extends Object>({
    required String label,
    required T value,
    required List<T> values,
    required String Function(T value) text,
    required ValueChanged<T> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: DropdownButton<T>(
          key: ValueKey('$label-${_creating?.name}-$_selectedId'),
          value: value,
          isExpanded: true,
          items: [
            for (final item in values)
              DropdownMenuItem(value: item, child: Text(text(item))),
          ],
          onChanged: (next) {
            if (next != null) {
              onChanged(next);
            }
          },
        ),
      ),
    );
  }

  List<Widget> _flowFields() {
    List<DropdownMenuItem<String>> endpoints() => [
      for (final asset in _workspace.assets)
        DropdownMenuItem(
          value: asset.id,
          child: Text('${asset.name} · ${assetKindLabel(asset.kind)}'),
        ),
      for (final system in _workspace.systems)
        DropdownMenuItem(
          value: system.id,
          child: Text('${system.name} · ${systemTypeLabel(system.systemType)}'),
        ),
    ];
    Widget endpoint(
      String label,
      String? value,
      ValueChanged<String?> onChanged,
    ) {
      final items = endpoints();
      final valid = items.any((item) => item.value == value);
      return DropdownButton<String>(
        key: ValueKey('$label-${_creating?.name}-$_selectedId'),
        value: valid ? value : null,
        isExpanded: true,
        hint: Text(label),
        items: items,
        onChanged: onChanged,
      );
    }

    return [
      const Text(
        'El flux és manual. L\'estat es tria; no es dedueix de l\'abast.',
      ),
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: endpoint('Origen', _flowSource, (value) {
          setState(() => _flowSource = value);
        }),
      ),
      _error('sourceId'),
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: endpoint('Destí', _flowTarget, (value) {
          setState(() => _flowTarget = value);
        }),
      ),
      _error('targetId'),
      _textField(
        workspaceFlowDataKey,
        _data,
        'Dades intercanviades',
        'exchangedData',
      ),
      CheckboxListTile(
        key: workspaceUnknownProtocolKey,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: const Text('Protocol desconegut'),
        value: _unknownProtocol,
        onChanged: (checked) =>
            setState(() => _unknownProtocol = checked ?? false),
      ),
      if (!_unknownProtocol)
        _textField(workspaceFlowProtocolKey, _protocol, 'Protocol', 'protocol'),
      _textField(workspaceFlowPurposeKey, _purpose, 'Finalitat', 'purpose'),
      const Text('Estat explícit'),
      Wrap(
        spacing: 8,
        children: [
          for (final status in FlowStatus.values)
            OutlinedButton(
              style: workspaceControlStyle.copyWith(
                backgroundColor: WidgetStatePropertyAll(
                  _flowStatus == status ? itBand : panel,
                ),
              ),
              onPressed: () => setState(() => _flowStatus = status),
              child: Text(
                _flowStatus == status
                    ? 'Estat: ${flowStatusLabel(status)}'
                    : flowStatusLabel(status),
              ),
            ),
        ],
      ),
    ];
  }

  List<Widget> _endpointFlows(String id) {
    final flows = [
      for (final flow in _workspace.flows)
        if (flow.sourceId == id || flow.targetId == id) flow,
    ];
    return [
      const SizedBox(height: 12),
      const Text('Fluxos', style: TextStyle(fontWeight: FontWeight.w600)),
      if (flows.isEmpty) const Text('Cap flux declarat.'),
      for (final flow in flows) ...[
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(flow.name),
          subtitle: Text(
            '${_entityLabel(flow.sourceId)} → ${_entityLabel(flow.targetId)} · ${flow.exchangedData} · ${flow.protocol ?? 'Protocol desconegut'} · ${flow.purpose} · ${flowStatusLabel(flow.status)}',
          ),
          onTap: () => _select(flow.id),
        ),
        if (flow.status == FlowStatus.suggested)
          OutlinedButton(
            key: Key('confirm-flow-${flow.id}'),
            style: workspaceControlStyle,
            onPressed: () => _confirmFlow(flow.id),
            child: const Text('Confirma el flux'),
          ),
        OutlinedButton(
          key: Key('discard-flow-${flow.id}'),
          style: workspaceControlStyle,
          onPressed: () {
            _select(flow.id);
            _delete();
          },
          child: const Text('Descarta'),
        ),
      ],
      OutlinedButton.icon(
        style: workspaceControlStyle,
        onPressed: () => _startCreate(_Draft.flow),
        icon: const Icon(Icons.arrow_forward),
        label: const Text('Afegeix flux'),
      ),
    ];
  }

  Widget _bottom(String status, bool wide) {
    return Material(
      color: const Color(0xFFE6EBEF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children:
                  [
                        OutlinedButton(
                          key: workspaceZoomInKey,
                          style: workspaceControlStyle,
                          onPressed: () => _zoom(1.15),
                          child: const Text('Apropa'),
                        ),
                        OutlinedButton(
                          key: workspaceZoomOutKey,
                          style: workspaceControlStyle,
                          onPressed: () => _zoom(1 / 1.15),
                          child: const Text('Allunya'),
                        ),
                        OutlinedButton(
                          key: workspaceFitKey,
                          style: workspaceControlStyle,
                          onPressed: _fit,
                          child: const Text('Enquadra'),
                        ),
                        OutlinedButton(
                          style: workspaceControlStyle,
                          onPressed: () => _pan(48, 0),
                          child: const Text('Esquerra'),
                        ),
                        OutlinedButton(
                          style: workspaceControlStyle,
                          onPressed: () => _pan(-48, 0),
                          child: const Text('Dreta'),
                        ),
                        OutlinedButton(
                          style: workspaceControlStyle,
                          onPressed: () => _pan(0, 48),
                          child: const Text('Amunt'),
                        ),
                        OutlinedButton(
                          style: workspaceControlStyle,
                          onPressed: () => _pan(0, -48),
                          child: const Text('Avall'),
                        ),
                        Text(
                          status,
                          key: workspaceSaveStatusKey,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text('Instantànies: ${_workspace.versions.length}'),
                      ]
                      .map(
                        (child) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: child,
                        ),
                      )
                      .toList(),
            ),
          ),
          const SizedBox(
            height: 72,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(
                storageLimitationMessage,
                style: TextStyle(fontSize: 12, color: ink),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Box {
  const _Box(this.id, this.rect, this.band);

  final String id;
  final Rect rect;
  final String band;
}

class _Geometry {
  const _Geometry(this.boxes, this.size, this.flows);

  final Map<String, _Box> boxes;
  final Size size;
  final List<ExchangeFlow> flows;
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter(this.geometry);

  final _Geometry geometry;

  @override
  void paint(Canvas canvas, Size size) {
    for (final flow in geometry.flows) {
      final source = geometry.boxes[flow.sourceId];
      final target = geometry.boxes[flow.targetId];
      if (source == null || target == null) {
        continue;
      }
      final from = source.rect.center;
      final to = target.rect.center;
      final confirmed = flow.status == FlowStatus.confirmed;
      final paint = Paint()
        ..color = anthracite
        ..strokeWidth = confirmed ? 2 : 1.2
        ..style = PaintingStyle.stroke;
      if (confirmed) {
        canvas.drawLine(from, to, paint);
      } else {
        _dash(canvas, from, to, paint);
      }
      final delta = to - from;
      final length = delta.distance;
      if (length < 8) {
        continue;
      }
      final unit = delta / length;
      final normal = Offset(-unit.dy, unit.dx);
      final tip = to - unit * 8;
      final base = tip - unit * 10;
      final path = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(base.dx + normal.dx * 5, base.dy + normal.dy * 5)
        ..lineTo(base.dx - normal.dx * 5, base.dy - normal.dy * 5)
        ..close();
      canvas.drawPath(path, Paint()..color = anthracite);
    }
  }

  void _dash(Canvas canvas, Offset from, Offset to, Paint paint) {
    final delta = to - from;
    final length = delta.distance;
    if (length == 0) {
      return;
    }
    final unit = delta / length;
    var drawn = 0.0;
    var on = true;
    while (drawn < length) {
      final next = math.min(drawn + (on ? 7 : 4), length);
      if (on) {
        canvas.drawLine(from + unit * drawn, from + unit * next, paint);
      }
      drawn = next;
      on = !on;
    }
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) => true;
}

class _DeleteDialog extends StatefulWidget {
  const _DeleteDialog({required this.workspace, required this.report});

  final Workspace workspace;
  final DependencyReport report;

  @override
  State<_DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<_DeleteDialog> {
  final _cancelFocus = FocusNode();
  final _confirmFocus = FocusNode();

  @override
  void dispose() {
    _cancelFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  String _names(List<String> ids) {
    if (ids.isEmpty) {
      return 'Cap';
    }
    return ids
        .map((id) {
          for (final item in widget.workspace.organizations) {
            if (item.id == id) {
              return item.name;
            }
          }
          for (final item in widget.workspace.assets) {
            if (item.id == id) {
              return item.name;
            }
          }
          for (final item in widget.workspace.systems) {
            if (item.id == id) {
              return item.name;
            }
          }
          for (final item in widget.workspace.flows) {
            if (item.id == id) {
              return item.name;
            }
          }
          for (final item in widget.workspace.schemas) {
            if (item.id == id) {
              return item.name;
            }
          }
          return id;
        })
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    return AlertDialog(
      title: const Text('Eliminar amb dependències'),
      content: SingleChildScrollView(
        child: Text(
          'Fills: ${_names(report.childIds)}\n'
          'Sistemes que l\'abasten: ${_names(report.scopeSystemIds)}\n'
          'Fluxos: ${_names(report.flowIds)}\n'
          'Esquemes: ${_names(report.schemaIds)}\n'
          'No s\'esborren les instantànies: ${_names(report.retainedSnapshotIds)}.\n'
          'No s\'esborren els registres OEE: ${_names(report.retainedOeeRecordIds)}.',
        ),
      ),
      actions: [
        TextButton(
          key: workspaceCancelDeleteKey,
          focusNode: _cancelFocus,
          style: workspaceControlStyle,
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel·la'),
        ),
        TextButton(
          key: workspaceConfirmDeleteKey,
          focusNode: _confirmFocus,
          style: workspaceControlStyle,
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Elimina'),
        ),
      ],
    );
  }
}
