import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class TransactionModel {
  final int? id;
  final String merchant;
  final double amount;
  final String currency;
  final String category;
  final String date;
  final String originalText;
  final String? cardDigits;

  TransactionModel({
    this.id,
    required this.merchant,
    required this.amount,
    required this.currency,
    required this.category,
    required this.date,
    required this.originalText,
    this.cardDigits,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchant': merchant,
      'amount': amount,
      'currency': currency,
      'category': category,
      'date': date,
      'originalText': originalText,
      'cardDigits': cardDigits,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      merchant: map['merchant'],
      amount: map['amount'],
      currency: map['currency'],
      category: map['category'],
      date: map['date'],
      originalText: map['originalText'],
      cardDigits: map['cardDigits'],
    );
  }
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'autospend.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, merchant TEXT, amount REAL, currency TEXT, category TEXT, date TEXT, originalText TEXT, cardDigits TEXT)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE transactions ADD COLUMN cardDigits TEXT',
          );
        }
      },
    );
  }

  Future<void> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TransactionModel>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) {
      return TransactionModel.fromMap(maps[i]);
    });
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('transactions');
  }

  Future<void> updateTransactionCategory(int id, String category) async {
    final db = await database;
    await db.update(
      'transactions',
      {'category': category},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateMerchantCategory(String merchant, String category) async {
    final db = await database;
    await db.update(
      'transactions',
      {'category': category},
      where: 'merchant = ?',
      whereArgs: [merchant],
    );
  }

  Future<double> getTodayTotal() async {
    final db = await database;
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE date LIKE ?',
      ['$todayStr%'],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getMonthlyTotal() async {
    final db = await database;
    final now = DateTime.now();
    final monthStr = "${now.year}-${now.month.toString().padLeft(2, '0')}";

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE date LIKE ?',
      ['$monthStr%'],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
