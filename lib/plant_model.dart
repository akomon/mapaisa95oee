// Model pur del mapa ISA-95. Sense dependències de Flutter.
// Jerarquia, validacions i JSON: specs/02-mapa-isa95/spec.md.

import 'dart:convert' show JsonEncoder, jsonDecode;

enum PlantNodeKind { enterprise, site, area, line, cell }

enum FunctionalLevel {
  process,
  sensing,
  control,
  mes,
  erp;

  int get value => index;

  static FunctionalLevel? fromValue(int value) {
    if (value < 0 || value >= FunctionalLevel.values.length) {
      return null;
    }
    return FunctionalLevel.values[value];
  }
}

enum PlantIssueCode {
  emptyName,
  invalidFunctionalLevel,
  invalidKind,
  hierarchyViolation,
  duplicateId,
  nodeNotFound,
  invalidJson,
}

class PlantNode {
  const PlantNode({
    required this.id,
    required this.name,
    required this.kind,
    required this.functionalLevel,
    this.description,
    this.children = const [],
  });

  final String id;
  final String name;
  final String? description;
  final PlantNodeKind kind;
  final FunctionalLevel functionalLevel;
  final List<PlantNode> children;

  PlantNode copyWith({
    String? id,
    String? name,
    String? description,
    bool clearDescription = false,
    PlantNodeKind? kind,
    FunctionalLevel? functionalLevel,
    List<PlantNode>? children,
  }) {
    return PlantNode(
      id: id ?? this.id,
      name: name ?? this.name,
      description: clearDescription ? null : (description ?? this.description),
      kind: kind ?? this.kind,
      functionalLevel: functionalLevel ?? this.functionalLevel,
      children: children ?? this.children,
    );
  }
}

class Plant {
  const Plant({required this.roots, required this.nextIdCounter});

  final List<PlantNode> roots;
  final int nextIdCounter;

  Plant copyWith({List<PlantNode>? roots, int? nextIdCounter}) {
    return Plant(
      roots: roots ?? this.roots,
      nextIdCounter: nextIdCounter ?? this.nextIdCounter,
    );
  }
}

class PlantMutation {
  const PlantMutation.success(this.plant) : issues = const [];

  const PlantMutation.failure(this.issues) : plant = null;

  final Plant? plant;
  final List<PlantIssueCode> issues;

  bool get isValid => plant != null;
}

typedef PlantImport = PlantMutation;

Plant createEmptyPlant() => const Plant(roots: [], nextIdCounter: 1);

Plant foodPlantExample() {
  return Plant(
    nextIdCounter: 12,
    roots: [
      PlantNode(
        id: 'n1',
        name: 'Alimentària Demo',
        description: 'Grup alimentari d\'exemple per a cursos.',
        kind: PlantNodeKind.enterprise,
        functionalLevel: FunctionalLevel.erp,
        children: [
          PlantNode(
            id: 'n2',
            name: 'Planta Girona',
            kind: PlantNodeKind.site,
            functionalLevel: FunctionalLevel.mes,
            children: [
              PlantNode(
                id: 'n3',
                name: 'Envasat',
                kind: PlantNodeKind.area,
                functionalLevel: FunctionalLevel.control,
                children: [
                  PlantNode(
                    id: 'n4',
                    name: 'Línia iogurt',
                    kind: PlantNodeKind.line,
                    functionalLevel: FunctionalLevel.control,
                    children: const [
                      PlantNode(
                        id: 'n5',
                        name: 'Omplidora',
                        kind: PlantNodeKind.cell,
                        functionalLevel: FunctionalLevel.sensing,
                      ),
                      PlantNode(
                        id: 'n6',
                        name: 'Taponadora',
                        kind: PlantNodeKind.cell,
                        functionalLevel: FunctionalLevel.sensing,
                      ),
                    ],
                  ),
                  const PlantNode(
                    id: 'n7',
                    name: 'Línia formatge',
                    kind: PlantNodeKind.line,
                    functionalLevel: FunctionalLevel.control,
                    children: [
                      PlantNode(
                        id: 'n8',
                        name: 'Premsadora',
                        kind: PlantNodeKind.cell,
                        functionalLevel: FunctionalLevel.sensing,
                      ),
                    ],
                  ),
                ],
              ),
              const PlantNode(
                id: 'n9',
                name: 'Emmagatzematge',
                kind: PlantNodeKind.area,
                functionalLevel: FunctionalLevel.control,
                children: [
                  PlantNode(
                    id: 'n10',
                    name: 'Cambra freda',
                    kind: PlantNodeKind.line,
                    functionalLevel: FunctionalLevel.sensing,
                    children: [
                      PlantNode(
                        id: 'n11',
                        name: 'Sensor temperatura',
                        kind: PlantNodeKind.cell,
                        functionalLevel: FunctionalLevel.process,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

PlantNodeKind? allowedChildKind(PlantNodeKind parent) {
  switch (parent) {
    case PlantNodeKind.enterprise:
      return PlantNodeKind.site;
    case PlantNodeKind.site:
      return PlantNodeKind.area;
    case PlantNodeKind.area:
      return PlantNodeKind.line;
    case PlantNodeKind.line:
      return PlantNodeKind.cell;
    case PlantNodeKind.cell:
      return null;
  }
}

String plantNodeKindLabel(PlantNodeKind kind) {
  switch (kind) {
    case PlantNodeKind.enterprise:
      return 'Empresa';
    case PlantNodeKind.site:
      return 'Lloc';
    case PlantNodeKind.area:
      return 'Àrea';
    case PlantNodeKind.line:
      return 'Línia';
    case PlantNodeKind.cell:
      return 'Cel·la';
  }
}

String functionalLevelLabel(FunctionalLevel level) {
  switch (level) {
    case FunctionalLevel.process:
      return 'Procés';
    case FunctionalLevel.sensing:
      return 'Sensors';
    case FunctionalLevel.control:
      return 'Control';
    case FunctionalLevel.mes:
      return 'MES';
    case FunctionalLevel.erp:
      return 'ERP';
  }
}

String functionalLevelColorHex(FunctionalLevel level) {
  switch (level) {
    case FunctionalLevel.process:
      return '#5C6B73';
    case FunctionalLevel.sensing:
      return '#2A9D8F';
    case FunctionalLevel.control:
      return '#E9C46A';
    case FunctionalLevel.mes:
      return '#F4A261';
    case FunctionalLevel.erp:
      return '#E76F51';
  }
}

String plantIssueMessage(PlantIssueCode code) {
  switch (code) {
    case PlantIssueCode.emptyName:
      return 'El nom no pot ser buit.';
    case PlantIssueCode.invalidFunctionalLevel:
      return 'El nivell funcional ha de ser entre 0 i 4.';
    case PlantIssueCode.invalidKind:
      return 'Tipus de node desconegut.';
    case PlantIssueCode.hierarchyViolation:
      return 'La jerarquia ISA-95 no es respecta.';
    case PlantIssueCode.duplicateId:
      return 'Hi ha identificadors duplicats.';
    case PlantIssueCode.nodeNotFound:
      return 'No s\'ha trobat el node.';
    case PlantIssueCode.invalidJson:
      return 'El fitxer JSON no és vàlid.';
  }
}

String kindToJsonName(PlantNodeKind kind) => kind.name;

PlantNodeKind? kindFromJsonName(String raw) {
  for (final kind in PlantNodeKind.values) {
    if (kind.name == raw) {
      return kind;
    }
  }
  return null;
}

String? _normalizeDescription(String? description) {
  if (description == null) {
    return null;
  }
  final trimmed = description.trim();
  return trimmed.isEmpty ? null : trimmed;
}

List<String> collectIds(Plant plant) {
  final ids = <String>[];
  void walk(PlantNode node) {
    ids.add(node.id);
    for (final child in node.children) {
      walk(child);
    }
  }

  for (final root in plant.roots) {
    walk(root);
  }
  return ids;
}

PlantNode? findNode(Plant plant, String id) {
  PlantNode? walk(PlantNode node) {
    if (node.id == id) {
      return node;
    }
    for (final child in node.children) {
      final found = walk(child);
      if (found != null) {
        return found;
      }
    }
    return null;
  }

  for (final root in plant.roots) {
    final found = walk(root);
    if (found != null) {
      return found;
    }
  }
  return null;
}

bool nodeHasChildren(Plant plant, String id) {
  final node = findNode(plant, id);
  return node != null && node.children.isNotEmpty;
}

/// Camí de noms des de l'arrel fins al node, separat per ` / `.
String? nodePath(Plant plant, String id) {
  List<String>? walk(PlantNode node, List<String> prefix) {
    final current = [...prefix, node.name];
    if (node.id == id) {
      return current;
    }
    for (final child in node.children) {
      final found = walk(child, current);
      if (found != null) {
        return found;
      }
    }
    return null;
  }

  for (final root in plant.roots) {
    final found = walk(root, const []);
    if (found != null) {
      return found.join(' / ');
    }
  }
  return null;
}

List<PlantNode> nodesAtFunctionalLevel(Plant plant, FunctionalLevel level) {
  final result = <PlantNode>[];
  void walk(PlantNode node) {
    if (node.functionalLevel == level) {
      result.add(node);
    }
    for (final child in node.children) {
      walk(child);
    }
  }

  for (final root in plant.roots) {
    walk(root);
  }
  return result;
}

PlantMutation addChild(
  Plant plant, {
  String? parentId,
  required String name,
  String? description,
  required PlantNodeKind kind,
  required FunctionalLevel functionalLevel,
}) {
  final issues = <PlantIssueCode>[];
  final trimmedName = name.trim();
  if (trimmedName.isEmpty) {
    issues.add(PlantIssueCode.emptyName);
  }

  if (parentId == null) {
    if (kind != PlantNodeKind.enterprise) {
      issues.add(PlantIssueCode.hierarchyViolation);
    }
  } else {
    final parent = findNode(plant, parentId);
    if (parent == null) {
      issues.add(PlantIssueCode.nodeNotFound);
    } else if (allowedChildKind(parent.kind) != kind) {
      issues.add(PlantIssueCode.hierarchyViolation);
    }
  }

  if (issues.isNotEmpty) {
    return PlantMutation.failure(issues);
  }

  final id = 'n${plant.nextIdCounter}';
  final node = PlantNode(
    id: id,
    name: trimmedName,
    description: _normalizeDescription(description),
    kind: kind,
    functionalLevel: functionalLevel,
  );

  if (parentId == null) {
    return PlantMutation.success(
      plant.copyWith(
        roots: [...plant.roots, node],
        nextIdCounter: plant.nextIdCounter + 1,
      ),
    );
  }

  List<PlantNode> mapNodes(List<PlantNode> nodes) {
    return [
      for (final n in nodes)
        if (n.id == parentId)
          n.copyWith(children: [...n.children, node])
        else
          n.copyWith(children: mapNodes(n.children)),
    ];
  }

  return PlantMutation.success(
    plant.copyWith(
      roots: mapNodes(plant.roots),
      nextIdCounter: plant.nextIdCounter + 1,
    ),
  );
}

PlantMutation updateNode(
  Plant plant, {
  required String id,
  required String name,
  String? description,
  required FunctionalLevel functionalLevel,
}) {
  final issues = <PlantIssueCode>[];
  final trimmedName = name.trim();
  if (trimmedName.isEmpty) {
    issues.add(PlantIssueCode.emptyName);
  }
  if (findNode(plant, id) == null) {
    issues.add(PlantIssueCode.nodeNotFound);
  }
  if (issues.isNotEmpty) {
    return PlantMutation.failure(issues);
  }

  final normalized = _normalizeDescription(description);

  List<PlantNode> mapNodes(List<PlantNode> nodes) {
    return [
      for (final n in nodes)
        if (n.id == id)
          n.copyWith(
            name: trimmedName,
            description: normalized,
            clearDescription: normalized == null,
            functionalLevel: functionalLevel,
          )
        else
          n.copyWith(children: mapNodes(n.children)),
    ];
  }

  return PlantMutation.success(plant.copyWith(roots: mapNodes(plant.roots)));
}

PlantMutation removeNode(Plant plant, {required String id}) {
  if (findNode(plant, id) == null) {
    return const PlantMutation.failure([PlantIssueCode.nodeNotFound]);
  }

  List<PlantNode> filterNodes(List<PlantNode> nodes) {
    return [
      for (final n in nodes)
        if (n.id != id) n.copyWith(children: filterNodes(n.children)),
    ];
  }

  return PlantMutation.success(plant.copyWith(roots: filterNodes(plant.roots)));
}

Map<String, Object?> _nodeToJson(PlantNode node) {
  return {
    'id': node.id,
    'name': node.name,
    'description': node.description,
    'kind': kindToJsonName(node.kind),
    'functionalLevel': node.functionalLevel.value,
    'children': [for (final child in node.children) _nodeToJson(child)],
  };
}

String plantToJson(Plant plant) {
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert({
    'version': 1,
    'nodes': [for (final root in plant.roots) _nodeToJson(root)],
  });
}

PlantImport plantFromJson(String raw) {
  late final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    return const PlantImport.failure([PlantIssueCode.invalidJson]);
  }

  if (decoded is! Map) {
    return const PlantImport.failure([PlantIssueCode.invalidJson]);
  }

  final map = Map<String, dynamic>.from(decoded);
  if (map['version'] != 1 || map['nodes'] is! List) {
    return const PlantImport.failure([PlantIssueCode.invalidJson]);
  }

  final issues = <PlantIssueCode>{};
  final seenIds = <String>{};
  var maxCounter = 0;

  int? parseIdCounter(String id) {
    if (!id.startsWith('n')) {
      return null;
    }
    return int.tryParse(id.substring(1));
  }

  PlantNode? parseNode(Object? rawNode, PlantNodeKind? expectedKind) {
    if (rawNode is! Map) {
      issues.add(PlantIssueCode.invalidJson);
      return null;
    }
    final nodeMap = Map<String, dynamic>.from(rawNode);
    final id = nodeMap['id'];
    final name = nodeMap['name'];
    final kindRaw = nodeMap['kind'];
    final levelRaw = nodeMap['functionalLevel'];
    final childrenRaw = nodeMap['children'];
    final descriptionRaw = nodeMap['description'];

    if (id is! String || id.isEmpty || name is! String) {
      issues.add(PlantIssueCode.invalidJson);
      return null;
    }
    if (kindRaw is! String) {
      issues.add(PlantIssueCode.invalidJson);
      return null;
    }
    final kind = kindFromJsonName(kindRaw);
    if (kind == null) {
      issues.add(PlantIssueCode.invalidKind);
      return null;
    }
    if (expectedKind != null && kind != expectedKind) {
      issues.add(PlantIssueCode.hierarchyViolation);
    }
    if (expectedKind == null && kind != PlantNodeKind.enterprise) {
      issues.add(PlantIssueCode.hierarchyViolation);
    }
    if (levelRaw is! int) {
      issues.add(PlantIssueCode.invalidJson);
      return null;
    }
    final level = FunctionalLevel.fromValue(levelRaw);
    if (level == null) {
      issues.add(PlantIssueCode.invalidFunctionalLevel);
      return null;
    }
    if (name.trim().isEmpty) {
      issues.add(PlantIssueCode.emptyName);
    }
    if (!seenIds.add(id)) {
      issues.add(PlantIssueCode.duplicateId);
    }
    final parsed = parseIdCounter(id);
    if (parsed != null && parsed > maxCounter) {
      maxCounter = parsed;
    }

    String? description;
    if (descriptionRaw == null) {
      description = null;
    } else if (descriptionRaw is String) {
      description = _normalizeDescription(descriptionRaw);
    } else {
      issues.add(PlantIssueCode.invalidJson);
      return null;
    }

    if (childrenRaw is! List) {
      issues.add(PlantIssueCode.invalidJson);
      return null;
    }

    final allowed = allowedChildKind(kind);
    final children = <PlantNode>[];
    for (final childRaw in childrenRaw) {
      if (allowed == null) {
        issues.add(PlantIssueCode.hierarchyViolation);
        parseNode(childRaw, PlantNodeKind.cell);
        continue;
      }
      final child = parseNode(childRaw, allowed);
      if (child != null) {
        children.add(child);
      }
    }

    return PlantNode(
      id: id,
      name: name.trim().isEmpty ? name : name.trim(),
      description: description,
      kind: kind,
      functionalLevel: level,
      children: children,
    );
  }

  final roots = <PlantNode>[];
  for (final rawNode in map['nodes'] as List) {
    final node = parseNode(rawNode, null);
    if (node != null) {
      roots.add(node);
    }
  }

  if (issues.isNotEmpty) {
    final ordered = PlantIssueCode.values
        .where(issues.contains)
        .toList(growable: false);
    return PlantImport.failure(ordered);
  }

  return PlantImport.success(
    Plant(roots: roots, nextIdCounter: maxCounter + 1),
  );
}
