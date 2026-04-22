# Changelog

Todos los cambios importantes de este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/).

## [Unreleased]

---

## [1.1.4] Teclado LaTeX - 2026-4-22

### Added

- Agregado widget `latex_keyboard.dart`:
  - Nuevo widget `LatexKeyboard` — panel de inserción de símbolos LaTeX para campos de texto.
  - Modelo interno `_Simbolo(etiqueta, latex, offsetDesdeFin)`: `offsetDesdeFin` posiciona el cursor dentro del primer argumento `{}` o `[]` tras la inserción (ej. `\frac{}{}` → cursor en el numerador).
  - 5 categorías en tabs scrollables:
    1. _Básico_ (fracciones, raíces, potencias, paréntesis extensibles)
    2. _Griegos_ (α–Ω, mayúsculas y minúsculas)
    3. _Operadores_ (∑ ∫ ∏ lim, funciones trigonométricas, entornos de matrices y cases)
    4. _Relaciones_ (≠ ≤ ≥ ∈ ⊂ ∪ ∩ …)
    5. _Flechas_ (→ ⇒ ⇔ ↦ …).
  - `GridView` con `SliverGridDelegateWithMaxCrossAxisExtent` — los botones se adaptan a cualquier ancho de pantalla sin configuración manual.
  - La inserción respeta la selección activa: reemplaza el texto seleccionado o inserta en la posición del cursor.

- `card_form_screen.dart`:
  - `FocusNode _focusFrente` y `FocusNode _focusDorso` con listeners que actualizan `_controladorActivo` al cambiar de campo.
  - `bool _mostrarTeclado`: controla la visibilidad del panel.
  - `IconButton(Icons.functions)` en el `AppBar` que togglea el teclado; el ícono se colorea con `colorScheme.primary` cuando está activo.
  - Panel `LatexKeyboard` anclado al fondo del `Scaffold`, fuera del `SingleChildScrollView`, envuelto en `ExcludeFocus` para que los botones no roben el foco del campo activo.

---

## [1.1.3] Renderizado y escritura LaTeX - 2026-4-13

### Added

- Agregado `MathText` (nuevo en `lib/views/widgets`):
  - Parser con regex `\$\$(.+?)\$\$|\$(.+?)\$` y `dotAll: true` - el flag es clave para que los saltos de línea dentro de `\begin{pmatrix}...\end{pmatrix}` sean capturados correctamente.
  - `onErrorFallback` loguea con `debugPrint` y muestra el LaTeX crudo en rojo itálico.
- `study_screen.dart`:
  - `AppBar`: nuevo `IconButton` rojo (`stop_circle_outlined`) visible solo cuando `!_isInitializing && !_isFinished`.
  - Nuevo método `_confirmAbandon`: muestra el diálogo, llama `abandonSession()` y hace `Navigator.pop` — en este punto `startOrResumeSession()` ya fue ejecutado, garantizando que `_activeDeckId` apunta al deck correcto.

### Changed

- `card_form_screen.dart`:
  - `_PreviewSide` reemplaza `Text` con `MathText` + `ConstrainedBox(maxHeight: 120)` + `NeverScrollableScrollPhysics` - el preview es indicativo, no hace falta scroll ahí.
  - `crossAxisAlignment: CrossAxisAlignment.start` en el `Row` del preview evita que las dos caras se desalineen cuando una es más alta que la otra.
  - `helperText`en ambos campos explica la sintaxis de delimitadores sin ser invasivo.

- `study_screen.dart`:
  - `_CardFace` ahora usa `Column` con `Expanded > Center > SingleChildScrollView > MathText` - esto permite que una matriz 6x6 se desplace verticalmente sin romper el layout del swipper.
  - `fontSize` bajó de 24 a 22 para dar más margen a contenido matemático denso.

- `pubspec.yaml`: agregado `flutter_math_fork: ^0.7.4` como dependencia del proyecto.

- `card_list_screen.dart`:
  - `AppBar`: el botón ahora solo muestra `Icons.school` (Estudiar) cuando no hay sesión; el estado con sesión activa ya no tiene icono de abandon.

### Removed

- `card_list_screen.dart`:
  - `_ActiveSessionBanner`: eliminado `onAbandon` del constructor, el parámetro y su campo — era requerido pero nunca se usaba en `build`.
  - Eliminado el método `_confirmAbandon`.

### Fixed

## [1.1.2] Bug Fixes - 2026-4-13

---

### Added

- Modelos de Datos:
  - `study_progress.dart`: Nuevo modelo para persistir el progreso parcial de una sesión (índice actual, aciertos, errores). Separado de `study_session.dart` que sigue siendo el modelo del historial.

- Base de Datos:
  - `database_service.dart`: Nueva tabla `study_progress` (deck_id UNIQUE). Métodos `getProgressByDeckId`, `upsertProgress`, `deleteProgress`. Migración a `version: 2` con `_onUpgrade` para instalaciones existentes.

- `session_provider.dart`:
  - Agregado `WidgetsBindingObserver` + `didChangeAppLifecycleState`: guarda el progreso cuando la app va a segundo plano o se cierra.
  - Agregado `checkSavedProgress()`, `hasSavedProgress()`, `hitsFor()`, `missesFor()`: permiten que la UI detecte y muestre progreso pausado aunque no sea el deck activo en memoria.

### Changed

- `session_provider.dart`:
  - `startSession()` reemplazado por `startOrResumeSession(int deckId)` (async): guarda el progreso del deck activo antes de cambiar, luego carga el progreso guardado del nuevo deck desde DB.
  - `updateProgress()` ahora persiste en DB en background (fire-and-forget) además de actualizar el estado en memoria.
  - `completeSession()` restaurado con el parámetro `total` y la lógica original de `StudySession`. Borra el progreso parcial al completar.
  - `abandonSession()` ahora es `async` y borra el progreso parcial de la DB.
  - Agregado `Map<int, StudyProgress?> _progressCache`: guarda el resultado de consultas a DB por deck.
  - `checkSavedProgress(deckId)`: consulta a la DB y llena el cache para el deck en cuestión.
  - `hasSavedProgress(deckId)`: devuelve `true` si hay sesión activa en memoria o progreso en DB. Este es el único bool que usa la UI ahora.
  - `hitsFor(deckId)`/`missesFor(deckId)`: saben de dónde leer dependiendo del estado.
  - El cache se limpia correctamente en `abandonSession`, `completeSession` y `startOrResumeSession`.

- `study_screen.dart`:
  - `_initSession()` ahora es `async`: aguarda `startOrResumeSession()` antes de restaurar el estado local. Muestra un `CircularProgressIndicator` mientras carga.
  - `completeSession()` restaurado con el parámetro `total`.
  - `_restartSession()` ahora es `async` y usa `abandonSession()` + `startOrResumeSession()`.

- `card_list_screen.dart`:
  - `initState` llama a `checkSavedProgress()` además de `checkHasSessions()`.
  - El banner amarillo y los controles de sesión ahora usan `hasSavedProgress()` en lugar de `isSessionActive()`, por lo que se muestran aunque el deck no sea el activo en memoria.
  - `_startStudy()` simplificado: ya no llama a `startSession()` (lo maneja `StudyScreen._initSession()`).

- `models/study_session.dart`: Restaurado al schema original (`hits`, `misses`, `total`, `completedAt`, getter `accuracy`).

- `leaderboard_screen.dart`: Restaurada la visualización de precisión, aciertos, errores, total y fecha por sesión.

### Removed

- `providers/study_provider.dart`: Eliminado. Era código duplicado que no estaba integrado a ninguna vista y referenciaba métodos inexistentes.

### Fixed

- **Bug #1 — Sesión destruida al cambiar de mazo**: `startOrResumeSession()` guarda el progreso del deck anterior en `study_progress` antes de activar el nuevo.
- **Bug #2 — Sesión destruida al cerrar la app**: `WidgetsBindingObserver` en `SessionProvider` persiste el progreso al detectar `AppLifecycleState.paused/inactive/detached`.
- **Bug #3 — Tarjeta siguiente llega volteada**: `FlipCard` recibe `key: ValueKey(card.id)`, forzando un rebuild limpio del widget cuando `CardSwiper` reutiliza la misma posición del árbol.
- **Bug #4 — Banner "Sesión en curso" no aparece en deck pausado**: La condición del banner ahora consulta `hasSavedProgress()` que verifica tanto el estado en memoria como la tabla `study_progress` en DB.
- **Schema en conflicto**: `_onCreate` tenía dos `CREATE TABLE study_sessions` consecutivos; el segundo (con schema diferente) se ignoraba silenciosamente dejando el modelo y la tabla desincronizados.

## [1.1.1] QoL Improvements - 2026-4-9

---

### Added

- Base de Datos:
  - `database_service.dart`: Nueva tabla. Se añadieron 3 métodos.

- Gestión de Estado:
  - `session_provider.dart`

- Modelos de Datos:
  - `study_session.dart`

- Interfaz de Usuario (UI):
  - `leaderboard_screen.dart`

- Assets:
  - Se agregó un logo.

### Changed

- Core:
  - `main.dart`: Se registró `SessionProvider`

- Interfaz de Usuario (UI):
  - `card_list_screen.dart`: Bloqueo de edición + banners + leaderboard.
  - `study_screen.dart`: `_onEnd` guarda sesión, `_onSwipe` reporta progreso.

- Changelog:
  - Se actualizó el formato del `CHANGELOG.md`.

### Deprecated

- No hay funcionalidades obsoletas.

### Removed

- No hay funcionalidades eliminadas.

### Fixed

- `session_provider.dart`:
  - Se añadió `_currentIndex` con su getter para rastrear qué tarjeta se estaba viendo.
  - `startSession()` ahora es **idempotente**: si `_activeDeckId == deckId` retorna sin hacer nada. Antes siempre reseteaba al entrar a la pantalla.
  - `updateProgress()` recibe un 3er parámetro `index` para persistir la posición actual en memoria junto con hits y misses.

- `study_screen.dart`
  - Se añadió `_startOffset` para saber desde qué tarjeta reanudar.
  - `_initSession()` (llamado via `addPostFrameCallback`) detecta si ya hay sesión activa: si sí, restaura `_hits`, `_misses` y `_startOffset`; si no, llama `startSession()`.
  - El `CardSwiper` recibe `cardsCount: _remainingCount` y el `cardBuilder` traduce el índice relativo del swiper al índice real de la lista con `index + _startOffset`. Así el swiper arranca desde la tarjeta pendiente, no desde la primera.
  - `_onSwipe` también convierte `prevIndex` y `currentIndex` al índice real antes de operar.
  - `_restartSession()` llama `abandonSession()` antes de `startSession()` para forzar el reset, ya que ahora `startSession` es idempotente.

## [1.0.0-MVP] - 2026-4-9

---

Este es un registro oficial del primer punto de control estable del proyecto, marcando la finalización del MVP (Minimum Viable Product). Este estado sirve como base de código estable antes de la implementación de nuevas características como anuncios y mejoras de calidad de vida (QoL).

### Added

- Core: Inicialización del proyecto Flutter con estructura de directorios modular.
- Base de Datos (Offline): Capa de acceso a datos SQLite local implementada usando sqflite.
  - `database_service.dart`: Lógica CRUD completa para Decks y Cards.
- Modelos de Datos:
  - `deck.dart`: Modelo de objeto para mazos.
  - `card.dart`: Modelo de objeto para tarjetas con campos de frente y dorso.
- Servicio de Importación:
  - `csv_import_service.dart`: Módulo funcional para leer archivos CSV locales y mapear campos a objetos Card con inserción masiva en la base de datos.
- Gestión de Estado:
  - `deck_provider.dart`: Lógica de negocio y estado para gestionar mazos.
  - `card_provider.dart`: Lógica de negocio y estado para gestionar tarjetas dentro de un mazo.
- Interfaz de Usuario (UI):
  - Mazos:
    - `deck_list_screen.dart`: Pantalla principal con lista de mazos guardados.
    - `deck_form_screen.dart`: Pantalla para crear/editar mazos.
  - Tarjetas:
    - `card_list_screen.dart`: Vista detallada de las tarjetas de un mazo.
    - `card_form_screen.dart`: Pantalla para crear/editar tarjetas individuales.
  - Estudio:
    - `study_screen.dart`: Vista interactiva de estudio con gestos de deslizar (`flutter_card_swiper`) y animaciones de volteo (`flip_card`).

### Changed

- No hay cambios de versiones previas.

### Deprecated

- No hay funcionalidades obsoletas.

### Removed

- No hay funcionalidades eliminadas.

### Fixed

- No hay correcciones de errores en esta versión inicial.
