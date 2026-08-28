import '../../../core/demo/demo_scenario.dart';

/// Example feature repository interface (docs/ARCHITECTURE.md §4).
///
/// Demonstrates the layering the rest of the app follows: the presentation layer
/// depends on this abstraction, never on `DemoRepository` / the data source
/// directly. A future `RemoteProfileRepository` would implement the same
/// interface without any UI change.
abstract interface class ProfileRepository {
  DemoUser currentUser();
}
