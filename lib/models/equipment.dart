/// Model Equipment: Mendefinisikan struktur data untuk peralatan atau barang di kost.
class Equipment {
  int? id;            // ID unik dari database
  String name;        // Nama barang (misal: "Kipas Angin", "Bantal")
  String condition;   // Status kondisi barang (misal: "Bagus", "Rusak")

  // Constructor - cara membuat object Equipment baru
  Equipment({
    this.id,
    required this.name,
    required this.condition,
    this.price = 0,
  });

  double price;

  // Factory method untuk membuat object Equipment dari Map (data dari database)
  factory Equipment.fromMap(Map<String, dynamic> map) => Equipment(
        id: map['id'] as int?,
        name: map['name'] as String,
        condition: map['condition'] as String,
        price: (map['price'] as num?)?.toDouble() ?? 0,
      );

  // Method untuk mengubah object Equipment jadi Map (untuk disimpan ke database)
  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
      'name': name,
      'condition': condition,
      'price': price,
    };
    
    // Kalau ID ada, masukkan juga
    if (id != null) data['id'] = id;
    
    return data;
  }
}
