import '../../../core/demo/demo_repository.dart';
import '../../../core/demo/demo_scenario.dart';
import '../domain/profile_repository.dart';

/// Demo Mode implementation — reads straight from the in-memory scenario.
class DemoProfileRepository implements ProfileRepository {
  DemoProfileRepository(this._demo);

  final DemoRepository _demo;

  @override
  DemoUser currentUser() => _demo.current.user;
}
