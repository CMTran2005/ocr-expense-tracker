import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../constants/categories.dart';
import '../../features/expense_tracker/models/expense_item.dart';

class DatabaseHelper {
  static const String _dbName = 'expenses_tracker.db';
  static const int _dbVersion = 1;
  static const String tableName = 'expenses';

  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docsDir.path, _dbName);

    return await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            merchant TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT NOT NULL,
            transactionDate INTEGER NOT NULL,
            receiptImagePath TEXT,
            rawOcrText TEXT,
            notes TEXT,
            createdAt INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  /// Insert a new expense and return its generated ID
  Future<int> insertExpense(ExpenseItem expense) async {
    final db = await database;
    return await db.insert(tableName, expense.toMap());
  }

  /// Fetch all expenses with optional filtering
  Future<List<ExpenseItem>> getAllExpenses({
    String? searchQuery,
    ExpenseCategory? category,
  }) async {
    final db = await database;
    String? whereClause;
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClause = 'merchant LIKE ?';
      whereArgs.add('%$searchQuery%');
    }

    if (category != null) {
      if (whereClause != null) {
        whereClause += ' AND category = ?';
      } else {
        whereClause = 'category = ?';
      }
      whereArgs.add(category.name);
    }

    final maps = await db.query(
      tableName,
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'transactionDate DESC',
    );

    return maps.map((m) => ExpenseItem.fromMap(m)).toList();
  }

  /// Get single expense by ID
  Future<ExpenseItem?> getExpenseById(int id) async {
    final db = await database;
    final results = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return ExpenseItem.fromMap(results.first);
  }

  /// Update an existing expense
  Future<int> updateExpense(ExpenseItem expense) async {
    final db = await database;
    return await db.update(
      tableName,
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  /// Delete an expense by ID and remove thumbnail if stored locally
  Future<int> deleteExpense(int id) async {
    final db = await database;
    final item = await getExpenseById(id);
    if (item?.receiptImagePath != null) {
      try {
        final file = File(item!.receiptImagePath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Total spending across all transactions
  Future<double> getTotalSpending() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(amount) as total FROM $tableName');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Aggregate spending grouped by category
  Future<Map<ExpenseCategory, double>> getSpendingByCategory() async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM $tableName
      GROUP BY category
    ''');

    final Map<ExpenseCategory, double> map = {};
    for (final row in results) {
      final cat = ExpenseCategory.fromString(row['category'] as String?);
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      map[cat] = total;
    }
    return map;
  }

  /// Get spending for the last 7 days (Monday to Sunday)
  Future<Map<DateTime, double>> getWeeklySpending() async {
    final db = await database;
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    
    // Start 6 days ago (total 7 days including today)
    final startDate = todayMidnight.subtract(const Duration(days: 6));

    final results = await db.rawQuery('''
      SELECT transactionDate, amount
      FROM $tableName
      WHERE transactionDate >= ?
      ORDER BY transactionDate ASC
    ''', [startDate.millisecondsSinceEpoch]);

    final Map<DateTime, double> weeklyMap = {};
    for (int i = 0; i < 7; i++) {
      final day = startDate.add(Duration(days: i));
      weeklyMap[day] = 0.0;
    }

    for (final row in results) {
      final timestamp = row['transactionDate'] as int;
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final keyDay = DateTime(date.year, date.month, date.day);
      if (weeklyMap.containsKey(keyDay)) {
        weeklyMap[keyDay] = (weeklyMap[keyDay] ?? 0.0) + ((row['amount'] as num).toDouble());
      }
    }

    return weeklyMap;
  }

  /// Delete all expenses and their cached receipt photos, marking has_seeded to prevent auto-reseed
  Future<void> clearAllExpenses() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_metadata (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
    await db.insert(
      'app_metadata',
      {'key': 'has_seeded', 'value': 'true'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final items = await getAllExpenses();
    for (final item in items) {
      if (item.receiptImagePath != null) {
        try {
          final file = File(item.receiptImagePath!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }
    }
    await db.delete(tableName);
  }

  /// Manually force-seed sample demo data
  Future<void> seedSampleData() async {
    final now = DateTime.now();
    final sampleItems = [
      ExpenseItem(
        merchant: 'WinMart+ Trần Đại Nghĩa',
        amount: 145000,
        category: ExpenseCategory.food,
        transactionDate: now.subtract(const Duration(hours: 4)),
        notes: 'Mua sữa, bánh mì, mì tôm',
      ),
      ExpenseItem(
        merchant: 'Highlands Coffee FPT',
        amount: 59000,
        category: ExpenseCategory.food,
        transactionDate: now.subtract(const Duration(days: 1, hours: 2)),
        notes: 'Phin sữa đá size L',
      ),
      ExpenseItem(
        merchant: 'Fahasa Da Nang',
        amount: 285000,
        category: ExpenseCategory.study,
        transactionDate: now.subtract(const Duration(days: 2)),
        notes: 'Giáo trình Clean Code & Sổ tay',
      ),
      ExpenseItem(
        merchant: 'Xăng dầu Petrolimex Số 12',
        amount: 90000,
        category: ExpenseCategory.travel,
        transactionDate: now.subtract(const Duration(days: 3)),
        notes: 'Đổ xăng xe máy Wave Alpha',
      ),
      ExpenseItem(
        merchant: 'Shopee - Ugreen Official',
        amount: 320000,
        category: ExpenseCategory.gear,
        transactionDate: now.subtract(const Duration(days: 4)),
        notes: 'Cáp sạc Type-C 100W & Chuột Bluetooth',
      ),
      ExpenseItem(
        merchant: 'CGV Vincom Plaza',
        amount: 210000,
        category: ExpenseCategory.entertainment,
        transactionDate: now.subtract(const Duration(days: 5)),
        notes: 'Vé xem phim cuối tuần',
      ),
      ExpenseItem(
        merchant: 'GrabBike',
        amount: 32000,
        category: ExpenseCategory.travel,
        transactionDate: now.subtract(const Duration(days: 6)),
        notes: 'Đi từ trường về ký túc xá',
      ),
    ];

    for (final item in sampleItems) {
      await insertExpense(item);
    }
  }

  /// Seed initial demo data only on fresh first install
  Future<void> seedInitialDataIfEmpty() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_metadata (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    final check = await db.query(
      'app_metadata',
      where: 'key = ?',
      whereArgs: ['has_seeded'],
    );

    // If app has already completed initial launch, never re-seed automatically
    if (check.isNotEmpty) {
      return;
    }

    // Mark as initialized
    await db.insert('app_metadata', {'key': 'has_seeded', 'value': 'true'});

    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableName'),
    );
    if (count == null || count == 0) {
      await seedSampleData();
    }
  }
}
