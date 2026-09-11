import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// `0812 3456 7890`, `62812…`, `+62812…` → `+62812…`. Null when it is not an
/// Indonesian mobile number.
String? normalizeIndonesianPhone(String input) {
  var s = input.replaceAll(RegExp(r'[\s\-().]'), '');
  if (s.startsWith('+62')) {
    s = s.substring(3);
  } else if (s.startsWith('62')) {
    s = s.substring(2);
  } else if (s.startsWith('0')) {
    s = s.substring(1);
  }
  return RegExp(r'^8\d{8,12}$').hasMatch(s) ? '+62$s' : null;
}

bool isValidPin(String pin) => RegExp(r'^\d{6}$').hasMatch(pin);

/// 111111, 123456, 654321 — the first PINs anyone guesses.
bool isWeakPin(String pin) {
  if (!isValidPin(pin)) return true;
  if (pin.split('').toSet().length == 1) return true;
  const up = '0123456789';
  const down = '9876543210';
  return up.contains(pin) || down.contains(pin);
}

/// Local-mode PIN hashing. Supabase Auth takes this over in the hosted build.
///
/// A six-digit PIN has only a million values, so hashing alone cannot stop
/// someone who has the file. What protects the account is the attempt lockout
/// in the auth repository; the salt and stretching just keep the PIN from
/// sitting in the file in plain text.
abstract final class PinHasher {
  static const int _rounds = 10000;
  static final Random _rng = Random.secure();

  static String newSalt() => List.generate(
    16,
    (_) => _rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();

  static String hash(String pin, String salt) {
    List<int> bytes = utf8.encode('$salt:$pin');
    for (int i = 0; i < _rounds; i++) {
      bytes = sha256.convert(bytes).bytes;
    }
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Constant-time so response timing does not reveal how close a guess was.
  static bool verify(String pin, String salt, String expected) {
    final actual = hash(pin, salt);
    if (actual.length != expected.length) return false;
    int diff = 0;
    for (int i = 0; i < actual.length; i++) {
      diff |= actual.codeUnitAt(i) ^ expected.codeUnitAt(i);
    }
    return diff == 0;
  }
}
