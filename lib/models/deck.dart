class Deck {
  final int? id;
  final String name;
  final String? description;
  final DateTime createdAt;

  Deck({this.id, required this.name, this.description, DateTime? createdAt})
    : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'created_at': createdAt.toIso8601String(),
  };

  factory Deck.fromMap(Map<String, dynamic> map) => Deck(
    id: map['id'] as int?,
    name: map['name'] as String,
    description: map['description'] as String?,
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  Deck copyWith({int? id, String? name, String? description}) => Deck(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    createdAt: createdAt,
  );
}
