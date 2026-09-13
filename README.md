# 🌿 IbuDaya — Platform Energi & Pembukuan Usaha Mikro

> **Bantu usaha Anda tumbuh lebih efisien dengan solusi energi yang terjangkau.**

IbuDaya adalah aplikasi mobile *offline-first* berbasis Flutter yang dirancang untuk memberdayakan pelaku usaha mikro (UMKM) melalui pengelolaan energi surya komunal, arisan kuota listrik, serta penilaian *Alternative Credit Scoring* berbasis riwayat energi (*Skor Kredit Energi*).

---

## 🚀 Fitur Utama

### ☀️ Communal Solar Hub
- **Reservasi Slot Daya**: Anggota dapat memesan dan mengalokasikan kapasitas energi surya milik koperasi sesuai kebutuhan usaha.
- **Monitoring Kapasitas Hub**: Visibilitas real-time penggunaan daya harian dan ketersediaan kuota listrik surya.

### ⚡ Arisan Kuota Energi
- **Berbagi Kuota Listrik**: Sistem arisan dan transfer kuota energi antar-anggota usaha mikro.
- **Pasar Kuota Usaha**: Fasilitas pertukaran dan pemberian hibah kuota daya harian bagi anggota yang membutuhkan.

### 📊 Skor Kredit Energi (Alternative Credit Scoring)
- **Penilaian Transparan**: Sistem pemeringkatan kredit berbasis aturan (*rule-based engine*) yang terukur dan deterministik (Bukan Black-box AI/ML).
- **4 Pilar Evaluasi**:
  1. *Stabilitas Penggunaan Daya* (35 poin)
  2. *Histori Pembayaran Tepat Waktu* (30 poin)
  3. *Aktivitas & Peralatan Usaha* (20 poin)
  4. *Partisipasi Koperasi & Arisan* (15 poin)
- **Skor Kanonis Ibu Clara**: Total Skor `82/100` (*Baik Sekali*).

### 🌐 Multi-Language System (Bilingual)
- **Bahasa Indonesia & English**: Pengalihan bahasa secara instan di seluruh layar dan modul tanpa perlu *re-login*.
- **Persistensi Preferensi**: Pilihan bahasa tersimpan secara otomatis di perangkat lokal.

### 📸 Pemindai Struk PLN & Estimator Surya
- **OCR Penggunaan Listrik**: Membaca kWh dan nominal tagihan PLN secara *on-device* offline.
- **Estimasi Potensi Atap**: Menghitung kapasitas panel surya dan penghematan daya usaha berdasarkan ukuran atap.

### 📲 Offline-First & Mode Demo
- **Bekerja 100% Offline**: Data tersimpan aman di penyimpanan lokal tanpa bergantung pada koneksi internet.
- **Mode Demo Interaktif**: Tombol *Coba dengan Data Contoh* untuk menguji peran Anggota maupun Admin Koperasi secara langsung.

---

## 🛠️ Teknologi & Arsitektur

- **Framework**: [Flutter](https://flutter.dev) (Dart SDK ^3.8)
- **Design System**: Material 3 dengan Token Desain Kustom IbuDaya (*Growth Green & Warm Cream*)
- **State Management**: [Riverpod](https://riverpod.dev) (`AsyncNotifierProvider`, `Provider`)
- **Navigasi**: [GoRouter](https://pub.dev/packages/go_router)
- **Arsitektur**: *Feature-First Architecture* (`UI` → `Provider/Controller` → `Repository` → `Data Source`)
- **Penyimpanan Lokal**: Offline-First JSON Engine

---

## 📱 Alur Kerja & Peran Pengguna

### 👩‍💼 Peran Anggota Koperasi (*Member*)
- Pencatatan & analisis energi bulanan.
- Pengajuan pembiayaan alat usaha & pemantauan jadwal cicilan.
- Pemesanan slot *Solar Hub* dan partisipasi *Arisan Kuota*.
- Pengaturan profil & preferensi bahasa.

### 🏢 Peran Pengurus Koperasi (*Admin*)
- Dasbor pengawasan penggunaan daya seluruh anggota.
- Peninjauan & persetujuan pengajuan pembiayaan alat usaha.
- Verifikasi pembayaran cicilan & iuran arisan.
- Pengaturan kapasitas *Solar Hub* dan pengumuman koperasi.

---

## ⚡ Memulai Pengembangan

### Prasyarat
- Flutter SDK (v3.22.0 atau lebih baru)
- Dart SDK (v3.8.0 atau lebih baru)

### Langkah-langkah

1. **Clone Repository**:
   ```bash
   git clone https://github.com/MuhammadReizan/IbuDayaa.git
   cd IbuDayaa
   ```

2. **Install Dependensi**:
   ```bash
   flutter pub get
   ```

3. **Jalankan Aplikasi**:
   ```bash
   flutter run
   ```

4. **Jalankan Pengujian Unit & Widget**:
   ```bash
   flutter test
   ```

---

## 📜 Kejujuran Produk (Product Honesty)

- **Skor Kredit Energi**: Penilaian kredit saat ini menggunakan *rule-based engine* deterministik transparan, bukan model AI/ML terprediksi.
- **Simulasi Pembiayaan**: Fitur pengajuan pembiayaan pada versi MVP ini merupakan mode simulasi edukatif untuk demonstrasi kompetisi.
- **Privasi Data**: Seluruh data simulasi disimpan secara lokal pada perangkat pengguna (*Offline-First*).

---

## 📄 Lisensi

Proyek ini dikembangkan untuk kompetisi inovasi energi dan UMKM. Hak Cipta © 2026 Tim IbuDaya.
