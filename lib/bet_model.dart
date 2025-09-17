class Bet {
  final int? id;
  final String content;
  final String description;
  final double probability; // Stored as 0.0 to 1.0
  final DateTime createdDate;
  final DateTime resolveDate;
  int? resolvedStatus; // null = unresolved, 1 = YES, 0 = NO

  Bet({
    this.id,
    required this.content,
    required this.description,
    required this.probability,
    required this.createdDate,
    required this.resolveDate,
    this.resolvedStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'description': description,
      'probability': probability,
      'createdDate': createdDate.toIso8601String(),
      'resolveDate': resolveDate.toIso8601String(),
      'resolvedStatus': resolvedStatus,
    };
  }

  factory Bet.fromMap(Map<String, dynamic> map) {
    return Bet(
      id: map['id'],
      content: map['content'],
      description: map['description'],
      probability: map['probability'],
      createdDate: DateTime.parse(map['createdDate']),
      resolveDate: DateTime.parse(map['resolveDate']),
      resolvedStatus: map['resolvedStatus'],
    );
  }
}