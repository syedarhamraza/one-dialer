# Italian: strings for human review

The Italian was written to AOSP Dialer/Contacts terminology but has not been checked by a native speaker. These need one, roughly in order of risk. Keys are in `lib/l10n/app_it.arb` unless a file is named; the ones marked ★ also carry a `REVIEW:` description in `app_en.arb`.

## Legal and privacy (must be exact)

| Key | Why |
| --- | --- |
| `setupDisclosure` ★ | Google Play prominent disclosure. Must match the privacy policy and Android's Italian permission names (Telefono, Registro chiamate, Contatti, Notifiche). |
| `reportLagMessage` ★ | States what a lag report sends; must stay accurate. |
| `importContactsMessage`, `deleteContactMessage`, `deleteContactsMessage`, `deleteCallsMessage` | Describe data being removed or saved. |

## May not fit (short controls)

The UI is laid out for English lengths; check these on the phone in Italian, especially on a 360 dp screen.

| Key | English → Italian |
| --- | --- |
| `addCall` ★ | Add call → Aggiungi chiamata (in-call round button label) |
| `mute` ★ | Mute → Muto (AOSP: "Disattiva audio", too long for the button) |
| `hold` ★ / `resume` | Hold → Attesa / Riprendi |
| `soon` ★ | Soon → Presto (badge) |
| `keypadDeleteHint`, `keypadDigitHint`, `keypadZeroHint` | Screen reader only, length doesn't matter; check wording |
| `recentsFilterMissed` | Missed → Perse (filter tab) |
| `deselectAll`, `selectItems` | Deselect all → Deseleziona tutto (selection header pill, beside Annulla) / Select items → Seleziona elementi (selection title) |
| `keepUsing`, `getOfficialVersion` | Keep using → Continua a usarla / Get the official version → Scarica la versione ufficiale (one-time sideload warning buttons, side by side) |
| `defaultSaveLocation`, `vibrateAnswerEnd`, `autoAnswer`, `speakerDefault` | Long settings rows |

## Wording choices to confirm

| Key | Note |
| --- | --- |
| `calling` ★, `calling_ellipsis` (`values-it`) | "Chiamata in uscita": AOSP uses "Chiamata in corso" for both dialing and connected calls; this keeps them apart. |
| `hang_up` (`values-it`) | "Riaggancia" on the ongoing-call notification. |
| `callScreenEffectsSubtitle` ★, `effectsFull/Reduced/Off`, `reduceVisualEffects` | ColorOS design names with no AOSP equivalent. |
| `callScreenEdgeGlow`, `darkModeEdgeGlow`, `edgeGlowClassic/Soft/Bold` | "Bagliore bordi"; Tenue and Intenso for Soft and Bold. ColorOS names with no AOSP equivalent. |
| `appIcon`, `appIconGlossy`, `appIconClassic` | "Lucida" and "Classica" (feminine, agreeing with icona). |
| `settingsDialing`, `settingsPersonalisation`, `settingsGeneral`, `displayAndEffects`, `keypadAndRecents` | Settings section and page titles: Composizione, Personalizzazione, Generali, Schermo ed effetti, Tastierino e recenti. |
| `contactLabel` ★ | Contact field labels; several are gendered (Figlio, Amico) where Android's own Italian uses the masculine. |
| `contactsMerged` ★ | `=1` means one *group* merged ("Contatti uniti"). |
| `selectedCount`, `foundCount` | Masculine plural agreement (selezionati, trovati). |
| `announce_calling` (`values-it`) | Spoken by text-to-speech: "{name} ti sta chiamando". TTS speaks in the phone's TTS language, not the app's. |
| `quick_replies` (`values-it`) | Android's Italian quick responses; only shown until the user edits the list. |
| `durationHoursMinutes/MinutesSeconds/Seconds` | "1 h 2 min", "3 min 5 s" |
| `tapRecentCall`, `chooseSimForCalls` | Setting titles phrased as nouns ("Tocco su una chiamata recente"). |
| `changelog` | "Novità" rather than a literal "Registro modifiche". |
| `glassStyle`, `navBarGlass`, `navGlass*` | Display & effects rows: "Stile vetro"; "Vetro liquido", "Rifrazione completa". |
| `glassSettings`, `navBarFrosted`, `darkModeEdgeGlow`, `liquidGlassOn`, `liquidScope*`, `navGlassAuto`, `glassExperimentalNote` | Glass & blur page: "Vetro e sfocatura", "Bagliore bordi", "Intensità bagliore", "Vetro liquido su", "Tutto", "Barra e pulsanti", "Solo barra di navigazione", "Automatico", and the experimental note. |
| `logIncoming/Outgoing/Missed/Rejected/Blocked`, `logRangFor` | Contact page call history: "In entrata", "In uscita", "Persa", "Rifiutata", "Bloccata"; "Persa (ha squillato per 29 s)". |
| `record`, `stopRecording`, `recordSetUpFirst`, `recordingNow`, `callRecording`, `recorder*`, `recording*`, `recordAllCalls*`, `recordings`, `noRecordings*`, `deleteAllRecordings*` | Call recording (with One Dialer Recorder): "Registra", "Registrazione chiamate", the consent notice "Prima di registrare" / "Ho capito". The recorder app's own strings are in `companion/app/src/main/res/values-it/strings.xml`. |
