import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String tableName = 'transactions';
  static const String typeIncome = 'income';
  static const String typeExpense = 'expense';

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final String path;
    if (kIsWeb) {
      // Trên web chỉ cần tên file, dữ liệu lưu trong IndexedDB của trình duyệt
      path = 'expense.db';
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, 'expense.db');
    }

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            type TEXT NOT NULL,
            category TEXT NOT NULL,
            date TEXT NOT NULL,
            note TEXT
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_transactions_date ON $tableName(date)');
      },
      // v1 -> v2: chuẩn hóa dữ liệu cũ 'Thu'/'Chi' về 'income'/'expense'
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              "UPDATE $tableName SET type = 'income' WHERE type IN ('Thu', 'thu')");
          await db.execute(
              "UPDATE $tableName SET type = 'expense' WHERE type IN ('Chi', 'chi')");
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_transactions_date ON $tableName(date)');
        }
      },
    );
  }

  // ---------------------------------------------------------------- THÊM
  Future<int> insertTransaction(TransactionModel t) async {
    final db = await database;
    final map = t.toMap()..remove('id'); // bỏ id để database tự đánh số
    return db.insert(tableName, map);
  }

  // ---------------------------------------------------------------- ĐỌC
  Future<TransactionModel?> getTransactionById(int id) async {
    final db = await database;
    final rows =
    await db.query(tableName, where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return TransactionModel.fromMap(rows.first);
  }

  /// Lấy tất cả, mới nhất trước.
  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    final rows = await db.query(tableName, orderBy: 'date DESC, id DESC');
    return rows.map((e) => TransactionModel.fromMap(e)).toList();
  }

  /// Lấy có lọc (dùng cho màn Danh sách giao dịch và Bộ lọc).
  /// - [type]: 'income' hoặc 'expense' (null = tất cả)
  /// - [keyword]: tìm trong tiêu đề, danh mục, ghi chú
  /// - [category]: lọc đúng một danh mục
  /// - [from] (gồm) và [to] (gồm cả ngày đó)
  Future<List<TransactionModel>> getTransactions({
    String? type,
    String? keyword,
    String? category,
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <Object?>[];

    if (type != null) {
      where.add('type = ?');
      args.add(type);
    }
    if (category != null) {
      where.add('category = ?');
      args.add(category);
    }
    if (keyword != null && keyword.trim().isNotEmpty) {
      final k = '%${keyword.trim()}%';
      where.add('(title LIKE ? OR category LIKE ? OR note LIKE ?)');
      args.addAll([k, k, k]);
    }
    _addDateRange(where, args, from, to);

    final rows = await db.query(
      tableName,
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date DESC, id DESC',
    );
    return rows.map((e) => TransactionModel.fromMap(e)).toList();
  }

  // ---------------------------------------------------------------- SỬA
  Future<int> updateTransaction(TransactionModel t) async {
    final db = await database;
    return db.update(tableName, t.toMap(),
        where: 'id = ?', whereArgs: [t.id]);
  }

  // ---------------------------------------------------------------- XÓA
  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAllTransactions() async {
    final db = await database;
    return db.delete(tableName);
  }

  // ---------------------------------------------------------------- THỐNG KÊ

  /// Tổng thu, tổng chi, số dư (có thể giới hạn theo khoảng ngày).
  Future<Map<String, double>> getSummary({DateTime? from, DateTime? to}) async {
    final db = await database;
    final where = <String>[];
    final args = <Object?>[];
    _addDateRange(where, args, from, to);
    final cond = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';

    final rows = await db.rawQuery(
      'SELECT type, SUM(amount) AS total FROM $tableName $cond GROUP BY type',
      args,
    );

    double income = 0, expense = 0;
    for (final r in rows) {
      final total = (r['total'] as num?)?.toDouble() ?? 0.0;
      if (r['type'] == typeIncome) {
        income += total;
      } else {
        expense += total;
      }
    }
    return {
      'income': income,
      'expense': expense,
      'balance': income - expense,
    };
  }

  /// Tổng tiền theo từng danh mục (dùng vẽ biểu đồ tròn ở màn Thống kê).
  /// Kết quả sắp xếp từ lớn đến nhỏ.
  Future<Map<String, double>> getTotalByCategory({
    String type = typeExpense,
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await database;
    final where = <String>['type = ?'];
    final args = <Object?>[type];
    _addDateRange(where, args, from, to);

    final rows = await db.rawQuery(
      '''
      SELECT category, SUM(amount) AS total
      FROM $tableName
      WHERE ${where.join(' AND ')}
      GROUP BY category
      ORDER BY total DESC
      ''',
      args,
    );

    return {
      for (final r in rows)
        r['category'] as String: (r['total'] as num?)?.toDouble() ?? 0.0,
    };
  }

  // ---------------------------------------------------------------- HỖ TRỢ

  /// Thêm điều kiện khoảng ngày. Ngày lưu dạng chuỗi ISO nên so sánh chuỗi
  /// vẫn đúng thứ tự thời gian. [to] được tính hết cả ngày đó.
  void _addDateRange(
      List<String> where,
      List<Object?> args,
      DateTime? from,
      DateTime? to,
      ) {
    if (from != null) {
      final start = DateTime(from.year, from.month, from.day);
      where.add('date >= ?');
      args.add(start.toIso8601String());
    }
    if (to != null) {
      final endExclusive = DateTime(to.year, to.month, to.day + 1);
      where.add('date < ?');
      args.add(endExclusive.toIso8601String());
    }
  }
}