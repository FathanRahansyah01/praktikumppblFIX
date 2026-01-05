/// Model Expense: Mendefinisikan struktur data untuk catatan pengeluaran harian.
class Expense {
  final int? id;              // ID unik catatan pengeluaran
  final double amount;        // Jumlah uang yang dikeluarkan
  final String category;
  final String description;
  final String date;

  // Constructor - cara membuat object Expense baru
  Expense({
    this.id,
    required this.amount,
    required this.category,
    this.description = '',
    required this.date,
  });

  // Method untuk mengubah object Expense jadi Map (untuk disimpan ke database)
  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'category': category,
        'description': description,
        'date': date,
      };

  // Factory method untuk membuat object Expense dari Map (data dari database)
  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
        id: map['id'] as int?,
        amount: (map['amount'] as num).toDouble(),
        category: map['category'] as String,
        description: map['description'] as String? ?? '',
        date: map['date'] as String,
      );
}
