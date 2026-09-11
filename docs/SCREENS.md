# IbuDaya v2 — Inventaris Layar & Alur

Sumber kebenaran rute: `lib/core/paths.dart` dan `lib/app/router.dart`
(`guard()` mengatur akses per role; diuji di `test/unit/router_guard_test.dart`).

## Autentikasi (belum masuk)

| Rute | Layar | Isi |
|---|---|---|
| `/welcome` | WelcomeScreen | Logo, 3 manfaat, Masuk, Daftar, "Coba dengan data contoh" |
| `/login` | LoginScreen | Nomor HP → PIN pad 6 angka, kunci 60 detik setelah 5× salah, Lupa PIN |
| `/register` | RegisterChoiceScreen | Pilih: Anggota koperasi / Admin koperasi |
| `/register/member` | RegisterMemberScreen | 1 Kode koperasi (dicek) → 2 Data diri & usaha → 3 Buat PIN |
| `/register/admin` | RegisterAdminScreen | 1 Data pengurus → 2 Nama koperasi → 3 Buat PIN |

## Anggota — tab bawah: Beranda · Solar Hub · Pesan · Profil

| Rute | Layar (Figma) | Isi |
|---|---|---|
| `/m/home` | Home | Sapaan, notifikasi, kartu tagihan bulan ini + Scan/Analisis, 8 pintasan, Status Penggunaan Daya, Skor Kredit, pinjaman aktif, dampak Solar Hub |
| `/scan` | Scan Tagihan | Kamera dengan bingkai, lampu, galeri, isi manual; OCR ML Kit di HP |
| `/energy/add` | Scan Tagihan (hasil) | Foto + status terbaca, jenis tagihan/token, bulan, kWh, total, cek harga per kWh |
| `/energy` | — | Grafik 6 bulan, daftar catatan, hapus |
| `/energy/analysis` | Analisis Energi | Pemakaian & perubahan, lonjakan, tren, rincian per alat, saran → booking hub, cara hitung |
| `/appliances`, `/appliances/edit` | — | Daftar alat & biaya; form jenis, watt, jam/hari, hari/minggu |
| `/m/solar` | Solar Hub | Kapasitas hari ini, booking, kuota bulan ini, slot hari ini, jadwal saya, Radar Atap |
| `/booking` | Solar Hub Booking | Tanggal (15 hari), alat, jam dengan sisa kapasitas & "Paling lega", ringkasan → berhasil |
| `/bookings` | — | Terjadwal/Riwayat, batalkan, "Sudah dipakai" |
| `/roof` | Radar Atap | Foto atap → ukuran, arah, bayangan → hasil bernomor (produksi, hemat, biaya & balik modal) + asumsi |
| `/arisan` | Arisan Energi | Total arisan, giliran, setor iuran (menunggu konfirmasi admin), status anggota, riwayat, chat grup |
| `/quota` | Perdagangan Energi | Saldo kuota, Bagikan/Butuh, perlu keputusan, penawaran anggota (Minta/Beri), riwayat |
| `/quota/new` | Bagikan Kuota → Penawaran Berhasil | kWh, waktu, pesan → layar berhasil |
| `/score` | Skor Kredit Energi | Gauge, perubahan vs bulan lalu, dukungan plafon, 4 faktor + perubahan poin, penjelasan |
| `/loan/apply` | Ajukan Pembiayaan | Nominal (slider sampai plafon), tenor, keperluan, rincian cicilan, persetujuan → terkirim |
| `/loans`, `/loans/:id` | — | Plafon & kebijakan, daftar pengajuan; detail status, skor saat mengajukan, cicilan, riwayat |
| `/m/messages`, `/thread/:id` | Pesan | Admin (support), pengumuman, grup arisan, anggota; chat |
| `/m/profile` + `/profile/edit`, `/profile/pin`, `/about` | Profil | Ringkasan, menu usaha & akun, tarif PLN, ganti PIN, tentang & hapus data |
| `/notifications` | — | Notifikasi dengan tautan ke layar terkait |

## Admin — tab bawah: Dasbor · Pengajuan · Anggota · Lainnya

| Rute | Isi |
|---|---|
| `/a/home` | Kode undangan (salin pesan), statistik, cicilan terlambat, checklist penyiapan, Solar Hub hari ini, antrean pengajuan & setoran |
| `/a/loans`, `/a/loans/:id` | Filter Menunggu/Berjalan/Selesai; review: Mulai review, Setujui (catatan), Tolak (alasan wajib), Catat pencairan, terima cicilan |
| `/a/members`, `/a/members/:id` | Cari anggota, skor & pinjaman aktif; detail skor, listrik, arisan, pinjaman, kirim pesan |
| `/a/more` | Menu kelola koperasi & akun |
| `/a/payments` | Konfirmasi / tolak setoran arisan |
| `/a/arisan`, `/a/arisan/new` | Grup, progres lunas, catat pencairan giliran; buat grup dengan urutan giliran |
| `/a/hub` | Nama, lokasi, kapasitas harian (+ kalkulator kWp), kuota anggota, slot jam, konfirmasi pemakaian |
| `/a/announce` | Kirim pengumuman ke semua anggota |
| `/a/settings` | Kode undangan baru, plafon, jasa, skor minimum, tenor, biaya panel per kWp |
| `/a/messages` | Semua percakapan admin |

## Alur utama (diuji di `test/widget/app_flow_test.dart`)

1. Admin daftar → dapat kode → anggota daftar dengan kode.
2. Anggota scan tagihan → periksa angka → simpan → analisis.
3. Anggota booking Solar Hub → datang → tandai sudah dipakai.
4. Anggota setor iuran → admin konfirmasi → skor naik.
5. Anggota ajukan pinjaman → admin review → setujui → catat pencairan → terima cicilan → lunas.
