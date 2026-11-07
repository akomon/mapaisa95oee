import 'package:flutter_test/flutter_test.dart';
import 'package:mapaisa95oee/plant_model.dart';

void main() {
  test('alta vàlida d\'empresa i lloc', () {
    var plant = createEmptyPlant();
    final enterprise = addChild(
      plant,
      name: 'Acme',
      kind: PlantNodeKind.enterprise,
      functionalLevel: FunctionalLevel.erp,
    );
    expect(enterprise.isValid, isTrue);
    plant = enterprise.plant!;
    expect(plant.roots, hasLength(1));
    expect(plant.roots.first.id, 'n1');
    expect(plant.roots.first.name, 'Acme');

    final site = addChild(
      plant,
      parentId: 'n1',
      name: 'Girona',
      kind: PlantNodeKind.site,
      functionalLevel: FunctionalLevel.mes,
    );
    expect(site.isValid, isTrue);
    expect(site.plant!.roots.first.children.single.name, 'Girona');
    expect(site.plant!.roots.first.children.single.id, 'n2');
  });

  test('nom buit només emptyName i planta intacta', () {
    final plant = createEmptyPlant();
    final mutation = addChild(
      plant,
      name: '   ',
      kind: PlantNodeKind.enterprise,
      functionalLevel: FunctionalLevel.erp,
    );
    expect(mutation.plant, isNull);
    expect(mutation.issues, [PlantIssueCode.emptyName]);
    expect(plantIssueMessage(PlantIssueCode.emptyName), 'El nom no pot ser buit.');
  });

  test('jerarquia: area sota enterprise és violation', () {
    final withEnterprise = addChild(
      createEmptyPlant(),
      name: 'Acme',
      kind: PlantNodeKind.enterprise,
      functionalLevel: FunctionalLevel.erp,
    ).plant!;
    final mutation = addChild(
      withEnterprise,
      parentId: 'n1',
      name: 'Envasat',
      kind: PlantNodeKind.area,
      functionalLevel: FunctionalLevel.control,
    );
    expect(mutation.issues, [PlantIssueCode.hierarchyViolation]);
  });

  test('jerarquia: enterprise sota lloc és violation', () {
    final example = foodPlantExample();
    final mutation = addChild(
      example,
      parentId: 'n2',
      name: 'Altra',
      kind: PlantNodeKind.enterprise,
      functionalLevel: FunctionalLevel.erp,
    );
    expect(mutation.issues, [PlantIssueCode.hierarchyViolation]);
  });

  test('esborrat recursiu de línia iogurt', () {
    final example = foodPlantExample();
    expect(nodeHasChildren(example, 'n4'), isTrue);
    final mutation = removeNode(example, id: 'n4');
    expect(mutation.isValid, isTrue);
    final plant = mutation.plant!;
    expect(findNode(plant, 'n4'), isNull);
    expect(findNode(plant, 'n5'), isNull);
    expect(findNode(plant, 'n6'), isNull);
    expect(findNode(plant, 'n7'), isNotNull);
  });

  test('foodPlantExample té els ids i nivells de la spec', () {
    final plant = foodPlantExample();
    expect(collectIds(plant), [
      'n1',
      'n2',
      'n3',
      'n4',
      'n5',
      'n6',
      'n7',
      'n8',
      'n9',
      'n10',
      'n11',
    ]);
    expect(findNode(plant, 'n1')!.functionalLevel, FunctionalLevel.erp);
    expect(findNode(plant, 'n11')!.functionalLevel, FunctionalLevel.process);
    expect(findNode(plant, 'n1')!.description, 'Grup alimentari d\'exemple per a cursos.');
    expect(plant.nextIdCounter, 12);
  });

  test('round-trip JSON de l\'exemple', () {
    final original = foodPlantExample();
    final raw = plantToJson(original);
    final imported = plantFromJson(raw);
    expect(imported.issues, isEmpty);
    final plant = imported.plant!;
    expect(collectIds(plant), collectIds(original));
    expect(findNode(plant, 'n5')!.name, 'Omplidora');
    expect(findNode(plant, 'n10')!.functionalLevel, FunctionalLevel.sensing);
    expect(plant.nextIdCounter, 12);
  });

  test('JSON invàlid', () {
    expect(plantFromJson('{"version":1}').issues, [PlantIssueCode.invalidJson]);
    expect(plantFromJson('<html>').issues, [PlantIssueCode.invalidJson]);
    expect(
      plantIssueMessage(PlantIssueCode.invalidJson),
      'El fitxer JSON no és vàlid.',
    );
  });

  test('ids duplicats en import', () {
    const raw = '''
{
  "version": 1,
  "nodes": [
    {
      "id": "n1",
      "name": "A",
      "description": null,
      "kind": "enterprise",
      "functionalLevel": 4,
      "children": [
        {
          "id": "n1",
          "name": "B",
          "description": null,
          "kind": "site",
          "functionalLevel": 3,
          "children": []
        }
      ]
    }
  ]
}
''';
    final imported = plantFromJson(raw);
    expect(imported.plant, isNull);
    expect(imported.issues, contains(PlantIssueCode.duplicateId));
  });

  test('updateNode i nodeNotFound', () {
    final plant = foodPlantExample();
    final ok = updateNode(
      plant,
      id: 'n5',
      name: 'Omplidora 2',
      description: 'Nova',
      functionalLevel: FunctionalLevel.control,
    );
    expect(ok.isValid, isTrue);
    expect(findNode(ok.plant!, 'n5')!.name, 'Omplidora 2');
    expect(findNode(ok.plant!, 'n5')!.description, 'Nova');

    final missing = updateNode(
      plant,
      id: 'n999',
      name: 'X',
      functionalLevel: FunctionalLevel.process,
    );
    expect(missing.issues, [PlantIssueCode.nodeNotFound]);
  });

  test('etiquetes i colors de la spec', () {
    expect(plantNodeKindLabel(PlantNodeKind.area), 'Àrea');
    expect(functionalLevelLabel(FunctionalLevel.sensing), 'Sensors');
    expect(functionalLevelColorHex(FunctionalLevel.process), '#5C6B73');
    expect(functionalLevelColorHex(FunctionalLevel.erp), '#E76F51');
    expect(nodePath(foodPlantExample(), 'n5'), 'Alimentària Demo / Planta Girona / Envasat / Línia iogurt / Omplidora');
  });
}
