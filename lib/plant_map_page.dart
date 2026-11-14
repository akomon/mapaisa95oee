import 'package:flutter/material.dart';

import 'plant_io.dart' as plant_io;
import 'plant_model.dart';
import 'plant_store.dart';
import 'workspace_shell.dart';
import 'workspace_theme.dart';

const Key plantMapTreeTabKey = Key('plantMapTreeTab');
const Key plantMapLevelsTabKey = Key('plantMapLevelsTab');
const Key plantMapAddEnterpriseKey = Key('plantMapAddEnterprise');
const Key plantMapLoadExampleKey = Key('plantMapLoadExample');
const Key plantMapExportKey = Key('plantMapExport');
const Key plantMapImportKey = Key('plantMapImport');
const Key plantMapNameFieldKey = Key('plantMapNameField');
const Key plantMapDescriptionFieldKey = Key('plantMapDescriptionField');
const Key plantConfirmDeleteKey = Key('plantConfirmDelete');

typedef PlantJsonExporter = Future<void> Function(String filename, String json);
typedef PlantJsonImporter = Future<String?> Function();

class PlantMapPage extends StatefulWidget {
  const PlantMapPage({
    super.key,
    required this.store,
    this.onOpenOee,
    this.onOpenEngine,
    this.onOpenData,
    this.exportJson,
    this.importJson,
  });

  final PlantStore store;
  final VoidCallback? onOpenOee;
  final VoidCallback? onOpenEngine;
  final VoidCallback? onOpenData;
  final PlantJsonExporter? exportJson;
  final PlantJsonImporter? importJson;

  @override
  State<PlantMapPage> createState() => _PlantMapPageState();
}

class _PlantMapPageState extends State<PlantMapPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  Plant? _plant;
  String? _banner;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final plant = await widget.store.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _plant = plant;
      _loading = false;
    });
  }

  Future<void> _persist(Plant plant) async {
    setState(() {
      _plant = plant;
      _banner = null;
    });
    await widget.store.save(plant);
  }

  void _showIssues(List<PlantIssueCode> issues) {
    final message = issues.isEmpty
        ? plantIssueMessage(PlantIssueCode.invalidJson)
        : plantIssueMessage(issues.first);
    setState(() => _banner = message);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadExample() async {
    await _persist(foodPlantExample());
  }

  Future<void> _export() async {
    final plant = _plant;
    if (plant == null) {
      return;
    }
    final json = plantToJson(plant);
    final exporter = widget.exportJson ?? plant_io.downloadJsonFile;
    await exporter('planta-isa95.json', json);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('JSON exportat.')));
  }

  Future<void> _import() async {
    final importer = widget.importJson ?? plant_io.pickJsonFile;
    final raw = await importer();
    if (raw == null) {
      return;
    }
    final imported = plantFromJson(raw);
    if (!imported.isValid) {
      _showIssues(imported.issues);
      return;
    }
    await _persist(imported.plant!);
  }

  Future<void> _addEnterprise() async {
    final draft = await _openNodeEditor(
      title: 'Afegeix empresa',
      kind: PlantNodeKind.enterprise,
      initialLevel: FunctionalLevel.erp,
    );
    if (draft == null || _plant == null) {
      return;
    }
    final mutation = addChild(
      _plant!,
      name: draft.name,
      description: draft.description,
      kind: PlantNodeKind.enterprise,
      functionalLevel: draft.level,
    );
    if (!mutation.isValid) {
      _showIssues(mutation.issues);
      return;
    }
    await _persist(mutation.plant!);
  }

  Future<void> _addChild(PlantNode parent) async {
    final childKind = allowedChildKind(parent.kind);
    if (childKind == null || _plant == null) {
      return;
    }
    final draft = await _openNodeEditor(
      title: 'Afegeix ${plantNodeKindLabel(childKind).toLowerCase()}',
      kind: childKind,
      initialLevel: parent.functionalLevel,
    );
    if (draft == null) {
      return;
    }
    final mutation = addChild(
      _plant!,
      parentId: parent.id,
      name: draft.name,
      description: draft.description,
      kind: childKind,
      functionalLevel: draft.level,
    );
    if (!mutation.isValid) {
      _showIssues(mutation.issues);
      return;
    }
    await _persist(mutation.plant!);
  }

  Future<void> _editNode(PlantNode node) async {
    final draft = await _openNodeEditor(
      title: 'Edita ${plantNodeKindLabel(node.kind).toLowerCase()}',
      kind: node.kind,
      initialName: node.name,
      initialDescription: node.description,
      initialLevel: node.functionalLevel,
    );
    if (draft == null || _plant == null) {
      return;
    }
    final mutation = updateNode(
      _plant!,
      id: node.id,
      name: draft.name,
      description: draft.description,
      functionalLevel: draft.level,
    );
    if (!mutation.isValid) {
      _showIssues(mutation.issues);
      return;
    }
    await _persist(mutation.plant!);
  }

  Future<void> _deleteNode(PlantNode node) async {
    final plant = _plant;
    if (plant == null) {
      return;
    }
    if (nodeHasChildren(plant, node.id)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Esborra el node'),
            content: const Text(
              'Aquest node té fills. Segur que vols esborrar-lo amb tot el subarbre?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel·la'),
              ),
              TextButton(
                key: plantConfirmDeleteKey,
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Esborra'),
              ),
            ],
          );
        },
      );
      if (confirmed != true) {
        return;
      }
    }
    final mutation = removeNode(plant, id: node.id);
    if (!mutation.isValid) {
      _showIssues(mutation.issues);
      return;
    }
    await _persist(mutation.plant!);
  }

  Future<_NodeDraft?> _openNodeEditor({
    required String title,
    required PlantNodeKind kind,
    String initialName = '',
    String? initialDescription,
    required FunctionalLevel initialLevel,
  }) {
    return showDialog<_NodeDraft>(
      context: context,
      builder: (context) {
        return _NodeEditorDialog(
          title: title,
          kind: kind,
          initialName: initialName,
          initialDescription: initialDescription ?? '',
          initialLevel: initialLevel,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      OutlinedButton(
        key: plantMapAddEnterpriseKey,
        style: workspaceControlStyle,
        onPressed: _addEnterprise,
        child: const Text('Afegeix empresa'),
      ),
      OutlinedButton(
        key: plantMapLoadExampleKey,
        style: workspaceControlStyle,
        onPressed: _loadExample,
        child: const Text('Carrega exemple'),
      ),
      OutlinedButton(
        key: plantMapExportKey,
        style: workspaceControlStyle,
        onPressed: _export,
        child: const Text('Exporta JSON'),
      ),
      OutlinedButton(
        key: plantMapImportKey,
        style: workspaceControlStyle,
        onPressed: _import,
        child: const Text('Importa JSON'),
      ),
      if (widget.onOpenOee != null)
        workspaceBarButton(
          label: 'Calculador OEE',
          onPressed: widget.onOpenOee,
        ),
      if (widget.onOpenData != null)
        workspaceBarButton(label: 'Dades locals', onPressed: widget.onOpenData),
    ];
    return WorkspaceShell(
      current: WorkspaceSection.map,
      onOpenCalculator: widget.onOpenOee,
      onOpenEngine: widget.onOpenEngine,
      onOpenData: widget.onOpenData,
      header: WorkspaceHeader(
        title: 'Mapa ISA-95',
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(key: plantMapTreeTabKey, text: 'Arbre'),
            Tab(key: plantMapLevelsTabKey, text: 'Nivells'),
          ],
        ),
      ),
      bottom: WorkspaceBottomBar(children: actions),
      child: _loading || _plant == null
          ? const Center(child: CircularProgressIndicator())
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  children: [
                    if (_banner != null)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _banner!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          _TreeView(
                            plant: _plant!,
                            onAddChild: _addChild,
                            onEdit: _editNode,
                            onDelete: _deleteNode,
                          ),
                          _LevelsView(plant: _plant!),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _NodeDraft {
  const _NodeDraft({
    required this.name,
    required this.description,
    required this.level,
  });

  final String name;
  final String? description;
  final FunctionalLevel level;
}

class _NodeEditorDialog extends StatefulWidget {
  const _NodeEditorDialog({
    required this.title,
    required this.kind,
    required this.initialName,
    required this.initialDescription,
    required this.initialLevel,
  });

  final String title;
  final PlantNodeKind kind;
  final String initialName;
  final String initialDescription;
  final FunctionalLevel initialLevel;

  @override
  State<_NodeEditorDialog> createState() => _NodeEditorDialogState();
}

class _NodeEditorDialogState extends State<_NodeEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late FunctionalLevel _level;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
    _description = TextEditingController(text: widget.initialDescription);
    _level = widget.initialLevel;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _name.text.trim();
    if (trimmed.isEmpty) {
      setState(() => _error = plantIssueMessage(PlantIssueCode.emptyName));
      return;
    }
    Navigator.of(context).pop(
      _NodeDraft(name: trimmed, description: _description.text, level: _level),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Tipus: ${plantNodeKindLabel(widget.kind)}'),
              const SizedBox(height: 12),
              TextField(
                key: plantMapNameFieldKey,
                controller: _name,
                decoration: InputDecoration(
                  labelText: 'Nom',
                  errorText: _error,
                  constraints: const BoxConstraints(minHeight: 48),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: plantMapDescriptionFieldKey,
                controller: _description,
                decoration: const InputDecoration(
                  labelText: 'Descripció (opcional)',
                  constraints: BoxConstraints(minHeight: 48),
                ),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Nivell funcional',
                  constraints: BoxConstraints(minHeight: 48),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<FunctionalLevel>(
                    isExpanded: true,
                    value: _level,
                    items: [
                      for (final level in FunctionalLevel.values)
                        DropdownMenuItem(
                          value: level,
                          child: Text(
                            '${level.value} - ${functionalLevelLabel(level)}',
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _level = value);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel·la'),
        ),
        TextButton(onPressed: _submit, child: const Text('Desa')),
      ],
    );
  }
}

class _TreeView extends StatefulWidget {
  const _TreeView({
    required this.plant,
    required this.onAddChild,
    required this.onEdit,
    required this.onDelete,
  });

  final Plant plant;
  final ValueChanged<PlantNode> onAddChild;
  final ValueChanged<PlantNode> onEdit;
  final ValueChanged<PlantNode> onDelete;

  @override
  State<_TreeView> createState() => _TreeViewState();
}

class _TreeViewState extends State<_TreeView> {
  final Set<String> _collapsed = {};

  @override
  Widget build(BuildContext context) {
    if (widget.plant.roots.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Encara no hi ha empreses. Afegeix-ne una o carrega l\'exemple.',
          ),
        ),
      );
    }

    final rows = <Widget>[];
    void walk(PlantNode node, int depth) {
      final hasChildren = node.children.isNotEmpty;
      final expanded = hasChildren && !_collapsed.contains(node.id);
      rows.add(
        _TreeRow(
          node: node,
          depth: depth,
          hasChildren: hasChildren,
          expanded: expanded,
          onToggle: hasChildren
              ? () {
                  setState(() {
                    if (_collapsed.contains(node.id)) {
                      _collapsed.remove(node.id);
                    } else {
                      _collapsed.add(node.id);
                    }
                  });
                }
              : null,
          onAddChild: widget.onAddChild,
          onEdit: widget.onEdit,
          onDelete: widget.onDelete,
        ),
      );
      if (expanded) {
        for (final child in node.children) {
          walk(child, depth + 1);
        }
      }
    }

    for (final root in widget.plant.roots) {
      walk(root, 0);
    }

    return ListView(padding: const EdgeInsets.all(8), children: rows);
  }
}

class _TreeRow extends StatelessWidget {
  const _TreeRow({
    required this.node,
    required this.depth,
    required this.hasChildren,
    required this.expanded,
    required this.onToggle,
    required this.onAddChild,
    required this.onEdit,
    required this.onDelete,
  });

  final PlantNode node;
  final int depth;
  final bool hasChildren;
  final bool expanded;
  final VoidCallback? onToggle;
  final ValueChanged<PlantNode> onAddChild;
  final ValueChanged<PlantNode> onEdit;
  final ValueChanged<PlantNode> onDelete;

  @override
  Widget build(BuildContext context) {
    final canAdd = allowedChildKind(node.kind) != null;
    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0, top: 4, bottom: 4),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                height: 48,
                child: hasChildren
                    ? IconButton(
                        tooltip: expanded ? 'Replega' : 'Desplega',
                        onPressed: onToggle,
                        icon: Icon(
                          expanded ? Icons.expand_more : Icons.chevron_right,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      plantNodeKindLabel(node.kind),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    _LevelChip(level: node.functionalLevel),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Accions',
                onSelected: (value) {
                  switch (value) {
                    case 'add':
                      onAddChild(node);
                    case 'edit':
                      onEdit(node);
                    case 'delete':
                      onDelete(node);
                  }
                },
                itemBuilder: (context) => [
                  if (canAdd)
                    const PopupMenuItem(
                      value: 'add',
                      child: Text('Afegeix fill'),
                    ),
                  const PopupMenuItem(value: 'edit', child: Text('Edita')),
                  const PopupMenuItem(value: 'delete', child: Text('Esborra')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelsView extends StatelessWidget {
  const _LevelsView({required this.plant});

  final Plant plant;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final level in FunctionalLevel.values) ...[
            _LevelSection(plant: plant, level: level),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _LevelSection extends StatelessWidget {
  const _LevelSection({required this.plant, required this.level});

  final Plant plant;
  final FunctionalLevel level;

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(functionalLevelColorHex(level));
    final nodes = nodesAtFunctionalLevel(plant, level);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${level.value} - ${functionalLevelLabel(level)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (nodes.isEmpty)
              const Text('Cap node en aquest nivell.')
            else
              for (final node in nodes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${nodePath(plant, node.id)} · ${plantNodeKindLabel(node.kind)}',
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.level});

  final FunctionalLevel level;

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(functionalLevelColorHex(level));
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        '${level.value} ${functionalLevelLabel(level)}',
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

Color colorFromHex(String hex) {
  final normalized = hex.replaceFirst('#', '');
  return Color(int.parse(normalized, radix: 16) + 0xFF000000);
}
