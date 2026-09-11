import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// Everything the signed-in user is allowed to see in their cooperative.
///
/// The local repository filters rows the way Supabase Row Level Security will:
/// a member sees her own energy records, loans and notifications; an admin sees
/// every member of her cooperative. Screens only ever read this.
@immutable
class CoopSnapshot {
  const CoopSnapshot({
    this.cooperative,
    this.members = const [],
    this.energyRecords = const [],
    this.appliances = const [],
    this.roofAssessments = const [],
    this.hubs = const [],
    this.slots = const [],
    this.bookings = const [],
    this.groups = const [],
    this.groupMembers = const [],
    this.payments = const [],
    this.offers = const [],
    this.loans = const [],
    this.installments = const [],
    this.loanEvents = const [],
    this.threads = const [],
    this.participants = const [],
    this.messages = const [],
    this.notifications = const [],
    this.scoreSnapshots = const [],
  });

  static const CoopSnapshot empty = CoopSnapshot();

  final Cooperative? cooperative;
  final List<Profile> members;
  final List<EnergyRecord> energyRecords;
  final List<Appliance> appliances;
  final List<RoofAssessment> roofAssessments;
  final List<SolarHub> hubs;
  final List<HubSlot> slots;
  final List<HubBooking> bookings;
  final List<ArisanGroup> groups;
  final List<ArisanMember> groupMembers;
  final List<ArisanPayment> payments;
  final List<QuotaOffer> offers;
  final List<LoanApplication> loans;
  final List<LoanInstallment> installments;
  final List<LoanEvent> loanEvents;
  final List<MessageThread> threads;
  final List<ThreadParticipant> participants;
  final List<Message> messages;
  final List<AppNotification> notifications;
  final List<ScoreSnapshot> scoreSnapshots;

  Profile? profile(String? id) =>
      id == null ? null : members.where((m) => m.id == id).firstOrNull;

  String nameOf(String? id) => profile(id)?.fullName ?? 'Anggota';

  SolarHub? get hub => hubs.firstOrNull;
}
