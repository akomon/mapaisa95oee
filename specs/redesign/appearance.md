# Secció 17 — Aparença compartida de l'aplicació

Font: petició de producte posterior a la QA integrada d'R6 (14 de novembre de 2026). Aquesta secció no reobre AC-01…AC-21, la secció 8 ni la QA d'R6: afegeix una capa visual comuna per sobre del comportament ja provat.

Abast decidit amb el producte:

| Pregunta | Decisió |
| --- | --- |
| On ha de romandre la barra lateral | A totes les pantalles: `Calculador OEE`, `Càlcul OEE`, `Mapa ISA-95` i `Dades locals`. |
| Què vol dir «botons inferiors a l'estil del mapa» | Mateix contenidor, colors, espaiat i objectius de 48 dp del mapa; cada pantalla conserva les seves accions. |
| Quines entrades té la barra | Calculador, Càlcul, Mapa i Dades. |
| Mapa antic i diàlegs | També adopten l'aparença del mapa. |

## 17.1 Closca comuna

`lib/workspace_shell.dart` és l'única font de la closca. Les quatre pantalles la fan servir; cap pantalla dibuixa la seva pròpia barra lateral.

| Element | Comportament |
| --- | --- |
| `WorkspaceShell` | Barra lateral + capçalera + contingut + barra inferior. El tema `workspaceTheme()` s'aplica a tota la closca. |
| `WorkspaceRail` | Fons antracita `#1E242B`. 76 px d'amplada; 64 px si la finestra fa menys de 600 px. Quatre entrades amb icona i text: `Calculador`, `Càlcul`, `Mapa`, `Dades`. L'entrada activa es marca amb `#2A333C` i text complet; l'activa no navega. Objectiu mínim de 48 × 48 dp. |
| `WorkspaceHeader` | 56 px, fons blanc, títol de 16 px i pes 600, accions pròpies de la pantalla. Admet una segona fila per a les pestanyes del mapa antic. Es desplaça en horitzontal si no hi cap. |
| `WorkspaceBottomBar` | Fons `#E6EBEF`, padding de 8/4 px, separació de 8 px entre accions i botons amb `workspaceControlStyle` (mínim 48 dp). Es desplaça en horitzontal a 360 px. |
| `workspaceBarButton` | Botó de barra o de capçalera amb l'estil dels controls del mapa, amb icona opcional. |

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
| Colors | `railActive` (`#2A333C`) i `bottomBarSurface` (`#E6EBEF`). |

## 17.3 Per pantalla

| Pantalla | Capçalera | Accions de la barra inferior | Entrades de la barra |
| --- | --- | --- | --- |
| Calculador OEE | `Calculador OEE` | Càlcul amb unitats, Mapa ISA-95, Dades locals | Calculador (activa), Càlcul, Mapa, Dades |
| Càlcul OEE | `Càlcul OEE` | Calculador US-1, Mapa ISA-95, Dades locals | Calculador, Càlcul (activa), Mapa, Dades |
| Mapa ISA-95 (espai de treball) | `Mapa de planta`, Afegeix i commutadors a 360 px | Apropa, Allunya, Enquadra, desplaçament, estat, esquemes, versions, historial i còpies | Calculador, Càlcul, Mapa (activa), Dades |
| Mapa ISA-95 (mapa antic) | `Mapa ISA-95` i pestanyes Arbre/Nivells | Afegeix empresa, Carrega exemple, Exporta JSON, Importa JSON i navegació disponible | Calculador, Càlcul, Mapa (activa), Dades |
| Dades locals | `Dades locals` | Calculador OEE, Mapa ISA-95 | Calculador, Càlcul, Mapa, Dades (activa) |

Una entrada de la barra que no té destinació en aquell context queda desactivada. El mapa antic no obre `Dades locals` quan l'aplicació no té repositori d'IndexedDB.

## 17.4 Comportament conservat

- El calculador US-1 continua donant `OEE: 79.2 %` amb 480 min, 60 min, 60 s/unitat, 400 i 380.
- La clau legacy continua sent només de lectura i la reconciliació no canvia.
- IndexedDB, la substitució completa, les instantànies i l'historial OEE no canvien.
- A 360 px no hi ha overflow horitzontal; els objectius continuen sent de 48 dp i el focus és visible.
- Els textos de producte no canvien.

## 17.5 Verificació

| Comprovació | Resultat |
| --- | --- |
| `flutter test` | 120 tests correctes, inclòs `test/workspace_shell_test.dart`. |
| `flutter analyze` | Cap error. Només 17 avisos `info` de deprecació de `package:flutter/material.dart`, ja presents abans. |
| `flutter build web` | Correcte. |
| Chrome real 1280 × 800 | Calculador, Càlcul, Dades, mapa buit i mapa amb exemple. |
| Chrome real 360 × 800 | Calculador i mapa amb la barra lateral compacta. |

L'evidència visual és a [appearance/](appearance/). Comprovació de píxels sobre les captures:

| Captura | Rail | Barra inferior | Finestra |
| --- | --- | --- | --- |
| `30-appearance-calculator-1280.png` | 76 px, `#1E242B` | y 744…799, `#E6EBEF` | 1280 × 800 |
| `31-appearance-engine-1280.png` | 76 px, `#1E242B` | y 744…799, `#E6EBEF` | 1280 × 800 |
| `32-appearance-data-1280.png` | 76 px, `#1E242B` | y 744…799, `#E6EBEF` | 1280 × 800 |
| `33-appearance-map-1280.png` | 76 px, `#1E242B` | y 672…799, `#E6EBEF` | 1280 × 800 |
| `34-appearance-map-example-1280.png` | 76 px, `#1E242B` | y 672…799, `#E6EBEF` | 1280 × 800 |
| `35-appearance-map-360.png` | 64 px, `#1E242B` | y 672…799, `#E6EBEF` | 360 × 800 |
| `36-appearance-calculator-360.png` | 64 px, `#1E242B` | y 744…799, `#E6EBEF` | 360 × 800 |

Cap captura conté les franges grogues i negres d'overflow de Flutter ni el vermell d'error. La capçalera blanca ocupa sempre els 56 px superiors del contingut.

## 17.6 Fora d'abast

No es canvien càlculs, textos de producte, esquema de dades ni persistència. No hi ha backend nou ni canvis a la QA integrada d'R6.
