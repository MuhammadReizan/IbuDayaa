import 'demo_bill_models.dart';
import 'demo_bill_repository.dart';

/// Repository for retrieving and holding pre-computed demo AI analysis data.
///
/// When a demo barcode (e.g. `IBUDAYA-DEMO-001`) is scanned, its analysis
/// payload is set to [current] so the analysis screen can present exact,
/// curated metrics for pitch presentations and judging sessions.
abstract final class DemoAnalysisRepository {
  /// The active demo analysis dataset, if a demo barcode was scanned.
  static DemoAnalysisData? current;

  /// Clears the active demo analysis dataset.
  static void clear() {
    current = null;
  }

  /// Finds the analysis dataset for a given barcode identifier.
  static DemoAnalysisData? findByBarcode(String barcode) {
    final payload = DemoBillRepository.findByBarcode(barcode);
    return payload?.analysis;
  }
}
