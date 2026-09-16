import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/credentials.dart';
import '../../errors.dart';
import '../../models/models.dart';
import '../repositories.dart';
import 'supabase_base.dart';

/// Phone + 6-digit PIN over Supabase Auth.
///
/// Supabase Auth speaks email/password, not "phone + PIN", so each account
/// signs up with a synthetic address derived from the E.164 phone
/// (`6281234567890@ibudaya.local`) and the PIN as the password. The phone
/// number itself is never used to send anything — it only identifies the
/// account and is stored on `profiles` for display.
///
/// Requires "Confirm email" turned OFF in the Supabase project's Auth
/// settings (Authentication → Providers → Email), since `@ibudaya.local`
/// addresses cannot receive a confirmation link.
class SupabaseAuthRepository extends SupabaseRepo implements AuthRepository {
  SupabaseAuthRepository(super.client);

  String _syntheticEmail(String e164Phone) =>
      '${e164Phone.replaceFirst('+', '')}@ibudaya.local';

  String _phone(String input) {
    final p = normalizeIndonesianPhone(input);
    if (p == null) {
      throw const AppException(
        'Nomor HP tidak valid. Contoh yang benar: 0812-3456-7890.',
      );
    }
    return p;
  }

  void _checkPin(String pin) {
    if (!isValidPin(pin)) throw const AppException('PIN harus 6 angka.');
    if (isWeakPin(pin)) {
      throw const AppException(
        'PIN terlalu mudah ditebak. Hindari angka yang sama semua atau '
        'berurutan.',
      );
    }
  }

  void _required(String value, String label) {
    if (value.trim().isEmpty) throw AppException('$label wajib diisi.');
  }

  Future<Profile> _fetchProfile(String userId) async {
    final row = await table('profiles').select().eq('id', userId).maybeSingle();
    if (row == null) throw const AppException('Akun tidak ditemukan.');
    return Profile.fromRow(row);
  }

  @override
  Future<Profile?> restoreSession() => guard(() async {
    final session = client.auth.currentSession;
    if (session == null) return null;
    try {
      return await _fetchProfile(session.user.id);
    } on AppException {
      // A signed-in auth user with no profile row (sign-up succeeded but the
      // register_admin/join_cooperative call never finished) has nothing to
      // restore into.
      return null;
    }
  });

  @override
  Future<Cooperative?> findCooperativeByInviteCode(String code) =>
      guard(() async {
        final trimmed = code.trim();
        if (trimmed.isEmpty) return null;
        final rows = await client.rpc(
          'find_cooperative',
          params: {'p_invite_code': trimmed},
        );
        if (rows is! List || rows.isEmpty) return null;
        final r = rows.first as Map<String, dynamic>;
        // find_cooperative only exposes what an unauthenticated visitor may see
        // (id/name/city) — everything else keeps the model's own defaults until
        // the member actually joins and reads the full row.
        return Cooperative(
          id: r['id'] as String,
          name: r['name'] as String? ?? '',
          city: r['city'] as String? ?? '',
          inviteCode: trimmed.toUpperCase(),
          createdBy: '',
          createdAt: DateTime.now(),
        );
      });

  @override
  Future<Profile> registerAdmin({
    required String phone,
    required String pin,
    required String fullName,
    required String city,
    required String cooperativeName,
  }) => guard(() async {
    final p = _phone(phone);
    _checkPin(pin);
    _required(fullName, 'Nama');
    _required(cooperativeName, 'Nama koperasi');
    _required(city, 'Kota');

    await client.auth.signUp(email: _syntheticEmail(p), password: pin);
    final uid = client.auth.currentUser?.id;
    if (uid == null) {
      throw const AppException('Pendaftaran gagal. Coba lagi.');
    }
    final row = await client.rpc(
      'register_admin',
      params: {
        'p_phone': p,
        'p_full_name': fullName.trim(),
        'p_city': city.trim(),
        'p_coop_name': cooperativeName.trim(),
      },
    );
    return Profile.fromRow(row as Map<String, dynamic>);
  });

  @override
  Future<Profile> registerMember({
    required String phone,
    required String pin,
    required String fullName,
    required String businessName,
    required String city,
    required String inviteCode,
  }) => guard(() async {
    final p = _phone(phone);
    _checkPin(pin);
    _required(fullName, 'Nama');
    _required(businessName, 'Nama usaha');
    _required(city, 'Kota');

    await client.auth.signUp(email: _syntheticEmail(p), password: pin);
    final uid = client.auth.currentUser?.id;
    if (uid == null) {
      throw const AppException('Pendaftaran gagal. Coba lagi.');
    }
    final row = await client.rpc(
      'join_cooperative',
      params: {
        'p_invite_code': inviteCode.trim(),
        'p_phone': p,
        'p_full_name': fullName.trim(),
        'p_business_name': businessName.trim(),
        'p_city': city.trim(),
      },
    );
    return Profile.fromRow(row as Map<String, dynamic>);
  });

  @override
  Future<Profile> login({required String phone, required String pin}) => guard(
    () async {
      final p = _phone(phone);
      try {
        await client.auth.signInWithPassword(
          email: _syntheticEmail(p),
          password: pin,
        );
      } on AuthException {
        // Supabase does not distinguish "no such account" from "wrong
        // password" in its error — neither should this message, so a wrong
        // guess cannot be used to find out which phone numbers are registered.
        throw const AppException('Nomor HP atau PIN salah.');
      }
      final uid = client.auth.currentUser?.id;
      if (uid == null) throw const AppException('Nomor HP atau PIN salah.');
      return _fetchProfile(uid);
    },
  );

  @override
  Future<void> logout() => guard(() => client.auth.signOut());

  @override
  Future<void> changePin({
    required String userId,
    required String currentPin,
    required String newPin,
  }) => guard(() async {
    _checkPin(newPin);
    if (newPin == currentPin) {
      throw const AppException('PIN baru harus berbeda dari PIN lama.');
    }
    final email = client.auth.currentUser?.email;
    if (email == null) throw const AppException('Sesi tidak ditemukan.');
    try {
      await client.auth.signInWithPassword(email: email, password: currentPin);
    } on AuthException {
      throw const AppException('PIN lama salah.');
    }
    await client.auth.updateUser(UserAttributes(password: newPin));
  });

  @override
  Future<Profile> updateProfile(Profile profile) => guard(() async {
    _required(profile.fullName, 'Nama');
    if (profile.tariffIdrPerKwh <= 0) {
      throw const AppException('Tarif listrik harus lebih dari 0.');
    }
    await table('profiles')
        .update({
          'full_name': profile.fullName.trim(),
          'business_name': profile.businessName.trim(),
          'city': profile.city.trim(),
          'tariff_idr_per_kwh': profile.tariffIdrPerKwh,
        })
        .eq('id', profile.id);
    return _fetchProfile(profile.id);
  });
}
