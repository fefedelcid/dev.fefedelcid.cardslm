class StudySession {
  final int? id;
  final int deckId;
  final int hits;
  final int misses;
  final int total;
  final DateTime completedAt;

  StudySession({
    this.id,
    required this.deckId,
    required this.hits,
    required this.misses,
    required this.total,
    required this.completedAt,
  });

  int get accuracy => total > 0 ? (hits / total * 100).round() : 0;

  Map<String, dynamic> toMap() => {
    'id': id,
    'deck_id': deckId,
    'hits': hits,
    'misses': misses,
    'total': total,
    'completed_at': completedAt.toIso8601String(),
  };

  factory StudySession.fromMap(Map<String, dynamic> map) => StudySession(
    id: map['id'] as int?,
    deckId: map['deck_id'] as int,
    hits: map['hits'] as int,
    misses: map['misses'] as int,
    total: map['total'] as int,
    completedAt: DateTime.parse(map['completed_at'] as String),
  );
}
