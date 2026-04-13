import 'package:flutter/material.dart';
import '../models/study_session.dart';
import '../models/study_progress.dart';
import '../services/database_service.dart';

class SessionProvider extends ChangeNotifier with WidgetsBindingObserver {
  final _db = DatabaseService();

  // ── Estado de sesión activa ───────────────────────────
  int? _activeDeckId;
  int _currentHits = 0;
  int _currentMisses = 0;
  int _currentIndex = 0;

  int? get activeDeckId => _activeDeckId;
  int get currentHits => _currentHits;
  int get currentMisses => _currentMisses;
  int get currentIndex => _currentIndex;

  bool isSessionActive(int deckId) => _activeDeckId == deckId;
  bool get hasActiveSession => _activeDeckId != null;

  // ── Leaderboard ───────────────────────────────────────
  List<StudySession> _sessions = [];
  bool _hasAnySessions = false;

  List<StudySession> get sessions => List.unmodifiable(_sessions);
  bool get hasAnySessions => _hasAnySessions;

  SessionProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  // ── Control de sesión ─────────────────────────────────

  /// Inicia o reanuda la sesión para [deckId].
  /// Si había otra sesión activa, guarda su progreso antes de cambiar.
  /// Si ya existe progreso guardado para [deckId], lo restaura.
  Future<void> startOrResumeSession(int deckId) async {
    // Idempotente: si ya está activa para este deck, no hace nada.
    if (_activeDeckId == deckId) return;

    // Guardar progreso del deck anterior antes de cambiar (Bug #1).
    if (_activeDeckId != null) {
      await _persistProgress();
    }

    _activeDeckId = deckId;

    // Intentar restaurar progreso guardado en DB.
    final saved = await _db.getProgressByDeckId(deckId);
    if (saved != null) {
      _currentHits = saved.correctCount;
      _currentMisses = saved.incorrectCount;
      _currentIndex = saved.currentIndex;
    } else {
      _currentHits = 0;
      _currentMisses = 0;
      _currentIndex = 0;
    }

    notifyListeners();
  }

  /// Actualiza el progreso en curso y lo persiste en DB (fire-and-forget).
  void updateProgress(int hits, int misses, int index) {
    _currentHits = hits;
    _currentMisses = misses;
    _currentIndex = index;
    notifyListeners();
    _persistProgress(); // no await: no bloquea la UI
  }

  /// Persiste la sesión completada en el historial y limpia el estado activo.
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
    await _db.deleteProgress(deckId); // ya no necesita reanudarse

    _activeDeckId = null;
    _currentHits = 0;
    _currentMisses = 0;
    _currentIndex = 0;

    await loadSessions(deckId);
  }

  /// Abandona sin guardar en historial. Borra también el progreso parcial.
  Future<void> abandonSession() async {
    if (_activeDeckId != null) {
      await _db.deleteProgress(_activeDeckId!);
    }
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

  // ── Ciclo de vida de la app ───────────────────────────

  /// Guarda el progreso cuando la app va a segundo plano (Bug #2).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _persistProgress();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ── Helpers privados ──────────────────────────────────

  Future<void> _persistProgress() async {
    if (_activeDeckId == null) return;
    final progress = StudyProgress(
      deckId: _activeDeckId!,
      currentIndex: _currentIndex,
      correctCount: _currentHits,
      incorrectCount: _currentMisses,
      updatedAt: DateTime.now(),
    );
    await _db.upsertProgress(progress);
  }
}
