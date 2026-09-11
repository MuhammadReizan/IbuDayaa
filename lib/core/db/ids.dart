import 'dart:math';

final Random _rng = Random.secure();

/// RFC 4122 v4 UUID, matching Postgres `uuid` primary keys.
String newId() {
  final b = List<int>.generate(16, (_) => _rng.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}

/// Cooperative invite code. Omits 0/O and 1/I/L so it can be read aloud or
/// copied off a paper note without mistakes.
String newInviteCode({int length = 6}) {
  const alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  return List.generate(
    length,
    (_) => alphabet[_rng.nextInt(alphabet.length)],
  ).join();
}
