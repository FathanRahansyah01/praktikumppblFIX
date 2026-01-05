/// Model Bill: Mendefinisikan struktur data untuk tagihan bulanan rutin.
class Bill {
  final int? id;        // ID unik data tagihan
  final String name;    // Nama tagihan (misal: "Listrik", "Internet")
  final double amount;  // Besaran biaya tagihan
  final String dueDate; // Tanggal jatuh tempo pembayaran (YYYY-MM-DD)

  // Constructor - cara membuat object Bill baru
  Bill({
    this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
  });

  final bool isPaid;

  // Method untuk mengubah object Bill jadi Map (untuk disimpan ke database)
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'amount': amount,
        'dueDate': dueDate,
        'isPaid': isPaid ? 1 : 0,
      };

  // Factory method untuk membuat object Bill dari Map (data dari database)
  factory Bill.fromMap(Map<String, dynamic> map) => Bill(
        id: map['id'] as int?,
        name: map['name'] as String,
        amount: (map['amount'] as num).toDouble(),
        dueDate: map['dueDate'] as String,
        isPaid: (map['isPaid'] as int? ?? 0) == 1,
      );
}
