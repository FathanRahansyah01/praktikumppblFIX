// Import package Flutter untuk UI
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk format mata uang
// Import model Laundry (cetakan data cucian)
import '../models/laundry.dart';
// Import database helper untuk akses database
import '../database/database_helper.dart';
// Import custom widgets
import '../widgets/widgets.dart';

/// Halaman LaundryScreen: Mencatat status cucian pengguna (misal: "Sedang Dicuci", "Selesai").
/// Membantu pengguna memantau biaya laundry dan progres pengerjaannya.
class LaundryScreen extends StatefulWidget {
  const LaundryScreen({super.key});

  @override
  State<LaundryScreen> createState() => _LaundryScreenState();
}

class _LaundryScreenState extends State<LaundryScreen> {
  // Instance database helper
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // List untuk menyimpan semua data laundry
  List<Laundry> _laundries = [];

  // Status loading
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLaundries(); // Load data saat pertama kali buka halaman
  }

  // Fungsi untuk mengambil semua data laundry dari database
  Future<void> _loadLaundries() async {
    setState(() => _isLoading = true); // Tampilkan loading

    final laundries =
        await _dbHelper.getAllLaundries(); // Ambil data dari database

    setState(() {
      _laundries = laundries; // Simpan data ke variable
      _isLoading = false; // Matikan loading
    });
  }

  // Fungsi untuk menampilkan dialog tambah/edit laundry
  Future<void> _showAddEditDialog({Laundry? laundry}) async {
    // Controller untuk input field
    final typeController = TextEditingController(text: laundry?.type ?? '');
    final quantityController = TextEditingController(
      text: laundry?.quantity.toString() ?? '',
    );
    final priceController = TextEditingController(
      text: laundry?.cost.toString() ?? '',
    );
    // Status yang dipilih (default: "Pending" atau status dari laundry)
    String selectedStatus = laundry?.status ?? 'Pending';

    // List pilihan status
    final statuses = ['Pending', 'Sedang Dicuci', 'Selesai'];

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  // Judul dialog (Tambah atau Edit)
                  title: Text(
                    laundry == null ? 'Tambah Laundry' : 'Edit Laundry',
                  ),

                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Input Jenis Pakaian
                        TextField(
                          controller: typeController,
                          decoration: const InputDecoration(
                            labelText: 'Jenis Pakaian',
                            border: OutlineInputBorder(),
                            hintText: 'Contoh: Kaos, Celana, Dll',
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
                            labelText: 'Harga/Biaya',
                            prefixText: 'Rp ',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),

                        // Dropdown Status
                        DropdownButtonFormField<String>(
                          value: selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                          ),
                          items: statuses.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            );
                          }).toList(),
                          // Update status saat user pilih
                          onChanged: (value) {
                            setDialogState(() => selectedStatus = value!);
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
                        if (typeController.text.isEmpty ||
                            quantityController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Harap isi semua field'),
                            ),
                          );
                          return;
                        }

                        // Buat object Laundry
                        final laundryToSave = Laundry(
                          id: laundry?.id, // ID (null untuk data baru)
                          item: typeController.text, // Menggunakan item sebagai name/type di model yang baru
                          type: typeController.text,
                          quantity: int.parse(quantityController.text),
                          status: selectedStatus,
                          cost: double.tryParse(priceController.text) ?? 0,
                        );

                        // Simpan ke database
                        if (laundry == null) {
                          await _dbHelper.insertLaundry(
                            laundryToSave,
                          ); // Tambah baru
                        } else {
                          await _dbHelper.updateLaundry(
                            laundryToSave,
                          ); // Update
                        }

                        if (mounted) {
                          Navigator.pop(context); // Tutup dialog
                          _loadLaundries(); // Refresh data

                          // Tampilkan notifikasi sukses
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                laundry == null
                                    ? 'Laundry ditambahkan'
                                    : 'Laundry diupdate',
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

  // Fungsi untuk menghapus laundry
  Future<void> _deleteLaundry(Laundry laundry) async {
    // Langsung hapus tanpa konfirmasi (sudah ada di SwipeableListItem)
    await _dbHelper.deleteLaundry(laundry.id!); // Hapus dari database
    _loadLaundries(); // Refresh data

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Laundry dihapus')));
    }
  }

  // Fungsi untuk menentukan warna berdasarkan status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange; // Orange untuk pending
      case 'Sedang Dicuci':
        return Colors.blue; // Biru untuk sedang dicuci
      case 'Selesai':
        return Colors.green; // Hijau untuk selesai
      default:
        return Colors.grey; // Abu-abu untuk status lain
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
              : _laundries.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_laundry_service,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada laundry',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
              // Kalau ada data, tampilkan list
              : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _laundries.length,
                itemBuilder: (context, index) {
                  final laundry = _laundries[index];

                  return SwipeableListItem(
                    // Icon di kiri
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple[100],
                      child: const Icon(
                        Icons.local_laundry_service,
                        color: Colors.purple,
                      ),
                    ),

                    // Jenis pakaian
                    title: Text(
                      laundry.type,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    // Detail (jumlah & badge status)
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Jumlah: ${laundry.quantity}'),
                        if (laundry.cost > 0)
                          Text(
                            'Biaya: Rp ${NumberFormat('#,###', 'id_ID').format(laundry.cost)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        const SizedBox(height: 4),

                        // Badge status dengan warna
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  laundry.status,
                                ).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                laundry.status,
                                style: TextStyle(
                                  color: _getStatusColor(laundry.status),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Double tap untuk edit
                    onEdit: () => _showAddEditDialog(laundry: laundry),

                    // Swipe untuk hapus
                    onDelete: () => _deleteLaundry(laundry),

                    deleteConfirmMessage:
                        'Yakin ingin menghapus laundry ${laundry.type}?',
                  );
                },
              ),

      // Tombol tambah di kanan bawah
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
