import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._(this.database);

  final Database database;

  static Future<AppDatabase> open() async {
    final dbPath = await getDatabasesPath();
    final database = await openDatabase(
      p.join(dbPath, 'morningbrief.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE module_cache(
            cache_key TEXT PRIMARY KEY,
            json_value TEXT NOT NULL,
            saved_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE calendar_events(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            starts_at TEXT NOT NULL,
            is_completed INTEGER NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
    return AppDatabase._(database);
  }
}
