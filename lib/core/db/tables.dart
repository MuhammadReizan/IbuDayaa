/// Table names. Every name and column mirrors the Supabase schema in
/// `supabase/migrations/` so a Supabase repository can replace the local one
/// without renaming anything.
abstract final class Tbl {
  static const profiles = 'profiles';
  static const cooperatives = 'cooperatives';
  static const energyRecords = 'energy_records';
  static const appliances = 'appliances';
  static const roofAssessments = 'roof_assessments';
  static const solarHubs = 'solar_hubs';
  static const hubSlots = 'hub_slots';
  static const hubBookings = 'hub_bookings';
  static const arisanGroups = 'arisan_groups';
  static const arisanMembers = 'arisan_members';
  static const arisanPayments = 'arisan_payments';
  static const quotaOffers = 'quota_offers';
  static const loanApplications = 'loan_applications';
  static const loanInstallments = 'loan_installments';
  static const loanEvents = 'loan_events';
  static const messageThreads = 'message_threads';
  static const threadParticipants = 'thread_participants';
  static const messages = 'messages';
  static const notifications = 'notifications';
  static const scoreSnapshots = 'score_snapshots';

  /// Local mode only — Supabase Auth owns credentials and sessions.
  static const localCredentials = 'local_credentials';
  static const localSession = 'local_session';

  static const all = [
    profiles,
    cooperatives,
    energyRecords,
    appliances,
    roofAssessments,
    solarHubs,
    hubSlots,
    hubBookings,
    arisanGroups,
    arisanMembers,
    arisanPayments,
    quotaOffers,
    loanApplications,
    loanInstallments,
    loanEvents,
    messageThreads,
    threadParticipants,
    messages,
    notifications,
    scoreSnapshots,
    localCredentials,
    localSession,
  ];
}
