/// Model ActivityReminder: Mendefinisikan struktur data untuk pengingat kegiatan kost.
class ActivityReminder {
  int? id;        // ID unik pengingat
  String name;    // Nama atau deskripsi kegiatan (misal: "Kerja Kelompok")
  String time;    // Waktu pelaksanaan kegiatan (HH:mm)

  // Constructor - cara membuat object ActivityReminder baru
  ActivityReminder({
    this.id,              // ID opsional
    required this.name,   // Nama kegiatan wajib diisi
    required this.time,   // Waktu wajib diisi
  });

  // Factory method untuk membuat object ActivityReminder dari Map (data dari database)
  factory ActivityReminder.fromMap(Map<String, dynamic> map) => ActivityReminder(
        id: map['id'] as int?,          // Ambil ID
        name: map['name'] as String,    // Ambil nama kegiatan
        time: map['time'] as String,    // Ambil waktu
      );

  // Method untuk mengubah object ActivityReminder jadi Map (untuk disimpan ke database)
  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
      'name': name,   // Masukkan nama kegiatan
      'time': time,   // Masukkan waktu
    };
    
    // Kalau ID ada, masukkan juga
    if (id != null) data['id'] = id;
    
    return data;
  }
}
