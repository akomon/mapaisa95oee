# Pla: Mapa ISA-95

Spec: [spec.md](spec.md). Tasques: [tasks.md](tasks.md).

## Enfocament

Ampliar l'app Flutter Web existent. El model i les validacions viuen a `lib/plant_model.dart` sense importar Flutter. La UI (`plant_map_page.dart`) edita, mostra arbre/nivells i dispara persistència i JSON. El calculador OEE es manté; `main.dart` afegeix navegació entre pantalles.

La implementació es commita només després d'aquesta spec.

## Estructura

```
lib/plant_model.dart          # jerarquia, validacions, JSON, exemple
lib/plant_store.dart          # abstracció + store SharedPreferences / memòria
lib/plant_map_page.dart       # arbre, nivells, CRUD, import/export
lib/main.dart                 # tema, rutes o navegació OEE ↔ mapa
lib/oee_form.dart             # enllaç a Mapa ISA-95 a l'AppBar
test/plant_model_test.dart    # jerarquia, CRUD, JSON, exemple
test/plant_store_test.dart    # round-trip en memòria
test/plant_map_page_test.dart # arbre, confirmació, 360 px (smoke)
```

Dependència nova: `shared_preferences` per a la clau `mapaisa95oee.plant.v1` al navegador.

Exportació web: genera el JSON i el descarrega com a fitxer `planta-isa95.json` via `AnchorElement` / APIs web. Importació: selector de fitxer (input file) que llegeix el text i crida `plantFromJson`.

## Decisions tancades per la spec

- Jerarquia estricte empresa → lloc → àrea → línia → cel·la; arrels només empresa.
- Nivell funcional 0–4 independent del tipus; colors fixos.
- Esborrat recursiu al model; confirmació només a la UI si hi ha fills.
- JSON `version: 1` + `nodes`; ids estables a l'exemple.
- Store injectable: producció amb SharedPreferences, tests amb memòria.
- Contingut max 640 px; prova de 360 px sense overflow.

## Verificació

```
flutter analyze
flutter test
```

`flutter analyze` sense issues. `flutter test` cobreix model, store i smoke de UI (exemple carregable, diàleg d'esborrat, 360 px).

## Riscos coneguts

- L'API de descàrrega/selecció de fitxer a web és diferent del test de widget; els tests cobreixen el parseig JSON, no el diàleg natiu del navegador.
- Si SharedPreferences falla en runtime, la UI arrenca amb planta buida.
- Fora d'abast: PDF i OEE per línia (US-3).
