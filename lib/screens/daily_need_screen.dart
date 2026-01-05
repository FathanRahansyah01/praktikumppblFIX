// Import package Flutter untuk UI
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk format mata uang
// Import model DailyNeed (cetakan data kebutuhan harian)
import '../models/daily_need.dart';
// Import database helper untuk akses database
import '../database/database_helper.dart';
// Import custom widgets
import '../widgets/widgets.dart';

/// Halaman DailyNeedScreen: Mengelola daftar kebutuhan sehari-hari (perlengkapan mandi, deterjen, dll).
/// Memungkinkan penambahan, penyuntingan, dan penghapusan data kebutuhan rutin.
class DailyNeedScreen extends StatefulWidget {
  const DailyNeedScreen({super.key});

  @override
  State<DailyNeedScreen> createState() => _DailyNeedScreenState();
}

class _DailyNeedScreenState extends State<DailyNeedScreen> {
  // Instance database helper
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // List untuk menyimpan semua data kebutuhan harian
  List<DailyNeed> _dailyNeeds = [];

  // Status loading
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDailyNeeds(); // Load data saat pertama kali buka halaman
  }

  // Fungsi untuk mengambil semua data kebutuhan harian dari database
  Future<void> _loadDailyNeeds() async {
    setState(() => _isLoading = true); // Tampilkan loading

    final dailyNeeds =
        await _dbHelper.getAllDailyNeeds(); // Ambil data dari database

    setState(() {
      _dailyNeeds = dailyNeeds; // Simpan data ke variable
      _isLoading = false; // Matikan loading
    });
  }

  // Fungsi untuk menampilkan dialog tambah/edit kebutuhan harian
  Future<void> _showAddEditDialog({DailyNeed? dailyNeed}) async {
    // Controller untuk input field
    final nameController = TextEditingController(text: dailyNeed?.name ?? '');
    final quantityController = TextEditingController(
      text: dailyNeed?.quantity.toString() ?? '',
    );
    final priceController = TextEditingController(
      text: dailyNeed?.price.toString() ?? '',
    );

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            // Judul dialog (Tambah atau Edit)
            title: Text(
              dailyNeed == null
                  ? 'Tambah Kebutuhan Harian'
                  : 'Edit Kebutuhan Harian',
            ),

            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Input Nama Kebutuhan
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Kebutuhan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input Jumlah
                  TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number, // Keyboard angka
                  ),
                  const SizedBox(height: 16),

                  // Input Harga
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Harga Satuan/Unit',
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
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
                  // Validasi: semua field harus diisi
                  if (nameController.text.isEmpty ||
                      quantityController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Harap isi semua field')),
                    );
                    return;
                  }

                  // Buat object DailyNeed
                  final dailyNeedToSave = DailyNeed(
                    id: dailyNeed?.id, // ID (null untuk data baru)
                    name: nameController.text,
                    quantity: int.parse(quantityController.text),
                    price: double.tryParse(priceController.text) ?? 0,
                  );

                  // Simpan ke database
                  if (dailyNeed == null) {
                    await _dbHelper.insertDailyNeed(
                      dailyNeedToSave,
                    ); // Tambah baru
                  } else {
                    await _dbHelper.updateDailyNeed(dailyNeedToSave); // Update
                  }

                  if (mounted) {
                    Navigator.pop(context); // Tutup dialog
                    _loadDailyNeeds(); // Refresh data

                    // Tampilkan notifikasi sukses
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          dailyNeed == null
                              ? 'Kebutuhan harian ditambahkan'
                              : 'Kebutuhan harian diupdate',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
    );
  }

  // Fungsi untuk menghapus kebutuhan harian
  Future<void> _deleteDailyNeed(DailyNeed dailyNeed) async {
    // Langsung hapus tanpa konfirmasi (sudah ada di SwipeableListItem)
    await _dbHelper.deleteDailyNeed(dailyNeed.id!); // Hapus dari database
    _loadDailyNeeds(); // Refresh data

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kebutuhan harian dihapus')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              // Kalau loading, tampilkan loading indicator
              ? const Center(child: CircularProgressIndicator())
              // Kalau data kosong, tampilkan pesan kosong
              : _dailyNeeds.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada kebutuhan harian',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
              // Kalau ada data, tampilkan list
              : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _dailyNeeds.length,
                itemBuilder: (context, index) {
                  final dailyNeed = _dailyNeeds[index];

                  return SwipeableListItem(
                    // Icon di kiri
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange[100],
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.orange,
                      ),
                    ),

                    // Nama kebutuhan
                    title: Text(
                      dailyNeed.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    // Jumlah & Harga
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Jumlah: ${dailyNeed.quantity}'),
                        if (dailyNeed.price > 0)
                          Text(
                            'Total: Rp ${NumberFormat('#,###', 'id_ID').format(dailyNeed.price * dailyNeed.quantity)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                      ],
                    ),

                    // Double tap untuk edit
                    onEdit: () => _showAddEditDialog(dailyNeed: dailyNeed),

                    // Swipe untuk hapus
                    onDelete: () => _deleteDailyNeed(dailyNeed),

                    deleteConfirmMessage:
                        'Yakin ingin menghapus ${dailyNeed.name}?',
                  );
                },
              ),

      // Tombol tambah di kanan bawah
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
