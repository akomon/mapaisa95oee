# US-2: Mapa ISA-95 de la planta

Font: issue [#3](https://github.com/akomon/mapaisa95oee/issues/3). Els criteris d'acceptació ja estan tancats. Aquest document els fixa perquè el codi i els tests els segueixin sense reinterpretar-los.

## Objectiu

Com a responsable de planta, modelar la jerarquia de la fàbrica segons ISA-95 per veure-la clara i fer-la servir als cursos.

## Abast

Dins:

- Aplicació Flutter Web, només client. Persistència al navegador; sense backend.
- Model pur a `lib/plant_model.dart`. La UI no decideix les regles de jerarquia ni de JSON; només crida el model i el mostra.
- Arbre desplegable, vista per nivells funcionals 0–4, CRUD de nodes, confirmació en esborrar amb fills.
- Persistència local, exportació i importació JSON, planta alimentària d'exemple.
- Navegació entre el calculador OEE (US-1) i el mapa.
- Tests unitaris del model, validacions, JSON i exemple.

Fora (US-3):

- Exportació PDF.
- OEE per línia.

## Jerarquia d'equipament

Cinc tipus, en aquest ordre estricte (pare → fill permès):

| Tipus | Identificador | Fill permès |
| --- | --- | --- |
| Empresa | `enterprise` | `site` |
| Lloc | `site` | `area` |
| Àrea | `area` | `line` |
| Línia | `line` | `cell` |
| Cel·la | `cell` | cap |

La planta és un bosc d'empreses: la llista arrel només pot contenir nodes `enterprise`. Un node només pot tenir fills del tipus immediatament inferior.

## Nivell funcional (Purdue / ISA-95)

Cada node té un nivell funcional enter de 0 a 4, independent del tipus d'equipament:

| Valor | Identificador | Etiqueta |
| --- | --- | --- |
| 0 | `process` | Procés |
| 1 | `sensing` | Sensors |
| 2 | `control` | Control |
| 3 | `mes` | MES |
| 4 | `erp` | ERP |

Colors fixos de la vista per nivells (i del xip de nivell a l'arbre):

| Nivell | Color |
| --- | --- |
| 0 | `#5C6B73` |
| 1 | `#2A9D8F` |
| 2 | `#E9C46A` |
| 3 | `#F4A261` |
| 4 | `#E76F51` |

## Camps d'un node

| Camp | Tipus | Regla |
| --- | --- | --- |
| `id` | cadena no buida | Únic dins de tota la planta. El genera el model (`n` + compte monòton) si no es passa. |
| `name` | cadena | Obligatori. Després de `trim` no pot ser buit. |
| `description` | cadena opcional | `null` o buit després de `trim` es normalitza a `null`. |
| `kind` | `PlantNodeKind` | Un dels cinc tipus. |
| `functionalLevel` | `FunctionalLevel` | 0–4. |
| `children` | llista ordenada | Només fills del tipus permès. |

## Validacions

Si una operació viola una regla, no modifica l'estat i retorna les incidències. Es reporten totes les aplicables, en aquest ordre estable:

| Codi | Quan | Missatge |
| --- | --- | --- |
| `emptyName` | `name.trim()` buit | El nom no pot ser buit. |
| `invalidFunctionalLevel` | nivell fora de 0–4 (només en import JSON) | El nivell funcional ha de ser entre 0 i 4. |
| `invalidKind` | tipus desconegut (només en import JSON) | Tipus de node desconegut. |
| `hierarchyViolation` | fill no permès sota el pare, o arrel que no és empresa | La jerarquia ISA-95 no es respecta. |
| `duplicateId` | dos nodes amb el mateix `id` | Hi ha identificadors duplicats. |
| `nodeNotFound` | edició o esborrat d'un `id` inexistent | No s'ha trobat el node. |
| `invalidJson` | text que no és un objecte JSON de planta vàlid | El fitxer JSON no és vàlid. |

`PlantMutation` / `PlantImport` exposen `issues` i, si tot és correcte, la planta resultant. Amb qualsevol incidència, `plant` és `null`.

## Operacions del model

- `Plant createEmptyPlant()` — arrels buides.
- `Plant foodPlantExample()` — planta alimentària d'exemple (vegeu més avall).
- `PlantMutation addChild(Plant plant, {String? parentId, required String name, String? description, required PlantNodeKind kind, required FunctionalLevel functionalLevel})` — si `parentId` és `null`, afegeix una empresa a l'arrel; altrament afegeix un fill sota el node.
- `PlantMutation updateNode(Plant plant, {required String id, required String name, String? description, required FunctionalLevel functionalLevel})` — no canvia el `kind` ni els fills.
- `PlantMutation removeNode(Plant plant, {required String id})` — esborra el node i tot el subarbre. La UI demana confirmació abans de cridar-ho si `nodeHasChildren`.
- `bool nodeHasChildren(Plant plant, String id)`
- `String plantToJson(Plant plant)` — JSON amb indentació de 2 espais.
- `PlantImport plantFromJson(String raw)`
- `String plantNodeKindLabel(PlantNodeKind kind)`
- `String functionalLevelLabel(FunctionalLevel level)`
- `Color` no viu al model pur; la UI usa la taula de colors d'aquesta spec via `functionalLevelColorHex`.

### JSON

Format exacte de l'arrel:

```json
{
  "version": 1,
  "nodes": [ /* empreses */ ]
}
```

Cada node:

```json
{
  "id": "n1",
  "name": "Alimentària Demo",
  "description": null,
  "kind": "enterprise",
  "functionalLevel": 4,
  "children": []
}
```

`kind` en anglès minúscules com a la taula. `functionalLevel` és l'enter 0–4. `description` pot ser `null` o una cadena. Qualsevol altre esquema, tipus o jerarquia incorrecta → `invalidJson` i/o les altres incidències aplicables; si el parseig JSON falla del tot → només `invalidJson`.

## Persistència

Clau al navegador: `mapaisa95oee.plant.v1`.

Valor: la mateixa cadena JSON que `plantToJson`.

Si no hi ha valor o la importació falla en carregar, s'usa `createEmptyPlant()` i no es bloqueja la UI. Un missatge d'error d'importació manual sí que es mostra.

La capa d'emmagatzematge s'abstrau (`PlantStore`) perquè els tests no depenguin del navegador.

## Interfície

- Títol de la pantalla: `Mapa ISA-95`.
- Navegació bidireccional amb el calculador: accions a l'`AppBar` — des del calculador `Mapa ISA-95`; des del mapa `Calculador OEE`.
- Dues vistes commutables amb pestanyes o segment: `Arbre` i `Nivells`.
- Vista arbre: `ExpansionTile` (o equivalent) per nodes amb fills; cada fila mostra nom, etiqueta de tipus, xip de nivell funcional amb el color de la taula; accions afegir fill (si el tipus ho permet), editar i esborrar.
- Afegir a l'arrel: acció `Afegeix empresa`.
- Esborrar un node amb fills: diàleg de confirmació amb text `Aquest node té fills. Segur que vols esborrar-lo amb tot el subarbre?` i botons `Cancel·la` / `Esborra`.
- Formulari d'alta/edició: nom, descripció opcional, nivell funcional (selector 0–4 amb etiquetes). En alta, el tipus el determina el context (arrel → empresa; fill → l'únic tipus permès) i es mostra com a text de només lectura.
- Vista per nivells: cinc seccions ordenades 0→4, títol amb etiqueta i color de fons suau del nivell; a dins, la llista de nodes d'aquell nivell funcional amb el camí jeràrquic (`Empresa / Lloc / …`).
- Accions globals: `Exporta JSON`, `Importa JSON`, `Carrega exemple`.
- Import fallida: SnackBar o banner amb `El fitxer JSON no és vàlid.` (o el primer missatge d'`issues` si n'hi ha d'altres).
- Amplada màxima del contingut 640 px; a 360 px, columna amb scroll sense overflow. Objectius tàctils ≥ 48 dp.

Textos de la interfície en català, tal com els missatges d'aquesta spec.

## Planta alimentària d'exemple

`foodPlantExample()` retorna exactament aquesta estructura (ids fixos):

- `n1` Empresa `Alimentària Demo` — nivell 4, descripció `Grup alimentari d'exemple per a cursos.`
  - `n2` Lloc `Planta Girona` — nivell 3
    - `n3` Àrea `Envasat` — nivell 2
      - `n4` Línia `Línia iogurt` — nivell 2
        - `n5` Cel·la `Omplidora` — nivell 1
        - `n6` Cel·la `Taponadora` — nivell 1
      - `n7` Línia `Línia formatge` — nivell 2
        - `n8` Cel·la `Premsadora` — nivell 1
    - `n9` Àrea `Emmagatzematge` — nivell 2
      - `n10` Línia `Cambra freda` — nivell 1
        - `n11` Cel·la `Sensor temperatura` — nivell 0

## API de `lib/plant_model.dart`

- `enum PlantNodeKind { enterprise, site, area, line, cell }`
- `enum FunctionalLevel { process, sensing, control, mes, erp }` amb getters `int get value` (0–4) i `FunctionalLevel functionalLevelFromValue(int)`
- `enum PlantIssueCode { emptyName, invalidFunctionalLevel, invalidKind, hierarchyViolation, duplicateId, nodeNotFound, invalidJson }`
- `class PlantNode` — camps immutables + `copyWith` / constructors
- `class Plant` — `List<PlantNode> roots` i `int nextIdCounter`
- `class PlantMutation` — `plant` nul si hi ha incidències; `issues` ordenades
- `class PlantImport` — igual que `PlantMutation`
- Funcions llistades a Operacions
- `String plantIssueMessage(PlantIssueCode code)`
- `String functionalLevelColorHex(FunctionalLevel level)` — retorna el hex de la taula (`#RRGGBB`)
- `PlantNodeKind? allowedChildKind(PlantNodeKind parent)` — `null` per a `cell`
- `PlantNodeKind? kindFromJsonName(String raw)` / `String kindToJsonName(PlantNodeKind kind)`

## Casos de referència

### Alta vàlida

Planta buida → afegeix empresa `Acme` nivell 4 → un sol arrel. Després fill lloc `Girona` sota `Acme` → OK.

### Nom buit

Alta o edició amb nom `   ` → només `emptyName`; planta intacta.

### Jerarquia

Intent d'afegir una `area` sota una `enterprise` → `hierarchyViolation`. Intent d'afegir una `enterprise` sota un lloc → `hierarchyViolation`.

### Esborrat

Esborrar `n4` de l'exemple elimina també `n5` i `n6`. `nodeHasChildren(plant, 'n4')` és `true`.

### JSON

`plantToJson(foodPlantExample())` reimportat amb `plantFromJson` dóna la mateixa estructura (ids, noms, nivells i fills). Text `{"version":1}` o HTML → `invalidJson`.

### Persistència

Després de `save` + `load` amb el mateix store en memòria, la planta és equivalent a la desada.
