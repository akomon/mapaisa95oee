# Pla: Calculador OEE

Spec: [spec.md](spec.md). Tasques: [tasks.md](tasks.md).

## Enfocament

Projecte Flutter Web mínim, sense backend. La fórmula i les validacions viuen a `lib/oee_calculator.dart` i no importen Flutter. La UI és un formulari Material 3 que parseja el text i pinta `OeeComputation`.

El càlcul es commita només després d'aquesta spec.

## Estructura

```
lib/main.dart                 # arrencada, tema, Calculador OEE
lib/oee_calculator.dart       # lògica pura i textos de la spec
lib/oee_form.dart             # formulari i resultat en viu
test/oee_calculator_test.dart # casos de referència i límits
test/oee_form_test.dart       # resultat en viu, errors, 360 px, 48 dp
```

`flutter create` deixa la plataforma web. S'elimina el comptador de demostració. El nom del paquet és `mapaisa95oee`.

## Decisions tancades per la spec

- Temps operatiu del rendiment en segons: `(plannedMinutes − downtimeMinutes) × 60`.
- Percentatge amb 1 decimal, half-away-from-zero, text `87.5 %`.
- Incidència → `result == null` i la llista completa de codis, en l'ordre de la spec.
- `R` arrodonit > 100.0 % → avís, sense capar l'OEE.
- Pèrdua principal sobre els percentatges arrodonits; els empats llisten tots els factors.
- Sense botó. Objectiu tàctil del camp ≥ 48 dp. Amplada màxima del formulari 640 px.

## Verificació

```
flutter analyze
flutter test
```

`flutter analyze` ha de quedar sense issues. `flutter test` ha d'executar els tests unitaris i els de widget, incloent-hi el torn de referència (79.2 %) i la superfície de 360 px.

## Riscos coneguts

- L'arrodoniment binari de `double` es tanca a `formatOeePercent` sumant un epsilon petit abans d'arrodonir, i els tests de referència usen les entrades enteres de la spec.
- `flutter test` no obre un navegador. La prova de 360 px fixa la superfície del `WidgetTester` i comprova que no hi ha overflow. No substitueix una passada manual a Chrome.
- Fora d'abast: persistència, ISA-95, exportació i desplegament.
