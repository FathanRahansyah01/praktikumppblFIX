import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async'; // Digunakan untuk StreamController (notifikasi perubahan data)

// Import model-model data yang digunakan dalam aplikasi
import '../models/food.dart';
import '../models/equipment.dart';
import '../models/laundry.dart';
import '../models/expense.dart';
import '../models/bill.dart';
import '../models/daily_need.dart';
import '../models/shopping_list.dart';
import '../models/activity_reminder.dart';
import '../models/finance_note.dart';

/// Class DatabaseHelper: Pengelola pusat database SQLite aplikasi.
/// Menggunakan pola Singleton agar hanya ada satu koneksi database yang aktif.
class DatabaseHelper {
  // Instance tunggal dari DatabaseHelper
  static final DatabaseHelper instance = DatabaseHelper._init();
  // Variable database yang akan diinisialisasi saat dibutuhkan
  static Database? _database;
  
  // Stream untuk memberitahu UI jika ada perubahan data keuangan (saldo/catatan)
  // Ini berguna agar widget saldo di Dashboard otomatis terupdate saat ada transaksi.
  final _transactionController = StreamController<void>.broadcast();
  Stream<void> get onTransactionChanged => _transactionController.stream;

  // Constructor private untuk Singleton
  DatabaseHelper._init();

  // Getter untuk mendapatkan database. Jika belum ada, maka akan diinisialisasi.
  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('kost_database.db');
    return _database!;
  }

  // Fungsi internal untuk inisialisasi file database di perangkat.
  Future<Database> _initDB(String filePath) async {
    // Dapatkan lokasi penyimpanan database di Android/iOS
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Buka database dengan versi tertentu
    return await openDatabase(
      path,
      version: 11, // Versi 11: Fix tabel pengingat_kegiatan
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // Fungsi untuk menangani migrasi struktur database jika versi ditingkatkan.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 10) {
      // Migrasi ke v10: Tambah kolom yang kurang
      try {
        await db.execute('ALTER TABLE makanan ADD COLUMN purchaseDate TEXT');
      } catch (e) {
        print("Tabel makanan sudah memiliki purchaseDate");
      }

      try {
        await db.execute('ALTER TABLE pengeluaran ADD COLUMN description TEXT');
      } catch (e) {
        print("Tabel pengeluaran sudah memiliki description");
      }

      try {
        await db.execute('ALTER TABLE laundry ADD COLUMN type TEXT');
        await db.execute('ALTER TABLE laundry ADD COLUMN quantity INTEGER');
      } catch (e) {
        print("Tabel laundry sudah memiliki type/quantity");
      }
    }

    if (oldVersion < 11) {
      // Migrasi ke v11: Pastikan tabel pengingat_kegiatan ada dan benar
      try {
        // Cek dulu apakah tabelnya sudah ada
        // Kalau sudah ada tapi salah kolom (title vs name), kita drop dulu (reset fitur ini)
        // karena kemungkinan user belum bisa pakai fitur ini sebelumnya (error)
        await db.execute('DROP TABLE IF EXISTS pengingat_kegiatan');
        
        await db.execute('''
          CREATE TABLE pengingat_kegiatan (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            time TEXT NOT NULL
          )
        ''');
      } catch (e) {
        print("Error migrasi v11: $e");
      }
    }
  }

  // Fungsi untuk membuat struktur tabel database saat awal aplikasi dijalankan.
  Future<void> _createDB(Database db, int version) async {
    // Tabel Makanan
    await db.execute('''
      CREATE TABLE makanan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        purchaseDate TEXT,
        price REAL NOT NULL DEFAULT 0
      )
    ''');

    // Tabel Peralatan
    await db.execute('''
      CREATE TABLE peralatan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        condition TEXT NOT NULL,
        price REAL NOT NULL DEFAULT 0
      )
    ''');

    // Tabel Laundry
    await db.execute('''
      CREATE TABLE laundry (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item TEXT NOT NULL,
        type TEXT,
        quantity INTEGER,
        status TEXT NOT NULL,
        cost REAL NOT NULL DEFAULT 0
      )
    ''');

    // Tabel Pengeluaran
    await db.execute('''
      CREATE TABLE pengeluaran (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        date TEXT NOT NULL
      )
    ''');

    // Tabel Tagihan Bulanan (Baru di v7)
    await db.execute('''
      CREATE TABLE tagihan_bulanan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        dueDate TEXT NOT NULL,
        isPaid INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Tabel Catatan Keuangan (Unified Finance)
    await db.execute('''
      CREATE TABLE catatan_keuangan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        note TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        source TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    // Tabel Kebutuhan Harian (Baru di v9)
    await db.execute('''
      CREATE TABLE kebutuhan_harian (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL DEFAULT 0
      )
    ''');

    // Tabel Daftar Belanja (Memo)
    await db.execute('''
      CREATE TABLE daftar_belanja (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL DEFAULT 0
      )
    ''');

    // Tabel Pengingat Kegiatan
    await db.execute('''
      CREATE TABLE pengingat_kegiatan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        time TEXT NOT NULL
      )
    ''');

    // Tabel Saldo Global
    await db.execute('''
      CREATE TABLE balance (
        id INTEGER PRIMARY KEY,
        amount REAL NOT NULL
      )
    ''');

    // Isi saldo awal dengan 0
    await db.insert('balance', {'id': 1, 'amount': 0.0});
  }

  // ========== CRUD MAKANAN (STOK) ==========

  Future<int> insertFood(Food food) async {
    final db = await database;
    final id = await db.insert('makanan', food.toMap());
    
    // OTOMATIS: Jika harga > 0, catat sebagai pengeluaran belanja di Unified Finance
    if (food.price > 0) {
      await recordTransaction(
        note: 'Stok Makanan: ${food.name}',
        amount: food.price * food.quantity,
        type: 'expense',
        source: 'makanan',
      );
    }
    return id;
  }

  Future<List<Food>> getAllFoods() async {
    final db = await database;
    final result = await db.query('makanan', orderBy: 'name ASC');
    return result.map((map) => Food.fromMap(map)).toList();
  }

  Future<int> updateFood(Food food) async {
    final db = await database;
    return await db.update(
      'makanan',
      food.toMap(),
      where: 'id = ?',
      whereArgs: [food.id],
    );
  }

  Future<int> deleteFood(int id) async {
    final db = await database;
    // Cari data sebelum dihapus untuk kepentingan refund saldo/log
    final result = await db.query('makanan', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      final food = Food.fromMap(result.first);
      if (food.price > 0) {
        await recordTransaction(
          note: 'Refund Makanan: ${food.name}',
          amount: food.price * food.quantity,
          type: 'income',
          source: 'makanan',
        );
      }
    }
    return await db.delete('makanan', where: 'id = ?', whereArgs: [id]);
  }

  // ========== CRUD PERALATAN (EQUIPMENT) ==========

  Future<int> insertEquipment(Equipment equipment) async {
    final db = await database;
    final id = await db.insert('peralatan', equipment.toMap());
    
    // OTOMATIS: Catat pengeluaran belanja peralatan
    if (equipment.price > 0) {
      await recordTransaction(
        note: 'Beli Alat: ${equipment.name}',
        amount: equipment.price,
        type: 'expense',
        source: 'peralatan',
      );
    }
    return id;
  }

  Future<List<Equipment>> getAllEquipment() async {
    final db = await database;
    final result = await db.query('peralatan', orderBy: 'name ASC');
    return result.map((map) => Equipment.fromMap(map)).toList();
  }

  // Alias untuk kompatibilitas dengan UI
  Future<List<Equipment>> getAllEquipments() => getAllEquipment();

  Future<int> updateEquipment(Equipment equipment) async {
    final db = await database;
    return await db.update(
      'peralatan',
      equipment.toMap(),
      where: 'id = ?',
      whereArgs: [equipment.id],
    );
  }

  Future<int> deleteEquipment(int id) async {
    final db = await database;
    final result = await db.query('peralatan', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      final equipment = Equipment.fromMap(result.first);
      if (equipment.price > 0) {
        await recordTransaction(
          note: 'Refund Alat: ${equipment.name}',
          amount: equipment.price,
          type: 'income',
          source: 'peralatan',
        );
      }
    }
    return await db.delete('peralatan', where: 'id = ?', whereArgs: [id]);
  }

  // ========== CRUD LAUNDRY ==========

  Future<int> insertLaundry(Laundry laundry) async {
    final db = await database;
    final id = await db.insert('laundry', laundry.toMap());
    
    // OTOMATIS: Catat pengeluaran laundry
    if (laundry.cost > 0) {
      await recordTransaction(
        note: 'Laundry: ${laundry.item}',
        amount: laundry.cost,
        type: 'expense',
        source: 'laundry',
      );
    }
    return id;
  }

  Future<List<Laundry>> getAllLaundry() async {
    final db = await database;
    final result = await db.query('laundry', orderBy: 'id DESC');
    return result.map((map) => Laundry.fromMap(map)).toList();
  }

  // Alias untuk kompatibilitas dengan UI
  Future<List<Laundry>> getAllLaundries() => getAllLaundry();

  Future<int> updateLaundry(Laundry laundry) async {
    final db = await database;
    return await db.update(
      'laundry',
      laundry.toMap(),
      where: 'id = ?',
      whereArgs: [laundry.id],
    );
  }

  Future<int> deleteLaundry(int id) async {
    final db = await database;
    final result = await db.query('laundry', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      final laundry = Laundry.fromMap(result.first);
      if (laundry.cost > 0) {
        await recordTransaction(
          note: 'Refund Laundry: ${laundry.item}',
          amount: laundry.cost,
          type: 'income',
          source: 'laundry',
        );
      }
    }
    return await db.delete('laundry', where: 'id = ?', whereArgs: [id]);
  }

  // ========== CRUD PENGELUARAN ==========

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    final id = await db.insert('pengeluaran', expense.toMap());
    
    // OTOMATIS: Catat transaksi terpadu
    await recordTransaction(
      note: 'Pengeluaran: ${expense.category}',
      amount: expense.amount,
      type: 'expense',
      source: 'pengeluaran',
    );
    
    return id;
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final result = await db.query('pengeluaran', orderBy: 'date DESC');
    return result.map((map) => Expense.fromMap(map)).toList();
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    
    // Ambil data lama sebelum update
    final oldData = await db.query('pengeluaran', where: 'id = ?', whereArgs: [expense.id]);
    if (oldData.isNotEmpty) {
      final oldExpense = Expense.fromMap(oldData.first);
      final difference = expense.amount - oldExpense.amount;
      
      // Jika harga berubah, catat penyesuaian di unified finance
      if (difference != 0) {
        if (difference > 0) {
          // Harga naik -> Tambah pengeluaran (selisihnya)
          await recordTransaction(
            note: 'Koreksi Harga: ${expense.category}',
            amount: difference,
            type: 'expense',
            source: 'pengeluaran',
          );
        } else {
          // Harga turun -> Kembalian / Income (selisih positifnya)
          await recordTransaction(
            note: 'Koreksi Harga: ${expense.category}',
            amount: difference.abs(),
            type: 'income',
            source: 'pengeluaran',
          );
        }
      }
    }

    return await db.update(
      'pengeluaran',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    final result = await db.query('pengeluaran', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      final expense = Expense.fromMap(result.first);
      await recordTransaction(
        note: 'Refund Pengeluaran: ${expense.category}',
        amount: expense.amount,
        type: 'income',
        source: 'pengeluaran',
      );
    }
    return await db.delete('pengeluaran', where: 'id = ?', whereArgs: [id]);
  }

  // ========== CRUD TAGIHAN (BILL) ==========

  Future<int> insertBill(Bill bill) async {
    final db = await database;
    final id = await db.insert('tagihan_bulanan', bill.toMap());
    
    // OTOMATIS: Catat pengeluaran saat tagihan dibuat (jika langsung bayar/untuk log)
    if (bill.isPaid) {
      await recordTransaction(
        note: 'Bayar Tagihan: ${bill.name}',
        amount: bill.amount,
        type: 'expense',
        source: 'tagihan',
      );
    }
    return id;
  }

  Future<List<Bill>> getAllBills() async {
    final db = await database;
    final result = await db.query('tagihan_bulanan', orderBy: 'dueDate ASC');
    return result.map((map) => Bill.fromMap(map)).toList();
  }

  Future<int> updateBill(Bill bill) async {
    final db = await database;
    
    // Pantau apakah status bayar berubah dari false ke true
    final oldData = await db.query('tagihan_bulanan', where: 'id = ?', whereArgs: [bill.id]);
    if (oldData.isNotEmpty) {
      final oldBill = Bill.fromMap(oldData.first);
      if (!oldBill.isPaid && bill.isPaid) {
        // Jika baru saja dibayar, catat transaksi
        await recordTransaction(
          note: 'Bayar Tagihan: ${bill.name}',
          amount: bill.amount,
          type: 'expense',
          source: 'tagihan',
        );
      }
    }

    return await db.update(
      'tagihan_bulanan',
      bill.toMap(),
      where: 'id = ?',
      whereArgs: [bill.id],
    );
  }

  Future<int> deleteBill(int id) async {
    final db = await database;
    final result = await db.query('tagihan_bulanan', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      final bill = Bill.fromMap(result.first);
      // recordTransaction otomatis mengupdate saldo via type: 'income'
      await recordTransaction(
        note: 'Refund Tagihan: ${bill.name}',
        amount: bill.amount,
        type: 'income',
        source: 'tagihan',
      );
    }
    return await db.delete('tagihan_bulanan', where: 'id = ?', whereArgs: [id]);
  }

  // ========== SISTEM SALDO (BALANCE) ==========

  // Ambil saldo saat ini
  Future<double> getCurrentBalance() async {
    final db = await database;
    final result = await db.query('balance', where: 'id = 1');
    if (result.isNotEmpty) {
      return (result.first['amount'] as num).toDouble();
    }
    return 0.0;
  }

  // Update saldo (tambah/kurang)
  Future<void> _updateBalance(double change) async {
    final db = await database;
    final current = await getCurrentBalance();
    await db.update(
      'balance',
      {'amount': current + change},
      where: 'id = 1',
    );
  }

  // ========== HELPER OTOMATISASI TRANSAKSI ==========

  // Method pusat untuk mencatat transaksi dari mana saja
  Future<void> recordTransaction({
    required String note,
    required double amount,
    required String type, // 'income' atau 'expense'
    required String source,
  }) async {
    final db = await database;
    
    // Simpan ke tabel catatan_keuangan dengan map langsung (tanpa model FinanceNote)
    await db.insert('catatan_keuangan', {
      'note': note,
      'amount': amount,
      'type': type,
      'source': source,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Update saldo total
    final change = type == 'income' ? amount : -amount;
    await _updateBalance(change);

    // Beritahu listener bahwa ada transaksi masuk
    _transactionController.add(null);
  }

  // Ambil semua catatan keuangan
  Future<List<FinanceNote>> getAllFinanceNotes() async {
    final db = await database;
    final result = await db.query(
      'catatan_keuangan',
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => FinanceNote.fromMap(map)).toList();
  }

  // Hapus transaksi (juga mengupdate saldo sebaliknya)
  Future<int> deleteFinanceNote(int id) async {
    final db = await database;
    
    // Cari data transaksinya dulu untuk tahu nominalnya
    final result = await db.query('catatan_keuangan', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      final data = result.first;
      final amount = (data['amount'] as num).toDouble();
      final type = data['type'] as String;
      
      final signedAmount = type == 'income' ? amount : -amount;
      
      // Balikkan saldonya (kalau pengeluaran dihapus, saldo bertambah)
      await _updateBalance(-signedAmount);
      
      // Beritahu listener
      _transactionController.add(null);
    }

    // Hapus datanya
    return await db.delete(
      'catatan_keuangan',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== CRUD KEBUTUHAN HARIAN ==========
  Future<int> insertDailyNeed(DailyNeed dailyNeed) async {
    final db = await database;
    final id = await db.insert('kebutuhan_harian', dailyNeed.toMap());
    
    // OTOMATIS: Catat pengeluaran
    if (dailyNeed.price > 0) {
      await recordTransaction(
        note: 'Beli Kebutuhan: ${dailyNeed.name}',
        amount: dailyNeed.price * dailyNeed.quantity,
        type: 'expense',
        source: 'harian',
      );
    }
    return id;
  }

  Future<List<DailyNeed>> getAllDailyNeeds() async {
    final db = await database;
    final result = await db.query('kebutuhan_harian', orderBy: 'name ASC');
    return result.map((map) => DailyNeed.fromMap(map)).toList();
  }

  Future<DailyNeed?> getDailyNeedById(int id) async {
    final db = await database;
    final result = await db.query(
      'kebutuhan_harian',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return DailyNeed.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateDailyNeed(DailyNeed dailyNeed) async {
    final db = await database;
    return await db.update(
      'kebutuhan_harian',
      dailyNeed.toMap(),
      where: 'id = ?',
      whereArgs: [dailyNeed.id],
    );
  }

  Future<int> deleteDailyNeed(int id) async {
    final db = await database;
    final result = await db.query('kebutuhan_harian', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      final need = DailyNeed.fromMap(result.first);
      if (need.price > 0) {
        await recordTransaction(
          note: 'Refund Kebutuhan: ${need.name}',
          amount: need.price * need.quantity,
          type: 'income',
          source: 'harian',
        );
      }
    }
    return await db.delete(
      'kebutuhan_harian',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== CRUD DAFTAR BELANJA ==========
  Future<int> insertShoppingList(ShoppingList shoppingList) async {
    final db = await database;
    final id = await db.insert('daftar_belanja', shoppingList.toMap());
    
    // OTOMATIS: Catat pengeluaran
    if (shoppingList.price > 0) {
      await recordTransaction(
        note: 'Belanja: ${shoppingList.item}',
        amount: shoppingList.price * shoppingList.quantity,
        type: 'expense',
        source: 'belanja',
      );
    }
    return id;
  }

  Future<List<ShoppingList>> getAllShoppingLists() async {
    final db = await database;
    final result = await db.query('daftar_belanja', orderBy: 'item ASC');
    return result.map((map) => ShoppingList.fromMap(map)).toList();
  }

  Future<ShoppingList?> getShoppingListById(int id) async {
    final db = await database;
    final result = await db.query(
      'daftar_belanja',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return ShoppingList.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateShoppingList(ShoppingList shoppingList) async {
    final db = await database;
    return await db.update(
      'daftar_belanja',
      shoppingList.toMap(),
      where: 'id = ?',
      whereArgs: [shoppingList.id],
    );
  }

  Future<int> deleteShoppingList(int id) async {
    final db = await database;
    final result = await db.query('daftar_belanja', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      final list = ShoppingList.fromMap(result.first);
      if (list.price > 0) {
        await recordTransaction(
          note: 'Refund Belanja: ${list.item}',
          amount: list.price * list.quantity,
          type: 'income',
          source: 'belanja',
        );
      }
    }
    return await db.delete(
      'daftar_belanja',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== CRUD PENGINGAT KEGIATAN ==========
  Future<int> insertActivityReminder(ActivityReminder reminder) async {
    final db = await database;
    return await db.insert('pengingat_kegiatan', reminder.toMap());
  }

  Future<List<ActivityReminder>> getAllActivityReminders() async {
    final db = await database;
    final result = await db.query('pengingat_kegiatan', orderBy: 'time ASC');
    return result.map((map) => ActivityReminder.fromMap(map)).toList();
  }

  Future<ActivityReminder?> getActivityReminderById(int id) async {
    final db = await database;
    final result = await db.query(
      'pengingat_kegiatan',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return ActivityReminder.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateActivityReminder(ActivityReminder reminder) async {
    final db = await database;
    return await db.update(
      'pengingat_kegiatan',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<int> deleteActivityReminder(int id) async {
    final db = await database;
    return await db.delete(
      'pengingat_kegiatan',
      where: 'id = ?',
      whereArgs: [id],
    );
  }



  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
