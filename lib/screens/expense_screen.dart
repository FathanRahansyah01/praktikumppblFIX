import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/expense.dart';

/// Halaman ExpenseScreen: Menampilkan daftar riwayat pengeluaran yang dikelompokkan berdasarkan tanggal.
/// Pengguna dapat memantau uang keluar dan kategori pengeluaran di layar ini.
class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  // Database helper untuk akses database
  final _db = DatabaseHelper.instance;

  // List untuk menyimpan semua data pengeluaran
  List<Expense> _expenses = [];

  // Status loading (true = sedang loading, false = selesai)
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Panggil fungsi untuk load data saat pertama kali buka halaman
    _loadExpenses();
  }

  // Fungsi untuk mengambil semua data pengeluaran dari database
  Future<void> _loadExpenses() async {
    setState(() => _loading = true); // Tampilkan loading

    final data = await _db.getAllExpenses(); // Ambil data dari database

    setState(() {
      _expenses = data; // Simpan data ke variable
      _loading = false; // Matikan loading
    });
  }

  // Fungsi untuk mengelompokkan pengeluaran berdasarkan tanggal
  // Hasilnya: {"2025-12-27": [expense1, expense2], "2025-12-26": [expense3]}
  Map<String, List<Expense>> _groupByDate() {
    Map<String, List<Expense>> grouped = {};

    for (var expense in _expenses) {
      String date = expense.date; // Ambil tanggal

      // Kalau tanggal belum ada di map, buat list baru
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }

      // Tambahkan expense ke list tanggal tersebut
      grouped[date]!.add(expense);
    }

    return grouped;
  }

  // Fungsi untuk format tanggal jadi "Hari Ini", "Kemarin", atau tanggal lengkap
  String _formatDate(String dateString) {
    DateTime date = DateTime.parse(dateString); // Parse string jadi DateTime
    DateTime now = DateTime.now(); // Tanggal hari ini

    // Hitung selisih hari
    int difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Hari Ini';
    } else if (difference == 1) {
      return 'Kemarin';
    } else {
      // Format: "27 Desember 2025"
      List<String> months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }

  // Fungsi untuk format angka jadi format rupiah (contoh: 25000 -> 25.000)
  String _formatRupiah(double amount) {
    String str = amount.toInt().toString();
    String result = '';
    int count = 0;

    // Loop dari belakang, tambahkan titik setiap 3 digit
    for (int i = str.length - 1; i >= 0; i--) {
      if (count == 3) {
        result = '.$result';
        count = 0;
      }
      result = str[i] + result;
      count++;
    }

    return result;
  }

  // Fungsi untuk menampilkan dialog tambah/edit pengeluaran
  Future<void> _showExpenseDialog({Expense? expense}) async {
    // Controller untuk input field
    final nominalCtrl = TextEditingController(
      text: expense?.amount.toString() ?? '',
    );
    final categoryCtrl = TextEditingController(text: expense?.category ?? '');
    final descriptionCtrl = TextEditingController(
      text: expense?.description ?? '',
    );

    // Tanggal yang dipilih (default: hari ini atau tanggal dari expense)
    DateTime selectedDate =
        expense != null ? DateTime.parse(expense.date) : DateTime.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                expense == null ? 'Tambah Pengeluaran' : 'Edit Pengeluaran',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Input Nominal
                    TextField(
                      controller: nominalCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nominal',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),

                    // Input Kategori
                    TextField(
                      controller: categoryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        hintText: 'Contoh: Makan, Transport',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Input Deskripsi (opsional)
                    TextField(
                      controller: descriptionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi (opsional)',
                        hintText: 'Contoh: Warteg depan kampus',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),

                    // Pilih Tanggal
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Tanggal'),
                      subtitle: Text(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        // Tampilkan date picker
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );

                        if (picked != null) {
                          setStateDialog(() => selectedDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                // Tombol Batal
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),

                // Tombol Simpan
                ElevatedButton(
                  onPressed: () async {
                    // Validasi: nominal dan kategori harus diisi
                    if (nominalCtrl.text.isEmpty || categoryCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nominal dan kategori harus diisi'),
                        ),
                      );
                      return;
                    }

                    // Buat object Expense baru
                    final expenseData = Expense(
                      id: expense?.id,
                      amount: double.tryParse(nominalCtrl.text) ?? 0,
                      category: categoryCtrl.text.trim(),
                      description: descriptionCtrl.text.trim(),
                      date: selectedDate.toIso8601String().split('T').first,
                    );

                    // Simpan ke database
                    if (expense == null) {
                      await _db.insertExpense(expenseData); // Tambah baru
                    } else {
                      await _db.updateExpense(expenseData); // Update yang lama
                    }

                    if (!mounted) return;
                    Navigator.pop(context); // Tutup dialog
                    _loadExpenses(); // Refresh data

                    // Tampilkan notifikasi sukses
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          expense == null
                              ? 'Pengeluaran ditambahkan'
                              : 'Pengeluaran diperbarui',
                        ),
                      ),
                    );
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Fungsi untuk hapus pengeluaran
  Future<void> _deleteExpense(Expense expense) async {
    await _db.deleteExpense(expense.id!);
    _loadExpenses();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Pengeluaran dihapus')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showExpenseDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    // Kalau masih loading, tampilkan loading indicator
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Kalau data kosong, tampilkan pesan kosong
    if (_expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada catatan pengeluaran',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Kelompokkan data berdasarkan tanggal
    final groupedExpenses = _groupByDate();

    // Urutkan tanggal dari terbaru ke terlama
    final sortedDates =
        groupedExpenses.keys.toList()..sort((a, b) => b.compareTo(a));

    // Tampilkan list
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        String date = sortedDates[index];
        List<Expense> expenses = groupedExpenses[date]!;

        // Hitung total pengeluaran untuk tanggal ini
        double total = 0;
        for (var expense in expenses) {
          total += expense.amount;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER TANGGAL
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey[200],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tanggal (Hari Ini, Kemarin, dll)
                  Text(
                    _formatDate(date),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Total pengeluaran hari ini
                  Text(
                    'Total: Rp ${_formatRupiah(total)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),

            // LIST PENGELUARAN
            ...expenses.map((expense) {
              return Dismissible(
                key: Key(expense.id.toString()),
                direction: DismissDirection.startToEnd,
                confirmDismiss: (direction) async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Konfirmasi'),
                        content: Text(
                          'Yakin ingin menghapus pengeluaran ${expense.category}?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Hapus'),
                          ),
                        ],
                      );
                    },
                  );
                  return result ?? false;
                },
                onDismissed: (direction) => _deleteExpense(expense),
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.delete, color: Colors.white, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Hapus',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: GestureDetector(
                    onDoubleTap: () => _showExpenseDialog(expense: expense),
                    child: ListTile(
                      // Icon di kiri
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: const Icon(Icons.payments, color: Colors.blue),
                      ),

                      // Konten utama
                      title: Text(
                        expense.category,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      // Deskripsi (kalau ada)
                      subtitle:
                          expense.description.isNotEmpty
                              ? Text(expense.description)
                              : null,

                      // Nominal dan hint di kanan
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '-Rp ${_formatRupiah(expense.amount)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          Text(
                            '2x Tap',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
