# Translations: strings for human review

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
| `speaker`, `speaker_off` (`values-it`) | "Vivavoce" / "Disattiva vivavoce", the Speaker button on the ongoing-call notification. |
| `callScreenEffectsSubtitle` ★, `effectsFull/Reduced/Off`, `reduceVisualEffects` | ColorOS design names with no AOSP equivalent. |
| `callScreenEdgeGlow`, `darkModeEdgeGlow`, `edgeGlowClassic/Soft/Bold` | "Bagliore bordi"; Tenue and Intenso for Soft and Bold. ColorOS names with no AOSP equivalent. |
| `onboardingSkip`, `onboardingNext`, `onboardingStart`, `onboardingLookTitle/Body`, `onboardingAnswerTitle/Body`, `onboardingCallingTitle/Body`, `onboardingHealthTitle/Body`, `onboardingAllSet` | First-run onboarding: Salta / Avanti / Inizia, "Personalizzala", "Pronta per le chiamate" (feminine: l'app). |
| `settingsDialing`, `settingsPersonalisation`, `settingsGeneral`, `displayAndEffects`, `keypadAndRecents` | Settings section and page titles: Composizione, Personalizzazione, Generali, Schermo ed effetti, Tastierino e recenti. |
| `contactLabel` ★ | Contact field labels; several are gendered (Figlio, Amico) where Android's own Italian uses the masculine. |
| `feedbackTypeTitle`, `feedbackBug`, `feedbackIdea`, `feedbackQuestion` | Send feedback's chooser: Di cosa si tratta? / Segnala un problema / Suggerisci un'idea / Fai una domanda. |
| `callBackgroundSoft`, `callBackgroundSoftSubtitle`, `callBackgroundAuto`, `callBackgroundAutoNote`, `callBackgroundColourNote`, `callBackgroundChangePhoto` | "Sfoca e scurisci" / "Ammorbidisce la foto dietro la chiamata": the call background's Blur & dim switch. Automatico / Cambia foto: the aurora's Auto colour and the photo row. |
| `callBackgroundPhotoBackupNote`, `callBackgroundPhotoBackupLink` | One sentence split in two: the note, then the tappable link that exports settings. Check it still reads as one sentence. |
| `backUpRestore`, `autoBackup`, `backupFootnote` and the other `backup*` keys | Settings › Backup e ripristino; "backup" kept as Android's Italian uses it. |
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
| `record`, `stopRecording`, `recordSetUpFirst`, `recordingNow`, `callRecording`, `recorder*`, `recording*`, `recordAllCalls*`, `recordings`, `noRecordings*`, `deleteAllRecordings*` | Call recording (with One Recorder): "Registra", "Registrazione chiamate", the consent notice "Prima di registrare" / "Ho capito". The recorder app's own strings are in `companion/app/src/main/res/values-it/strings.xml`. |
| `autoRecord*`, `neverRecord*`, `recordTheseContacts`, `volumeBoost*`, `boost*`, `micSource*`, `autoDelete*`, `storage*`, `saveToPhone`, `recordingsSaved`, `deleteRecordings`, `star`, `unstar`, `filterStarred`, `filterUnknown`, `rename*`, `searchRecordings`, `noMatchingRecordings`, `addContact` | Recordings v2: "Registrazione automatica", "Non registrare mai", "Amplificazione volume", "Sorgente microfono", "Eliminazione automatica"; "Speciali" for starred, as Android's Italian contacts. |
| `*Subtitle` hints (`glassStyle`, `darkModeEdgeGlow`, `liquidGlassOn`, `navBarGlass`, `tapRecentCall`, `callScreenEdgeGlow`, `answerButtons`, `carrierSettings`) | One-line Settings summaries under the row titles; "Leggero" and "Rifrazione completa" must match the `navGlass*` choices. |
| `callBackground*` | Call screen: "Sfondo chiamata", "Foto del contatto", "Come tutte le chiamate", "Predefinito", "Colore", "Foto", "Scegli foto". |
| `vip*` | VIP calls: "Chiamate VIP", "Squillo in Silenzioso per i VIP", "Includi preferiti"; `vipDndHint` names Android's Do Not Disturb starred-contacts option ("contatti speciali"). |
| `splashIcon*` | Display & effects: "Icona app all'avvio" (the launch splash's icon switch). |
| `blocklist*`, `allowlist*`, `blockCalls`, `blockByPrefix`, `numberPrefix`, `startsWith`, `removeFromBlocklist/Allowlist`, `noNumbers`, `none` | Block & filter: "Lista bloccati" / "Lista consentiti" (ColorOS's Italian may say "Lista nera" / "Lista bianca"), "Blocca per prefisso". |
| `mergeDuplicatedNames/Numbers`, `manuallyMergeDuplicates`, `mergeManually`, `manualMergingDetails`, `nameRequired`, `numbersSelectMany`, `mergeDeletesNumbers`, `sameNumberContacts`, `sameNameContacts`, `groupCount`, `searchContactNumbers` | Merge duplicates and the number picker: "Unisci manualmente", "Dettagli unione manuale", "Numero (puoi sceglierne più di uno)". |

## Russian, Spanish, Turkish, German

Written to each language's AOSP Dialer and Contacts terms (glossaries in `docs/localization.md`), not yet checked by native speakers. Check in this order:

| Key | Why |
| --- | --- |
| `setupDisclosure`, `reportLagMessage` | Google Play prominent disclosure and what a lag report sends: must match the privacy policy and Android's own permission names in each language (Russian quotes them: «Телефон», «Журнал звонков», «Контакты», «Уведомления»). |
| `recordingConsentBody` and One Recorder's `consent_*`, `setup_consent` (`companion/.../values-xx`) | Legal wording about recording consent. |
| `importContactsMessage`, `deleteContactMessage`, `deleteContactsMessage`, `deleteCallsMessage` | Describe data being removed or saved. |
| `mute`, `hold`, `addCall`, `speaker` | Under round in-call buttons: shortened (de Stumm, Halten, Hinzufügen; ru Без звука, Удержать, Добавить; es Silenciar, Retener, Añadir). |
| Russian plurals (`deleteCallsTitle`, `contactsCount`, `recordingsSaved`, `autoDeleteDays`...) and `missed_calls` (`values-ru`) | one/few/many forms; 1 reads "1 вызов" rather than a number-less singular. |
| Turkish messages with a name or number | Suffixes can't attach to a placeholder, so they are rephrased ("{name} silinsin mi?", "Kaldır: {item}", "Aramayı bitir: {name}"). Check they read naturally. |
| `contactLabel` | Gendered relation labels (de Freund, Verwandter; es Hijo/a, Amigo/a; ru Друг, Родственник). |
| `answerVerb`, `declineVerb`, `swipeUpHint`, `swipeUpDownHint` | Screen-reader hint built from a verb: de "um anzunehmen", tr "yanıtlamak için". |
| `sameAsKeypad` | Shortened to fit as a grey value: "Wie Wähltastatur", "Как на клавиатуре". |
| `quick_replies` (`values-xx`) | Android's default quick responses in each language; only shown until edited. |
| `announce_calling` (`values-xx`) | Spoken by text-to-speech in the phone's TTS language. |

| `onboarding*`, `feedbackTypeTitle`, `feedbackBug`, `feedbackIdea`, `feedbackQuestion` | First-run pages and the feedback type picker, added after the four languages; de "Los geht’s", ru "Под себя". |
| One Recorder's `off_wifi*`, `pair_again*`, `setup_helper_connect_failed`, `setup_helper_debugging_off`, `setup_helper_no_wifi`, `stopped_*` | Wi-Fi and pairing messages; they name Android's Developer options rows (Build number, Wireless debugging), which must match each language's own Settings. |
| One Recorder's `logs_*` | Setup › Logs and report: "log" is it Log, ru Журнал, es Registro, tr Günlük, de Protokoll; GitHub's "issue" is it segnalazione, ru запрос, es incidencia, tr kayıt, de Issue. |
| `supportOneDialer`, `supportIntro`, `leaveATip`, `tipSmall`, `tipMedium`, `tipLarge`, `tipsLoading`, `tipsUnavailable`, `tipThanks`, `tipPending`, `tipFailed` | Settings › Support One Dialer (Google Play tips); `supportIntro` says tips unlock nothing and the app stays free, which must stay accurate. |
