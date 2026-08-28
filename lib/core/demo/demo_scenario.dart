import 'package:flutter/foundation.dart';

/// The root demo object, loaded once at bootstrap from
/// `assets/demo/scenario_happy_path.json` (docs/DATA_MODEL.md §3.1).
@immutable
class DemoScenario {
  const DemoScenario({
    required this.meta,
    required this.user,
    required this.impact,
    required this.creditInputs,
    required this.loanParams,
    required this.arisanSummary,
    required this.solarDaySummary,
    this.energyInsight,
    required this.roofScan,
    required this.solarDay,
    required this.arisan,
    required this.quota,
    required this.offers,
    required this.threads,
  });

  final DemoMeta meta;
  final DemoUser user;
  final DemoImpactMetrics impact;
  final DemoCreditInputs creditInputs;
  final DemoLoanParams loanParams;
  final DemoArisanSummary arisanSummary;
  final DemoSolarDaySummary solarDaySummary;
  final DemoEnergyInsight? energyInsight;
  final DemoRoofScan roofScan;
  final DemoSolarDay solarDay;
  final DemoArisanGroup arisan;
  final DemoEnergyQuota quota;
  final List<DemoQuotaOffer> offers;
  final List<DemoMessageThread> threads;

  factory DemoScenario.fromJson(Map<String, dynamic> json) {
    return DemoScenario(
      meta: DemoMeta.fromJson(_object(json, 'meta')),
      user: DemoUser.fromJson(_object(json, 'user')),
      impact: DemoImpactMetrics.fromJson(_object(json, 'impact')),
      creditInputs: DemoCreditInputs.fromJson(_object(json, 'creditInputs')),
      loanParams: DemoLoanParams.fromJson(_object(json, 'loanParams')),
      arisanSummary: DemoArisanSummary.fromJson(_object(json, 'arisanSummary')),
      solarDaySummary: DemoSolarDaySummary.fromJson(
        _object(json, 'solarDaySummary'),
      ),
      energyInsight: json['energyInsight'] != null
          ? DemoEnergyInsight.fromJson(_object(json, 'energyInsight'))
          : null,
      roofScan: DemoRoofScan.fromJson(_object(json, 'roofScan')),
      solarDay: DemoSolarDay.fromJson(_object(json, 'solarDay')),
      arisan: DemoArisanGroup.fromJson(_object(json, 'arisan')),
      quota: DemoEnergyQuota.fromJson(_object(json, 'quota')),
      offers: (json['offers'] as List)
          .map((e) => DemoQuotaOffer.fromJson(e as Map<String, dynamic>))
          .toList(),
      threads: (json['threads'] as List)
          .map((e) => DemoMessageThread.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  DemoScenario copyWith({
    DemoMeta? meta,
    DemoUser? user,
    DemoImpactMetrics? impact,
    DemoCreditInputs? creditInputs,
    DemoLoanParams? loanParams,
    DemoArisanSummary? arisanSummary,
    DemoSolarDaySummary? solarDaySummary,
    DemoEnergyInsight? energyInsight,
    DemoRoofScan? roofScan,
    DemoSolarDay? solarDay,
    DemoArisanGroup? arisan,
    DemoEnergyQuota? quota,
    List<DemoQuotaOffer>? offers,
    List<DemoMessageThread>? threads,
  }) => DemoScenario(
    meta: meta ?? this.meta,
    user: user ?? this.user,
    impact: impact ?? this.impact,
    creditInputs: creditInputs ?? this.creditInputs,
    loanParams: loanParams ?? this.loanParams,
    arisanSummary: arisanSummary ?? this.arisanSummary,
    solarDaySummary: solarDaySummary ?? this.solarDaySummary,
    energyInsight: energyInsight ?? this.energyInsight,
    roofScan: roofScan ?? this.roofScan,
    solarDay: solarDay ?? this.solarDay,
    arisan: arisan ?? this.arisan,
    quota: quota ?? this.quota,
    offers: offers ?? this.offers,
    threads: threads ?? this.threads,
  );
}

// ---------------------------------------------------------------------------
// Meta
// ---------------------------------------------------------------------------

@immutable
class DemoMeta {
  const DemoMeta({required this.label, required this.generatedAt});
  final String label;
  final DateTime generatedAt;

  factory DemoMeta.fromJson(Map<String, dynamic> json) => DemoMeta(
    label: _string(json, 'label'),
    generatedAt: _dateTime(json, 'generatedAt'),
  );
}

// ---------------------------------------------------------------------------
// User
// ---------------------------------------------------------------------------

/// Canonical persona: Ibu Clara (docs/ASSUMPTIONS_AND_RISKS.md PD-13).
@immutable
class DemoUser {
  const DemoUser({
    required this.id,
    required this.displayName,
    required this.greetingName,
    required this.role,
    required this.phone,
    required this.city,
    required this.joinedAt,
  });

  final String id;
  final String displayName;
  final String greetingName;
  final String role;
  final String phone;
  final String city;
  final DateTime joinedAt;

  factory DemoUser.fromJson(Map<String, dynamic> json) => DemoUser(
    id: _string(json, 'id'),
    displayName: _string(json, 'displayName'),
    greetingName: _string(json, 'greetingName'),
    role: _string(json, 'role'),
    phone: _string(json, 'phone'),
    city: _string(json, 'city'),
    joinedAt: _dateTime(json, 'joinedAt'),
  );
}

// ---------------------------------------------------------------------------
// Impact
// ---------------------------------------------------------------------------

@immutable
class DemoImpactMetrics {
  const DemoImpactMetrics({
    required this.totalEnergyUsedKwh,
    required this.energySharedKwh,
    required this.co2AvoidedKg,
    required this.arisanGroupSize,
    required this.monthlySavingIdr,
    required this.solarSharePct,
  });

  final double totalEnergyUsedKwh;
  final double energySharedKwh;
  final double co2AvoidedKg;
  final int arisanGroupSize;
  final int monthlySavingIdr;
  final int solarSharePct;

  factory DemoImpactMetrics.fromJson(Map<String, dynamic> json) =>
      DemoImpactMetrics(
        totalEnergyUsedKwh: _double(json, 'totalEnergyUsedKwh'),
        energySharedKwh: _double(json, 'energySharedKwh'),
        co2AvoidedKg: _double(json, 'co2AvoidedKg'),
        arisanGroupSize: _int(json, 'arisanGroupSize'),
        monthlySavingIdr: _int(json, 'monthlySavingIdr'),
        solarSharePct: _int(json, 'solarSharePct'),
      );
}

// ---------------------------------------------------------------------------
// Credit inputs
// ---------------------------------------------------------------------------

@immutable
class DemoCreditInputs {
  const DemoCreditInputs({
    required this.energyUsageConsistency,
    required this.paymentHistory,
    required this.businessActivity,
    required this.communityParticipation,
  });

  final double energyUsageConsistency;
  final double paymentHistory;
  final double businessActivity;
  final double communityParticipation;

  factory DemoCreditInputs.fromJson(Map<String, dynamic> json) =>
      DemoCreditInputs(
        energyUsageConsistency: _double(json, 'energyUsageConsistency'),
        paymentHistory: _double(json, 'paymentHistory'),
        businessActivity: _double(json, 'businessActivity'),
        communityParticipation: _double(json, 'communityParticipation'),
      );
}

// ---------------------------------------------------------------------------
// Loan params
// ---------------------------------------------------------------------------

/// Seeded financing simulation parameters (docs/DATA_MODEL.md §3.12).
@immutable
class DemoLoanParams {
  const DemoLoanParams({
    required this.minIdr,
    required this.maxDemoFinancingIdr,
    required this.flatMonthlyRatePct,
    required this.eligibleScoreThreshold,
  });

  final int minIdr;
  final int maxDemoFinancingIdr;
  final double flatMonthlyRatePct;
  final int eligibleScoreThreshold;

  factory DemoLoanParams.fromJson(Map<String, dynamic> json) => DemoLoanParams(
    minIdr: _int(json, 'minIdr'),
    maxDemoFinancingIdr: _int(json, 'maxDemoFinancingIdr'),
    flatMonthlyRatePct: _double(json, 'flatMonthlyRatePct'),
    eligibleScoreThreshold: _int(json, 'eligibleScoreThreshold'),
  );
}

// ---------------------------------------------------------------------------
// Arisan summary (Home dashboard minimal view)
// ---------------------------------------------------------------------------

@immutable
class DemoArisanSummary {
  const DemoArisanSummary({
    required this.groupName,
    required this.memberCount,
    required this.myContributionStatus,
    required this.myTurnPosition,
  });

  final String groupName;
  final int memberCount;
  final String myContributionStatus;
  final int myTurnPosition;

  factory DemoArisanSummary.fromJson(Map<String, dynamic> json) =>
      DemoArisanSummary(
        groupName: _string(json, 'groupName'),
        memberCount: _int(json, 'memberCount'),
        myContributionStatus: _string(json, 'myContributionStatus'),
        myTurnPosition: _int(json, 'myTurnPosition'),
      );
}

// ---------------------------------------------------------------------------
// Solar Hub day summary (Home dashboard)
// ---------------------------------------------------------------------------

@immutable
class DemoSolarDaySummary {
  const DemoSolarDaySummary({
    required this.capacityPct,
    required this.statusLabel,
  });

  final int capacityPct;
  final String statusLabel;

  factory DemoSolarDaySummary.fromJson(Map<String, dynamic> json) =>
      DemoSolarDaySummary(
        capacityPct: _int(json, 'capacityPct'),
        statusLabel: _string(json, 'statusLabel'),
      );
}

// ---------------------------------------------------------------------------
// Energy insight
// ---------------------------------------------------------------------------

@immutable
class DemoEnergyInsight {
  const DemoEnergyInsight({
    required this.spikeDetected,
    required this.spikeWindowLabel,
    required this.addedMonthlyCostIdr,
    required this.mainInsight,
    required this.contributors,
  });

  final bool spikeDetected;
  final String spikeWindowLabel;
  final int addedMonthlyCostIdr;
  final String mainInsight;
  final List<DemoApplianceCost> contributors;

  factory DemoEnergyInsight.fromJson(Map<String, dynamic> json) =>
      DemoEnergyInsight(
        spikeDetected: _bool(json, 'spikeDetected'),
        spikeWindowLabel: _string(json, 'spikeWindowLabel'),
        addedMonthlyCostIdr: _int(json, 'addedMonthlyCostIdr'),
        mainInsight: _string(json, 'mainInsight'),
        contributors: (json['contributors'] as List)
            .map((e) => DemoApplianceCost.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

@immutable
class DemoApplianceCost {
  const DemoApplianceCost({
    required this.applianceKind,
    required this.name,
    required this.costIdr,
    this.tip,
  });

  final String applianceKind;
  final String name;
  final int costIdr;
  final String? tip;

  factory DemoApplianceCost.fromJson(Map<String, dynamic> json) =>
      DemoApplianceCost(
        applianceKind: _string(json, 'applianceKind'),
        name: _string(json, 'name'),
        costIdr: _int(json, 'costIdr'),
        tip: json['tip'] as String?,
      );
}

// ---------------------------------------------------------------------------
// Roof scan
// ---------------------------------------------------------------------------

@immutable
class DemoRoofScan {
  const DemoRoofScan({
    required this.suitability,
    required this.estimatedPotentialAreaM2,
    required this.roofOrientationLabel,
    required this.sunExposurePotentialLabel,
    required this.verificationNotice,
    required this.tip,
  });

  final String suitability;
  final double estimatedPotentialAreaM2;
  final String roofOrientationLabel;
  final String sunExposurePotentialLabel;
  final String verificationNotice;
  final String tip;

  factory DemoRoofScan.fromJson(Map<String, dynamic> json) => DemoRoofScan(
    suitability: _string(json, 'suitability'),
    estimatedPotentialAreaM2: _double(json, 'estimatedPotentialAreaM2'),
    roofOrientationLabel: _string(json, 'roofOrientationLabel'),
    sunExposurePotentialLabel: _string(json, 'sunExposurePotentialLabel'),
    verificationNotice: _string(json, 'verificationNotice'),
    tip: _string(json, 'tip'),
  );
}

// ---------------------------------------------------------------------------
// Solar day
// ---------------------------------------------------------------------------

@immutable
class DemoSolarDay {
  const DemoSolarDay({
    required this.capacityPct,
    required this.recommendedSlotId,
    required this.recommendationReason,
    required this.slots,
    required this.appliances,
  });

  final int capacityPct;
  final String recommendedSlotId;
  final String recommendationReason;
  final List<DemoSolarSlot> slots;
  final List<DemoAppliance> appliances;

  factory DemoSolarDay.fromJson(Map<String, dynamic> json) => DemoSolarDay(
    capacityPct: _int(json, 'capacityPct'),
    recommendedSlotId: _string(json, 'recommendedSlotId'),
    recommendationReason: _string(json, 'recommendationReason'),
    slots: (json['slots'] as List)
        .map((e) => DemoSolarSlot.fromJson(e as Map<String, dynamic>))
        .toList(),
    appliances: (json['appliances'] as List)
        .map((e) => DemoAppliance.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

@immutable
class DemoSolarSlot {
  const DemoSolarSlot({
    required this.id,
    required this.label,
    required this.availability,
  });

  final String id;
  final String label;
  final String availability;

  factory DemoSolarSlot.fromJson(Map<String, dynamic> json) => DemoSolarSlot(
    id: _string(json, 'id'),
    label: _string(json, 'label'),
    availability: _string(json, 'availability'),
  );
}

@immutable
class DemoAppliance {
  const DemoAppliance({
    required this.kind,
    required this.name,
    required this.approxPowerKw,
  });

  final String kind;
  final String name;
  final double approxPowerKw;

  factory DemoAppliance.fromJson(Map<String, dynamic> json) => DemoAppliance(
    kind: _string(json, 'kind'),
    name: _string(json, 'name'),
    approxPowerKw: _double(json, 'approxPowerKw'),
  );
}

// ---------------------------------------------------------------------------
// Solar booking (in-session mutable)
// ---------------------------------------------------------------------------

@immutable
class DemoSolarBooking {
  const DemoSolarBooking({
    required this.id,
    required this.applianceKind,
    required this.applianceName,
    required this.slotId,
    required this.slotLabel,
    required this.date,
    required this.createdAt,
  });

  final String id;
  final String applianceKind;
  final String applianceName;
  final String slotId;
  final String slotLabel;
  final DateTime date;
  final DateTime createdAt;
}

// ---------------------------------------------------------------------------
// Arisan Group
// ---------------------------------------------------------------------------

@immutable
class DemoArisanGroup {
  const DemoArisanGroup({
    required this.id,
    required this.name,
    required this.myContributionStatus,
    required this.myTurnPosition,
    required this.nextTurnDate,
    required this.members,
    required this.rotation,
    required this.ledger,
  });

  final String id;
  final String name;
  final String myContributionStatus;
  final int myTurnPosition;
  final DateTime nextTurnDate;
  final List<DemoArisanMember> members;
  final List<DemoRotationSlot> rotation;
  final List<DemoLedgerEntry> ledger;

  factory DemoArisanGroup.fromJson(Map<String, dynamic> json) =>
      DemoArisanGroup(
        id: _string(json, 'id'),
        name: _string(json, 'name'),
        myContributionStatus: _string(json, 'myContributionStatus'),
        myTurnPosition: _int(json, 'myTurnPosition'),
        nextTurnDate: _dateTime(json, 'nextTurnDate'),
        members: (json['members'] as List)
            .map((e) => DemoArisanMember.fromJson(e as Map<String, dynamic>))
            .toList(),
        rotation: (json['rotation'] as List)
            .map((e) => DemoRotationSlot.fromJson(e as Map<String, dynamic>))
            .toList(),
        ledger: (json['ledger'] as List)
            .map((e) => DemoLedgerEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  DemoArisanGroup copyWith({List<DemoLedgerEntry>? ledger}) => DemoArisanGroup(
    id: id,
    name: name,
    myContributionStatus: myContributionStatus,
    myTurnPosition: myTurnPosition,
    nextTurnDate: nextTurnDate,
    members: members,
    rotation: rotation,
    ledger: ledger ?? this.ledger,
  );
}

@immutable
class DemoArisanMember {
  const DemoArisanMember({
    required this.id,
    required this.name,
    required this.isCurrentUser,
  });

  final String id;
  final String name;
  final bool isCurrentUser;

  factory DemoArisanMember.fromJson(Map<String, dynamic> json) =>
      DemoArisanMember(
        id: _string(json, 'id'),
        name: _string(json, 'name'),
        isCurrentUser: _bool(json, 'isCurrentUser'),
      );
}

@immutable
class DemoRotationSlot {
  const DemoRotationSlot({
    required this.date,
    required this.memberId,
    required this.memberName,
  });

  final DateTime date;
  final String memberId;
  final String memberName;

  factory DemoRotationSlot.fromJson(Map<String, dynamic> json) =>
      DemoRotationSlot(
        date: _dateTime(json, 'date'),
        memberId: _string(json, 'memberId'),
        memberName: _string(json, 'memberName'),
      );
}

@immutable
class DemoLedgerEntry {
  const DemoLedgerEntry({
    required this.id,
    required this.type,
    required this.memberId,
    required this.memberName,
    this.amountIdr,
    this.amountKwh,
    required this.timestamp,
    required this.status,
    this.note,
  });

  final String id;
  final String
  type; // 'contribution' | 'payout' | 'quotaShared' | 'quotaReceived' | 'adjustment'
  final String memberId;
  final String memberName;
  final int? amountIdr;
  final double? amountKwh;
  final DateTime timestamp;
  final String status; // 'pending' | 'settled'
  final String? note;

  factory DemoLedgerEntry.fromJson(Map<String, dynamic> json) =>
      DemoLedgerEntry(
        id: _string(json, 'id'),
        type: _string(json, 'type'),
        memberId: _string(json, 'memberId'),
        memberName: _string(json, 'memberName'),
        amountIdr: json['amountIdr'] as int?,
        amountKwh: json['amountKwh'] != null
            ? (json['amountKwh'] as num).toDouble()
            : null,
        timestamp: _dateTime(json, 'timestamp'),
        status: _string(json, 'status'),
        note: json['note'] as String?,
      );
}

// ---------------------------------------------------------------------------
// Energy Quota
// ---------------------------------------------------------------------------

/// Mutable during demo session (docs/DATA_MODEL.md §3.10).
@immutable
class DemoEnergyQuota {
  const DemoEnergyQuota({
    required this.availableKwh,
    required this.neededKwh,
    required this.myTurnSlotLabel,
  });

  final double availableKwh;
  final double neededKwh;
  final String myTurnSlotLabel;

  factory DemoEnergyQuota.fromJson(Map<String, dynamic> json) =>
      DemoEnergyQuota(
        availableKwh: _double(json, 'availableKwh'),
        neededKwh: _double(json, 'neededKwh'),
        myTurnSlotLabel: _string(json, 'myTurnSlotLabel'),
      );

  DemoEnergyQuota copyWith({double? availableKwh, double? neededKwh}) =>
      DemoEnergyQuota(
        availableKwh: availableKwh ?? this.availableKwh,
        neededKwh: neededKwh ?? this.neededKwh,
        myTurnSlotLabel: myTurnSlotLabel,
      );
}

// ---------------------------------------------------------------------------
// Quota Offer
// ---------------------------------------------------------------------------

@immutable
class DemoQuotaOffer {
  const DemoQuotaOffer({
    required this.id,
    required this.ownerMemberId,
    required this.ownerName,
    required this.amountKwh,
    required this.slotLabel,
    this.note,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String ownerMemberId;
  final String ownerName;
  final double amountKwh;
  final String slotLabel;
  final String? note;
  final String status; // 'open' | 'taken' | 'cancelled' | 'expired'
  final DateTime createdAt;

  factory DemoQuotaOffer.fromJson(Map<String, dynamic> json) => DemoQuotaOffer(
    id: _string(json, 'id'),
    ownerMemberId: _string(json, 'ownerMemberId'),
    ownerName: _string(json, 'ownerName'),
    amountKwh: _double(json, 'amountKwh'),
    slotLabel: _string(json, 'slotLabel'),
    note: json['note'] as String?,
    status: _string(json, 'status'),
    createdAt: _dateTime(json, 'createdAt'),
  );

  DemoQuotaOffer copyWith({String? status}) => DemoQuotaOffer(
    id: id,
    ownerMemberId: ownerMemberId,
    ownerName: ownerName,
    amountKwh: amountKwh,
    slotLabel: slotLabel,
    note: note,
    status: status ?? this.status,
    createdAt: createdAt,
  );
}

// ---------------------------------------------------------------------------
// Quota Request (in-session only)
// ---------------------------------------------------------------------------

@immutable
class DemoQuotaRequest {
  const DemoQuotaRequest({
    required this.id,
    required this.offerId,
    required this.amountKwh,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String offerId;
  final double amountKwh;
  final String? note;
  final DateTime createdAt;
}

// ---------------------------------------------------------------------------
// Messages
// ---------------------------------------------------------------------------

@immutable
class DemoMessageThread {
  const DemoMessageThread({
    required this.id,
    required this.kind,
    required this.title,
    required this.lastPreview,
    required this.lastAt,
    required this.unreadCount,
    required this.messages,
  });

  final String id;
  final String kind; // 'group' | 'admin' | 'member' | 'system'
  final String title;
  final String lastPreview;
  final DateTime lastAt;
  final int unreadCount;
  final List<DemoMessage> messages;

  factory DemoMessageThread.fromJson(Map<String, dynamic> json) =>
      DemoMessageThread(
        id: _string(json, 'id'),
        kind: _string(json, 'kind'),
        title: _string(json, 'title'),
        lastPreview: _string(json, 'lastPreview'),
        lastAt: _dateTime(json, 'lastAt'),
        unreadCount: _int(json, 'unreadCount'),
        messages: (json['messages'] as List)
            .map((e) => DemoMessage.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

@immutable
class DemoMessage {
  const DemoMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.isCurrentUser,
    required this.isSystem,
    required this.text,
    required this.sentAt,
  });

  final String id;
  final String senderId;
  final String senderName;
  final bool isCurrentUser;
  final bool isSystem;
  final String text;
  final DateTime sentAt;

  factory DemoMessage.fromJson(Map<String, dynamic> json) => DemoMessage(
    id: _string(json, 'id'),
    senderId: _string(json, 'senderId'),
    senderName: _string(json, 'senderName'),
    isCurrentUser: _bool(json, 'isCurrentUser'),
    isSystem: _bool(json, 'isSystem'),
    text: _string(json, 'text'),
    sentAt: _dateTime(json, 'sentAt'),
  );
}

// ---------------------------------------------------------------------------
// Format exception
// ---------------------------------------------------------------------------

class DemoScenarioFormatException implements Exception {
  DemoScenarioFormatException(this.message);
  final String message;
  @override
  String toString() => 'DemoScenarioFormatException: $message';
}

// ---------------------------------------------------------------------------
// Tiny typed accessors
// ---------------------------------------------------------------------------

Map<String, dynamic> _object(Map<String, dynamic> json, String key) {
  final Object? value = json[key];
  if (value is Map<String, dynamic>) return value;
  throw DemoScenarioFormatException('missing or invalid object "$key"');
}

String _string(Map<String, dynamic> json, String key) {
  final Object? value = json[key];
  if (value is String && value.isNotEmpty) return value;
  throw DemoScenarioFormatException('missing or invalid string "$key"');
}

DateTime _dateTime(Map<String, dynamic> json, String key) {
  final Object? value = json[key];
  if (value is String) {
    final DateTime? parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw DemoScenarioFormatException('missing or invalid ISO-8601 date "$key"');
}

double _double(Map<String, dynamic> json, String key) {
  final Object? value = json[key];
  if (value is num) return value.toDouble();
  throw DemoScenarioFormatException('missing or invalid number "$key"');
}

int _int(Map<String, dynamic> json, String key) {
  final Object? value = json[key];
  if (value is num) return value.toInt();
  throw DemoScenarioFormatException('missing or invalid integer "$key"');
}

bool _bool(Map<String, dynamic> json, String key) {
  final Object? value = json[key];
  if (value is bool) return value;
  throw DemoScenarioFormatException('missing or invalid boolean "$key"');
}
