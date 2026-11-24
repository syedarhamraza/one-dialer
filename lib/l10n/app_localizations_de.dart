// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get languageName => 'Deutsch';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get dismiss => 'Schließen';

  @override
  String get dismissMenu => 'Menü schließen';

  @override
  String get share => 'Teilen';

  @override
  String get more => 'Mehr';

  @override
  String get back => 'Zurück';

  @override
  String get soon => 'Bald';

  @override
  String get all => 'Alle';

  @override
  String get selectAll => 'Alle auswählen';

  @override
  String get deselectAll => 'Keine auswählen';

  @override
  String get selectItems => 'Elemente auswählen';

  @override
  String get search => 'Suchen';

  @override
  String get searchContacts => 'Kontakte durchsuchen';

  @override
  String get clear => 'Löschen';

  @override
  String get clearSearch => 'Suche löschen';

  @override
  String get searchByVoice => 'Sprachsuche';

  @override
  String get scrollToTop => 'Nach oben';

  @override
  String dateWheelDay(String day) {
    return 'Tag $day';
  }

  @override
  String dateWheelYear(String year) {
    return 'Jahr $year';
  }

  @override
  String get navCalls => 'Anrufe';

  @override
  String get navContacts => 'Kontakte';

  @override
  String get returnToCall => 'Zurück zum Anruf';

  @override
  String get createContact => 'Kontakt erstellen';

  @override
  String get showKeypad => 'Wähltastatur einblenden';

  @override
  String get settingsLanguageHeader => 'Sprache';

  @override
  String get settingsAppLanguage => 'App-Sprache';

  @override
  String get settingsAppLanguageSubtitle => 'Ändert nur diese App';

  @override
  String get settingsLanguageSystem => 'Wie Telefon';

  @override
  String get settingsAndroidLanguage => 'Android-Spracheinstellungen';

  @override
  String get settingsAndroidLanguageSubtitle =>
      'Sprache in den Android-Einstellungen wählen';

  @override
  String get call => 'Anrufen';

  @override
  String get message => 'Nachricht';

  @override
  String get add => 'Hinzufügen';

  @override
  String get block => 'Blockieren';

  @override
  String get unblock => 'Freigeben';

  @override
  String get settings => 'Einstellungen';

  @override
  String get notes => 'Notizen';

  @override
  String get moreOptions => 'Weitere Optionen';

  @override
  String get voicemail => 'Mailbox';

  @override
  String get today => 'Heute';

  @override
  String get yesterday => 'Gestern';

  @override
  String durationHoursMinutes(String hours, String minutes) {
    return '$hours Std. $minutes Min.';
  }

  @override
  String durationMinutesSeconds(String minutes, String seconds) {
    return '$minutes Min. $seconds Sek.';
  }

  @override
  String durationSeconds(String seconds) {
    return '$seconds Sek.';
  }

  @override
  String get privateNumber => 'Private Nummer';

  @override
  String appVideo(String app) {
    return '$app-Video';
  }

  @override
  String videoCallOnApp(String app) {
    return 'Videoanruf über $app';
  }

  @override
  String callOnApp(String app) {
    return 'Anruf über $app';
  }

  @override
  String get callTypeOutgoing => 'Ausgehender Anruf';

  @override
  String get callTypeMissed => 'Entgangener Anruf';

  @override
  String get callTypeRejected => 'Abgelehnter Anruf';

  @override
  String get callTypeBlocked => 'Blockierter Anruf';

  @override
  String get callTypeVoicemail => 'Mailbox';

  @override
  String get callNotConnected => '(Nicht verbunden)';

  @override
  String get callTypeIncoming => 'Eingehender Anruf';

  @override
  String get speedDialNoNumber => 'Keine Kurzwahlnummer';

  @override
  String speedDialAssignPrompt(String digit) {
    return 'Der Taste $digit einen Kontakt zuweisen?';
  }

  @override
  String get assign => 'Zuweisen';

  @override
  String get couldNotPlaceCall => 'Anruf konnte nicht getätigt werden';

  @override
  String get keypadNumberEmpty => 'Nummer, leer. Lange drücken zum Einfügen';

  @override
  String keypadNumber(String number) {
    return 'Nummer $number';
  }

  @override
  String get keypadZeroHint => '0, lange drücken für Plus';

  @override
  String get keypadVoicemailHint => '1, lange drücken für Mailbox';

  @override
  String keypadDigitHint(String digit) {
    return '$digit, lange drücken für Kurzwahl';
  }

  @override
  String get hideKeypad => 'Wähltastatur ausblenden';

  @override
  String callWithSim(String slot, String sim) {
    return 'Mit SIM $slot anrufen, $sim';
  }

  @override
  String get keypadDeleteHint => 'Löschen, lange drücken für alles';

  @override
  String get addPause => '2-Sek.-Pause einfügen';

  @override
  String get addWait => 'Warten einfügen';

  @override
  String get sendMessage => 'Nachricht senden';

  @override
  String get speedDialNumbers => 'Kurzwahlnummern';

  @override
  String speedDialKey(String digit) {
    return 'Kurzwahl $digit';
  }

  @override
  String get speedDial => 'Kurzwahl';

  @override
  String get speedDialAssignContacts => 'Kontakte zuweisen';

  @override
  String speedDialRemoved(String name, String digit) {
    return '$name von $digit entfernt';
  }

  @override
  String get callLogs => 'Anruflisten';

  @override
  String get deleteCallHistory => 'Anrufliste löschen';

  @override
  String deleteCallsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Anrufe löschen?',
      one: 'Anruf löschen?',
    );
    return '$_temp0';
  }

  @override
  String get deleteCallsMessage =>
      'Die ausgewählten Einträge werden von diesem Telefon gelöscht.';

  @override
  String get couldNotDeleteCalls =>
      'Anrufliste konnte nicht gelöscht werden. Versuche es noch einmal.';

  @override
  String get showAllCalls => 'Alle Anrufe anzeigen';

  @override
  String get showAppCallsOnly => 'Nur App-Anrufe anzeigen';

  @override
  String get showBlockedCalls => 'Blockierte Anrufe anzeigen';

  @override
  String get hideBlockedCalls => 'Blockierte Anrufe ausblenden';

  @override
  String blockNumberTitle(String number) {
    return '$number blockieren?';
  }

  @override
  String blockNumbersTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Nummern blockieren?',
      one: '1 Nummer blockieren?',
    );
    return '$_temp0';
  }

  @override
  String get blockNumbersMessage =>
      'Du erhältst keine Anrufe von blockierten Nummern.';

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ausgewählt',
    );
    return '$_temp0';
  }

  @override
  String get recentsSetDefaultMessage =>
      'Lege Dialer als Standard-Telefon-App fest, um letzte Anrufe zu sehen';

  @override
  String get setAsDefault => 'Als Standard festlegen';

  @override
  String get recentsNoAppCalls => 'Keine App-Anrufe';

  @override
  String get recentsNoRecentCalls => 'Keine letzten Anrufe';

  @override
  String get recentsNoMissedCalls => 'Keine entgangenen Anrufe';

  @override
  String get recentsFilterMissed => 'Entgangen';

  @override
  String get addToContacts => 'Zu Kontakten hinzufügen';

  @override
  String get callDetails => 'Anrufdetails';

  @override
  String contactLabel(String label) {
    String _temp0 = intl.Intl.selectLogic(label, {
      'mobile': 'Mobil',
      'home': 'Privat',
      'work': 'Geschäftlich',
      'workMobile': 'Mobil (geschäftl.)',
      'main': 'Hauptnummer',
      'phone': 'Telefon',
      'faxHome': 'Fax (privat)',
      'faxWork': 'Fax (geschäftl.)',
      'faxOther': 'Fax (sonstige)',
      'pager': 'Pager',
      'workPager': 'Pager (geschäftl.)',
      'school': 'Schule',
      'car': 'Auto',
      'companyMain': 'Firma (Zentrale)',
      'callback': 'Rückruf',
      'assistant': 'Assistent',
      'birthday': 'Geburtstag',
      'anniversary': 'Jahrestag',
      'homepage': 'Homepage',
      'blog': 'Blog',
      'profile': 'Profil',
      'brother': 'Bruder',
      'sister': 'Schwester',
      'child': 'Kind',
      'father': 'Vater',
      'mother': 'Mutter',
      'parent': 'Elternteil',
      'friend': 'Freund',
      'manager': 'Vorgesetzter',
      'partner': 'Partner',
      'relative': 'Verwandter',
      'spouse': 'Ehepartner',
      'domesticPartner': 'Lebenspartner',
      'referredBy': 'Empfohlen von',
      'other': 'Sonstige',
    });
    return '$_temp0';
  }

  @override
  String addressLabel(String label) {
    return 'Adresse ($label)';
  }

  @override
  String get accountSamsung => 'Samsung-Konto';

  @override
  String get accountSimServiceNumbers => 'SIM-Servicenummern';

  @override
  String get accountSimCard => 'SIM-Karte';

  @override
  String get accountThisDevice => 'Dieses Gerät';

  @override
  String contactsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kontakte',
      one: '1 Kontakt',
    );
    return '$_temp0';
  }

  @override
  String get justOnce => 'Nur einmal';

  @override
  String get close => 'Schließen';

  @override
  String get ok => 'OK';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get video => 'Video';

  @override
  String get remove => 'Entfernen';

  @override
  String get custom => 'Benutzerdefiniert';

  @override
  String get allow => 'Zulassen';

  @override
  String get select => 'Auswählen';

  @override
  String get merge => 'Zusammenführen';

  @override
  String get import => 'Importieren';

  @override
  String get qrScanHint =>
      'Mit einer Handykamera scannen, um diesen Kontakt hinzuzufügen';

  @override
  String deleteContactTitle(String name) {
    return '$name löschen?';
  }

  @override
  String get deleteContactMessage =>
      'Dieser Kontakt wird von diesem Telefon und aus seinen Konten gelöscht.';

  @override
  String get shareVcf => 'vCard-Datei (VCF)';

  @override
  String get shareText => 'Text';

  @override
  String get qrCode => 'QR-Code';

  @override
  String get blockContact => 'Kontakt blockieren';

  @override
  String get unblockContact => 'Kontakt freigeben';

  @override
  String get askEveryTime => 'Jedes Mal fragen';

  @override
  String get contactNotFound => 'Kontakt nicht gefunden';

  @override
  String get addToFavourites => 'Zu Favoriten hinzufügen';

  @override
  String get removeFromFavourites => 'Aus Favoriten entfernen';

  @override
  String get defaultNumber => 'Standard';

  @override
  String get ringtone => 'Klingelton';

  @override
  String get organization => 'Arbeit';

  @override
  String get website => 'Website';

  @override
  String get simForCalls => 'SIM-Karte für Anrufe';

  @override
  String get storageLocations => 'Speicherorte';

  @override
  String get viewAll => 'Alle anzeigen';

  @override
  String get selectContact => 'Kontakt auswählen';

  @override
  String get noMatchingContacts => 'Keine passenden Kontakte';

  @override
  String get noCallsWithContact => 'Noch keine Anrufe mit diesem Kontakt';

  @override
  String get unlink => 'Trennen';

  @override
  String get unlinkAll => 'Alle trennen';

  @override
  String deleteContactsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kontakte löschen?',
      one: 'Kontakt löschen?',
    );
    return '$_temp0';
  }

  @override
  String get deleteContactsMessage =>
      'Sie werden von diesem Telefon und aus ihren Konten gelöscht.';

  @override
  String get manageContacts => 'Kontakte verwalten';

  @override
  String get contactsAccessMessage =>
      'Erlaube den Zugriff auf deine Kontakte, um sie hier zu sehen und Namen bei Anrufen anzuzeigen';

  @override
  String get alphabetIndex => 'Alphabetischer Index';

  @override
  String get createNewContact => 'Neuen Kontakt erstellen';

  @override
  String get updateExistingContact => 'Vorhandenen Kontakt aktualisieren';

  @override
  String get customLabel => 'Eigenes Label';

  @override
  String get noContactsToExport => 'Keine Kontakte zum Exportieren';

  @override
  String get couldNotOpenFile => 'Datei konnte nicht geöffnet werden';

  @override
  String get noContactsInFile => 'Keine Kontakte in dieser Datei';

  @override
  String importContactsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kontakte importieren?',
      one: '1 Kontakt importieren?',
    );
    return '$_temp0';
  }

  @override
  String importContactsMessage(String account) {
    return 'Sie werden in $account gespeichert.';
  }

  @override
  String contactsImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kontakte importiert',
      one: 'Kontakt importiert',
    );
    return '$_temp0';
  }

  @override
  String get couldNotImportContacts =>
      'Diese Kontakte konnten nicht importiert werden';

  @override
  String get display => 'Anzeige';

  @override
  String get showContactPhotos => 'Profilbild des Kontakts anzeigen';

  @override
  String get onlyContactsWithNumbers => 'Nur Kontakte mit Nummern anzeigen';

  @override
  String get contactsToDisplay => 'Anzuzeigende Kontakte';

  @override
  String get sortBy => 'Sortieren nach';

  @override
  String get firstName => 'Vorname';

  @override
  String get lastName => 'Nachname';

  @override
  String get nameFormat => 'Namensformat';

  @override
  String get firstNameFirst => 'Vorname zuerst';

  @override
  String get lastNameFirst => 'Nachname zuerst';

  @override
  String get defaultSaveLocation => 'Standard-Speicherort';

  @override
  String get phoneDefault => 'Telefonstandard';

  @override
  String get importContacts => 'Kontakte importieren';

  @override
  String get fromVcf => 'Aus einer .vcf-Datei';

  @override
  String get exportContacts => 'Kontakte exportieren';

  @override
  String get asVcf => 'Als .vcf-Datei';

  @override
  String get simContacts => 'Kontakte auf der SIM-Karte';

  @override
  String get mergeDuplicates => 'Doppelte Kontakte zusammenführen';

  @override
  String get simReadError => 'SIM-Karte konnte nicht gelesen werden';

  @override
  String get simReading => 'SIM-Karte wird gelesen…';

  @override
  String get simEmpty => 'Keine Kontakte auf der SIM-Karte';

  @override
  String get allSavedInContacts => 'Alle in Kontakten gespeichert';

  @override
  String importToContacts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count in Kontakte importieren',
    );
    return '$_temp0';
  }

  @override
  String mergeGroupTitle(String count) {
    return '$count Kontakte zusammenführen?';
  }

  @override
  String mergeGroupsTitle(String count, String groups) {
    return '$count Kontakte zu $groups zusammenführen?';
  }

  @override
  String mergeGroupMessage(String name) {
    return 'Sie werden zu einem Kontakt namens $name, mit allen Nummern und Details.';
  }

  @override
  String get mergeGroupsMessage =>
      'Jede Gruppe wird zu einem Kontakt, mit allen Nummern und Details.';

  @override
  String contactsMerged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kontakte zusammengeführt',
      one: 'Kontakte zusammengeführt',
    );
    return '$_temp0';
  }

  @override
  String get couldNotMergeContacts =>
      'Diese Kontakte konnten nicht zusammengeführt werden';

  @override
  String get noDuplicateContacts => 'Keine doppelten Kontakte';

  @override
  String mergeAll(String count) {
    return 'Alle zusammenführen ($count)';
  }

  @override
  String get recentSearches => 'Letzte Suchen';

  @override
  String get clearAll => 'Alle löschen';

  @override
  String get noResultsFound => 'Keine Ergebnisse';

  @override
  String foundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gefunden',
    );
    return '$_temp0';
  }

  @override
  String removeItem(String item) {
    return '$item entfernen';
  }

  @override
  String get done => 'Fertig';

  @override
  String get discard => 'Verwerfen';

  @override
  String get change => 'Ändern';

  @override
  String get contactReadOnly =>
      'Das Konto dieses Kontakts ist schreibgeschützt, daher kann er hier nicht geändert werden';

  @override
  String get couldNotSaveContact => 'Kontakt konnte nicht gespeichert werden';

  @override
  String alreadySavedAs(String number, String name) {
    return '$number ist bereits als $name gespeichert.';
  }

  @override
  String alreadyInContacts(String name) {
    return '$name ist bereits in deinen Kontakten.';
  }

  @override
  String get alreadyInContactsTitle => 'Bereits in Kontakten';

  @override
  String saveAnotherAnyway(String duplicate) {
    return '$duplicate Trotzdem einen weiteren Kontakt speichern?';
  }

  @override
  String get saveAnyway => 'Trotzdem speichern';

  @override
  String get saveOrDiscard => 'Änderungen speichern?';

  @override
  String get couldNotLoadContactRetry =>
      'Kontakt konnte nicht geladen werden. Erneut versuchen';

  @override
  String get email => 'E-Mail';

  @override
  String get addEmail => 'E-Mail hinzufügen';

  @override
  String get addWebsite => 'Website hinzufügen';

  @override
  String get relationships => 'Beziehungen';

  @override
  String get addRelationship => 'Beziehung hinzufügen';

  @override
  String get showLess => 'Weniger anzeigen';

  @override
  String get showMore => 'Mehr anzeigen';

  @override
  String get newContact => 'Neuer Kontakt';

  @override
  String get addToExistingContact => 'Zu Kontakt hinzufügen';

  @override
  String get editContact => 'Kontakt bearbeiten';

  @override
  String get couldNotLoadAccounts => 'Konten konnten nicht geladen werden';

  @override
  String get loadingAccounts => 'Konten werden geladen…';

  @override
  String saveToAccount(String account) {
    return 'In $account speichern';
  }

  @override
  String get profilePicture => 'Profilbild';

  @override
  String get camera => 'Kamera';

  @override
  String get selectPhotos => 'Fotos auswählen';

  @override
  String get deleteProfilePicture => 'Profilbild löschen';

  @override
  String get couldNotOpenCamera => 'Kamera konnte nicht geöffnet werden';

  @override
  String get couldNotOpenApp => 'App konnte nicht geöffnet werden';

  @override
  String get followSystem => 'Wie System';

  @override
  String get customRingtone => 'Eigener Klingelton';

  @override
  String get fromFollowingAccount => 'Aus folgendem Konto';

  @override
  String get fewerNameFields => 'Weniger Namensfelder';

  @override
  String get moreNameFields => 'Mehr Namensfelder';

  @override
  String get namePrefix => 'Namenspräfix';

  @override
  String get middleName => 'Zweiter Vorname';

  @override
  String get nameSuffix => 'Namenssuffix';

  @override
  String get name => 'Name';

  @override
  String get number => 'Nummer';

  @override
  String get workInfo => 'Arbeit';

  @override
  String get company => 'Firma';

  @override
  String get jobTitle => 'Position';

  @override
  String get department => 'Abteilung';

  @override
  String get address => 'Adresse';

  @override
  String get street => 'Straße';

  @override
  String get city => 'Ort';

  @override
  String get stateProvince => 'Bundesland/Region';

  @override
  String get postalCode => 'Postleitzahl';

  @override
  String get country => 'Land';

  @override
  String get addAddress => 'Adresse hinzufügen';

  @override
  String get importantDate => 'Wichtiges Datum';

  @override
  String get importantDates => 'Wichtige Daten';

  @override
  String get addImportantDate => 'Wichtiges Datum hinzufügen';

  @override
  String get noGroupsInAccount => 'Keine Gruppen in diesem Konto';

  @override
  String get groups => 'Gruppen';

  @override
  String get enterNumber => 'Nummer eingeben';

  @override
  String get chooseFromContacts => 'Aus Kontakten wählen';

  @override
  String get blockingNeedsScreeningRole =>
      'Lege Dialer als App für Anrufer-ID und Spam fest, um diese Anrufe zu blockieren';

  @override
  String get blockNumber => 'Nummer blockieren';

  @override
  String get phoneNumber => 'Telefonnummer';

  @override
  String get blockAndFilter => 'Blockieren & filtern';

  @override
  String get searchBlockedNumbers => 'Blockierte Nummern durchsuchen';

  @override
  String get blockingPaused => 'Blockierregeln sind pausiert';

  @override
  String get blockingPausedSubtitle =>
      'Eine andere App prüft deine Anrufe. Tippe, damit Dialer sie prüft.';

  @override
  String get blockUnknown => 'Unbekannte/private Nummern blockieren';

  @override
  String get blockUnknownSubtitle => 'Anrufer, die ihre Nummer unterdrücken';

  @override
  String get blockNonContacts =>
      'Anrufe von Nummern außerhalb der Kontakte blockieren';

  @override
  String get blockNonContactsSubtitle =>
      'Nur deine Kontakte können dich anrufen';

  @override
  String get blockedNumbers => 'Blockierte Nummern';

  @override
  String get addNumber => 'Nummer hinzufügen';

  @override
  String get noMatchingBlocked => 'Keine passenden blockierten Nummern';

  @override
  String get blockedCalls => 'Blockierte Anrufe';

  @override
  String get addCall => 'Hinzufügen';

  @override
  String get note => 'Notiz';

  @override
  String get editNote => 'Notiz bearbeiten';

  @override
  String get videoCall => 'Videoanruf (Meet)';

  @override
  String get switchToVideoCall => 'Zu Videoanruf wechseln';

  @override
  String get mute => 'Stumm';

  @override
  String get hold => 'Halten';

  @override
  String get resume => 'Fortsetzen';

  @override
  String get headset => 'Headset';

  @override
  String get speaker => 'Lautsprecher';

  @override
  String get audioPhone => 'Telefon';

  @override
  String get wiredHeadset => 'Kabel-Headset';

  @override
  String get endCall => 'Anruf beenden';

  @override
  String get end => 'Beenden';

  @override
  String get dialPad => 'Tastatur';

  @override
  String get callNote => 'Anrufnotiz';

  @override
  String get callNoteHint =>
      'Schreib etwas auf, das du dir von diesem Anruf merken willst';

  @override
  String get conferenceCall => 'Telefonkonferenz';

  @override
  String get unknown => 'Unbekannt';

  @override
  String get lineBusy => 'Besetzt';

  @override
  String get callDeclined => 'Anruf abgelehnt';

  @override
  String get callCancelled => 'Anruf abgebrochen';

  @override
  String get callFailed => 'Anruf fehlgeschlagen';

  @override
  String get callEnded => 'Anruf beendet';

  @override
  String get connected => 'Verbunden';

  @override
  String get calling => 'Wird angerufen';

  @override
  String get onHold => 'Gehalten';

  @override
  String get phoneCall => 'Telefonanruf';

  @override
  String get hdCall => 'HD-Anruf';

  @override
  String switchToOnHold(String name) {
    return 'Zu $name wechseln, gehalten';
  }

  @override
  String get switchCall => 'Wechseln';

  @override
  String get declineWithSms => 'SMS-Antwort';

  @override
  String get answer => 'Annehmen';

  @override
  String get decline => 'Ablehnen';

  @override
  String get answerVerb => 'anzunehmen';

  @override
  String get declineVerb => 'abzulehnen';

  @override
  String swipeUpDownHint(String up, String down) {
    return 'Nach oben wischen, um $up, nach unten, um $down';
  }

  @override
  String swipeUpHint(String action) {
    return 'Nach oben wischen, um $action';
  }

  @override
  String get effectsFull => 'Alle Effekte';

  @override
  String get effectsReduced => 'Weniger Effekte';

  @override
  String get effectsOff => 'Effekte aus';

  @override
  String get off => 'Aus';

  @override
  String get always => 'Immer';

  @override
  String get onlyWithHeadphones => 'Nur mit Kopfhörern';

  @override
  String get incomingCallReminders => 'Eingehende Anrufe';

  @override
  String get incomingFootnote =>
      'Gilt nur für eingehende Anrufe, während dein Gerät entsperrt ist.';

  @override
  String get banner => 'Banner';

  @override
  String get fullScreen => 'Vollbild';

  @override
  String get announceCalls => 'Eingehende Anrufe ansagen';

  @override
  String get announceCallsSubtitle =>
      'Sagt den Namen des Anrufers, während es klingelt';

  @override
  String get flashOnCall => 'Blitzbenachrichtigung';

  @override
  String get flashOnCallSubtitle =>
      'Kamerablitz blinkt, während ein Anruf klingelt';

  @override
  String get systemFlash =>
      'Dein Telefon hat eine eigene Blitzbenachrichtigung';

  @override
  String get systemFlashSubtitle =>
      'Schalte eine davon aus, sonst blinken beide. Du findest sie in den Einstellungen unter Benachrichtigungen oder Bedienungshilfen';

  @override
  String get swipeUpToAnswer => 'Zum Annehmen nach oben wischen';

  @override
  String get swipeDownToAnswer => 'Zum Annehmen nach unten wischen';

  @override
  String get answerButtons => 'Anrufbildschirm';

  @override
  String get twoButtons => '2 Tasten';

  @override
  String get oneButton => '1 Taste';

  @override
  String get answerCall => 'Anruf annehmen';

  @override
  String get callScreenEffects => 'Effekte im Anrufbildschirm';

  @override
  String get callScreenEffectsSubtitle =>
      'Glas und Leuchten im Anrufbildschirm';

  @override
  String get callScreenAnimations => 'Animationen im Anrufbildschirm';

  @override
  String get callScreenAnimationsSubtitle =>
      'Bewegung, wenn sich der Anrufbildschirm öffnet, annimmt und ändert';

  @override
  String get hideContactNumbers => 'Nummern von Kontakten ausblenden';

  @override
  String get hideContactNumbersSubtitle =>
      'Bei gespeicherten Kontakten nur den Namen im Anrufbildschirm und in Anrufe zeigen';

  @override
  String get callerPhoto => 'Foto des Anrufers';

  @override
  String get callerPhotoSubtitle =>
      'Wo das Foto eines Kontakts im Anrufbildschirm sitzt';

  @override
  String get callerPhotoSide => 'Neben dem Namen';

  @override
  String get callerPhotoStacked => 'Über dem Namen';

  @override
  String secondsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sekunden',
      one: '1 Sekunde',
    );
    return '$_temp0';
  }

  @override
  String get answerEndCalls => 'Anrufe annehmen und beenden';

  @override
  String get vibrateAnswerEnd =>
      'Vibrieren, wenn Anrufe angenommen/beendet werden';

  @override
  String get autoAnswer =>
      'Anrufe automatisch annehmen, wenn ein externes Audiogerät verbunden ist';

  @override
  String get autoAnswerSubtitle => 'Auch Bluetooth- und Kabelkopfhörer';

  @override
  String get autoAnswerDelay => 'Automatisch annehmen nach';

  @override
  String get replyWithSms => 'Mit SMS antworten';

  @override
  String get speakerDefault => 'Anrufe standardmäßig über Lautsprecher';

  @override
  String get speakerDefaultSubtitle =>
      'Gilt nicht, wenn externe Geräte verbunden sind.';

  @override
  String get quickDeclineMessage => 'Ablehnungsnachricht';

  @override
  String get quickDeclineMessages => 'Ablehnungsnachrichten';

  @override
  String get quickDeclineHint =>
      'Wird gesendet, wenn du einen Anruf mit einer Nachricht ablehnst';

  @override
  String get addMessage => 'Nachricht hinzufügen';

  @override
  String get settingNotAvailable =>
      'Dieses Telefon hat diese Einstellung nicht';

  @override
  String get notDefaultApp => 'Nicht deine Standard-Telefon-App';

  @override
  String get notDefaultAppSubtitle =>
      'Eingehende Anrufe nutzen eine andere App';

  @override
  String get notificationsOff => 'Benachrichtigungen sind aus';

  @override
  String get notificationsOffSubtitle =>
      'Du siehst keine eingehenden oder entgangenen Anrufe';

  @override
  String get fullScreenOff => 'Vollbild-Anrufe sind aus';

  @override
  String get fullScreenOffSubtitle =>
      'Eingehende Anrufe erscheinen nur als Benachrichtigung';

  @override
  String get blockingPausedShort => 'Eine andere App prüft deine Anrufe';

  @override
  String get bluetoothNamesHidden => 'Bluetooth-Namen ausgeblendet';

  @override
  String get bluetoothNamesHiddenSubtitle =>
      'Anrufe können Uhr und Ohrhörer nicht unterscheiden';

  @override
  String get fix => 'Beheben';

  @override
  String get callSettings => 'Anrufeinstellungen';

  @override
  String get needsAttention => 'Erfordert Aufmerksamkeit';

  @override
  String get callerIdentification => 'Anrufer-Identifikation';

  @override
  String get callerIdSpamApp => 'App für Anrufer-ID und Spam';

  @override
  String get carrierSettings => 'Netzbetreiber-Einstellungen';

  @override
  String get softwareUpdate => 'Software-Update';

  @override
  String get helpFeedback => 'Hilfe & Feedback';

  @override
  String get privacyPolicy => 'Datenschutzerklärung';

  @override
  String get aboutOneDialer => 'Über One Dialer';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get openDetails => 'Details öffnen';

  @override
  String get writeInKeypad => 'In Wähltastatur schreiben';

  @override
  String get tapRecentCall => 'Auf letzten Anruf tippen';

  @override
  String get chooseSimForCalls => 'Mit welcher SIM anrufen';

  @override
  String get appearance => 'Aussehen';

  @override
  String get reduceVisualEffects => 'Visuelle Effekte reduzieren';

  @override
  String get displaySize => 'Anzeigegröße';

  @override
  String get displaySizeSmall => 'Klein';

  @override
  String get displaySizeDefault => 'Standard';

  @override
  String get displaySizeLarge => 'Groß';

  @override
  String get displaySizeLarger => 'Größer';

  @override
  String get displaySizeApp => 'App';

  @override
  String get displaySizeNavBar => 'Navigationsleiste';

  @override
  String get reduceVisualEffectsSubtitle =>
      'Weniger Unschärfe läuft auf langsameren Telefonen flüssiger';

  @override
  String get callScreenEdgeGlow => 'Kantenleuchten im Anrufbildschirm';

  @override
  String get darkModeEdgeGlow => 'Leuchtstärke';

  @override
  String get edgeGlowClassic => 'Klassisch';

  @override
  String get edgeGlowSoft => 'Sanft';

  @override
  String get edgeGlowBold => 'Kräftig';

  @override
  String get glassStyle => 'Glasstil';

  @override
  String get navBarFrosted => 'Kantenleuchten';

  @override
  String get navBarLiquid => 'Flüssigglas';

  @override
  String get navBarGlass => 'Glaseffekt';

  @override
  String get navGlassPremium => 'Volle Lichtbrechung';

  @override
  String get navGlassStandard => 'Leicht';

  @override
  String get navGlassAuto => 'Automatisch';

  @override
  String get glassSettings => 'Glas & Unschärfe';

  @override
  String get splashIcon => 'App-Symbol beim Start';

  @override
  String get splashIconSubtitle =>
      'Ausschalten für einen leeren Startbildschirm, wenn dein Startbildschirm ein anderes Symbol nutzt';

  @override
  String get liquidGlassOn => 'Flüssigglas für';

  @override
  String get liquidScopeAll => 'Alles';

  @override
  String get liquidScopeControls => 'Navigationsleiste und Tasten';

  @override
  String get liquidScopeNavbar => 'Nur Navigationsleiste';

  @override
  String get glassExperimentalNote =>
      'Flüssigglas ist experimentell und der aufwendigste Stil: Es braucht noch mehr Grafikleistung als Kantenleuchten, das schon anspruchsvoll ist. Wenn das Scrollen ruckelt, versuche Nur Navigationsleiste oder Glaseffekt › Automatisch, oder wechsle zurück zu Kantenleuchten. Auf langsameren Telefonen läuft Anzeige & Effekte › Visuelle Effekte reduzieren am flüssigsten.';

  @override
  String get callsFromOtherApps => 'Anrufe aus anderen Apps';

  @override
  String get callsFromOtherAppsSubtitle =>
      'Anrufe von WhatsApp und anderen Apps in Letzte zeigen';

  @override
  String get manageContactsSubtitle =>
      'Anzeige, Speicherort, Import und Export, SIM, Duplikate';

  @override
  String get googleContactsSync => 'Google Kontakte-Synchronisierung';

  @override
  String get googleContactsSyncSubtitle =>
      'Welche Konten synchronisieren und Sicherung der Telefonkontakte';

  @override
  String get defaultApps => 'Standard-Apps';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get setupTitle => 'One Dialer als Standard-Telefon-App festlegen';

  @override
  String get setupBody =>
      'Nötig, um Anrufe zu tätigen und anzunehmen, deine Anrufliste und Kontakte zu zeigen und Nummern zu blockieren.';

  @override
  String get settingUp => 'Wird eingerichtet…';

  @override
  String get setupDisclosure =>
      'One Dialer nutzt Telefon, um Anrufe über deine SIMs zu tätigen und zu verwalten, Anrufliste für Letzte und entgangene Anrufe, Kontakte für Namen, Fotos und Suche und Benachrichtigungen für eingehende, laufende und entgangene Anrufe. Deine Anrufe, deine Anrufliste und deine Kontakte verlassen nie dein Telefon. Absturzberichte (ohne persönliche Daten) helfen, Fehler zu beheben.';

  @override
  String get installedDirectly => 'Direkt installiert';

  @override
  String get anotherAppStore => 'Anderer App-Store';

  @override
  String aboutApp(String app) {
    return 'Über $app';
  }

  @override
  String get updateAvailable => 'Update verfügbar';

  @override
  String get versionUpToDate => 'Version ist aktuell';

  @override
  String get checkForUpdates => 'Nach Updates suchen';

  @override
  String get checking => 'Wird geprüft…';

  @override
  String get version => 'Version';

  @override
  String get build => 'Build';

  @override
  String get installedFrom => 'Installiert aus';

  @override
  String get device => 'Gerät';

  @override
  String get androidVersion => 'Android-Version';

  @override
  String get openSourceLicences => 'Open-Source-Lizenzen';

  @override
  String get copyrightNotice =>
      'Copyright (C) 2026 Syed Arham Raza\nFreie Software unter der GNU General Public License v3.0';

  @override
  String get changelog => 'Änderungsprotokoll';

  @override
  String installedOn(String date) {
    return 'Installiert am $date';
  }

  @override
  String get earlierVersions => 'Frühere Versionen';

  @override
  String get aboutThisUpdate => 'Über dieses Update';

  @override
  String get reportLag => 'Ruckeln melden';

  @override
  String get reportLagMessage =>
      'Sendet aktuelle Leistungsmessungen, Bildschirm- und Aktionsnamen und Gerätedetails, um Verlangsamungen zu finden. Telefonnummern, Kontakte und Nachrichten sind nicht enthalten.';

  @override
  String get sendReport => 'Bericht senden';

  @override
  String get reportUnavailable =>
      'Melden nicht verfügbar oder gerade erst angefragt. Versuche es in einer Minute noch einmal.';

  @override
  String get reportQueued => 'Bericht in Warteschlange';

  @override
  String reportQueuedMessage(String id) {
    return 'Dein Bericht ist gespeichert und wird hochgeladen, sobald das möglich ist. Teile diese ID mit deinem Feedback:\\n\\n$id';
  }

  @override
  String get copy => 'Kopieren';

  @override
  String get paste => 'Einfügen';

  @override
  String get copyId => 'ID kopieren';

  @override
  String get reportIdCopied => 'Berichts-ID kopiert';

  @override
  String get editSpeedDial => 'Kurzwahl bearbeiten';

  @override
  String get clearNumber => 'Nummer löschen';

  @override
  String get changeNumber => 'Nummer ändern';

  @override
  String get numberCopied => 'Nummer kopiert';

  @override
  String get noEmailApp => 'Keine E-Mail-App gefunden';

  @override
  String get noBrowser => 'Kein Browser gefunden';

  @override
  String get sendFeedback => 'Feedback senden';

  @override
  String get feedbackTypeTitle => 'Worum geht es?';

  @override
  String get feedbackBug => 'Problem melden';

  @override
  String get feedbackIdea => 'Idee vorschlagen';

  @override
  String get feedbackQuestion => 'Frage stellen';

  @override
  String get developer => 'Entwickler';

  @override
  String get downloadStopped =>
      'Der Download wurde gestoppt. Versuche es erneut, wenn du verbunden bist.';

  @override
  String get couldNotInstallUpdate =>
      'Update konnte nicht installiert werden. Versuche es noch einmal.';

  @override
  String get updateCancelled =>
      'Update abgebrochen. Du kannst es jederzeit hier herunterladen.';

  @override
  String get noInternet =>
      'Keine Internetverbindung. Verbinde dich und versuche es noch einmal.';

  @override
  String get couldNotDownloadUpdate =>
      'Update konnte nicht heruntergeladen werden. Versuche es noch einmal.';

  @override
  String get softwareInformation => 'Softwareinformationen';

  @override
  String get autoDownload => 'Automatisch herunterladen';

  @override
  String get downloadAndInstall => 'Herunterladen und installieren';

  @override
  String get installAndRestart => 'Installieren und neu starten';

  @override
  String get tryAgain => 'Erneut versuchen';

  @override
  String get downloading => 'Wird heruntergeladen…';

  @override
  String get noNetwork => 'Keine Netzwerkverbindung';

  @override
  String get notFromPlay =>
      'Updates kommen über Google Play. Diese Kopie wurde nicht aus Play installiert.';

  @override
  String get notFromPlayTitle => 'Nicht aus Google Play';

  @override
  String get notFromPlayWarning =>
      'Diese Kopie wurde nicht aus Google Play installiert, bekommt daher keine Updates und wurde vielleicht verändert. Du kannst sie weiter nutzen oder die offizielle Version aus der Beta holen.';

  @override
  String get keepUsing => 'Weiter nutzen';

  @override
  String get getOfficialVersion => 'Offizielle Version holen';

  @override
  String get couldNotReachPlay => 'Google Play nicht erreichbar';

  @override
  String get softwareVersion => 'Softwareversion';

  @override
  String get closedBeta => 'Geschlossene Beta';

  @override
  String get newVersionAvailable => 'Eine neue Version ist verfügbar';

  @override
  String get autoDownloadExplainer =>
      'Wann One Dialer beim Öffnen in Google Play nach Updates sucht. Updates werden nur installiert, wenn du auf Herunterladen und installieren tippst.';

  @override
  String get autoUpdateNeverSubtitle =>
      'Nur wenn du auf Nach Updates suchen tippst';

  @override
  String get autoUpdateAlwaysSubtitle => 'Die Suche braucht sehr wenig Daten';

  @override
  String get autoUpdateNever => 'Nie';

  @override
  String get autoUpdateWifiOnly => 'Nur über WLAN';

  @override
  String get autoUpdateAlways => 'Über WLAN oder mobile Daten';

  @override
  String get displayAndEffects => 'Anzeige & Effekte';

  @override
  String get keypadAndRecents => 'Wähltastatur & Letzte';

  @override
  String get logIncoming => 'Eingehend';

  @override
  String get logOutgoing => 'Ausgehend';

  @override
  String get logMissed => 'Entgangen';

  @override
  String get logRejected => 'Abgelehnt';

  @override
  String get logBlocked => 'Blockiert';

  @override
  String logRangFor(String type, String duration) {
    return '$type (klingelte $duration)';
  }

  @override
  String get record => 'Aufnehmen';

  @override
  String get stopRecording => 'Aufnahme beenden';

  @override
  String get recordSetUpFirst => 'Aufnehmen (in Einstellungen einrichten)';

  @override
  String get recordingNow => 'Aufnahme läuft';

  @override
  String get callRecording => 'Anrufaufzeichnung';

  @override
  String get recorderApp => 'One Recorder';

  @override
  String get recorderBothSides => 'Nimmt beide Seiten deiner Anrufe auf';

  @override
  String get recorderNeedsSetup => 'Beide Seiten in One Recorder einrichten';

  @override
  String get recorderHelperStopped =>
      'Beide Seiten ist pausiert: Starte den Dienst in One Recorder';

  @override
  String get recorderUntrusted =>
      'Der Recorder funktioniert nur mit One Dialer aus Google Play. Installiere ihn aus Play oder aktualisiere beide Apps.';

  @override
  String get recordingConsentTitle => 'Bevor du aufnimmst';

  @override
  String get recordingConsentBody =>
      'Die Gesetze zur Aufnahme unterscheiden sich je nach Land, und manche verlangen die Zustimmung aller Teilnehmer. Du bist dafür verantwortlich, die andere Person zu informieren und ihre Zustimmung einzuholen. Aufnahmen bleiben auf diesem Telefon und werden nie hochgeladen.';

  @override
  String get recordingConsentAccept => 'Verstanden';

  @override
  String get recordings => 'Aufnahmen';

  @override
  String get noRecordings => 'Noch keine Aufnahmen';

  @override
  String get noRecordingsSubtitle =>
      'Tippe während eines Anrufs im Anrufbildschirm auf ⋮ › Aufnehmen';

  @override
  String get deleteAllRecordings => 'Alle Aufnahmen löschen';

  @override
  String get deleteAllRecordingsTitle => 'Alle Aufnahmen löschen?';

  @override
  String get deleteAllRecordingsMessage =>
      'Sie können nicht wiederhergestellt werden.';

  @override
  String get recordingNotSetUp => 'Anrufe werden nicht aufgenommen';

  @override
  String get recordingNotSetUpSubtitle =>
      'Automatische Aufnahme ist an, aber One Recorder ist nicht eingerichtet';

  @override
  String get rename => 'Umbenennen';

  @override
  String get star => 'Markieren';

  @override
  String get unstar => 'Markierung entfernen';

  @override
  String get filterStarred => 'Markiert';

  @override
  String get filterUnknown => 'Unbekannt';

  @override
  String get saveToPhone => 'Auf Telefon speichern';

  @override
  String get searchRecordings => 'Aufnahmen durchsuchen';

  @override
  String get renameRecording => 'Aufnahme umbenennen';

  @override
  String recordingsSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Aufnahmen in Recordings/One Dialer gespeichert',
      one: 'In Recordings/One Dialer gespeichert',
    );
    return '$_temp0';
  }

  @override
  String get recordingSaveFailed =>
      'Konnte nicht auf dem Telefon gespeichert werden';

  @override
  String deleteRecordings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Aufnahmen löschen?',
      one: 'Diese Aufnahme löschen?',
    );
    return '$_temp0';
  }

  @override
  String get noMatchingRecordings => 'Keine passenden Aufnahmen';

  @override
  String get addContact => 'Kontakt hinzufügen';

  @override
  String get autoRecord => 'Automatisch aufnehmen';

  @override
  String get autoRecordOff => 'Aus';

  @override
  String get autoRecordAll => 'Alle Anrufe';

  @override
  String get autoRecordUnknown => 'Unbekannte Nummern';

  @override
  String get autoRecordContacts => 'Ausgewählte Kontakte';

  @override
  String get recordTheseContacts => 'Aufzunehmende Kontakte';

  @override
  String get neverRecord => 'Nie aufnehmen';

  @override
  String get neverRecordSubtitle =>
      'Kontakte, die die automatische Aufnahme immer auslässt';

  @override
  String get storage => 'Speicher';

  @override
  String get storageUsed => 'Belegter Speicher';

  @override
  String get autoDelete => 'Automatisch löschen';

  @override
  String get autoDeleteSubtitle => 'Markierte Aufnahmen bleiben immer erhalten';

  @override
  String get autoDeleteNever => 'Nie';

  @override
  String autoDeleteDays(int days) {
    return 'Nach $days Tagen';
  }

  @override
  String get imeiTitle => 'IMEI';

  @override
  String get imeiUnavailable =>
      'Android lässt Apps die IMEI nicht anzeigen. Du findest sie in den Einstellungen deines Telefons unter Über das Telefon.';

  @override
  String get aboutPhone => 'Über das Telefon';

  @override
  String get glassStyleSubtitle =>
      'Flüssigglas bricht, was dahinter liegt, braucht aber mehr Energie';

  @override
  String get darkModeEdgeGlowSubtitle =>
      'Wie hell die Glaskanten im dunklen Modus leuchten';

  @override
  String get liquidGlassOnSubtitle => 'Welche Teile der App Flüssigglas nutzen';

  @override
  String get navBarGlassSubtitle =>
      'Volle Lichtbrechung sieht am besten aus; Leicht läuft auf langsameren Telefonen flüssiger';

  @override
  String get tapRecentCallSubtitle =>
      'Was passiert, wenn du in Anrufe auf einen Anruf tippst';

  @override
  String get callScreenEdgeGlowSubtitle =>
      'Wie hell die Glaskanten der Anruftasten leuchten';

  @override
  String get answerButtonsSubtitle =>
      'Wie du annimmst, Effekte, Foto des Anrufers und Hintergrund';

  @override
  String get incomingCallsSubtitle =>
      'Klingelstil, Anrufer ansagen, Blitz, Live-Update';

  @override
  String get answerEndCallsSubtitle =>
      'Automatisch annehmen, mit SMS antworten, Lautsprecher';

  @override
  String get sectionCalls => 'Anrufe';

  @override
  String get sectionMakingCalls => 'Anrufe tätigen';

  @override
  String get sectionBlocking => 'Blockieren und Anrufer-ID';

  @override
  String get sectionDisplay => 'Anzeige';

  @override
  String get sectionSystem => 'Kontakte und System';

  @override
  String get searchSettings => 'Einstellungen durchsuchen';

  @override
  String get carrierSettingsSubtitle =>
      'Rufumleitung, Anklopfen und Rufnummernanzeige';

  @override
  String get callBackground => 'Anrufhintergrund';

  @override
  String get callBackgroundAllSubtitle =>
      'Für jeden Anruf, außer ein Kontakt hat einen eigenen';

  @override
  String get callBackgroundDefault => 'Standard';

  @override
  String get callBackgroundColour => 'Farbe';

  @override
  String get callBackgroundPhoto => 'Foto';

  @override
  String get callBackgroundAurora => 'Aurora';

  @override
  String get callBackgroundAuto => 'Auto';

  @override
  String get callBackgroundAutoNote =>
      'Auto: Jeder Anrufer bekommt eigene Farben, aus seinem Kontaktfoto oder seinem Namen.';

  @override
  String get callBackgroundColourNote => 'Jeder Anruf nutzt diese Farbe.';

  @override
  String get callBackgroundChangePhoto => 'Foto ändern';

  @override
  String get callBackgroundPhotoBackupNote =>
      'Fotos werden nur auf diesem Telefon gespeichert. Um sie nach einer Neuinstallation von One Dialer oder auf einem neuen Telefon zu behalten,';

  @override
  String get callBackgroundPhotoBackupLink => 'sichere deine Einstellungen';

  @override
  String get callBackgroundSoft => 'Weichzeichnen & abdunkeln';

  @override
  String get callBackgroundSoftSubtitle =>
      'Macht das Foto hinter dem Anruf weicher';

  @override
  String get callBackgroundContactPhoto => 'Foto des Kontakts';

  @override
  String get callBackgroundContactPhotoSubtitle =>
      'Android speichert Kontaktfotos klein; wähle ein Foto für ein schärferes Bild';

  @override
  String get callBackgroundSameAsAll => 'Wie bei allen Anrufen';

  @override
  String get callBackgroundAllNote =>
      'Ein Kontakt mit eigenem Anrufhintergrund, festgelegt auf seiner Kontaktseite, nutzt stattdessen diesen.';

  @override
  String get callBackgroundContactNote =>
      'Wird für diesen Kontakt statt des Anrufhintergrunds für alle Anrufe genutzt.';

  @override
  String get backUpRestore => 'Sichern & wiederherstellen';

  @override
  String get backUpRestoreSubtitle =>
      'Einstellungen, Anrufnotizen und Anrufhintergründe, in einer Datei auf diesem Telefon';

  @override
  String get backUpNow => 'Jetzt sichern';

  @override
  String lastBackup(String time) {
    return 'Letzte Sicherung: $time';
  }

  @override
  String get backupNever => 'Noch nicht gesichert';

  @override
  String get restoreBackup => 'Wiederherstellen';

  @override
  String get restoreBackupSubtitle =>
      'Sicherungsdatei wählen; die Dateien-App öffnet Dokumente';

  @override
  String get autoBackup => 'Automatische Sicherung';

  @override
  String get backupFrequency => 'Häufigkeit';

  @override
  String get backupEveryDay => 'Täglich';

  @override
  String get backupEvery3Days => 'Alle 3 Tage';

  @override
  String get backupEveryWeek => 'Wöchentlich';

  @override
  String get backupEveryMonth => 'Monatlich';

  @override
  String get backupLocation => 'Speicherort';

  @override
  String get backupLocationNone => 'Ordner wählen; Dokumente eignet sich gut';

  @override
  String get backupFailed =>
      'Die letzte Sicherung ist fehlgeschlagen. Tippe auf Speicherort, um den Ordner neu zu wählen.';

  @override
  String get backupFootnote =>
      'Eine Sicherung enthält deine Einstellungen, Kurzwahl, Anrufnotizen und Anrufhintergründe mit ihren Fotos. Es ist eine Datei, die jede Sicherung ersetzt, daher füllt sie nie deinen Speicher. Die automatische Sicherung läuft, wenn du One Dialer öffnest oder ein Anruf endet.';

  @override
  String get backedUp => 'Gesichert';

  @override
  String get couldNotBackUp => 'Sicherung in diesen Ordner nicht möglich';

  @override
  String get importSettingsTitle => 'Einstellungen ersetzen?';

  @override
  String get importSettingsMessage =>
      'Deine Einstellungen, Kurzwahl, Anrufnotizen und Anrufhintergründe werden durch die aus der Datei ersetzt. Danach startet One Dialer neu.';

  @override
  String get importSettingsInCall =>
      'Während eines Anrufs können keine Einstellungen importiert werden';

  @override
  String get notASettingsFile =>
      'Das ist keine Einstellungsdatei von One Dialer';

  @override
  String endHeldCall(String name) {
    return 'Anruf mit $name beenden';
  }

  @override
  String get fullScreenAsk =>
      'Eingehende Anrufe erscheinen nur in der Benachrichtigungsleiste. Schalte auf der nächsten Seite Vollbild-Benachrichtigungen für One Dialer ein. Wenn es schon an aussieht, schalte es aus und wieder ein.';

  @override
  String get notNow => 'Nicht jetzt';

  @override
  String get vipCalls => 'VIP-Anrufe';

  @override
  String get vipCallsSubtitle => 'Klingeln auch bei Lautlos oder Vibration';

  @override
  String get vipRing => 'Bei Lautlos für VIPs klingeln';

  @override
  String get vipRingSubtitle =>
      'Anrufe deiner VIPs klingeln auch, wenn das Telefon auf Lautlos oder Vibration steht, danach wird zurückgeschaltet';

  @override
  String get vipFavourites => 'Favoriten einschließen';

  @override
  String get vipFavouritesSubtitle =>
      'Deine markierten Kontakte zählen als VIPs';

  @override
  String get vipContacts => 'VIP-Kontakte';

  @override
  String get vipNeedsAccess => 'VIP-Anrufe können bei Lautlos nicht klingeln';

  @override
  String get vipNeedsAccessSubtitle =>
      'Anrufprüfung und Zugriff auf Bitte nicht stören erlauben';

  @override
  String get vipDndHint =>
      'Bei aktivem Bitte nicht stören entscheidet Android, wer klingelt: Erlaube markierte Kontakte in den Einstellungen von Bitte nicht stören.';

  @override
  String get rowCallButton => 'Anruftaste in Zeilen';

  @override
  String get rowCallButtonSubtitle =>
      'Eine Anruftaste in jeder Zeile in Anrufe';

  @override
  String get swipeToCall => 'Wischen zum Anrufen oder Schreiben';

  @override
  String get swipeToCallSubtitle =>
      'Zeile nach rechts wischen zum Anrufen, nach links zum Schreiben';

  @override
  String get clearDefault => 'Standard entfernen';

  @override
  String get swipeStyle => 'Wischstil';

  @override
  String get swipeStylePill => 'Glastaste';

  @override
  String get swipeStyleFlat => 'Flach';

  @override
  String get quickCalling => 'Schnell anrufen';

  @override
  String get quickCallingSubtitle => 'Tippen, Anruftaste und Wischen in Zeilen';

  @override
  String get useRecentSim => 'Zuletzt genutzte SIM';

  @override
  String get simSameAsPhone => 'Wie Telefon';

  @override
  String alwaysSim(Object sim) {
    return 'Immer $sim';
  }

  @override
  String get keypadSimButtons => 'Zwei Anruftasten';

  @override
  String get keypadSimButtonsSubtitle =>
      'Eine für jede SIM, statt einer einzelnen Anruftaste';

  @override
  String get keypadSimButtonsOneSim => 'Nur auf Telefonen mit zwei SIMs';

  @override
  String get keypadSettings => 'Wähltastatur';

  @override
  String get keypadSettingsSubtitle => 'Zwei Anruftasten, Kurzwahl';

  @override
  String get phoneDefaultSim => 'Standard-SIM des Telefons';

  @override
  String get simRulesHint =>
      'Die eigene SIM eines Kontakts, festgelegt auf seiner Seite, hat immer Vorrang.';

  @override
  String get callButtonStyle => 'Stil der Anruftaste';

  @override
  String get callButtonTint => 'Leichte Tönung';

  @override
  String get callButtonGlyph => 'Nur Symbol';

  @override
  String get callButtonLit => 'Grüner Kreis';

  @override
  String get callsAndContactsRows => 'Zeilen in Anrufe und Kontakte';

  @override
  String get callsRows => 'Zeilen in Anrufe';

  @override
  String get tapAlreadyCalls => 'Tippen auf einen Anruf ruft schon an';

  @override
  String get simCards => 'SIM-Karten';

  @override
  String get groupByContact => 'Nach Kontakt gruppieren';

  @override
  String get dontGroupByContact => 'Nicht nach Kontakt gruppieren';

  @override
  String get keypadAndContacts => 'Wähltastatur und Kontakte';

  @override
  String get swipeToCallSim => 'Wischen zum Anrufen';

  @override
  String get sameAsKeypad => 'Wie Wähltastatur';

  @override
  String get tapSimUnused =>
      'Nur genutzt, wenn Auf letzten Anruf tippen in Schnell anrufen auf Anrufen steht';

  @override
  String get swipeSimUnused =>
      'Nur genutzt, wenn Wischen zum Anrufen in Schnell anrufen an ist';

  @override
  String get onboardingSkip => 'Überspringen';

  @override
  String get onboardingNext => 'Weiter';

  @override
  String get onboardingStart => 'Los geht’s';

  @override
  String get onboardingLookTitle => 'Mach sie zu deiner';

  @override
  String get onboardingLookBody =>
      'Wähle die Sprache der App und ob sie hell oder dunkel ist.';

  @override
  String get onboardingAnswerTitle => 'Anrufe annehmen';

  @override
  String get onboardingAnswerBody =>
      'Wähle, wie eingehende Anrufe aussehen und wie du sie annimmst.';

  @override
  String get onboardingHealthTitle => 'Bereit für Anrufe';

  @override
  String get onboardingHealthBody =>
      'Eingehende Anrufe brauchen das von Android. Tippe auf einen Punkt, um ihn zu beheben.';

  @override
  String get onboardingAllSet => 'Alles bereit';

  @override
  String get onboardingCallingTitle => 'Anrufen';

  @override
  String get onboardingCallingBody =>
      'Wähle die SIM für Anrufe und was Tippen oder Wischen auf einem Anruf bewirkt.';
}
