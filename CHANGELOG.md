# Changelog

Todos los cambios importantes de este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/).

## [Unreleased]

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

- No hay correcciones de errores en esta versión inicial.

### TODO

- [ ] Arreglar el guardado de sesión `study_screen.dart > _onEnd`: Al salir de la misma, incluso al salir del mazo, el progreso se observa mas no se puede retomar la sesión, sino que ésta se reinicia.
- [ ] Agregar sintaxis LaTeX para tarjetas con ecuaciones matemáticas.
  - [ ] Agregar funcionalidad para escribir LaTeX sin mucha complicación (ver implementación en `com.bagatrix.mathway`)
- [ ] Agregar monetización y publicar en PlayStore.

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
