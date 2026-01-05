// Import package Flutter untuk UI
import 'package:flutter/material.dart';
// Import model Equipment (cetakan data peralatan)
import '../models/equipment.dart';
// Import database helper untuk akses database
import '../database/database_helper.dart';
// Import custom widgets
import '../widgets/widgets.dart';

/// Halaman EquipmentScreen: Mencatat barang/peralatan yang ada di kamar kost (misal: AC, Kursi).
/// Digunakan untuk memantau kondisi barang agar mudah dilaporkan jika ada kerusakan.
class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  // Instance database helper
  final _db = DatabaseHelper.instance;

  // List untuk menyimpan semua data peralatan
  List<Equipment> _items = [];

  @override
  void initState() {
    super.initState();
    _load(); // Load data saat pertama kali buka halaman
  }

  // Fungsi untuk mengambil semua data peralatan dari database
  Future _load() async {
    final list = await _db.getAllEquipments(); // Ambil data dari database
    setState(() => _items = list); // Simpan ke variable dan update UI
  }

  // Fungsi untuk menampilkan dialog tambah/edit peralatan
  Future _showForm({Equipment? edit}) async {
    // Controller untuk input nama
    final nameCtrl = TextEditingController(text: edit?.name ?? '');

    // Kondisi yang dipilih (default: "Baik" atau kondisi dari edit)
    String condition = edit?.condition ?? 'Baik';

    // List pilihan kondisi
    final conditions = [
      'Baik',
      'Rusak Ringan',
      'Rusak Berat',
      'Perlu Perbaikan',
    ];

    await showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  // Judul dialog (Tambah atau Edit)
                  title: Text(
                    edit == null ? 'Tambah Peralatan' : 'Edit Peralatan',
                  ),

                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Input Nama Barang
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nama Barang',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Dropdown Kondisi
                      DropdownButtonFormField<String>(
                        value: condition,
                        decoration: const InputDecoration(labelText: 'Kondisi'),
                        items:
                            conditions
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                        // Update kondisi saat user pilih
                        onChanged: (v) => setState(() => condition = v!),
                      ),
                    ],
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
                        final name = nameCtrl.text.trim();

                        // Validasi: nama harus diisi
                        if (name.isEmpty) return;

                        // Buat object Equipment
                        final data = Equipment(
                          id: edit?.id, // ID (null untuk data baru)
                          name: name,
                          condition: condition,
                        );

                        // Simpan ke database
                        if (edit == null) {
                          await _db.insertEquipment(data); // Tambah baru
                        } else {
                          await _db.updateEquipment(data); // Update
                        }

                        if (mounted) {
                          Navigator.pop(context); // Tutup dialog
                          await _load(); // Refresh data
                        }
                      },
                      child: const Text('Simpan'),
                    ),
                  ],
                ),
          ),
    );
  }

  // Fungsi untuk menghapus peralatan
  Future _delete(Equipment item) async {
    // Langsung hapus dari database tanpa konfirmasi
    // (konfirmasi sudah ditangani oleh SwipeableListItem)
    await _db.deleteEquipment(item.id!); // Hapus dari database
    await _load(); // Refresh data
  }

  // Fungsi untuk menentukan warna berdasarkan kondisi
  Color _getColor(String condition) {
    switch (condition) {
      case 'Baik':
        return Colors.green; // Hijau untuk kondisi baik
      case 'Rusak Ringan':
        return Colors.orange; // Orange untuk rusak ringan
      case 'Rusak Berat':
        return Colors.red; // Merah untuk rusak berat
      case 'Perlu Perbaikan':
        return Colors.amber; // Kuning untuk perlu perbaikan
      default:
        return Colors.grey; // Abu-abu untuk kondisi lain
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          // Kalau data kosong, tampilkan pesan kosong
          _items.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chair_alt, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada peralatan',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
              // Kalau ada data, tampilkan list
              : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];

                  return SwipeableListItem(
                    // Icon di kiri dengan warna sesuai kondisi
                    leading: CircleAvatar(
                      backgroundColor: _getColor(
                        item.condition,
                      ).withOpacity(0.2),
                      child: Icon(
                        Icons.chair_alt,
                        color: _getColor(item.condition),
                      ),
                    ),

                    // Nama barang
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    // Badge kondisi dengan warna
                    subtitle: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getColor(item.condition).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.condition,
                          style: TextStyle(
                            color: _getColor(item.condition),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Double tap untuk edit
                    onEdit: () => _showForm(edit: item),

                    // Swipe untuk hapus
                    onDelete: () => _delete(item),

                    deleteConfirmMessage: 'Yakin ingin menghapus ${item.name}?',
                  );
                },
              ),

      // Tombol tambah di kanan bawah
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
