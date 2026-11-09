# Tasques: fonament del replantejament (PR A)

Extretes de [spec.md](spec.md). La spec es commita abans de qualsevol codi. Les PR B, C, D i E no formen part d'aquesta llista executable. El detall de la PR D és [phase-d.md](phase-d.md), secció 15, i no reescriu les llistes de sota.

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
- [x] PR C: plantilles, suggeriments, esquemes múltiples, snapshots i restauració (AC-11). El detall executable és la llista de la PR C.
- [x] PR D: motor OEE de la secció 5. El detall executable és [phase-d.md](phase-d.md).
- [x] PR E: històric i filtres. El detall executable és [phase-e.md](phase-e.md).
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

- [x] PR C: plantilles, suggeriments assistits, esquemes múltiples, snapshots, restauració i substitució completa. El detall executable és la llista següent.
- [x] PR D: motor OEE de la secció 5. El detall executable és [phase-d.md](phase-d.md).
- [x] PR E: històric i filtres. El detall executable és [phase-e.md](phase-e.md).
- [ ] QA integrada d'R6.

# Tasques: plantilles, esquemes i versions (PR C)

Extretes de [spec.md](spec.md), secció 14. Aquesta actualització es commita abans del codi de la PR C.

## T8 — Spec de la PR C

- [x] Afegir a `specs/redesign/` la traça de C i el que queda diferit a D, E i la QA integrada.
- [x] Commit de la spec abans del codi.

## T9 — Plantilles i suggeriments

- [x] Catàleg `envasat` i `cambra`, previsualització de màquines i icones, alta que només hereta el pare.
- [x] Cap plantilla ni canvi d'icona assigna funcions o fluxos confirmats.
- [x] Suggeriments visibles, descart individual i confirmació individual. Cap flux creat des de l'abast sol. Cap xarxa.

## T10 — Esquemes, instantànies i còpia

- [x] Crear, copiar, desar i reobrir esquemes amb disposició i selecció contextual.
- [x] Instantània amb data i nota. Restauració que referencia l'origen, sense mutar versions prèvies, mestres ni OEE.
- [x] Substitució completa amb prevalidació, impacte, confirmació, còpia prèvia i cap base parcial.

## T11 — Verificació

- [x] Tests dels AC d'aquesta PR, inclòs el cicle de versions i el cicle de flux.
- [x] `flutter analyze`, `flutter test`, `flutter build web` i Chrome real, amb el flux manual de la PR B.
- [x] 360 px, teclat, focus visible i objectius de 48 dp.

## Fora de la PR C

- [x] PR D: motor OEE de la secció 5. El detall executable és [phase-d.md](phase-d.md).
- [x] PR E: històric i filtres. El detall executable és [phase-e.md](phase-e.md).
- [ ] QA integrada d'R6.
