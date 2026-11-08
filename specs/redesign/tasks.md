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

- [ ] Camp opcionals `latestLegacyRaw` i `reconciledLegacyRaw`, sense pujar `formatVersion`.
- [ ] Fusió física no destructiva: sense promoció, sense orfes, sense tocar snapshots ni OEE.
- [ ] Clau apareguda després del primer arrencada, clau divergent i clau il·legible.
- [ ] La còpia rodona inclou el treball canònic, l'original i el text més recent.
- [ ] Cap escriptura de `mapaisa95oee.plant.v1`.

## T7 — Inventari, mapa i fluxos manuals

- [ ] Arbre, mapa IT/OT amb franja L3 explicada, inspector i barra, visibles alhora a 1280 × 800.
- [ ] CRUD amb missatge al camp, ID estable, pare incompatible, cicle i confirmació d'esborrat.
- [ ] ERP o MES amb abast doble; l'organització sense selector L0–L4.
- [ ] Flux manual amb extrems, dades, protocol o desconegut, finalitat i estat explícit. Cap flux inventat des de l'abast.
- [ ] Exemple alimentari sense empresa = L4 ni línia = L2.
- [ ] 360 px, teclat, focus visible, 48 dp i estat amb text.
- [ ] `flutter analyze`, `flutter test`, `flutter build web` i Chrome real.

## Fora de la PR B

- [ ] PR C: plantilles, suggeriments assistits, esquemes múltiples i restauració.
- [ ] PR D: motor OEE de la secció 5.
- [ ] PR E: històric i filtres.
- [ ] QA integrada d'R6.
