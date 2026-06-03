import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  Future<Database> initDB() async {
    final path = join(await getDatabasesPath(), 'contacts.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE contacts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            phone TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertContact(String name, String phone) async {
    final db = await database;
    await db.insert(
      'contacts',
      {'name': name, 'phone': phone},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getContacts() async {
    final db = await database;
    return await db.query('contacts');
  }

  Future<void> clearContacts() async {
    final db = await database;
    await db.delete('contacts');
  }
}