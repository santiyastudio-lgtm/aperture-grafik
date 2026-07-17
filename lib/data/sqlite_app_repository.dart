import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../domain/models.dart';
import 'app_repository.dart';

class SqliteAppRepository implements AppRepository {
  Database? _database;

  Future<Database> get _db async {
    final cached = _database;
    if (cached != null) return cached;
    final directory = await getDatabasesPath();
    _database = await openDatabase(
      path.join(directory, 'aperture_grafik.db'),
      version: 1,
      onCreate: (db, _) => db.execute(
        'CREATE TABLE app_state (id INTEGER PRIMARY KEY, payload TEXT NOT NULL)',
      ),
    );
    return _database!;
  }

  @override
  Future<AppState> load() async {
    final rows = await (await _db).query(
      'app_state',
      where: 'id = ?',
      whereArgs: [1],
    );
    if (rows.isEmpty) return AppState.initial();
    try {
      return AppState.fromJson(
        jsonDecode(rows.single['payload']! as String) as Map<String, dynamic>,
      );
    } on FormatException {
      return AppState.initial();
    }
  }

  @override
  Future<void> save(AppState state) async {
    await (await _db).insert('app_state', {
      'id': 1,
      'payload': jsonEncode(state.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> replace(AppState state) => save(state);
}
