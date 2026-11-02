import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// `MaterialApp.locale` for the saved language (`DialerPrefs.language`): null follows the system.
Locale? appLocale(String tag) => tag == 'system' ? null : Locale(tag.split(RegExp('[-_]')).first);
