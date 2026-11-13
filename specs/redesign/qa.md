# Secció 17 — QA integrada d'R6

Font: [spec.md](spec.md), seccions 4 (AC-20 i AC-21), 6, 9 i 11. Aquesta secció no afegeix requisits ni reobre les decisions de la secció 8 ni les seccions 13…16. És la passada final quan B, C, D i E ja són a `main`.

La QA no és una PR de producte. Només corregeix defectes que impedeixin tancar AC-20 o AC-21. Qualsevol canvi de comportament que no sigui un defecte d'aquests dos criteris queda fora i es documenta.

## 17.1 Abast

| AC | Què es tanca |
| --- | --- |
| AC-20 | Formularis, històrics i accions accessibles sense retalls a 360 px i en escriptori; mapa amb zoom, desplaçament i enquadrament. Teclat per seleccionar, editar, confirmar i cancel·lar, focus visible, etiquetes accessibles i estat expressat amb text, no només amb color. Objectius de 48 × 48 dp i controls del mapa operables sense arrossegar com a única via. |
| AC-21 | Unitaris, persistència, importació, restauració, OEE i historial executats; `flutter analyze`, `flutter test` i `flutter build web`; Chrome real amb recàrrega, import invàlid, substitució, restauració, historial, teclat i 360 px; evidència visual de 1280 × 800 i de 360 px; cap empresa = L4/ERP ni jerarquia = nivells a l'exemple; cap indicador inventat. |

AC-01…AC-19 no es reobren. Es comproven de manera indirecta amb la suite existent i amb un recorregut de fum al navegador.

## 17.2 Decisions preses abans d'executar

Aquests punts eren ambigus i es tanquen així abans de tocar tests o codi:

1. **Passada integrada** vol dir una branca `qa/r6-integrated` des de `main`, amb una sola PR de QA. No es fusiona res sense confirmació de Mon.
2. **360 px** vol dir viewport CSS de 360 × 800 en Chrome real, més tests de widget a 360 × 800. No es disposa de dispositiu físic; l'evidència mòbil és aquest viewport i s'indica a la traça.
3. **Zoom i desplaçament** es proven amb els botons `+`/`-`, amb el teclat (`+`, `-`, fletxes) i amb arrossegar el mapa. El gest de pinça tàctil no es pot reproduir en Chrome d'escriptori; es documenta com a límit i es recolza en `InteractiveViewer`, que és qui el proporciona.
4. **48 dp** es mesura amb tests de widget sobre la mida renderitzada, perquè el canvas de Flutter no exposa aquesta mida al DOM. L'evidència visual no substitueix la mesura.
5. **Focus visible** es prova amb recorregut real de teclat a Chrome i amb tests que comproven el node enfocat i el seu indicador. El color del focus no és l'única prova.
6. **Estat no només pel color** es comprova amb el text present: `Desant…`, `Desat`, error, `suggested`/`confirmed`, `Esborrany`/`Validat`.
7. **Cap indicador inventat** vol dir que l'espai de treball i l'exemple no pinten OEE: només el motor, el calculador US-1 i l'historial calculen. El recorregut ho comprova sense escriure registres des de l'exemple.
8. **Evidència** es desa a `specs/redesign/qa/` com a PNG, i les sortides de comandes es ressenyen en aquest fitxer amb data i commit. No s'inclouen dades personals ni el token de GitHub.
9. **Quota real del navegador** no es força. La interrupció de transacció injectada als tests continua sent la prova de la fallada; una quota real només es reportaria si es reproduís.
10. **Defectes** es corregeixen amb el mínim canvi i un test que els fixi. Si un defecte afecta AC-01…AC-19, no es corregeix aquí: es documenta i es decideix fora d'aquesta QA.

## 17.3 Matriu

| Superfície | 1280 × 800 | 360 × 800 | Teclat i focus | Text d'estat | 48 dp |
| --- | --- | --- | --- | --- | --- |
| Calculador US-1 (`OeeForm`) | Sí | Sí | Camps, `Calcula`, `Mapa`, `Dades`, `Càlcul` | Resultat i errors | Tests |
| Motor OEE (`OeeEnginePage`) | Sí | Sí | Camps, unitats, desar, navegació | Resultat, errors, avisos | Tests |
| Espai de treball (`WorkspacePage`) | Sí | Sí | Arbre, inspector, alta, edició, esborrat, flux, plantilla, esquema, instantània, zoom | `Desant…`/`Desat`/error, suggeriments | Tests |
| Històric OEE (`OeeHistoryBrowser`) | Sí | Sí | Filtres, mode, obrir, tancar, correcció | `Esborrany`/`Validat`, buit | Tests |
| `Dades locals` (`DataFoundationPage`) | Sí | Sí | Exportar, importar, substituir, cancel·lar | Desament i error | Tests |

## 17.4 Recorregut real al navegador

1. Obrir l'aplicació, carregar l'exemple alimentari i comprovar que no apareix cap OEE ni cap empresa = L4.
2. Seleccionar una línia, aplicar la plantilla `envasat`, confirmar, desar i recarregar.
3. Crear un flux manual, confirmar-lo i comprovar el text d'estat.
4. Crear una instantània amb nota, restaurar-la i comprovar l'informe i que l'OEE no canvia.
5. Exportar la còpia, importar un JSON invàlid (ha de rebutjar-se sense obrir la substitució) i importar una còpia vàlida amb confirmació.
6. Desar el torn de referència US-1 des de la línia i veure `79.166667 %` a l'historial; el calculador ha de seguir a `79.2 %`.
7. Repetir els punts crítics a 360 px i amb teclat, comprovant zoom, desplaçament, enquadrament i absència de retalls.

## 17.5 Resultats

**Data:** 13 de novembre de 2026.

**Branca:** `qa/r6-integrated`, des de `main` (`39ceda4`). Spec de QA: `8e23bde`. Prova afegida de zoom, desplaçament i enquadrament: `71ea599`. La QA no modifica `lib/`; el build web és el mateix codi que les PR C, D i E.

### 17.5.1 Comandes

| Comanda | Resultat |
| --- | --- |
| `flutter analyze` | 16 avisos `info` de `deprecated_member_use` per `package:flutter/material.dart`, cap error ni cap warning. Són preexistents i no bloquegen AC-20 ni AC-21. |
| `flutter test` | 118 tests, tots passats. Inclou el test nou de zoom, desplaçament, enquadrament i 48 dp dels controls del mapa. |
| `flutter build web` | Correcte. `build/web` generat. |

La suite cobreix els unitaris de model, còpia, migració, reconciliació, OEE, històric, persistència, importació, restauració, teclat, focus, 48 dp i 360 px. No s'ha afegit cap dependència.

### 17.5.2 Chrome real

Chrome 157 headless per CDP, amb viewport de 1280 × 800 i de 360 × 800. L'origen es va netejar abans del recorregut i després es va carregar l'exemple. Resultats:

| Punt | Resultat |
| --- | --- |
| Calculador US-1 | Amb 480/60/60/400/380 i entrada real de teclat: `OEE: 79.2 %`, `Disponibilitat: 87.5 %`, `Rendiment: 95.2 %`, `Qualitat: 95.0 %`, `Pèrdua principal: Disponibilitat.` a 1280 i a 360. |
| Exemple alimentari | `Alimentària Demo` surt com a organització sense funció ISA-95. No apareix empresa = L4/ERP ni jerarquia = nivells. L'espai no pinta cap indicador OEE; l'històric diu `Encara no hi ha registres OEE.` |
| Plantilla `envasat` | S'afegeixen Omplidora i Taponadora a la línia, sense funcions ni fluxos inventats. |
| Instantània i restauració | La instantània amb nota crea `Versions: 1`. En restaurar, l'informe diu `L'inventari vigent coincideix amb la captura.` i passa a `Versions: 2`, sense sobreescriure la versió anterior. |
| Recàrrega | Es conserven l'exemple, les dues màquines de la plantilla i `Versions: 2`. |
| Import invàlid | `El JSON no és vàlid.`; no s'obre el diàleg de substitució i la base no canvia. |
| Import vàlid | Una còpia real de 29.871 caràcters llegida d'IndexedDB obre `Substitució completa`. En confirmar, l'estat segueix `Desat` i es conserven les dades i `Versions: 2`. |
| Motor OEE | Amb 480/60/60/400/380, torn T1 i article Iogurt: `OEE: 79.166667 %`, estat `Validat`. L'històric mostra el registre; el calculador US-1 continua a `79.2 %`. |
| 360 px | Espai, arbre, inspector i històric es mostren sense retalls. Els filtres de l'històric fan com a màxim 360 px d'ample. La suite comprova l'absència d'overflow a 360 × 800. |
| Mapa: botons | `Apropa` fa créixer la caixa ERP de 193 × 118 a 222 × 135 (×1,15); `Allunya` la retorna a 193 × 118. |
| Mapa: teclat | Amb focus al mapa, `=` fa el mateix zoom ×1,15, `ArrowLeft` desplaça la caixa de x = 331 a x = 379 i `f` enquadra de nou a 193 × 118. |
| Mapa: arrossegament | Arrossegar 80 px desplaça la caixa de x = 331 a x = 391; `Enquadra` la retorna a x = 331. |
| Teclat de diàleg | 12 tabuladors fins a la línia i `Enter` la selecciona. Al diàleg d'importació, 3 tabuladors fins a `Cancel·la` i `Enter` el tanquen; 4 tabuladors fins a `Prepara substitució` i `Enter` activen la validació, que mostra `El JSON no és vàlid.` |
| Focus visible | Les captures de selecció i de diàleg mostren l'indicador de focus. Els tests comproven el node enfocat i el focus border de 2 px. |

Límit documentat: el gest de pinça tàctil no es pot reproduir en Chrome d'escriptori; `InteractiveViewer` el proporciona i la resta de vies (botons, teclat i arrossegament) queden provades. La quota real del navegador no s'ha forçat; la fallada de transacció injectada als tests continua sent la prova.

### 17.5.3 Evidència visual

Totes les imatges són a `specs/redesign/qa/`:

- Calculador: `01-calculator-1280.png`, `01-calculator-360.png`, `02-calculator-result-1280.png`, `02-calculator-result-360.png`.
- Espai: `03-workspace-empty-1280.png`, `04-workspace-example-1280.png`, `05-workspace-line-1280.png`, `06-workspace-template-1280.png`, `07-workspace-versions-1280.png`, `08-workspace-reload-1280.png`.
- Importació i substitució: `09-workspace-import-invalid-1280.png`, `16-workspace-replace-dialog-1280.png`, `17-workspace-after-replace-1280.png`, `27-keyboard-dialog-cancel-1280.png`, `28-keyboard-dialog-prepare-1280.png`.
- OEE i històric: `10-workspace-history-1280.png`, `14-workspace-engine-result-1280.png`, `15-workspace-history-record-1280.png`, `14b-workspace-history-360.png`.
- 360 px: `11-workspace-360.png`, `12-workspace-tree-360.png`, `13-workspace-inspector-360.png`.
- Mapa: `18-map-before-1280.png`, `19-map-zoom-in-1280.png`, `20-map-keyboard-pan-1280.png`, `21-map-drag-1280.png`, `22-map-before-360.png`, `23-map-zoom-360.png`.
- Teclat: `24-keyboard-selection-1280.png`, `27-keyboard-dialog-cancel-1280.png`, `28-keyboard-dialog-prepare-1280.png`.

### 17.5.4 Conclusió

| AC | Resultat |
| --- | --- |
| AC-20 | Tancat. Formularis, històrics i accions sense retalls a 1280 i a 360; mapa amb zoom, desplaçament i enquadrament per botons, teclat i arrossegament; teclat per seleccionar, editar, confirmar i cancel·lar; focus visible; estats amb text; objectius de 48 × 48 dp mesurats en tests. |
| AC-21 | Tancat. Unitaris, persistència, importació, restauració, OEE i històric executats; `flutter analyze`, `flutter test` i `flutter build web`; Chrome real amb recàrrega, import invàlid, substitució, restauració, historial, teclat i 360 px; evidència visual de 1280 × 800 i de 360 px; exemple sense empresa = L4/ERP ni jerarquia = nivells; cap indicador inventat. |

No s'ha detectat cap defecte que bloquegi AC-20 o AC-21. Els 16 avisos `info` de deprecació queden fora d'aquesta QA i no s'han tocat. No es fusiona la PR sense confirmació de Mon.

