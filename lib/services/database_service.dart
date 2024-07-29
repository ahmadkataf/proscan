import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/document_model.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  initDB() async {
    String path = await getDatabasesPath();
    return await openDatabase(
      join(path, 'proscan_database.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE documents(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            filePath TEXT,
            dateCreated TEXT,
            category TEXT
          )
        ''');
      },
      version: 2,
    );
  }

  Future<int> insertDocument(Document document) async {
    final db = await database;
    return await db.insert('documents', document.toMap());
  }

  Future<List<Document>> getDocuments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('documents', orderBy: 'dateCreated DESC');
    return List.generate(maps.length, (i) => Document.fromMap(maps[i]));
  }

  Future<List<Document>> searchDocuments({
    String? query,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    final db = await database;
    List<String> whereConditions = [];
    List<dynamic> whereArgs = [];

    if (query != null && query.isNotEmpty) {
      whereConditions.add('(title LIKE ? OR category LIKE ?)');
      whereArgs.addAll(['%$query%', '%$query%']);
    }

    if (startDate != null) {
      whereConditions.add('dateCreated >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereConditions.add('dateCreated <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    if (category != null && category.isNotEmpty) {
      whereConditions.add('category = ?');
      whereArgs.add(category);
    }

    String whereClause =
        whereConditions.isEmpty ? '' : whereConditions.join(' AND ');

    final List<Map<String, dynamic>> maps = await db.query(
      'documents',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'dateCreated DESC',
    );

    return List.generate(maps.length, (i) => Document.fromMap(maps[i]));
  }

  Future<int> updateDocument(Document document) async {
    final db = await database;
    return await db.update(
      'documents',
      document.toMap(),
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }
}
