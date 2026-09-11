# IbuDaya — pindah dari mode lokal ke Supabase

Hari ini aplikasi berjalan **lokal**: semua data di satu file JSON di HP
(`LocalDatabase`). Lapisan di atasnya sudah disiapkan agar pindah ke Supabase
cukup dengan mengganti implementasi repository. **Laravel tidak diperlukan.**

```
UI → appStateProvider (+ selectors) → AppActions → Repository interfaces
                                                   ├── Local*Repository   (sekarang)
                                                   └── Supabase*Repository (nanti)
```

## Kenapa Supabase saja cukup

| Kebutuhan | Di Supabase |
|---|---|
| Login nomor HP + PIN | Supabase Auth (email sintetis `+62…@ibudaya.local` + PIN sebagai password, atau Phone OTP bila SMS provider tersedia) |
| Role anggota/admin, data per koperasi | Tabel `profiles` + Row Level Security |
| Admin menyetujui pinjaman, konfirmasi setoran, kapasitas hub | Fungsi Postgres `SECURITY DEFINER` di migrasi |
| Skor kredit dihitung server | Edge Function `submit-loan` (port dari `lib/core/logic/credit_signals.dart` + `rule_based_credit_scoring_engine.dart`) |
| Foto tagihan & atap | Supabase Storage bucket privat `photos/<user_id>/…` |
| Chat & notifikasi langsung | Supabase Realtime |

Laravel baru masuk akal jika nanti ada back-office berat (akuntansi koperasi,
integrasi bank/payment gateway, laporan RAT) dan tim lebih kuat di PHP.

## Langkah

1. Buat project Supabase (region Singapura).
2. Jalankan `supabase/migrations/20260911000000_init.sql`
   (`supabase db push` atau SQL editor).
3. Buat bucket Storage `photos` (privat) dengan policy: pemilik folder
   `auth.uid()` boleh baca/tulis; admin koperasi boleh baca.
4. Tambah dependency `supabase_flutter` (jelaskan alasannya di `pubspec.yaml`).
5. Isi URL dan anon key lewat `--dart-define`, **jangan pernah commit key**:
   ```
   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
   ```
6. Tulis `lib/core/repositories/supabase/*` yang mengimplementasikan interface
   di `lib/core/repositories/repositories.dart`:

   | Interface | Supabase |
   |---|---|
   | `AuthRepository.registerAdmin` | `auth.signUp` → `rpc('register_admin')` |
   | `AuthRepository.registerMember` | `rpc('find_cooperative')` → `auth.signUp` → `rpc('join_cooperative')` |
   | `AuthRepository.login` | `auth.signInWithPassword` |
   | `SnapshotRepository.load` | `select` per tabel (RLS menyaring otomatis) |
   | `EnergyRepository.*` | `insert/update/delete` langsung (RLS: hanya milik sendiri) |
   | `SolarRepository.book` / `setBookingStatus` | `rpc('book_slot')` / `rpc('set_booking_status')` |
   | `ArisanRepository.*` | `rpc('create_arisan_group' / 'submit_contribution' / 'review_payment' / 'record_payout' / 'post_quota' / 'respond_quota' / 'settle_quota' / 'cancel_quota')` |
   | `LoanRepository.submit` | `functions.invoke('submit-loan')` |
   | `LoanRepository.startReview/approve/reject/disburse` | `rpc('admin_loan_action')` |
   | `LoanRepository.markInstallmentPaid` / `cancel` | `rpc('mark_installment_paid')` / `rpc('cancel_loan')` |
   | `MessageRepository.directThread` | `rpc('direct_thread')` |
   | `CooperativeRepository.regenerateInviteCode` | `rpc('regenerate_invite_code')` |

7. Ganti override provider di `lib/app/bootstrap.dart` dan
   `lib/core/state/app_state.dart`. Tambahkan langganan Realtime yang memanggil
   `appStateProvider.notifier.refresh()`.
8. `PhotoStore` → unggah ke Storage; `ReceiptTextReader` tetap ML Kit di HP.

## Yang belum dibuat

- Edge Function `submit-loan` (skor dihitung ulang di server, lalu memanggil
  `private_insert_loan` dengan service role).
- Implementasi `Supabase*Repository`.
- Migrasi **belum dijalankan** ke project Supabase sungguhan. Sebelum dipakai
  anggota, uji minimal:
  - anggota A tidak bisa `select` catatan listrik anggota B;
  - anggota tidak bisa memanggil `admin_loan_action` / `review_payment`;
  - dua booking bersamaan tidak bisa melebihi kapasitas slot;
  - `private_insert_loan` tidak bisa dipanggil dari client.

## Catatan hukum

Pinjaman ke anggota dijalankan oleh koperasi, bukan oleh aplikasi. Koperasi
wajib berbadan hukum dan memiliki izin usaha simpan pinjam (KSP/USP) sesuai
aturan Kementerian Koperasi. Aplikasi hanya mencatat, menghitung, dan membantu
admin meninjau.
