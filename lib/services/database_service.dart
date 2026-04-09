import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/deck.dart';
import '../models/card.dart';

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
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

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
      // ON DELETE CASCADE elimina las cards asociadas automáticamente.
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
}
