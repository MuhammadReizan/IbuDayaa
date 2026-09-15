import 'demo_bill_models.dart';
import 'demo_payloads.dart';

/// Looks a scanned demo barcode up against the bundled dummy dataset.
///
/// The barcode carries no data itself — scanning only yields a string, which
/// this either matches to a [DemoBillPayload] or not. There is no partial
/// match and no network call; an unrecognised barcode simply returns null so
/// the caller can show "Ini bukan barcode demo IbuDaya." and stop.
abstract final class DemoBillRepository {
  static DemoBillPayload? findByBarcode(String barcode) {
    final cleaned = barcode.trim().toUpperCase();
    if (cleaned.isEmpty) return null;

    // Direct match first
    if (demoPayloads.containsKey(cleaned)) {
      return DemoBillPayload.fromMap(demoPayloads[cleaned]!);
    }

    // Substring match in case of URL or surrounding text in QR code
    for (final entry in demoPayloads.entries) {
      if (cleaned.contains(entry.key.toUpperCase())) {
        return DemoBillPayload.fromMap(entry.value);
      }
    }

    return null;
  }

  /// Returns the human-readable scenario name for debugging and presentation.
  static String scenarioNameOf(DemoBillPayload? payload) {
    if (payload?.analysis == null) return 'Default / Unknown';
    switch (payload!.analysis!.status) {
      case 'energy_spike':
        return 'Energy Spike';
      case 'normal':
        return 'Normal Usage';
      case 'solar_recommendation':
        return 'Solar Hub Opportunity';
      default:
        return payload.analysis!.status;
    }
  }
}
