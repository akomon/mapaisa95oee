# Tasques: Mapa ISA-95

Extretes de l'issue #3. La spec es commita abans de qualsevol codi.

## T0 — Spec

- [ ] Crear `specs/02-mapa-isa95/spec.md`, `plan.md` i `tasks.md`.
- [ ] Commit de la spec abans del codi.

## T1 — Model i tests

- [ ] `lib/plant_model.dart` amb jerarquia, CRUD, JSON, textos i `foodPlantExample`.
- [ ] Tests unitaris: alta vàlida, nom buit, jerarquia, esborrat amb fills, round-trip JSON, exemple, ids duplicats i JSON invàlid.

## T2 — Arbre i edició

- [ ] Pantalla `Mapa ISA-95` amb vista arbre desplegable.
- [ ] Afegir / editar / esborrar; confirmació si el node té fills.
- [ ] Tipus determinat pel context; nivell funcional seleccionable.

## T3 — Vista per nivells

- [ ] Pestanya o segment `Nivells` amb seccions 0–4 i colors de la spec.
- [ ] Cada node mostra el camí jeràrquic.

## T4 — Persistència i JSON

- [ ] `PlantStore` + SharedPreferences (`mapaisa95oee.plant.v1`).
- [ ] Exporta / importa JSON; missatge clar si el fitxer és invàlid.
- [ ] `Carrega exemple` substitueix la planta i desa.

## T5 — Navegació i responsiu

- [ ] Enllaços bidireccionals Calculador OEE ↔ Mapa ISA-95.
- [ ] Amplada màxima 640 px; a 360 px sense overflow; objectius ≥ 48 dp.
- [ ] Tests de widget smoke + `flutter analyze` / `flutter test` en verd.

## Fet quan

- [ ] `flutter analyze` sense issues.
- [ ] `flutter test` en verd.
- [ ] PR petita cap a `main` que tanca l'issue #3 i enllaça aquesta carpeta.
