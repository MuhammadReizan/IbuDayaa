import 'solar_panel_model.dart';
import 'solar_qr_payloads.dart';

/// Mapping URL QR fisik → internal panel ID.
///
/// QR fisik yang dicetak di lapangan mengandung URL shortener (mis. me-qr.com).
/// Mapping ini menerjemahkan URL tersebut ke panel ID yang tersimpan di
/// [solarQrPayloads].
///
/// Untuk menambah QR demo baru:
///   1. Tambahkan panel ID + payload di [solarQrPayloads].
///   2. Tambahkan URL → panel ID di [qrUrlMappings].
const Map<String, String> qrUrlMappings = {
  // Solar Hub Balai Melati — IBUDAYA-SOLAR-001
  'https://q.me-qr.com/6vovs0mu': 'IBUDAYA-SOLAR-001',
  'https://q.me-qr.com/6VOVS0MU': 'IBUDAYA-SOLAR-001',

  // Solar Hub Kenanga — IBUDAYA-SOLAR-002
  'https://q.me-qr.com/abc123': 'IBUDAYA-SOLAR-002',
  'https://q.me-qr.com/ABC123': 'IBUDAYA-SOLAR-002',

  // Solar Hub Mawar — IBUDAYA-SOLAR-003
  'https://q.me-qr.com/xyz456': 'IBUDAYA-SOLAR-003',
  'https://q.me-qr.com/XYZ456': 'IBUDAYA-SOLAR-003',
};

/// Mencocokkan string QR yang discan ke [SolarPanelData] dari payload lokal.
///
/// Strategi resolusi (berurutan):
///   1. URL mapping  — QR berisi URL shortener → resolve ke panel ID.
///   2. Direct match — QR berisi panel ID langsung ("IBUDAYA-SOLAR-001").
///   3. Substring    — QR berisi URL/teks yang mengandung panel ID.
///
/// Untuk menambah QR demo baru, tambahkan entry di [solarQrPayloads] dan
/// (jika QR fisik berupa URL) di [qrUrlMappings].
abstract final class SolarPanelRepository {
  /// Cari [SolarPanelData] berdasarkan string yang discan dari QR.
  ///
  /// Kembalikan null jika tidak ada yang cocok — caller menampilkan snackbar.
  static SolarPanelData? findByQr(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // ── 1. URL mapping (case-insensitive) ──────────────────────────────────
    // QR fisik biasanya berisi URL shortener. Cocokkan terlebih dahulu.
    final lowerRaw = trimmed.toLowerCase();
    for (final entry in qrUrlMappings.entries) {
      if (lowerRaw == entry.key.toLowerCase()) {
        final panelId = entry.value;
        debugLog('[SOLAR-SCAN] URL matched → Panel ID: $panelId');
        return _loadById(panelId);
      }
    }

    // Partial URL match — menangani kasus URL dengan query string/fragment.
    for (final entry in qrUrlMappings.entries) {
      if (lowerRaw.contains(entry.key.toLowerCase())) {
        final panelId = entry.value;
        debugLog('[SOLAR-SCAN] URL partial match → Panel ID: $panelId');
        return _loadById(panelId);
      }
    }

    // ── 2. Direct panel ID match (case-insensitive) ─────────────────────────
    final upperId = trimmed.toUpperCase();
    if (solarQrPayloads.containsKey(upperId)) {
      debugLog('[SOLAR-SCAN] Direct ID match: $upperId');
      return SolarPanelData.fromMap(solarQrPayloads[upperId]!);
    }

    // ── 3. Substring — QR berisi teks yang mengandung panel ID ─────────────
    for (final entry in solarQrPayloads.entries) {
      if (upperId.contains(entry.key)) {
        debugLog('[SOLAR-SCAN] Substring match: ${entry.key}');
        return SolarPanelData.fromMap(entry.value);
      }
    }

    return null;
  }

  /// Load [SolarPanelData] berdasarkan panel ID yang sudah diketahui.
  static SolarPanelData? _loadById(String panelId) {
    final payload = solarQrPayloads[panelId];
    if (payload == null) return null;
    return SolarPanelData.fromMap(payload);
  }

  // ignore: avoid_print
  static void debugLog(String message) => print(message);
}
