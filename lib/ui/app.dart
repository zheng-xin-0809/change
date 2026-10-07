import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app_controller.dart';
import 'pages.dart';

/// Chinese Android locales (including region variants) use zh. All other
/// languages fall back to English. A null app locale follows system changes.
Locale resolveSupportedLocale(
  List<Locale>? locales,
  Iterable<Locale> supported,
) {
  final language = locales?.isNotEmpty == true
      ? locales!.first.languageCode
      : 'en';
  return Locale(language == 'zh' ? 'zh' : 'en');
}

class FitNotesApp extends StatelessWidget {
  const FitNotesApp({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: controller.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeListResolutionCallback: resolveSupportedLocale,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF166A58),
          surface: const Color(0xFFF5F6F3),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F6F3),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F6F3),
          scrolledUnderElevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ),
      home: controller.ready
          ? AppShell(controller: controller)
          : _Startup(controller: controller),
    ),
  );
}

class _Startup extends StatelessWidget {
  const _Startup({required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (controller.startupFailed) ...[
                  const Icon(Icons.folder_off_outlined, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    l.startupFailed,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(l.startupFailedBody),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: controller.initialize,
                    child: Text(l.retry),
                  ),
                ] else ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(l.loading),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
