# Custom Widgets

Folder ini berisi custom widget yang dapat digunakan ulang di berbagai halaman aplikasi.

## 📋 Ketentuan Custom Widget

✅ Widget yang kita bangun sendiri  
✅ Memiliki fungsi dan tampilan sesuai keinginan kita  
✅ Dapat digunakan ulang pada halaman-halaman lain  
✅ Menyederhanakan kode  
✅ Memudahkan perawatan kode  
✅ Hanya **StatelessWidget** atau **StatefulWidget** biasa  

---

## 🧩 Daftar Widget

### 1. CustomButton
Button yang dapat dikustomisasi dengan mudah.

**Fitur:**
- Support icon
- Loading state
- Custom color
- Custom width

**Contoh Penggunaan:**
```dart
import 'package:tubes_ppbl/widgets/widgets.dart';

CustomButton(
  text: 'Simpan Data',
  icon: Icons.save,
  onPressed: () {
    // Aksi saat button ditekan
  },
)

// Dengan loading state
CustomButton(
  text: 'Menyimpan...',
  isLoading: true,
)

// Custom color
CustomButton(
  text: 'Hapus',
  backgroundColor: Colors.red,
  icon: Icons.delete,
  onPressed: () {},
)
```

---

### 2. CustomCard
Card dengan styling konsisten untuk menampilkan konten.

**Fitur:**
- Custom padding
- Custom background color
- Support onTap
- Custom elevation

**Contoh Penggunaan:**
```dart
CustomCard(
  child: Column(
    children: [
      Text('Judul Card'),
      Text('Konten di dalam card'),
    ],
  ),
  onTap: () {
    // Aksi saat card ditekan
  },
)
```

---

### 3. CustomInput
Input field dengan styling konsisten untuk form.

**Fitur:**
- Label dan hint
- Prefix & suffix icon
- Validator
- Multi line support
- Enable/disable state

**Contoh Penggunaan:**
```dart
CustomInput(
  label: 'Nama',
  hint: 'Masukkan nama Anda',
  controller: nameController,
  prefixIcon: Icons.person,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    return null;
  },
)

// Password field
CustomInput(
  label: 'Password',
  obscureText: true,
  prefixIcon: Icons.lock,
  suffixIcon: Icons.visibility,
  onSuffixIconPressed: () {
    // Toggle visibility
  },
)

// Multi line
CustomInput(
  label: 'Catatan',
  maxLines: 4,
  hint: 'Tulis catatan di sini...',
)
```

---

### 4. MenuCard
Card untuk menu navigasi dengan icon dan deskripsi.

**Fitur:**
- Icon dengan background lingkaran
- Title dan subtitle
- Custom icon color
- Tap handler

**Contoh Penggunaan:**
```dart
MenuCard(
  title: 'Makanan',
  subtitle: 'Kelola daftar makanan',
  icon: Icons.restaurant,
  iconColor: Colors.orange,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FoodScreen()),
    );
  },
)
```

---

### 5. EmptyState
Widget untuk menampilkan pesan ketika data kosong.

**Fitur:**
- Icon dengan styling
- Title dan message
- Optional action button

**Contoh Penggunaan:**
```dart
EmptyState(
  icon: Icons.inbox_outlined,
  title: 'Belum Ada Data',
  message: 'Anda belum memiliki data makanan.\nTambahkan data baru untuk memulai.',
  actionText: 'Tambah Data',
  onActionPressed: () {
    // Aksi untuk menambah data
  },
)

// Tanpa button
EmptyState(
  icon: Icons.search_off,
  title: 'Tidak Ditemukan',
  message: 'Data yang Anda cari tidak ditemukan.',
)
```

---

## 📦 Import Widget

**Import satu widget:**
```dart
import 'package:tubes_ppbl/widgets/custom_button.dart';
```

**Import semua widget sekaligus:**
```dart
import 'package:tubes_ppbl/widgets/widgets.dart';
```

---

## ✨ Keuntungan Menggunakan Custom Widget

1. **Konsistensi** - Semua tampilan menggunakan style yang sama
2. **DRY (Don't Repeat Yourself)** - Tidak perlu menulis kode yang sama berulang kali
3. **Mudah Maintenance** - Ubah di satu tempat, semua halaman ikut berubah
4. **Clean Code** - Kode lebih rapi dan mudah dibaca
5. **Reusable** - Bisa digunakan di berbagai halaman

---

## 🎨 Sesuai dengan Theme

Semua custom widget sudah menggunakan:
- ✅ Font Poppins (dari ThemeData)
- ✅ Warna biru untuk button
- ✅ Background putih
- ✅ Styling yang konsisten

---

## 📝 Tips Penggunaan

1. Gunakan `CustomButton` untuk semua tombol di aplikasi
2. Gunakan `CustomInput` untuk semua form input
3. Gunakan `MenuCard` untuk menu navigasi
4. Gunakan `EmptyState` saat data kosong
5. Gunakan `CustomCard` untuk menampilkan konten dalam card

Dengan menggunakan custom widget ini, kode aplikasi akan lebih rapi, konsisten, dan mudah di-maintain! 🚀
