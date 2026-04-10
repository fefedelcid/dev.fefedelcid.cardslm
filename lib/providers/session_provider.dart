import 'package:flutter/material.dart';
import '../models/study_session.dart';
import '../services/database_service.dart';

class SessionProvider extends ChangeNotifier {
  final _db = DatabaseService();

  // ── Estado de sesión activa ───────────────────────────
  int? _activeDeckId;
  int _currentHits = 0;
  int _currentMisses = 0;

  int? get activeDeckId => _activeDeckId;
  int get currentHits => _currentHits;
  int get currentMisses => _currentMisses;

  bool isSessionActive(int deckId) => _activeDeckId == deckId;
  bool get hasActiveSession => _activeDeckId != null;

  // ── Leaderboard ───────────────────────────────────────
  List<StudySession> _sessions = [];
  bool _hasAnySessions = false;

  List<StudySession> get sessions => List.unmodifiable(_sessions);
  bool get hasAnySessions => _hasAnySessions;

  // ── Control de sesión ─────────────────────────────────

  void startSession(int deckId) {
    _activeDeckId = deckId;
    _currentHits = 0;
    _currentMisses = 0;
    notifyListeners();
  }

  void updateProgress(int hits, int misses) {
    _currentHits = hits;
    _currentMisses = misses;
    notifyListeners();
  }

  /// Persiste la sesión y limpia el estado activo.
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

    // Recargar leaderboard del deck recién completado
    await loadSessions(deckId);
  }

  /// Abandona sin guardar. El estado activo persiste en memoria
  /// mientras la app siga abierta (el usuario puede retomar).
  void abandonSession() {
    _activeDeckId = null;
    _currentHits = 0;
    _currentMisses = 0;
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
