# 🃏 FlashCards

> Estudia más inteligente, no más duro. Una app de tarjetas interactivas offline-first para Android.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart)
![SQLite](https://img.shields.io/badge/SQLite-sqflite-003B57?style=flat-square&logo=sqlite)
![Version](https://img.shields.io/badge/versión-1.1.2-brightgreen?style=flat-square)
![Platform](https://img.shields.io/badge/plataforma-Android-3DDC84?style=flat-square&logo=android)

---

## ¿Qué es esto?

FlashCards es una app Android para crear mazos de tarjetas de estudio, repasar conceptos con flip & swipe, y llevar un historial de sesiones. Funciona **completamente offline**, sin cuentas, sin nube, sin ads molestos (todavía).

El código fue construido en colaboración estrecha con IA (**vibecodeado**, si quieres llamarle así), pero detrás hay decisiones de arquitectura reales, un modelo de datos normalizado, migraciones de BD versionadas y lógica de negocio pensada para escalar. No es spaghetti que funciona de casualidad.

---

## Funcionalidades actuales (`v1.1.2`)

- 📚 **CRUD de Mazos y Tarjetas** — crea, edita y elimina decks y cards
- 📥 **Importación masiva desde CSV** — sube cientos de tarjetas en segundos
- 🔄 **Sesión de estudio con flip + swipe** — voltea la tarjeta, desliza para acierto/error
- 💾 **Reanudación de sesión** — cierra la app, vuelve y sigue donde quedaste
- 📊 **Historial de sesiones** — revisa tu precisión, aciertos y errores por sesión
- 🔒 **100% offline** — ni un solo byte sale del dispositivo

---

## Stack

| Capa           | Tecnología                          |
| -------------- | ----------------------------------- |
| Framework      | Flutter / Dart                      |
| Base de datos  | `sqflite` + `path_provider`         |
| Estado         | `provider`                          |
| Importación    | `file_picker` + `csv`               |
| UI de tarjetas | `flip_card` + `flutter_card_swiper` |

---

## Arquitectura

El proyecto sigue una separación estricta de responsabilidades:

```
lib/
├── models/          # Entidades de datos puras (Dart)
├── services/        # Acceso a SQLite y parseo de CSV
├── providers/       # Estado de la aplicación (ChangeNotifier)
└── views/           # Pantallas de UI
```

No hay lógica de negocio en los widgets, no hay queries SQL en los providers, no hay estado en los services. Cada capa hace exactamente lo suyo.

La base de datos está en **versión 2**, con migraciones encadenadas en `_onUpgrade` para no romper instalaciones existentes.

---

## Comenzar

### Requisitos

- Flutter SDK `>=3.0.0`
- Android SDK `>=21` (Android 5.0+)
- Dart `>=3.0.0`

### Instalación

```bash
git clone https://github.com/tu-usuario/flashcards.git
cd flashcards
flutter pub get
flutter run
```

### Importar tarjetas desde CSV

El archivo debe tener dos columnas: `front` y `back`. Sin encabezados especiales, sin complicaciones.

```csv
¿Capital de Francia?,París
¿Cuánto es 7 × 8?,56
¿Quién escribió el Quijote?,Cervantes
```

Desde la pantalla del mazo, tocá el ícono de importar y seleccioná tu archivo. El resto es automático.

---

## Contribuir

Toda contribución es bienvenida. Algunos puntos a tener en cuenta antes de abrir un PR:

### Lo que hay que respetar

1. **La arquitectura no se negocia.** Nada de colapsar capas, nada de queries en los widgets.
2. **Toda operación de BD va en `try-catch`** con `debugPrint` del error. Sin excepciones silenciadas.
3. **Nuevas tablas o columnas = nueva migración en `_onUpgrade`** + incremento de `version` en `openDatabase`.
4. **`hasSavedProgress()`** es la única fuente de verdad para banners de sesión en la UI. No usar `isSessionActive()`.
5. **`FlipCard` dentro de un swiper siempre lleva `key: ValueKey(card.id)`** — sin esto la siguiente tarjeta puede aparecer ya volteada.
6. **El código, comentarios y textos de UI van en español.**

### Flujo de trabajo

```bash
# 1. Crea tu rama
git checkout -b feat/nombre-de-la-feature

# 2. Desarrolla y testea en dispositivo/emulador físico
flutter run

# 3. Verifica que no rompiste nada
flutter analyze

# 4. Abre el PR con descripción clara de qué cambia y por qué
```

### Backlog abierto (buenos puntos de entrada)

- [ ] Integración de `google_mobile_ads` (banners no intrusivos)
- [ ] Algoritmo de repetición espaciada (SRS tipo Anki)
- [ ] Exportación de progreso a CSV
- [ ] Soporte para imágenes en tarjetas
- [ ] Temas claro/oscuro

Si vas a trabajar en alguno de estos, abrí un issue primero para coordinar.

---

## Estructura de la BD

```sql
-- Mazos
decks (id, name, description)

-- Tarjetas
cards (id, deck_id, front, back)

-- Historial de sesiones completadas
study_sessions (id, deck_id, hits, misses, total, completed_at)

-- Progreso parcial de sesión activa (UPSERT, 1 fila por deck)
study_progress (id, deck_id, current_index, hits, misses)
```

---

## Sobre el proceso de desarrollo

Este proyecto nació y creció con IA como par de programación. No como generador de código desechable, sino como colaborador real: proponiendo estructuras, detectando inconsistencias, ayudando a pensar las migraciones y los edge cases de estado.

¿Vibecodeado? Sí. ¿Descuidado? Para nada.

Si creés que el código asistido por IA no puede ser limpio y bien pensado, este proyecto existe para demostrar lo contrario. Si ya lo sabías, bienvenido al equipo.

---

## Licencia

MIT — hacé lo que quieras, pero no te olvides de la atribución.

---

_Última actualización del documento: v1.1.4_
