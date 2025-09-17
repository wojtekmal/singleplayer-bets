import 'dart:math';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'bet_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'bets.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE bets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content TEXT NOT NULL,
        description TEXT NOT NULL,
        probability REAL NOT NULL,
        createdDate TEXT NOT NULL,
        resolveDate TEXT NOT NULL,
        resolvedStatus INTEGER
      )
    ''');
  }

  Future<int> insertBet(Bet bet) async {
    final db = await database;
    return await db.insert('bets', bet.toMap());
  }

  Future<List<Bet>> getBets() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('bets');
    List<Bet> bets = List.generate(maps.length, (i) => Bet.fromMap(maps[i]));

    // Sort: unresolved first, then by creation date descending
    bets.sort((a, b) {
      if (a.resolvedStatus == null && b.resolvedStatus != null) return -1;
      if (a.resolvedStatus != null && b.resolvedStatus == null) return 1;
      return b.createdDate.compareTo(a.createdDate);
    });

    return bets;
  }
  
  Future<int> updateBet(Bet bet) async {
    final db = await database;
    return await db.update(
      'bets',
      bet.toMap(),
      where: 'id = ?',
      whereArgs: [bet.id],
    );
  }

  Future<int> deleteBet(int id) async {
    final db = await database;
    return await db.delete(
      'bets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double?> calculateAverageLogLoss() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bets',
      where: 'resolvedStatus IS NOT NULL',
    );

    if (maps.isEmpty) {
      return null;
    }

    double totalLogLoss = 0;
    for (var map in maps) {
      Bet bet = Bet.fromMap(map);
      double p = bet.probability;
      int y = bet.resolvedStatus!;
      
      // Clamp probability to avoid log(0)
      p = p.clamp(0.0001, 0.9999);

      double loss = -(y * log(p) + (1 - y) * log(1 - p));
      totalLogLoss += loss;
    }

    return totalLogLoss / maps.length;
  }
}