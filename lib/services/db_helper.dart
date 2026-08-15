import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product_model.dart'; // Canonical Model Import
import '../models/voice_note_model.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('dokan_shop.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      // Bumped 1 -> 2 to add the voice_notes table for the Voice Notes
      // feature. This is purely additive: existing `products` data and
      // schema are untouched, see _upgradeDB below.
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        sku TEXT NOT NULL,
        category TEXT NOT NULL,
        stockQuantity INTEGER NOT NULL,
        costPrice REAL NOT NULL,
        sellingPrice REAL NOT NULL,
        lowStockThreshold INTEGER NOT NULL
      )
    ''');
    await _createVoiceNotesTable(db);
  }

  // Safe, additive migration: existing installs (which were on version 1,
  // `products` table only) get the new `voice_notes` table created without
  // touching any existing table or row. Nothing is dropped or recreated.
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createVoiceNotesTable(db);
    }
  }

  Future<void> _createVoiceNotesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS voice_notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        filePath TEXT NOT NULL,
        durationMs INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // ==================== Products (unchanged) ====================

  Future<int> insertProduct(Product product) async {
    final db = await instance.database;
    return await db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Product>> fetchProducts() async {
    final db = await instance.database;
    final maps = await db.query('products');
    return maps.map((json) => Product.fromMap(json)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(String id) async {
    final db = await instance.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== Voice Notes ====================

  Future<int> insertVoiceNote(VoiceNote note) async {
    final db = await instance.database;
    return await db.insert(
      'voice_notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<VoiceNote>> fetchVoiceNotes() async {
    final db = await instance.database;
    final maps = await db.query('voice_notes', orderBy: 'createdAt DESC');
    return maps.map((json) => VoiceNote.fromMap(json)).toList();
  }

  Future<int> deleteVoiceNote(String id) async {
    final db = await instance.database;
    return await db.delete(
      'voice_notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
