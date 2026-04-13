import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/deck.dart';
import '../models/card.dart';
import '../models/study_session.dart';
import '../models/study_progress.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'flashcards.db');
    return openDatabase(
      path,
      version: 2, // ← bumped de 1 a 2 para agregar study_progress
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  /// Instalaciones nuevas: crea las 4 tablas desde cero.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE decks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        deck_id INTEGER NOT NULL,
        front TEXT NOT NULL,
        back TEXT NOT NULL,
        hits INTEGER NOT NULL DEFAULT 0,
        misses INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (deck_id) REFERENCES decks (id) ON DELETE CASCADE
      )
    ''');

    // Historial de sesiones completadas (leaderboard).
    await db.execute('''
      CREATE TABLE study_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        deck_id INTEGER NOT NULL,
        hits INTEGER NOT NULL,
        misses INTEGER NOT NULL,
        total INTEGER NOT NULL,
        completed_at TEXT NOT NULL,
        FOREIGN KEY (deck_id) REFERENCES decks (id) ON DELETE CASCADE
      )
    ''');

    // Progreso parcial de sesión en curso (para reanudar).
    await db.execute('''
      CREATE TABLE study_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        deck_id INTEGER NOT NULL UNIQUE,
        current_index INTEGER NOT NULL DEFAULT 0,
        correct_count INTEGER NOT NULL DEFAULT 0,
        incorrect_count INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (deck_id) REFERENCES decks(id) ON DELETE CASCADE
      )
    ''');
  }

  /// Usuarios existentes en v1: solo agregar study_progress.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS study_progress (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          deck_id INTEGER NOT NULL UNIQUE,
          current_index INTEGER NOT NULL DEFAULT 0,
          correct_count INTEGER NOT NULL DEFAULT 0,
          incorrect_count INTEGER NOT NULL DEFAULT 0,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (deck_id) REFERENCES decks(id) ON DELETE CASCADE
        )
      ''');
    }
  }

  // ── DECKS ──────────────────────────────────────────────

  Future<int> insertDeck(Deck deck) async {
    try {
      final db = await database;
      return await db.insert('decks', deck.toMap()..remove('id'));
    } catch (e) {
      throw Exception('Error al insertar deck: $e');
    }
  }

  Future<List<Deck>> getAllDecks() async {
    try {
      final db = await database;
      final maps = await db.query('decks', orderBy: 'created_at DESC');
      return maps.map(Deck.fromMap).toList();
    } catch (e) {
      throw Exception('Error al obtener decks: $e');
    }
  }

  Future<int> updateDeck(Deck deck) async {
    try {
      final db = await database;
      return await db.update(
        'decks',
        deck.toMap(),
        where: 'id = ?',
        whereArgs: [deck.id],
      );
    } catch (e) {
      throw Exception('Error al actualizar deck: $e');
    }
  }

  Future<int> deleteDeck(int id) async {
    try {
      final db = await database;
      return await db.delete('decks', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw Exception('Error al eliminar deck: $e');
    }
  }

  // ── CARDS ──────────────────────────────────────────────

  Future<int> insertCard(FlashCard card) async {
    try {
      final db = await database;
      return await db.insert('cards', card.toMap()..remove('id'));
    } catch (e) {
      throw Exception('Error al insertar card: $e');
    }
  }

  Future<void> insertCardsBatch(List<FlashCard> cards) async {
    try {
      final db = await database;
      final batch = db.batch();
      for (final card in cards) {
        batch.insert('cards', card.toMap()..remove('id'));
      }
      await batch.commit(noResult: true);
    } catch (e) {
      throw Exception('Error en importación por lote: $e');
    }
  }

  Future<List<FlashCard>> getCardsByDeck(int deckId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'cards',
        where: 'deck_id = ?',
        whereArgs: [deckId],
      );
      return maps.map(FlashCard.fromMap).toList();
    } catch (e) {
      throw Exception('Error al obtener cards: $e');
    }
  }

  Future<int> updateCard(FlashCard card) async {
    try {
      final db = await database;
      return await db.update(
        'cards',
        card.toMap(),
        where: 'id = ?',
        whereArgs: [card.id],
      );
    } catch (e) {
      throw Exception('Error al actualizar card: $e');
    }
  }

  Future<int> deleteCard(int id) async {
    try {
      final db = await database;
      return await db.delete('cards', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw Exception('Error al eliminar card: $e');
    }
  }

  Future<int> getCardCountByDeck(int deckId) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM cards WHERE deck_id = ?',
        [deckId],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // ── STUDY SESSIONS (historial / leaderboard) ───────────

  Future<int> insertSession(StudySession session) async {
    try {
      final db = await database;
      return await db.insert('study_sessions', session.toMap()..remove('id'));
    } catch (e) {
      throw Exception('Error al guardar sesión: $e');
    }
  }

  Future<List<StudySession>> getSessionsByDeck(int deckId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'study_sessions',
        where: 'deck_id = ?',
        whereArgs: [deckId],
        orderBy: 'completed_at DESC',
      );
      return maps.map(StudySession.fromMap).toList();
    } catch (e) {
      throw Exception('Error al obtener sesiones: $e');
    }
  }

  Future<StudySession?> getSessionByDeck(int deckId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'study_progress',
        where: 'deck_id = ?',
        whereArgs: [deckId],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      final progress = StudyProgress.fromMap(maps.first);
      return StudySession(
        deckId: deckId,
        hits: progress.correctCount,
        misses: progress.incorrectCount,
        total: progress.currentIndex,
        completedAt: progress.updatedAt,
      );
    } catch (e) {
      debugPrint('Error al obtener sesión por deck: $e');
      return null;
    }
  }

  Future<bool> hasSessionsForDeck(int deckId) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM study_sessions WHERE deck_id = ?',
        [deckId],
      );
      return (Sqflite.firstIntValue(result) ?? 0) > 0;
    } catch (e) {
      return false;
    }
  }

  // ── STUDY PROGRESS (reanudación de sesión parcial) ──────

  Future<StudyProgress?> getProgressByDeckId(int deckId) async {
    try {
      final db = await database;
      final results = await db.query(
        'study_progress',
        where: 'deck_id = ?',
        whereArgs: [deckId],
        limit: 1,
      );
      if (results.isEmpty) return null;
      return StudyProgress.fromMap(results.first);
    } catch (e) {
      debugPrint('Error al obtener progreso: $e');
      return null;
    }
  }

  Future<void> upsertProgress(StudyProgress progress) async {
    try {
      final db = await database;
      await db.insert(
        'study_progress',
        progress.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error al guardar progreso: $e');
    }
  }

  Future<void> deleteProgress(int deckId) async {
    try {
      final db = await database;
      await db.delete(
        'study_progress',
        where: 'deck_id = ?',
        whereArgs: [deckId],
      );
    } catch (e) {
      debugPrint('Error al eliminar progreso: $e');
    }
  }
}
