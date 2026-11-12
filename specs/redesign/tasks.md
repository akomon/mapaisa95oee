# Tasques: fonament del replantejament (PR A)

Extretes de [spec.md](spec.md). La spec es commita abans de qualsevol codi. Les PR B, C, D i E no formen part d'aquesta llista executable.

## T0 — Spec

- [x] Crear `specs/redesign/spec.md`, `plan.md` i `tasks.md` amb la font canònica, l'aprovació posterior, AC-01…AC-21, les sis històries, les dependències i la línia base inspeccionada.
- [x] Commit de la spec abans del codi.

## T1 — Model i fixture

- [x] Entitats, jerarquia estricta, sistemes, fluxos, esquemes, versions i registres OEE separats.
- [x] Rebuig de nom buit, pare incompatible, cicle i funcions sobre l'organització.
- [x] IDs estables, abast que no mou actius, eliminació amb confirmació i sense orfes actius.
- [x] `foodIndustryExample()` sense empresa = L4 ni línia = L2.
- [x] Tests de model.

## T2 — Còpia versionada

- [x] `formatVersion` 1, anada i tornada de totes les col·leccions.
- [x] Rebuig de JSON invàlid, versió desconeguda, legacy v1, IDs duplicats, orfes i cicles de jerarquia.
- [x] Acceptació d'un cicle de flux.
- [x] Editar un mestre no muta snapshots ni registres OEE.

## T3 — Migració

- [x] Funció pura sobre una còpia del JSON antic.
- [x] Projecció física de la secció 6.2, revisions `promoted: false`, cap sistema inventat.
- [x] Legacy il·legible: cap document aplicat.
- [x] El repositori no rep un escriptor de la clau `mapaisa95oee.plant.v1`.

## T4 — IndexedDB i pantalla

- [x] Base `mapaisa95oee` versió 1, magatzem `kv`, transacció única.
- [x] Estats Desant… / Desat / error, sense èxit si la transacció falla.
- [x] Substitució amb impacte, confirmació, còpia prèvia i cancel·lació.
- [x] Pantalla `Dades locals`, 48 dp i 360 px, sense retirar el calculador ni el mapa.
- [x] `flutter analyze`, `flutter test` i `flutter build web`.
- [x] Comprovació real al navegador de l'abast d'aquesta PR.

## Fora d'aquesta PR

- [x] PR B: espai de treball, inventari, mapa IT/OT i fluxos manuals. El detall executable és la llista següent.
- [ ] PR C: plantilles, suggeriments, esquemes múltiples a la UI, snapshots i restauració (AC-11).
- [ ] PR D: motor OEE de la secció 5.
- [ ] PR E: històric i filtres.
- [ ] QA integrada d'R6.

# Tasques: espai de treball (PR B)

Extretes de [spec.md](spec.md), secció 13. Aquesta actualització es commita abans del codi de la PR B.

## T5 — Spec de la PR B

- [x] Afegir a `specs/redesign/` la traça de B, el contracte de reconciliació i el que queda diferit.
- [x] Commit de la spec abans del codi de l'espai.

## T6 — Reconciliació legacy

- [x] Camp opcionals `latestLegacyRaw` i `reconciledLegacyRaw`, sense pujar `formatVersion`.
- [x] Fusió física no destructiva: sense promoció, sense orfes, sense tocar snapshots ni OEE.
- [x] Clau apareguda després del primer arrencada, clau divergent i clau il·legible.
- [x] La còpia rodona inclou el treball canònic, l'original i el text més recent.
- [x] Cap escriptura de `mapaisa95oee.plant.v1`.

## T7 — Inventari, mapa i fluxos manuals

- [x] Arbre, mapa IT/OT amb franja L3 explicada, inspector i barra, visibles alhora a 1280 × 800.
- [x] CRUD amb missatge al camp, ID estable, pare incompatible, cicle i confirmació d'esborrat.
- [x] ERP o MES amb abast doble; l'organització sense selector L0–L4.
- [x] Flux manual amb extrems, dades, protocol o desconegut, finalitat i estat explícit. Cap flux inventat des de l'abast.
- [x] Exemple alimentari sense empresa = L4 ni línia = L2.
- [x] 360 px, teclat, focus visible, 48 dp i estat amb text.
- [x] `flutter analyze`, `flutter test`, `flutter build web` i Chrome real.

## Fora de la PR B

- [ ] PR C: plantilles, suggeriments assistits, esquemes múltiples i restauració.
- [ ] PR D: motor OEE de la secció 5.
- [ ] PR E: històric i filtres.
- [ ] QA integrada d'R6.

A partir d'aquí, el detall executable de les PR C, D, E i la QA final. Aquestes llistes deriven de [spec.md](spec.md) i no afegeixen requisits: si una decisió no hi és, es tanca a la SPEC abans del codi o no s'implementa.

# Tasques: plantilles, suggeriments, esquemes i versions (PR C)

Extretes de [spec.md](spec.md), seccions 3, 4, 6 i 13. La spec es commita abans de qualsevol codi.

## T8 — Spec de la PR C

- [ ] Afegir a `specs/redesign/` la traça de C i confirmar que aquesta llista no afegeix requisits a les seccions 3, 4, 6 i 13.
- [ ] Tancar a la SPEC, abans del codi, el contingut de les plantilles i l'origen dels suggeriments assistits. Si no es tanquen, no s'inventa cap generador ni cap plantilla.
- [ ] Commit de la spec abans del codi de la PR C.

## T9 — Plantilles (AC-05)

- [ ] Model de plantilla que només descriu màquines i icones a crear; cap funció, zona, abast ni flux.
- [ ] Previsualització abans d'aplicar amb les màquines i les icones que es crearan.
- [ ] En aplicar la plantilla des d'una línia, la màquina creada només n'hereta la pertinença; el pare és la línia.
- [ ] Tests: la plantilla no assigna funcions, zona ni fluxos confirmats; canviar la icona no canvia el tipus ni les funcions.

## T10 — Suggeriments assistits (AC-06)

- [ ] Contracte de suggeriment amb origen, destí, dades, protocol o desconegut, finalitat i estat `suggested`.
- [ ] Cada suggeriment es mostra com a suggeriment i es pot descartar; descartar elimina amb les regles d'AC-03.
- [ ] Confirmar és una acció individual sobre aquell flux; no hi ha confirmació en bloc.
- [ ] Cap lectura de xarxa ni flux derivat d'un abast compartit; cap suggeriment automàtic si la SPEC no n'ha tancat l'origen.
- [ ] Tests: un suggeriment no confirmat no compta com a confirmat i confirmar-ne un no en confirma d'altres.

## T11 — Esquemes múltiples (AC-07)

- [ ] Crear un esquema amb nom, plantes, actius, sistemes, fluxos i disposició.
- [ ] Copiar un esquema existent amb la seva disposició i referències, amb ID nou.
- [ ] Obrir i canviar l'esquema i la planta actius conservant la selecció contextual; el selector existent no crea ni restaura res.
- [ ] La disposició només cita IDs de l'esquema i coordenades finites; un esquema pot no contenir tota la planta.
- [ ] Tests: crear i copiar, canvi d'esquema, selecció coherent i cap duplicació de l'ERP compartit.

## T12 — Instantànies i restauració (AC-11)

- [ ] Crear una instantània manual amb data, nota i `parentVersionId`; snapshot autocontingut amb esquema, organitzacions, actius, sistemes i fluxos.
- [ ] El snapshot no inclou registres OEE, revisions de migració ni versions; la cadena de versions no té cicles.
- [ ] Restaurar genera una versió nova que referencia l'origen, conserva els IDs capturats i no sobreescriu versions ni mestres actuals.
- [ ] Mostrar i confirmar la reconciliació amb l'inventari vigent; no deduir-la en silenci.
- [ ] Els registres OEE i els snapshots previs queden intactes; avisos d'espai i de quota sense purga automàtica.
- [ ] Tests: anada i tornada del snapshot, restauració, cicle de versions, mestre retirat i OEE intacte.

## Fet quan

- [ ] `flutter analyze`, `flutter test` i `flutter build web` en verd.
- [ ] Chrome real a 1280 × 800 i a 360 px: plantilla, suggeriment, esquemes múltiples, crear i restaurar versió, desar i recarregar.
- [ ] PR C petita cap a `main` que tanca AC-05, AC-06 (descoberta), AC-07 (múltiples esquemes) i AC-11, i enllaça aquesta carpeta.

# Tasques: motor OEE (PR D)

Extretes de [spec.md](spec.md), secció 5. La spec es commita abans de qualsevol codi.

## T13 — Spec de la PR D

- [ ] Afegir a `specs/redesign/` la traça de D i confirmar que aquesta llista no afegeix requisits a la secció 5.
- [ ] Commit de la spec abans del codi de la PR D.

## T14 — Motor pur `oee.v1`

- [ ] Mòdul pur sense Flutter: normalitza a segons, `O = P − S`, `c = 1/v`, `D = O/P`, `R = cN/O`, `Q = G/N`, `OEE = cG/P`.
- [ ] Domini: `P > 0`, `0 ≤ S ≤ P`, `c > 0`, `v > 0`, `N` i `G` enters, `0 ≤ G ≤ N`.
- [ ] Sense arrodoniment intern; tolerància relativa `1e-9` només per a conversions i residus de coma flotant.
- [ ] Versió de fórmula explícita `oee.v1`; qualsevol canvi de fórmula porta una versió nova.
- [ ] Tests de tots els casos de la taula de la secció 5.

## T15 — Unitats i conversions (AC-12, AC-13)

- [ ] Acceptar velocitat en `secondsPerUnit` i `unitsPerSecond`; `c` canònic surt del valor original.
- [ ] Canviar d'unitat no encadena arrodoniments; conversions repetides mantenen `c` i els resultats dins la tolerància.
- [ ] Tests de `0,4 s/u` ↔ `2,5 u/s` i del cas `P = 1 min`, `S = 0`, `N = 100`, `G = 90`.

## T16 — Estats, errors i pastís (AC-14, AC-15)

- [ ] Cobrir els estats: referència, `N = 0` i `O > 0`, `O = 0` i `N = 0`, `O = 0` i `N > 0` inconsistent, `R > 1`, i errors `P = 0`, `S > P`, `c ≤ 0`, `v ≤ 0`, `G > N`, `N` negatiu o fraccionari.
- [ ] Cap divisió per zero ni retall silenciós al 100 %; cada error identifica el camp.
- [ ] Pastís: productiu `cG`, disponibilitat `S`, rendiment `O − cN`, qualitat `c(N − G)`, total `P`; unitat i valors visibles.
- [ ] No pintar porcions negatives ni un pastís aparentment vàlid amb dades inconsistents o `R > 1`.
- [ ] Mai representar `D + R + Q` com a suma; llegenda i tooltip expliquen la conversió d'unitats a temps ideal.
- [ ] Tests de residus de coma flotant i del residu estrictament numèric.

## T17 — Formulari i resultats

- [ ] Formulari amb P i S en minuts, N i G enters, velocitat i unitat; decimals amb coma o punt.
- [ ] Rebutjar buits obligatoris, `NaN`, infinits, comptatges fraccionaris i separadors de milers ambigus.
- [ ] Mostrar OEE, disponibilitat, rendiment i qualitat separats, amb errors i factors indefinits explicats.
- [ ] `R > 1` permet desar esborrany i bloqueja la validació fins a corregir-lo; no es capa el factor.
- [ ] En desar, congelar `c`, velocitat i unitat originals, noms de línia i planta, estat i `formulaVersion` `oee.v1`.
- [ ] Substituir el calculador visible de la US-1 pel motor nou i mantenir l'accés des de l'espai.
- [ ] Cap agregació ni mitjana de D, R o Q a l'MVP.
- [ ] 48 dp, 360 px, etiquetes visibles i estat amb text.
- [ ] Tests de widget i d'integració amb els casos de la secció 5.

## Fet quan

- [ ] `flutter analyze`, `flutter test` i `flutter build web` en verd.
- [ ] Chrome real a 1280 × 800 i a 360 px: casos de referència, conversió, errors, `R > 1` i pastís.
- [ ] PR D petita cap a `main` que tanca AC-12, AC-13, AC-14 i AC-15, i enllaça aquesta carpeta.

# Tasques: històric i filtres (PR E)

Extretes de [spec.md](spec.md), seccions 5, 8 i 13. La spec es commita abans de qualsevol codi.

## T18 — Spec de la PR E

- [ ] Afegir a `specs/redesign/` la traça de E i confirmar que aquesta llista no afegeix requisits a les decisions de la secció 8.
- [ ] Commit de la spec abans del codi de la PR E.

## T19 — Captura i registre congelat (AC-16)

- [ ] Desar registre amb data de producció `YYYY-MM-DD`, torn, línia, article, lot opcional, P, S, N, G, velocitat original i unitat, `c` congelat, estat i versió de fórmula.
- [ ] Lot buit es normalitza a `null`; les dates de creació i modificació són UTC i diferents de la data de producció.
- [ ] Capturar els noms de línia i planta en desar; reanomenar la línia o canviar la velocitat mestra no altera el registre.
- [ ] Tests de captura i d'immutabilitat en reanomenar o canviar el mestre.

## T20 — Consulta i filtres (AC-17)

- [ ] Històric amb filtres per dates, torn, línia, article i lot.
- [ ] Per defecte només registres validats; control explícit per incloure esborranys.
- [ ] Obrir un registre mostra les entrades, l'estat, els quatre indicadors i un pastís vàlid; sense lot continua sent desable i filtrable.
- [ ] Cap mitjana simple de percentatges ni agregació de factors; només indicadors per registre.
- [ ] Tests de filtres, de lot `null` i d'exclusió d'esborranys.

## T21 — Esborrany, validat i revisions (AC-18)

- [ ] Distingir esborrany i validat pel text, no només pel color.
- [ ] Un registre validat és immutable; corregir-lo crea una revisió que el substitueix a la vista i conserva l'anterior.
- [ ] `R > 1` no es pot validar; un esborrany sí que es pot desar.
- [ ] Tests de revisió, d'immutabilitat i d'exclusió de l'anterior a la vista.
- [ ] La persistència i la còpia inclouen historial i revisions sense alterar els snapshots d'arquitectura.

## Fet quan

- [ ] `flutter analyze`, `flutter test` i `flutter build web` en verd.
- [ ] Chrome real a 1280 × 800 i a 360 px: desar, filtrar, obrir, validar, corregir i recarregar.
- [ ] PR E petita cap a `main` que tanca AC-16, AC-17 i AC-18, i enllaça aquesta carpeta.

# Tasques: QA integrada d'R6

Extretes de [spec.md](spec.md), seccions 4, 9 i 11. És la passada final, no una PR de producte.

## T22 — Accessibilitat i responsiu (AC-20)

- [ ] A 360 px i en escriptori, formularis, històrics i accions sense retalls; mapa amb zoom, desplaçament i enquadrament.
- [ ] Teclat per seleccionar, editar, confirmar i cancel·lar a totes les pantalles noves; focus visible.
- [ ] Etiquetes accessibles; estat suggerit, confirmat, desat i error llegit per text i no només pel color.
- [ ] Objectius ≥ 48 × 48 dp i controls del mapa operables sense arrossegar com a única via.
- [ ] Tests de widget o d'accessibilitat i comprovació manual a 360 px.

## T23 — Proves i evidència (AC-21)

- [ ] Executar unitaris, de persistència, d'importació, de restauració, d'OEE i d'historial; `flutter analyze`, `flutter test` i `flutter build web`.
- [ ] Chrome real: recàrrega, import invàlid, substitució, restauració, historial, teclat i 360 px.
- [ ] Aportar sortides d'anàlisi i de tests, i evidència visual de 1280 × 800 i de 360 px.
- [ ] Verificar que l'exemple no presenta empresa = L4/ERP ni jerarquia = nivells, i que no es pinten indicadors inventats.

## T24 — Tancament

- [ ] Recórrer AC-01…AC-21 i confirmar que totes tenen prova o evidència; actualitzar la taula de traçabilitat.
- [ ] Marcar a `tasks.md` les caselles de C, D, E i QA.
- [ ] PR de QA final enllaçada a aquesta carpeta.
