/// Model DailyNeed: Mendefinisikan struktur data untuk kebutuhan harian yang rutin dibeli.
class DailyNeed {
  int? id;          // ID unik data kebutuhan
  String name;      // Nama barang kebutuhan (misal: "Sabun", "Pasta Gigi")
  int quantity;     // Jumlah barang yang dibeli/dibutuhkan
  double price;     // Harga per item barang

  // Constructor
  DailyNeed({
    this.id,
    required this.name,
    required this.quantity,
    this.price = 0,
  });

  factory DailyNeed.fromMap(Map<String, dynamic> map) => DailyNeed(
        id: map['id'] as int?,
        name: map['name'] as String,
        quantity: map['quantity'] as int,
        price: (map['price'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
      'name': name,
      'quantity': quantity,
      'price': price,
    };
    if (id != null) data['id'] = id;
    return data;
  }
}
