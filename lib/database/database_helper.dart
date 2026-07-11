import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/conversation_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'conversations.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE conversations(id INTEGER PRIMARY KEY AUTOINCREMENT, text TEXT, reply TEXT, timestamp TEXT, isUser INTEGER)',
        );
      },
    );
  }

  Future<int> insertConversation(Conversation conversation) async {
    Database db = await database;
    return await db.insert('conversations', conversation.toMap());
  }

  Future<List<Conversation>> getConversations() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'conversations',
      orderBy: 'id DESC',
      limit: 100,
    );
    return List.generate(maps.length, (i) => Conversation.fromMap(maps[i]));
  }

  Future<void> clearConversations() async {
    Database db = await database;
    await db.delete('conversations');
  }
}
