/// Model ShoppingList: Mendefinisikan struktur data untuk item dalam daftar belanja.
class ShoppingList {
  int? id;          // ID unik item dalam daftar belanja
  String item;      // Nama barang yang akan dibeli
  int quantity;     // Jumlah barang yang direncanakan
  double price;     // Estimasi harga barang

  // Constructor
  ShoppingList({
    this.id,
    required this.item,
    required this.quantity,
    this.price = 0,
  });

  factory ShoppingList.fromMap(Map<String, dynamic> map) => ShoppingList(
        id: map['id'] as int?,
        item: map['item'] as String,
        quantity: map['quantity'] as int,
        price: (map['price'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
      'item': item,
      'quantity': quantity,
      'price': price,
    };
    if (id != null) data['id'] = id;
    return data;
  }
}
