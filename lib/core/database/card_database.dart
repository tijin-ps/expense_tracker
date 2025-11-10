import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class CardDatabase {
  static final CardDatabase instance = CardDatabase._init();
  static Database? _database;

  CardDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB("cards.db");
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE cards (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bank TEXT,
      number TEXT,
      expiry TEXT,
      holder TEXT,
      balance REAL,   -- ✅ FIXED HERE
      type TEXT
    )
  ''');
  }

  Future<int> addCard(Map<String, dynamic> card) async {
    final db = await instance.database;
    return await db.insert("cards", card);
  }

  Future<List<Map<String, dynamic>>> getCards() async {
    final db = await instance.database;
    return await db.query("cards");
  }

  Future<int> deleteCard(int id) async {
    final db = await instance.database;
    return await db.delete("cards", where: "id = ?", whereArgs: [id]);
  }
}
