import 'package:expense_tracker/features/dashboard/models/category_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class CategoryDB {
  static final CategoryDB instance = CategoryDB._internal();
  CategoryDB._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'categories.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            iconCode INTEGER,
            colorCode INTEGER
          )''');
      },
    );
  }

  // ✅ INSERT Category
  Future<int> insertCategory(CategoryModel category) async {
    final db = await database;
    return db.insert('categories', category.toMap());
  }

  // ✅ FETCH Categories
  Future<List<CategoryModel>> fetchCategories() async {
    final db = await database;
    final result = await db.query('categories');
    return result.map((map) => CategoryModel.fromMap(map)).toList();
  }

  // ✅ UPDATE Category
  Future<int> updateCategory(CategoryModel category) async {
    final db = await database;
    return db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  // ✅ DELETE Category
  Future<int> deleteCategory(int id) async {
    final db = await database;
    return db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ✅ OPTIONAL: Delete All Categories
  Future<int> clearCategories() async {
    final db = await database;
    return db.delete('categories');
  }
}
