import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('prostore.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE orders (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        total          REAL    NOT NULL,
        discount       REAL    NOT NULL DEFAULT 0,
        final_total    REAL    NOT NULL,
        date           TEXT    NOT NULL,
        status         TEXT    NOT NULL DEFAULT 'completed',
        payment_method TEXT    NOT NULL DEFAULT 'Credit',
        card_holder    TEXT,
        card_last4     TEXT,
        promo_code     TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id         INTEGER NOT NULL,
        product_id       TEXT    NOT NULL,
        product_name     TEXT    NOT NULL,
        product_image    TEXT    NOT NULL,
        product_price    REAL    NOT NULL,
        product_category TEXT    NOT NULL,
        product_seller   TEXT    NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id)
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE orders ADD COLUMN discount REAL NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE orders ADD COLUMN final_total REAL NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE orders ADD COLUMN payment_method TEXT NOT NULL DEFAULT "Credit"');
      await db.execute('ALTER TABLE orders ADD COLUMN card_holder TEXT');
      await db.execute('ALTER TABLE orders ADD COLUMN card_last4 TEXT');
      await db.execute('ALTER TABLE orders ADD COLUMN promo_code TEXT');
    }
  }

  // ── Guardar orden completa ────────────────────────────────────────────────
  Future<int> saveOrder(
    List<Product> items,
    double total, {
    String paymentMethod = 'Credit',
    String? cardHolder,
    String? cardLast4,
    String? promoCode,
    double discount = 0,
  }) async {
    final db = await database;
    final finalTotal = total - discount;

    final orderId = await db.insert('orders', {
      'total': total,
      'discount': discount,
      'final_total': finalTotal,
      'date': DateTime.now().toIso8601String(),
      'status': 'completed',
      'payment_method': paymentMethod,
      'card_holder': cardHolder ?? '',
      'card_last4': cardLast4 ?? '****',
      'promo_code': promoCode ?? '',
    });

    for (final product in items) {
      await db.insert('order_items', {
        'order_id': orderId,
        'product_id': product.id,
        'product_name': product.name,
        'product_image': product.image,
        'product_price': product.price,
        'product_category': product.category,
        'product_seller': product.seller,
      });
    }

    return orderId;
  }

  // ── Obtener todas las órdenes ─────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAllOrders() async {
    final db = await database;
    final orders = await db.query('orders', orderBy: 'date DESC');

    List<Map<String, dynamic>> result = [];
    for (final order in orders) {
      final items = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [order['id']],
      );
      result.add({...order, 'items': items});
    }
    return result;
  }

  // ── Obtener orden por ID ──────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getOrderById(int id) async {
    final db = await database;
    final orders = await db.query('orders', where: 'id = ?', whereArgs: [id]);
    if (orders.isEmpty) return null;
    final items = await db.query('order_items', where: 'order_id = ?', whereArgs: [id]);
    return {...orders.first, 'items': items};
  }

  Future<void> clearOrders() async {
    final db = await database;
    await db.delete('order_items');
    await db.delete('orders');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}