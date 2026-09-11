import '../../../core/paths.dart';
import '../../auth/credentials.dart';
import '../../db/ids.dart';
import '../../db/row.dart';
import '../../db/tables.dart';
import '../../errors.dart';
import '../../models/models.dart';
import '../repositories.dart';
import 'local_base.dart';

class LocalAuthRepository extends LocalRepo implements AuthRepository {
  LocalAuthRepository(super.db, super.now);

  static const int maxAttempts = 5;
  static const Duration lockDuration = Duration(seconds: 60);

  static const List<(int, int)> _defaultSlots = [
    (8, 10),
    (10, 12),
    (13, 15),
    (15, 17),
  ];

  @override
  Future<Profile?> restoreSession() async {
    final userId = db.find(Tbl.localSession, 'current')?['user_id'];
    if (userId is! String) return null;
    final row = db.find(Tbl.profiles, userId);
    return row == null ? null : Profile.fromRow(row);
  }

  @override
  Future<Cooperative?> findCooperativeByInviteCode(String code) async {
    final c = code.trim().toUpperCase();
    if (c.isEmpty) return null;
    final row = db.first(Tbl.cooperatives, (r) => r['invite_code'] == c);
    return row == null ? null : Cooperative.fromRow(row);
  }

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

  void _ensurePhoneFree(String phone) {
    if (db.first(Tbl.profiles, (r) => r['phone'] == phone) != null) {
      throw const AppException('Nomor HP ini sudah terdaftar. Silakan masuk.');
    }
  }

  void _required(String value, String label) {
    if (value.trim().isEmpty) throw AppException('$label wajib diisi.');
  }

  Future<void> _storeCredential(String userId, String pin) {
    final salt = PinHasher.newSalt();
    return db.insert(Tbl.localCredentials, {
      'id': userId,
      'pin_hash': PinHasher.hash(pin, salt),
      'pin_salt': salt,
      'failed_attempts': 0,
      'locked_until': null,
    });
  }

  Future<void> _startSession(String userId) async {
    await db.deleteWhere(Tbl.localSession, (_) => true);
    await db.insert(Tbl.localSession, {'id': 'current', 'user_id': userId});
  }

  @override
  Future<Profile> registerAdmin({
    required String phone,
    required String pin,
    required String fullName,
    required String city,
    required String cooperativeName,
  }) async {
    final p = _phone(phone);
    _checkPin(pin);
    _required(fullName, 'Nama');
    _required(cooperativeName, 'Nama koperasi');
    _required(city, 'Kota');
    _ensurePhoneFree(p);

    return db.transaction(() async {
      final t = now();
      final userId = newId();
      final coopId = newId();

      String code;
      do {
        code = newInviteCode();
      } while (db.first(Tbl.cooperatives, (r) => r['invite_code'] == code) !=
          null);

      final coop = Cooperative(
        id: coopId,
        name: cooperativeName.trim(),
        city: city.trim(),
        inviteCode: code,
        createdBy: userId,
        createdAt: t,
      );
      final profile = Profile(
        id: userId,
        phone: p,
        fullName: fullName.trim(),
        businessName: '',
        city: city.trim(),
        role: UserRole.admin,
        cooperativeId: coopId,
        tariffIdrPerKwh: 1444.70,
        createdAt: t,
      );

      await db.insert(Tbl.cooperatives, coop.toRow());
      await db.insert(Tbl.profiles, profile.toRow());
      await _storeCredential(userId, pin);

      // Capacity 0 = not configured. Members see "belum diatur" until the
      // admin enters the installation's real rating.
      final hubId = newId();
      await db.insert(
        Tbl.solarHubs,
        SolarHub(
          id: hubId,
          cooperativeId: coopId,
          name: 'Solar Hub ${coop.name}',
          location: coop.city,
          dailyCapacityKwh: 0,
          createdAt: t,
        ).toRow(),
      );
      for (int i = 0; i < _defaultSlots.length; i++) {
        await db.insert(
          Tbl.hubSlots,
          HubSlot(
            id: newId(),
            hubId: hubId,
            startHour: _defaultSlots[i].$1,
            endHour: _defaultSlots[i].$2,
            sort: i,
          ).toRow(),
        );
      }

      final threadId = newId();
      await db.insert(
        Tbl.messageThreads,
        MessageThread(
          id: threadId,
          cooperativeId: coopId,
          kind: ThreadKind.announcement,
          title: 'Pengumuman ${coop.name}',
          createdAt: t,
        ).toRow(),
      );
      await addParticipant(threadId, userId);

      await _startSession(userId);
      return profile;
    });
  }

  @override
  Future<Profile> registerMember({
    required String phone,
    required String pin,
    required String fullName,
    required String businessName,
    required String city,
    required String inviteCode,
  }) async {
    final p = _phone(phone);
    _checkPin(pin);
    _required(fullName, 'Nama');
    _required(businessName, 'Nama usaha');
    _required(city, 'Kota');
    final coop = await findCooperativeByInviteCode(inviteCode);
    if (coop == null) {
      throw const AppException(
        'Kode koperasi tidak ditemukan. Tanyakan lagi kodenya ke admin '
        'koperasi Anda.',
      );
    }
    _ensurePhoneFree(p);

    return db.transaction(() async {
      final t = now();
      final userId = newId();
      final profile = Profile(
        id: userId,
        phone: p,
        fullName: fullName.trim(),
        businessName: businessName.trim(),
        city: city.trim(),
        role: UserRole.member,
        cooperativeId: coop.id,
        tariffIdrPerKwh: 1444.70,
        createdAt: t,
      );
      await db.insert(Tbl.profiles, profile.toRow());
      await _storeCredential(userId, pin);

      final announcement = db.first(
        Tbl.messageThreads,
        (r) => r['cooperative_id'] == coop.id && r['kind'] == 'announcement',
      );
      if (announcement != null) {
        await addParticipant(announcement['id'] as String, userId);
      }

      final supportId = newId();
      await db.insert(
        Tbl.messageThreads,
        MessageThread(
          id: supportId,
          cooperativeId: coop.id,
          kind: ThreadKind.support,
          title: 'Admin ${coop.name}',
          refId: userId,
          createdAt: t,
        ).toRow(),
      );
      await addParticipant(supportId, userId);
      for (final a in adminsOf(coop.id)) {
        await addParticipant(supportId, a.id);
      }
      await postSystemMessage(
        supportId,
        'Selamat bergabung di ${coop.name}. Tanyakan apa saja ke admin di '
        'sini.',
      );

      await notifyAdmins(
        cooperativeId: coop.id,
        type: 'member',
        title: 'Anggota baru bergabung',
        body:
            '${profile.fullName} (${profile.businessName}) masuk ke koperasi.',
        route: Paths.adminMember(userId),
      );

      await _startSession(userId);
      return profile;
    });
  }

  @override
  Future<Profile> login({required String phone, required String pin}) async {
    final p = _phone(phone);
    final row = db.first(Tbl.profiles, (r) => r['phone'] == p);
    if (row == null) {
      throw const AppException('Nomor HP ini belum terdaftar. Daftar dulu.');
    }
    final profile = Profile.fromRow(row);
    final cred = db.find(Tbl.localCredentials, profile.id);
    if (cred == null) {
      throw const AppException('Akun ini belum punya PIN. Hubungi admin.');
    }

    final t = now();
    final lockedUntil = rDateN(cred, 'locked_until');
    if (lockedUntil != null && t.isBefore(lockedUntil)) {
      final secs = lockedUntil.difference(t).inSeconds + 1;
      throw AppException(
        'Terlalu banyak percobaan. Coba lagi dalam $secs detik.',
      );
    }

    final ok = PinHasher.verify(
      pin,
      rStr(cred, 'pin_salt'),
      rStr(cred, 'pin_hash'),
    );
    if (!ok) {
      final attempts = rInt(cred, 'failed_attempts') + 1;
      if (attempts >= maxAttempts) {
        await db.update(Tbl.localCredentials, profile.id, {
          'failed_attempts': 0,
          'locked_until': ts(t.add(lockDuration)),
        });
        throw AppException(
          'PIN salah $maxAttempts kali. Tunggu '
          '${lockDuration.inSeconds} detik lalu coba lagi.',
        );
      }
      await db.update(Tbl.localCredentials, profile.id, {
        'failed_attempts': attempts,
      });
      throw AppException(
        'PIN salah. Sisa percobaan: ${maxAttempts - attempts}.',
      );
    }

    await db.update(Tbl.localCredentials, profile.id, {
      'failed_attempts': 0,
      'locked_until': null,
    });
    await _startSession(profile.id);
    return profile;
  }

  @override
  Future<void> logout() => db.deleteWhere(Tbl.localSession, (_) => true);

  @override
  Future<void> changePin({
    required String userId,
    required String currentPin,
    required String newPin,
  }) async {
    final cred = db.find(Tbl.localCredentials, userId);
    if (cred == null) throw const AppException('Akun tidak ditemukan.');
    if (!PinHasher.verify(
      currentPin,
      rStr(cred, 'pin_salt'),
      rStr(cred, 'pin_hash'),
    )) {
      throw const AppException('PIN lama salah.');
    }
    _checkPin(newPin);
    if (newPin == currentPin) {
      throw const AppException('PIN baru harus berbeda dari PIN lama.');
    }
    final salt = PinHasher.newSalt();
    await db.update(Tbl.localCredentials, userId, {
      'pin_hash': PinHasher.hash(newPin, salt),
      'pin_salt': salt,
      'failed_attempts': 0,
      'locked_until': null,
    });
  }

  @override
  Future<Profile> updateProfile(Profile profile) async {
    profileById(profile.id);
    _required(profile.fullName, 'Nama');
    if (profile.tariffIdrPerKwh <= 0) {
      throw const AppException('Tarif listrik harus lebih dari 0.');
    }
    await db.update(Tbl.profiles, profile.id, {
      'full_name': profile.fullName.trim(),
      'business_name': profile.businessName.trim(),
      'city': profile.city.trim(),
      'tariff_idr_per_kwh': profile.tariffIdrPerKwh,
    });
    return profileById(profile.id);
  }
}
