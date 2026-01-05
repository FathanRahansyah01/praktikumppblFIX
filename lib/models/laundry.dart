/// Model Laundry: Mendefinisikan struktur data untuk pencatatan laundry.
class Laundry {
  int? id;          // ID unik transaksi laundry
  String type;
  int quantity;
  String status;

  // Constructor
  Laundry({
    this.id,
    required this.item,
    required this.type,
    required this.quantity,
    required this.status,
    this.cost = 0,
  });

  String item;
  double cost;

  factory Laundry.fromMap(Map<String, dynamic> map) => Laundry(
        id: map['id'] as int?,
        item: map['item'] as String? ?? '',
        type: map['type'] as String,
        quantity: map['quantity'] as int,
        status: map['status'] as String,
        cost: (map['cost'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
      'item': item,
      'type': type,
      'quantity': quantity,
      'status': status,
      'cost': cost,
    };
    if (id != null) data['id'] = id;
    return data;
  }
}
