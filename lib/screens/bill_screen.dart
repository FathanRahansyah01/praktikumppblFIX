// Import package Flutter untuk UI
import 'package:flutter/material.dart';
// Import database helper untuk akses database
import '../database/database_helper.dart';
// Import model Bill (cetakan data tagihan)
import '../models/bill.dart';
// Import custom widgets
import '../widgets/widgets.dart';

/// Halaman BillScreen: Mengelola daftar tagihan rutin bulanan (misal: WiFi, Listrik).
/// Pengguna dapat mencatat nominal dan tanggal jatuh tempo agar tidak terlambat membayar.
class BillScreen extends StatefulWidget {
  const BillScreen({super.key});

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> {
  // Instance database helper
  final _db = DatabaseHelper.instance;

  // List untuk menyimpan semua data tagihan
  List<Bill> _bills = [];

  // Status loading
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBills(); // Load data saat pertama kali buka halaman
  }

  // Fungsi untuk mengambil semua data tagihan dari database
  Future<void> _loadBills() async {
    setState(() => _loading = true); // Tampilkan loading

    final data = await _db.getAllBills(); // Ambil data dari database

    setState(() {
      _bills = data; // Simpan data ke variable
      _loading = false; // Matikan loading
    });
  }

  // Fungsi untuk menampilkan dialog tambah/edit tagihan
  Future<void> _showBillDialog({Bill? bill}) async {
    // Controller untuk input field
    final nameCtrl = TextEditingController(text: bill?.name ?? '');
    final amountCtrl = TextEditingController(
      text: bill?.amount.toString() ?? '',
    );

    // Tanggal jatuh tempo yang dipilih (default: hari ini atau tanggal dari bill)
    DateTime dueDate =
        bill != null ? DateTime.parse(bill.dueDate) : DateTime.now();

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  // Judul dialog (Tambah atau Edit)
                  title: Text(bill == null ? 'Tambah Tagihan' : 'Edit Tagihan'),

                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Input Nama Tagihan
                        TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nama Tagihan',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Input Nominal
                        TextField(
                          controller: amountCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nominal',
                            prefixText: 'Rp ',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number, // Keyboard angka
                        ),
                        const SizedBox(height: 12),

                        // Pilih Tanggal Jatuh Tempo
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Tenggat'),
                          subtitle: Text(
                            '${dueDate.day}/${dueDate.month}/${dueDate.year}',
                          ),
                          trailing: const Icon(Icons.calendar_month),
                          onTap: () async {
                            // Tampilkan date picker
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: dueDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );

                            if (picked != null) {
                              setDialogState(() => dueDate = picked);
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
                        if (nameCtrl.text.isEmpty || amountCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Harap isi semua field'),
                            ),
                          );
                          return;
                        }

                        // Buat object Bill
                        final billData = Bill(
                          id: bill?.id, // ID (null untuk data baru)
                          name: nameCtrl.text.trim(),
                          amount: double.tryParse(amountCtrl.text) ?? 0,
                          dueDate: dueDate.toIso8601String().split('T').first,
                        );

                        // Simpan ke database
                        if (bill == null) {
                          await _db.insertBill(billData); // Tambah baru
                        } else {
                          await _db.updateBill(billData); // Update
                        }

                        if (!mounted) return;
                        Navigator.pop(context); // Tutup dialog
                        _loadBills(); // Refresh data

                        // Tampilkan notifikasi sukses
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              bill == null
                                  ? 'Tagihan ditambahkan'
                                  : 'Tagihan diperbarui',
                            ),
                          ),
                        );
                      },
                      child: const Text('Simpan'),
                    ),
                  ],
                ),
          ),
    );
  }

  // Fungsi untuk menghapus tagihan
  Future<void> _deleteBill(Bill bill) async {
    await _db.deleteBill(bill.id!);
    _loadBills();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Tagihan dihapus')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _loading
              // Kalau loading, tampilkan loading indicator
              ? const Center(child: CircularProgressIndicator())
              // Kalau data kosong, tampilkan pesan kosong
              : _bills.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada tagihan',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
              // Kalau ada data, tampilkan list
              : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _bills.length,
                itemBuilder: (context, index) {
                  final bill = _bills[index];

                  return SwipeableListItem(
                    // Icon di kiri
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: const Icon(Icons.receipt_long, color: Colors.blue),
                    ),

                    // Nama tagihan
                    title: Text(
                      bill.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    // Detail (nominal & tanggal jatuh tempo)
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rp ${bill.amount.toStringAsFixed(0)}'),
                        Text('Jatuh tempo: ${bill.dueDate}'),
                      ],
                    ),

                    // Double tap untuk edit
                    onEdit: () => _showBillDialog(bill: bill),

                    // Swipe untuk hapus
                    onDelete: () => _deleteBill(bill),

                    deleteConfirmMessage:
                        'Yakin ingin menghapus tagihan ${bill.name}?',
                  );
                },
              ),

      // Tombol tambah di kanan bawah
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBillDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
