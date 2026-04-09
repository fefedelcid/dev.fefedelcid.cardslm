// Evitamos conflicto con el widget Card de Flutter usando alias en imports.
class FlashCard {
  final int? id;
  final int deckId;
  final String front;
  final String back;
  final int hits;
  final int misses;

  FlashCard({
    this.id,
    required this.deckId,
    required this.front,
    required this.back,
    this.hits = 0,
    this.misses = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'deck_id': deckId,
    'front': front,
    'back': back,
    'hits': hits,
    'misses': misses,
  };

  factory FlashCard.fromMap(Map<String, dynamic> map) => FlashCard(
    id: map['id'] as int?,
    deckId: map['deck_id'] as int,
    front: map['front'] as String,
    back: map['back'] as String,
    hits: map['hits'] as int? ?? 0,
    misses: map['misses'] as int? ?? 0,
  );

  FlashCard copyWith({
    int? id,
    String? front,
    String? back,
    int? hits,
    int? misses,
  }) => FlashCard(
    id: id ?? this.id,
    deckId: deckId,
    front: front ?? this.front,
    back: back ?? this.back,
    hits: hits ?? this.hits,
    misses: misses ?? this.misses,
  );
}
