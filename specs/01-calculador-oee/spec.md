# US-1: Calculador OEE

Font: issue [#1](https://github.com/akomon/mapaisa95oee/issues/1). Els criteris d'acceptació ja estan tancats. Aquest document els fixa perquè el codi i els tests els segueixin sense reinterpretar-los.

## Objectiu

Com a responsable de producció, introduir les dades d'un torn i obtenir l'OEE i els seus tres factors per saber on es perd eficiència.

## Abast

Dins:

- Aplicació Flutter Web, només client. Sense backend i sense persistència.
- Lògica pura a `lib/oee_calculator.dart`. La UI no calcula; només parseja, crida la lògica i mostra el resultat.
- Formulari en viu (sense botó de càlcul), validacions, avís de rendiment i pèrdua principal.
- Tests unitaris del càlcul i tests de widget del formulari.

Fora (context MVP, no aquesta US):

- Mapa ISA-95.
- Dades locals.
- Exportació JSON o PDF.

## Camps

| Camp visible | Identificador | Unitat | Entrada |
| --- | --- | --- | --- |
| Temps planificat | `plannedMinutes` | minuts | decimal ≥ 0 |
| Temps de parades | `downtimeMinutes` | minuts | decimal ≥ 0 |
| Temps de cicle ideal | `idealCycleSeconds` | segons / unitat | decimal ≥ 0 |
| Unitats totals | `totalUnits` | unitats | decimal ≥ 0 |
| Unitats bones | `goodUnits` | unitats | decimal ≥ 0 |

El separador decimal acceptat és `.` o `,`. Els espais inicials i finals s'ignoren. Una cadena buida és una dada pendent, no un error.

## Fórmules

Temps operatiu (minuts) = `plannedMinutes − downtimeMinutes`.

Temps operatiu (segons) = temps operatiu (minuts) × 60.

El cicle ideal està en segons/unitat i les parades en minuts. El rendiment es divideix pel temps operatiu en segons perquè el factor sigui adimensional, tal com exigeixen les unitats del criteri 1 i la fórmula del criteri 2.

- Disponibilitat `D = (plannedMinutes − downtimeMinutes) / plannedMinutes`
- Rendiment `R = (idealCycleSeconds × totalUnits) / temps operatiu en segons`
- Qualitat `Q = goodUnits / totalUnits`
- `OEE = D × R × Q`

La lògica retorna els factors com a raons (1 = 100 %). `R` i l'OEE poden superar 1. No es capen.

### Presentació

El percentatge mostrat té 1 decimal, arrodonit half-away-from-zero (0,05 puja). Format exacte: `87.5 %` (punt decimal, espai abans del símbol). Es calcula sobre la raó amb `formatOeePercent`.

La comparació de pèrdua principal i l'avís de rendiment usen aquest percentatge ja arrodonit, perquè coincideixi amb el que es llegeix a la pantalla.

## Validació

Si hi ha qualsevol incidència, no hi ha resultat numèric. Les incidències es reporten totes, en aquest ordre estable:

| Codi | Quan | Missatge |
| --- | --- | --- |
| `invalidNumber` | El text no és un decimal | Introdueix un nombre vàlid. |
| `negativeValue` | Qualsevol valor < 0 | Els valors no poden ser negatius. |
| `goodExceedsTotal` | `goodUnits > totalUnits` (ambdós ≥ 0) | Les unitats bones no poden superar les unitats totals. |
| `downtimeExceedsPlanned` | `downtimeMinutes > plannedMinutes` (ambdós ≥ 0) | El temps de parades no pot superar el temps planificat. |
| `plannedTimeZero` | `plannedMinutes == 0` | El temps planificat ha de ser més gran que zero. |
| `operatingTimeZero` | temps operatiu == 0 i `plannedMinutes > 0` | El temps operatiu és zero; no es pot calcular el rendiment. |
| `totalUnitsZero` | `totalUnits == 0` | Les unitats totals han de ser més grans que zero. |

`negativeValue` és una sola incidència encara que hi hagi més d'un negatiu. Si hi ha un negatiu, no s'avaluen les comparacions ni les divisions: només `negativeValue`. El cicle ideal 0 és vàlid (`R = 0`).

Text buit en algun camp: estat incomplet, sense resultat. Missatge neutre: `Introdueix totes les dades del torn.` Si un altre camp ja té un nombre invàlid o negatiu, aquests missatges es mostren igualment.

## Avís de rendiment

Si el resultat és vàlid i el percentatge arrodonit de `R` és major que `100.0`, es mostra el resultat i l'avís:

`El rendiment supera el 100 %. Revisa el temps de cicle ideal.`

## Pèrdua principal

Entre D, R i Q, el factor (o factors) amb el percentatge arrodonit més baix és la pèrdua principal. Empats inclouen tots els factors empatats. Ordre fix dels noms: Disponibilitat, Rendiment, Qualitat.

| Factors | Text |
| --- | --- |
| Disponibilitat | Pèrdua principal: Disponibilitat. |
| Rendiment | Pèrdua principal: Rendiment. |
| Qualitat | Pèrdua principal: Qualitat. |
| Disponibilitat i Rendiment | Pèrdua principal: Disponibilitat i Rendiment. |
| Disponibilitat i Qualitat | Pèrdua principal: Disponibilitat i Qualitat. |
| Rendiment i Qualitat | Pèrdua principal: Rendiment i Qualitat. |
| Els tres | Pèrdua principal: Disponibilitat, Rendiment i Qualitat. |

## Interfície

- Títol: `Calculador OEE`.
- Cinc camps amb etiqueta visible, en l'ordre de la taula de camps. Sense botó de càlcul: cada canvi recalcula.
- Zona de resultat amb l'OEE destacat, els tres factors amb el seu percentatge, la pèrdua principal, les incidències i l'avís de rendiment.
- Objectius tàctils dels camps ≥ 48 dp (alçada del `TextField`).
- A 360 px d'amplada el contingut cap en una columna amb desplaçament, sense overflow. A escriptori el formulari es centra amb una amplada màxima de 640 px.
- Textos de la interfície en català, tal com els missatges d'aquesta spec.

## API de `lib/oee_calculator.dart`

- `enum OeeFactor { availability, performance, quality }`
- `enum OeeIssueCode { invalidNumber, negativeValue, goodExceedsTotal, downtimeExceedsPlanned, plannedTimeZero, operatingTimeZero, totalUnitsZero }`
- `class OeeInputs` amb els cinc doubles.
- `class OeeResult` amb `availability`, `performance`, `quality`, `oee`, `mainLosses` (`List<OeeFactor>` en l'ordre fix) i `performanceAboveIdeal`.
- `class OeeComputation` amb `result` nul si hi ha incidències, i `issues` en l'ordre de la taula.
- `OeeComputation calculateOee(OeeInputs inputs)`
- `double? parseOeeDecimal(String raw)` — buit → `null`; invàlid → llança `FormatException` o es tracta a la UI com `invalidNumber`. El càlcul pur rep doubles ja parsejats.
- `String formatOeePercent(double ratio)`
- `String oeeIssueMessage(OeeIssueCode code)`
- `String oeeFactorLabel(OeeFactor factor)`
- `String mainLossMessage(List<OeeFactor> factors)`

`parseOeeDecimal` retorna `null` només si, després de `trim`, la cadena és buida. Qualsevol altre text no numèric llança `FormatException`.

## Casos de referència

### Torn estàndard

Entrada: 480 min, 60 min, 60 s/unitat, 400 totals, 380 bones.

- Temps operatiu = 25200 s
- D = 420/480 = 87.5 %
- R = 24000/25200 = 95.2 %
- Q = 95.0 %
- OEE = 133/168 = 79.2 %
- Pèrdua principal: Disponibilitat
- Sense avís de rendiment

### Torn perfecte

Entrada: 100 min, 0 min, 60 s/unitat, 100 totals, 100 bones.

- D = R = Q = OEE = 100.0 %
- Pèrdua principal: Disponibilitat, Rendiment i Qualitat
- Sense avís

### Cicle ideal massa curt

Entrada: 60 min, 0 min, 30 s/unitat, 150 totals, 150 bones.

- D = 100.0 %, R = 125.0 %, Q = 100.0 %, OEE = 125.0 %
- Avís de rendiment
- Pèrdua principal: Disponibilitat i Qualitat

### Límits sense resultat

- Qualsevol negatiu → només `negativeValue`.
- Bones > totals → `goodExceedsTotal`.
- Parades > planificat → `downtimeExceedsPlanned`.
- Planificat 0 (i parades 0) → `plannedTimeZero`. Si les totals també són 0, s'hi afegeix `totalUnitsZero`. El temps operatiu 0 amb planificat 0 no afegeix `operatingTimeZero`.
- Planificat &gt; 0 i parades iguals al planificat → `operatingTimeZero`.
- Totals 0 i bones 0, amb la resta vàlida → `totalUnitsZero`.
- Cicle 0 amb la resta vàlida → resultat vàlid, R = 0.0 %, OEE = 0.0 %.
