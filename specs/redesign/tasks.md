# Tasques: fonament del replantejament (PR A)

Extretes de [spec.md](spec.md). La spec es commita abans de qualsevol codi. Les PR B, C, D i E no formen part d'aquesta llista executable.

## T0 — Spec

- [x] Crear `specs/redesign/spec.md`, `plan.md` i `tasks.md` amb la font canònica, l'aprovació posterior, AC-01…AC-21, les sis històries, les dependències i la línia base inspeccionada.
- [x] Commit de la spec abans del codi.

## T1 — Model i fixture

- [ ] Entitats, jerarquia estricta, sistemes, fluxos, esquemes, versions i registres OEE separats.
- [ ] Rebuig de nom buit, pare incompatible, cicle i funcions sobre l'organització.
- [ ] IDs estables, abast que no mou actius, eliminació amb confirmació i sense orfes actius.
- [ ] `foodIndustryExample()` sense empresa = L4 ni línia = L2.
- [ ] Tests de model.

## T2 — Còpia versionada

- [ ] `formatVersion` 1, anada i tornada de totes les col·leccions.
- [ ] Rebuig de JSON invàlid, versió desconeguda, legacy v1, IDs duplicats, orfes i cicles de jerarquia.
- [ ] Acceptació d'un cicle de flux.
- [ ] Editar un mestre no muta snapshots ni registres OEE.

## T3 — Migració

- [ ] Funció pura sobre una còpia del JSON antic.
- [ ] Projecció física de la secció 6.2, revisions `promoted: false`, cap sistema inventat.
- [ ] Legacy il·legible: cap document aplicat.
- [ ] El repositori no rep un escriptor de la clau `mapaisa95oee.plant.v1`.

## T4 — IndexedDB i pantalla

- [ ] Base `mapaisa95oee` versió 1, magatzem `kv`, transacció única.
- [ ] Estats Desant… / Desat / error, sense èxit si la transacció falla.
- [ ] Substitució amb impacte, confirmació, còpia prèvia i cancel·lació.
- [ ] Pantalla `Dades locals`, 48 dp i 360 px, sense retirar el calculador ni el mapa.
- [ ] `flutter analyze`, `flutter test` i `flutter build web`.
- [ ] Comprovació real al navegador de l'abast d'aquesta PR.

## Fora d'aquesta PR

- [ ] PR B: espai de treball, inventari, mapa IT/OT i fluxos manuals.
- [ ] PR C: plantilles, suggeriments, esquemes múltiples a la UI, snapshots i restauració (AC-11).
- [ ] PR D: motor OEE de la secció 5.
- [ ] PR E: històric i filtres.
- [ ] QA integrada d'R6.
