# Changelog

Todos los cambios importantes de este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/).

## [Unreleased]

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
