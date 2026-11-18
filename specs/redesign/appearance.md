# Secció 17 — Aparença compartida de l'aplicació

Font: petició de producte posterior a la QA integrada d'R6 (14–15 de novembre de 2026). Aquesta secció no reobre AC-01…AC-21, la secció 8 ni la QA d'R6: afegeix una capa visual comuna per sobre del comportament ja provat. La petició posterior també retira el Calculador OEE com a pantalla; el càlcul es manté a `Càlcul OEE` i al quadre de la línia del mapa.

Abast decidit amb el producte:

| Pregunta | Decisió |
| --- | --- |
| On ha de romandre la barra lateral | A totes les pantalles: `Càlcul OEE`, `Mapa ISA-95` i `Dades locals`. |
| Què vol dir «botons inferiors a l'estil del mapa» | Mateix contenidor, colors, espaiat i objectius de 48 dp del mapa; cada pantalla conserva les seves accions. |
| Quines entrades té la barra | Càlcul, Mapa i Dades. |
| Mapa antic i diàlegs | També adopten l'aparença del mapa. |

## 17.1 Closca comuna

`lib/workspace_shell.dart` és l'única font de la closca. Les tres pantalles la fan servir; cap pantalla dibuixa la seva pròpia barra lateral.

| Element | Comportament |
| --- | --- |
| `WorkspaceShell` | Barra lateral + capçalera + contingut + barra inferior. El tema `workspaceTheme()` s'aplica a tota la closca. |
| `WorkspaceRail` | Fons antracita `#1E242B`. 76 px d'amplada; 64 px si la finestra fa menys de 600 px. Tres entrades amb icona i text: `Càlcul`, `Mapa`, `Dades`. L'entrada activa es marca amb `#2A333C` i text complet; l'activa no navega. Objectiu mínim de 48 × 48 dp. Icones i text sempre en blanc (`panel`) sobre el fons fosc; les entrades desactivades baixen a blanc al 50 %. |
| `WorkspaceHeader` | 56 px, fons blanc, títol de 16 px i pes 600, accions pròpies de la pantalla. Admet una segona fila per a les pestanyes del mapa antic. Es desplaça en horitzontal si no hi cap. |
| `WorkspaceBottomBar` | Fons `#E6EBEF`, padding de 8/4 px, separació de 8 px entre accions i controls quadrats de 48 dp. Es desplaça en horitzontal a 360 px. |
| `workspaceBarButton` | Botó de barra o de capçalera amb l'estil dels controls del mapa. Sempre porta icona i text; no hi ha botons només icona a les barres. |

El punt de tall `wide` del mapa continua depenent de la finestra (`MediaQuery.width >= 1100`), no de l'amplada del rail.

## 17.2 Tema

`MaterialApp.theme` passa a ser `workspaceTheme()`, de manera que diàlegs, menús, snackbars, targetes i pestanyes hereten l'aparença del mapa. S'afegeixen:

| Entrada | Valor |
| --- | --- |
| `appBarTheme` | Fons antracita, text blanc, sense elevació. |
| `dialogTheme` | Fons blanc, vora `steelLine`, títol de 18 px. |
| `snackBarTheme` | Fons antracita, text blanc, acció blava clara. |
| `cardTheme` | Fons blanc, vora `steelLine`, sense elevació. |
| `tabBarTheme` | Etiqueta activa `ink`, inactiva `steel`, indicador `accent`. |
| `popupMenuTheme` | Fons blanc, vora `steelLine`. |
| `workspaceControlStyle` | Rectangle de 6 px de radi, fons blanc `panel`, vora `steelLine`, text i icona `ink`, mínim 48 × 48 dp i focus amb vora de 2 px. S'aplica a `OutlinedButton`, `TextButton`, `FilledButton` i `IconButton`. |
| Colors | `railActive` (`#2A333C`), `bottomBarSurface` (`#E6EBEF`) i `tertiary` ambre (`#8A6A2F`) per als avisos. |

Els controls són quadrats arrodonits, no píndoles ni cercles. `IconButton` (desplega/replega i menú de tres punts del mapa antic) i els botons de text hereten la mateixa forma, el mateix fons blanc i la mateixa vora, de manera que cap botó queda rodó ni amb el gris `surfaceContainerHighest`. Les accions de les barres porten icona i text, com la resta de la pàgina.

## 17.3 Per pantalla

| Pantalla | Capçalera | Accions de la barra inferior | Entrades de la barra |
| --- | --- | --- | --- |
| Càlcul OEE | `Càlcul OEE` | Mapa ISA-95, Dades locals | Càlcul (activa), Mapa, Dades |
| Mapa ISA-95 (espai de treball) | `Mapa de planta`, Afegeix i commutadors a 360 px | Apropa, Allunya, Enquadra, desplaçament, estat, esquemes, versions, historial i còpies | Càlcul, Mapa (activa), Dades |
| Mapa ISA-95 (mapa antic) | `Mapa ISA-95` i pestanyes Arbre/Nivells | Afegeix empresa, Carrega exemple, Exporta JSON, Importa JSON i navegació disponible | Càlcul, Mapa (activa), Dades |
| Dades locals | `Dades locals` | Mapa ISA-95 | Càlcul, Mapa, Dades (activa) |

S'ha retirat el **Calculador OEE** (el formulari US-1) i la seva entrada de la barra. El càlcul OEE continua sencer a **Càlcul OEE** i al quadre de la línia del mapa, que desa els registres a l'historial. També s'han retirat els enllaços «Calculador US-1», «Calculador OEE» i «Obre el calculador» de les barres i de l'inspector.

Una entrada de la barra que no té destinació en aquell context queda desactivada. El mapa antic no obre `Dades locals` quan l'aplicació no té repositori d'IndexedDB.

## 17.4 Roda del ratolí i zoom

El mapa de l'espai de treball ja no fa zoom amb la roda. `lib/map_viewport.dart` substitueix `InteractiveViewer` perquè aquest amplia amb la roda des d'un `Listener` intern que no es pot interceptar.

| Gest | Efecte |
| --- | --- |
| Roda del ratolí | Desplaça el mapa amunt o avall, amb el delta exacte de l'esdeveniment. |
| `Maj` + roda | Desplaça el mapa en horitzontal. |
| `Apropa` / `Allunya` | Únic zoom amb botons, en passos de 1,15. |
| Teclat | `+` apropa, `-` allunya i `F` enquadra. |
| Pessigar | Continua fent zoom amb dos dits. |
| Arrossegar | Continua desplaçant el mapa. |

El zoom es limita a 0,35…2,5 i el desplaçament deixa sempre 80 px del contingut visibles. La roda mai no canvia l'escala; dues rodes oposades recuperen exactament la vista anterior.

## 17.5 Comportament conservat

- Càlcul OEE continua donant `OEE: 79.166667 %` amb 480 min, 60 min, 1 unitat/s, 24000 i 22800; el quadre de la línia del mapa dona el mateix resultat i desa el registre.
- La clau legacy continua sent només de lectura i la reconciliació no canvia.
- IndexedDB, la substitució completa, les instantànies i l'historial OEE no canvien.
- A 360 px no hi ha overflow horitzontal; els objectius continuen sent de 48 dp i el focus és visible.
- Els textos de producte no canvien.

## 17.6 Verificació

| Comprovació | Resultat |
| --- | --- |
| `flutter test` | 117 tests correctes, inclosos `test/workspace_shell_test.dart` i la prova de roda de `test/workspace_page_test.dart`. |
| `flutter analyze` | Cap error. Només 16 avisos `info` de deprecació de `package:flutter/material.dart`, ja presents abans. |
| `flutter build web` | Correcte. |
| Chrome real 1280 × 800 | Càlcul, Dades, mapa buit, mapa amb exemple i mapa després de la roda. |
| Chrome real 360 × 800 | Càlcul i mapa amb la barra lateral compacta. |

L'evidència visual és a [appearance/](appearance/). Comprovació de píxels sobre les captures:

| Captura | Rail | Barra inferior | Finestra |
| --- | --- | --- | --- |
| `31-appearance-engine-1280.png` | 76 px, `#1E242B` | y 744…799, `#E6EBEF` | 1280 × 800 |
| `32-appearance-data-1280.png` | 76 px, `#1E242B` | y 744…799, `#E6EBEF` | 1280 × 800 |
| `33-appearance-map-1280.png` | 76 px, `#1E242B` | y 672…799, `#E6EBEF` | 1280 × 800 |
| `34-appearance-map-example-1280.png` | 76 px, `#1E242B` | y 672…799, `#E6EBEF` | 1280 × 800 |
| `34b-appearance-map-wheel-1280.png` | 76 px, `#1E242B` | y 672…799, `#E6EBEF` | 1280 × 800 |
| `34c-appearance-map-wheel-back-1280.png` | 76 px, `#1E242B` | y 672…799, `#E6EBEF` | 1280 × 800 |
| `35-appearance-map-360.png` | 64 px, `#1E242B` | y 672…799, `#E6EBEF` | 360 × 800 |
| `37-appearance-engine-360.png` | 64 px, `#1E242B` | y 744…799, `#E6EBEF` | 360 × 800 |

Cap captura conté les franges grogues i negres d'overflow de Flutter ni el vermell d'error. La capçalera blanca ocupa sempre els 56 px superiors del contingut. Les icones de la barra lateral són blanques sobre el fons antracita, també a les entrades inactives.

La prova de la roda comprova que `-120` desplaça el mapa 120 px avall i que `Maj` + `-80` el desplaça 80 px en horitzontal, sense canviar l'escala. A Chrome, `34b` és la vista després de la roda i `34c` la vista després de tornar-la a girar: totes dues comparteixen el SHA256 `E1CA39DE98DDB7240D5058C9215D85B17001E3B28DFCA188906A7B6E6C4CA9F7` amb `34`, és a dir, el desplaçament es recupera exactament i no hi ha zoom.

## 17.7 Fora d'abast

No es canvien càlculs, textos de producte, esquema de dades ni persistència. No hi ha backend nou ni canvis a la QA integrada d'R6.
