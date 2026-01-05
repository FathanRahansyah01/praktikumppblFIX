import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';
import '../models/finance_note.dart';

/// Widget CategoryPieChart: Menampilkan diagram lingkaran (Pie Chart) 
/// yang menunjukkan porsi pengeluaran berdasarkan sumber/kategori transaksi.
class CategoryPieChart extends StatefulWidget {
  const CategoryPieChart({super.key});

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  final _db = DatabaseHelper.instance;

  @override
  Widget build(BuildContext context) {
    // Dengarkan perubahan database
    return StreamBuilder<void>(
      stream: _db.onTransactionChanged,
      builder: (context, snapshot) {
        return FutureBuilder<List<FinanceNote>>(
          future: _db.getAllFinanceNotes(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final notes = snapshot.data!;
            final data = _getCategoryData(notes);

            if (data.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('Belum ada data pengeluaran bulan ini.'),
                ),
              );
            }

            // List warna untuk setiap potongan pie
            final colors = [
              Colors.blue,
              Colors.orange,
              Colors.green,
              Colors.purple,
              Colors.red,
              Colors.teal,
              Colors.pink
            ];

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Porsi Pengeluaran Bulan Ini',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    // Grafik Pie
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: data.entries.map((entry) {
                            int index = data.keys.toList().indexOf(entry.key);
                            return PieChartSectionData(
                              color: colors[index % colors.length],
                              value: entry.value,
                              title:
                                  '${entry.key}\n${(entry.value / 1000).toStringAsFixed(0)}k',
                              radius: 50,
                              titleStyle: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    const Text(
                      'Insights: Semakin besar potongan, semakin banyak uang habis di sana.',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Memproses data menjadi hitungan per kategori (Netto: Pengeluaran - Pengembalian)
  Map<String, double> _getCategoryData(List<FinanceNote> notes) {
    final categoryMap = <String, double>{};
    final now = DateTime.now();

    for (var note in notes) {
      // Filter bulan ini
      if (note.timestamp.month == now.month &&
          note.timestamp.year == now.year) {
        String cat = note.source;

        if (note.type == 'expense') {
          // Tambah beban pengeluaran
          categoryMap[cat] = (categoryMap[cat] ?? 0) + note.amount;
        } else if (note.type == 'income') {
          // Kurangi beban jika ada refund/koreksi (misal barang dihapus/harga turun)
          categoryMap[cat] = (categoryMap[cat] ?? 0) - note.amount;
        }
      }
    }

    // Bersihkan kategori yang nilainya 0 atau negatif (hasil refund total)
    categoryMap.removeWhere((key, value) => value <= 0);

    return categoryMap;
  }
}
