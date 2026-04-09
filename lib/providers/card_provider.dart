import 'package:flutter/material.dart';
import '../models/card.dart';
import '../services/database_service.dart';
import '../services/csv_import_service.dart';

class CardProvider extends ChangeNotifier {
  final _db = DatabaseService();
  final _csvService = CsvImportService();

  List<FlashCard> _cards = [];
  bool _isLoading = false;
  String? _error;
  int? _currentDeckId;

  List<FlashCard> get cards => List.unmodifiable(_cards);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCards(int deckId) async {
    _currentDeckId = deckId;
    _setLoading(true);
    try {
      _cards = await _db.getCardsByDeck(deckId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addCard(FlashCard card) async {
    try {
      final id = await _db.insertCard(card);
      _cards.add(card.copyWith(id: id));
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateCard(FlashCard card) async {
    try {
      await _db.updateCard(card);
      final index = _cards.indexWhere((c) => c.id == card.id);
      if (index != -1) _cards[index] = card;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteCard(int id) async {
    try {
      await _db.deleteCard(id);
      _cards.removeWhere((c) => c.id == id);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Importa desde CSV y persiste en lote. Retorna el número de cards importadas.
  Future<int> importFromCsv(int deckId) async {
    _setLoading(true);
    try {
      final newCards = await _csvService.pickAndParseCsv(deckId: deckId);
      if (newCards.isEmpty) return 0;

      await _db.insertCardsBatch(newCards);

      // Recargar desde BD para obtener los IDs generados
      if (_currentDeckId == deckId) await loadCards(deckId);

      _error = null;
      return newCards.length;
    } on FormatException catch (e) {
      _error = e.message;
      notifyListeners();
      return 0;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return 0;
    } finally {
      _setLoading(false);
    }
  }

  /// Registra acierto y persiste.
  Future<void> recordHit(FlashCard card) async {
    final updated = card.copyWith(hits: card.hits + 1);
    await updateCard(updated);
  }

  /// Registra error y persiste.
  Future<void> recordMiss(FlashCard card) async {
    final updated = card.copyWith(misses: card.misses + 1);
    await updateCard(updated);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
