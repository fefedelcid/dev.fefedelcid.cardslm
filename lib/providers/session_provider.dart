import 'package:flutter/material.dart';
import '../models/study_session.dart';
import '../services/database_service.dart';

class SessionProvider extends ChangeNotifier {
  final _db = DatabaseService();

  // ── Estado de sesión activa ───────────────────────────
  int? _activeDeckId;
  int _currentHits = 0;
  int _currentMisses = 0;
  int _currentIndex = 0; // ← NUEVO: índice de la tarjeta actual

  int? get activeDeckId => _activeDeckId;
  int get currentHits => _currentHits;
  int get currentMisses => _currentMisses;
  int get currentIndex => _currentIndex; // ← NUEVO

  bool isSessionActive(int deckId) => _activeDeckId == deckId;
  bool get hasActiveSession => _activeDeckId != null;

  // ── Leaderboard ───────────────────────────────────────
  List<StudySession> _sessions = [];
  bool _hasAnySessions = false;

  List<StudySession> get sessions => List.unmodifiable(_sessions);
  bool get hasAnySessions => _hasAnySessions;

  // ── Control de sesión ─────────────────────────────────

  /// Inicia una sesión nueva SOLO si no hay una activa para este deck.
  /// Si ya existe una sesión para el mismo deck, no hace nada (idempotente).
  void startSession(int deckId) {
    // ← CAMBIO CLAVE: no resetear si ya hay sesión activa para este deck
    if (_activeDeckId == deckId) return;

    _activeDeckId = deckId;
    _currentHits = 0;
    _currentMisses = 0;
    _currentIndex = 0;
    notifyListeners();
  }

  /// Actualiza el progreso en curso (se llama en cada swipe).
  void updateProgress(int hits, int misses, int index) {
    // ← index añadido
    _currentHits = hits;
    _currentMisses = misses;
    _currentIndex = index; // ← persiste el índice actual en memoria
    notifyListeners();
  }

  /// Persiste la sesión completada y limpia el estado activo.
  Future<void> completeSession({
    required int deckId,
    required int hits,
    required int misses,
    required int total,
  }) async {
    final session = StudySession(
      deckId: deckId,
      hits: hits,
      misses: misses,
      total: total,
      completedAt: DateTime.now(),
    );

    await _db.insertSession(session);

    _activeDeckId = null;
    _currentHits = 0;
    _currentMisses = 0;
    _currentIndex = 0;

    await loadSessions(deckId);
  }

  /// Abandona sin guardar. Limpia el estado activo.
  void abandonSession() {
    _activeDeckId = null;
    _currentHits = 0;
    _currentMisses = 0;
    _currentIndex = 0;
    notifyListeners();
  }

  // ── Leaderboard ───────────────────────────────────────

  Future<void> loadSessions(int deckId) async {
    try {
      _sessions = await _db.getSessionsByDeck(deckId);
      _hasAnySessions = _sessions.isNotEmpty;
    } catch (e) {
      _sessions = [];
      _hasAnySessions = false;
    }
    notifyListeners();
  }

  Future<void> checkHasSessions(int deckId) async {
    _hasAnySessions = await _db.hasSessionsForDeck(deckId);
    notifyListeners();
  }
}
