import 'package:flutter/foundation.dart';

/// Logger centralizado. En release build, kDebugMode = false y el
/// compilador elimina todas las llamadas como código muerto.
/// Para silenciar en debug puntualmente: AppLogger.enabled = false;
///
/// flutter run 2>&1 | grep -E "\[Session\]|\[DB\]|\[ERROR\]" | tee logs.txt
abstract class AppLogger {
  static bool enabled = kDebugMode;

  static void session(String msg) {
    if (enabled) debugPrint('[Session] $msg');
  }

  static void db(String msg) {
    if (enabled) debugPrint('[DB]      $msg');
  }

  static void error(String tag, Object e) {
    if (enabled) debugPrint('[ERROR][$tag] $e');
  }
}
