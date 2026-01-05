// Import package Flutter untuk UI
import 'package:flutter/material.dart';
// Import service untuk menyimpan preferensi user (nama)
import '../services/preferences_service.dart';
// Import widgets untuk chart dan summary
import '../widgets/weekly_expense_chart.dart';
import '../widgets/expense_summary_cards.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/monthly_tracker_widget.dart';
import 'package:intl/date_symbol_data_local.dart'; // Untuk format tanggal lokal Indonesia

/// Halaman HomeScreen: Dashboard utama aplikasi yang menyapa pengguna.
/// Menampilkan rangkuman pengeluaran mingguan dalam bentuk grafik dan kartu ringkasan.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Service untuk menyimpan data preferensi (SharedPreferences)
  final _prefs = PreferencesService.instance;

  // Variable untuk menyimpan status dan data
  bool _loading = true;              // Status loading (tampil muter-muter)
  String _name = 'Pengguna';         // Nama user yang akan ditampilkan di sapaan

  @override
  void initState() {
    super.initState();
    _load();  // Load data saat pertama kali buka halaman
  }

  // Fungsi untuk memuat data dari memori (SharedPreferences)
  Future<void> _load() async {
    await _prefs.init();  // Siapkan layanan preferensi
    await initializeDateFormatting('id_ID', null); // Siapkan format tanggal Indonesia
    
    // Perbarui UI setelah data berhasil diambil
    setState(() {
      _name = _prefs.getUserName() ?? 'Pengguna';
      _loading = false;
    });
  }

  // Fungsi untuk menampilkan kotak dialog ganti nama
  Future<void> _showEditNameDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => EditNameDialog(currentName: _name),
    );

    if (result != null && mounted) {
      await _prefs.saveUserName(result);
      setState(() => _name = result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama berhasil diperbarui!')),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Kalau masih loading, tampilkan loading indicator
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      // AppBar dengan nama user dan tombol edit
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.home, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dashboard',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Halo, $_name',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditNameDialog,
            tooltip: 'Ganti Nama',
          ),
        ],
        elevation: 0,
      ),

      // Body dengan RefreshIndicator
      body: RefreshIndicator(
        onRefresh: () async {
          await _load();
          // Trigger rebuild untuk refresh chart
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              const ExpenseSummaryCards(),
              const SizedBox(height: 20),

              // Grafik Arus Kas 7 Hari (Masuk vs Keluar)
              const WeeklyExpenseChart(),
              const SizedBox(height: 20),

              // Visualisasi Porsi Pengeluaran (Pie Chart)
              const CategoryPieChart(),
              const SizedBox(height: 20),

              // Pelacak Bulanan dengan Dropdown
              const MonthlyTrackerWidget(),
              const SizedBox(height: 20),

              // Quick Info
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fitur Aplikasi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Kelola Keuangan',
                        subtitle: 'Catat pengeluaran & kebutuhan harian',
                        color: Colors.blue,
                      ),
                      const Divider(height: 20),
                      _buildInfoRow(
                        icon: Icons.fastfood_outlined,
                        title: 'Persediaan Makanan',
                        subtitle: 'Pantau stok makanan di kost',
                        color: Colors.orange,
                      ),
                      const Divider(height: 20),
                      _buildInfoRow(
                        icon: Icons.shopping_cart_outlined,
                        title: 'Daftar Belanja',
                        subtitle: 'Buat daftar belanjaan',
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Tips Card
              Card(
                elevation: 1,
                color: Colors.blue[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tarik ke bawah untuk refresh data terbaru',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget dialog terpisah untuk menangani Edit Nama
/// Ini mencegah error "Controller disposed" karena Lifecycle controller
/// sekarang terikat penuh pada Lifecycle widget dialog ini.
class EditNameDialog extends StatefulWidget {
  final String currentName;

  const EditNameDialog({super.key, required this.currentName});

  @override
  State<EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<EditNameDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ganti Nama'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Nama Baru Anda',
          hintText: 'Masukkan nama...',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
        textCapitalization: TextCapitalization.words,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            final newName = _controller.text.trim();
            if (newName.isNotEmpty) {
              Navigator.pop(context, newName); // Kembalikan nama baru ke halaman utama
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
