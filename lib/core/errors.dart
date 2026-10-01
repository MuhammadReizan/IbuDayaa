/// A failure the user should read. [message] is written in plain Indonesian
/// and [en] is the same sentence in English; the UI shows whichever matches the
/// language the user chose (see [localized]). Both must say what went wrong and
/// what to do next.
class AppException implements Exception {
  const AppException(this.message, {this.en});

  final String message;
  final String? en;

  /// The message for the chosen language; Indonesian when there is no English.
  String localized({required bool english}) =>
      english ? (en ?? message) : message;

  @override
  String toString() => message;
}
