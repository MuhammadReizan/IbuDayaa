import 'package:flutter/foundation.dart';

import 'models.dart';

/// The whole of the user's data, as one immutable document.
///
/// This replaces the bundled demo scenario: it starts *empty* and only ever
/// contains what the person using the app recorded. `profile == null` means
/// onboarding has not been completed yet.
@immutable
class AppData {
  const AppData({
    this.profile,
    this.bills = const [],
    this.appliances = const [],
    this.sessions = const [],
    this.arisan,
    this.ledger = const [],
    this.offers = const [],
    this.calculations = const [],
    this.readNotificationIds = const {},
  });

  /// Bump when a field changes shape; [AppData.fromJson] migrates forward.
  static const int schemaVersion = 1;

  final UserProfile? profile;
  final List<Bill> bills;
  final List<Appliance> appliances;
  final List<SolarSession> sessions;
  final ArisanGroup? arisan;
  final List<LedgerEntry> ledger;
  final List<QuotaOffer> offers;
  final List<SavedCalculation> calculations;
  final Set<String> readNotificationIds;

  static const AppData empty = AppData();

  bool get isOnboarded => profile != null;

  /// True once the user has recorded enough for the dashboard to say anything.
  bool get hasAnyRecords =>
      bills.isNotEmpty ||
      appliances.isNotEmpty ||
      sessions.isNotEmpty ||
      arisan != null;

  AppData copyWith({
    UserProfile? profile,
    List<Bill>? bills,
    List<Appliance>? appliances,
    List<SolarSession>? sessions,
    ArisanGroup? arisan,
    bool clearArisan = false,
    List<LedgerEntry>? ledger,
    List<QuotaOffer>? offers,
    List<SavedCalculation>? calculations,
    Set<String>? readNotificationIds,
  }) => AppData(
    profile: profile ?? this.profile,
    bills: bills ?? this.bills,
    appliances: appliances ?? this.appliances,
    sessions: sessions ?? this.sessions,
    arisan: clearArisan ? null : (arisan ?? this.arisan),
    ledger: ledger ?? this.ledger,
    offers: offers ?? this.offers,
    calculations: calculations ?? this.calculations,
    readNotificationIds: readNotificationIds ?? this.readNotificationIds,
  );

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'profile': profile?.toJson(),
    'bills': bills.map((e) => e.toJson()).toList(),
    'appliances': appliances.map((e) => e.toJson()).toList(),
    'sessions': sessions.map((e) => e.toJson()).toList(),
    'arisan': arisan?.toJson(),
    'ledger': ledger.map((e) => e.toJson()).toList(),
    'offers': offers.map((e) => e.toJson()).toList(),
    'calculations': calculations.map((e) => e.toJson()).toList(),
    'readNotificationIds': readNotificationIds.toList(),
  };

  /// Tolerant by design: a field that fails to parse is dropped rather than
  /// taking the user's whole document down with it.
  factory AppData.fromJson(Map<String, dynamic> j) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) {
      final raw = j[key];
      if (raw is! List) return const [];
      final out = <T>[];
      for (final e in raw) {
        if (e is! Map<String, dynamic>) continue;
        try {
          out.add(parse(e));
        } catch (_) {
          // Skip the unreadable record, keep the rest.
        }
      }
      return out;
    }

    UserProfile? profile;
    final rawProfile = j['profile'];
    if (rawProfile is Map<String, dynamic>) {
      try {
        profile = UserProfile.fromJson(rawProfile);
      } catch (_) {
        profile = null;
      }
    }

    ArisanGroup? arisan;
    final rawArisan = j['arisan'];
    if (rawArisan is Map<String, dynamic>) {
      try {
        arisan = ArisanGroup.fromJson(rawArisan);
      } catch (_) {
        arisan = null;
      }
    }

    return AppData(
      profile: profile,
      bills: list('bills', Bill.fromJson),
      appliances: list('appliances', Appliance.fromJson),
      sessions: list('sessions', SolarSession.fromJson),
      arisan: arisan,
      ledger: list('ledger', LedgerEntry.fromJson),
      offers: list('offers', QuotaOffer.fromJson),
      calculations: list('calculations', SavedCalculation.fromJson),
      readNotificationIds:
          (j['readNotificationIds'] as List?)?.whereType<String>().toSet() ??
          const {},
    );
  }
}
