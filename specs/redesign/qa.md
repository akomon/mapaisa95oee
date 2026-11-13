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

Pendent d'execució. Aquesta secció es completa amb les sortides reals, la data i el commit, abans d'obrir la PR de QA.
