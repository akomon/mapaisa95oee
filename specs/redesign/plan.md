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

El pla de la PR D és [phase-d.md](phase-d.md), secció 15.

# Pla: espai de treball (PR B)

Spec: [spec.md](spec.md), secció 13. Tasques: [tasks.md](tasks.md).

Aquesta PR és només la PR B. El codi es commita després d'aquesta actualització de la spec. No es implementen les PR C, D ni E.

## Enfocament

L'espai nou llegeix i escriu el workspace canònic a través del repositori. No es reutilitza `functionalLevel` ni la pantalla del mapa antic com a editor. `PlantMapPage` es conserva al repositori perquè les proves de la US-2 continuïn, però `main.dart` no la munta quan hi ha repositori.

En obrir, si la clau legacy difereix del text ja reconciliat, `reconcileLegacyWorkspace` fusiona només la jerarquia física sobre una còpia. Les instantànies i l'OEE es passen per referència. La clau legacy no es rep cap escriptor.

Les operacions noves de domini que la UI necessita, i que la PR A no exposava senceres, són `updateSystem`, `updateFlow` i `linkToSchema`. No creen esquemes addicionals ni versions.

## Estructura

```
lib/legacy_reconciliation.dart   # fusió pura, sense Flutter
lib/workspace_theme.dart          # antracita, acer, objectius de 48 dp
lib/workspace_page.dart           # arbre, mapa, inspector, barra
test/legacy_reconciliation_test.dart
test/workspace_page_test.dart
```

Es toquen també el model, el codec, el repositori, `main.dart` i el text de `Dades locals` que encara deia que el mapa antic no actualitza el model.

## Decisions d'aquesta PR

- Un sol editor: el workspace. La clau legacy només es llegeix.
- `formatVersion` es manté en 1. `latestLegacyRaw` i `reconciledLegacyRaw` són opcionals.
- L'esquema actiu, si ja existeix, rep les altes. No hi ha gestor de plantilles ni de restauració.
- El calculador US-1 no es modifica. L'inspector hi enllaça i no inventa percentatges.
- La maqueta fixa la composició i la paleta. No fixa noms, nivells ni dades.

## Verificació

```
flutter analyze
flutter test
flutter build web
```

Després, Chrome real a 1280 × 800 i a 360 px: densitat, flux manual, teclat, desar i recarregar, legacy divergent i clau tardana, còpia coherent, i el calculador US-1. La quota real del navegador només es reporta si es reprodueix. La fallada de quota continua coberta per la base en memòria.

## Riscos

- Una fusió amb conflicte conserva el canònic i el text cru. L'usuari ha de descarregar-lo per veure el detall no aplicat.
- El mapa antic, si algú el construeix fora de `main.dart`, encara escriuria la clau. L'obertura següent el tornaria a reconciliar.
- La maqueta mostra un pastís OEE i etiquetes de nivell que aquesta PR no ha de copiar.
