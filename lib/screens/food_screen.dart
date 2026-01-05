// Import package Flutter untuk UI
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk format mata uang
// Import model Food (cetakan data makanan)
import '../models/food.dart';
// Import database helper untuk akses database
import '../database/database_helper.dart';
// Import custom widgets
import '../widgets/widgets.dart';

/// Halaman FoodScreen: Mengelola inventaris stok makanan di kost (misal: mie instan, beras).
/// Memudahkan pengguna memantau sisa stok dan riwayat harga beli makanan.
class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  // Instance database helper
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // List untuk menyimpan semua data makanan
  List<Food> _foods = [];

  // Status loading
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFoods(); // Load data saat pertama kali buka halaman
  }

  // Fungsi untuk mengambil semua data makanan dari database
  Future<void> _loadFoods() async {
    setState(() => _isLoading = true); // Tampilkan loading

    final foods = await _dbHelper.getAllFoods(); // Ambil data dari database

    setState(() {
      _foods = foods; // Simpan data ke variable
      _isLoading = false; // Matikan loading
    });
  }

  // Fungsi untuk menampilkan dialog tambah/edit makanan
  Future<void> _showAddEditDialog({Food? food}) async {
    // Controller untuk input field
    final nameController = TextEditingController(text: food?.name ?? '');
    final quantityController = TextEditingController(
      text: food?.quantity.toString() ?? '',
    );
    final priceController = TextEditingController(
      text: food?.price.toString() ?? '',
    );
    // Tanggal yang dipilih (default: hari ini atau tanggal dari food)
    DateTime selectedDate =
        food != null ? DateTime.parse(food.purchaseDate) : DateTime.now();

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  // Judul dialog (Tambah atau Edit)
                  title: Text(food == null ? 'Tambah Makanan' : 'Edit Makanan'),

                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Input Nama Makanan
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Makanan',
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
                            labelText: 'Harga Satuan',
                            prefixText: 'Rp ',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),

                        // Pilih Tanggal Beli
                        ListTile(
                          title: const Text('Tanggal Beli'),
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
                              lastDate: DateTime.now(), // Maksimal hari ini
                            );

                            if (picked != null) {
                              setDialogState(() => selectedDate = picked);
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
                        // Validasi: semua field harus diisi
                        if (nameController.text.isEmpty ||
                            quantityController.text.isEmpty ||
                            priceController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Harap isi semua field'),
                            ),
                          );
                          return;
                        }

                        // Buat object Food
                        final foodToSave = Food(
                          id: food?.id, // ID (null untuk data baru)
                          name: nameController.text,
                          quantity: int.parse(quantityController.text),
                          purchaseDate:
                              selectedDate.toIso8601String().split('T')[0],
                          price: double.tryParse(priceController.text) ?? 0,
                        );

                        // Simpan ke database
                        if (food == null) {
                          await _dbHelper.insertFood(foodToSave); // Tambah baru
                        } else {
                          await _dbHelper.updateFood(foodToSave); // Update
                        }

                        if (mounted) {
                          Navigator.pop(context); // Tutup dialog
                          _loadFoods(); // Refresh data

                          // Tampilkan notifikasi sukses
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                food == null
                                    ? 'Makanan ditambahkan'
                                    : 'Makanan diupdate',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Simpan'),
                    ),
                  ],
                ),
                ),
    );
  }

  // Fungsi untuk menghapus makanan
  Future<void> _deleteFood(Food food) async {
    // Langsung hapus tanpa konfirmasi (sudah ada di SwipeableListItem)
    await _dbHelper.deleteFood(food.id!); // Hapus dari database
    _loadFoods(); // Refresh data

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Makanan dihapus')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          // Kalau loading, tampilkan loading indicator
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              // Kalau data kosong, tampilkan pesan kosong
              : _foods.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fastfood, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada persediaan makanan',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
              // Kalau ada data, tampilkan list
              : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _foods.length,
                itemBuilder: (context, index) {
                  final food = _foods[index];
                  return SwipeableListItem(
                    // Icon di kiri
                    leading: CircleAvatar(
                      backgroundColor: Colors.green[100],
                      child: const Icon(Icons.fastfood, color: Colors.green),
                    ),

                    // Nama makanan
                    title: Text(
                      food.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    // Detail (jumlah & tanggal)
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Jumlah: ${food.quantity}'),
                        if (food.price > 0)
                          Text(
                            'Total: Rp ${NumberFormat('#,###', 'id_ID').format(food.price * food.quantity)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        Text('Tanggal Beli: ${food.purchaseDate}'),
                      ],
                    ),

                    // Double tap untuk edit
                    onEdit: () => _showAddEditDialog(food: food),

                    // Swipe untuk hapus
                    onDelete: () => _deleteFood(food),

                    deleteConfirmMessage: 'Yakin ingin menghapus ${food.name}?',
                  );
                },
              ),

      // Tombol tambah di kanan bawah
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
