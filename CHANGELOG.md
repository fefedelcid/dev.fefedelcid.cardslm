## [1.0.0-MVP] - 9/4/2026

Este es un registro oficial del primer punto de control estable del proyecto, marcando la finalización del MVP (Minimum Viable Product). Este estado sirve como base de código estable antes de la implementación de nuevas características como anuncios y mejoras de calidad de vida (QoL).

### Added

- Core: Inicialización del proyecto Flutter con estructura de directorios modular.

- Base de Datos (Offline): Capa de acceso a datos SQLite local implementada usando sqflite.
  - database_service.dart: Lógica CRUD completa para Decks y Cards.

- Modelos de Datos:
  - deck.dart: Modelo de objeto para mazos.
  - card.dart: Modelo de objeto para tarjetas con campos de frente y dorso.

- Servicio de Importación:
  - csv_import_service.dart: Módulo funcional para leer archivos CSV locales y mapear campos a objetos Card con inserción masiva en la base de datos.

- Gestión de Estado:
  - deck_provider.dart: Lógica de negocio y estado para gestionar mazos.
  - card_provider.dart: Lógica de negocio y estado para gestionar tarjetas dentro de un mazo.

- Interfaz de Usuario (UI):
  - Mazos:
    - deck_list_screen.dart: Pantalla principal con lista de mazos guardados.
    - deck_form_screen.dart: Pantalla para crear/editar mazos.

  - Tarjetas:
    - card_list_screen.dart: Vista detallada de las tarjetas de un mazo.
    - card_form_screen.dart: Pantalla para crear/editar tarjetas individuales.

  - Estudio:
    - study_screen.dart: Vista interactiva de estudio con gestos de deslizar (flutter_card_swiper) y animaciones de volteo (flip_card).

### Changed

- No hay cambios de versiones previas.

### Deprecated

- No hay funcionalidades obsoletas.

### Removed

- No hay funcionalidades eliminadas.

### Fixed

- No hay correcciones de errores en esta versión inicial.

---

### Próximos Pasos (V 1.1.0):

- Implementación de AdMob (Banners y posiblemente Interstitials).
- Mejoras de QoL (ej. búsqueda de mazos, filtros de tarjetas).
- Mejoras menores de UI.
