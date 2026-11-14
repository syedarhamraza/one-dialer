// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageName => 'English';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get dismissMenu => 'Dismiss menu';

  @override
  String get share => 'Share';

  @override
  String get more => 'More';

  @override
  String get back => 'Back';

  @override
  String get soon => 'Soon';

  @override
  String get all => 'All';

  @override
  String get selectAll => 'Select all';

  @override
  String get deselectAll => 'Deselect all';

  @override
  String get selectItems => 'Select items';

  @override
  String get search => 'Search';

  @override
  String get searchContacts => 'Search contacts';

  @override
  String get clear => 'Clear';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get searchByVoice => 'Search by voice';

  @override
  String get scrollToTop => 'Scroll to top';

  @override
  String dateWheelDay(String day) {
    return 'Day $day';
  }

  @override
  String dateWheelYear(String year) {
    return 'Year $year';
  }

  @override
  String get navCalls => 'Calls';

  @override
  String get navContacts => 'Contacts';

  @override
  String get returnToCall => 'Return to call';

  @override
  String get createContact => 'Create contact';

  @override
  String get showKeypad => 'Show keypad';

  @override
  String get settingsLanguageHeader => 'Language';

  @override
  String get settingsAppLanguage => 'App language';

  @override
  String get settingsAppLanguageSubtitle => 'Only changes this app';

  @override
  String get settingsLanguageSystem => 'Same as phone';

  @override
  String get settingsAndroidLanguage => 'Android language settings';

  @override
  String get settingsAndroidLanguageSubtitle =>
      'Choose the language in Android\'s settings';

  @override
  String get call => 'Call';

  @override
  String get message => 'Message';

  @override
  String get add => 'Add';

  @override
  String get block => 'Block';

  @override
  String get unblock => 'Unblock';

  @override
  String get settings => 'Settings';

  @override
  String get notes => 'Notes';

  @override
  String get moreOptions => 'More options';

  @override
  String get voicemail => 'Voicemail';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String durationHoursMinutes(String hours, String minutes) {
    return '$hours hr $minutes min';
  }

  @override
  String durationMinutesSeconds(String minutes, String seconds) {
    return '$minutes min $seconds sec';
  }

  @override
  String durationSeconds(String seconds) {
    return '$seconds sec';
  }

  @override
  String get privateNumber => 'Private number';

  @override
  String appVideo(String app) {
    return '$app video';
  }

  @override
  String videoCallOnApp(String app) {
    return 'Video call on $app';
  }

  @override
  String callOnApp(String app) {
    return 'Call on $app';
  }

  @override
  String get callTypeOutgoing => 'Outgoing call';

  @override
  String get callTypeMissed => 'Missed call';

  @override
  String get callTypeRejected => 'Rejected call';

  @override
  String get callTypeBlocked => 'Blocked call';

  @override
  String get callTypeVoicemail => 'Voicemail';

  @override
  String get callNotConnected => '(Not connected)';

  @override
  String get callTypeIncoming => 'Incoming call';

  @override
  String get speedDialNoNumber => 'No speed dial number';

  @override
  String speedDialAssignPrompt(String digit) {
    return 'Assign a contact to key $digit?';
  }

  @override
  String get assign => 'Assign';

  @override
  String get couldNotPlaceCall => 'Couldn\'t place the call';

  @override
  String get keypadNumberEmpty => 'Number, empty. Long-press to paste';

  @override
  String keypadNumber(String number) {
    return 'Number $number';
  }

  @override
  String get keypadZeroHint => '0, long-press for plus';

  @override
  String keypadDigitHint(String digit) {
    return '$digit, long-press for speed dial';
  }

  @override
  String get hideKeypad => 'Hide keypad';

  @override
  String callWithSim(String slot, String sim) {
    return 'Call with SIM $slot, $sim';
  }

  @override
  String get keypadDeleteHint => 'Delete, long-press to clear';

  @override
  String get addPause => 'Add 2-sec pause';

  @override
  String get addWait => 'Add wait';

  @override
  String get sendMessage => 'Send message';

  @override
  String get speedDialNumbers => 'Speed dial numbers';

  @override
  String speedDialKey(String digit) {
    return 'Speed dial $digit';
  }

  @override
  String get speedDial => 'Speed dial';

  @override
  String get speedDialAssignContacts => 'Assign contacts';

  @override
  String speedDialRemoved(String name, String digit) {
    return 'Removed $name from $digit';
  }

  @override
  String get callLogs => 'Call logs';

  @override
  String get deleteCallHistory => 'Delete call history';

  @override
  String deleteCallsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count calls?',
      one: 'Delete call?',
    );
    return '$_temp0';
  }

  @override
  String get deleteCallsMessage =>
      'The selected call history will be removed from this phone.';

  @override
  String get couldNotDeleteCalls => 'Couldn\'t delete call history. Try again.';

  @override
  String get showAllCalls => 'Show all calls';

  @override
  String get showAppCallsOnly => 'Show app calls only';

  @override
  String get showBlockedCalls => 'Show blocked calls';

  @override
  String get hideBlockedCalls => 'Hide blocked calls';

  @override
  String blockNumberTitle(String number) {
    return 'Block $number?';
  }

  @override
  String blockNumbersTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Block $count numbers?',
      one: 'Block 1 number?',
    );
    return '$_temp0';
  }

  @override
  String get blockNumbersMessage =>
      'You won\'t get calls from blocked numbers.';

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
    );
    return '$_temp0';
  }

  @override
  String get recentsSetDefaultMessage =>
      'Set Dialer as your default phone app to see recent calls';

  @override
  String get setAsDefault => 'Set as default';

  @override
  String get recentsNoAppCalls => 'No app calls';

  @override
  String get recentsNoRecentCalls => 'No recent calls';

  @override
  String get recentsNoMissedCalls => 'No missed calls';

  @override
  String get recentsFilterMissed => 'Missed';

  @override
  String get addToContacts => 'Add to Contacts';

  @override
  String get callDetails => 'Call details';

  @override
  String contactLabel(String label) {
    String _temp0 = intl.Intl.selectLogic(label, {
      'mobile': 'Mobile',
      'home': 'Home',
      'work': 'Work',
      'workMobile': 'Work mobile',
      'main': 'Main',
      'phone': 'Phone',
      'faxHome': 'Home fax',
      'faxWork': 'Work fax',
      'faxOther': 'Other fax',
      'pager': 'Pager',
      'workPager': 'Work pager',
      'school': 'School',
      'car': 'Car',
      'companyMain': 'Company main',
      'callback': 'Callback',
      'assistant': 'Assistant',
      'birthday': 'Birthday',
      'anniversary': 'Anniversary',
      'homepage': 'Homepage',
      'blog': 'Blog',
      'profile': 'Profile',
      'brother': 'Brother',
      'sister': 'Sister',
      'child': 'Child',
      'father': 'Father',
      'mother': 'Mother',
      'parent': 'Parent',
      'friend': 'Friend',
      'manager': 'Manager',
      'partner': 'Partner',
      'relative': 'Relative',
      'spouse': 'Spouse',
      'domesticPartner': 'Domestic partner',
      'referredBy': 'Referred by',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String addressLabel(String label) {
    return '$label address';
  }

  @override
  String get accountSamsung => 'Samsung account';

  @override
  String get accountSimServiceNumbers => 'SIM service numbers';

  @override
  String get accountSimCard => 'SIM card';

  @override
  String get accountThisDevice => 'This device';

  @override
  String contactsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contacts',
      one: '1 contact',
    );
    return '$_temp0';
  }

  @override
  String get justOnce => 'Just once';

  @override
  String get close => 'Close';

  @override
  String get ok => 'OK';

  @override
  String get edit => 'Edit';

  @override
  String get video => 'Video';

  @override
  String get remove => 'Remove';

  @override
  String get custom => 'Custom';

  @override
  String get allow => 'Allow';

  @override
  String get select => 'Select';

  @override
  String get merge => 'Merge';

  @override
  String get import => 'Import';

  @override
  String get qrScanHint => 'Scan with a phone camera to add this contact';

  @override
  String deleteContactTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteContactMessage =>
      'This contact will be removed from this phone and from its accounts.';

  @override
  String get shareVcf => 'vCard file (VCF)';

  @override
  String get shareText => 'Text';

  @override
  String get qrCode => 'QR code';

  @override
  String get blockContact => 'Block contact';

  @override
  String get unblockContact => 'Unblock contact';

  @override
  String get askEveryTime => 'Ask every time';

  @override
  String get contactNotFound => 'Contact not found';

  @override
  String get addToFavourites => 'Add to favourites';

  @override
  String get removeFromFavourites => 'Remove from favourites';

  @override
  String get defaultNumber => 'Default';

  @override
  String get ringtone => 'Ringtone';

  @override
  String get organization => 'Work';

  @override
  String get website => 'Website';

  @override
  String get simForCalls => 'SIM card for calls';

  @override
  String get storageLocations => 'Storage locations';

  @override
  String get viewAll => 'View all';

  @override
  String get selectContact => 'Select contact';

  @override
  String get noMatchingContacts => 'No matching contacts';

  @override
  String get noCallsWithContact => 'No calls with this contact yet';

  @override
  String get unlink => 'Unlink';

  @override
  String get unlinkAll => 'Unlink all';

  @override
  String deleteContactsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count contacts?',
      one: 'Delete contact?',
    );
    return '$_temp0';
  }

  @override
  String get deleteContactsMessage =>
      'They will be removed from this phone and from their accounts.';

  @override
  String get manageContacts => 'Manage contacts';

  @override
  String get contactsAccessMessage =>
      'Allow access to your contacts to see them here and show names for calls';

  @override
  String get alphabetIndex => 'Alphabet index';

  @override
  String get createNewContact => 'Create new contact';

  @override
  String get updateExistingContact => 'Update existing contact';

  @override
  String get customLabel => 'Custom label';

  @override
  String get noContactsToExport => 'No contacts to export';

  @override
  String get couldNotOpenFile => 'Couldn\'t open the file';

  @override
  String get noContactsInFile => 'No contacts in this file';

  @override
  String importContactsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Import $count contacts?',
      one: 'Import 1 contact?',
    );
    return '$_temp0';
  }

  @override
  String importContactsMessage(String account) {
    return 'They will be saved to $account.';
  }

  @override
  String contactsImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contacts imported',
      one: 'Contact imported',
    );
    return '$_temp0';
  }

  @override
  String get couldNotImportContacts => 'Couldn\'t import these contacts';

  @override
  String get display => 'Display';

  @override
  String get showContactPhotos => 'Show contact\'s profile picture';

  @override
  String get onlyContactsWithNumbers => 'Only display contacts with numbers';

  @override
  String get contactsToDisplay => 'Contacts to display';

  @override
  String get sortBy => 'Sort by';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get nameFormat => 'Name format';

  @override
  String get firstNameFirst => 'First name first';

  @override
  String get lastNameFirst => 'Last name first';

  @override
  String get defaultSaveLocation => 'Default save location';

  @override
  String get phoneDefault => 'Phone default';

  @override
  String get importContacts => 'Import contacts';

  @override
  String get fromVcf => 'From a .vcf file';

  @override
  String get exportContacts => 'Export contacts';

  @override
  String get asVcf => 'As a .vcf file';

  @override
  String get simContacts => 'SIM card contacts';

  @override
  String get mergeDuplicates => 'Merge duplicate contacts';

  @override
  String get simReadError => 'Couldn\'t read the SIM card';

  @override
  String get simReading => 'Reading the SIM card…';

  @override
  String get simEmpty => 'No contacts on the SIM card';

  @override
  String get allSavedInContacts => 'All saved in Contacts';

  @override
  String importToContacts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Import $count to Contacts',
    );
    return '$_temp0';
  }

  @override
  String mergeGroupTitle(String count) {
    return 'Merge $count contacts?';
  }

  @override
  String mergeGroupsTitle(String count, String groups) {
    return 'Merge $count contacts into $groups?';
  }

  @override
  String mergeGroupMessage(String name) {
    return 'They become one contact named $name, with all their numbers and details.';
  }

  @override
  String get mergeGroupsMessage =>
      'Each group becomes one contact, with all its numbers and details.';

  @override
  String contactsMerged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contacts merged',
      one: 'Contacts merged',
    );
    return '$_temp0';
  }

  @override
  String get couldNotMergeContacts => 'Couldn\'t merge these contacts';

  @override
  String get noDuplicateContacts => 'No duplicate contacts';

  @override
  String mergeAll(String count) {
    return 'Merge all ($count)';
  }

  @override
  String get recentSearches => 'Recent searches';

  @override
  String get clearAll => 'Clear all';

  @override
  String get noResultsFound => 'No results found';

  @override
  String foundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count found',
    );
    return '$_temp0';
  }

  @override
  String removeItem(String item) {
    return 'Remove $item';
  }

  @override
  String get done => 'Done';

  @override
  String get discard => 'Discard';

  @override
  String get change => 'Change';

  @override
  String get contactReadOnly =>
      'This contact\'s account is read-only, so it can\'t be changed here';

  @override
  String get couldNotSaveContact => 'Couldn\'t save the contact';

  @override
  String alreadySavedAs(String number, String name) {
    return '$number is already saved as $name.';
  }

  @override
  String alreadyInContacts(String name) {
    return '$name is already in your contacts.';
  }

  @override
  String get alreadyInContactsTitle => 'Already in contacts';

  @override
  String saveAnotherAnyway(String duplicate) {
    return '$duplicate Save another contact anyway?';
  }

  @override
  String get saveAnyway => 'Save anyway';

  @override
  String get saveOrDiscard => 'Save your edits?';

  @override
  String get couldNotLoadContactRetry => 'Couldn\'t load the contact. Retry';

  @override
  String get email => 'Email';

  @override
  String get addEmail => 'Add email';

  @override
  String get addWebsite => 'Add website';

  @override
  String get relationships => 'Relationships';

  @override
  String get addRelationship => 'Add relationship';

  @override
  String get showLess => 'Show less';

  @override
  String get showMore => 'Show more';

  @override
  String get newContact => 'New contact';

  @override
  String get addToExistingContact => 'Add to existing contact';

  @override
  String get editContact => 'Edit contact';

  @override
  String get couldNotLoadAccounts => 'Couldn\'t load accounts';

  @override
  String get loadingAccounts => 'Loading accounts…';

  @override
  String saveToAccount(String account) {
    return 'Save to $account';
  }

  @override
  String get profilePicture => 'Profile picture';

  @override
  String get camera => 'Camera';

  @override
  String get selectPhotos => 'Select photos';

  @override
  String get deleteProfilePicture => 'Delete profile picture';

  @override
  String get couldNotOpenCamera => 'Couldn\'t open the camera';

  @override
  String get followSystem => 'Follow system';

  @override
  String get customRingtone => 'Custom ringtone';

  @override
  String get fromFollowingAccount => 'From the following account';

  @override
  String get fewerNameFields => 'Fewer name fields';

  @override
  String get moreNameFields => 'More name fields';

  @override
  String get namePrefix => 'Name prefix';

  @override
  String get middleName => 'Middle name';

  @override
  String get nameSuffix => 'Name suffix';

  @override
  String get name => 'Name';

  @override
  String get number => 'Number';

  @override
  String get workInfo => 'Work info';

  @override
  String get company => 'Company';

  @override
  String get jobTitle => 'Job title';

  @override
  String get department => 'Department';

  @override
  String get address => 'Address';

  @override
  String get street => 'Street';

  @override
  String get city => 'City';

  @override
  String get stateProvince => 'State/Province';

  @override
  String get postalCode => 'Postal code';

  @override
  String get country => 'Country';

  @override
  String get addAddress => 'Add address';

  @override
  String get importantDate => 'Important date';

  @override
  String get importantDates => 'Important dates';

  @override
  String get addImportantDate => 'Add important date';

  @override
  String get noGroupsInAccount => 'No groups in this account';

  @override
  String get groups => 'Groups';

  @override
  String get enterNumber => 'Enter number';

  @override
  String get chooseFromContacts => 'Choose from contacts';

  @override
  String get blockingNeedsScreeningRole =>
      'Set Dialer as your caller ID & spam app to block these calls';

  @override
  String get blockNumber => 'Block number';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get blockAndFilter => 'Block & filter';

  @override
  String get searchBlockedNumbers => 'Search blocked numbers';

  @override
  String get blockingPaused => 'Blocking rules are paused';

  @override
  String get blockingPausedSubtitle =>
      'Another app screens your calls. Tap to let Dialer screen them.';

  @override
  String get blockUnknown => 'Block unknown/private numbers';

  @override
  String get blockUnknownSubtitle => 'Callers who hide their number';

  @override
  String get blockNonContacts => 'Block calls from numbers not in Contacts';

  @override
  String get blockNonContactsSubtitle => 'Only your contacts can ring you';

  @override
  String get blockedNumbers => 'Blocked numbers';

  @override
  String get addNumber => 'Add number';

  @override
  String get noMatchingBlocked => 'No matching blocked numbers';

  @override
  String get blockedCalls => 'Blocked calls';

  @override
  String get addCall => 'Add call';

  @override
  String get note => 'Note';

  @override
  String get editNote => 'Edit note';

  @override
  String get videoCall => 'Video call (Meet)';

  @override
  String get switchToVideoCall => 'Switch to video call';

  @override
  String get mute => 'Mute';

  @override
  String get hold => 'Hold';

  @override
  String get resume => 'Resume';

  @override
  String get headset => 'Headset';

  @override
  String get speaker => 'Speaker';

  @override
  String get audioPhone => 'Phone';

  @override
  String get wiredHeadset => 'Wired headset';

  @override
  String get endCall => 'End call';

  @override
  String get end => 'End';

  @override
  String get dialPad => 'Dial pad';

  @override
  String get callNote => 'Call note';

  @override
  String get callNoteHint => 'Write something to remember from this call';

  @override
  String get conferenceCall => 'Conference call';

  @override
  String get unknown => 'Unknown';

  @override
  String get lineBusy => 'Line busy';

  @override
  String get callDeclined => 'Call declined';

  @override
  String get callCancelled => 'Call cancelled';

  @override
  String get callFailed => 'Call failed';

  @override
  String get callEnded => 'Call ended';

  @override
  String get connected => 'Connected';

  @override
  String get calling => 'Calling';

  @override
  String get onHold => 'On hold';

  @override
  String get phoneCall => 'Phone call';

  @override
  String get hdCall => 'HD call';

  @override
  String switchToOnHold(String name) {
    return 'Switch to $name, on hold';
  }

  @override
  String get switchCall => 'Switch';

  @override
  String get declineWithSms => 'SMS reply';

  @override
  String get answer => 'Answer';

  @override
  String get decline => 'Decline';

  @override
  String get answerVerb => 'answer';

  @override
  String get declineVerb => 'decline';

  @override
  String swipeUpDownHint(String up, String down) {
    return 'Swipe up to $up, down to $down';
  }

  @override
  String swipeUpHint(String action) {
    return 'Swipe up to $action';
  }

  @override
  String get effectsFull => 'Full effects';

  @override
  String get effectsReduced => 'Reduced effects';

  @override
  String get effectsOff => 'Effects off';

  @override
  String get off => 'Off';

  @override
  String get always => 'Always';

  @override
  String get onlyWithHeadphones => 'Only with headphones';

  @override
  String get incomingCallReminders => 'Incoming call reminders';

  @override
  String get incomingFootnote =>
      'Applies only to incoming calls received when your device is unlocked.';

  @override
  String get banner => 'Banner';

  @override
  String get fullScreen => 'Full screen';

  @override
  String get announceCalls => 'Announce incoming calls';

  @override
  String get announceCallsSubtitle => 'Says the caller\'s name while it rings';

  @override
  String get flashOnCall => 'Flash notification';

  @override
  String get flashOnCallSubtitle => 'Blink the camera flash while a call rings';

  @override
  String get systemFlash => 'Your phone has its own flash notification';

  @override
  String get systemFlashSubtitle =>
      'Turn one of them off, or both will blink. Find it in Settings under Notifications or Accessibility';

  @override
  String get liveUpdateCapsule => 'Live Update capsule (Experimental)';

  @override
  String get liveUpdateCapsuleSubtitle =>
      'Android 16: show a connected call in the status bar chip, and the capsule on ColorOS, OxygenOS and realme UI';

  @override
  String get swipeUpToAnswer => 'Swipe up to answer';

  @override
  String get swipeDownToAnswer => 'Swipe down to answer';

  @override
  String get answerButtons => 'Answer buttons';

  @override
  String get twoButtons => '2 buttons';

  @override
  String get oneButton => '1 button';

  @override
  String get answerCall => 'Answer call';

  @override
  String get callScreenEffects => 'Call screen effects';

  @override
  String get callScreenEffectsSubtitle => 'Glass and glow on the call screen';

  @override
  String get callScreenAnimations => 'Call screen animations';

  @override
  String get callScreenAnimationsSubtitle =>
      'Motion when the call screen opens, answers and changes';

  @override
  String get hideContactNumbers => 'Hide contact phone numbers';

  @override
  String get hideContactNumbersSubtitle =>
      'Show only the name of saved contacts on the call screen and in Calls';

  @override
  String secondsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seconds',
      one: '1 second',
    );
    return '$_temp0';
  }

  @override
  String get answerEndCalls => 'Answer/End calls';

  @override
  String get vibrateAnswerEnd => 'Vibrate when your calls are answered/ended';

  @override
  String get autoAnswer =>
      'Auto-answer calls when connected to external audio device';

  @override
  String get autoAnswerSubtitle => 'Includes Bluetooth and wired headphones';

  @override
  String get autoAnswerDelay => 'Delay auto answer';

  @override
  String get replyWithSms => 'Reply with SMS';

  @override
  String get speakerDefault => 'Calls default to speaker';

  @override
  String get speakerDefaultSubtitle =>
      'Doesn\'t take effect when external devices are connected.';

  @override
  String get quickDeclineMessage => 'Quick decline message';

  @override
  String get quickDeclineMessages => 'Quick decline messages';

  @override
  String get quickDeclineHint => 'Sent when you decline a call with a message';

  @override
  String get addMessage => 'Add message';

  @override
  String get settingNotAvailable => 'This phone doesn\'t have that setting';

  @override
  String get notDefaultApp => 'Not your default phone app';

  @override
  String get notDefaultAppSubtitle => 'Incoming calls use another app';

  @override
  String get notificationsOff => 'Notifications are off';

  @override
  String get notificationsOffSubtitle =>
      'You won\'t see incoming or missed calls';

  @override
  String get fullScreenOff => 'Full-screen calls are off';

  @override
  String get fullScreenOffSubtitle =>
      'Incoming calls only show as a notification';

  @override
  String get blockingPausedShort => 'Another app screens your calls';

  @override
  String get bluetoothNamesHidden => 'Bluetooth names hidden';

  @override
  String get bluetoothNamesHiddenSubtitle =>
      'Calls can\'t tell your watch from your earbuds';

  @override
  String get fix => 'Fix';

  @override
  String get callSettings => 'Call settings';

  @override
  String get needsAttention => 'Needs attention';

  @override
  String get callerIdentification => 'Caller identification';

  @override
  String get callerIdSpamApp => 'Caller ID & spam app';

  @override
  String get carrierSettings => 'Carrier-related settings';

  @override
  String get softwareUpdate => 'Software update';

  @override
  String get helpFeedback => 'Help & feedback';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get aboutOneDialer => 'About One Dialer';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get openDetails => 'Open details';

  @override
  String get writeInKeypad => 'Write in keypad';

  @override
  String get twoCallButtons => 'Two Call buttons';

  @override
  String get chooseSimAndCall => 'Choose SIM and call';

  @override
  String get tapRecentCall => 'Tap a recent call';

  @override
  String get chooseSimForCalls => 'Choose SIM for calls';

  @override
  String get chooseSimSubtitle => 'Dual SIM with no default SIM';

  @override
  String get appearance => 'Appearance';

  @override
  String get reduceVisualEffects => 'Reduce visual effects';

  @override
  String get displaySize => 'Display size';

  @override
  String get displaySizeSmall => 'Small';

  @override
  String get displaySizeDefault => 'Default';

  @override
  String get displaySizeLarge => 'Large';

  @override
  String get displaySizeLarger => 'Larger';

  @override
  String get displaySizeApp => 'App';

  @override
  String get displaySizeNavBar => 'Navigation bar';

  @override
  String get reduceVisualEffectsSubtitle =>
      'Less blur runs smoother on slower phones';

  @override
  String get callScreenEdgeGlow => 'Call screen edge glow';

  @override
  String get darkModeEdgeGlow => 'Glow strength';

  @override
  String get edgeGlowClassic => 'Classic';

  @override
  String get edgeGlowSoft => 'Soft';

  @override
  String get edgeGlowBold => 'Bold';

  @override
  String get glassStyle => 'Glass style';

  @override
  String get navBarFrosted => 'Edge glow';

  @override
  String get navBarLiquid => 'Liquid glass';

  @override
  String get navBarGlass => 'Glass effect';

  @override
  String get navGlassPremium => 'Full refraction';

  @override
  String get navGlassStandard => 'Light';

  @override
  String get navGlassAuto => 'Automatic';

  @override
  String get glassSettings => 'Glass & blur';

  @override
  String get liquidGlassOn => 'Liquid glass on';

  @override
  String get liquidScopeAll => 'Everything';

  @override
  String get liquidScopeControls => 'Nav bar and buttons';

  @override
  String get liquidScopeNavbar => 'Nav bar only';

  @override
  String get glassExperimentalNote =>
      'Liquid glass is experimental and the heaviest style: it needs even more graphics power than Edge glow, which is already demanding. If scrolling stutters, try Nav bar only or Glass effect › Automatic, or go back to Edge glow. On slower phones, Display & effects › Reduce visual effects runs smoothest.';

  @override
  String get callsFromOtherApps => 'Calls from other apps';

  @override
  String get callsFromOtherAppsSubtitle =>
      'Show WhatsApp and other apps\' calls in Recents';

  @override
  String get manageContactsSubtitle =>
      'Display, save location, import and export, SIM, duplicates';

  @override
  String get googleContactsSync => 'Google Contacts sync';

  @override
  String get googleContactsSyncSubtitle =>
      'Which accounts sync, and backing up phone contacts';

  @override
  String get defaultApps => 'Default apps';

  @override
  String get notifications => 'Notifications';

  @override
  String get setupTitle => 'Set One Dialer as your default phone app';

  @override
  String get setupBody =>
      'Needed to make and answer calls, show your call history and contacts, and block numbers.';

  @override
  String get settingUp => 'Setting up…';

  @override
  String get setupDisclosure =>
      'One Dialer uses Phone to make and manage calls on your SIMs, Call history for Recents and missed calls, Contacts for names, photos and search, and Notifications for incoming, ongoing and missed calls. Your calls, call history and contacts never leave your phone. Crash reports (no personal data) help fix bugs.';

  @override
  String get installedDirectly => 'Installed directly';

  @override
  String get anotherAppStore => 'Another app store';

  @override
  String aboutApp(String app) {
    return 'About $app';
  }

  @override
  String get updateAvailable => 'Update available';

  @override
  String get versionUpToDate => 'Version up to date';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get checking => 'Checking…';

  @override
  String get version => 'Version';

  @override
  String get build => 'Build';

  @override
  String get installedFrom => 'Installed from';

  @override
  String get device => 'Device';

  @override
  String get androidVersion => 'Android version';

  @override
  String get openSourceLicences => 'Open source licences';

  @override
  String get changelog => 'Changelog';

  @override
  String installedOn(String date) {
    return 'Installed $date';
  }

  @override
  String get earlierVersions => 'Earlier versions';

  @override
  String get aboutThisUpdate => 'About this update';

  @override
  String get reportLag => 'Report lag';

  @override
  String get reportLagMessage =>
      'Send recent performance timings, screen and action names, and device details to help find slowdowns. Phone numbers, contacts and messages are not included.';

  @override
  String get sendReport => 'Send report';

  @override
  String get reportUnavailable =>
      'Reporting unavailable or recently requested. Try again in a minute.';

  @override
  String get reportQueued => 'Report queued';

  @override
  String reportQueuedMessage(String id) {
    return 'Your report is saved for upload when reporting is available. Share this ID with your feedback:\\n\\n$id';
  }

  @override
  String get copy => 'Copy';

  @override
  String get paste => 'Paste';

  @override
  String get copyId => 'Copy ID';

  @override
  String get reportIdCopied => 'Report ID copied';

  @override
  String get editSpeedDial => 'Edit speed dial';

  @override
  String get clearNumber => 'Clear number';

  @override
  String get changeNumber => 'Change number';

  @override
  String get numberCopied => 'Number copied';

  @override
  String get noEmailApp => 'No email app found';

  @override
  String get noBrowser => 'No browser found';

  @override
  String get sendFeedback => 'Send feedback';

  @override
  String get developer => 'Developer';

  @override
  String get downloadStopped =>
      'The download stopped. Try again when you\'re connected.';

  @override
  String get couldNotInstallUpdate =>
      'Couldn\'t install the update. Try again.';

  @override
  String get updateCancelled =>
      'Update cancelled. You can download it any time from here.';

  @override
  String get noInternet => 'No internet connection. Connect and try again.';

  @override
  String get couldNotDownloadUpdate =>
      'Couldn\'t download the update. Try again.';

  @override
  String get softwareInformation => 'Software information';

  @override
  String get autoDownload => 'Auto download';

  @override
  String get downloadAndInstall => 'Download and install';

  @override
  String get installAndRestart => 'Install and restart';

  @override
  String get tryAgain => 'Try again';

  @override
  String get downloading => 'Downloading…';

  @override
  String get noNetwork => 'No network connection';

  @override
  String get notFromPlay =>
      'Updates come from Google Play. This copy wasn\'t installed from Play.';

  @override
  String get notFromPlayTitle => 'Not from Google Play';

  @override
  String get notFromPlayWarning =>
      'This copy wasn\'t installed from Google Play, so it won\'t get updates and may have been changed. You can keep using it, or get the official version from the beta.';

  @override
  String get keepUsing => 'Keep using';

  @override
  String get getOfficialVersion => 'Get the official version';

  @override
  String get couldNotReachPlay => 'Couldn\'t reach Google Play';

  @override
  String get softwareVersion => 'Software version';

  @override
  String get closedBeta => 'Closed beta';

  @override
  String get newVersionAvailable => 'A new version is available';

  @override
  String get autoDownloadExplainer =>
      'When One Dialer checks Google Play for updates as you open it. Updates only install when you tap Download and install.';

  @override
  String get autoUpdateNeverSubtitle => 'Only when you tap Check for updates';

  @override
  String get autoUpdateAlwaysSubtitle => 'Checking uses very little data';

  @override
  String get autoUpdateNever => 'Never';

  @override
  String get autoUpdateWifiOnly => 'Using Wi-Fi only';

  @override
  String get autoUpdateAlways => 'Using Wi-Fi or mobile data';

  @override
  String get displayAndEffects => 'Display & effects';

  @override
  String get keypadAndRecents => 'Keypad & recents';

  @override
  String get logIncoming => 'Incoming';

  @override
  String get logOutgoing => 'Outgoing';

  @override
  String get logMissed => 'Missed';

  @override
  String get logRejected => 'Rejected';

  @override
  String get logBlocked => 'Blocked';

  @override
  String logRangFor(String type, String duration) {
    return '$type (Rang for $duration)';
  }

  @override
  String get record => 'Record';

  @override
  String get stopRecording => 'Stop recording';

  @override
  String get recordSetUpFirst => 'Record (set up in Settings)';

  @override
  String get recordingNow => 'Recording';

  @override
  String get callRecording => 'Call recording';

  @override
  String get recorderApp => 'One Recorder';

  @override
  String get recorderReady => 'Ready to record';

  @override
  String get recorderNeedsMic => 'Allow the microphone in One Recorder';

  @override
  String get recorderNeedsAccessibility => 'Turn on its accessibility service';

  @override
  String get recorderBothSides => 'Records both sides of your calls';

  @override
  String get recorderMicrophone => 'Records with the microphone';

  @override
  String get recorderHelperStopped =>
      'Both sides is paused: start the helper in One Recorder';

  @override
  String get recorderUntrusted =>
      'The recorder works only with One Dialer from Google Play. Install it from Play, or update both apps.';

  @override
  String get recordingConsentTitle => 'Before you record';

  @override
  String get recordingConsentBody =>
      'Recording laws differ by country, and some need everyone on the call to agree. You\'re responsible for telling the other person and getting their consent. Recordings stay on this phone and are never uploaded.';

  @override
  String get recordingConsentAccept => 'I understand';

  @override
  String get recordings => 'Recordings';

  @override
  String get noRecordings => 'No recordings yet';

  @override
  String get noRecordingsSubtitle =>
      'Tap ⋮ › Record on the call screen during a call';

  @override
  String get deleteAllRecordings => 'Delete all recordings';

  @override
  String get deleteAllRecordingsTitle => 'Delete all recordings?';

  @override
  String get deleteAllRecordingsMessage => 'They can\'t be recovered.';

  @override
  String get recordingNotSetUp => 'Calls aren\'t being recorded';

  @override
  String get recordingNotSetUpSubtitle =>
      'Auto-record is on, but One Recorder isn\'t set up';

  @override
  String get rename => 'Rename';

  @override
  String get star => 'Star';

  @override
  String get unstar => 'Unstar';

  @override
  String get filterStarred => 'Starred';

  @override
  String get filterUnknown => 'Unknown';

  @override
  String get saveToPhone => 'Save to phone';

  @override
  String get searchRecordings => 'Search recordings';

  @override
  String get renameRecording => 'Rename recording';

  @override
  String recordingsSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recordings saved to Recordings/One Dialer',
      one: 'Saved to Recordings/One Dialer',
    );
    return '$_temp0';
  }

  @override
  String get recordingSaveFailed => 'Couldn\'t save to the phone';

  @override
  String deleteRecordings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count recordings?',
      one: 'Delete this recording?',
    );
    return '$_temp0';
  }

  @override
  String get noMatchingRecordings => 'No matching recordings';

  @override
  String get addContact => 'Add contact';

  @override
  String get autoRecord => 'Auto-record';

  @override
  String get autoRecordOff => 'Off';

  @override
  String get autoRecordAll => 'All calls';

  @override
  String get autoRecordUnknown => 'Unknown numbers';

  @override
  String get autoRecordContacts => 'Selected contacts';

  @override
  String get recordTheseContacts => 'Contacts to record';

  @override
  String get neverRecord => 'Never record';

  @override
  String get neverRecordSubtitle => 'Contacts auto-record always skips';

  @override
  String get recordingSound => 'Sound';

  @override
  String get volumeBoost => 'Volume boost';

  @override
  String get volumeBoostSubtitle =>
      'Lifts the other person\'s voice, which the mic only hears faintly';

  @override
  String get boostOff => 'Off';

  @override
  String get boostNormal => 'Normal';

  @override
  String get boostStrong => 'Strong';

  @override
  String get micSource => 'Microphone source';

  @override
  String get micSourceSubtitle =>
      'Automatic tries each on the first call and keeps the loudest';

  @override
  String get micSourceAuto => 'Automatic';

  @override
  String get micSourceRecognition => 'Voice recognition';

  @override
  String get micSourceCommunication => 'Voice communication';

  @override
  String get micSourceMic => 'Microphone';

  @override
  String get storage => 'Storage';

  @override
  String get storageUsed => 'Space used';

  @override
  String get autoDelete => 'Auto-delete';

  @override
  String get autoDeleteSubtitle => 'Starred recordings are always kept';

  @override
  String get autoDeleteNever => 'Never';

  @override
  String autoDeleteDays(int days) {
    return 'After $days days';
  }

  @override
  String get imeiTitle => 'IMEI';

  @override
  String get imeiUnavailable =>
      'Android doesn\'t let apps show the IMEI. You can find it in your phone\'s settings under About phone.';

  @override
  String get aboutPhone => 'About phone';

  @override
  String get glassStyleSubtitle =>
      'Liquid glass bends what\'s behind it but uses more power';

  @override
  String get darkModeEdgeGlowSubtitle =>
      'How brightly the glass edges glow in dark mode';

  @override
  String get liquidGlassOnSubtitle => 'Which parts of the app use liquid glass';

  @override
  String get navBarGlassSubtitle =>
      'Full refraction looks best; Light runs smoother on slower phones';

  @override
  String get tapRecentCallSubtitle =>
      'What happens when you tap a call in Calls';

  @override
  String get callScreenEdgeGlowSubtitle =>
      'How brightly the call buttons\' glass edges glow';

  @override
  String get answerButtonsSubtitle =>
      'How you answer, and how the call screen looks';

  @override
  String get carrierSettingsSubtitle =>
      'Call forwarding, call waiting and caller ID';

  @override
  String get callBackground => 'Call background';

  @override
  String get callBackgroundAllSubtitle =>
      'For every call, unless a contact has its own';

  @override
  String get callBackgroundDefault => 'Default';

  @override
  String get callBackgroundColour => 'Colour';

  @override
  String get callBackgroundPhoto => 'Photo';

  @override
  String get callBackgroundChoosePhoto => 'Choose photo';

  @override
  String get callBackgroundContactPhoto => 'Contact\'s photo';

  @override
  String get callBackgroundContactPhotoSubtitle =>
      'Android keeps contact photos small; choose a photo for a sharper one';

  @override
  String get callBackgroundSameAsAll => 'Same as all calls';

  @override
  String get callBackgroundAllNote =>
      'A contact with their own call background, set on their contact page, uses it instead.';

  @override
  String get callBackgroundContactNote =>
      'Used for this contact instead of the call background for all calls.';

  @override
  String get exportSettings => 'Export settings';

  @override
  String get exportSettingsSubtitle =>
      'Save settings, call notes and call backgrounds to a file';

  @override
  String get importSettings => 'Import settings';

  @override
  String get importSettingsSubtitle => 'Restore them from an exported file';

  @override
  String get importSettingsTitle => 'Replace your settings?';

  @override
  String get importSettingsMessage =>
      'Your settings, speed dial, call notes and call backgrounds are replaced by the ones in the file. One Dialer then restarts.';

  @override
  String get importSettingsInCall =>
      'Settings can\'t be imported during a call';

  @override
  String get settingsExported => 'Settings exported';

  @override
  String get couldNotSaveSettings => 'Couldn\'t save the file';

  @override
  String get notASettingsFile => 'This isn\'t a One Dialer settings file';

  @override
  String endHeldCall(String name) {
    return 'End call with $name';
  }
}
