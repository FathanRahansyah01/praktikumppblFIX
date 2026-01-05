import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/finance_note.dart';

/// Widget ExpenseSummaryCards: Menampilkan dua kartu ringkasan utama di Dashboard.
/// 1. Total pengeluaran bulan ini (semua modul).
/// 2. Sumber pengeluaran yang paling dominan (makanan, laundry, dll).
class ExpenseSummaryCards extends StatefulWidget {
  const ExpenseSummaryCards({super.key});

  @override
  State<ExpenseSummaryCards> createState() => _ExpenseSummaryCardsState();
}

class _ExpenseSummaryCardsState extends State<ExpenseSummaryCards> {
  final _db = DatabaseHelper.instance;
  double _monthlyTotal = 0;
  String _topCategory = '-';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSummary(); // Load data saat kartu ditampilkan
  }

  // Fungsi untuk menghitung ringkasan data keuangan
  Future<void> _loadSummary() async {
    if (!mounted) return;
    setState(() => _loading = true);

    // Ambil SEMUA catatan keuangan terpadu (Unified Finance)
    final notes = await _db.getAllFinanceNotes();
    final now = DateTime.now();

    // Filter transaksi tipe 'expense' (pengeluaran) di bulan ini
    final monthlyExpenses = notes.where((note) {
      return note.type == 'expense' &&
             note.timestamp.year == now.year && 
             note.timestamp.month == now.month;
    }).toList();

    double total = 0;
    final categoryTotals = <String, double>{};

    // Hitung total uang keluar dan kelompokkan berdasarkan sumbernya
    for (var note in monthlyExpenses) {
      total += note.amount;
      // Source berisi 'makanan', 'laundry', 'tagihan', dll
      String source = note.source.toUpperCase();
      categoryTotals[source] = (categoryTotals[source] ?? 0) + note.amount;
    }

    // Cari sumber yang memakan biaya paling banyak
    String topCat = '-';
    double maxAmount = 0;
    categoryTotals.forEach((category, amount) {
      if (amount > maxAmount) {
        maxAmount = amount;
        topCat = category;
      }
    });

    if (mounted) {
      setState(() {
        _monthlyTotal = total;
        _topCategory = topCat;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Row(
      children: [
        // Kartu 1: Total Pengeluaran Bulan Ini
        Expanded(
          child: Card(
            elevation: 2,
            color: Colors.red[50], // Latar belakang merah pucat (tanda uang keluar)
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_month, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Bulan Ini',
                        style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Rp ${NumberFormat('#,###', 'id_ID').format(_monthlyTotal)}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[900]),
                  ),
                  const Text('Total Keluar', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Kartu 2: Pengeluaran Terbanyak (Sumber Utama)
        Expanded(
          child: Card(
            elevation: 2,
            color: Colors.blue[50], // Latar belakang biru pucat
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Dominan',
                        style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _topCategory,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text('Sumber Utama', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
