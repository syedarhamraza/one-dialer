# Localization

One Dialer ships in English and Italian. The Flutter UI uses Flutter's gen-l10n; the Kotlin layer's notification text uses Android string resources.

| What | Where |
| --- | --- |
| UI text (template) | `lib/l10n/app_en.arb` |
| UI text, Italian | `lib/l10n/app_it.arb` |
| Generated classes | `lib/l10n/app_localizations*.dart` (`flutter gen-l10n`, also run by `flutter pub get`/`build`) |
| Access in widgets | `context.l10n.key` (`lib/l10n/l10n.dart`) |
| Notifications, channels, call announcement, default quick replies | `android/app/src/main/res/values/strings.xml`, `values-it/strings.xml` |
| Android 13+ per-app language list | `android/app/src/main/res/xml/locales_config.xml` |

Keys are camelCase by meaning (`deleteCallsTitle`, `callTypeMissed`). Counts are ICU plurals, names and numbers are placeholders. Contact names, phone numbers, brand names (One Dialer, WhatsApp, Google Play) and internal ids (call states, audio routes, `call-N`) are never translated. Release notes (`lib/core/config/changelog.dart`) stay English.

Code without a `BuildContext` takes an `AppLocalizations` argument from its caller (`dayLabel(l10n, ...)`, `callerName(l10n, call)`, `labelDisplay(l10n, label)`), never a global lookup. Dates and times go through `intl`'s `DateFormat` with `l10n.localeName`.

## Choosing the language

Settings › General › Language:

- **App language**: Same as phone, or one of the app's languages (each named in itself, from its ARB's `languageName`). Only this app changes.
- **Android language settings**: opens Android's own page for this app (Android 13+), or the system language page on Android 10–12.

Both edit one value, `AppLanguage.kt`: Android's per-app language (`LocaleManager`) on 13+, a SharedPreferences entry below. Dart reads it through `getAppLanguage`/`setAppLanguage` into `DialerPrefs.language`, at start and on every resume of either engine, and both `MaterialApp`s set `locale` from it. Notifications read it through `AppLanguage.localized(context)`.

A switch never interrupts a call: nothing calls `Locale.setDefault`, both activities already handle `locale` config changes, and neither the engines nor `InCallService` restart. A running call screen re-renders in the new language (13+) or picks it up on its next resume (10–12); the ongoing-call notification on its next repost.

## Adding a language

1. Copy `lib/l10n/app_it.arb` to `app_xx.arb`, set `@@locale` and translate every value (`languageName` is the language's own name).
2. Copy `values-it/strings.xml` to `values-xx/strings.xml` and translate it (plurals need the language's quantities).
3. Add `<locale android:name="xx" />` to `res/xml/locales_config.xml`.

That's all: `supportedLocales`, the language picker and Android's list pick it up. `test/l10n_test.dart` fails until the ARB has every key and placeholder, `values-xx` exists and `locales_config.xml` lists it. Right-to-left languages also need a layout pass (not done yet).

## Italian glossary

Follows AOSP Dialer and Contacts: Recenti, Contatti, Tastierino, Preferiti, Chiamata persa, Chiamata in arrivo, Chiamata in uscita, Chiamata in corso, Rispondi, Rifiuta, Riaggancia (notification), Termina chiamata, Vivavoce, In attesa, Richiama, Messaggio, Blocca numero, Numero privato, Sconosciuto, Segreteria, Chiamata rapida. Strings that still need a native speaker are listed in `docs/l10n-review.md`.
