import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/data/app_data_controller.dart';
import '../core/data/derived_providers.dart';
import '../core/design/app_theme.dart';
import 'router.dart';

/// Root widget: a single Material 3 light theme, Indonesian locale, and the
/// GoRouter config. No business logic lives here.
class IbuDayaApp extends ConsumerWidget {
  const IbuDayaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Always-active listeners above the Navigator. Without them, screens that
    // Riverpod pauses behind a route transition come back dirty and get
    // flushed mid-build, which trips a setState-during-build assertion.
    // `listen` rather than `watch`: keep them warm, don't rebuild MaterialApp.
    ref.listen(appDataProvider, (_, _) {});
    keepDerivedProvidersWarm(ref);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      themeMode: ThemeMode.light,
      routerConfig: router,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
