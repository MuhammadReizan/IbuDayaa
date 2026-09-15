/// Demo QR payloads untuk fitur Scan QR Solar Panel.
///
/// Setiap entry diidentifikasi oleh ID panel yang terpasang dalam QR code.
/// Repository ini adalah satu-satunya sumber data untuk fitur demo;
/// tidak ada koneksi server atau API eksternal.
///
/// Untuk menambah QR demo baru, cukup tambahkan entry baru di sini.
const Map<String, Map<String, dynamic>> solarQrPayloads = {
  'IBUDAYA-SOLAR-001': {
    'panel_id': 'IBUDAYA-SOLAR-001',
    'location': 'Solar Hub Balai Melati',
    'status': 'healthy',
    'sun_exposure': 'excellent',
    'roof_area': 62,
    'roof_slope': 28,
    'roi_years': 3.2,
    'accuracy': 92,
    'monthly_saving': 280000,
    'recommendation': true,
  },
  'IBUDAYA-SOLAR-002': {
    'panel_id': 'IBUDAYA-SOLAR-002',
    'location': 'Solar Hub Kenanga',
    'status': 'warning',
    'sun_exposure': 'good',
    'roof_area': 40,
    'roof_slope': 19,
    'roi_years': 4.8,
    'accuracy': 88,
    'monthly_saving': 180000,
    'recommendation': true,
  },
  'IBUDAYA-SOLAR-003': {
    'panel_id': 'IBUDAYA-SOLAR-003',
    'location': 'Solar Hub Mawar',
    'status': 'poor',
    'sun_exposure': 'low',
    'roof_area': 18,
    'roof_slope': 8,
    'roi_years': 9.5,
    'accuracy': 80,
    'monthly_saving': 50000,
    'recommendation': false,
  },
};
