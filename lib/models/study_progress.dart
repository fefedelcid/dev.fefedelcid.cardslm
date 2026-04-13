/// Modelo para guardar el progreso parcial de una sesión de estudio.
/// Permite reanudar desde donde se dejó (al cambiar de mazo o cerrar la app).
/// Tabla: study_progress (deck_id UNIQUE → una fila por mazo activo).
class StudyProgress {
  final int? id;
  final int deckId;
  final int currentIndex;
  final int correctCount;
  final int incorrectCount;
  final DateTime updatedAt;

  StudyProgress({
    this.id,
    required this.deckId,
    required this.currentIndex,
    required this.correctCount,
    required this.incorrectCount,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'deck_id': deckId,
    'current_index': currentIndex,
    'correct_count': correctCount,
    'incorrect_count': incorrectCount,
    'updated_at': updatedAt.toIso8601String(),
  };

  factory StudyProgress.fromMap(Map<String, dynamic> map) => StudyProgress(
    id: map['id'] as int?,
    deckId: map['deck_id'] as int,
    currentIndex: map['current_index'] as int,
    correctCount: map['correct_count'] as int,
    incorrectCount: map['incorrect_count'] as int,
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );
}
