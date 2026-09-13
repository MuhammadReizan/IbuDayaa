import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/design/app_theme.dart';
import '../core/l10n/l10n.dart';
import 'router.dart';

class IbuDayaApp extends ConsumerWidget {
  const IbuDayaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(resolvedLocaleProvider);

    return AppLocalizationsProvider(
      child: MaterialApp.router(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        themeMode: ThemeMode.light,
        routerConfig: ref.watch(routerProvider),
        locale: locale,
        supportedLocales: const [Locale('id', 'ID'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
