# SPEC v0.2 — Replantejament del mapa industrial IT/OT i de l'històric OEE

## 0. Procedència i aprovació

Font canònica, sense modificar:

<https://cursor.com/canvas/store-e0e4efdc-ca1f-4184-b42d-5f74748993ed/1ae0df40-ac99-402a-9f79-4f9f4b691006>

El canvas es conserva amb la redacció anterior a l'aprovació («Pendent d'aprovació», «criteris de l'esborrany», «DECISIÓ PROPOSADA», «només aleshores es demanarà aprovació»). Aquesta redacció és històrica. No es reescriu al canvas i no es reobren els requisits.

Aprovació posterior de Mon, com a product owner:

- «Em sembla bé l’spec»
- «Ok, que comenci»

Aquesta SPEC v0.2 és la consolidació fidel d'aquella font un cop aprovada. El que al canvas consta com a decisió proposada queda tancat a la secció 8. No s'hi afegeixen requisits. La maqueta visual, si n'hi ha, no és font de requisits d'aquesta PR: és referència de direcció per a la PR B.

Substitueix la US-2 (issue [#3](https://github.com/akomon/mapaisa95oee/issues/3), PR [#4](https://github.com/akomon/mapaisa95oee/pull/4), commit `4eb3e7dd01d1b8bf6e10f4798061caa0faa12220`) com a direcció de producte. No es reprèn la US-2 ni se'n pressuposa la reutilització completa.

La inspecció de model, persistència i dades reals s'ha fet sobre `main` a `4eb3e7dd01d1b8bf6e10f4798061caa0faa12220`, abans de qualsevol codi d'aquesta línia. Les troballes són a la secció 7.

## 1. Objectiu i límits

Documentar com s'organitza una planta, quins equips i sistemes hi intervenen i quines dades intercanvien; calcular i consultar l'OEE per línia sense perdre el context. Públic: responsables de planta, operacions, enginyeria IT/OT i participants en formació ISA-95.

Abast: Flutter Web existent, múltiples plantes i esquemes locals, inventari, fluxos declarats, relacions semiautomàtiques, versions d'arquitectura i registres OEE independents. La maqueta ja revisada és referència de direcció visual, no una pantalla normativa ni una font de dades.

Fora d'abast: backend, comptes, pagaments, col·laboració o sincronització, detecció de xarxa, connector industrial, telemetria en temps real, certificació ISA-95, PDF i agregació de factors OEE. L'aplicació documenta declaracions de l'usuari; no verifica la realitat de planta.

Ja acordat, i no reobert: lot opcional, separació IT/OT, arquitectura independent dels nivells, persistència local, històrics separats i velocitat en les dues unitats.

## 2. Conceptes i dades

Tres dimensions independents: jerarquia física, sistemes i aplicacions, i funcions ISA-95. L'organització és un contenidor organitzatiu sense nivell funcional. ERP i MES són sistemes que poden donar servei a diverses plantes o línies; no són fills físics d'una màquina. Tipus d'equip, funció i zona IT/OT no es dedueixen els uns dels altres.

La vista separa IT i OT amb una franja d'operacions L3 a la frontera. És una convenció visual explicada, no una classificació universal de MES ni de cap producte. Les funcions es documenten per responsabilitats: L0 procés, L1 sensat i actuació, L2 control, L3 operacions i L4 planificació empresarial. Un sistema en pot cobrir diverses. Un sensor no es converteix en una màquina perquè faci una funció L1, ni una màquina canvia de tipus perquè se li assigni una funció.

### 2.1 Entitats

Identitat comuna: ID estable, nom no buit, descripció opcional, dates de creació i modificació. Les referències usen IDs, mai noms.

| Entitat | Dades |
| --- | --- |
| Organització | ID, nom, descripció opcional, `iconKey` `organization`, creació i modificació. Agrupa plantes. Sense `parentId`, sense funcions, sense zona i sense tipus de sistema. |
| Actiu | `kind` estricta `plant`, `area`, `line` o `machine`. `parentId`. `iconKey` físic. Funcions L0–L4 opcionals i múltiples, mai deduïdes del tipus ni de la profunditat. |
| Sistema | Tipus descriptiu `erp`, `mes`, `scada`, `plc` o `other`. Icona de sistema. `scopeIds` d'actius. Funcions L0–L4. Zona declarada `it`, `ot`, `boundary` o `undefined`. Sense pare físic. |
| Flux | ID, origen i destí per ID d'actiu o sistema, dades intercanviades, protocol (pot ser desconegut), finalitat, estat `suggested` o `confirmed`. Un abast compartit no crea un flux. |
| Esquema | ID, nom, plantes incloses, actius, sistemes i fluxos referenciats, i disposició visual. Permet esquemes diferents sense duplicar un ERP compartit. |
| Versió d'esquema | ID, `schemaId`, data, nota, `parentVersionId` i snapshot autocontingut del model necessari i la disposició. Les versions anteriors no canvien en editar els mestres. |
| Registre OEE | ID, data de producció, torn, `lineId`, article, lot opcional, P, S, N, G, velocitat original i unitat, `c` normalitzat, estat i versió de fórmula. Snapshot de noms de línia i planta, article i valors emprats. Les dates de creació i modificació són diferents de la data de producció. |
| Còpia | `formatVersion`, `exportedAt`, entitats, esquemes, versions i registres OEE, amb tots els IDs i snapshots. L'històric OEE no forma part del snapshot d'arquitectura. |

Jerarquia física inicial, estricta: organització, i sota seu planta → àrea → línia → màquina. Un pare incompatible o un cicle es rebutja sencer. La jerarquia es podrà ampliar més endavant; aquesta versió no ho fa.

Eliminar un element amb fills, abasts, fluxos o referències d'esquema exigeix mostrar l'impacte i confirmar-lo. Cancel·lar no modifica res. Els snapshots i els registres OEE no s'esborren en cascada. Els noms capturats eviten dependre d'un mestre que ja no existeix. Després d'una eliminació confirmada no queden referències actives orfes: els fills físics s'eliminen amb el subarbre, els abasts perden aquells IDs, els fluxos afectats s'eliminen i els esquemes deixen de citar-los. Una referència històrica dins d'un snapshot o d'un registre OEE es conserva.

### 2.2 Identificadors i temps

Els IDs nous tenen la forma `n` seguida d'un enter, amb un comptador monòton al document. Els IDs ja existents, inclosos els de la migració, no es reescriuen en reanomenar ni en moure un element. El comptador salta un ID que ja existeixi.

Les dates de creació i modificació són UTC en ISO-8601 acabades en `Z`. La data de producció d'un registre OEE és `YYYY-MM-DD` i no es confon amb aquests instants.

### 2.3 Vocabulari tancat

| Concepte | Valors JSON | Etiqueta |
| --- | --- | --- |
| Funció `l0` | `l0` | Procés |
| Funció `l1` | `l1` | Sensat i actuació |
| Funció `l2` | `l2` | Control |
| Funció `l3` | `l3` | Operacions |
| Funció `l4` | `l4` | Planificació empresarial |
| Zona `it` | `it` | IT |
| Zona `ot` | `ot` | OT |
| Zona `boundary` | `boundary` | Frontera |
| Zona `undefined` | `undefined` | No definida |
| Tipus `erp` | `erp` | ERP |
| Tipus `mes` | `mes` | MES |
| Tipus `scada` | `scada` | SCADA |
| Tipus `plc` | `plc` | PLC |
| Tipus `other` | `other` | Altre |

Les etiquetes de funció no són ERP ni MES. ERP i MES són tipus de sistema.

Icona d'organització: `organization`. Icones d'actiu: `plant`, `area`, `line`, `machine`. Icones de sistema: `erp`, `mes`, `scada`, `plc`, `genericSystem`. Canviar la icona no canvia el tipus, les funcions, la zona ni els fluxos.

### 2.4 Document de còpia, formatVersion 1

```json
{
  "formatVersion": 1,
  "exportedAt": "2026-01-01T00:00:00.000Z",
  "nextIdCounter": 1,
  "organizations": [],
  "assets": [],
  "systems": [],
  "flows": [],
  "schemas": [],
  "architectureVersions": [],
  "oeeRecords": [],
  "migrationReviews": [],
  "legacyRaw": null
}
```

`exportedAt` només és obligatori a la còpia descarregada. El document desat a IndexedDB pot ometre'l. `legacyRaw` és el text original del mapa antic quan n'hi ha hagut; si no n'hi ha, és `null`.

Organització:

```json
{
  "id": "n1",
  "name": "Alimentària Demo",
  "description": null,
  "iconKey": "organization",
  "createdAt": "2026-01-01T00:00:00.000Z",
  "updatedAt": "2026-01-01T00:00:00.000Z"
}
```

Una organització amb `functions`, `functionalLevel`, `parentId`, `systemType` o `zone` es rebutja. No es converteix en ERP.

Actiu:

```json
{
  "id": "n2",
  "name": "Planta Girona",
  "description": null,
  "kind": "plant",
  "parentId": "n1",
  "iconKey": "plant",
  "functions": [],
  "createdAt": "2026-01-01T00:00:00.000Z",
  "updatedAt": "2026-01-01T00:00:00.000Z"
}
```

`kind` és `plant`, `area`, `line` o `machine`. El pare d'una planta és una organització; el d'una àrea, una planta; el d'una línia, una àrea; el d'una màquina, una línia. `functions` és una llista sense duplicats de `l0`…`l4`. Pot ser buida.

Sistema:

```json
{
  "id": "n16",
  "name": "ERP corporatiu",
  "description": null,
  "systemType": "erp",
  "iconKey": "erp",
  "scopeIds": ["n2", "n12"],
  "functions": ["l4"],
  "zone": "it",
  "createdAt": "2026-01-01T00:00:00.000Z",
  "updatedAt": "2026-01-01T00:00:00.000Z"
}
```

Cada `scopeId` ha de ser un actiu existent. No s'accepta l'ID d'una organització, d'un sistema ni d'un flux. El tipus, les funcions i la zona es desen encara que no «coincideixin».

Flux:

```json
{
  "id": "n30",
  "name": "Ordres de producció",
  "description": null,
  "sourceId": "n16",
  "targetId": "n17",
  "exchangedData": "Ordres",
  "protocol": null,
  "purpose": "Enviar el pla",
  "status": "suggested",
  "createdAt": "2026-01-01T00:00:00.000Z",
  "updatedAt": "2026-01-01T00:00:00.000Z"
}
```

`protocol` `null` vol dir desconegut. Una cadena buida no és un protocol. `status` és `suggested` o `confirmed`. Origen i destí són actius o sistemes existents. Els fluxos poden formar cicles; la prohibició de cicles no s'hi aplica.

Esquema:

```json
{
  "id": "n20",
  "name": "Esquema alimentari",
  "description": null,
  "plantIds": ["n2"],
  "assetIds": ["n2"],
  "systemIds": [],
  "flowIds": [],
  "layout": {
    "n2": {"x": 0, "y": 0}
  },
  "createdAt": "2026-01-01T00:00:00.000Z",
  "updatedAt": "2026-01-01T00:00:00.000Z"
}
```

Cada ID citat ha d'existir i ser del tipus que el camp indica. `plantIds` són actius `plant`. La disposició només cita IDs de la llista de l'esquema. Les coordenades són finites. Un esquema pot no contenir tota la planta.

Versió:

```json
{
  "id": "n40",
  "schemaId": "n20",
  "createdAt": "2026-01-01T00:00:00.000Z",
  "note": "Primera captura",
  "parentVersionId": null,
  "snapshot": {
    "schema": {},
    "organizations": [],
    "assets": [],
    "systems": [],
    "flows": []
  }
}
```

El snapshot no té `oeeRecords`, `migrationReviews` ni `architectureVersions`. Si hi apareixen, la còpia es rebutja. El snapshot és vàlid per si sol. `schemaId` ha d'existir entre els esquemes vius o, si el mestre s'ha retirat, el snapshot ha de portar un esquema amb el mateix ID i un nom no buit. `parentVersionId` és `null` o l'ID d'una altra versió. La cadena de versions no té cicles. La nota pot ser buida.

Registre OEE:

```json
{
  "id": "n50",
  "productionDate": "2026-03-01",
  "shift": "Matí",
  "lineId": "n4",
  "article": "Iogurt natural",
  "lot": null,
  "plannedMinutes": 480,
  "downtimeMinutes": 60,
  "speedOriginal": 1,
  "speedUnit": "secondsPerUnit",
  "idealCycleSeconds": 1,
  "totalUnits": 24000,
  "goodUnits": 22800,
  "status": "draft",
  "formulaVersion": "oee.v1",
  "capturedLineName": "Línia iogurt",
  "capturedPlantName": "Planta Girona",
  "createdAt": "2026-03-02T08:00:00.000Z",
  "updatedAt": "2026-03-02T08:00:00.000Z"
}
```

`speedUnit` és `secondsPerUnit` o `unitsPerSecond`. `status` és `draft` o `validated`. `totalUnits` i `goodUnits` són enters. `lot` buit es normalitza a `null`. Aquesta PR no calcula l'OEE ni aplica el domini de la secció 5: valida la forma. `lineId` ha de ser una línia viva o, si ja no existeix, el registre ha de conservar `capturedLineName` i `capturedPlantName` no buits. Reanomenar la línia no modifica el registre.

Revisió de migració:

```json
{
  "id": "review-n1",
  "entityId": "n1",
  "legacyKind": "enterprise",
  "legacyFunctionalLevel": 4,
  "legacyFunctionalLevelLabel": "ERP",
  "promoted": false,
  "status": "pendingReview"
}
```

`legacyKind` és `enterprise`, `site`, `area`, `line` o `cell`. El nivell és un enter 0–4 i l'etiqueta és exactament la del mapa antic: 0 Procés, 1 Sensors, 2 Control, 3 MES, 4 ERP. `promoted` de la migració d'aquesta PR és sempre `false`. `status` és `pendingReview` o `reviewed`. `entityId` ha d'existir. La revisió no escriu funcions, tipus ni zona.

Els IDs vius d'organitzacions, actius, sistemes, fluxos, esquemes, versions i registres OEE comparteixen un sol espai. Els IDs de revisió viuen a part, amb el prefix `review-`. Dins de cada snapshot els IDs no es dupliquen; poden repetir els IDs vius perquè són la identitat capturada.

### 2.5 Validació d'una còpia

Si el text no és un objecte JSON, l'única incidència és `invalidJson`. Si l'objecte és el mapa antic (`version` 1 i `nodes`, sense `formatVersion`), l'única incidència és `legacyFileNeedsMigration`: no es llegeix com a còpia nova i no es migra des del botó d'importació. Si `formatVersion` no és 1, `unsupportedVersion`.

Qualsevol altra incidència rebutja el conjunt abans d'escriure. Ordre estable:

| Codi | Quan |
| --- | --- |
| `invalidJson` | Forma il·legible o tipus JSON incorrecte. |
| `unsupportedVersion` | `formatVersion` absent o diferent d'1. |
| `legacyFileNeedsMigration` | JSON del mapa antic, no una còpia d'aquest format. |
| `emptyName` | Nom buit després de `trim`. El camp és `name`. |
| `duplicateId` | Dos IDs vius iguals, o duplicats dins d'un snapshot o d'una llista d'abast. |
| `incompatibleParent` | Pare que no respecta la jerarquia estricta. |
| `cycle` | Cicle a la jerarquia física o a la cadena de versions. |
| `orphanReference` | Referència activa a un ID inexistent, o disposició que cita un ID fora de l'esquema. |
| `invalidEndpoint` | Origen o destí que no és un actiu ni un sistema. |
| `functionsNotAssignable` | Funcions, nivell, pare, tipus o zona sobre una organització, o `functionalLevel` sobre un actiu. |
| `invalidField` | Enum, nombre, data o enter fora del que aquesta secció admet. El camp identifica l'error. |
| `confirmationRequired` | Eliminació amb dependències sense confirmació. No s'usa en importar. |
| `notFound` | Edició o esborrat d'un ID inexistent. |

Missatges:

| Codi | Missatge |
| --- | --- |
| `invalidJson` | El JSON no és vàlid. |
| `unsupportedVersion` | La versió del format no està suportada. |
| `legacyFileNeedsMigration` | Aquest JSON és del mapa antic. No s'importa com a còpia nova; la migració llegeix la clau del navegador. |
| `emptyName` | El nom no pot ser buit. |
| `duplicateId` | Hi ha identificadors duplicats. |
| `incompatibleParent` | El pare no és compatible amb aquest element. |
| `cycle` | La jerarquia no pot contenir cicles. |
| `orphanReference` | Hi ha una referència orfe. |
| `invalidEndpoint` | L'origen o el destí del flux no és un actiu ni un sistema. |
| `functionsNotAssignable` | L'organització no té funcions ISA-95 ni es converteix en un sistema. |
| `invalidField` | El camp no és vàlid. |
| `confirmationRequired` | Cal confirmar l'eliminació: hi ha dependències. |
| `notFound` | No s'ha trobat l'element. |

Una operació invàlida retorna el document intacte.

### 2.6 Operacions de domini cobertes per la PR A

El domini no importa Flutter. Les operacions reben l'instant `now`.

- Crear, reanomenar i canviar la descripció d'una organització. L'ID no canvia. No hi ha operació per assignar-li funcions: `assignFunctions` sobre una organització retorna `functionsNotAssignable` i no muta.
- Crear un actiu amb pare compatible, icona i funcions opcionals. Rebutjar nom buit, pare incompatible i cicle.
- Moure un actiu només cap a un pare compatible, sense cicles. Canviar la icona o les funcions no mou el pare ni crea fluxos.
- Crear i editar un sistema, l'abast inclòs. Editar l'abast no modifica cap `parentId`.
- Crear un flux només amb extrems vàlids. L'estat inicial pot ser `suggested`. Confirmar-lo és una operació explícita sobre aquell flux.
- Eliminar. Si hi ha fills, sistemes que l'abasten, fluxos o esquemes que el citen, cal `confirm: true`. Amb `confirm: false` el resultat és `confirmationRequired`, el document no canvia i l'informe llista `childIds`, `scopeSystemIds`, `flowIds` i `schemaIds`. També llista, sense esborrar-los, `retainedOeeRecordIds` i `retainedSnapshotIds`. Sense dependències actives, l'eliminació es fa directament. Els snapshots queden byte a byte iguals. Els registres OEE també.
- Marcar una revisió com a `reviewed` no escriu funcions, tipus ni zona.
- La fixture i la migració descrites més avall.

La UI per fer aquestes operacions sobre el mapa és la PR B. Aquesta PR les deixa provades al model.

### 2.7 Fixture pedagògica

`foodIndustryExample()` és l'exemple alimentari nou. No és el `foodPlantExample()` del mapa antic. Tots els instants són `2026-01-01T00:00:00.000Z`. `nextIdCounter` és 21. No hi ha fluxos, versions, registres OEE ni revisions. Cap actiu té funcions. L'organització no és un sistema i no té nivell.

| ID | Què és | Pare | Detall |
| --- | --- | --- | --- |
| `n1` | Organització Alimentària Demo | — | Descripció `Grup alimentari d'exemple. Contenidor organitzatiu, sense funció ISA-95.` Icona `organization`. |
| `n2` | Planta Girona | `n1` | |
| `n3` | Àrea Envasat | `n2` | |
| `n4` | Línia iogurt | `n3` | Sense funcions. No és L2. |
| `n5` | Màquina Omplidora | `n4` | |
| `n6` | Màquina Taponadora | `n4` | |
| `n7` | Línia formatge | `n3` | |
| `n8` | Màquina Premsadora | `n7` | |
| `n9` | Àrea Emmagatzematge | `n2` | |
| `n10` | Línia Cambra freda | `n9` | |
| `n11` | Màquina Sensor temperatura | `n10` | És una màquina. No se li assigna L0 ni L1 pel nom. |
| `n12` | Planta Lleida | `n1` | |
| `n13` | Àrea Elaboració | `n12` | |
| `n14` | Línia llet | `n13` | |
| `n15` | Màquina Pasteuritzadora | `n14` | |
| `n16` | Sistema ERP corporatiu | — | Tipus `erp`, funcions `l4`, zona `it`, abast `n2` i `n12`, icona `erp`. |
| `n17` | Sistema MES envasat | — | Tipus `mes`, funcions `l3`, zona `boundary`, abast `n4` i `n7`, icona `mes`. |
| `n18` | Sistema PLC omplidora | — | Tipus `plc`, funcions `l1` i `l2`, zona `ot`, abast `n5`, icona `plc`. |
| `n19` | Sistema Historian qualitat | — | Tipus `other`, funcions `l2` i `l3`, zona `it`, abast `n2`, icona `genericSystem`. |
| `n20` | Esquema alimentari | — | Plantes `n2` i `n12`. Actius `n2`…`n15`. Sistemes `n16`…`n19`. Sense fluxos. Disposició en graella d'aquells IDs, començant a (0, 0) amb pas 160. |

L'ERP no és fill de cap màquina i no es duplica per planta. El MES no és un nivell de la línia. El PLC té dues funcions. El historian té un tipus que no és una funció.

## 3. Espai de treball

L'espai de treball aprovat, per a la PR B, és un escriptori compacte d'estètica industrial: antracita i acer, accents discrets, contrast llegible i icones amb etiqueta. Arbre contextual a l'esquerra; mapa IT/OT al centre, amb franja L3; inspector lateral per editar la selecció, l'abast, les funcions i els fluxos; barra baixa per al mapa, les versions i l'estat de desament. Sense grans buits ni formularis en pàgines successives.

Seleccionar una línia manté l'arbre i el context. Un panell permet alternar esquema, càlcul i històric OEE. El mapa té selecció, zoom i enquadrament. Les connexions mostren direcció i estat. No cal representar una planta sencera per desar un primer esquema.

A 360 px, l'arbre i l'inspector són panells desplegables accessibles i el mapa es pot navegar. L'OEE i els formularis passen a una columna. La referència d'escriptori és 1280 × 800, amb arbre, mapa i inspector alhora. Ni el color ni arrossegar són l'única manera d'operar.

Aquesta PR no construeix aquest espai. No substitueix el calculador ni el mapa antic per una versió incompleta. Afegeix només la pantalla `Dades locals`, necessària per exercir la persistència, la còpia i la migració.

### 3.1 Pantalla `Dades locals`

Textos en català. Amplada màxima 640 px. A 360 px, una columna amb desplaçament i sense overflow. Els controls nous fan com a mínim 48 × 48 dp. L'estat de desament es llegeix pel text, no només pel color.

| Estat | Text |
| --- | --- |
| Escrivint | Desant… |
| Transacció confirmada | Desat |
| Transacció fallida | Error de desament. Les dades anteriors es conserven. |

Si l'excepció indica quota, s'hi afegeix `La quota d'emmagatzematge s'ha exhaurit.` L'estat continua sent error. No es mostra `Desat`.

Limitació, sempre visible:

`IndexedDB és local a aquest origen i perfil del navegador. No és una còpia de seguretat. Esborrar dades, canviar de dispositiu, el mode privat o l'expulsió d'emmagatzematge pot perdre informació. Un error de quota no vol dir que s'hagi desat. El JSON descarregable és la via de recuperació. No hi ha sincronització ni durabilitat garantida.`

La pantalla mostra si la clau lògica `mapaisa95oee.plant.v1` encara es llegeix, i a la web si `localStorage` conserva `flutter.mapaisa95oee.plant.v1`. No esborra ni reescriu cap de les dues. Mostra les revisions pendents amb el tipus antic, el nivell, l'etiqueta antiga i el text `no promogut`. Mostra els recomptes d'organitzacions, actius, sistemes, fluxos, esquemes, versions i registres OEE, i recorda que els registres OEE no formen part dels snapshots. Llista organitzacions amb `Sense funció ISA-95`, actius amb el tipus físic i sistemes amb tipus, funcions, zona i abast.

Accions:

- `Exporta còpia` descarrega `mapaisa95oee-backup.json`.
- `Descarrega la còpia legacy` descarrega el text original, quan existeix, com a `mapaisa95oee-legacy-plant.json`. No escriu a la base.
- `Carrega exemple alimentari` carrega la fixture. Si ja hi ha dades, demana confirmació: `Carregar l'exemple substitueix les dades d'aquest navegador.` Botons `Cancel·la` i `Carrega exemple`. Cancel·lar no escriu.
- `Prepara substitució` valida el JSON enganxat o el fitxer triat. Si és invàlid, mostra el missatge i no escriu. Si és vàlid, obre `Substitució completa`, amb els recomptes, el text `Aquesta acció substitueix totes les dades locals d'IndexedDB. No fusiona identificadors.`, i els botons `Descarrega la còpia prèvia`, `Cancel·la` i `Substitueix les dades`. Cancel·lar no escriu. Confirmar escriu el document nou i la còpia prèvia en una sola transacció.

Un rebuig de validació no és un èxit de desament. Una transacció fallida torna a mostrar el document anterior.

Navegació bidireccional, sense treure la que ja existeix: `Calculador OEE`, `Mapa ISA-95`, `Dades locals`.

## 4. User stories i acceptació

La numeració AC-01…AC-21 és la de la font i no es renumera. Tots els criteris formen part del producte aprovat. No tots es tanquen en aquesta PR. La traça és a la secció 12.

### US-R1 · Inventari i estructura física

Com a responsable de planta, vull definir actius i sistemes sense barrejar-los amb els nivells funcionals.

1. AC-01. Crear, editar i eliminar organització, plantes, àrees, línies i màquines amb nom i icona; rebutjar noms buits, pares incompatibles i cicles, amb missatge al camp. IDs estables després de reanomenar.
2. AC-02. Crear un MES o ERP amb abast en dues plantes o línies i funcions independents; editar-ne l'abast no mou cap actiu. L'organització no ofereix selector L0–L4 ni conversió a ERP.
3. AC-03. Abans d'eliminar un element amb fills, abasts o fluxos, mostrar dependències i demanar confirmació; cancel·lar no modifica res. Cap operació deixa referències actives orfes; els snapshots previs continuen llegibles.

### US-R2 · Mapa útil i relacions assistides

Com a enginyer IT/OT, vull veure i documentar els intercanvis sense que l'eina inventi connexions.

4. AC-04. En escriptori es poden seleccionar i editar equips i sistemes al mateix espai, amb arbre, mapa IT/OT, franja L3 i inspector; canviar la selecció conserva la planta i l'esquema actius.
5. AC-05. Aplicar una plantilla mostra prèviament les màquines i les icones a crear; la màquina creada des d'una línia n'hereta només la pertinença. Cap plantilla ni canvi d'icona assigna nivells o fluxos confirmats.
6. AC-06. Crear un flux amb origen i destí vàlids, dades, protocol o desconegut i finalitat. Cada suggeriment es veu com a suggeriment, es pot descartar i requereix confirmació explícita individual. Cap exploració de xarxa.
7. AC-07. Es poden guardar i obrir múltiples esquemes i plantes amb disposició i selecció contextual coherents. L'exemple alimentari separa estructura física, abast ERP/MES i funcions; no presenta empresa = L4 ni línia = L2.

### US-R3 · Persistència, còpia i versions

Com a usuari, vull recuperar el treball i les versions sense dependre d'un servidor.

8. AC-08. Després de desar i recarregar al mateix origen i navegador, IndexedDB recupera el model, els esquemes, les versions i l'OEE. La UI distingeix desant, desat i error, i no anuncia èxit si una transacció falla.
9. AC-09. Exportar un JSON versionat i reimportar-lo reprodueix les dades i els històrics. Un import invàlid, una versió no suportada, IDs duplicats, referències orfes o cicles rebutja el conjunt abans de modificar la base.
10. AC-10. Una importació que substitueixi dades mostra l'impacte, exigeix confirmació i ofereix una còpia prèvia. L'aplicació és atòmica: cancel·lació, error o interrupció no deixen una base parcial.
11. AC-11. Crear una instantània amb data i nota; restaurar-ne una genera una versió nova que referencia l'origen, sense sobreescriure versions prèvies ni alterar l'OEE. El snapshot restaurat conserva íntegre el seu contingut.

### US-R4 · Càlcul OEE explícit i fiable

Com a responsable de producció, vull introduir la velocitat en la unitat que conec i entendre els resultats.

12. AC-12. Introduir P i S en minuts, N i G enters, i la velocitat en s/unitat o unitats/s. Acceptar decimals amb coma o punt, sense separadors de milers ambigus; rebutjar buits obligatoris, NaN, infinits i valors fora de domini.
13. AC-13. Canviar d'unitat usa el valor canònic sense encadenar arrodoniments; conversions repetides mantenen `c` i els resultats dins la tolerància de QA. Arrodonir només la presentació.
14. AC-14. Mostrar OEE, disponibilitat, rendiment i qualitat separats segons les fórmules i els estats de la secció 5. Els errors i els factors indefinits s'expliquen; no hi ha divisió per zero ni retall silenciós al 100%.
15. AC-15. Pastís del temps planificat amb productiu equivalent i tres pèrdues, unitat i valors visibles; mai la suma de D, R i Q. Si hi ha dades inconsistents o un rendiment excessiu, no es pinten porcions negatives ni un pastís aparentment vàlid.

### US-R5 · Històric OEE contextual

Com a responsable de línia, vull conservar i retrobar els càlculs per producció.

16. AC-16. Desar un registre amb data i torn, línia, article i lot opcional, dades originals i `c` congelat. Reanomenar la línia o canviar la velocitat mestra no modifica cap resultat ni cap etiqueta històrica capturada.
17. AC-17. Consultar i filtrar per dates, torn, línia, article i lot; obrir un registre mostra les entrades, l'estat, els quatre indicadors i un pastís vàlid. Sense lot continua sent desable i filtrable.
18. AC-18. Distingir esborrany i registre validat; l'històric de registres validats exclou els esborranys per defecte. A l'MVP es mostren indicadors per registre, sense mitjana simple de percentatges ni agregació de factors.

### US-R6 · Transició segura i qualitat d'ús

Com a usuari existent, vull conservar les dades i operar amb claredat en pantalles diferents.

19. AC-19. Abans de migrar les dades existents es conserva una còpia recuperable i es valida la migració sobre una còpia. Les assignacions antigues de tipus cap a nivell no es promouen automàticament al significat nou; queden identificades per revisar.
20. AC-20. A 360 px i en escriptori, formularis, històrics i accions són accessibles sense retalls; el mapa té zoom i desplaçament. Prova amb teclat de selecció, edició, confirmació i cancel·lació, focus visible, etiquetes accessibles i estat que no s'expressa només pel color.
21. AC-21. QA executa proves unitàries, de persistència, d'importació i de restauració, i comprovacions reals al navegador; aporta sortides d'anàlisi i de tests, i evidència visual de la densitat d'escriptori i de l'ús mòbil. Cap equivalència pedagògica empresa = ERP o jerarquia = nivells a l'exemple.

## 5. Càlcul i casos OEE

Normatiu per a la PR D. Aquesta PR no modifica `lib/oee_calculator.dart` ni el formulari del calculador. El calculador visible continua sent el de la US-1 fins a la PR D.

Tots els temps es normalitzen a segons: P planificat, S parades, O operatiu, `c` segons/unitat, `v` unitats/segon, N total produït i G unitats bones. P exclou el temps que no s'havia planificat produir. S són parades dins de P. Entrada vàlida: P > 0, 0 ≤ S ≤ P, `c` > 0, N i G enters, 0 ≤ G ≤ N. La velocitat ideal correspon a la línia i l'article del registre.

O = P − S. `c` = 1/v. D = O/P.

R = cN/O. Q = G/N. OEE = cG/P.

Quan els denominadors són vàlids, OEE = D × R × Q. Els indicadors es mostren en percentatge. Els càlculs interns no s'arrodonixen.

Tproductiu = cG. Tdisponibilitat = S. Trendiment = O − cN. Tqualitat = c(N − G).

Tproductiu + Tdisponibilitat + Trendiment + Tqualitat = P.

El pastís descompon el temps planificat en equivalent. No és un registre cronològic de causes de parada. La llegenda i el tooltip expliquen la conversió d'unitats a temps ideal.

| Cas | Comportament |
| --- | --- |
| Referència | P = 480 min, S = 60 min, c = 1 s/u, N = 24000, G = 22800. O = 25200 s. D = 87,5 %. R = 95,238095 %. Q = 95 %. OEE = 79,166667 %. |
| Pastís de referència | Productiu 380 min; disponibilitat 60 min; rendiment 20 min; qualitat 20 min; total 480 min. |
| Conversió decimal | 0,4 s/u equival a 2,5 u/s. Convertir repetidament no canvia l'OEE. P = 1 min, S = 0, N = 100, G = 90: D = 100 %, R = 66,666667 %, Q = 90 %, OEE = 60 %. |
| N = 0 i O > 0 | G = 0. OEE = 0. D = O/P. R = 0 perquè O > 0. Q no aplica. Pastís: productiu 0, disponibilitat S, rendiment O, qualitat 0. |
| O = 0 i N = 0 | G = 0 i S = P. D = 0, OEE = 0, R i Q no apliquen. Pastís: disponibilitat P i la resta 0. |
| O = 0 i N > 0 | Inconsistent. Error visible. Sense pastís i sense validar el registre. No es mostra un OEE com si fos fiable. |
| R > 1 | Avís de velocitat, temps o unitats inconsistents. Es pot desar un esborrany. No es pot validar el registre fins a corregir-lo. No es capa el factor ni es pinta un pastís negatiu. |
| Altres errors | P = 0, S > P, c ≤ 0, v ≤ 0, G > N, N negatiu o comptatges fraccionaris: error amb el camp identificat. No es calculen resultats vàlids. |

Tolerància relativa `1e-9` per a conversions i residus de coma flotant. No serveix per amagar un rendiment real superior a 1. Un residu estrictament numèric s'explica i només es normalitza en representar el pastís. Qualsevol canvi de fórmula porta una versió explícita. La constant reservada per a aquesta fórmula és `oee.v1`. Aquesta PR la pot emmagatzemar; no la calcula.

No hi ha agregació a l'MVP. Si s'aprovés més endavant, l'OEE de conjunt seria la suma de `cG` dividida per la suma de P, sobre registres validats, compatibles i sense solapaments. No seria una mitjana simple. Tampoc es poden mitjanar D, R i Q. Si `c` varia, la qualitat que tanca la descomposició agregada seria la suma de `cG` dividida per la suma de `cN`.

El contracte executable de la PR D és la secció 15, a [phase-d.md](phase-d.md). No reobre els casos d'aquesta secció ni les decisions de la secció 8.

El contracte executable de la PR E és la secció 16, a [phase-e.md](phase-e.md). No reobre les seccions 8, 14 ni 15.

## 6. Persistència, migració i QA

IndexedDB és local a l'origen i al perfil del navegador. No és una còpia de seguretat. Esborrar dades del navegador, canviar de dispositiu, el mode privat o l'expulsió d'emmagatzematge pot perdre informació. La limitació es mostra al desament i a la còpia. Un error de quota no deixa un estat de desat fals. El JSON descarregable és la via de recuperació. No es promet sincronització ni durabilitat. Tampoc es promet que l'aplicació arrenqui sense xarxa: una closca offline tindria abast i proves propis.

La importació de l'MVP és només substitució completa. No hi ha fusió parcial d'IDs. Abans d'escriure es valida el format, els dominis, la jerarquia, els abasts, els extrems dels fluxos, els snapshots autocontinguts i la forma dels registres OEE. Una referència històrica a un mestre retirat és admissible només si el snapshot o el registre conserva la identitat. Els fluxos poden tenir cicles reals. La prohibició de cicles és per a la jerarquia i per a la cadena de versions.

La restauració d'un esquema, a la PR C, genera una versió de treball nova des del snapshot, sense sobreescriure els mestres compartits actuals ni l'OEE. Conserva els IDs originals com a identitat capturada. Qualsevol reconciliació amb l'inventari vigent es mostra i es confirma; no es dedueix en silenci.

Base IndexedDB d'aquesta PR:

| Peça | Valor |
| --- | --- |
| Nom de la base | `mapaisa95oee` |
| Versió d'esquema IndexedDB | 1 |
| Magatzem | `kv` |
| Clau del document | `workspace` |
| Clau de l'informe de migració | `migrationState` |

`workspace` i les claus que s'escriuen juntes van en una sola transacció. Si la transacció falla, IndexedDB conserva els valors anteriors i la UI no diu `Desat`.

`migrationState.status` és `noLegacyData`, `migrated` o `rejected`. En `rejected` no hi ha `workspace` aplicat. L'estat de la UI és error, no desat. El text legacy queda a `migrationState.legacyRaw` i a la clau del navegador.

### 6.1 Què es conserva del navegador

La migració només llegeix `SharedPreferences.getString('mapaisa95oee.plant.v1')`. No crida `setString`, `remove` ni `clear` sobre aquesta clau ni sobre cap altra.

A Flutter Web, `shared_preferences` 2.5.6 amb `shared_preferences_web` 2.4.3 desa aquesta clau a `localStorage` com a `flutter.mapaisa95oee.plant.v1`. El valor d'`localStorage` és el JSON del text (una cadena JSON codificada una segona vegada). `getString` ja retorna el text del mapa. La migració usa aquest text. La comprovació visual mira també la clau de `localStorage` i no l'esborra.

El mapa antic continua podent escriure la seva clau si l'usuari l'edita. Aquesta PR no el sincronitza amb IndexedDB. La còpia capturada en migrar és el text llegit en aquell moment. El risc de divergència queda descrit a la secció 7 i es manté fins que la PR B retiri el mapa antic.

### 6.2 Migració no destructiva

1. Si `workspace` ja existeix, no es torna a migrar i no es llegeix el legacy per substituir-lo.
2. Si no hi ha text legacy, es desa un document buit vàlid i l'informe `noLegacyData`.
3. Si n'hi ha, es treballa sobre una còpia en memòria. El text original no s'escriu.
4. La còpia es valida amb el parser del mapa antic (`plantFromJson`). Si falla, el resultat és `rejected`, sense entitats noves, i la UI queda en error.
5. Si és vàlid, es projecta la jerarquia física i es torna a validar el document nou. Si aquesta segona validació falla, es descarta el resultat i l'informe és `rejected`.
6. Només un resultat vàlid s'escriu a `workspace`, en la mateixa transacció que l'informe `migrated`.

Projecció, i cap altra:

| `kind` antic | Entitat nova | Pare |
| --- | --- | --- |
| `enterprise` | Organització | Cap |
| `site` | Actiu `plant` | L'empresa on penjava |
| `area` | Actiu `area` | El lloc on penjava |
| `line` | Actiu `line` | L'àrea on penjava |
| `cell` | Actiu `machine` | La línia on penjava |

Es conserven `id`, `name` i `description`. `iconKey` surt només del tipus físic nou: `organization`, `plant`, `area`, `line`, `machine`. No surt de `functionalLevel`. Les funcions queden buides. No es creen sistemes, fluxos, esquemes, versions ni registres OEE. No s'assigna zona. Els instants de creació i modificació són l'instant de migració passat pel cridant, perquè el mapa antic no en tenia. Cada node genera una revisió `pendingReview` amb `promoted: false`, el `kind` antic, l'enter `functionalLevel` i l'etiqueta antiga. `nextIdCounter` és el del document antic.

Sobre l'exemple antic, el resultat esperat és:

| ID | Entitat | Pare | Nivell antic | Etiqueta antiga |
| --- | --- | --- | --- | --- |
| `n1` | Organització Alimentària Demo | — | 4 | ERP |
| `n2` | Planta Girona | `n1` | 3 | MES |
| `n3` | Àrea Envasat | `n2` | 2 | Control |
| `n4` | Línia iogurt | `n3` | 2 | Control |
| `n5` | Màquina Omplidora | `n4` | 1 | Sensors |
| `n6` | Màquina Taponadora | `n4` | 1 | Sensors |
| `n7` | Línia formatge | `n3` | 2 | Control |
| `n8` | Màquina Premsadora | `n7` | 1 | Sensors |
| `n9` | Àrea Emmagatzematge | `n2` | 2 | Control |
| `n10` | Línia Cambra freda | `n9` | 1 | Sensors |
| `n11` | Màquina Sensor temperatura | `n10` | 0 | Procés |

Onze revisions, zero sistemes, descripció de `n1` conservada, `nextIdCounter` 12. Cap d'aquests nivells es copia a `functions`.

No es tradueixen protocols: el mapa antic no en tenia. No es creen referències a IDs que la projecció no hagi creat.

## 7. Línia base inspeccionada

Commit `4eb3e7dd01d1b8bf6e10f4798061caa0faa12220`. No hi ha backend ni cap altra clau de persistència.

### 7.1 Model llegat (`lib/plant_model.dart`)

Arbre imbricat, no una llista amb `parentId`. Tipus `enterprise`, `site`, `area`, `line`, `cell`, amb un sol fill permès per nivell i arrels només empresa. Cada node té `functionalLevel` 0–4 independent del tipus segons les regles, però l'exemple pedagògic lliga tipus i nivell:

| ID | Tipus | Nivell | Etiqueta que pinta la UI antiga |
| --- | --- | --- | --- |
| `n1` Alimentària Demo | `enterprise` | 4 | ERP |
| `n2` Planta Girona | `site` | 3 | MES |
| `n3` Envasat | `area` | 2 | Control |
| `n4` Línia iogurt | `line` | 2 | Control |
| `n5` Omplidora, `n6` Taponadora | `cell` | 1 | Sensors |
| `n7` Línia formatge | `line` | 2 | Control |
| `n8` Premsadora | `cell` | 1 | Sensors |
| `n9` Emmagatzematge | `area` | 2 | Control |
| `n10` Cambra freda | `line` | 1 | Sensors |
| `n11` Sensor temperatura | `cell` | 0 | Procés |

IDs `n1`…`n11`, `nextIdCounter` 12. No hi ha icones, sistemes, abasts, fluxos, esquemes, snapshots ni OEE. L'esborrat del model és recursiu i immediat. La UI només confirma si hi ha fills. El JSON és `{ "version": 1, "nodes": [...] }`. Una importació invàlida no aplica el canvi. Una càrrega invàlida mostra una planta buida en memòria i no reescriu la clau fins que un desament posterior ho faci. Aquesta PR no copia aquest buidat silenciós: un legacy il·legible no es converteix en un document nou desat com a èxit.

### 7.2 Persistència llegada

`lib/plant_store.dart`: clau `mapaisa95oee.plant.v1`, valor `plantToJson`. `PreferencesPlantStore` rep un lector i un escriptor. `main.dart` els connecta a `SharedPreferences.getString` i `setString`. El prefix real de web és `flutter.` i la codificació del valor és la de la secció 6.1. `MemoryPlantStore` només s'usa als tests.

`lib/plant_io_web.dart` descarrega i llegeix un fitxer. No persisteix. El calculador (`lib/oee_calculator.dart`, `lib/oee_form.dart`) no persisteix res. Les seves fórmules i el torn de referència (cicle 60 s, 400 unitats, OEE mostrat 79,2 %) són les de `specs/01-calculador-oee/` i no són les de la secció 5.

### 7.3 Què es reutilitza i què no

Es reutilitza el patró de model pur, incidències ordenades, store injectable, JSON versionat i textos en català. Es conserven el calculador, el formulari, el mapa, el model antic i la seva clau, perquè retirar-los ara seria substituir la UI per una etapa que aquesta PR no tanca.

No es reutilitza `functionalLevel` com a funció nova, ni `foodPlantExample()` com a fixture nova, ni l'equivalència empresa = ERP. No es reutilitza l'esborrat recursiu cec sense informe. No es pressuposa que la PR #4 ja modela sistemes, fluxos o OEE: no ho fa.

Risc acceptat fins a la PR B: el mapa antic i IndexedDB poden divergir si l'usuari edita el mapa després de la migració. La clau legacy no s'esborra. La còpia capturada queda al document nou i es pot tornar a descarregar.

## 8. Decisions tancades

Aprovades amb la font. No es reobren.

1. Jerarquia estricta planta → àrea → línia → màquina, amb l'organització com a contenidor sense funció. Funcions múltiples als sistemes i, quan es declaren, als actius.
2. L'article és un text obligatori. El catàleg d'articles queda fora de l'MVP. El torn és un text.
3. S'admeten esborranys. Un rendiment superior a 1 impedeix validar el registre. No capa el factor.
4. Les versions són manuals, amb nota. No hi ha purga automàtica inicial. Hi ha avisos d'espai i d'error de quota.
5. Un registre validat és immutable. Corregir-lo crea una revisió que el substitueix a la vista i conserva l'anterior. Ho implementa la PR E; aquesta PR no reescriu captures.
6. La importació és completa i la restauració, quan arribi, serà autocontinguda. Aquesta PR ja substitueix el document sencer de la còpia, amb confirmació i còpia prèvia.
7. Les dades són locals. No es promet que l'aplicació funcioni sense xarxa.

També tancat: tolerància relativa `1e-9`; separació estricta entre snapshot d'arquitectura i històric OEE; cicles prohibits a la jerarquia i a les versions, permesos als fluxos; cap descoberta de xarxa; cap backend.

## 9. Verificació mínima d'aquesta PR

- Model: nom buit, pare incompatible, cicle, ID estable, ERP i MES amb abast a dues plantes o línies, editar l'abast no mou actius, organització sense funcions, icona sense efecte semàntic, eliminació amb confirmació i sense orfes, snapshots i OEE intactes.
- Fixture: cap organització amb funció, cap línia amb L2, ERP separat i no duplicat, PLC amb dues funcions, historian amb tipus `other`.
- Migració de l'exemple antic sobre una còpia, amb les onze revisions, zero sistemes i la clau legacy sense escriure. JSON antic invàlid: cap entitat i estat d'error.
- Còpia: anada i tornada; versió desconeguda; JSON truncat; ID duplicat; orfe; cicle de jerarquia rebutjat; cicle de flux acceptat; fitxer legacy rebutjat com a còpia; cancel·lar no escriu; fallada de transacció sense `Desat` i amb el document anterior.
- Editar un mestre no canvia el JSON d'un snapshot ni un registre OEE.
- `flutter analyze`, `flutter test` i `flutter build web`.
- Navegador real: conservació de la clau legacy, recàrrega des d'IndexedDB, error de còpia invàlida, cancel·lació, fixture sense empresa = L4, calculador US-1 encara operatiu, 360 px sense overflow.

Fora d'aquesta execució, i obligatori abans de tancar el producte: plantilles, suggeriments, mapa, restauració de versions, motor OEE nou, filtres d'històric, teclat complet de l'espai de treball i la passada integrada d'R6.

## 10. Pla de lliurament

| PR | Després de | Contingut |
| --- | --- | --- |
| A, aquesta | `main` actual | Model independent, fixture, IndexedDB versionat, còpia recuperable i migració no destructiva. Base d'R1, R3 i R6. |
| B | A | Espai compacte, inventari, mapa IT/OT i fluxos manuals. R2. |
| C | A i B | Plantilles, suggeriments, esquemes múltiples, snapshots, restauració. R3 que aquesta PR encara no fa, sobretot AC-11. |
| D | A | Motor OEE, unitats, quatre indicadors i pastís. R4. |
| E | B i D | Històric OEE i filtres. R5. |
| QA | Cada PR, i una passada final | R6 integrada quan B, C, D i E existeixin. |

No es fusiona res sense decisió de Mon. Si una PR creix fins a barrejar etapes, se subdivideix sense saltar dependències ni aquesta SPEC. Aquesta PR no s'ha subdividit: el model, la fixture, la base i la migració comparteixen un sol document. La UI del mapa no s'hi ha inclòs.

## 11. Traçabilitat AC-01…AC-21

| AC | US | On es tanca | Aquesta PR |
| --- | --- | --- | --- |
| AC-01 | R1 | Model ara; formulari amb el missatge al camp a la PR B | Parcial, només domini |
| AC-02 | R1 | Model ara; inspector a la PR B | Parcial, només domini |
| AC-03 | R1 | Model ara; diàleg al mapa a la PR B | Parcial, només domini |
| AC-04 | R2 | PR B | Diferit |
| AC-05 | R2 | PR B | Diferit. El model ja impedeix que la icona assigni funcions o fluxos |
| AC-06 | R2 | PR B | Diferit. El model no inventa fluxos ni explora la xarxa |
| AC-07 | R2 | Fixture ara; obertura al mapa a les PR B i C | Parcial, fixture |
| AC-08 | R3 | Aquesta PR | Cobert a la base de persistència |
| AC-09 | R3 | Aquesta PR | Cobert per a la còpia versionada |
| AC-10 | R3 | Aquesta PR | Cobert per a la substitució completa |
| AC-11 | R3 | PR C | Diferit. El document ja no barreja snapshots i OEE, i editar un mestre no els muta |
| AC-12 | R4 | PR D | Diferit. El calculador US-1 es conserva |
| AC-13 | R4 | PR D | Diferit |
| AC-14 | R4 | PR D | Diferit |
| AC-15 | R4 | PR D | Diferit |
| AC-16 | R5 | PR E | Diferit a la UI. El model no reescriu captures en reanomenar |
| AC-17 | R5 | PR E | Diferit |
| AC-18 | R5 | PR E | Diferit. El document ja té `draft` i `validated` |
| AC-19 | R6 | Aquesta PR | Cobert |
| AC-20 | R6 | PR B i PR E, amb la passada final | No tancat. La pantalla nova compleix 48 dp i 360 px, i l'estat de desament porta text |
| AC-21 | R6 | Cada PR i la passada final | Parcial: anàlisi, tests, build web i navegador de l'abast d'aquesta PR |

## 12. Fora d'aquesta PR

PR B, C, D i E, el redisseny visual, les plantilles, la descoberta assistida, la restauració de versions, el motor i el pastís de la secció 5, els filtres d'històric, l'agregació, el PDF, el backend i qualsevol lectura de la xarxa.

La columna «Aquesta PR» de la secció 11 descriu només la PR A. L'estat que tanca la PR B és la secció 13. No es reobren les decisions de la secció 8.

## 13. PR B — espai de treball, inventari i fluxos manuals

Aquesta secció és el contracte de la PR B. No afegeix requisits de producte. Tanca la part de UI que la secció 11 deixava per a B i resol el risc de divergència de la secció 7.3. La maqueta aprovada és direcció de composició, densitat i material. Els textos i les dades que s'hi veuen són il·lustratius. Si un rètol de la maqueta contradiu aquesta SPEC, mana la SPEC: l'organització no és L4 ni un ERP, una línia no és L2, un tipus de sistema no assigna funcions ni zona, i un abast compartit no crea un flux.

### 13.1 Què es tanca i què es deixa

| AC | PR B |
| --- | --- |
| AC-01 | Tancat a la UI: alta, edició i baixa d'organització, planta, àrea, línia i màquina, amb nom i icona, missatge al camp, i ID estable en reanomenar. |
| AC-02 | Tancat a la UI: alta d'ERP o MES amb abast a dues plantes o línies i funcions independents. Editar l'abast no canvia cap `parentId`. L'organització no mostra selector L0–L4 ni conversió a ERP. |
| AC-03 | Tancat a la UI: abans d'eliminar amb fills, abasts o fluxos es mostren les dependències i cal confirmar. Cancel·lar no escriu. No queden orfes actius. Els snapshots i els registres OEE no s'esborren. |
| AC-04 | Tancat: a 1280 × 800 l'arbre, el mapa IT/OT amb la franja L3 explicada i l'inspector es veuen alhora. Canviar la selecció no canvia la planta ni l'esquema actius. |
| AC-05 | Diferit a la PR C. El model ja impedeix que la icona assigni funcions o fluxos. La PR B no aplica plantilles. |
| AC-06 | Tancat el flux manual: origen i destí vàlids, dades, protocol o desconegut, finalitat i estat explícit `suggested` o `confirmed`. Confirmar és una acció sobre aquell flux. Descartar l'elimina amb les regles d'AC-03. No hi ha suggeriments automàtics ni lectura de xarxa. La descoberta assistida queda a la PR C. |
| AC-07 | Parcial: l'exemple alimentari s'obre al mapa sense empresa = L4 ni línia = L2. La planta i l'esquema actius es conserven. Crear, copiar o restaurar esquemes múltiples queda a la PR C. Si el document ja en té més d'un, un selector canvia l'actiu sense crear-ne ni restaurar-ne. |
| AC-08 | Es conserva. L'espai nou mostra els mateixos textos de desament. Una edició del mapa nou escriu el document d'IndexedDB. |
| AC-09, AC-10 | Es conserven. La còpia exportada inclou el treball canònic vigent i els textos legacy de la secció 13.2. |
| AC-11 | Diferit a la PR C. La barra mostra el recompte d'instantànies. No hi ha botó de crear ni de restaurar. |
| AC-12…AC-18 | Diferits a les PR D i E. El calculador US-1 es conserva i s'obre des de l'espai. No es pinten indicadors inventats. |
| AC-19 | Es conserva i s'estén amb la reconciliació de la secció 13.2. Cap nivell antic es promou. |
| AC-20 | Tancat per a l'espai de treball: 360 px amb arbre i inspector desplegables, formularis en una columna, zoom, desplaçament i enquadrament del mapa, teclat per seleccionar, editar, confirmar i cancel·lar, focus visible, objectius de 48 dp i estat amb text. |
| AC-21 | Parcial d'aquesta PR: anàlisi, tests, build web i Chrome real de l'abast B. La passada integrada d'R6 continua fora. |

Fora de la PR B: plantilles, suggeriments assistits, gestió de múltiples esquemes, snapshots editables, restauració, motor OEE de la secció 5, històric i filtres, agregació, PDF, backend i qualsevol lectura de la xarxa. La SPEC sencera no queda tancada.

### 13.2 Reconciliació no destructiva del legacy

El mapa antic deixa d'estar muntat quan hi ha repositori de workspace. L'app no el torna a escriure. La clau `mapaisa95oee.plant.v1` continua sense `setString`, `remove` ni `clear`.

El document `formatVersion` 1 guanya dos camps opcionals. Si no hi són, valen `null`. No és una versió nova de format: les còpies de la PR A es continuen llegint.

| Camp | Sentit |
| --- | --- |
| `legacyRaw` | Text original capturat. Un cop té valor, no es substitueix. |
| `latestLegacyRaw` | Darrer text de la clau diferent de l'original. `null` si encara no n'hi ha hagut. |
| `reconciledLegacyRaw` | Darrer text legacy que ja s'ha intentat reconciliar amb èxit de projecció. No forma part del diagrama de la secció 2.4 perquè només evita repetir la fusió; la còpia el conserva perquè la represa sigui estable. |

En obrir, si ja hi ha `workspace`:

1. Si la clau és buida, igual a `legacyRaw` sense cap reconciliació prèvia, o igual a `reconciledLegacyRaw`, no es torna a projectar.
2. Si el text nou no passa `migrateLegacyPlant`, no es canvien entitats, snapshots ni OEE. Es desa el text a `latestLegacyRaw`. L'estat visible és error, no `Desat`. L'original es conserva.
3. Si el text és projectable, es fusiona sobre una còpia del workspace. No es substitueix el document.
4. La projecció només aporta organitzacions i actius físics, amb funcions buides i icona del tipus físic. No crea sistemes, fluxos, esquemes, versions ni registres OEE. No escriu `functions`, tipus ni zona a partir de `functionalLevel`. `promoted` continua sent `false`.
5. Un ID nou s'afegeix amb la jerarquia estricta. Si el pare no existeix o no és compatible, no s'afegeix i no queda un orfe actiu.
6. Un ID que ja existeix com a organització o actiu del mateix paper només rep nom, descripció o pare nous si el valor canònic encara és el de la línia base (`reconciledLegacyRaw` o, si no n'hi ha, `legacyRaw`). Si el model canònic ja ha divergit, es conserva el valor canònic. Funcions, icones, sistemes, fluxos i abasts canònics no es toquen.
7. Un ID ocupat per una entitat d'un altre paper no es reescriu.
8. Una absència al legacy nou no esborra res del model canònic.
9. `nextIdCounter` no baixa.
10. Les llistes de sistemes, fluxos, esquemes, versions i registres OEE queden les mateixes. El JSON d'instantànies i el d'OEE, abans i després, coincideixen.
11. `legacyRaw` passa a ser el text només quan encara era `null` i la projecció és vàlida. Aquest primer text és l'original recuperable, també si la clau ha aparegut després d'un primer arrencada buit.
12. La còpia descarregada inclou les entitats ja reconciliades, `legacyRaw` i `latestLegacyRaw`. Reimportar-la restitueix aquest treball. `priorBackup` d'una substitució anterior no s'escriu durant la reconciliació.

La pantalla `Dades locals` descarrega l'original i, quan existeix, el text més recent. El mapa nou desa a IndexedDB. L'exportació posterior conté aquest desament.

### 13.3 Espai de treball

Estètica compacta industrial: rail antracita, panells d'acer i fons clar, accents discrets, contrast de text, icones amb etiqueta. A 1280 × 800 es veuen alhora l'arbre contextual, el mapa i l'inspector. La barra baixa té els controls del mapa, el recompte d'instantànies i l'estat de desament amb text.

L'arbre és la jerarquia física més una llista de sistemes que no pengen de cap màquina. El mapa separa IT, la franja L3 i OT. La franja diu que és una convenció visual i que no classifica un MES ni cap producte. La posició d'un sistema surt de la zona declarada. Les funcions es llegeixen a l'etiqueta de la fitxa. Un sistema amb funcions L2 i L3 i zona IT roman a IT. Els actius no es col·loquen en un nivell pel seu tipus. Un actiu només entra al mapa si un flux el cita, en una franja que no és un nivell ISA-95.

L'inspector edita la selecció en una columna: nom, descripció, icona, pare, funcions quan l'entitat les admet, abast, zona i fluxos. Els errors de nom buit, pare incompatible, cicle, extrem invàlid i protocol buit es mostren al camp. Els controls nous fan com a mínim 48 × 48 dp.

A menys de 1100 px, i en concret a 360 px, l'arbre i l'inspector són panells que s'obren i es tanquen. El mapa continua muntat. Els formularis segueixen en una columna. El mapa es pot apropar, allunyar, desplaçar i enquadrar sense que arrossegar sigui l'única via. La selecció, l'edició, la confirmació i la cancel·lació es poden fer amb teclat. El focus es veu. Suggerit, confirmat, desat i error es llegeixen per text.

Seleccionar una línia o un sistema no canvia la planta ni l'esquema actius. No cal una planta sencera per crear el primer element. El primer esquema existent, si n'hi ha, rep les altes noves perquè el mapa les pugui mostrar. Això no obre l'editor d'esquemes de la PR C.

## 14. PR C — plantilles, suggeriments, esquemes, versions i còpia

Aquesta secció és el contracte de la PR C. No afegeix requisits de producte ni reobre la secció 8. Tanca el que les seccions 11 i 13 deixaven per a C, i fa visible a l'espai de treball la substitució completa que la PR A ja validava. Es conserva la UI compacta de la PR B, la reconciliació legacy de la secció 13.2 i la separació entre snapshots i OEE. No hi ha backend ni lectura de xarxa.

### 14.1 Què es tanca i què es deixa

| AC | PR C |
| --- | --- |
| AC-05 | Tancat. Abans d'aplicar una plantilla es mostren les màquines i les icones. La màquina creada des d'una línia només en rep el pare. Ni la plantilla ni un canvi d'icona assignen funcions ni fluxos confirmats. |
| AC-06 | El flux manual de la PR B es conserva i es torna a comprovar al navegador. S'hi afegeix la part assistida: cada suggeriment es veu com a suggeriment, es descarta sol i només entra al model amb una confirmació explícita d'aquell suggeriment. Cap exploració de xarxa. Un abast compartit no crea un flux. |
| AC-07 | Tancat a la UI. Es poden crear, copiar, desar i tornar a obrir diversos esquemes i plantes. La disposició desada es recupera. La planta i la selecció visibles pertanyen a l'esquema obert. L'exemple alimentari continua sense empresa = L4 ni línia = L2. |
| AC-08 | Es conserva. Esquemes, versions i OEE surten d'IndexedDB en recarregar. |
| AC-09, AC-10 | Es conserven i es comproven de nou, també des de l'espai. La substitució és sencera: prevalidació, impacte, confirmació, còpia prèvia, i cap base parcial si es cancel·la, si el JSON és invàlid o si la transacció falla. |
| AC-11 | Tancat. Una instantània manual té data i nota. Restaurar-la afegeix una versió nova que referencia l'origen, amb el mateix snapshot. No sobreescriu versions anteriors, ni els mestres vigents, ni l'OEE. |
| AC-01…AC-04, AC-19 | Es conserven. Aquesta PR no els reobre. |
| AC-12…AC-18 | Diferits a les PR D i E. El calculador US-1 es conserva. No es calculen indicadors nous. |
| AC-20 | Parcial: els controls nous d'aquesta PR fan 48 dp, es poden operar amb teclat, el focus es veu i a 360 px no es retallen. La passada integrada continua fora. |
| AC-21 | Parcial d'aquesta PR: anàlisi, tests, build web i Chrome real de l'abast C, inclòs el flux manual. La passada integrada d'R6 continua fora. |

Fora de la PR C: el motor OEE de la secció 5, l'històric i els filtres, l'agregació, el PDF, el backend, la descoberta de xarxa, la purga de versions i una closca offline. La SPEC sencera no queda tancada.

### 14.2 Plantilles i màquina de línia

El catàleg és tancat i només descriu màquines. No té funcions, zona, tipus de sistema ni fluxos.

| Id | Nom | Màquines i icona |
| --- | --- | --- |
| `envasat` | Envasat | Omplidora, icona `machine`. Taponadora, icona `machine`. |
| `cambra` | Cambra | Sensor de temperatura, icona `machine`. |

Amb una línia seleccionada, `Aplica una plantilla` obre la previsualització: nom de cada màquina i la seva icona. `Cancel·la` no escriu. `Aplica plantilla` crea aquelles màquines amb pare la línia, les funcions buides i cap flux. Els IDs són nous. Si la línia ja té funcions, no es copien.

Crear una màquina des de l'alta existent, amb una línia com a pare, també hereta només la pertinença. Les funcions queden les que l'usuari marca, inicialment cap. Canviar la icona d'una màquina o d'un sistema no canvia les funcions, la zona, el tipus ni els fluxos.

### 14.3 Suggeriments assistits

`Suggereix relacions` calcula, sense escriure, parelles ja declarades: un sistema i un actiu del seu `scopeIds`. Si hi ha un esquema actiu, la parella ha de pertànyer a aquest esquema. No es proposa un flux entre dos sistemes pel fet de compartir abast. No es proposa una parella que ja té un flux amb el mateix origen i destí. El càlcul no obre sockets ni llegeix la xarxa.

Cada fila diu `Suggeriment`, mostra origen i destí, i té `Descarta` i `Confirma`. Descartar treu només aquella fila i no escriu. Confirmar obre el formulari d'aquell flux, amb dades, protocol o desconegut i finalitat. Acceptar-lo crea un sol flux `confirmed`. Cancel·lar el formulari no crea el flux. No hi ha confirmació massiva. Fins que no s'accepta un suggeriment, el document no guanya fluxos.

### 14.4 Esquemes múltiples

`Nou esquema` demana nom i plantes. El nom buit es rebutja. L'esquema inclou les plantes triades, els actius descendents i els sistemes que abasten algun d'aquests actius. No copia fluxos ni funcions. La disposició inicial és una graella de pas 160. `Copia l'esquema` duplica pertinença i disposició amb un ID nou. No duplica versions ni OEE.

L'ordre de les fitxes dins de cada franja IT, L3, OT o no definida segueix la disposició de l'esquema actiu. Les franges i el text que explica L3 es conserven. Editar la disposició d'un element seleccionat només canvia el punt `x`, `y` d'aquell ID a l'esquema actiu.

Canviar d'esquema restaura la planta i la selecció que aquell esquema tenia en la sessió, si encara en formen part. Si no, la planta visible és una planta de l'esquema i la selecció no queda en un element de l'altre. Després de recarregar, s'obre un esquema desat i la disposició és la del document. La selecció inicial és d'aquest esquema.

### 14.5 Instantànies i restauració

`Nova instantània` mostra la data UTC que es desarà i un camp de nota. La nota pot ser buida. Cancel·lar no escriu. Confirmar afegeix una versió: `createdAt` és aquesta data, `parentVersionId` és `null`, `schemaId` és l'esquema actiu. El snapshot copia l'esquema i el tancament necessari perquè es validi sol: organitzacions pare, actius citats amb els seus avantpassats, sistemes citats o extrems, i fluxos citats. No conté OEE, revisions ni versions. Els mestres vius no es modifiquen. Les versions ja existents queden iguals.

`Restaura` mostra la data d'origen, la nota nova, l'ID d'origen i un informe de reconciliació: IDs capturats absents de l'inventari, i IDs presents amb nom, pare, funcions, abast, extrems o disposició diferents. L'informe no escriu. Cancel·lar no escriu. Confirmar afegeix una versió nova. El seu `parentVersionId` és l'ID d'origen. El snapshot nou és el mateix contingut que el d'origen. Les versions anteriors, els mestres, els esquemes i l'OEE queden com eren. No hi ha botó que copiï el snapshot sobre l'inventari.

### 14.6 Substitució completa

L'espai ofereix `Exporta còpia` i `Importa còpia`, amb el mateix repositori que `Dades locals`. `formatVersion` continua sent 1.

Abans d'escriure es valida el conjunt: JSON, versió, dominis, jerarquia, abasts, extrems de flux, IDs duplicats, orfes, cicles de jerarquia i cicles de versions. Un cicle de flux és vàlid. Si hi ha incidències, es mostra el missatge i no s'obre la substitució.

Si és vàlid, es mostren els recomptes d'entrada, el text que la substitució no fusiona identificadors, i els botons `Descarrega la còpia prèvia`, `Cancel·la` i `Substitueix les dades`. Cancel·lar no escriu. Confirmar escriu el document nou i la còpia prèvia en una sola transacció. Si la transacció falla, es conserva el document anterior i l'estat no és `Desat`. Una quota real del navegador només es reporta si es reprodueix. La fallada injectada a la base en memòria continua sent la prova d'interrupció.
