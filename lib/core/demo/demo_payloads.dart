/// Dummy bill, appliance, and pre-computed AI analysis data for the barcode
/// demo path, keyed by unique demo identifiers (e.g. `IBUDAYA-DEMO-001`).
///
/// Every entry is looked up through [DemoBillRepository]
/// (`lib/core/demo/demo_bill_repository.dart`), never read directly by the
/// UI, so the shape stays private to this feature.
library;

const Map<String, Map<String, dynamic>> demoPayloads = {
  // CASE 1: Energy Spike
  'IBUDAYA-DEMO-001': {
    'type': 'ibudaya_demo_bill',
    'current': {'month': '2026-09', 'kwh': 145, 'total_idr': 210000},
    'history': [
      {'month': '2026-06', 'kwh': 112, 'total_idr': 161800},
      {'month': '2026-07', 'kwh': 118, 'total_idr': 170500},
      {'month': '2026-08', 'kwh': 109, 'total_idr': 157500},
    ],
    'appliances': [
      {
        'name': 'Oven Listrik',
        'kind': 'oven',
        'watts': 1500,
        'hours_per_day': 2,
        'days_per_week': 6,
      },
      {
        'name': 'Freezer',
        'kind': 'refrigerator',
        'watts': 65,
        'hours_per_day': 24,
        'days_per_week': 7,
      },
      {
        'name': 'Blender',
        'kind': 'blender',
        'watts': 350,
        'hours_per_day': 1,
        'days_per_week': 3,
      },
    ],
    'analysis': {
      'status': 'energy_spike',
      'title': 'Lonjakan Energi Terdeteksi',
      'description': 'Pemakaian tinggi jam 18.00–21.00',
      'extra_cost': 45026,
      'main_cause': 'Kulkas, oven, dan blender sering dipakai bersamaan sore hari.',
      'insight': 'Pindahkan pemakaian alat berat ke jam 10.00–14.00 agar lebih hemat.',
      'contributors': [
        {'name': 'Kulkas', 'monthly_cost': 156028, 'percentage': 100, 'kind': 'refrigerator'},
        {'name': 'Oven', 'monthly_cost': 111448, 'percentage': 72, 'kind': 'oven'},
        {'name': 'Blender', 'monthly_cost': 10835, 'percentage': 12, 'kind': 'blender'},
      ],
    },
  },

  // CASE 2: Normal Usage
  'IBUDAYA-DEMO-002': {
    'type': 'ibudaya_demo_bill',
    'current': {'month': '2026-09', 'kwh': 112, 'total_idr': 162000},
    'history': [
      {'month': '2026-06', 'kwh': 110, 'total_idr': 159000},
      {'month': '2026-07', 'kwh': 115, 'total_idr': 166000},
      {'month': '2026-08', 'kwh': 111, 'total_idr': 160000},
    ],
    'appliances': [
      {
        'name': 'Kulkas',
        'kind': 'refrigerator',
        'watts': 65,
        'hours_per_day': 24,
        'days_per_week': 7,
      },
      {
        'name': 'Kipas Angin',
        'kind': 'fan',
        'watts': 50,
        'hours_per_day': 8,
        'days_per_week': 7,
      },
      {
        'name': 'Lampu & Lainnya',
        'kind': 'other',
        'watts': 60,
        'hours_per_day': 5,
        'days_per_week': 7,
      },
    ],
    'analysis': {
      'status': 'normal',
      'title': 'Pemakaian Stabil',
      'description': 'Tidak ditemukan lonjakan pemakaian',
      'extra_cost': 162000,
      'main_cause': 'Penggunaan alat usaha stabil dan terjadwal secara merata.',
      'insight': 'Pertahankan pola pemakaian hemat energi ini.',
      'contributors': [
        {'name': 'Kulkas', 'monthly_cost': 120000, 'percentage': 65, 'kind': 'refrigerator'},
        {'name': 'Kipas Angin', 'monthly_cost': 45000, 'percentage': 25, 'kind': 'fan'},
        {'name': 'Lampu & Lainnya', 'monthly_cost': 20000, 'percentage': 10, 'kind': 'other'},
      ],
    },
  },

  // CASE 3: Solar Hub Recommendation
  'IBUDAYA-DEMO-003': {
    'type': 'ibudaya_demo_bill',
    'current': {'month': '2026-09', 'kwh': 160, 'total_idr': 232000},
    'history': [
      {'month': '2026-06', 'kwh': 140, 'total_idr': 202000},
      {'month': '2026-07', 'kwh': 145, 'total_idr': 210000},
      {'month': '2026-08', 'kwh': 142, 'total_idr': 205000},
    ],
    'appliances': [
      {
        'name': 'Oven Listrik',
        'kind': 'oven',
        'watts': 1500,
        'hours_per_day': 2.5,
        'days_per_week': 6,
      },
      {
        'name': 'Freezer',
        'kind': 'refrigerator',
        'watts': 65,
        'hours_per_day': 24,
        'days_per_week': 7,
      },
      {
        'name': 'Mixer',
        'kind': 'mixer',
        'watts': 300,
        'hours_per_day': 1.5,
        'days_per_week': 4,
      },
    ],
    'analysis': {
      'status': 'solar_recommendation',
      'title': 'Potensi Penghematan Ditemukan',
      'description': 'Disarankan menggunakan Solar Hub',
      'extra_cost': 120000,
      'main_cause': 'Pemakaian oven & freezer tinggi di siang hari.',
      'insight': 'Pindahkan pemakaian alat ke jam 10.00–14.00 agar hemat hingga Rp120.000/bln.',
      'contributors': [
        {'name': 'Oven Listrik', 'monthly_cost': 180000, 'percentage': 85, 'kind': 'oven'},
        {'name': 'Freezer', 'monthly_cost': 110000, 'percentage': 55, 'kind': 'refrigerator'},
        {'name': 'Mixer', 'monthly_cost': 35000, 'percentage': 18, 'kind': 'mixer'},
      ],
    },
  },

  // Legacy barcode alias (matches sample PLN meter sticker in pitch presentations)
  '5629123456789012': {
    'type': 'ibudaya_demo_bill',
    'current': {'month': '2026-09', 'kwh': 145, 'total_idr': 210000},
    'history': [
      {'month': '2026-06', 'kwh': 112, 'total_idr': 161800},
      {'month': '2026-07', 'kwh': 118, 'total_idr': 170500},
      {'month': '2026-08', 'kwh': 109, 'total_idr': 157500},
    ],
    'appliances': [
      {
        'name': 'Oven Listrik',
        'kind': 'oven',
        'watts': 1500,
        'hours_per_day': 2,
        'days_per_week': 6,
      },
      {
        'name': 'Freezer',
        'kind': 'refrigerator',
        'watts': 65,
        'hours_per_day': 24,
        'days_per_week': 7,
      },
      {
        'name': 'Blender',
        'kind': 'blender',
        'watts': 350,
        'hours_per_day': 1,
        'days_per_week': 3,
      },
    ],
    'analysis': {
      'status': 'energy_spike',
      'title': 'Lonjakan Energi Terdeteksi',
      'description': 'Pemakaian tinggi jam 18.00–21.00',
      'extra_cost': 45026,
      'main_cause': 'Kulkas, oven, blender sering dipakai bersamaan.',
      'insight': 'Pindahkan penggunaan alat berat ke siang hari.',
      'contributors': [
        {'name': 'Kulkas', 'monthly_cost': 156028, 'percentage': 100, 'kind': 'refrigerator'},
        {'name': 'Oven', 'monthly_cost': 111448, 'percentage': 72, 'kind': 'oven'},
        {'name': 'Blender', 'monthly_cost': 10835, 'percentage': 12, 'kind': 'blender'},
      ],
    },
  },
};
