class Document {
  final int? id;
  String title;
  final String filePath;
  final DateTime dateCreated;
  String category;

  Document({
    this.id,
    required this.title,
    required this.filePath,
    required this.dateCreated,
    this.category = 'Uncategorized',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'filePath': filePath,
      'dateCreated': dateCreated.toIso8601String(),
      'category': category,
    };
  }

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'],
      title: map['title'],
      filePath: map['filePath'],
      dateCreated: DateTime.parse(map['dateCreated']),
      category: map['category'] ?? 'Uncategorized',
    );
  }
}
