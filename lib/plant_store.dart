import 'plant_model.dart';

const String plantStorageKey = 'mapaisa95oee.plant.v1';

/// Emmagatzematge injectable de la planta (navegador o memòria de test).
abstract class PlantStore {
  Future<Plant> load();

  Future<void> save(Plant plant);
}

class MemoryPlantStore implements PlantStore {
  MemoryPlantStore([Plant? initial])
    : _json = initial == null ? null : plantToJson(initial);

  String? _json;

  String? get rawJson => _json;

  @override
  Future<Plant> load() async {
    final raw = _json;
    if (raw == null) {
      return createEmptyPlant();
    }
    final imported = plantFromJson(raw);
    return imported.plant ?? createEmptyPlant();
  }

  @override
  Future<void> save(Plant plant) async {
    _json = plantToJson(plant);
  }
}

typedef PreferencesReader = Future<String?> Function(String key);
typedef PreferencesWriter = Future<void> Function(String key, String value);

/// Store basat en SharedPreferences (o qualsevol parell get/set de cadena).
class PreferencesPlantStore implements PlantStore {
  const PreferencesPlantStore({
    required this.read,
    required this.write,
  });

  final PreferencesReader read;
  final PreferencesWriter write;

  @override
  Future<Plant> load() async {
    final raw = await read(plantStorageKey);
    if (raw == null || raw.isEmpty) {
      return createEmptyPlant();
    }
    final imported = plantFromJson(raw);
    return imported.plant ?? createEmptyPlant();
  }

  @override
  Future<void> save(Plant plant) async {
    await write(plantStorageKey, plantToJson(plant));
  }
}
