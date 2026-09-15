import 'package:flutter_test/flutter_test.dart';
import 'package:ibudaya/core/demo/demo_analysis_repository.dart';
import 'package:ibudaya/core/demo/demo_bill_repository.dart';

void main() {
  setUp(() {
    DemoAnalysisRepository.clear();
  });

  tearDown(() {
    DemoAnalysisRepository.clear();
  });

  group('DemoBillRepository legacy barcode', () {
    test('finds the bundled demo entry by its exact barcode', () {
      final payload = DemoBillRepository.findByBarcode('5629123456789012');
      expect(payload, isNotNull);
      expect(payload!.current.kwh, 145);
      expect(payload.current.totalIdr, 210000);
      expect(payload.history, hasLength(3));
      expect(payload.appliances.map((a) => a.name), [
        'Oven Listrik',
        'Freezer',
        'Blender',
      ]);
    });

    test('trims surrounding whitespace from a scanned value', () {
      expect(DemoBillRepository.findByBarcode(' 5629123456789012 '), isNotNull);
    });

    test('returns null for a barcode that is not in the demo dataset', () {
      expect(DemoBillRepository.findByBarcode('0000000000000000'), isNull);
      expect(DemoBillRepository.findByBarcode('https://example.com'), isNull);
      expect(DemoBillRepository.findByBarcode(''), isNull);
    });
  });

  group('Demo Scenarios (IBUDAYA-DEMO-001, 002, 003)', () {
    test('IBUDAYA-DEMO-001 loads Energy Spike scenario', () {
      final payload = DemoBillRepository.findByBarcode('IBUDAYA-DEMO-001');
      expect(payload, isNotNull);
      expect(payload!.analysis, isNotNull);
      final analysis = payload.analysis!;
      expect(analysis.status, 'energy_spike');
      expect(analysis.title, 'Lonjakan Energi Terdeteksi');
      expect(analysis.extraCost, 45026);
      expect(analysis.contributors, hasLength(3));
      expect(analysis.contributors.first.name, 'Kulkas');
    });

    test('IBUDAYA-DEMO-002 loads Normal Usage scenario', () {
      final payload = DemoBillRepository.findByBarcode('IBUDAYA-DEMO-002');
      expect(payload, isNotNull);
      expect(payload!.analysis, isNotNull);
      final analysis = payload.analysis!;
      expect(analysis.status, 'normal');
      expect(analysis.title, 'Pemakaian Stabil');
      expect(analysis.extraCost, 162000);
      expect(analysis.contributors, hasLength(3));
      expect(analysis.contributors.first.name, 'Kulkas');
    });

    test('IBUDAYA-DEMO-003 loads Solar Hub Recommendation scenario', () {
      final payload = DemoBillRepository.findByBarcode('IBUDAYA-DEMO-003');
      expect(payload, isNotNull);
      expect(payload!.analysis, isNotNull);
      final analysis = payload.analysis!;
      expect(analysis.status, 'solar_recommendation');
      expect(analysis.title, 'Potensi Penghematan Ditemukan');
      expect(analysis.extraCost, 120000);
      expect(analysis.contributors, hasLength(3));
      expect(analysis.contributors.first.name, 'Oven Listrik');
    });
  });

  group('DemoAnalysisRepository', () {
    test('findByBarcode resolves analysis data', () {
      final analysis = DemoAnalysisRepository.findByBarcode('IBUDAYA-DEMO-001');
      expect(analysis, isNotNull);
      expect(analysis!.status, 'energy_spike');

      expect(DemoAnalysisRepository.findByBarcode('UNKNOWN-CODE'), isNull);
    });

    test('stores and clears current analysis', () {
      expect(DemoAnalysisRepository.current, isNull);
      final analysis = DemoAnalysisRepository.findByBarcode('IBUDAYA-DEMO-003');
      DemoAnalysisRepository.current = analysis;
      expect(DemoAnalysisRepository.current, isNotNull);
      expect(
        DemoAnalysisRepository.current?.title,
        'Potensi Penghematan Ditemukan',
      );

      DemoAnalysisRepository.clear();
      expect(DemoAnalysisRepository.current, isNull);
    });
  });
}
