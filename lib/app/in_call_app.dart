import 'package:flutter/material.dart';

import '../core/diagnostics/lag_diagnostics.dart';

import '../core/prefs/dialer_prefs.dart';
import '../features/in_call/call_controls.dart';
import '../features/in_call/in_call_screen.dart';
import '../l10n/l10n.dart';
import '../theme/one_ui_theme.dart';
import 'layout.dart';

class InCallApp extends StatelessWidget {
  const InCallApp({super.key});
  static final _diagnosticsObserver = DiagnosticsNavigatorObserver();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: DialerPrefs.instance.language,
      builder: (context, language, _) => MaterialApp(
        locale: appLocale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        navigatorObservers: [_diagnosticsObserver],
        debugShowCheckedModeBanner: false,
        theme: OneUITheme.darkTheme,
        scrollBehavior: const MaterialScrollBehavior(), // the call screen holds still
        builder: (context, child) => DesignWidth(child: child!),
        home: CallEffects(child: const InCallScreen()),
      ),
    );
  }
}
