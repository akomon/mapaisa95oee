# Pla: fonament del replantejament (PR A)

Spec: [spec.md](spec.md). Tasques: [tasks.md](tasks.md).

Aquesta PR és només la PR A de la secció 10 de la spec. El codi es commita després d'aquesta spec.

## Enfocament

El model nou viu a part del mapa ISA-95 antic. No es reescriu `lib/plant_model.dart` ni el calculador. La pantalla nova llegeix i escriu IndexedDB. El mapa antic continua llegint i escrivint `mapaisa95oee.plant.v1`.

La migració és una funció pura sobre una còpia del text llegat. El repositori només té un lector d'aquella clau. No rep un escriptor. IndexedDB s'escriu quan el resultat de la còpia és vàlid. Si no ho és, no hi ha document `workspace` i l'estat visible és d'error.

La substitució d'una còpia nova es valida sencera abans de la transacció. La transacció escriu el document nou i conserva la còpia prèvia. Si llença, el repositori es queda amb el document anterior i no mostra `Desat`.

## Estructura

```
lib/workspace_model.dart           # entitats, operacions, fixture
lib/workspace_codec.dart           # còpia formatVersion 1
lib/legacy_migration.dart          # projecció no destructiva
lib/workspace_database.dart        # contracte del magatzem
lib/workspace_database_memory.dart # memòria, amb fallada injectable
lib/workspace_idb.dart             # IndexedDB via idb_shim
lib/workspace_idb_factory.dart     # navegador o memòria segons la plataforma
lib/workspace_repository.dart      # estat de desament, migració, substitució
lib/data_foundation_page.dart      # pantalla Dades locals
lib/legacy_key_probe.dart          # lectura, sense escriptura, de la clau web
lib/main.dart                      # enllaç; el calculador i el mapa es conserven
test/workspace_model_test.dart
test/workspace_codec_test.dart
test/legacy_migration_test.dart
test/workspace_repository_test.dart
test/data_foundation_page_test.dart
```

Dependència nova: `idb_shim`. La implementació de navegador és la fàbrica IndexedDB del paquet. Els tests de VM usen la fàbrica en memòria del mateix paquet i la base falsa que pot fallar abans d'escriure. `shared_preferences` es conserva per al mapa antic.

`plant_io.dart` es reutilitza per triar i descarregar fitxers. No es duplica l'accés al DOM.

## Decisions d'aquesta PR

- Un sol document JSON per al workspace, clau `workspace`, transacció única.
- La còpia descarregada i el document desat comparteixen `formatVersion` 1.
- AC-01, AC-02 i AC-03 es proven al model. La pantalla no és l'inventari.
- AC-08, AC-09, AC-10 i AC-19 es proven al repositori, al codec i a la pantalla.
- AC-11 i R2, R4 i R5 no s'implementen. Els tipus de snapshot i de registre OEE existeixen perquè la còpia no els perdi i perquè un canvi de mestre no els muti.
- La fixture nova no substitueix `foodPlantExample()`.

## Verificació

```
flutter analyze
flutter test
flutter build web
```

Després, servir el build web i comprovar al navegador la clau legacy, la recàrrega, la còpia invàlida, la cancel·lació, la fixture i el calculador. Les captures queden amb la PR. La fallada de transacció es força a la base en memòria; el build de release no porta un botó per simular-la.

## Riscos

- El mapa antic i IndexedDB poden divergir després de la migració. La clau legacy no es toca i la còpia capturada es pot tornar a descarregar.
- `idb_shim` en memòria no és Chrome. La recàrrega real es comprova al navegador.
- El calculador US-1 i les fórmules de la secció 5 conviuen fins a la PR D. No s'han d'unificar aquí.
- Una quota esgotada depèn del navegador. El repositori tracta qualsevol excepció d'escriptura com a error i no marca `Desat`.
