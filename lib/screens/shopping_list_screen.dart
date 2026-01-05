// Import package Flutter untuk UI
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk format mata uang
// Import model ShoppingList (cetakan data daftar belanja)
import '../models/shopping_list.dart';
// Import database helper untuk akses database
import '../database/database_helper.dart';
// Import custom widgets
import '../widgets/widgets.dart';

/// Halaman ShoppingListScreen: Mencatat barang-barang yang perlu dibeli di masa mendatang.
/// Berguna sebagai memo belanja agar tidak ada barang yang terlewat saat ke supermarket.
class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  // Instance database helper
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // List untuk menyimpan semua data daftar belanja
  List<ShoppingList> _shoppingList = [];

  // Status loading
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShoppingList(); // Load data saat pertama kali buka halaman
  }

  // Fungsi untuk mengambil semua data daftar belanja dari database
  Future<void> _loadShoppingList() async {
    setState(() => _isLoading = true); // Tampilkan loading

    final shoppingList =
        await _dbHelper.getAllShoppingLists(); // Ambil data dari database

    setState(() {
      _shoppingList = shoppingList; // Simpan data ke variable
      _isLoading = false; // Matikan loading
    });
  }

  // Fungsi untuk menampilkan dialog tambah/edit daftar belanja
  Future<void> _showAddEditDialog({ShoppingList? shoppingItem}) async {
    // Controller untuk input field
    final itemController = TextEditingController(
      text: shoppingItem?.item ?? '',
    );
    final quantityController = TextEditingController(
      text: shoppingItem?.quantity.toString() ?? '',
    );
    final priceController = TextEditingController(
      text: shoppingItem?.price.toString() ?? '',
    );

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            // Judul dialog (Tambah atau Edit)
            title: Text(
              shoppingItem == null
                  ? 'Tambah Daftar Belanja'
                  : 'Edit Daftar Belanja',
            ),

            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Input Nama Barang
                  TextField(
                    controller: itemController,
                    decoration: const InputDecoration(
                      labelText: 'Barang',
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
                  if (itemController.text.isEmpty ||
                      quantityController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Harap isi semua field')),
                    );
                    return;
                  }

                  // Buat object ShoppingList
                  final shoppingItemToSave = ShoppingList(
                    id: shoppingItem?.id, // ID (null untuk data baru)
                    item: itemController.text,
                    quantity: int.parse(quantityController.text),
                    price: double.tryParse(priceController.text) ?? 0,
                  );

                  // Simpan ke database
                  if (shoppingItem == null) {
                    await _dbHelper.insertShoppingList(
                      shoppingItemToSave,
                    ); // Tambah baru
                  } else {
                    await _dbHelper.updateShoppingList(
                      shoppingItemToSave,
                    ); // Update
                  }

                  if (mounted) {
                    Navigator.pop(context); // Tutup dialog
                    _loadShoppingList(); // Refresh data

                    // Tampilkan notifikasi sukses
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          shoppingItem == null
                              ? 'Barang ditambahkan ke daftar belanja'
                              : 'Barang diupdate',
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

  // Fungsi untuk menghapus barang dari daftar belanja
  Future<void> _deleteShoppingItem(ShoppingList shoppingItem) async {
    // Langsung hapus tanpa konfirmasi (sudah ada di SwipeableListItem)
    await _dbHelper.deleteShoppingList(shoppingItem.id!); // Hapus dari database
    _loadShoppingList(); // Refresh data

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barang dihapus dari daftar belanja')),
      );
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
              : _shoppingList.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada daftar belanja',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
              // Kalau ada data, tampilkan list
              : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _shoppingList.length,
                itemBuilder: (context, index) {
                  final shoppingItem = _shoppingList[index];

                  return SwipeableListItem(
                    // Icon di kiri
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: const Icon(
                        Icons.shopping_cart,
                        color: Colors.blue,
                      ),
                    ),

                    // Nama barang
                    title: Text(
                      shoppingItem.item,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    // Jumlah & Harga
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Jumlah: ${shoppingItem.quantity}'),
                        if (shoppingItem.price > 0)
                          Text(
                            'Total: Rp ${NumberFormat('#,###', 'id_ID').format(shoppingItem.price * shoppingItem.quantity)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                      ],
                    ),

                    // Double tap untuk edit
                    onEdit:
                        () => _showAddEditDialog(shoppingItem: shoppingItem),

                    // Swipe untuk hapus
                    onDelete: () => _deleteShoppingItem(shoppingItem),

                    deleteConfirmMessage:
                        'Yakin ingin menghapus ${shoppingItem.item}?',
                  );
                },
              ),

      // Tombol tambah di kanan bawah
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
