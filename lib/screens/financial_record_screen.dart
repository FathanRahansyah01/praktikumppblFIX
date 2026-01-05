// Import package Flutter untuk UI
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk format mata uang
// Import model FinanceNote
import '../models/finance_note.dart';
// Import database helper untuk akses database
import '../database/database_helper.dart';
// Import custom widgets
import '../widgets/widgets.dart';

// Halaman Catatan Keuangan - Menampilkan semua transaksi dan saldo
class FinancialRecordScreen extends StatefulWidget {
  const FinancialRecordScreen({super.key});

  @override
  State<FinancialRecordScreen> createState() => _FinancialRecordScreenState();
}

class _FinancialRecordScreenState extends State<FinancialRecordScreen> {
  // Instance database helper
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // List untuk menyimpan semua transaksi
  List<FinanceNote> _transactions = [];

  // Saldo saat ini
  double _currentBalance = 0.0;

  // Status loading
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData(); // Load data saat pertama kali buka halaman
  }

  // Fungsi untuk mengambil semua data transaksi dan saldo dari database
  Future<void> _loadData() async {
    setState(() => _isLoading = true); // Tampilkan loading

    final transactions = await _dbHelper.getAllFinanceNotes();
    final balance = await _dbHelper.getCurrentBalance();

    setState(() {
      _transactions = transactions;
      _currentBalance = balance;
      _isLoading = false; // Matikan loading
    });
  }

  // Fungsi untuk menampilkan dialog set saldo awal
  Future<void> _showSetBalanceDialog() async {
    final balanceController = TextEditingController(
      text: _currentBalance.toString(),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atur Saldo'),
        content: TextField(
          controller: balanceController,
          decoration: const InputDecoration(
            labelText: 'Saldo',
            prefixText: 'Rp ',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newBalance = double.tryParse(balanceController.text) ?? 0;
              final difference = newBalance - _currentBalance;

              if (difference != 0) {
                // Catat sebagai transaksi penyesuaian saldo
                await _dbHelper.recordTransaction(
                  note: difference > 0
                      ? 'Tambah Saldo Manual'
                      : 'Kurangi Saldo Manual',
                  amount: difference.abs(),
                  type: difference > 0 ? 'income' : 'expense',
                  source: 'manual',
                );

                if (mounted) {
                  Navigator.pop(context);
                  _loadData(); // Refresh data

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saldo berhasil diatur')),
                  );
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk menghapus transaksi
  Future<void> _deleteTransaction(FinanceNote transaction) async {
    await _dbHelper.deleteFinanceNote(transaction.id!);
    _loadData(); // Refresh data

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi dihapus, saldo dikembalikan')),
      );
    }
  }

  // Fungsi untuk mendapatkan icon berdasarkan source
  IconData _getIconBySource(String source) {
    switch (source) {
      case 'makanan':
        return Icons.fastfood;
      case 'laundry':
        return Icons.local_laundry_service;
      case 'tagihan':
        return Icons.receipt_long;
      case 'belanja':
        return Icons.shopping_cart;
      case 'harian':
        return Icons.check_circle;
      case 'manual':
        return Icons.edit;
      default:
        return Icons.attach_money;
    }
  }

  // Fungsi untuk mendapatkan warna berdasarkan source
  Color _getColorBySource(String source) {
    switch (source) {
      case 'makanan':
        return Colors.green;
      case 'laundry':
        return Colors.blue;
      case 'tagihan':
        return Colors.orange;
      case 'belanja':
        return Colors.purple;
      case 'harian':
        return Colors.teal;
      case 'manual':
        return Colors.grey;
      default:
        return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Card Saldo
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade700, Colors.indigo.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Saldo Saat Ini',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: _showSetBalanceDialog,
                            tooltip: 'Atur Saldo',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rp ${NumberFormat('#,###', 'id_ID').format(_currentBalance)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // List Transaksi
                Expanded(
                  child: _transactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Belum ada transaksi',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _transactions[index];
                            final isIncome = transaction.type == 'income';
                            final color = _getColorBySource(transaction.source);

                            return SwipeableListItem(
                              // Icon di kiri
                              leading: CircleAvatar(
                                backgroundColor: color.withOpacity(0.2),
                                child: Icon(
                                  _getIconBySource(transaction.source),
                                  color: color,
                                ),
                              ),

                              // Deskripsi transaksi
                              title: Text(
                                transaction.note,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              // Detail (tanggal & kategori)
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('dd MMM yyyy, HH:mm')
                                        .format(transaction.timestamp),
                                  ),
                                  Text(
                                    'Kategori: ${_getCategoryName(transaction.source)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),

                              // Nominal di kanan
                              trailing: Text(
                                '${isIncome ? '+' : '-'} Rp ${NumberFormat('#,###', 'id_ID').format(transaction.amount)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isIncome ? Colors.green : Colors.red,
                                ),
                              ),

                              // Edit (disabled untuk transaksi otomatis)
                              onEdit: () {
                                if (transaction.source != 'manual') {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Transaksi otomatis tidak dapat diedit di sini. Silakan edit dari menu asalnya.'),
                                    ),
                                  );
                                } else {
                                  // TODO: Implement edit manual transaction if needed
                                }
                              },

                              // Swipe untuk hapus
                              onDelete: () => _deleteTransaction(transaction),

                              deleteConfirmMessage:
                                  'Yakin ingin menghapus transaksi ini? Saldo akan dikembalikan.',
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  // Helper untuk mendapatkan nama kategori yang lebih friendly
  String _getCategoryName(String source) {
    switch (source) {
      case 'makanan':
        return 'Persediaan Makanan';
      case 'laundry':
        return 'Laundry';
      case 'tagihan':
        return 'Tagihan Bulanan';
      case 'belanja':
        return 'Daftar Belanja';
      case 'harian':
        return 'Kebutuhan Harian';
      case 'manual':
        return 'Manual';
      default:
        return source;
    }
  }
}
