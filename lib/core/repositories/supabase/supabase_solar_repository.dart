import '../../db/row.dart';
import '../../errors.dart';
import '../../models/models.dart';
import '../repositories.dart';
import 'supabase_base.dart';

/// Hub/slot admin edits are plain RLS-checked table writes; booking and its
/// capacity/quota math run server-side in `book_slot` /
/// `set_booking_status` (`supabase/migrations`) — a modified client cannot
/// overbook a slot or skip the quota check the way it could if this repository
/// re-implemented that arithmetic locally.
class SupabaseSolarRepository extends SupabaseRepo implements SolarRepository {
  SupabaseSolarRepository(super.client);

  @override
  Future<SolarHub> updateHub(Profile admin, SolarHub hub) => guard(() async {
    if (hub.name.trim().isEmpty) {
      throw const AppException('Nama hub wajib diisi.');
    }
    if (hub.dailyCapacityKwh < 0 || hub.dailyCapacityKwh > 100000) {
      throw const AppException('Kapasitas harian tidak masuk akal.');
    }
    final row = await table('solar_hubs')
        .update({
          'name': hub.name.trim(),
          'location': hub.location.trim(),
          'daily_capacity_kwh': hub.dailyCapacityKwh,
          'weather_adm4_code': hub.weatherAdm4Code?.trim().isEmpty ?? true
              ? null
              : hub.weatherAdm4Code!.trim(),
        })
        .eq('id', hub.id)
        .select()
        .single();
    return SolarHub.fromRow(row);
  });

  @override
  Future<HubSlot> addSlot(
    Profile admin,
    String hubId,
    int startHour,
    int endHour,
  ) => guard(() async {
    if (startHour < 5 || endHour > 19 || endHour <= startHour) {
      throw const AppException('Jam slot harus di antara 05.00 dan 19.00.');
    }
    final existing = await table('hub_slots').select().eq('hub_id', hubId);
    final slots = (existing as List).cast<Map<String, dynamic>>().map(
      HubSlot.fromRow,
    );
    final overlaps = slots.any(
      (s) => startHour < s.endHour && endHour > s.startHour,
    );
    if (overlaps) {
      throw const AppException('Slot ini bertabrakan dengan slot lain.');
    }
    final row = await table('hub_slots')
        .insert({
          'hub_id': hubId,
          'start_hour': startHour,
          'end_hour': endHour,
          'sort': startHour,
        })
        .select()
        .single();
    return HubSlot.fromRow(row);
  });

  @override
  Future<void> setSlotOpen(Profile admin, String slotId, bool open) => guard(
    () => table('hub_slots').update({'is_open': open}).eq('id', slotId),
  );

  @override
  Future<void> removeSlot(Profile admin, String slotId) =>
      guard(() => table('hub_slots').delete().eq('id', slotId));

  @override
  Future<HubBooking> book({
    required Profile me,
    required String slotId,
    required DateTime date,
    required String applianceName,
    required double estKwh,
    double loadKw = 0,
  }) => guard(() async {
    // TODO(supabase-migration): book_slot needs p_load_kw and the kW check.
    final row = await client.rpc(
      'book_slot',
      params: {
        'p_slot': slotId,
        'p_date': dateOnly(date),
        'p_appliance': applianceName,
        'p_est_kwh': estKwh,
        'p_load_kw': loadKw,
      },
    );
    return HubBooking.fromRow(row as Map<String, dynamic>);
  });

  /// TODO(supabase-migration): `request_connection` doesn't exist yet in
  /// `supabase/migrations/` — this refactor only implements the QR
  /// connection-request flow against [LocalSolarRepository]. Add the SQL
  /// function (same capacity/quota checks as `book_slot`, but inserting
  /// `status = 'pendingVerification'`) when the Supabase build is wired up.
  @override
  Future<HubBooking> requestConnection({
    required Profile me,
    required String scannedCode,
    required String applianceName,
    required double estKwh,
    double loadKw = 0,
  }) => guard(() async {
    final row = await client.rpc(
      'request_connection',
      params: {
        'p_scanned_code': scannedCode,
        'p_appliance': applianceName,
        'p_est_kwh': estKwh,
        'p_load_kw': loadKw,
      },
    );
    return HubBooking.fromRow(row as Map<String, dynamic>);
  });

  /// TODO(supabase-migration): `respond_to_connection_request` doesn't
  /// exist yet — see [requestConnection].
  @override
  Future<void> respondToConnectionRequest({
    required Profile admin,
    required String bookingId,
    required bool approve,
  }) => guard(
    () => client.rpc(
      'respond_to_connection_request',
      params: {'p_booking': bookingId, 'p_approve': approve},
    ),
  );

  @override
  Future<void> setBookingStatus(
    Profile actor,
    String bookingId,
    BookingStatus status,
  ) => guard(
    () => client.rpc(
      'set_booking_status',
      params: {'p_booking': bookingId, 'p_status': status.db},
    ),
  );

  @override
  Future<Profile> setMemberHubAllocation({
    required Profile admin,
    required String memberId,
    double? allocationKwh,
  }) => guard(() async {
    if (allocationKwh != null &&
        (allocationKwh < 0 || allocationKwh > 100000)) {
      throw const AppException('Alokasi kapasitas tidak masuk akal.');
    }
    final row = await table('profiles')
        .update({'hub_allocation_kwh': allocationKwh})
        .eq('id', memberId)
        .select()
        .single();
    return Profile.fromRow(row);
  });
}
