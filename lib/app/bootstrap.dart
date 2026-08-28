import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../core/error/app_error_box.dart';
import 'app.dart';

/// App entry point. Sets up locale data, app-level error handling, and the
/// `ProviderScope`, then runs the app. See docs/ARCHITECTURE.md §8.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Indonesian date formatting symbols (number formatting needs no init).
  await initializeDateFormatting('id_ID');

  // Calm placeholder instead of the default red/grey error rectangle.
  ErrorWidget.builder = (FlutterErrorDetails details) =>
      AppErrorBox(details: details);

  // Framework errors: log (debug console) but keep the app running so a
  // friendly surface can be shown rather than a hard crash.
  final FlutterExceptionHandler? previousOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    previousOnError?.call(details);
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  };

  runZonedGuarded(() => runApp(const ProviderScope(child: IbuDayaApp())), (
    Object error,
    StackTrace stack,
  ) {
    debugPrint('Uncaught error: $error\n$stack');
  });
}
