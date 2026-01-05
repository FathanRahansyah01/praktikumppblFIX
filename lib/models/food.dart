/// Model Food: Mendefinisikan struktur data untuk persediaan makanan.
class Food {
  int? id;              // ID unik dari database (null jika baru)
  String name;          // Nama jenis makanan (misal: "Indomie", "Beras")
  int quantity;         // Jumlah stok yang tersedia
  String purchaseDate;  // Tanggal pembelian makanan (format: YYYY-MM-DD)
  double price;         // Harga beli per satuan stok

  // Constructor
  Food({
    this.id,
    required this.name,
    required this.quantity,
    required this.purchaseDate,
    this.price = 0,     // Default 0
  });

  factory Food.fromMap(Map<String, dynamic> map) => Food(
        id: map['id'] as int?,
        name: map['name'] as String,
        quantity: map['quantity'] as int,
        purchaseDate: map['purchaseDate'] as String,
        price: (map['price'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
      'name': name,
      'quantity': quantity,
      'purchaseDate': purchaseDate,
      'price': price,
    };
    if (id != null) data['id'] = id;
    return data;
  }
}
