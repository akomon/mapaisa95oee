# Tasques: Calculador OEE

Extretes de l'issue #1. La spec es commita abans de qualsevol codi.

## T0 — Spec

- [x] Crear `specs/01-calculador-oee/spec.md`, `plan.md` i `tasks.md`.
- [x] Commit de la spec abans del codi.

## T1 — Esquelet web

- [x] Projecte Flutter amb plataforma web habilitada.
- [x] Treure el comptador de demostració i deixar l'arrencada de `Calculador OEE`.
- [x] `flutter analyze` net sobre l'esquelet.

## T2 — Lògica i tests

- [x] `lib/oee_calculator.dart` amb la fórmula, les unitats i els textos de `spec.md`.
- [x] Tests unitaris: torn estàndard (79.2 %), torn perfecte, cicle massa curt (125 %), cicle 0, negatius, bones > totals, parades > planificat, planificat 0, temps operatiu 0, totals 0, parseig i format.

## T3 — Formulari i resultat

- [x] Cinc camps en l'ordre de la spec, etiquetes visibles, sense botó.
- [x] Resultat en viu: OEE, D, R, Q i pèrdua principal.
- [x] Amplada màxima 640 px; a 360 px, columna amb scroll i sense overflow.
- [x] Alçada dels camps ≥ 48 dp.

## T4 — Validacions i avisos

- [x] Cada incidència de la spec amb el seu missatge, sense xifres quan el càlcul no és vàlid.
- [x] Estat incomplet amb el missatge neutre.
- [x] Avís quan el rendiment arrodonit supera el 100 %.
- [x] Tests de widget d'aquests estats.

## Fet quan

- [x] `flutter analyze` sense issues.
- [x] `flutter test` en verd.
- [x] PR petita cap a `main` que tanca l'issue #1 i enllaça aquesta carpeta.
