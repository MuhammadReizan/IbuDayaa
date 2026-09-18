import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/app/router.dart';
import 'package:ibudaya/core/models/models.dart';
import 'package:ibudaya/core/paths.dart';

Profile _profile(UserRole role) => Profile(
  id: role.name,
  phone: '+6281200000009',
  fullName: 'Uji',
  businessName: '',
  city: 'Palembang',
  role: role,
  cooperativeId: 'c',
  tariffIdrPerKwh: 1444.70,
  createdAt: DateTime(2026),
);

void main() {
  final member = _profile(UserRole.member);
  final admin = _profile(UserRole.admin);

  test('signed out: only auth screens are reachable', () {
    expect(guard(null, Paths.login), isNull);
    expect(guard(null, Paths.registerMember), isNull);
    expect(guard(null, Paths.memberHome), Paths.welcome);
    expect(guard(null, Paths.adminHome), Paths.welcome);
    expect(guard(null, Paths.splash), Paths.welcome);
  });

  test('signed in: auth screens send each role home', () {
    expect(guard(member, Paths.login), Paths.memberHome);
    expect(guard(admin, Paths.welcome), Paths.adminHome);
  });

  test('members cannot open admin screens and vice versa', () {
    expect(guard(member, Paths.adminLoan('x')), Paths.memberHome);
    expect(guard(member, Paths.adminSettings), Paths.memberHome);
    expect(guard(admin, Paths.loanApply), Paths.adminHome);
    expect(guard(admin, Paths.energy), Paths.adminHome);
    expect(guard(member, Paths.loanApply), isNull);
    expect(guard(admin, Paths.adminLoan('x')), isNull);
  });

  test('shared screens are open to both roles', () {
    for (final p in [
      Paths.thread('t'),
      Paths.notifications,
      Paths.profileEdit,
      Paths.changePin,
      Paths.about,
    ]) {
      expect(guard(member, p), isNull, reason: p);
      expect(guard(admin, p), isNull, reason: p);
    }
  });
}
