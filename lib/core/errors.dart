/// A failure the user should read. [message] is written in plain Indonesian
/// and shown as-is, so it must say what went wrong and what to do next.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}
