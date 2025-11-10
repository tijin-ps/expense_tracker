import 'package:expense_tracker/features/wallet/models/expense_model.dart';
import 'package:expense_tracker/features/wallet/models/income_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static Database? _db;

  Future<Database> get database async {
    _db ??= await initDB();
    return _db!;
  }

  initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'wallet.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute("""
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            amount REAL,
            category TEXT,
            date TEXT,
            card TEXT
          )
        """);

        await db.execute("""
          CREATE TABLE income (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            description TEXT,
            amount REAL,
            category TEXT,
            date TEXT,
            card TEXT 
          )
        """);

        await db.execute('''
          CREATE TABLE user (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            dob TEXT NOT NULL,
            gender TEXT NOT NULL,
            image_path TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE budget (
            id INTEGER PRIMARY KEY,
            amount REAL NOT NULL
          )
        ''');
      },
    );
  }

  // ---------------- EXPENSE ----------------
  Future<int> insertExpense(ExpenseModel model) async {
    final db = await database;
    return await db.insert('expenses', model.toMap());
  }

  Future<List<ExpenseModel>> getExpenses() async {
    final db = await database;
    final data = await db.query('expenses', orderBy: "id DESC");
    return data.map((e) => ExpenseModel.fromMap(e)).toList();
  }

  Future<int> updateExpense(ExpenseModel model) async {
    final db = await database;
    return await db.update(
      'expenses',
      model.toMap(),
      where: "id = ?",
      whereArgs: [model.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete('expenses', where: "id = ?", whereArgs: [id]);
  }

  // ---------------- INCOME ----------------
  Future<int> insertIncome(IncomeModel model) async {
    final db = await database;
    return await db.insert('income', model.toMap());
  }

  Future<int> deleteIncome(int id) async {
    final db = await database;
    return await db.delete('income', where: "id = ?", whereArgs: [id]);
  }

  Future<int> updateIncome(IncomeModel model) async {
    final db = await database;
    return await db.update(
      'income',
      model.toMap(),
      where: "id = ?",
      whereArgs: [model.id],
    );
  }

  Future<List<IncomeModel>> getAllIncome() async {
    final db = await database;
    final data = await db.query("income", orderBy: "id DESC");
    return data.map((e) => IncomeModel.fromMap(e)).toList();
  }

  // ---------------- USER PROFILE ----------------

  Future<int> saveProfile({
    required String firstName,
    required String lastName,
    required String dob,
    required String gender,
    String? imagePath,
  }) async {
    final db = await database;

    final existing = await db.query("user", limit: 1);

    final profileData = {
      'first_name': firstName,
      'last_name': lastName,
      'dob': dob,
      'gender': gender,
      'image_path': imagePath,
    };

    if (existing.isEmpty) {
      return await db.insert("user", profileData);
    } else {
      final id = existing.first["id"];
      return await db.update(
        "user",
        profileData,
        where: "id = ?",
        whereArgs: [id],
      );
    }
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final db = await database;
    final data = await db.query("user", limit: 1);
    if (data.isEmpty) return null;
    return data.first;
  }

  // ---------------- BUDGET ----------------

  Future<void> saveBudget(double amount) async {
    final db = await database;
    final existing = await db.query("budget", limit: 1);
    if (existing.isEmpty) {
      await db.insert("budget", {'id': 1, 'amount': amount});
    } else {
      await db.update(
        "budget",
        {'amount': amount},
        where: "id = ?",
        whereArgs: [1],
      );
    }
  }

  Future<double?> getBudget() async {
    final db = await database;
    final data = await db.query("budget", limit: 1);
    if (data.isNotEmpty) {
      return data.first['amount'] as double?;
    }
    return null;
  }
}
