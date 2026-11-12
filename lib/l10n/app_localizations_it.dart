// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get languageName => 'Italiano';

  @override
  String get cancel => 'Annulla';

  @override
  String get save => 'Salva';

  @override
  String get delete => 'Elimina';

  @override
  String get dismiss => 'Chiudi';

  @override
  String get dismissMenu => 'Chiudi menu';

  @override
  String get share => 'Condividi';

  @override
  String get more => 'Altro';

  @override
  String get back => 'Indietro';

  @override
  String get soon => 'Presto';

  @override
  String get all => 'Tutti';

  @override
  String get selectAll => 'Seleziona tutto';

  @override
  String get deselectAll => 'Deseleziona tutto';

  @override
  String get selectItems => 'Seleziona elementi';

  @override
  String get search => 'Cerca';

  @override
  String get searchContacts => 'Cerca contatti';

  @override
  String get clear => 'Cancella';

  @override
  String get clearSearch => 'Cancella ricerca';

  @override
  String get searchByVoice => 'Ricerca vocale';

  @override
  String get scrollToTop => 'Torna su';

  @override
  String dateWheelDay(String day) {
    return 'Giorno $day';
  }

  @override
  String dateWheelYear(String year) {
    return 'Anno $year';
  }

  @override
  String get navCalls => 'Chiamate';

  @override
  String get navContacts => 'Contatti';

  @override
  String get returnToCall => 'Torna alla chiamata';

  @override
  String get createContact => 'Crea contatto';

  @override
  String get showKeypad => 'Mostra tastierino';

  @override
  String get settingsLanguageHeader => 'Lingua';

  @override
  String get settingsAppLanguage => 'Lingua dell\'app';

  @override
  String get settingsAppLanguageSubtitle => 'Cambia solo questa app';

  @override
  String get settingsLanguageSystem => 'Come il telefono';

  @override
  String get settingsAndroidLanguage => 'Impostazioni lingua di Android';

  @override
  String get settingsAndroidLanguageSubtitle =>
      'Scegli la lingua nelle impostazioni di Android';

  @override
  String get call => 'Chiama';

  @override
  String get message => 'Messaggio';

  @override
  String get add => 'Aggiungi';

  @override
  String get block => 'Blocca';

  @override
  String get unblock => 'Sblocca';

  @override
  String get settings => 'Impostazioni';

  @override
  String get notes => 'Note';

  @override
  String get moreOptions => 'Altre opzioni';

  @override
  String get voicemail => 'Segreteria';

  @override
  String get today => 'Oggi';

  @override
  String get yesterday => 'Ieri';

  @override
  String durationHoursMinutes(String hours, String minutes) {
    return '$hours h $minutes min';
  }

  @override
  String durationMinutesSeconds(String minutes, String seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String durationSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String get privateNumber => 'Numero privato';

  @override
  String appVideo(String app) {
    return 'Video $app';
  }

  @override
  String videoCallOnApp(String app) {
    return 'Videochiamata su $app';
  }

  @override
  String callOnApp(String app) {
    return 'Chiama su $app';
  }

  @override
  String get callTypeOutgoing => 'Chiamata in uscita';

  @override
  String get callTypeMissed => 'Chiamata persa';

  @override
  String get callTypeRejected => 'Chiamata rifiutata';

  @override
  String get callTypeBlocked => 'Chiamata bloccata';

  @override
  String get callTypeVoicemail => 'Segreteria';

  @override
  String get callNotConnected => '(Non connesso)';

  @override
  String get callTypeIncoming => 'Chiamata in arrivo';

  @override
  String get speedDialNoNumber => 'Nessun numero di chiamata rapida';

  @override
  String speedDialAssignPrompt(String digit) {
    return 'Assegnare un contatto al tasto $digit?';
  }

  @override
  String get assign => 'Assegna';

  @override
  String get couldNotPlaceCall => 'Impossibile effettuare la chiamata';

  @override
  String get keypadNumberEmpty => 'Numero, vuoto. Tieni premuto per incollare';

  @override
  String keypadNumber(String number) {
    return 'Numero $number';
  }

  @override
  String get keypadZeroHint => '0, tieni premuto per il segno più';

  @override
  String keypadDigitHint(String digit) {
    return '$digit, tieni premuto per la chiamata rapida';
  }

  @override
  String get hideKeypad => 'Nascondi tastierino';

  @override
  String callWithSim(String slot, String sim) {
    return 'Chiama con SIM $slot, $sim';
  }

  @override
  String get keypadDeleteHint => 'Elimina, tieni premuto per cancellare tutto';

  @override
  String get addPause => 'Aggiungi pausa di 2 sec';

  @override
  String get addWait => 'Aggiungi attesa';

  @override
  String get sendMessage => 'Invia messaggio';

  @override
  String get speedDialNumbers => 'Numeri di chiamata rapida';

  @override
  String speedDialKey(String digit) {
    return 'Chiamata rapida $digit';
  }

  @override
  String get speedDial => 'Chiamata rapida';

  @override
  String get speedDialAssignContacts => 'Assegna contatti';

  @override
  String speedDialRemoved(String name, String digit) {
    return '$name rimosso dal tasto $digit';
  }

  @override
  String get callLogs => 'Registro chiamate';

  @override
  String get deleteCallHistory => 'Elimina cronologia chiamate';

  @override
  String deleteCallsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Eliminare $count chiamate?',
      one: 'Eliminare la chiamata?',
    );
    return '$_temp0';
  }

  @override
  String get deleteCallsMessage =>
      'La cronologia chiamate selezionata verrà rimossa da questo telefono.';

  @override
  String get couldNotDeleteCalls =>
      'Impossibile eliminare la cronologia chiamate. Riprova.';

  @override
  String get showAllCalls => 'Mostra tutte le chiamate';

  @override
  String get showAppCallsOnly => 'Mostra solo chiamate da app';

  @override
  String get showBlockedCalls => 'Mostra chiamate bloccate';

  @override
  String get hideBlockedCalls => 'Nascondi chiamate bloccate';

  @override
  String blockNumberTitle(String number) {
    return 'Bloccare $number?';
  }

  @override
  String blockNumbersTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bloccare $count numeri?',
      one: 'Bloccare 1 numero?',
    );
    return '$_temp0';
  }

  @override
  String get blockNumbersMessage =>
      'Non riceverai chiamate dai numeri bloccati.';

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selezionati',
      one: '1 selezionato',
    );
    return '$_temp0';
  }

  @override
  String get recentsSetDefaultMessage =>
      'Imposta One Dialer come app Telefono predefinita per vedere le chiamate recenti';

  @override
  String get setAsDefault => 'Imposta come predefinita';

  @override
  String get recentsNoAppCalls => 'Nessuna chiamata da app';

  @override
  String get recentsNoRecentCalls => 'Nessuna chiamata recente';

  @override
  String get recentsNoMissedCalls => 'Nessuna chiamata persa';

  @override
  String get recentsFilterMissed => 'Perse';

  @override
  String get addToContacts => 'Aggiungi ai contatti';

  @override
  String get callDetails => 'Dettagli chiamata';

  @override
  String contactLabel(String label) {
    String _temp0 = intl.Intl.selectLogic(label, {
      'mobile': 'Cellulare',
      'home': 'Casa',
      'work': 'Lavoro',
      'workMobile': 'Cellulare lavoro',
      'main': 'Principale',
      'phone': 'Telefono',
      'faxHome': 'Fax casa',
      'faxWork': 'Fax lavoro',
      'faxOther': 'Altro fax',
      'pager': 'Cercapersone',
      'workPager': 'Cercapersone lavoro',
      'school': 'Scuola',
      'car': 'Auto',
      'companyMain': 'Azienda principale',
      'callback': 'Richiamata',
      'assistant': 'Assistente',
      'birthday': 'Compleanno',
      'anniversary': 'Anniversario',
      'homepage': 'Home page',
      'blog': 'Blog',
      'profile': 'Profilo',
      'brother': 'Fratello',
      'sister': 'Sorella',
      'child': 'Figlio',
      'father': 'Padre',
      'mother': 'Madre',
      'parent': 'Genitore',
      'friend': 'Amico',
      'manager': 'Responsabile',
      'partner': 'Partner',
      'relative': 'Parente',
      'spouse': 'Coniuge',
      'domesticPartner': 'Convivente',
      'referredBy': 'Presentato da',
      'other': 'Altro',
    });
    return '$_temp0';
  }

  @override
  String addressLabel(String label) {
    return 'Indirizzo ($label)';
  }

  @override
  String get accountSamsung => 'Account Samsung';

  @override
  String get accountSimServiceNumbers => 'Numeri di servizio SIM';

  @override
  String get accountSimCard => 'Scheda SIM';

  @override
  String get accountThisDevice => 'Questo dispositivo';

  @override
  String contactsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contatti',
      one: '1 contatto',
    );
    return '$_temp0';
  }

  @override
  String get justOnce => 'Solo una volta';

  @override
  String get close => 'Chiudi';

  @override
  String get ok => 'OK';

  @override
  String get edit => 'Modifica';

  @override
  String get video => 'Video';

  @override
  String get remove => 'Rimuovi';

  @override
  String get custom => 'Personalizzato';

  @override
  String get allow => 'Consenti';

  @override
  String get select => 'Seleziona';

  @override
  String get merge => 'Unisci';

  @override
  String get import => 'Importa';

  @override
  String get qrScanHint =>
      'Inquadra con la fotocamera di un telefono per aggiungere questo contatto';

  @override
  String deleteContactTitle(String name) {
    return 'Eliminare $name?';
  }

  @override
  String get deleteContactMessage =>
      'Questo contatto verrà rimosso da questo telefono e dai relativi account.';

  @override
  String get shareVcf => 'File vCard (VCF)';

  @override
  String get shareText => 'Testo';

  @override
  String get qrCode => 'Codice QR';

  @override
  String get blockContact => 'Blocca contatto';

  @override
  String get unblockContact => 'Sblocca contatto';

  @override
  String get askEveryTime => 'Chiedi ogni volta';

  @override
  String get contactNotFound => 'Contatto non trovato';

  @override
  String get addToFavourites => 'Aggiungi ai preferiti';

  @override
  String get removeFromFavourites => 'Rimuovi dai preferiti';

  @override
  String get defaultNumber => 'Predefinito';

  @override
  String get ringtone => 'Suoneria';

  @override
  String get organization => 'Lavoro';

  @override
  String get website => 'Sito web';

  @override
  String get simForCalls => 'SIM per le chiamate';

  @override
  String get storageLocations => 'Posizioni di archiviazione';

  @override
  String get viewAll => 'Visualizza tutto';

  @override
  String get selectContact => 'Seleziona contatto';

  @override
  String get noMatchingContacts => 'Nessun contatto corrispondente';

  @override
  String get noCallsWithContact =>
      'Ancora nessuna chiamata con questo contatto';

  @override
  String get unlink => 'Scollega';

  @override
  String get unlinkAll => 'Scollega tutti';

  @override
  String deleteContactsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Eliminare $count contatti?',
      one: 'Eliminare il contatto?',
    );
    return '$_temp0';
  }

  @override
  String get deleteContactsMessage =>
      'Verranno rimossi da questo telefono e dai relativi account.';

  @override
  String get manageContacts => 'Gestisci contatti';

  @override
  String get contactsAccessMessage =>
      'Consenti l\'accesso ai contatti per vederli qui e mostrare i nomi nelle chiamate';

  @override
  String get alphabetIndex => 'Indice alfabetico';

  @override
  String get createNewContact => 'Crea nuovo contatto';

  @override
  String get updateExistingContact => 'Aggiorna contatto esistente';

  @override
  String get customLabel => 'Etichetta personalizzata';

  @override
  String get noContactsToExport => 'Nessun contatto da esportare';

  @override
  String get couldNotOpenFile => 'Impossibile aprire il file';

  @override
  String get noContactsInFile => 'Nessun contatto in questo file';

  @override
  String importContactsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importare $count contatti?',
      one: 'Importare 1 contatto?',
    );
    return '$_temp0';
  }

  @override
  String importContactsMessage(String account) {
    return 'Verranno salvati in $account.';
  }

  @override
  String contactsImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contatti importati',
      one: 'Contatto importato',
    );
    return '$_temp0';
  }

  @override
  String get couldNotImportContacts => 'Impossibile importare questi contatti';

  @override
  String get display => 'Visualizzazione';

  @override
  String get showContactPhotos => 'Mostra l\'immagine del profilo dei contatti';

  @override
  String get onlyContactsWithNumbers => 'Mostra solo i contatti con numero';

  @override
  String get contactsToDisplay => 'Contatti da visualizzare';

  @override
  String get sortBy => 'Ordina per';

  @override
  String get firstName => 'Nome';

  @override
  String get lastName => 'Cognome';

  @override
  String get nameFormat => 'Formato nome';

  @override
  String get firstNameFirst => 'Prima il nome';

  @override
  String get lastNameFirst => 'Prima il cognome';

  @override
  String get defaultSaveLocation => 'Posizione di salvataggio predefinita';

  @override
  String get phoneDefault => 'Predefinita del telefono';

  @override
  String get importContacts => 'Importa contatti';

  @override
  String get fromVcf => 'Da un file .vcf';

  @override
  String get exportContacts => 'Esporta contatti';

  @override
  String get asVcf => 'Come file .vcf';

  @override
  String get simContacts => 'Contatti della SIM';

  @override
  String get mergeDuplicates => 'Unisci contatti duplicati';

  @override
  String get simReadError => 'Impossibile leggere la SIM';

  @override
  String get simReading => 'Lettura della SIM…';

  @override
  String get simEmpty => 'Nessun contatto sulla SIM';

  @override
  String get allSavedInContacts => 'Tutti salvati in Contatti';

  @override
  String importToContacts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importa $count in Contatti',
    );
    return '$_temp0';
  }

  @override
  String mergeGroupTitle(String count) {
    return 'Unire $count contatti?';
  }

  @override
  String mergeGroupsTitle(String count, String groups) {
    return 'Unire $count contatti in $groups?';
  }

  @override
  String mergeGroupMessage(String name) {
    return 'Diventeranno un unico contatto di nome $name, con tutti i numeri e i dettagli.';
  }

  @override
  String get mergeGroupsMessage =>
      'Ogni gruppo diventerà un unico contatto, con tutti i numeri e i dettagli.';

  @override
  String contactsMerged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contatti uniti',
      one: 'Contatti uniti',
    );
    return '$_temp0';
  }

  @override
  String get couldNotMergeContacts => 'Impossibile unire questi contatti';

  @override
  String get noDuplicateContacts => 'Nessun contatto duplicato';

  @override
  String mergeAll(String count) {
    return 'Unisci tutti ($count)';
  }

  @override
  String get recentSearches => 'Ricerche recenti';

  @override
  String get clearAll => 'Cancella tutto';

  @override
  String get noResultsFound => 'Nessun risultato';

  @override
  String foundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trovati',
      one: '1 trovato',
    );
    return '$_temp0';
  }

  @override
  String removeItem(String item) {
    return 'Rimuovi $item';
  }

  @override
  String get done => 'Fine';

  @override
  String get discard => 'Ignora';

  @override
  String get change => 'Cambia';

  @override
  String get contactReadOnly =>
      'L\'account di questo contatto è di sola lettura, quindi non può essere modificato qui';

  @override
  String get couldNotSaveContact => 'Impossibile salvare il contatto';

  @override
  String alreadySavedAs(String number, String name) {
    return '$number è già salvato come $name.';
  }

  @override
  String alreadyInContacts(String name) {
    return '$name è già nei tuoi contatti.';
  }

  @override
  String get alreadyInContactsTitle => 'Già nei contatti';

  @override
  String saveAnotherAnyway(String duplicate) {
    return '$duplicate Salvare comunque un altro contatto?';
  }

  @override
  String get saveAnyway => 'Salva comunque';

  @override
  String get saveOrDiscard => 'Salvare le modifiche?';

  @override
  String get couldNotLoadContactRetry =>
      'Impossibile caricare il contatto. Riprova';

  @override
  String get email => 'Email';

  @override
  String get addEmail => 'Aggiungi email';

  @override
  String get addWebsite => 'Aggiungi sito web';

  @override
  String get relationships => 'Relazioni';

  @override
  String get addRelationship => 'Aggiungi relazione';

  @override
  String get showLess => 'Mostra meno';

  @override
  String get showMore => 'Mostra altro';

  @override
  String get newContact => 'Nuovo contatto';

  @override
  String get addToExistingContact => 'Aggiungi a contatto esistente';

  @override
  String get editContact => 'Modifica contatto';

  @override
  String get couldNotLoadAccounts => 'Impossibile caricare gli account';

  @override
  String get loadingAccounts => 'Caricamento account…';

  @override
  String saveToAccount(String account) {
    return 'Salva in $account';
  }

  @override
  String get profilePicture => 'Immagine del profilo';

  @override
  String get camera => 'Fotocamera';

  @override
  String get selectPhotos => 'Seleziona foto';

  @override
  String get deleteProfilePicture => 'Elimina immagine del profilo';

  @override
  String get couldNotOpenCamera => 'Impossibile aprire la fotocamera';

  @override
  String get followSystem => 'Segui il sistema';

  @override
  String get customRingtone => 'Suoneria personalizzata';

  @override
  String get fromFollowingAccount => 'Dal seguente account';

  @override
  String get fewerNameFields => 'Meno campi del nome';

  @override
  String get moreNameFields => 'Più campi del nome';

  @override
  String get namePrefix => 'Prefisso nome';

  @override
  String get middleName => 'Secondo nome';

  @override
  String get nameSuffix => 'Suffisso nome';

  @override
  String get name => 'Nome';

  @override
  String get number => 'Numero';

  @override
  String get workInfo => 'Informazioni di lavoro';

  @override
  String get company => 'Azienda';

  @override
  String get jobTitle => 'Qualifica';

  @override
  String get department => 'Reparto';

  @override
  String get address => 'Indirizzo';

  @override
  String get street => 'Via';

  @override
  String get city => 'Città';

  @override
  String get stateProvince => 'Provincia';

  @override
  String get postalCode => 'CAP';

  @override
  String get country => 'Paese';

  @override
  String get addAddress => 'Aggiungi indirizzo';

  @override
  String get importantDate => 'Data importante';

  @override
  String get importantDates => 'Date importanti';

  @override
  String get addImportantDate => 'Aggiungi data importante';

  @override
  String get noGroupsInAccount => 'Nessun gruppo in questo account';

  @override
  String get groups => 'Gruppi';

  @override
  String get enterNumber => 'Inserisci numero';

  @override
  String get chooseFromContacts => 'Scegli dai contatti';

  @override
  String get blockingNeedsScreeningRole =>
      'Imposta One Dialer come app per ID chiamante e spam per bloccare queste chiamate';

  @override
  String get blockNumber => 'Blocca numero';

  @override
  String get phoneNumber => 'Numero di telefono';

  @override
  String get blockAndFilter => 'Blocca e filtra';

  @override
  String get searchBlockedNumbers => 'Cerca numeri bloccati';

  @override
  String get blockingPaused => 'Le regole di blocco sono in pausa';

  @override
  String get blockingPausedSubtitle =>
      'Un\'altra app filtra le tue chiamate. Tocca per farle filtrare a One Dialer.';

  @override
  String get blockUnknown => 'Blocca numeri sconosciuti/privati';

  @override
  String get blockUnknownSubtitle => 'Chi chiama nascondendo il proprio numero';

  @override
  String get blockNonContacts =>
      'Blocca chiamate da numeri non presenti nei contatti';

  @override
  String get blockNonContactsSubtitle =>
      'Solo i tuoi contatti possono chiamarti';

  @override
  String get blockedNumbers => 'Numeri bloccati';

  @override
  String get addNumber => 'Aggiungi numero';

  @override
  String get noMatchingBlocked => 'Nessun numero bloccato corrispondente';

  @override
  String get blockedCalls => 'Chiamate bloccate';

  @override
  String get addCall => 'Aggiungi chiamata';

  @override
  String get note => 'Nota';

  @override
  String get editNote => 'Modifica nota';

  @override
  String get videoCall => 'Videochiamata (Meet)';

  @override
  String get mute => 'Muto';

  @override
  String get hold => 'Attesa';

  @override
  String get resume => 'Riprendi';

  @override
  String get headset => 'Auricolari';

  @override
  String get speaker => 'Vivavoce';

  @override
  String get audioPhone => 'Telefono';

  @override
  String get wiredHeadset => 'Auricolari con cavo';

  @override
  String get endCall => 'Termina chiamata';

  @override
  String get end => 'Termina';

  @override
  String get dialPad => 'Tastierino';

  @override
  String get callNote => 'Nota chiamata';

  @override
  String get callNoteHint => 'Scrivi qualcosa da ricordare di questa chiamata';

  @override
  String get conferenceCall => 'Chiamata in conferenza';

  @override
  String get unknown => 'Sconosciuto';

  @override
  String get lineBusy => 'Linea occupata';

  @override
  String get callDeclined => 'Chiamata rifiutata';

  @override
  String get callCancelled => 'Chiamata annullata';

  @override
  String get callFailed => 'Chiamata non riuscita';

  @override
  String get callEnded => 'Chiamata terminata';

  @override
  String get connected => 'Connesso';

  @override
  String get calling => 'Chiamata in uscita';

  @override
  String get onHold => 'In attesa';

  @override
  String get phoneCall => 'Telefonata';

  @override
  String get hdCall => 'Chiamata HD';

  @override
  String switchToOnHold(String name) {
    return 'Passa a $name, in attesa';
  }

  @override
  String get switchCall => 'Passa';

  @override
  String get declineWithSms => 'Rispondi con SMS';

  @override
  String get answer => 'Rispondi';

  @override
  String get decline => 'Rifiuta';

  @override
  String get answerVerb => 'rispondere';

  @override
  String get declineVerb => 'rifiutare';

  @override
  String swipeUpDownHint(String up, String down) {
    return 'Scorri verso l\'alto per $up, verso il basso per $down';
  }

  @override
  String swipeUpHint(String action) {
    return 'Scorri verso l\'alto per $action';
  }

  @override
  String get effectsFull => 'Effetti completi';

  @override
  String get effectsReduced => 'Effetti ridotti';

  @override
  String get effectsOff => 'Effetti disattivati';

  @override
  String get off => 'Disattivato';

  @override
  String get always => 'Sempre';

  @override
  String get onlyWithHeadphones => 'Solo con le cuffie';

  @override
  String get incomingCallReminders => 'Avvisi chiamate in arrivo';

  @override
  String get incomingFootnote =>
      'Si applica solo alle chiamate ricevute quando il dispositivo è sbloccato.';

  @override
  String get banner => 'Banner';

  @override
  String get fullScreen => 'Schermo intero';

  @override
  String get announceCalls => 'Annuncia chiamate in arrivo';

  @override
  String get announceCallsSubtitle =>
      'Pronuncia il nome di chi chiama mentre squilla';

  @override
  String get liveUpdateCapsule => 'Capsula Live Update (Sperimentale)';

  @override
  String get liveUpdateCapsuleSubtitle =>
      'Android 16: mostra la chiamata in corso nel chip della barra di stato e nella capsula su ColorOS, OxygenOS e realme UI';

  @override
  String get swipeUpToAnswer => 'Scorri verso l\'alto per rispondere';

  @override
  String get swipeDownToAnswer => 'Scorri verso il basso per rispondere';

  @override
  String get answerButtons => 'Pulsanti di risposta';

  @override
  String get twoButtons => '2 pulsanti';

  @override
  String get oneButton => '1 pulsante';

  @override
  String get answerCall => 'Rispondi alla chiamata';

  @override
  String get callScreenEffects => 'Effetti schermata di chiamata';

  @override
  String get callScreenEffectsSubtitle =>
      'Vetro e bagliore nella schermata di chiamata';

  @override
  String get callScreenAnimations => 'Animazioni schermata di chiamata';

  @override
  String get callScreenAnimationsSubtitle =>
      'Movimento quando la schermata di chiamata si apre, risponde e cambia';

  @override
  String get hideContactNumbers => 'Nascondi i numeri dei contatti';

  @override
  String get hideContactNumbersSubtitle =>
      'Mostra solo il nome dei contatti salvati nella schermata di chiamata e in Chiamate';

  @override
  String secondsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count secondi',
      one: '1 secondo',
    );
    return '$_temp0';
  }

  @override
  String get answerEndCalls => 'Risposta/fine chiamate';

  @override
  String get vibrateAnswerEnd =>
      'Vibra quando le chiamate vengono accettate o terminate';

  @override
  String get autoAnswer =>
      'Rispondi automaticamente con un dispositivo audio esterno collegato';

  @override
  String get autoAnswerSubtitle => 'Include cuffie Bluetooth e con cavo';

  @override
  String get autoAnswerDelay => 'Ritardo risposta automatica';

  @override
  String get replyWithSms => 'Rispondi con SMS';

  @override
  String get speakerDefault => 'Vivavoce predefinito per le chiamate';

  @override
  String get speakerDefaultSubtitle =>
      'Non ha effetto quando sono collegati dispositivi esterni.';

  @override
  String get quickDeclineMessage => 'Messaggio di rifiuto rapido';

  @override
  String get quickDeclineMessages => 'Messaggi di rifiuto rapido';

  @override
  String get quickDeclineHint =>
      'Inviato quando rifiuti una chiamata con un messaggio';

  @override
  String get addMessage => 'Aggiungi messaggio';

  @override
  String get settingNotAvailable =>
      'Questo telefono non ha questa impostazione';

  @override
  String get notDefaultApp => 'Non è l\'app Telefono predefinita';

  @override
  String get notDefaultAppSubtitle =>
      'Le chiamate in arrivo usano un\'altra app';

  @override
  String get notificationsOff => 'Le notifiche sono disattivate';

  @override
  String get notificationsOffSubtitle =>
      'Non vedrai le chiamate in arrivo o perse';

  @override
  String get fullScreenOff => 'Le chiamate a schermo intero sono disattivate';

  @override
  String get fullScreenOffSubtitle =>
      'Le chiamate in arrivo appaiono solo come notifica';

  @override
  String get blockingPausedShort => 'Un\'altra app filtra le tue chiamate';

  @override
  String get bluetoothNamesHidden => 'Nomi Bluetooth nascosti';

  @override
  String get bluetoothNamesHiddenSubtitle =>
      'Le chiamate non distinguono l\'orologio dagli auricolari';

  @override
  String get fix => 'Risolvi';

  @override
  String get callSettings => 'Impostazioni chiamate';

  @override
  String get needsAttention => 'Richiede attenzione';

  @override
  String get callerIdentification => 'Identificazione chiamante';

  @override
  String get callerIdSpamApp => 'App ID chiamante e spam';

  @override
  String get carrierSettings => 'Impostazioni dell\'operatore';

  @override
  String get softwareUpdate => 'Aggiornamento software';

  @override
  String get helpFeedback => 'Guida e feedback';

  @override
  String get privacyPolicy => 'Informativa sulla privacy';

  @override
  String get aboutOneDialer => 'Informazioni su One Dialer';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';

  @override
  String get openDetails => 'Apri dettagli';

  @override
  String get writeInKeypad => 'Scrivi nel tastierino';

  @override
  String get twoCallButtons => 'Due pulsanti Chiama';

  @override
  String get chooseSimAndCall => 'Scegli SIM e chiama';

  @override
  String get tapRecentCall => 'Tocco su una chiamata recente';

  @override
  String get chooseSimForCalls => 'Scelta SIM per le chiamate';

  @override
  String get chooseSimSubtitle => 'Doppia SIM senza SIM predefinita';

  @override
  String get appearance => 'Aspetto';

  @override
  String get reduceVisualEffects => 'Riduci effetti visivi';

  @override
  String get displaySize => 'Dimensioni schermo';

  @override
  String get displaySizeSmall => 'Piccole';

  @override
  String get displaySizeDefault => 'Predefinite';

  @override
  String get displaySizeLarge => 'Grandi';

  @override
  String get displaySizeLarger => 'Più grandi';

  @override
  String get displaySizeApp => 'App';

  @override
  String get displaySizeNavBar => 'Barra di navigazione';

  @override
  String get reduceVisualEffectsSubtitle =>
      'Meno sfocatura, più fluidità sui telefoni lenti';

  @override
  String get appIcon => 'Icona dell\'app';

  @override
  String get appIconGlossy => 'Lucida';

  @override
  String get appIconClassic => 'Classica';

  @override
  String get appIconFootnote =>
      'Cambia sia l\'icona di Telefono sia quella di Contatti. Il launcher può impiegare qualche secondo e le icone nella schermata Home potrebbero dover essere aggiunte di nuovo dal cassetto delle app.';

  @override
  String get callScreenEdgeGlow => 'Bagliore bordi nella chiamata';

  @override
  String get darkModeEdgeGlow => 'Intensità bagliore';

  @override
  String get edgeGlowClassic => 'Classico';

  @override
  String get edgeGlowSoft => 'Tenue';

  @override
  String get edgeGlowBold => 'Intenso';

  @override
  String get glassStyle => 'Stile vetro';

  @override
  String get navBarFrosted => 'Bagliore bordi';

  @override
  String get navBarLiquid => 'Vetro liquido';

  @override
  String get navBarGlass => 'Effetto vetro';

  @override
  String get navGlassPremium => 'Rifrazione completa';

  @override
  String get navGlassStandard => 'Leggero';

  @override
  String get navGlassAuto => 'Automatico';

  @override
  String get glassSettings => 'Vetro e sfocatura';

  @override
  String get liquidGlassOn => 'Vetro liquido su';

  @override
  String get liquidScopeAll => 'Tutto';

  @override
  String get liquidScopeControls => 'Barra e pulsanti';

  @override
  String get liquidScopeNavbar => 'Solo barra di navigazione';

  @override
  String get glassExperimentalNote =>
      'Il vetro liquido è sperimentale ed è lo stile più pesante: richiede ancora più potenza grafica del Bagliore bordi, già impegnativo. Se lo scorrimento scatta, prova Solo barra di navigazione o Effetto vetro › Automatico, oppure torna a Bagliore bordi. Sui telefoni meno potenti, Schermo ed effetti › Riduci effetti visivi è la scelta più fluida.';

  @override
  String get callsFromOtherApps => 'Chiamate da altre app';

  @override
  String get callsFromOtherAppsSubtitle =>
      'Mostra in Recenti le chiamate di WhatsApp e di altre app';

  @override
  String get manageContactsSubtitle =>
      'Visualizzazione, salvataggio, importazione ed esportazione, SIM, duplicati';

  @override
  String get googleContactsSync => 'Sincronizzazione Contatti Google';

  @override
  String get googleContactsSyncSubtitle =>
      'Account da sincronizzare e backup dei contatti del telefono';

  @override
  String get defaultApps => 'App predefinite';

  @override
  String get notifications => 'Notifiche';

  @override
  String get setupTitle => 'Imposta One Dialer come app Telefono predefinita';

  @override
  String get setupBody =>
      'Serve per fare e ricevere chiamate, mostrare cronologia e contatti e bloccare numeri.';

  @override
  String get settingUp => 'Configurazione…';

  @override
  String get setupDisclosure =>
      'One Dialer usa Telefono per effettuare e gestire le chiamate sulle tue SIM, Registro chiamate per Recenti e chiamate perse, Contatti per nomi, foto e ricerca, e Notifiche per chiamate in arrivo, in corso e perse. Chiamate, cronologia e contatti non lasciano mai il telefono. I rapporti sugli arresti anomali (senza dati personali) aiutano a correggere i bug.';

  @override
  String get installedDirectly => 'Installata direttamente';

  @override
  String get anotherAppStore => 'Un altro store di app';

  @override
  String aboutApp(String app) {
    return 'Informazioni su $app';
  }

  @override
  String get updateAvailable => 'Aggiornamento disponibile';

  @override
  String get versionUpToDate => 'Versione aggiornata';

  @override
  String get checkForUpdates => 'Verifica aggiornamenti';

  @override
  String get checking => 'Verifica in corso…';

  @override
  String get version => 'Versione';

  @override
  String get build => 'Build';

  @override
  String get installedFrom => 'Installata da';

  @override
  String get device => 'Dispositivo';

  @override
  String get androidVersion => 'Versione di Android';

  @override
  String get openSourceLicences => 'Licenze open source';

  @override
  String get changelog => 'Novità';

  @override
  String installedOn(String date) {
    return 'Installata il $date';
  }

  @override
  String get earlierVersions => 'Versioni precedenti';

  @override
  String get aboutThisUpdate => 'Informazioni su questo aggiornamento';

  @override
  String get reportLag => 'Segnala rallentamenti';

  @override
  String get reportLagMessage =>
      'Invia i tempi di prestazione recenti, i nomi di schermate e azioni e i dettagli del dispositivo per aiutare a trovare i rallentamenti. Numeri di telefono, contatti e messaggi non sono inclusi.';

  @override
  String get sendReport => 'Invia segnalazione';

  @override
  String get reportUnavailable =>
      'Segnalazione non disponibile o già richiesta di recente. Riprova tra un minuto.';

  @override
  String get reportQueued => 'Segnalazione in coda';

  @override
  String reportQueuedMessage(String id) {
    return 'La segnalazione è salvata e verrà caricata quando possibile. Condividi questo ID con il tuo feedback:\\n\\n$id';
  }

  @override
  String get copy => 'Copia';

  @override
  String get paste => 'Incolla';

  @override
  String get copyId => 'Copia ID';

  @override
  String get reportIdCopied => 'ID segnalazione copiato';

  @override
  String get editSpeedDial => 'Modifica chiamata rapida';

  @override
  String get clearNumber => 'Cancella numero';

  @override
  String get changeNumber => 'Cambia numero';

  @override
  String get numberCopied => 'Numero copiato';

  @override
  String get noEmailApp => 'Nessuna app email trovata';

  @override
  String get noBrowser => 'Nessun browser trovato';

  @override
  String get sendFeedback => 'Invia feedback';

  @override
  String get developer => 'Sviluppatore';

  @override
  String get downloadStopped =>
      'Il download si è interrotto. Riprova quando sei connesso.';

  @override
  String get couldNotInstallUpdate =>
      'Impossibile installare l\'aggiornamento. Riprova.';

  @override
  String get updateCancelled =>
      'Aggiornamento annullato. Puoi scaricarlo in qualsiasi momento da qui.';

  @override
  String get noInternet =>
      'Nessuna connessione a Internet. Connettiti e riprova.';

  @override
  String get couldNotDownloadUpdate =>
      'Impossibile scaricare l\'aggiornamento. Riprova.';

  @override
  String get softwareInformation => 'Informazioni software';

  @override
  String get autoDownload => 'Download automatico';

  @override
  String get downloadAndInstall => 'Scarica e installa';

  @override
  String get installAndRestart => 'Installa e riavvia';

  @override
  String get tryAgain => 'Riprova';

  @override
  String get downloading => 'Download in corso…';

  @override
  String get noNetwork => 'Nessuna connessione di rete';

  @override
  String get notFromPlay =>
      'Gli aggiornamenti arrivano da Google Play. Questa copia non è stata installata da Play.';

  @override
  String get notFromPlayTitle => 'Non da Google Play';

  @override
  String get notFromPlayWarning =>
      'Questa copia non è stata installata da Google Play, quindi non riceverà aggiornamenti e potrebbe essere stata modificata. Puoi continuare a usarla o scaricare la versione ufficiale dalla beta.';

  @override
  String get keepUsing => 'Continua a usarla';

  @override
  String get getOfficialVersion => 'Scarica la versione ufficiale';

  @override
  String get couldNotReachPlay => 'Impossibile raggiungere Google Play';

  @override
  String get softwareVersion => 'Versione software';

  @override
  String get closedBeta => 'Beta chiusa';

  @override
  String get newVersionAvailable => 'È disponibile una nuova versione';

  @override
  String get autoDownloadExplainer =>
      'Quando One Dialer controlla gli aggiornamenti su Google Play all\'apertura. Gli aggiornamenti si installano solo quando tocchi Scarica e installa.';

  @override
  String get autoUpdateNeverSubtitle =>
      'Solo quando tocchi Verifica aggiornamenti';

  @override
  String get autoUpdateAlwaysSubtitle => 'La verifica usa pochissimi dati';

  @override
  String get autoUpdateNever => 'Mai';

  @override
  String get autoUpdateWifiOnly => 'Solo con Wi-Fi';

  @override
  String get autoUpdateAlways => 'Con Wi-Fi o dati mobili';

  @override
  String get displayAndEffects => 'Schermo ed effetti';

  @override
  String get keypadAndRecents => 'Tastierino e recenti';

  @override
  String get logIncoming => 'In entrata';

  @override
  String get logOutgoing => 'In uscita';

  @override
  String get logMissed => 'Persa';

  @override
  String get logRejected => 'Rifiutata';

  @override
  String get logBlocked => 'Bloccata';

  @override
  String logRangFor(String type, String duration) {
    return '$type (ha squillato per $duration)';
  }

  @override
  String get record => 'Registra';

  @override
  String get stopRecording => 'Interrompi registrazione';

  @override
  String get recordSetUpFirst => 'Registra (configura in Impostazioni)';

  @override
  String get recordingNow => 'Registrazione in corso';

  @override
  String get callRecording => 'Registrazione chiamate';

  @override
  String get recorderApp => 'One Dialer Recorder';

  @override
  String get recorderReady => 'Pronto per registrare';

  @override
  String get recorderNeedsMic => 'Consenti il microfono in One Dialer Recorder';

  @override
  String get recorderNeedsAccessibility =>
      'Attiva il suo servizio di accessibilità';

  @override
  String get recorderUntrusted =>
      'Il registratore funziona solo con One Dialer da Google Play. Installalo da Play o aggiorna entrambe le app.';

  @override
  String get recordingConsentTitle => 'Prima di registrare';

  @override
  String get recordingConsentBody =>
      'Le leggi sulla registrazione variano da paese a paese e alcune richiedono il consenso di tutti i partecipanti alla chiamata. Sei responsabile di informare l\'altra persona e di ottenere il suo consenso. Le registrazioni restano su questo telefono e non vengono mai caricate.';

  @override
  String get recordingConsentAccept => 'Ho capito';

  @override
  String get recordings => 'Registrazioni';

  @override
  String get noRecordings => 'Ancora nessuna registrazione';

  @override
  String get noRecordingsSubtitle =>
      'Durante una chiamata tocca ⋮ › Registra nella schermata di chiamata';

  @override
  String get deleteAllRecordings => 'Elimina tutte le registrazioni';

  @override
  String get deleteAllRecordingsTitle => 'Eliminare tutte le registrazioni?';

  @override
  String get deleteAllRecordingsMessage => 'Non potranno essere recuperate.';

  @override
  String get recordingNotSetUp => 'Le chiamate non vengono registrate';

  @override
  String get recordingNotSetUpSubtitle =>
      'La registrazione automatica è attiva, ma One Dialer Recorder non è configurato';

  @override
  String get rename => 'Rinomina';

  @override
  String get star => 'Aggiungi a speciali';

  @override
  String get unstar => 'Rimuovi da speciali';

  @override
  String get filterStarred => 'Speciali';

  @override
  String get filterUnknown => 'Sconosciuti';

  @override
  String get saveToPhone => 'Salva sul telefono';

  @override
  String get searchRecordings => 'Cerca registrazioni';

  @override
  String get renameRecording => 'Rinomina registrazione';

  @override
  String recordingsSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registrazioni salvate in Recordings/One Dialer',
      one: 'Salvata in Recordings/One Dialer',
    );
    return '$_temp0';
  }

  @override
  String get recordingSaveFailed => 'Impossibile salvare sul telefono';

  @override
  String deleteRecordings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Eliminare $count registrazioni?',
      one: 'Eliminare questa registrazione?',
    );
    return '$_temp0';
  }

  @override
  String get noMatchingRecordings => 'Nessuna registrazione corrispondente';

  @override
  String get addContact => 'Aggiungi contatto';

  @override
  String get autoRecord => 'Registrazione automatica';

  @override
  String get autoRecordOff => 'Disattivata';

  @override
  String get autoRecordAll => 'Tutte le chiamate';

  @override
  String get autoRecordUnknown => 'Numeri sconosciuti';

  @override
  String get autoRecordContacts => 'Contatti selezionati';

  @override
  String get recordTheseContacts => 'Contatti da registrare';

  @override
  String get neverRecord => 'Non registrare mai';

  @override
  String get neverRecordSubtitle =>
      'Contatti sempre esclusi dalla registrazione automatica';

  @override
  String get recordingSound => 'Audio';

  @override
  String get volumeBoost => 'Amplificazione volume';

  @override
  String get volumeBoostSubtitle =>
      'Alza la voce dell\'altra persona, che il microfono sente appena';

  @override
  String get boostOff => 'Disattivata';

  @override
  String get boostNormal => 'Normale';

  @override
  String get boostStrong => 'Forte';

  @override
  String get micSource => 'Sorgente microfono';

  @override
  String get micSourceSubtitle =>
      'Automatica prova ciascuna alla prima chiamata e tiene la più forte';

  @override
  String get micSourceAuto => 'Automatica';

  @override
  String get micSourceRecognition => 'Riconoscimento vocale';

  @override
  String get micSourceCommunication => 'Comunicazione vocale';

  @override
  String get micSourceMic => 'Microfono';

  @override
  String get storage => 'Spazio';

  @override
  String get storageUsed => 'Spazio occupato';

  @override
  String get autoDelete => 'Eliminazione automatica';

  @override
  String get autoDeleteSubtitle =>
      'Le registrazioni speciali vengono sempre conservate';

  @override
  String get autoDeleteNever => 'Mai';

  @override
  String autoDeleteDays(int days) {
    return 'Dopo $days giorni';
  }

  @override
  String get imeiTitle => 'IMEI';

  @override
  String get imeiUnavailable =>
      'Android non consente alle app di mostrare l\'IMEI. Puoi trovarlo nelle impostazioni del telefono, in Info sul telefono.';

  @override
  String get aboutPhone => 'Info sul telefono';

  @override
  String get glassStyleSubtitle =>
      'Il vetro liquido piega ciò che sta dietro, ma consuma di più';

  @override
  String get darkModeEdgeGlowSubtitle =>
      'Quanto brillano i bordi del vetro in modalità scura';

  @override
  String get liquidGlassOnSubtitle =>
      'Quali parti dell\'app usano il vetro liquido';

  @override
  String get navBarGlassSubtitle =>
      'Rifrazione completa è più bella; Leggero è più fluido sui telefoni lenti';

  @override
  String get tapRecentCallSubtitle =>
      'Cosa succede quando tocchi una chiamata in Chiamate';

  @override
  String get callScreenEdgeGlowSubtitle =>
      'Quanto brillano i bordi di vetro dei pulsanti di chiamata';

  @override
  String get answerButtonsSubtitle =>
      'Come rispondi e l\'aspetto della schermata di chiamata';

  @override
  String get carrierSettingsSubtitle =>
      'Trasferimento, avviso di chiamata e ID chiamante';

  @override
  String get callBackground => 'Sfondo chiamata';

  @override
  String get callBackgroundAllSubtitle =>
      'Per ogni chiamata, salvo i contatti che ne hanno uno proprio';

  @override
  String get callBackgroundDefault => 'Predefinito';

  @override
  String get callBackgroundColour => 'Colore';

  @override
  String get callBackgroundPhoto => 'Foto';

  @override
  String get callBackgroundChoosePhoto => 'Scegli foto';

  @override
  String get callBackgroundContactPhoto => 'Foto del contatto';

  @override
  String get callBackgroundContactPhotoSubtitle =>
      'Android salva le foto dei contatti piccole; scegli una foto per una più nitida';

  @override
  String get callBackgroundSameAsAll => 'Come tutte le chiamate';

  @override
  String get callBackgroundAllNote =>
      'Un contatto con un proprio sfondo, impostato nella sua scheda, usa quello.';

  @override
  String get callBackgroundContactNote =>
      'Usato per questo contatto al posto dello sfondo per tutte le chiamate.';

  @override
  String get exportSettings => 'Esporta impostazioni';

  @override
  String get exportSettingsSubtitle =>
      'Salva impostazioni, note e sfondi delle chiamate in un file';

  @override
  String get importSettings => 'Importa impostazioni';

  @override
  String get importSettingsSubtitle => 'Ripristinale da un file esportato';

  @override
  String get importSettingsTitle => 'Sostituire le impostazioni?';

  @override
  String get importSettingsMessage =>
      'Impostazioni, chiamata rapida, note e sfondi delle chiamate vengono sostituiti da quelli del file. Poi One Dialer si riavvia.';

  @override
  String get importSettingsInCall =>
      'Non puoi importare le impostazioni durante una chiamata';

  @override
  String get settingsExported => 'Impostazioni esportate';

  @override
  String get couldNotSaveSettings => 'Impossibile salvare il file';

  @override
  String get notASettingsFile =>
      'Questo non è un file di impostazioni di One Dialer';
}
