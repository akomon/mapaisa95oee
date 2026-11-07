import 'package:flutter_test/flutter_test.dart';
import 'package:mapaisa95oee/plant_model.dart';
import 'package:mapaisa95oee/plant_store.dart';

void main() {
  test('MemoryPlantStore round-trip', () async {
    final store = MemoryPlantStore();
    final empty = await store.load();
    expect(empty.roots, isEmpty);

    await store.save(foodPlantExample());
    final loaded = await store.load();
    expect(collectIds(loaded), collectIds(foodPlantExample()));
    expect(store.rawJson, contains('Alimentària Demo'));
  });

  test('PreferencesPlantStore usa la clau de la spec', () async {
    final memory = <String, String>{};
    final store = PreferencesPlantStore(
      read: (key) async => memory[key],
      write: (key, value) async {
        memory[key] = value;
      },
    );

    await store.save(foodPlantExample());
    expect(memory.keys, [plantStorageKey]);
    final loaded = await store.load();
    expect(findNode(loaded, 'n1')!.name, 'Alimentària Demo');
  });

  test('load amb JSON invàlid torna planta buida', () async {
    final store = PreferencesPlantStore(
      read: (key) async => '{bad',
      write: (key, value) async {},
    );
    final loaded = await store.load();
    expect(loaded.roots, isEmpty);
  });
}
