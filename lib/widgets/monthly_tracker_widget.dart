import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/finance_note.dart';

/// Widget MonthlyTrackerWidget: Memungkinkan pengguna memilih bulan tertentu 
/// melalui dropdown dan melihat rangkuman pengeluaran per kategori pada bulan tersebut.
class MonthlyTrackerWidget extends StatefulWidget {
  const MonthlyTrackerWidget({super.key});

  @override
  State<MonthlyTrackerWidget> createState() => _MonthlyTrackerWidgetState();
}

class _MonthlyTrackerWidgetState extends State<MonthlyTrackerWidget> {
  final _db = DatabaseHelper.instance;
  
  // Bulan dan Tahun yang dipilih (default: sekarang)
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  
  List<FinanceNote> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Mengambil data dari database
  Future<void> _loadData() async {
    final data = await _db.getAllFinanceNotes();
    if (mounted) {
      setState(() {
        _notes = data;
        _loading = false;
      });
    }
  }

  // Fungsi untuk mendapatkan list bulan (untuk dropdown) - 6 bulan ke belakang
  List<DateTime> _getMonthOptions() {
    final now = DateTime.now();
    return List.generate(6, (i) => DateTime(now.year, now.month - i));
  }

  // Fungsi untuk memfilter data berdasarkan bulan yang dipilih
  Map<String, double> _getFilteredData() {
    final map = <String, double>{};
    for (var note in _notes) {
      // Hanya ambil pengeluaran yang bulan & tahunnya cocok
      if (note.type == 'expense' && 
          note.timestamp.month == _selectedMonth.month && 
          note.timestamp.year == _selectedMonth.year) {
        map[note.source] = (map[note.source] ?? 0) + note.amount;
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final filteredData = _getFilteredData();
    final monthOptions = _getMonthOptions();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lacak Bulanan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                // Dropdown untuk pilih bulan
                DropdownButton<DateTime>(
                  value: _selectedMonth,
                  underline: const SizedBox(), // Hilangkan garis bawah default
                  icon: const Icon(Icons.calendar_today, size: 16),
                  items: monthOptions.map((date) {
                    // Format tampilan bulan (misal: "Desember 2025")
                    String label = DateFormat('MMMM yyyy', 'id_ID').format(date);
                    return DropdownMenuItem(value: date, child: Text(label, style: const TextStyle(fontSize: 13)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedMonth = val);
                  },
                ),
              ],
            ),
            const Divider(),
            
            // Tampilan Data Per Kategori
            if (filteredData.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('Tidak ada transaksi di bulan ini.', style: TextStyle(fontSize: 12, color: Colors.grey))),
              )
            else
              ...filteredData.entries.map((entry) => _buildCategoryRow(entry.key, entry.value)),
              
            const SizedBox(height: 10),
            Text(
               'Total: Rp ${NumberFormat('#,###', 'id_ID').format(filteredData.values.fold(0.0, (a, b) => a + b))}',
               style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
          ],
        ),
      ),
    );
  }

  // Widget baris untuk setiap kategori (misal: Makanan -> Rp 50.000)
  Widget _buildCategoryRow(String category, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.circle, size: 8, color: Colors.indigo),
              const SizedBox(width: 8),
              Text(category.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
          Text(
            'Rp ${NumberFormat('#,###', 'id_ID').format(amount)}',
            style: const TextStyle(fontSize: 13, color: Colors.redAccent, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
