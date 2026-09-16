# IbuDaya — pindah dari mode lokal ke Supabase

**STATUS: dibangun, belum dijalankan ke project sungguhan.** Semua kode di
bawah sudah ada (`lib/core/repositories/supabase/*`, `bootstrap.dart`,
`supabase/migrations/20260911000000_init.sql`) dan lolos `flutter analyze` +
`flutter test`. Yang belum bisa dilakukan dari sandbox pengembangan ini:
menjalankan migrasi SQL ke project Supabase sungguhan (butuh password
database atau personal access token, bukan `anon`/`service_role` key) dan
menguji end-to-end dengan koneksi jaringan nyata. Ikuti langkah di bawah.

```
UI → appStateProvider (+ selectors) → AppActions → Repository interfaces
                                                   ├── Local*Repository    (dipakai test suite)
                                                   └── Supabase*Repository (dipakai app sungguhan)
```

`lib/app/bootstrap.dart` adalah satu-satunya tempat yang menentukan mana yang
dipakai: ia meng-override 9 provider repository di `app_state.dart` dengan
implementasi Supabase. `Local*Repository` **sengaja tidak dihapus** — test
suite (`test/unit/repositories/workflow_test.dart`,
`test/widget/app_flow_test.dart`, dll., 152 test) meng-override
`localDatabaseProvider` dan bergantung padanya; menghapusnya akan
menggagalkan semua test itu tanpa manfaat apa pun untuk app sungguhan, yang
sekarang murni jalan di Supabase begitu `bootstrap()` dipanggil.

## Langkah menjalankan

1. **Nonaktifkan "Confirm email"** di dashboard Supabase: Authentication →
   Providers → Email → matikan "Confirm email". Login memakai alamat
   sintetis `<nomor-hp>@ibudaya.local` (lihat `SupabaseAuthRepository`) yang
   tidak bisa menerima email konfirmasi.
2. **Jalankan migrasi.** Buka SQL Editor di dashboard Supabase project kamu,
   tempel seluruh isi `supabase/migrations/20260911000000_init.sql`, jalankan
   sekali. (CLI `supabase db push` juga bisa dipakai kalau kamu install CLI-nya
   dan sudah `supabase login` — tidak tersedia dari sandbox ini.)
3. **Buat bucket Storage** `photos` (privat) — belum dipakai oleh kode saat
   ini (lihat "Yang belum dibuat" di bawah), tapi siapkan lebih awal kalau mau
   lanjut ke situ.
4. **Jalankan app** dengan URL + publishable key lewat `--dart-define`
   (jangan pernah commit key ke repo):
   ```
   flutter run \
     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
     --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx
   ```
   `lib/core/config/supabase_config.dart` membaca dua variabel ini.
   `bootstrap()` melempar error jelas kalau salah satu kosong.
   **`SUPABASE_SECRET_KEY` tidak pernah dipakai di sisi app** — key itu
   service-role, membypass RLS, dan kalau ikut ke APK siapa pun bisa
   membongkarnya dan dapat akses admin penuh ke database. Kalau key itu
   pernah tertempel di tempat yang tidak aman (chat, dokumen publik, dst.),
   regenerasi dari Settings → API di dashboard.
5. Uji minimal sebelum dipakai anggota sungguhan (checklist dari versi
   dokumen sebelumnya, masih berlaku):
   - anggota A tidak bisa `select` catatan listrik anggota B;
   - anggota tidak bisa memanggil `admin_loan_action` / `review_payment`;
   - dua booking bersamaan tidak bisa melebihi kapasitas slot;
   - `private_insert_loan` tidak bisa dipanggil langsung dari client (hanya
     lewat `submit_loan`, yang menghitung ulang skor di server).

## Pemetaan interface → Supabase (yang sudah dibangun)

| Interface | Implementasi | Supabase |
|---|---|---|
| `AuthRepository.*` | `SupabaseAuthRepository` | `auth.signUp`/`signInWithPassword` (email sintetis `<hp>@ibudaya.local` + PIN sebagai password) → `rpc('register_admin'/'join_cooperative')` |
| `SnapshotRepository.load` | `SupabaseSnapshotRepository` | `select()` per tabel — RLS yang menyaring, bukan kode Dart |
| `EnergyRepository.*` | `SupabaseEnergyRepository` | insert/update/delete langsung (RLS: `user_id = auth.uid()`) |
| `ScoreRepository.recordMonthlySnapshot` | `SupabaseEnergyRepository` | insert/update langsung ke `score_snapshots` (butuh policy `scores_write`, ditambahkan di migrasi) |
| `SolarRepository.updateHub/addSlot/removeSlot` | `SupabaseSolarRepository` | table write langsung (RLS admin) |
| `SolarRepository.book/setBookingStatus` | `SupabaseSolarRepository` | `rpc('book_slot'/'set_booking_status')` |
| `ArisanRepository.*` | `SupabaseArisanRepository` | `rpc('create_arisan_group'/'submit_contribution'/'review_payment'/'record_payout'/'post_quota'/'respond_quota'/'settle_quota'/'cancel_quota')` |
| `LoanRepository.submit` | `SupabaseLoanRepository` | `rpc('submit_loan')` — **bukan Edge Function**, lihat catatan di bawah |
| `LoanRepository.startReview/approve/reject/disburse` | `SupabaseLoanRepository` | `rpc('admin_loan_action')` |
| `LoanRepository.markInstallmentPaid` / `cancel` | `SupabaseLoanRepository` | `rpc('mark_installment_paid'/'cancel_loan')` |
| `MessageRepository.*` | `SupabaseMessageRepository` | table write + `rpc('direct_thread')` |
| `CooperativeRepository.*` | `SupabaseMessageRepository` | table write (admin RLS) + `rpc('regenerate_invite_code')` |

### Kenapa `submit_loan` adalah fungsi SQL, bukan Edge Function

Versi dokumen ini sebelumnya merencanakan Edge Function `submit-loan` (Deno/
TypeScript) yang menghitung ulang skor lalu memanggil `private_insert_loan`
dengan service role. Setelah dilihat lebih jauh: seluruh data yang dibutuhkan
skor (catatan listrik, alat usaha, booking, arisan, cicilan, kuota) sudah ada
di Postgres, jadi perhitungannya bisa dilakukan langsung sebagai fungsi
`security definer` di SQL — `public.submit_loan(p_amount, p_purpose, p_tenor,
p_note)` di `supabase/migrations/20260911000000_init.sql`. Ini port langsung
dari `lib/core/logic/credit_signals.dart` +
`rule_based_credit_scoring_engine.dart` + `loan_math.dart` (rumus konsistensi
pemakaian, riwayat pembayaran, aktivitas usaha, partisipasi komunitas, plafon
per band). Keamanannya identik (client tidak bisa mengarang skornya sendiri —
`private_insert_loan` tetap direvoke dari client), tapi tidak perlu
`supabase functions deploy` terpisah. **Kalau skor server dan skor yang
ditampilkan di layar (`RuleBasedCreditScoringEngine`, dihitung ulang di
Dart) pernah berbeda, keduanya harus disinkronkan bersamaan** — keduanya
mengimplementasikan rumus yang sama secara independen.

## Perbaikan yang ditemukan saat migrasi ini dibangun

- `solar_hubs` belum punya kolom `weather_adm4_code` (fitur cuaca BMKG) —
  ditambahkan.
- Tidak ada RLS write-policy untuk `score_snapshots` sama sekali — tanpanya
  `recordMonthlySnapshot` selalu gagal (RLS default-deny). Ditambahkan
  `scores_write`.
- `loan_flat_monthly_rate_pct` dibatasi `check (... between 0 and 5)` di SQL
  padahal validasi UI (`CooperativeRepository.updateSettings`) mengizinkan
  0–10%. Batas SQL dilebarkan ke 0–10 supaya konsisten dengan yang sudah
  divalidasi di app.
- `lib/core/db/row.dart`: `rInt`/`rDbl`/dst. sebelumnya melakukan
  `(r[k] as num?)` — PostgREST mengembalikan kolom `numeric` sebagai **string
  JSON**, bukan number, jadi cast itu akan melempar `TypeError` untuk hampir
  semua kolom uang/kWh begitu datanya datang dari Supabase. Diperbaiki agar
  menerima keduanya.

## Yang belum dibuat / sengaja di luar cakupan migrasi ini

- **"Coba dengan data contoh"** di welcome screen masih memanggil
  `SampleSeeder` yang menulis langsung ke `LocalDatabase` — tombol itu hanya
  akan berfungsi kalau app tetap jalan di mode lokal. Belum ada versi
  Supabase-nya. Alasan tidak dikerjakan sekaligus: mem-porting seeder ini
  akan membuat 5 akun dengan PIN tetap (`147258`) di project Supabase
  **sungguhan** kamu — begitu satu orang pernah menekannya, akun itu ada
  selamanya untuk siapa pun yang tahu PIN-nya (bukan sandbox per-perangkat
  seperti mode lokal). Ini keputusan produk (apakah demo publik dengan
  kredensial tetap boleh ada di backend sungguhan), bukan keputusan teknis —
  beri tahu saya kalau mau tetap dibuatkan.
- **Upload foto ke Storage.** `photo_path` masih disimpan apa adanya (path
  file lokal di HP), sama seperti mode lokal — belum ada upload ke bucket
  `photos`. Tidak mengubah alur yang ada (path lokal juga tidak portable di
  mode lokal), tapi berarti admin di perangkat lain tidak bisa melihat foto
  tagihan/atap anggota lain sampai ini dibangun.
- **Realtime.** Chat dan notifikasi memakai `AppStateController.refresh()`
  (tarik manual) seperti sekarang; migrasi tidak menambahkan langganan
  `supabase_realtime` otomatis meskipun tabelnya sudah masuk publication di
  SQL. Menambahkannya adalah perubahan aditif kecil, bukan pekerjaan besar,
  kalau nanti dibutuhkan.

## Catatan hukum

Pinjaman ke anggota dijalankan oleh koperasi, bukan oleh aplikasi. Koperasi
wajib berbadan hukum dan memiliki izin usaha simpan pinjam (KSP/USP) sesuai
aturan Kementerian Koperasi. Aplikasi hanya mencatat, menghitung, dan membantu
admin meninjau.
