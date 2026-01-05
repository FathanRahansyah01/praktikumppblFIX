import 'package:flutter/material.dart';
import 'expense_screen.dart';
import 'daily_need_screen.dart';

/// Halaman UnifiedFinanceScreen: Layar gabungan yang menyatukan Pengeluaran dan Kebutuhan Harian.
/// Menggunakan TabBar untuk navigasi antar kategori keuangan dan kebutuhan.
class UnifiedFinanceScreen extends StatelessWidget {
  const UnifiedFinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Keuangan & Kebutuhan'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.money_off), text: 'Pengeluaran'),
              Tab(icon: Icon(Icons.check_circle_outline), text: 'Kebutuhan Harian'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
          elevation: 0,
        ),
        body: const TabBarView(
          children: [
            ExpenseScreen(),
            DailyNeedScreen(),
          ],
        ),
      ),
    );
  }
}
