import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/finance_note.dart';

/// Widget WeeklyExpenseChart: Menampilkan grafik batang ganda untuk membandingkan
/// pemasukan (hijau) dan pengeluaran (merah) selama 7 hari terakhir.
class WeeklyExpenseChart extends StatefulWidget {
  const WeeklyExpenseChart({super.key});

  @override
  State<WeeklyExpenseChart> createState() => _WeeklyExpenseChartState();
}

class _WeeklyExpenseChartState extends State<WeeklyExpenseChart> {
  // Instance database helper untuk mengambil data
  final _db = DatabaseHelper.instance;
  
  // List untuk menampung semua catatan keuangan
  List<FinanceNote> _notes = [];
  
  // Status pemuatan data
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData(); // Ambil data saat widget pertama kali dibuat
  }

  // Fungsi untuk mengambil data transaksi dari database
  Future<void> _loadData() async {
    setState(() => _loading = true);
    // Mengambil data dari tabel catatan_keuangan (Unified Finance)
    final data = await _db.getAllFinanceNotes();
    setState(() {
      _notes = data;
      _loading = false;
    });
  }

  // Fungsi untuk memproses data menjadi format yang dipahami grafik
  // Mengembalikan map: {index_hari: {income: total, expense: total}}
  Map<int, Map<String, double>> _getWeeklyData() {
    final now = DateTime.now();
    final weekData = <int, Map<String, double>>{};

    // Inisialisasi 7 hari terakhir dengan nilai 0
    for (int i = 0; i < 7; i++) {
      weekData[i] = {'income': 0.0, 'expense': 0.0};
    }

    // Kelompokkan transaksi berdasarkan tanggal dan tipe
    for (var note in _notes) {
      final daysDiff = now.difference(note.timestamp).inDays;

      // Hanya ambil data dalam rentang 7 hari terakhir
      if (daysDiff >= 0 && daysDiff < 7) {
        int index = 6 - daysDiff; // Index 0 adalah hari tertua (7 hari lalu), 6 adalah hari ini
        if (note.type == 'income') {
          weekData[index]!['income'] = (weekData[index]!['income'] ?? 0) + note.amount;
        } else {
          weekData[index]!['expense'] = (weekData[index]!['expense'] ?? 0) + note.amount;
        }
      }
    }

    return weekData;
  }

  // Fungsi untuk menentukan label nama hari pada sumbu X
  String _getDayLabel(int index) {
    final now = DateTime.now();
    final date = now.subtract(Duration(days: 6 - index));
    final days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    return days[date.weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan indikator loading jika data sedang diambil
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final weekData = _getWeeklyData();
    
    // Mencari nilai tertinggi untuk menentukan skala grafik (Y)
    double maxVal = 10000.0;
    for (var data in weekData.values) {
      if (data['income']! > maxVal) maxVal = data['income']!;
      if (data['expense']! > maxVal) maxVal = data['expense']!;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul Grafik
            const Text(
              'Arus Kas 7 Hari Terakhir',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            
            // Keterangan warna (Legend)
            Row(
              children: [
                _buildLegendItem('Masuk', Colors.green),
                const SizedBox(width: 15),
                _buildLegendItem('Keluar', Colors.red),
              ],
            ),
            const SizedBox(height: 24),

            // Kontainer Grafik Batang
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVal * 1.2, // Beri jarak 20% di atas batang tertinggi
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          'Rp ${NumberFormat('#,###', 'id_ID').format(rod.toY)}',
                          const TextStyle(color: Colors.white, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(_getDayLabel(value.toInt()), style: const TextStyle(fontSize: 10)),
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const Text('');
                          return Text('${(value / 1000).toStringAsFixed(0)}k', style: const TextStyle(fontSize: 9));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  // Membuat grup batang untuk setiap hari
                  barGroups: weekData.entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        // Batang Pemasukan (Hijau)
                        BarChartRodData(
                          toY: entry.value['income']!,
                          color: Colors.green,
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        // Batang Pengeluaran (Merah)
                        BarChartRodData(
                          toY: entry.value['expense']!,
                          color: Colors.red,
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget kecil untuk menampilkan keterangan warna (Hijau = Masuk, Merah = Keluar)
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
