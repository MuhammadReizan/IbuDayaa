/// Backend contracts.
///
/// Local mode implements these against [LocalDatabase]; the Supabase build
/// implements the same interfaces with `supabase_flutter`, and nothing above
/// this layer changes. Authorization checks live in the implementations — in
/// Supabase they become RLS policies and `security definer` functions, so a
/// modified client still cannot approve its own loan.
library;

import '../../features/credit_score/domain/credit_scoring_engine.dart';
import '../models/models.dart';
import '../state/snapshot.dart';

abstract interface class AuthRepository {
  Future<Profile?> restoreSession();
  Future<Cooperative?> findCooperativeByInviteCode(String code);

  Future<Profile> registerMember({
    required String phone,
    required String pin,
    required String fullName,
    required String businessName,
    required String city,
    required String inviteCode,
  });

  /// Creates the cooperative and makes the caller its first admin.
  Future<Profile> registerAdmin({
    required String phone,
    required String pin,
    required String fullName,
    required String city,
    required String cooperativeName,
  });

  Future<Profile> login({required String phone, required String pin});
  Future<void> logout();

  Future<void> changePin({
    required String userId,
    required String currentPin,
    required String newPin,
  });

  Future<Profile> updateProfile(Profile profile);
}

abstract interface class SnapshotRepository {
  Future<CoopSnapshot> load(Profile me);
}

abstract interface class CooperativeRepository {
  Future<Cooperative> updateSettings(Profile admin, Cooperative updated);
  Future<Cooperative> regenerateInviteCode(Profile admin);
}

abstract interface class EnergyRepository {
  /// A second bill for the same month replaces the first; tokens accumulate.
  Future<EnergyRecord> saveRecord({
    required Profile me,
    required EnergyKind kind,
    required DateTime periodMonth,
    required double kwh,
    required int totalIdr,
    String? customerId,
    String? photoPath,
    required RecordSource source,
    String? replaceId,
  });

  Future<void> deleteRecord(Profile me, String recordId);

  Future<Appliance> saveAppliance({
    required Profile me,
    String? id,
    required String name,
    required String kind,
    required double watts,
    required double hoursPerDay,
    required int daysPerWeek,
  });

  Future<void> deleteAppliance(Profile me, String applianceId);

  Future<RoofAssessment> saveRoofAssessment(Profile me, RoofAssessment draft);
}

abstract interface class SolarRepository {
  Future<SolarHub> updateHub(Profile admin, SolarHub hub);
  Future<HubSlot> addSlot(
    Profile admin,
    String hubId,
    int startHour,
    int endHour,
  );
  Future<void> removeSlot(Profile admin, String slotId);

  Future<HubBooking> book({
    required Profile me,
    required String slotId,
    required DateTime date,
    required String applianceName,
    required double estKwh,
  });

  Future<void> setBookingStatus(
    Profile actor,
    String bookingId,
    BookingStatus status,
  );
}

abstract interface class ArisanRepository {
  Future<ArisanGroup> createGroup({
    required Profile admin,
    required String name,
    required int contributionIdr,
    required DateTime startMonth,
    required List<String> memberIdsInTurnOrder,
  });

  Future<ArisanPayment> submitContribution({
    required Profile me,
    required String groupId,
    required DateTime periodMonth,
    String? note,
  });

  Future<void> reviewPayment({
    required Profile admin,
    required String paymentId,
    required bool approve,
    String? note,
  });

  Future<ArisanPayment> recordPayout({
    required Profile admin,
    required String groupId,
    required String userId,
    required DateTime periodMonth,
  });

  Future<QuotaOffer> postQuota({
    required Profile me,
    required QuotaKind kind,
    required double kwh,
    required String slotNote,
    String? note,
  });

  /// Another member answers an open post ("Minta" on a share, "Beri" on a need).
  Future<void> respondToQuota({required Profile me, required String offerId});

  /// The post's owner accepts or declines the response.
  Future<void> settleQuota({
    required Profile me,
    required String offerId,
    required bool accept,
  });

  Future<void> cancelQuota({required Profile me, required String offerId});
}

abstract interface class LoanRepository {
  /// Recomputes the score from stored data rather than trusting the caller,
  /// then checks the request against the cooperative's policy.
  Future<LoanApplication> submit({
    required Profile me,
    required int amountIdr,
    required LoanPurpose purpose,
    required int tenorMonths,
    String? note,
  });

  Future<void> cancel({required Profile me, required String loanId});
  Future<void> startReview({required Profile admin, required String loanId});

  Future<void> approve({
    required Profile admin,
    required String loanId,
    String? note,
  });

  Future<void> reject({
    required Profile admin,
    required String loanId,
    required String reason,
  });

  Future<void> disburse({required Profile admin, required String loanId});

  Future<void> markInstallmentPaid({
    required Profile admin,
    required String installmentId,
  });
}

abstract interface class MessageRepository {
  Future<MessageThread> directThread({
    required Profile me,
    required String otherUserId,
  });

  Future<Message> send({
    required Profile me,
    required String threadId,
    required String body,
  });

  Future<void> markThreadRead({required Profile me, required String threadId});
  Future<void> markNotificationRead(Profile me, String notificationId);
  Future<void> markAllNotificationsRead(Profile me);
}

abstract interface class ScoreRepository {
  /// One snapshot per member per month, so the score screen can show which
  /// factors moved since last month.
  Future<void> recordMonthlySnapshot(Profile me, CreditScore score);
}
