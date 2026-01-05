import 'package:flutter/material.dart';

/// Widget CustomCard: Kontainer berbentuk kartu dengan styling yang seragam.
/// Dapat mendeteksi ketukan (tap) dan mendukung elevasi kustom.
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final double? elevation;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.onTap,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: elevation ?? 2,
      color: backgroundColor ?? Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: card,
      );
    }

    return card;
  }
}

/// Contoh Pemakaian:
/// CustomCard(
///   child: Column(
///     children: [
///       Text('Judul'),
///       Text('Konten'),
///     ],
///   ),
///   onTap: () {
///     // Aksi saat card ditekan
///   },
/// )
