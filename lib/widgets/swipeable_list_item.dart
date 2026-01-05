import 'package:flutter/material.dart';

/// Custom List Item Widget dengan Gesture Controls
/// - Double Tap untuk edit
/// - Swipe dari kiri ke kanan untuk hapus
/// Sesuai ketentuan: StatelessWidget, dapat digunakan ulang,
/// menyederhanakan kode, memudahkan perawatan
class SwipeableListItem extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String deleteConfirmMessage;

  const SwipeableListItem({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onEdit,
    required this.onDelete,
    this.deleteConfirmMessage = 'Yakin ingin menghapus item ini?',
  });

  // Fungsi untuk konfirmasi hapus
  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: Text(deleteConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      // Unique key untuk setiap item
      key: UniqueKey(),

      // Hanya bisa swipe dari kiri ke kanan
      direction: DismissDirection.startToEnd,

      // Konfirmasi sebelum hapus
      confirmDismiss: (direction) async {
        return await _confirmDelete(context);
      },

      // Callback saat item dihapus (langsung panggil tanpa konfirmasi lagi)
      onDismissed: (direction) {
        onDelete();
      },

      // Background saat swipe (warna merah dengan icon delete)
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: Colors.red,
        child: Row(
          children: const [
            Icon(Icons.delete, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text(
              'Hapus',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),

      // Card dengan GestureDetector untuk double tap
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: GestureDetector(
          // Double tap untuk edit
          onDoubleTap: onEdit,

          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: leading,
            title: title,
            subtitle: subtitle,
            trailing: trailing, // Gunakan parameter trailing
          ),
        ),
      ),
    );
  }
}

/// Contoh Pemakaian:
/// SwipeableListItem(
///   leading: CircleAvatar(
///     child: Icon(Icons.fastfood),
///   ),
///   title: Text('Nasi Goreng'),
///   subtitle: Text('Jumlah: 5'),
///   onEdit: () {
///     // Aksi edit
///   },
///   onDelete: () {
///     // Aksi hapus
///   },
///   deleteConfirmMessage: 'Yakin ingin menghapus makanan ini?',
/// )
