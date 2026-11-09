# Secció 15 — PR D: motor OEE, unitats, indicadors i pastís

Font: [spec.md](spec.md), secció 5, i la font aprovada. Aquesta secció no afegeix requisits ni reobre la secció 8. El fitxer és nou perquè la PR C (secció 14, encara no fusionada) append al final de `spec.md`, `plan.md` i `tasks.md`. Així les dues PR no editen les mateixes línies.

Aquesta PR és només la PR D. Depèn de la PR A, ja a `main`. La PR B també és a `main` i es conserva. No s'apila sobre la PR C. No comença la PR E.

## 15.1 Què es tanca i què es deixa

| AC | PR D |
| --- | --- |
| AC-12 | Tancat. P i S en minuts, N i G enters, velocitat en s/unitat o unitats/s. Coma o punt decimal. Separadors de milers ambigus rebutjats. Buits, NaN, infinits i fora de domini rebutjats, amb el camp identificat. |
| AC-13 | Tancat. El canvi d'unitat parteix del `c` canònic i no encadena arrodoniments. Conversions repetides mantenen `c` i els resultats dins de `1e-9` relatiu. Només es presenta arrodonit el percentatge i l'etiqueta del pastís. |
| AC-14 | Tancat. OEE, disponibilitat, rendiment i qualitat es mostren separats, amb les fórmules i els estats de la secció 5. Els factors que no apliquen s'expliquen. No hi ha divisió per zero ni retall al 100 %. |
| AC-15 | Tancat. El pastís descompon el temps planificat en productiu equivalent i tres pèrdues, amb unitat i valors. No és la suma de D, R i Q. Dades inconsistents o rendiment superior a 1 no pinten porcions negatives ni un pastís aparentment vàlid. |
| AC-01…AC-11, AC-19 | Es conserven. Aquesta PR no els reobre ni en modifica el codi de domini, de còpia ni de migració. |
| AC-16…AC-18 | Diferits a la PR E. No es crea, edita ni filtra cap registre OEE. El motor pot dir si un resultat es podria validar; no l'escriu. |
| AC-20 | Parcial d'aquesta pantalla: 360 px sense overflow horitzontal, objectius de 48 dp, focus visible, teclat i textos. La passada integrada continua fora. |
| AC-21 | Parcial: anàlisi, tests, build web i Chrome real de l'abast D. |

Fora de la PR D: històric, filtres, esborranys persistits, revisions de registres validats, agregació, PDF, backend, plantilles, suggeriments, esquemes i restauració. La SPEC sencera no queda tancada.

## 15.2 Entrada

Temps intern en segons. L'usuari escriu P i S en minuts. La velocitat s'introdueix en una unitat explícita:

| Unitat visible | JSON ja existent | Canònic |
| --- | --- | --- |
| `s/unitat` | `secondsPerUnit` | `c` és el valor introduït |
| `unitats/s` | `unitsPerSecond` | `c = 1/v` |

`c` és segons/unitat. No es llegeix un nombre de `s/unitat` com si fossin `unitats/s`. Si un cridant passa `speedOriginal`, `speedUnit` i `idealCycleSeconds` i no compleixen la fila de dalt dins de la tolerància, el resultat és `unitMismatch` i no hi ha càlcul. El formulari no fa aquesta barreja: en canviar la unitat, el text surt de `c` i `c` no es torna a calcular des del text arrodonit.

Decimals de P, S i velocitat: després de `trim`, un sol `.` o una sola `,` és el separador decimal. `0,4` i `0.4` són el mateix valor. Més d'un separador, o els dos alhora (`1.234,56`, `1,234.56`, `1.234.567`), és `ambiguousThousands`. No es tria en silenci entre milers i decimals. Espais interiors, exponent (`1e2`) i text no numèric són `invalidNumber`. `NaN`, `Infinity` i infinits no són finits.

N i G: signe opcional i dígits, sense separador decimal. `10.0`, `10,5` i `1.000` no són enters. Un negatiu és fora de domini, no un resultat amb qualitat negativa.

Domini, un cop el text és parsejable: P > 0, 0 ≤ S ≤ P, velocitat > 0, N i G enters, 0 ≤ G ≤ N. Cada incompliment nomena el camp i no produeix indicadors.

Ordre estable de les incidències: P, S, velocitat, N, G i, només si la resta és vàlida, la producció amb temps operatiu zero.

| Codi | Missatge |
| --- | --- |
| buit, P | El temps planificat és obligatori. |
| buit, S | El temps de parades és obligatori. |
| buit, velocitat | La velocitat és obligatòria. |
| buit, N | Les unitats totals són obligatòries. |
| buit, G | Les unitats bones són obligatòries. |
| nombre invàlid, P | El temps planificat no és un nombre vàlid. |
| nombre invàlid, S | El temps de parades no és un nombre vàlid. |
| nombre invàlid, velocitat | La velocitat no és un nombre vàlid. |
| milers ambigus, P | El temps planificat té separadors de milers ambigus. |
| milers ambigus, S | El temps de parades té separadors de milers ambigus. |
| milers ambigus, velocitat | La velocitat té separadors de milers ambigus. |
| no finit, P | El temps planificat no és un nombre finit. |
| no finit, S | El temps de parades no és un nombre finit. |
| no finit, velocitat | La velocitat no és un nombre finit. |
| no finit, N | Les unitats totals no són un nombre finit. |
| no finit, G | Les unitats bones no són un nombre finit. |
| no enter, N | Les unitats totals han de ser un enter, sense decimals ni separadors de milers. |
| no enter, G | Les unitats bones han de ser un enter, sense decimals ni separadors de milers. |
| P ≤ 0 | El temps planificat ha de ser més gran que zero. |
| S < 0 | El temps de parades no pot ser negatiu. |
| S > P | El temps de parades no pot superar el temps planificat. |
| velocitat ≤ 0 | La velocitat ha de ser més gran que zero. |
| N < 0 | Les unitats totals no poden ser negatives. |
| G < 0 | Les unitats bones no poden ser negatives. |
| G > N | Les unitats bones no poden superar les unitats totals. |
| unitat incoherent | La unitat de la velocitat no coincideix amb el cicle canònic. No es fa cap conversió silenciosa. |
| O = 0 i N > 0 | No hi pot haver producció amb temps operatiu zero. |

## 15.3 Indicadors

Fórmula `oee.v1`. Temps en segons: P és el planificat, S les parades, O = P − S, N les unitats totals, G les bones.

D = O/P. R = cN/O quan O > 0. Q = G/N quan N > 0. OEE = cG/P. Els càlculs interns no s'arrodonixen. Quan D, R i Q tenen denominador vàlid, OEE = D × R × Q dins de la tolerància.

| Cas de la secció 5 | Què es mostra |
| --- | --- |
| Referència 480 min, 60 min, 1 s/u, 24000, 22800 | O = 25200 s. D `87.5 %`. R `95.238095 %`. Q `95 %`. OEE `79.166667 %`. |
| 0,4 s/u o 2,5 u/s, amb P = 1 min, S = 0, N = 100, G = 90 | D `100 %`. R `66.666667 %`. Q `90 %`. OEE `60 %`. El mateix `c` després de conversions repetides. |
| N = 0, O > 0, G = 0 | OEE `0 %`. D = O/P. R `0 %`. Qualitat: `no aplica`. |
| O = 0, N = 0, G = 0, S = P | D `0 %`. OEE `0 %`. Rendiment i qualitat: `no aplica`. |
| O = 0, N > 0 | Només l'error de la secció 15.2. Cap percentatge, cap pastís, cap validació. |
| R > 1, més enllà de la tolerància | Els quatre percentatges, sense capar R ni l'OEE. Avís. Sense pastís. No es valida. |
| G > N, P = 0, S > P, c ≤ 0, v ≤ 0, N negatiu, comptatge fraccionari | Errors de camp. Cap indicador. |

Textos dels factors que no apliquen:

- `La qualitat no aplica perquè no hi ha unitats produïdes.`
- `El rendiment no aplica perquè el temps operatiu és zero i no hi ha producció.`

Avís de rendiment superior a 1:

`El rendiment supera 1. La velocitat, el temps o les unitats no són coherents. No es capa el factor.`

`Es podria desar un esborrany, però no es pot validar. Aquest càlcul no desa cap registre.`

Un resultat coherent diu: `Aquest càlcul no desa cap registre.` No hi ha botó de desar ni de validar.

El percentatge visible té fins a 6 decimals, half-away-from-zero, sense zeros finals, amb punt i un espai abans de `%`. Exemple: `79.166667 %`. Això no canvia el format d'1 decimal del calculador US-1.

## 15.4 Pastís

Tproductiu = cG. Tdisponibilitat = S. Trendiment = O − cN. Tqualitat = c(N − G). La suma és P.

És una descomposició equivalent del temps planificat. No és un registre de causes de parada. La llegenda i el tooltip ho diuen, i diuen que les unitats es passen a temps ideal amb `c`.

Es pinta només si les quatre porcions són ≥ 0 després de tractar el residu numèric, i la suma continua sent P dins de la tolerància. Una porció negativa amb valor absolut més gran que `1e-9 × P` no es normalitza: no hi ha pastís i el text és `No es dibuixa el pastís: el rendiment superior a 1 deixaria una porció negativa.` No s'ensenya un gràfic buit com si fos vàlid.

Un residu estrictament numèric (porció negativa o desviació de la suma, dins de la tolerància) es posa a zero només al pastís i s'explica: `Un residu numèric de coma flotant s'ha normalitzat només en representar el pastís.` No es fa servir per donar per bo un rendiment real superior a 1.

Unitat visible: minuts, el mateix eix que P i S. El total mostrat és P. Valors de la referència: productiu 380 min, disponibilitat 60 min, rendiment 20 min, qualitat 20 min, total 480 min. Una porció zero es llista igualment.

Casos de pastís de la secció 5:

- N = 0 i O > 0: productiu 0, disponibilitat S, rendiment O, qualitat 0.
- O = 0 i N = 0: disponibilitat P i la resta 0.

## 15.5 Pantalla

Textos en català. El tema és el de l'espai de treball: antracita, acer, focus de 2 px, controls nous d'almenys 48 dp. L'amplada màxima del formulari és 640 px. A 360 px el contingut és una columna amb desplaçament vertical i sense overflow horitzontal. La unitat activa es llegeix pel text `Activa`, no només pel color.

La pantalla pròpia es titula `Càlcul OEE`. S'obre des del calculador US-1 amb `Càlcul amb unitats`. El calculador US-1 no canvia de fórmules ni de torn de referència: 480 min, 60 min, 60 s/unitat, 400 totals i 380 bones continuen mostrant `OEE: 79.2 %`.

A l'inspector d'una línia es mostra el mateix quadre, amb el nom de la línia, i es conserva `Obre el calculador`. El nom de la línia és context visible. No es desa i no es recalcula cap registre si la línia es reanomena: no n'hi ha cap d'escrit per aquesta PR.

Cada canvi recalcula. No hi ha botó de càlcul.

## 15.6 Què no es toca

`lib/oee_calculator.dart` i el resultat US-1. `formatVersion` 1. Els registres OEE ja desats, les còpies i la clau `mapaisa95oee.plant.v1`. El model, el codec, el repositori i la migració. Els fitxers nous de la PR C (`flow_suggestions.dart`, `workspace_phase_c.dart`, `phase_c_domain_test.dart`). L'edició de `workspace_page.dart` es limita al bloc de la línia, perquè la PR C hi afegeix plantilles i disposició en un altre punt.

## 15.7 Verificació

```
flutter analyze
flutter test
flutter build web
```

Chrome real a 1280 × 800 i a 360 px sobre el càlcul de la secció 5: referència, pastís amb minuts, canvi d'unitat, error de camp i rendiment superior a 1 sense pastís. El torn US-1 continua a `79.2 %`.

# Pla: motor OEE (PR D)

Spec: [phase-d.md](phase-d.md), secció 15. El codi es commita després d'aquest document.

## Enfocament

El motor és pur i no importa Flutter. La UI parseja, crida el motor i pinta. El canvi d'unitat conserva el double canònic. El calculador US-1 segueix muntat a l'arrencada. Aquesta PR no escriu IndexedDB.

## Estructura

```
lib/oee_engine.dart            # parseig, c, indicadors, pastís
lib/oee_engine_panel.dart      # formulari, quatre indicadors, pastís
lib/main.dart                  # pantalla nova; l'inici continua sent el calculador US-1
lib/oee_form.dart              # enllaç, sense canviar el càlcul
lib/workspace_page.dart        # quadre a la línia; botó US-1 conservat
test/oee_engine_test.dart
test/oee_engine_panel_test.dart
```

## Decisions d'aquesta PR

- `SpeedUnit` del model es reutilitza. No hi ha un segon vocabulari.
- La tolerància és relativa: `|a − b| ≤ 1e-9 × max(|a|, |b|)` quan el màxim no és zero.
- El pastís es decideix a part, perquè un test pugui forçar un residu que el double de la referència no produeix.
- No es persisteix res. `allowsValidation` és un resultat del motor, no una escriptura.

## Riscos

- `1/(1/c)` pot diferir de `c` en un ulp. El formulari no reparseja el text generat per obtenir un `c` nou.
- La PR C també edita `workspace_page.dart`. El canvi d'aquesta PR és el bloc de la línia, no els imports nous ni les plantilles.
- Una quota real del navegador no aplica: aquesta PR no escriu la base.

# Tasques: motor OEE (PR D)

## T12 — Spec

- [x] Afegir la secció 15, el pla i la traça abans del codi.

## T13 — Motor

- [x] Parseig de decimals, enters, milers ambigus, buits, NaN i infinits.
- [x] `c` canònic, canvi d'unitat sense encadenar, incoherència d'unitat.
- [x] Indicadors de la secció 5, inclosos zeros, R > 1 i G > N.
- [x] Pastís en minuts, residu numèric i rebuig de porcions negatives.

## T14 — Pantalla

- [x] Quatre indicadors, explicacions i pastís.
- [x] 48 dp, focus visible, teclat i 360 px.
- [x] El torn US-1 segueix a `79.2 %`.
- [x] La línia mostra el quadre sense escriure registres.

## T15 — Verificació

- [x] `flutter analyze`, `flutter test`, `flutter build web` i Chrome a 1280 × 800 i 360 px.

## Fora de la PR D

- [ ] PR E: històric i filtres.
- [ ] QA integrada d'R6.
