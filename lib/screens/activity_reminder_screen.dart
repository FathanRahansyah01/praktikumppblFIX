// Import package Flutter untuk UI
import 'package:flutter/material.dart';
// Import untuk filter input (hanya angka dan titik dua)
import 'package:flutter/services.dart';
// Import model ActivityReminder (cetakan data pengingat kegiatan)
import '../models/activity_reminder.dart';
// Import database helper untuk akses database
import '../database/database_helper.dart';
// Import custom widgets
import '../widgets/widgets.dart';

/// Halaman ActivityReminderScreen: Menyimpan jadwal kegiatan harian pengguna kost.
/// Pengguna dapat mencatat nama kegiatan dan jam pelaksanaannya sebagai pengingat.
class ActivityReminderScreen extends StatefulWidget {
  const ActivityReminderScreen({super.key});

  @override
  State<ActivityReminderScreen> createState() => _ActivityReminderScreenState();
}

class _ActivityReminderScreenState extends State<ActivityReminderScreen> {
  // Instance database helper
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // List untuk menyimpan semua data pengingat
  List<ActivityReminder> _reminders = [];

  // Status loading
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders(); // Load data saat pertama kali buka halaman
  }

  // Fungsi untuk mengambil semua data pengingat dari database
  Future<void> _loadReminders() async {
    setState(() => _isLoading = true); // Tampilkan loading

    final reminders =
        await _dbHelper.getAllActivityReminders(); // Ambil data dari database

    setState(() {
      _reminders = reminders; // Simpan data ke variable
      _isLoading = false; // Matikan loading
    });
  }

  // Fungsi untuk menampilkan dialog tambah/edit pengingat
  Future<void> _showAddEditDialog({ActivityReminder? reminder}) async {
    // Tampilkan dialog dan tunggu hasilnya
    final result = await showDialog<ActivityReminder>(
      context: context,
      builder: (context) => ActivityReminderDialog(reminder: reminder),
    );

    // Jika ada hasil (user klik simpan), simpan ke database
    if (result != null && mounted) {
      if (result.id == null) {
        await _dbHelper.insertActivityReminder(result); // Tambah baru
      } else {
        await _dbHelper.updateActivityReminder(result); // Update existing
      }

      _loadReminders(); // Refresh list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.id == null
                  ? 'Pengingat kegiatan ditambahkan'
                  : 'Pengingat kegiatan diperbarui',
            ),
          ),
        );
      }
    }
  }

  // Fungsi untuk menghapus pengingat
  Future<void> _deleteReminder(ActivityReminder reminder) async {
    await _dbHelper.deleteActivityReminder(reminder.id!);
    _loadReminders();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengingat kegiatan dihapus')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              // Kalau loading, tampilkan loading indicator
              ? const Center(child: CircularProgressIndicator())
              // Kalau data kosong, tampilkan pesan kosong
              : _reminders.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada pengingat kegiatan',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
              // Kalau ada data, tampilkan list
              : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _reminders.length,
                itemBuilder: (context, index) {
                  final reminder = _reminders[index];

                  return SwipeableListItem(
                    // Icon di kiri
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple[100],
                      child: const Icon(
                        Icons.notifications,
                        color: Colors.purple,
                      ),
                    ),

                    // Nama kegiatan
                    title: Text(
                      reminder.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    // Waktu
                    subtitle: Text('Waktu: ${reminder.time}'),

                    // Double tap untuk edit
                    onEdit: () => _showAddEditDialog(reminder: reminder),

                    // Swipe untuk hapus
                    onDelete: () => _deleteReminder(reminder),

                    deleteConfirmMessage:
                        'Yakin ingin menghapus pengingat ${reminder.name}?',
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

/// Widget dialog terpisah untuk Tambah/Edit Pengingat
/// Mengelola controller dan validasi sendiri agar lebih aman & rapi.
class ActivityReminderDialog extends StatefulWidget {
  final ActivityReminder? reminder;

  const ActivityReminderDialog({super.key, this.reminder});

  @override
  State<ActivityReminderDialog> createState() => _ActivityReminderDialogState();
}

class _ActivityReminderDialogState extends State<ActivityReminderDialog> {
  late TextEditingController _nameController;
  late TextEditingController _timeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.reminder?.name ?? '');
    _timeController = TextEditingController(text: widget.reminder?.time ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  // Validasi format HH:mm
  bool _isValidTimeFormat(String time) {
    final regex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
    return regex.hasMatch(time);
  }

  // Parse string ke TimeOfDay
  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length == 2) {
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    return TimeOfDay.now();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final time = _timeController.text.trim();

    // Validasi kosong
    if (name.isEmpty || time.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi semua field')),
      );
      return;
    }

    // Validasi format
    if (!_isValidTimeFormat(time)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Format waktu tidak valid. Gunakan format HH:mm')),
      );
      return;
    }

    // Return object baru
    final result = ActivityReminder(
      id: widget.reminder?.id, // Pertahankan ID lama jika edit
      name: name,
      time: time,
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.reminder == null
            ? 'Tambah Pengingat Kegiatan'
            : 'Edit Pengingat Kegiatan',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Input Nama Kegiatan
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Kegiatan',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
            ),
            const SizedBox(height: 16),

            // Input Waktu (format HH:mm)
            TextField(
              controller: _timeController,
              decoration: const InputDecoration(
                labelText: 'Waktu (HH:mm)',
                border: OutlineInputBorder(),
                hintText: 'Contoh: 08:00',
              ),
              keyboardType: TextInputType.datetime,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
              ],
            ),
            const SizedBox(height: 8),

            // Opsi Time Picker
            ListTile(
              title: const Text('Atau pilih waktu'),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final currentVal =
                    _timeController.text.isNotEmpty
                        ? _parseTime(_timeController.text)
                        : TimeOfDay.now();

                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: currentVal,
                );

                if (picked != null) {
                  final formattedTime =
                      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                  setState(() {
                    _timeController.text = formattedTime;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
