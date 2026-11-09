# Secció 16 — PR E: històric OEE contextual i filtres

Font: [spec.md](spec.md), seccions 2, 5 i 8, i la font aprovada. Aquesta secció no afegeix requisits ni reobre la secció 8, la secció 14 ni la secció 15. El fitxer és nou, com el de la PR D.

Aquesta PR és només la PR E. Depèn de B i D, ja a `main`. Es reutilitza el motor de `lib/oee_engine.dart`. No es comença la QA integrada d'R6.

## 16.1 Què es tanca i què es deixa

| AC | PR E |
| --- | --- |
| AC-16 | Tancat. Es desa un registre amb data de producció, torn, línia, article, lot opcional, dades originals i `c` congelat. Reanomenar la línia no modifica el resultat ni les etiquetes capturades. Un càlcul posterior amb una altra velocitat no reescriu el registre ja desat. |
| AC-17 | Tancat. Es consulta i es filtra per dates, torn, línia, article i lot. Obrir un registre mostra les entrades, l'estat, els quatre indicadors i, si el motor el considera vàlid, el pastís. Sense lot es pot desar i filtrar. |
| AC-18 | Tancat. Es distingeix esborrany i validat per text. L'històric de validats exclou els esborranys per defecte. Es mostren indicadors per registre. No hi ha mitjana de percentatges ni agregació de factors. |
| AC-01…AC-15, AC-19 | Es conserven. No es reobren. El calculador US-1 segueix al torn 480 min, 60 min, 60 s/unitat, 400 i 380, amb `OEE: 79.2 %`. |
| AC-11 | Es conserva. Restaurar una instantània no altera els registres OEE. |
| AC-20 | Parcial d'aquesta pantalla: 360 px sense overflow horitzontal, objectius de 48 dp, focus visible, teclat i textos. La passada integrada continua fora. |
| AC-21 | Parcial: anàlisi, tests, build web i Chrome real de l'abast E. |

Fora de la PR E: agregació, PDF, backend, catàleg d'articles, purga de versions, closca offline i la QA integrada d'R6. La SPEC sencera no queda tancada.

## 16.2 Registre

`formatVersion` continua sent 1. `replacesId` és opcional. Si la clau no hi és, val `null`. Les còpies de les PR A…D es continuen llegint. No es reescriuen els registres ja desats en obrir l'aplicació.

```json
{
  "id": "n50",
  "replacesId": null
}
```

Quan `replacesId` és `null`, l'exportació omet la clau. Un valor no nul és l'ID d'un altre registre OEE. No pot ser l'ID propi. La cadena no té cicles. Un ID inexistent és `orphanReference`. Això no és un camp nou de l'inventari: és la revisió de la decisió 5.

Desar des d'una línia viva captura, en aquell instant:

| Camp | Origen |
| --- | --- |
| `lineId` | ID de la línia. No canvia si la línia es reanomena. |
| `capturedLineName` | Nom de la línia en desar. |
| `capturedPlantName` | Nom de la planta avantpassada. Si la línia no en té, no es desa. |
| `productionDate` | `AAAA-MM-DD` real. No és `createdAt`. |
| `shift` | Text obligatori, després de `trim`. |
| `article` | Text obligatori, després de `trim`. Sense catàleg. |
| `lot` | Text després de `trim`, o `null` si queda buit. |
| `plannedMinutes`, `downtimeMinutes`, `speedOriginal`, `speedUnit` | Valors parsejats pel motor, no un text reformat. |
| `idealCycleSeconds` | `c` de l'outcome. No es torna a calcular en obrir ni en reanomenar. |
| `totalUnits`, `goodUnits` | Enters del motor. |
| `formulaVersion` | `oee.v1`. |
| `status` | `draft` o `validated`. |

`createdAt` i `updatedAt` són l'instant del repositori. En crear, coincideixen. En actualitzar un esborrany, `createdAt` es conserva.

El motor ha de retornar un resultat. Un error de camp, o producció amb temps operatiu zero, no escriu. Un esborrany es pot desar quan `allowsDraft`. Validar només si `allowsValidation`. Un rendiment superior a 1 no es capa, no es valida i no pinta pastís. El domini torna a comprovar-ho: la UI no és l'única barrera.

Un registre validat no es muta. Corregir-lo crea un registre nou, amb ID nou, `replacesId` de l'original i els valors nous. El JSON de l'original queda igual, inclosos el nom capturat, `c` i l'estat. Un esborrany sí que es pot actualitzar al mateix ID. Validar-lo canvia l'estat d'aquell ID. No es crea una revisió només per passar d'esborrany a validat.

La vista de validats mostra els registres `validated` que cap altre registre `validated` no cita a `replacesId`. Un esborrany que cita un validat no l'amaga. L'original es conserva i s'obre des de `Revisió anterior` a la revisió. No s'esborra en cascada si es treu la línia.

Missatges de l'operació, a part dels del motor:

| Cas | Missatge |
| --- | --- |
| Article buit | L'article és obligatori. |
| Torn buit | El torn és obligatori. |
| Data invàlida | La data de producció ha de ser AAAA-MM-DD. |
| Sense planta | Aquesta línia no té una planta. No es desa el registre. |
| Validat immutable | Un registre validat no es modifica. Corregir-lo crea una revisió. |
| No validable | No es pot validar aquest resultat. |
| Registre absent | No s'ha trobat el registre. |

## 16.3 Filtres i buits

La consulta és pura. No escriu. L'ordre és data de producció descendent i, a igual data, ID descendent.

| Filtre | Comportament |
| --- | --- |
| Dates | `Des de` i `Fins a`, inclusius, sobre `productionDate`. Buit vol dir sense límit. Un text no buit que no és una data real mostra l'error de la secció 16.2 i no es fa servir com si fos un interval obert. Si la inicial és posterior a la final: `La data inicial és posterior a la data final.` |
| Torn | Igualtat després de `trim`, sense distingir majúscules. Buit: tots. `Mat` no coincideix amb `Matí`. |
| Línia | Per `lineId`. Per defecte, la línia seleccionada. `Totes les línies` inclou les altres i les retirades. Reanomenar no treu el registre del filtre d'aquell ID. Una línia que ja no existeix es llista amb el nom capturat i el text `línia retirada`. |
| Article | Conté, després de `trim`, sense distingir majúscules. Buit: tots. |
| Lot | `Qualsevol lot` no filtra. `Sense lot` només els `null`. `Lot concret` amb text és igualtat després de `trim`, sense distingir majúscules; `L1` no coincideix amb `L10` ni amb un lot buit. Text buit en aquest mode: `Escriu el lot per filtrar.` i cap llista silenciosa. |
| Estat | `Validats` per defecte, sense esborranys. `Esborranys`. `Tots` mostra els dos, i continua amagant un validat ja substituït per una revisió validada. |

Textos de buit, no un zero inventat:

- `Encara no hi ha registres OEE.`
- `Cap registre amb aquests filtres.`

Sempre visible: `Indicadors per registre. Sense mitjana ni agregació.` No hi ha cap control ni cap xifra de conjunt.

Obrir un registre mostra les entrades originals, l'estat en text (`Esborrany` o `Validat`), els quatre indicadors i el pastís que el motor torni a calcular amb els doubles desats i el `c` congelat. No es llegeix una velocitat de la línia. Si el pastís no és vàlid, no es pinta. Si la línia s'ha reanomenat: `El nom actual de la línia és diferent. L'etiqueta històrica no canvia.` Si ja no hi és: `La línia ja no és a l'inventari. Es conserva el nom capturat.`

## 16.4 Pantalla

Textos en català. El tema és el de l'espai: antracita, acer, focus de 2 px, controls nous d'almenys 48 dp. A 360 px els filtres, el formulari i la llista són una columna dins de l'inspector, amb desplaçament vertical i sense overflow horitzontal. L'estat es llegeix pel text.

Seleccionar una línia manté l'arbre i el context. El panell de la línia alterna `Càlcul` i `Històric`. El mapa continua sent l'esquema. Per defecte es veu el càlcul, amb `Obre el calculador`. La pantalla `Càlcul OEE` sense línia no guanya botó de desar: allà el càlcul continua sense registre.

A la línia, el càlcul afegeix data, torn, article i lot, i els botons `Desa esborrany` i `Valida`. No escriuen sols. `Valida` queda inhabilitat si el motor no ho permet. Corregir un validat mostra `Correcció. El registre validat no es modifica.` Els botons passen a `Desa la revisió com a esborrany` i `Valida la revisió`.

`Històric OEE`, a la barra, obre el mateix històric. Si no hi ha línia seleccionada, l'inspector el mostra amb `Totes les línies`, perquè un registre d'una línia eliminada es pugui retrobar. La clau `mapaisa95oee.plant.v1` no es rep cap escriptor.

## 16.5 Què no es toca

`lib/oee_calculator.dart` i el resultat US-1. `formatVersion` 1. La base IndexedDB, el nom i la versió. Les instantànies. La migració i la reconciliació, que ja no muten l'OEE. El motor de fórmules, tret d'exposar els inputs ja parsejats perquè el registre guardi els doubles originals. Els fitxers de plantilles i de suggeriments, fora del punt de la línia a `workspace_page.dart`.

## 16.6 Verificació

```
flutter analyze
flutter test
flutter build web
```

Tests d'AC-16, AC-17 i AC-18: lot buit, dates inclusives i creuades, data invàlida, torn i lot exactes, article parcial, esborrany fora de la vista per defecte, rendiment superior a 1, línia reanomenada, línia eliminada, revisió que no muta l'original, recàrrega, còpia rodona i restauració sense canviar l'OEE. Cap agregació.

Chrome real a 1280 × 800 i a 360 px: desar el torn de referència de la secció 5 des de la línia, veure `79.166667 %` a l'històric, filtrar, obrir el registre amb el pastís, i el calculador US-1 encara a `79.2 %`.

# Pla: històric OEE (PR E)

Spec: [phase-e.md](phase-e.md), secció 16. El codi es commita després d'aquest document.

## Enfocament

Les operacions i els filtres són purs i no importen Flutter. El panell llegeix el motor i escriu pel repositori existent, el document sencer. No es puja `formatVersion`. No hi ha escriptor de la clau legacy. La pantalla solta del motor no desa.

## Estructura

```
lib/oee_history.dart           # desar, revisió, filtres, vista
lib/oee_history_panel.dart     # càlcul contextual i històric
lib/workspace_model.dart       # replacesId opcional
lib/workspace_codec.dart       # clau opcional, cicle i orfe
lib/oee_engine_panel.dart      # llavor i botons només si el panell desa
lib/workspace_page.dart        # segment a la línia i botó de barra
test/oee_history_test.dart
test/oee_history_panel_test.dart
```

## Decisions d'aquesta PR

- `replacesId` apunta al validat corregit. L'original no guanya cap camp nou en ser substituït.
- L'esborrany s'actualitza al mateix ID. El validat, no.
- El torn i el lot concret comparen igualtat. L'article compara conté.
- La llista no mostra el validat substituït. `Revisió anterior` l'obre.
- El pastís i els indicadors d'un registre obert surten de `evaluateOeeEngine` amb el `c` desat.

## Riscos

- `replacesId` absent s'ha de llegir com a `null`. Un export sense revisions no ha d'afegir la clau.
- La pantalla solta del motor i la de la línia comparteixen el panell. El botó de desar només es munta a la línia.
- Una línia eliminada no es pot seleccionar a l'arbre. L'històric de la barra és la via per retrobar-la.
- La quota real del navegador només es reporta si es reprodueix. El repositori ja no marca `Desat` si l'escriptura falla.

# Tasques: històric OEE (PR E)

## T16 — Spec

- [x] Afegir la secció 16, el pla i la traça abans del codi.

## T17 — Domini

- [ ] Desar esborrany i validat amb `c` congelat i noms capturats.
- [ ] El validat és immutable. La correcció crea una revisió i conserva l'original.
- [ ] Filtres, inclosos els extrems de data, torn, article, lot buit i línia retirada o reanomenada.
- [ ] La vista per defecte exclou esborranys i no agrega.
- [ ] La còpia rodona i la restauració no muten l'OEE.

## T18 — Pantalla

- [ ] Alternar càlcul i històric a la línia. La barra obre l'històric sense línia.
- [ ] Obrir un registre amb entrades, estat, indicadors i pastís vàlid.
- [ ] 48 dp, focus visible, teclat i 360 px.
- [ ] El torn US-1 segueix a `79.2 %`. La pantalla solta no desa.

## T19 — Verificació

- [ ] `flutter analyze`, `flutter test`, `flutter build web` i Chrome a 1280 × 800 i 360 px.

## Fora de la PR E

- [ ] QA integrada d'R6.
