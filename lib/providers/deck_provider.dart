import 'package:flutter/material.dart';
import '../models/deck.dart';
import '../services/database_service.dart';

class DeckProvider extends ChangeNotifier {
  final _db = DatabaseService();

  List<Deck> _decks = [];
  bool _isLoading = false;
  String? _error;

  List<Deck> get decks => List.unmodifiable(_decks);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDecks() async {
    _setLoading(true);
    try {
      _decks = await _db.getAllDecks();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addDeck(String name, {String? description}) async {
    try {
      final id = await _db.insertDeck(
        Deck(name: name, description: description),
      );
      _decks.insert(0, Deck(id: id, name: name, description: description));
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateDeck(Deck deck) async {
    try {
      await _db.updateDeck(deck);
      final index = _decks.indexWhere((d) => d.id == deck.id);
      if (index != -1) _decks[index] = deck;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteDeck(int id) async {
    try {
      await _db.deleteDeck(id);
      _decks.removeWhere((d) => d.id == id);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
