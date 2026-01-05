/// Model FinanceNote: Representasi data catatan keuangan (transaksi).
/// Digunakan untuk menyimpan informasi uang masuk/keluar.
class FinanceNote {
  final int? id;             // ID unik transaksi (null untuk data baru)
  final String note;         // Keterangan transaksi
  final double amount;       // Nominal transaksi
  final String type;         // Tipe: 'income' (masuk) atau 'expense' (keluar)
  final String source;       // Sumber: 'makanan', 'laundry', 'tagihan', dll
  final DateTime timestamp;  // Waktu transaksi terjadi

  FinanceNote({
    this.id,
    required this.note,
    required this.amount,
    required this.type,
    required this.source,
    required this.timestamp,
  });

  // Konversi dari Map (data database) ke object FinanceNote
  factory FinanceNote.fromMap(Map<String, dynamic> map) {
    return FinanceNote(
      id: map['id'],
      note: map['note'],
      amount: (map['amount'] as num).toDouble(),
      type: map['type'],
      source: map['source'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  // Konversi dari object FinanceNote ke Map (untuk simpan di database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'note': note,
      'amount': amount,
      'type': type,
      'source': source,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
