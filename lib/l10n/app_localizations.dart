import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @languageName.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageName;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @dismissMenu.
  ///
  /// In en, this message translates to:
  /// **'Dismiss menu'**
  String get dismissMenu;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// REVIEW: Badge for features not available yet; keep it short
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get soon;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get deselectAll;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchContacts.
  ///
  /// In en, this message translates to:
  /// **'Search contacts'**
  String get searchContacts;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @searchByVoice.
  ///
  /// In en, this message translates to:
  /// **'Search by voice'**
  String get searchByVoice;

  /// No description provided for @scrollToTop.
  ///
  /// In en, this message translates to:
  /// **'Scroll to top'**
  String get scrollToTop;

  /// No description provided for @dateWheelDay.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String dateWheelDay(String day);

  /// No description provided for @dateWheelYear.
  ///
  /// In en, this message translates to:
  /// **'Year {year}'**
  String dateWheelYear(String year);

  /// No description provided for @navCalls.
  ///
  /// In en, this message translates to:
  /// **'Calls'**
  String get navCalls;

  /// No description provided for @navContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get navContacts;

  /// No description provided for @returnToCall.
  ///
  /// In en, this message translates to:
  /// **'Return to call'**
  String get returnToCall;

  /// No description provided for @createContact.
  ///
  /// In en, this message translates to:
  /// **'Create contact'**
  String get createContact;

  /// No description provided for @showKeypad.
  ///
  /// In en, this message translates to:
  /// **'Show keypad'**
  String get showKeypad;

  /// No description provided for @settingsLanguageHeader.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageHeader;

  /// No description provided for @settingsAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsAppLanguage;

  /// No description provided for @settingsAppLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only changes this app'**
  String get settingsAppLanguageSubtitle;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'Same as phone'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsAndroidLanguage.
  ///
  /// In en, this message translates to:
  /// **'Android language settings'**
  String get settingsAndroidLanguage;

  /// No description provided for @settingsAndroidLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the language in Android\'s settings'**
  String get settingsAndroidLanguageSubtitle;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @voicemail.
  ///
  /// In en, this message translates to:
  /// **'Voicemail'**
  String get voicemail;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} hr {minutes} min'**
  String durationHoursMinutes(String hours, String minutes);

  /// No description provided for @durationMinutesSeconds.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min {seconds} sec'**
  String durationMinutesSeconds(String minutes, String seconds);

  /// No description provided for @durationSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} sec'**
  String durationSeconds(String seconds);

  /// No description provided for @privateNumber.
  ///
  /// In en, this message translates to:
  /// **'Private number'**
  String get privateNumber;

  /// No description provided for @appVideo.
  ///
  /// In en, this message translates to:
  /// **'{app} video'**
  String appVideo(String app);

  /// No description provided for @videoCallOnApp.
  ///
  /// In en, this message translates to:
  /// **'Video call on {app}'**
  String videoCallOnApp(String app);

  /// No description provided for @callOnApp.
  ///
  /// In en, this message translates to:
  /// **'Call on {app}'**
  String callOnApp(String app);

  /// No description provided for @callTypeOutgoing.
  ///
  /// In en, this message translates to:
  /// **'Outgoing call'**
  String get callTypeOutgoing;

  /// No description provided for @callTypeMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed call'**
  String get callTypeMissed;

  /// No description provided for @callTypeRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected call'**
  String get callTypeRejected;

  /// No description provided for @callTypeBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked call'**
  String get callTypeBlocked;

  /// No description provided for @callTypeVoicemail.
  ///
  /// In en, this message translates to:
  /// **'Voicemail'**
  String get callTypeVoicemail;

  /// No description provided for @callNotConnected.
  ///
  /// In en, this message translates to:
  /// **'(Not connected)'**
  String get callNotConnected;

  /// No description provided for @callTypeIncoming.
  ///
  /// In en, this message translates to:
  /// **'Incoming call'**
  String get callTypeIncoming;

  /// No description provided for @speedDialNoNumber.
  ///
  /// In en, this message translates to:
  /// **'No speed dial number'**
  String get speedDialNoNumber;

  /// No description provided for @speedDialAssignPrompt.
  ///
  /// In en, this message translates to:
  /// **'Assign a contact to key {digit}?'**
  String speedDialAssignPrompt(String digit);

  /// No description provided for @assign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// No description provided for @couldNotPlaceCall.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t place the call'**
  String get couldNotPlaceCall;

  /// No description provided for @keypadNumberEmpty.
  ///
  /// In en, this message translates to:
  /// **'Number, empty. Long-press to paste'**
  String get keypadNumberEmpty;

  /// No description provided for @keypadNumber.
  ///
  /// In en, this message translates to:
  /// **'Number {number}'**
  String keypadNumber(String number);

  /// No description provided for @keypadZeroHint.
  ///
  /// In en, this message translates to:
  /// **'0, long-press for plus'**
  String get keypadZeroHint;

  /// No description provided for @keypadDigitHint.
  ///
  /// In en, this message translates to:
  /// **'{digit}, long-press for speed dial'**
  String keypadDigitHint(String digit);

  /// No description provided for @hideKeypad.
  ///
  /// In en, this message translates to:
  /// **'Hide keypad'**
  String get hideKeypad;

  /// No description provided for @callWithSim.
  ///
  /// In en, this message translates to:
  /// **'Call with SIM {slot}, {sim}'**
  String callWithSim(String slot, String sim);

  /// No description provided for @keypadDeleteHint.
  ///
  /// In en, this message translates to:
  /// **'Delete, long-press to clear'**
  String get keypadDeleteHint;

  /// No description provided for @addPause.
  ///
  /// In en, this message translates to:
  /// **'Add 2-sec pause'**
  String get addPause;

  /// No description provided for @addWait.
  ///
  /// In en, this message translates to:
  /// **'Add wait'**
  String get addWait;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessage;

  /// No description provided for @speedDialNumbers.
  ///
  /// In en, this message translates to:
  /// **'Speed dial numbers'**
  String get speedDialNumbers;

  /// No description provided for @speedDialKey.
  ///
  /// In en, this message translates to:
  /// **'Speed dial {digit}'**
  String speedDialKey(String digit);

  /// No description provided for @speedDial.
  ///
  /// In en, this message translates to:
  /// **'Speed dial'**
  String get speedDial;

  /// No description provided for @speedDialAssignContacts.
  ///
  /// In en, this message translates to:
  /// **'Assign contacts'**
  String get speedDialAssignContacts;

  /// No description provided for @speedDialRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed {name} from {digit}'**
  String speedDialRemoved(String name, String digit);

  /// No description provided for @callLogs.
  ///
  /// In en, this message translates to:
  /// **'Call logs'**
  String get callLogs;

  /// No description provided for @deleteCallHistory.
  ///
  /// In en, this message translates to:
  /// **'Delete call history'**
  String get deleteCallHistory;

  /// No description provided for @deleteCallsTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete call?} other{Delete {count} calls?}}'**
  String deleteCallsTitle(int count);

  /// No description provided for @deleteCallsMessage.
  ///
  /// In en, this message translates to:
  /// **'The selected call history will be removed from this phone.'**
  String get deleteCallsMessage;

  /// No description provided for @couldNotDeleteCalls.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete call history. Try again.'**
  String get couldNotDeleteCalls;

  /// No description provided for @showAllCalls.
  ///
  /// In en, this message translates to:
  /// **'Show all calls'**
  String get showAllCalls;

  /// No description provided for @showAppCallsOnly.
  ///
  /// In en, this message translates to:
  /// **'Show app calls only'**
  String get showAppCallsOnly;

  /// No description provided for @showBlockedCalls.
  ///
  /// In en, this message translates to:
  /// **'Show blocked calls'**
  String get showBlockedCalls;

  /// No description provided for @hideBlockedCalls.
  ///
  /// In en, this message translates to:
  /// **'Hide blocked calls'**
  String get hideBlockedCalls;

  /// No description provided for @blockNumberTitle.
  ///
  /// In en, this message translates to:
  /// **'Block {number}?'**
  String blockNumberTitle(String number);

  /// No description provided for @blockNumbersTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Block 1 number?} other{Block {count} numbers?}}'**
  String blockNumbersTitle(int count);

  /// No description provided for @blockNumbersMessage.
  ///
  /// In en, this message translates to:
  /// **'You won\'t get calls from blocked numbers.'**
  String get blockNumbersMessage;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} selected}}'**
  String selectedCount(int count);

  /// No description provided for @recentsSetDefaultMessage.
  ///
  /// In en, this message translates to:
  /// **'Set Dialer as your default phone app to see recent calls'**
  String get recentsSetDefaultMessage;

  /// No description provided for @setAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get setAsDefault;

  /// No description provided for @recentsNoAppCalls.
  ///
  /// In en, this message translates to:
  /// **'No app calls'**
  String get recentsNoAppCalls;

  /// No description provided for @recentsNoRecentCalls.
  ///
  /// In en, this message translates to:
  /// **'No recent calls'**
  String get recentsNoRecentCalls;

  /// No description provided for @recentsNoMissedCalls.
  ///
  /// In en, this message translates to:
  /// **'No missed calls'**
  String get recentsNoMissedCalls;

  /// No description provided for @recentsFilterMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get recentsFilterMissed;

  /// No description provided for @addToContacts.
  ///
  /// In en, this message translates to:
  /// **'Add to Contacts'**
  String get addToContacts;

  /// No description provided for @callDetails.
  ///
  /// In en, this message translates to:
  /// **'Call details'**
  String get callDetails;

  /// REVIEW: Android contact field labels (phone, email, event, relation types); several are gendered in Italian (Figlio, Amico)
  ///
  /// In en, this message translates to:
  /// **'{label, select, mobile{Mobile} home{Home} work{Work} workMobile{Work mobile} main{Main} phone{Phone} faxHome{Home fax} faxWork{Work fax} faxOther{Other fax} pager{Pager} workPager{Work pager} school{School} car{Car} companyMain{Company main} callback{Callback} assistant{Assistant} birthday{Birthday} anniversary{Anniversary} homepage{Homepage} blog{Blog} profile{Profile} brother{Brother} sister{Sister} child{Child} father{Father} mother{Mother} parent{Parent} friend{Friend} manager{Manager} partner{Partner} relative{Relative} spouse{Spouse} domesticPartner{Domestic partner} referredBy{Referred by} other{Other}}'**
  String contactLabel(String label);

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'{label} address'**
  String addressLabel(String label);

  /// No description provided for @accountSamsung.
  ///
  /// In en, this message translates to:
  /// **'Samsung account'**
  String get accountSamsung;

  /// No description provided for @accountSimServiceNumbers.
  ///
  /// In en, this message translates to:
  /// **'SIM service numbers'**
  String get accountSimServiceNumbers;

  /// No description provided for @accountSimCard.
  ///
  /// In en, this message translates to:
  /// **'SIM card'**
  String get accountSimCard;

  /// No description provided for @accountThisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get accountThisDevice;

  /// No description provided for @contactsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 contact} other{{count} contacts}}'**
  String contactsCount(int count);

  /// No description provided for @justOnce.
  ///
  /// In en, this message translates to:
  /// **'Just once'**
  String get justOnce;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @merge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get merge;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @qrScanHint.
  ///
  /// In en, this message translates to:
  /// **'Scan with a phone camera to add this contact'**
  String get qrScanHint;

  /// No description provided for @deleteContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteContactTitle(String name);

  /// No description provided for @deleteContactMessage.
  ///
  /// In en, this message translates to:
  /// **'This contact will be removed from this phone and from its accounts.'**
  String get deleteContactMessage;

  /// No description provided for @shareVcf.
  ///
  /// In en, this message translates to:
  /// **'vCard file (VCF)'**
  String get shareVcf;

  /// No description provided for @shareText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get shareText;

  /// No description provided for @qrCode.
  ///
  /// In en, this message translates to:
  /// **'QR code'**
  String get qrCode;

  /// No description provided for @blockContact.
  ///
  /// In en, this message translates to:
  /// **'Block contact'**
  String get blockContact;

  /// No description provided for @unblockContact.
  ///
  /// In en, this message translates to:
  /// **'Unblock contact'**
  String get unblockContact;

  /// No description provided for @askEveryTime.
  ///
  /// In en, this message translates to:
  /// **'Ask every time'**
  String get askEveryTime;

  /// No description provided for @contactNotFound.
  ///
  /// In en, this message translates to:
  /// **'Contact not found'**
  String get contactNotFound;

  /// No description provided for @addToFavourites.
  ///
  /// In en, this message translates to:
  /// **'Add to favourites'**
  String get addToFavourites;

  /// No description provided for @removeFromFavourites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favourites'**
  String get removeFromFavourites;

  /// No description provided for @defaultNumber.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultNumber;

  /// No description provided for @ringtone.
  ///
  /// In en, this message translates to:
  /// **'Ringtone'**
  String get ringtone;

  /// No description provided for @organization.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get organization;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @simForCalls.
  ///
  /// In en, this message translates to:
  /// **'SIM card for calls'**
  String get simForCalls;

  /// No description provided for @storageLocations.
  ///
  /// In en, this message translates to:
  /// **'Storage locations'**
  String get storageLocations;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @selectContact.
  ///
  /// In en, this message translates to:
  /// **'Select contact'**
  String get selectContact;

  /// No description provided for @noMatchingContacts.
  ///
  /// In en, this message translates to:
  /// **'No matching contacts'**
  String get noMatchingContacts;

  /// No description provided for @noCallsWithContact.
  ///
  /// In en, this message translates to:
  /// **'No calls with this contact yet'**
  String get noCallsWithContact;

  /// No description provided for @unlink.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get unlink;

  /// No description provided for @unlinkAll.
  ///
  /// In en, this message translates to:
  /// **'Unlink all'**
  String get unlinkAll;

  /// No description provided for @deleteContactsTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete contact?} other{Delete {count} contacts?}}'**
  String deleteContactsTitle(int count);

  /// No description provided for @deleteContactsMessage.
  ///
  /// In en, this message translates to:
  /// **'They will be removed from this phone and from their accounts.'**
  String get deleteContactsMessage;

  /// No description provided for @manageContacts.
  ///
  /// In en, this message translates to:
  /// **'Manage contacts'**
  String get manageContacts;

  /// No description provided for @contactsAccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Allow access to your contacts to see them here and show names for calls'**
  String get contactsAccessMessage;

  /// No description provided for @alphabetIndex.
  ///
  /// In en, this message translates to:
  /// **'Alphabet index'**
  String get alphabetIndex;

  /// No description provided for @createNewContact.
  ///
  /// In en, this message translates to:
  /// **'Create new contact'**
  String get createNewContact;

  /// No description provided for @updateExistingContact.
  ///
  /// In en, this message translates to:
  /// **'Update existing contact'**
  String get updateExistingContact;

  /// No description provided for @customLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom label'**
  String get customLabel;

  /// No description provided for @noContactsToExport.
  ///
  /// In en, this message translates to:
  /// **'No contacts to export'**
  String get noContactsToExport;

  /// No description provided for @couldNotOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the file'**
  String get couldNotOpenFile;

  /// No description provided for @noContactsInFile.
  ///
  /// In en, this message translates to:
  /// **'No contacts in this file'**
  String get noContactsInFile;

  /// No description provided for @importContactsTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Import 1 contact?} other{Import {count} contacts?}}'**
  String importContactsTitle(int count);

  /// No description provided for @importContactsMessage.
  ///
  /// In en, this message translates to:
  /// **'They will be saved to {account}.'**
  String importContactsMessage(String account);

  /// No description provided for @contactsImported.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Contact imported} other{{count} contacts imported}}'**
  String contactsImported(int count);

  /// No description provided for @couldNotImportContacts.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t import these contacts'**
  String get couldNotImportContacts;

  /// No description provided for @display.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get display;

  /// No description provided for @showContactPhotos.
  ///
  /// In en, this message translates to:
  /// **'Show contact\'s profile picture'**
  String get showContactPhotos;

  /// No description provided for @onlyContactsWithNumbers.
  ///
  /// In en, this message translates to:
  /// **'Only display contacts with numbers'**
  String get onlyContactsWithNumbers;

  /// No description provided for @contactsToDisplay.
  ///
  /// In en, this message translates to:
  /// **'Contacts to display'**
  String get contactsToDisplay;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @nameFormat.
  ///
  /// In en, this message translates to:
  /// **'Name format'**
  String get nameFormat;

  /// No description provided for @firstNameFirst.
  ///
  /// In en, this message translates to:
  /// **'First name first'**
  String get firstNameFirst;

  /// No description provided for @lastNameFirst.
  ///
  /// In en, this message translates to:
  /// **'Last name first'**
  String get lastNameFirst;

  /// No description provided for @defaultSaveLocation.
  ///
  /// In en, this message translates to:
  /// **'Default save location'**
  String get defaultSaveLocation;

  /// No description provided for @phoneDefault.
  ///
  /// In en, this message translates to:
  /// **'Phone default'**
  String get phoneDefault;

  /// No description provided for @importContacts.
  ///
  /// In en, this message translates to:
  /// **'Import contacts'**
  String get importContacts;

  /// No description provided for @fromVcf.
  ///
  /// In en, this message translates to:
  /// **'From a .vcf file'**
  String get fromVcf;

  /// No description provided for @exportContacts.
  ///
  /// In en, this message translates to:
  /// **'Export contacts'**
  String get exportContacts;

  /// No description provided for @asVcf.
  ///
  /// In en, this message translates to:
  /// **'As a .vcf file'**
  String get asVcf;

  /// No description provided for @simContacts.
  ///
  /// In en, this message translates to:
  /// **'SIM card contacts'**
  String get simContacts;

  /// No description provided for @mergeDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Merge duplicate contacts'**
  String get mergeDuplicates;

  /// No description provided for @simReadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the SIM card'**
  String get simReadError;

  /// No description provided for @simReading.
  ///
  /// In en, this message translates to:
  /// **'Reading the SIM card…'**
  String get simReading;

  /// No description provided for @simEmpty.
  ///
  /// In en, this message translates to:
  /// **'No contacts on the SIM card'**
  String get simEmpty;

  /// No description provided for @allSavedInContacts.
  ///
  /// In en, this message translates to:
  /// **'All saved in Contacts'**
  String get allSavedInContacts;

  /// No description provided for @importToContacts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Import {count} to Contacts}}'**
  String importToContacts(int count);

  /// No description provided for @mergeGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Merge {count} contacts?'**
  String mergeGroupTitle(String count);

  /// No description provided for @mergeGroupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Merge {count} contacts into {groups}?'**
  String mergeGroupsTitle(String count, String groups);

  /// No description provided for @mergeGroupMessage.
  ///
  /// In en, this message translates to:
  /// **'They become one contact named {name}, with all their numbers and details.'**
  String mergeGroupMessage(String name);

  /// No description provided for @mergeGroupsMessage.
  ///
  /// In en, this message translates to:
  /// **'Each group becomes one contact, with all its numbers and details.'**
  String get mergeGroupsMessage;

  /// REVIEW: English "=1" means one group merged, check the Italian reads naturally
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Contacts merged} other{{count} contacts merged}}'**
  String contactsMerged(int count);

  /// No description provided for @couldNotMergeContacts.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t merge these contacts'**
  String get couldNotMergeContacts;

  /// No description provided for @noDuplicateContacts.
  ///
  /// In en, this message translates to:
  /// **'No duplicate contacts'**
  String get noDuplicateContacts;

  /// No description provided for @mergeAll.
  ///
  /// In en, this message translates to:
  /// **'Merge all ({count})'**
  String mergeAll(String count);

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get recentSearches;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @foundCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} found}}'**
  String foundCount(int count);

  /// No description provided for @removeItem.
  ///
  /// In en, this message translates to:
  /// **'Remove {item}'**
  String removeItem(String item);

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @contactReadOnly.
  ///
  /// In en, this message translates to:
  /// **'This contact\'s account is read-only, so it can\'t be changed here'**
  String get contactReadOnly;

  /// No description provided for @couldNotSaveContact.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the contact'**
  String get couldNotSaveContact;

  /// No description provided for @alreadySavedAs.
  ///
  /// In en, this message translates to:
  /// **'{number} is already saved as {name}.'**
  String alreadySavedAs(String number, String name);

  /// No description provided for @alreadyInContacts.
  ///
  /// In en, this message translates to:
  /// **'{name} is already in your contacts.'**
  String alreadyInContacts(String name);

  /// No description provided for @alreadyInContactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Already in contacts'**
  String get alreadyInContactsTitle;

  /// No description provided for @saveAnotherAnyway.
  ///
  /// In en, this message translates to:
  /// **'{duplicate} Save another contact anyway?'**
  String saveAnotherAnyway(String duplicate);

  /// No description provided for @saveAnyway.
  ///
  /// In en, this message translates to:
  /// **'Save anyway'**
  String get saveAnyway;

  /// No description provided for @saveOrDiscard.
  ///
  /// In en, this message translates to:
  /// **'Save your changes or discard them?'**
  String get saveOrDiscard;

  /// No description provided for @couldNotLoadContactRetry.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the contact. Retry'**
  String get couldNotLoadContactRetry;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @addEmail.
  ///
  /// In en, this message translates to:
  /// **'Add email'**
  String get addEmail;

  /// No description provided for @addWebsite.
  ///
  /// In en, this message translates to:
  /// **'Add website'**
  String get addWebsite;

  /// No description provided for @relationships.
  ///
  /// In en, this message translates to:
  /// **'Relationships'**
  String get relationships;

  /// No description provided for @addRelationship.
  ///
  /// In en, this message translates to:
  /// **'Add relationship'**
  String get addRelationship;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get showMore;

  /// No description provided for @newContact.
  ///
  /// In en, this message translates to:
  /// **'New contact'**
  String get newContact;

  /// No description provided for @editContact.
  ///
  /// In en, this message translates to:
  /// **'Edit contact'**
  String get editContact;

  /// No description provided for @couldNotLoadAccounts.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load accounts'**
  String get couldNotLoadAccounts;

  /// No description provided for @loadingAccounts.
  ///
  /// In en, this message translates to:
  /// **'Loading accounts…'**
  String get loadingAccounts;

  /// No description provided for @saveToAccount.
  ///
  /// In en, this message translates to:
  /// **'Save to {account}'**
  String saveToAccount(String account);

  /// No description provided for @profilePicture.
  ///
  /// In en, this message translates to:
  /// **'Profile picture'**
  String get profilePicture;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @selectPhotos.
  ///
  /// In en, this message translates to:
  /// **'Select photos'**
  String get selectPhotos;

  /// No description provided for @deleteProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Delete profile picture'**
  String get deleteProfilePicture;

  /// No description provided for @couldNotOpenCamera.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the camera'**
  String get couldNotOpenCamera;

  /// No description provided for @followSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get followSystem;

  /// No description provided for @customRingtone.
  ///
  /// In en, this message translates to:
  /// **'Custom ringtone'**
  String get customRingtone;

  /// No description provided for @fromFollowingAccount.
  ///
  /// In en, this message translates to:
  /// **'From the following account'**
  String get fromFollowingAccount;

  /// No description provided for @fewerNameFields.
  ///
  /// In en, this message translates to:
  /// **'Fewer name fields'**
  String get fewerNameFields;

  /// No description provided for @moreNameFields.
  ///
  /// In en, this message translates to:
  /// **'More name fields'**
  String get moreNameFields;

  /// No description provided for @namePrefix.
  ///
  /// In en, this message translates to:
  /// **'Name prefix'**
  String get namePrefix;

  /// No description provided for @middleName.
  ///
  /// In en, this message translates to:
  /// **'Middle name'**
  String get middleName;

  /// No description provided for @nameSuffix.
  ///
  /// In en, this message translates to:
  /// **'Name suffix'**
  String get nameSuffix;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @number.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get number;

  /// No description provided for @workInfo.
  ///
  /// In en, this message translates to:
  /// **'Work info'**
  String get workInfo;

  /// No description provided for @company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// No description provided for @jobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job title'**
  String get jobTitle;

  /// No description provided for @department.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get department;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @street.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get street;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @stateProvince.
  ///
  /// In en, this message translates to:
  /// **'State/Province'**
  String get stateProvince;

  /// No description provided for @postalCode.
  ///
  /// In en, this message translates to:
  /// **'Postal code'**
  String get postalCode;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @addAddress.
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get addAddress;

  /// No description provided for @importantDate.
  ///
  /// In en, this message translates to:
  /// **'Important date'**
  String get importantDate;

  /// No description provided for @importantDates.
  ///
  /// In en, this message translates to:
  /// **'Important dates'**
  String get importantDates;

  /// No description provided for @addImportantDate.
  ///
  /// In en, this message translates to:
  /// **'Add important date'**
  String get addImportantDate;

  /// No description provided for @noGroupsInAccount.
  ///
  /// In en, this message translates to:
  /// **'No groups in this account'**
  String get noGroupsInAccount;

  /// No description provided for @groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groups;

  /// No description provided for @enterNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter number'**
  String get enterNumber;

  /// No description provided for @chooseFromContacts.
  ///
  /// In en, this message translates to:
  /// **'Choose from contacts'**
  String get chooseFromContacts;

  /// No description provided for @blockingNeedsScreeningRole.
  ///
  /// In en, this message translates to:
  /// **'Set Dialer as your caller ID & spam app to block these calls'**
  String get blockingNeedsScreeningRole;

  /// No description provided for @blockNumber.
  ///
  /// In en, this message translates to:
  /// **'Block number'**
  String get blockNumber;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @blockAndFilter.
  ///
  /// In en, this message translates to:
  /// **'Block & filter'**
  String get blockAndFilter;

  /// No description provided for @searchBlockedNumbers.
  ///
  /// In en, this message translates to:
  /// **'Search blocked numbers'**
  String get searchBlockedNumbers;

  /// No description provided for @blockingPaused.
  ///
  /// In en, this message translates to:
  /// **'Blocking rules are paused'**
  String get blockingPaused;

  /// No description provided for @blockingPausedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Another app screens your calls. Tap to let Dialer screen them.'**
  String get blockingPausedSubtitle;

  /// No description provided for @blockUnknown.
  ///
  /// In en, this message translates to:
  /// **'Block unknown/private numbers'**
  String get blockUnknown;

  /// No description provided for @blockUnknownSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Callers who hide their number'**
  String get blockUnknownSubtitle;

  /// No description provided for @blockNonContacts.
  ///
  /// In en, this message translates to:
  /// **'Block calls from numbers not in Contacts'**
  String get blockNonContacts;

  /// No description provided for @blockNonContactsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only your contacts can ring you'**
  String get blockNonContactsSubtitle;

  /// No description provided for @blockedNumbers.
  ///
  /// In en, this message translates to:
  /// **'Blocked numbers'**
  String get blockedNumbers;

  /// No description provided for @addNumber.
  ///
  /// In en, this message translates to:
  /// **'Add number'**
  String get addNumber;

  /// No description provided for @noMatchingBlocked.
  ///
  /// In en, this message translates to:
  /// **'No matching blocked numbers'**
  String get noMatchingBlocked;

  /// No description provided for @blockedCalls.
  ///
  /// In en, this message translates to:
  /// **'Blocked calls'**
  String get blockedCalls;

  /// REVIEW: In-call control label under a round button; check it fits
  ///
  /// In en, this message translates to:
  /// **'Add call'**
  String get addCall;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @editNote.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get editNote;

  /// No description provided for @videoCall.
  ///
  /// In en, this message translates to:
  /// **'Video call'**
  String get videoCall;

  /// REVIEW: In-call control label; AOSP uses "Disattiva audio", shortened to fit the button
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// REVIEW: In-call control label; AOSP uses "Metti in attesa", shortened to fit the button
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get hold;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @headset.
  ///
  /// In en, this message translates to:
  /// **'Headset'**
  String get headset;

  /// No description provided for @speaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get speaker;

  /// No description provided for @audioPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get audioPhone;

  /// No description provided for @wiredHeadset.
  ///
  /// In en, this message translates to:
  /// **'Wired headset'**
  String get wiredHeadset;

  /// No description provided for @endCall.
  ///
  /// In en, this message translates to:
  /// **'End call'**
  String get endCall;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @dialPad.
  ///
  /// In en, this message translates to:
  /// **'Dial pad'**
  String get dialPad;

  /// No description provided for @callNote.
  ///
  /// In en, this message translates to:
  /// **'Call note'**
  String get callNote;

  /// No description provided for @callNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Write something to remember from this call'**
  String get callNoteHint;

  /// No description provided for @conferenceCall.
  ///
  /// In en, this message translates to:
  /// **'Conference call'**
  String get conferenceCall;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @lineBusy.
  ///
  /// In en, this message translates to:
  /// **'Line busy'**
  String get lineBusy;

  /// No description provided for @callDeclined.
  ///
  /// In en, this message translates to:
  /// **'Call declined'**
  String get callDeclined;

  /// No description provided for @callCancelled.
  ///
  /// In en, this message translates to:
  /// **'Call cancelled'**
  String get callCancelled;

  /// No description provided for @callFailed.
  ///
  /// In en, this message translates to:
  /// **'Call failed'**
  String get callFailed;

  /// No description provided for @callEnded.
  ///
  /// In en, this message translates to:
  /// **'Call ended'**
  String get callEnded;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// REVIEW: followed by animated dots while dialing; AOSP uses "Chiamata in corso" for both dialing and active calls, "in uscita" keeps them apart
  ///
  /// In en, this message translates to:
  /// **'Calling'**
  String get calling;

  /// No description provided for @onHold.
  ///
  /// In en, this message translates to:
  /// **'On hold'**
  String get onHold;

  /// No description provided for @phoneCall.
  ///
  /// In en, this message translates to:
  /// **'Phone call'**
  String get phoneCall;

  /// No description provided for @hdCall.
  ///
  /// In en, this message translates to:
  /// **'HD call'**
  String get hdCall;

  /// No description provided for @switchToOnHold.
  ///
  /// In en, this message translates to:
  /// **'Switch to {name}, on hold'**
  String switchToOnHold(String name);

  /// No description provided for @switchCall.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get switchCall;

  /// No description provided for @declineWithSms.
  ///
  /// In en, this message translates to:
  /// **'Decline with SMS'**
  String get declineWithSms;

  /// No description provided for @noQuickReplies.
  ///
  /// In en, this message translates to:
  /// **'No quick replies saved'**
  String get noQuickReplies;

  /// No description provided for @answer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get answer;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @answerVerb.
  ///
  /// In en, this message translates to:
  /// **'answer'**
  String get answerVerb;

  /// No description provided for @declineVerb.
  ///
  /// In en, this message translates to:
  /// **'decline'**
  String get declineVerb;

  /// No description provided for @swipeUpDownHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe up to {up}, down to {down}'**
  String swipeUpDownHint(String up, String down);

  /// No description provided for @swipeUpHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe up to {action}'**
  String swipeUpHint(String action);

  /// No description provided for @effectsFull.
  ///
  /// In en, this message translates to:
  /// **'Full effects'**
  String get effectsFull;

  /// No description provided for @effectsReduced.
  ///
  /// In en, this message translates to:
  /// **'Reduced effects'**
  String get effectsReduced;

  /// No description provided for @effectsOff.
  ///
  /// In en, this message translates to:
  /// **'Effects off'**
  String get effectsOff;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @always.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get always;

  /// No description provided for @onlyWithHeadphones.
  ///
  /// In en, this message translates to:
  /// **'Only with headphones'**
  String get onlyWithHeadphones;

  /// No description provided for @incomingCallReminders.
  ///
  /// In en, this message translates to:
  /// **'Incoming call reminders'**
  String get incomingCallReminders;

  /// No description provided for @incomingFootnote.
  ///
  /// In en, this message translates to:
  /// **'Applies only to incoming calls received when your device is unlocked.'**
  String get incomingFootnote;

  /// No description provided for @banner.
  ///
  /// In en, this message translates to:
  /// **'Banner'**
  String get banner;

  /// No description provided for @fullScreen.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get fullScreen;

  /// No description provided for @announceCalls.
  ///
  /// In en, this message translates to:
  /// **'Announce incoming calls'**
  String get announceCalls;

  /// No description provided for @announceCallsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Says the caller\'s name while it rings'**
  String get announceCallsSubtitle;

  /// No description provided for @swipeUpToAnswer.
  ///
  /// In en, this message translates to:
  /// **'Swipe up to answer'**
  String get swipeUpToAnswer;

  /// No description provided for @swipeDownToAnswer.
  ///
  /// In en, this message translates to:
  /// **'Swipe down to answer'**
  String get swipeDownToAnswer;

  /// No description provided for @answerButtons.
  ///
  /// In en, this message translates to:
  /// **'Answer buttons'**
  String get answerButtons;

  /// No description provided for @twoButtons.
  ///
  /// In en, this message translates to:
  /// **'2 buttons'**
  String get twoButtons;

  /// No description provided for @oneButton.
  ///
  /// In en, this message translates to:
  /// **'1 button'**
  String get oneButton;

  /// No description provided for @answerCall.
  ///
  /// In en, this message translates to:
  /// **'Answer call'**
  String get answerCall;

  /// No description provided for @callScreenEffects.
  ///
  /// In en, this message translates to:
  /// **'Call screen effects'**
  String get callScreenEffects;

  /// REVIEW: "Glass and glow" names the design's frosted-glass look; keep it short
  ///
  /// In en, this message translates to:
  /// **'Glass and glow on the call screen'**
  String get callScreenEffectsSubtitle;

  /// No description provided for @secondsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 second} other{{count} seconds}}'**
  String secondsCount(int count);

  /// No description provided for @answerEndCalls.
  ///
  /// In en, this message translates to:
  /// **'Answer/End calls'**
  String get answerEndCalls;

  /// No description provided for @vibrateAnswerEnd.
  ///
  /// In en, this message translates to:
  /// **'Vibrate when your calls are answered/ended'**
  String get vibrateAnswerEnd;

  /// No description provided for @autoAnswer.
  ///
  /// In en, this message translates to:
  /// **'Auto-answer calls when connected to external audio device'**
  String get autoAnswer;

  /// No description provided for @autoAnswerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Includes Bluetooth and wired headphones'**
  String get autoAnswerSubtitle;

  /// No description provided for @autoAnswerDelay.
  ///
  /// In en, this message translates to:
  /// **'Delay auto answer'**
  String get autoAnswerDelay;

  /// No description provided for @replyWithSms.
  ///
  /// In en, this message translates to:
  /// **'Reply with SMS'**
  String get replyWithSms;

  /// No description provided for @speakerDefault.
  ///
  /// In en, this message translates to:
  /// **'Calls default to speaker'**
  String get speakerDefault;

  /// No description provided for @speakerDefaultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Doesn\'t take effect when external devices are connected.'**
  String get speakerDefaultSubtitle;

  /// No description provided for @quickDeclineMessage.
  ///
  /// In en, this message translates to:
  /// **'Quick decline message'**
  String get quickDeclineMessage;

  /// No description provided for @quickDeclineMessages.
  ///
  /// In en, this message translates to:
  /// **'Quick decline messages'**
  String get quickDeclineMessages;

  /// No description provided for @quickDeclineHint.
  ///
  /// In en, this message translates to:
  /// **'Sent when you decline a call with a message'**
  String get quickDeclineHint;

  /// No description provided for @addMessage.
  ///
  /// In en, this message translates to:
  /// **'Add message'**
  String get addMessage;

  /// No description provided for @settingNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'This phone doesn\'t have that setting'**
  String get settingNotAvailable;

  /// No description provided for @notDefaultApp.
  ///
  /// In en, this message translates to:
  /// **'Not your default phone app'**
  String get notDefaultApp;

  /// No description provided for @notDefaultAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Incoming calls use another app'**
  String get notDefaultAppSubtitle;

  /// No description provided for @notificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off'**
  String get notificationsOff;

  /// No description provided for @notificationsOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You won\'t see incoming or missed calls'**
  String get notificationsOffSubtitle;

  /// No description provided for @fullScreenOff.
  ///
  /// In en, this message translates to:
  /// **'Full-screen calls are off'**
  String get fullScreenOff;

  /// No description provided for @fullScreenOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Incoming calls only show as a notification'**
  String get fullScreenOffSubtitle;

  /// No description provided for @blockingPausedShort.
  ///
  /// In en, this message translates to:
  /// **'Another app screens your calls'**
  String get blockingPausedShort;

  /// No description provided for @bluetoothNamesHidden.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth names hidden'**
  String get bluetoothNamesHidden;

  /// No description provided for @bluetoothNamesHiddenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Calls can\'t tell your watch from your earbuds'**
  String get bluetoothNamesHiddenSubtitle;

  /// No description provided for @fix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get fix;

  /// No description provided for @callSettings.
  ///
  /// In en, this message translates to:
  /// **'Call settings'**
  String get callSettings;

  /// No description provided for @needsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get needsAttention;

  /// No description provided for @callerIdentification.
  ///
  /// In en, this message translates to:
  /// **'Caller identification'**
  String get callerIdentification;

  /// No description provided for @callerIdSpamApp.
  ///
  /// In en, this message translates to:
  /// **'Caller ID & spam app'**
  String get callerIdSpamApp;

  /// No description provided for @carrierSettings.
  ///
  /// In en, this message translates to:
  /// **'Carrier-related settings'**
  String get carrierSettings;

  /// No description provided for @softwareUpdate.
  ///
  /// In en, this message translates to:
  /// **'Software update'**
  String get softwareUpdate;

  /// No description provided for @helpFeedback.
  ///
  /// In en, this message translates to:
  /// **'Help & feedback'**
  String get helpFeedback;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @aboutOneDialer.
  ///
  /// In en, this message translates to:
  /// **'About One Dialer'**
  String get aboutOneDialer;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @openDetails.
  ///
  /// In en, this message translates to:
  /// **'Open details'**
  String get openDetails;

  /// No description provided for @writeInKeypad.
  ///
  /// In en, this message translates to:
  /// **'Write in keypad'**
  String get writeInKeypad;

  /// No description provided for @twoCallButtons.
  ///
  /// In en, this message translates to:
  /// **'Two Call buttons'**
  String get twoCallButtons;

  /// No description provided for @chooseSimAndCall.
  ///
  /// In en, this message translates to:
  /// **'Choose SIM and call'**
  String get chooseSimAndCall;

  /// No description provided for @tapRecentCall.
  ///
  /// In en, this message translates to:
  /// **'Tap a recent call'**
  String get tapRecentCall;

  /// No description provided for @chooseSimForCalls.
  ///
  /// In en, this message translates to:
  /// **'Choose SIM for calls'**
  String get chooseSimForCalls;

  /// No description provided for @chooseSimSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Dual SIM with no default SIM'**
  String get chooseSimSubtitle;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @reduceVisualEffects.
  ///
  /// In en, this message translates to:
  /// **'Reduce visual effects'**
  String get reduceVisualEffects;

  /// No description provided for @reduceVisualEffectsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Less blur runs smoother on slower phones'**
  String get reduceVisualEffectsSubtitle;

  /// No description provided for @appIcon.
  ///
  /// In en, this message translates to:
  /// **'App icon'**
  String get appIcon;

  /// No description provided for @appIconGlossy.
  ///
  /// In en, this message translates to:
  /// **'Glossy'**
  String get appIconGlossy;

  /// No description provided for @appIconClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get appIconClassic;

  /// No description provided for @appIconFootnote.
  ///
  /// In en, this message translates to:
  /// **'Changes both the Phone and Contacts icons. The launcher may take a few seconds, and icons on the home screen may need adding again from the app drawer.'**
  String get appIconFootnote;

  /// No description provided for @callScreenEdgeGlow.
  ///
  /// In en, this message translates to:
  /// **'Call screen edge glow'**
  String get callScreenEdgeGlow;

  /// No description provided for @darkModeEdgeGlow.
  ///
  /// In en, this message translates to:
  /// **'Dark mode edge glow'**
  String get darkModeEdgeGlow;

  /// No description provided for @edgeGlowClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get edgeGlowClassic;

  /// No description provided for @edgeGlowSoft.
  ///
  /// In en, this message translates to:
  /// **'Soft'**
  String get edgeGlowSoft;

  /// No description provided for @edgeGlowBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get edgeGlowBold;

  /// No description provided for @navBarStyle.
  ///
  /// In en, this message translates to:
  /// **'Nav bar style'**
  String get navBarStyle;

  /// No description provided for @navBarFrosted.
  ///
  /// In en, this message translates to:
  /// **'Frosted'**
  String get navBarFrosted;

  /// No description provided for @navBarLiquid.
  ///
  /// In en, this message translates to:
  /// **'Liquid glass'**
  String get navBarLiquid;

  /// No description provided for @navBarGlass.
  ///
  /// In en, this message translates to:
  /// **'Glass effect'**
  String get navBarGlass;

  /// No description provided for @navGlassPremium.
  ///
  /// In en, this message translates to:
  /// **'Full refraction'**
  String get navGlassPremium;

  /// No description provided for @navGlassStandard.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get navGlassStandard;

  /// No description provided for @navGlassMinimal.
  ///
  /// In en, this message translates to:
  /// **'Blur only'**
  String get navGlassMinimal;

  /// No description provided for @callsFromOtherApps.
  ///
  /// In en, this message translates to:
  /// **'Calls from other apps'**
  String get callsFromOtherApps;

  /// No description provided for @callsFromOtherAppsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show WhatsApp and other apps\' calls in Recents'**
  String get callsFromOtherAppsSubtitle;

  /// No description provided for @manageContactsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Display, save location, import and export, SIM, duplicates'**
  String get manageContactsSubtitle;

  /// No description provided for @googleContactsSync.
  ///
  /// In en, this message translates to:
  /// **'Google Contacts sync'**
  String get googleContactsSync;

  /// No description provided for @googleContactsSyncSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Which accounts sync, and backing up phone contacts'**
  String get googleContactsSyncSubtitle;

  /// No description provided for @defaultApps.
  ///
  /// In en, this message translates to:
  /// **'Default apps'**
  String get defaultApps;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set One Dialer as your default phone app'**
  String get setupTitle;

  /// No description provided for @setupBody.
  ///
  /// In en, this message translates to:
  /// **'Needed to make and answer calls, show your call history and contacts, and block numbers.'**
  String get setupBody;

  /// No description provided for @settingUp.
  ///
  /// In en, this message translates to:
  /// **'Setting up…'**
  String get settingUp;

  /// REVIEW: Google Play prominent disclosure: must match the privacy policy and Android's Italian permission names
  ///
  /// In en, this message translates to:
  /// **'One Dialer uses Phone to make and manage calls on your SIMs, Call history for Recents and missed calls, Contacts for names, photos and search, and Notifications for incoming, ongoing and missed calls. Your calls, call history and contacts never leave your phone. Crash reports (no personal data) help fix bugs.'**
  String get setupDisclosure;

  /// No description provided for @installedDirectly.
  ///
  /// In en, this message translates to:
  /// **'Installed directly'**
  String get installedDirectly;

  /// No description provided for @anotherAppStore.
  ///
  /// In en, this message translates to:
  /// **'Another app store'**
  String get anotherAppStore;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About {app}'**
  String aboutApp(String app);

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailable;

  /// No description provided for @versionUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Version up to date'**
  String get versionUpToDate;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checking;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @build.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get build;

  /// No description provided for @installedFrom.
  ///
  /// In en, this message translates to:
  /// **'Installed from'**
  String get installedFrom;

  /// No description provided for @device.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get device;

  /// No description provided for @androidVersion.
  ///
  /// In en, this message translates to:
  /// **'Android version'**
  String get androidVersion;

  /// No description provided for @openSourceLicences.
  ///
  /// In en, this message translates to:
  /// **'Open source licences'**
  String get openSourceLicences;

  /// No description provided for @changelog.
  ///
  /// In en, this message translates to:
  /// **'Changelog'**
  String get changelog;

  /// No description provided for @installedOn.
  ///
  /// In en, this message translates to:
  /// **'Installed {date}'**
  String installedOn(String date);

  /// No description provided for @earlierVersions.
  ///
  /// In en, this message translates to:
  /// **'Earlier versions'**
  String get earlierVersions;

  /// No description provided for @aboutThisUpdate.
  ///
  /// In en, this message translates to:
  /// **'About this update'**
  String get aboutThisUpdate;

  /// No description provided for @reportLag.
  ///
  /// In en, this message translates to:
  /// **'Report lag'**
  String get reportLag;

  /// REVIEW: Privacy wording: must stay accurate to what the report sends
  ///
  /// In en, this message translates to:
  /// **'Send recent performance timings, screen and action names, and device details to help find slowdowns. Phone numbers, contacts and messages are not included.'**
  String get reportLagMessage;

  /// No description provided for @sendReport.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get sendReport;

  /// No description provided for @reportUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Reporting unavailable or recently requested. Try again in a minute.'**
  String get reportUnavailable;

  /// No description provided for @reportQueued.
  ///
  /// In en, this message translates to:
  /// **'Report queued'**
  String get reportQueued;

  /// No description provided for @reportQueuedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your report is saved for upload when reporting is available. Share this ID with your feedback:\\n\\n{id}'**
  String reportQueuedMessage(String id);

  /// No description provided for @copyId.
  ///
  /// In en, this message translates to:
  /// **'Copy ID'**
  String get copyId;

  /// No description provided for @reportIdCopied.
  ///
  /// In en, this message translates to:
  /// **'Report ID copied'**
  String get reportIdCopied;

  /// No description provided for @noEmailApp.
  ///
  /// In en, this message translates to:
  /// **'No email app found'**
  String get noEmailApp;

  /// No description provided for @noBrowser.
  ///
  /// In en, this message translates to:
  /// **'No browser found'**
  String get noBrowser;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get sendFeedback;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// No description provided for @downloadStopped.
  ///
  /// In en, this message translates to:
  /// **'The download stopped. Try again when you\'re connected.'**
  String get downloadStopped;

  /// No description provided for @couldNotInstallUpdate.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t install the update. Try again.'**
  String get couldNotInstallUpdate;

  /// No description provided for @updateCancelled.
  ///
  /// In en, this message translates to:
  /// **'Update cancelled. You can download it any time from here.'**
  String get updateCancelled;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Connect and try again.'**
  String get noInternet;

  /// No description provided for @couldNotDownloadUpdate.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t download the update. Try again.'**
  String get couldNotDownloadUpdate;

  /// No description provided for @softwareInformation.
  ///
  /// In en, this message translates to:
  /// **'Software information'**
  String get softwareInformation;

  /// No description provided for @autoDownload.
  ///
  /// In en, this message translates to:
  /// **'Auto download'**
  String get autoDownload;

  /// No description provided for @downloadAndInstall.
  ///
  /// In en, this message translates to:
  /// **'Download and install'**
  String get downloadAndInstall;

  /// No description provided for @installAndRestart.
  ///
  /// In en, this message translates to:
  /// **'Install and restart'**
  String get installAndRestart;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get downloading;

  /// No description provided for @noNetwork.
  ///
  /// In en, this message translates to:
  /// **'No network connection'**
  String get noNetwork;

  /// No description provided for @notFromPlay.
  ///
  /// In en, this message translates to:
  /// **'Updates come from Google Play. This copy wasn\'t installed from Play.'**
  String get notFromPlay;

  /// No description provided for @couldNotReachPlay.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach Google Play'**
  String get couldNotReachPlay;

  /// No description provided for @softwareVersion.
  ///
  /// In en, this message translates to:
  /// **'Software version'**
  String get softwareVersion;

  /// No description provided for @closedBeta.
  ///
  /// In en, this message translates to:
  /// **'Closed beta'**
  String get closedBeta;

  /// No description provided for @newVersionAvailable.
  ///
  /// In en, this message translates to:
  /// **'A new version is available'**
  String get newVersionAvailable;

  /// No description provided for @autoDownloadExplainer.
  ///
  /// In en, this message translates to:
  /// **'When One Dialer checks Google Play for updates as you open it. Updates only install when you tap Download and install.'**
  String get autoDownloadExplainer;

  /// No description provided for @autoUpdateNeverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only when you tap Check for updates'**
  String get autoUpdateNeverSubtitle;

  /// No description provided for @autoUpdateAlwaysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Checking uses very little data'**
  String get autoUpdateAlwaysSubtitle;

  /// No description provided for @autoUpdateNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get autoUpdateNever;

  /// No description provided for @autoUpdateWifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Using Wi-Fi only'**
  String get autoUpdateWifiOnly;

  /// No description provided for @autoUpdateAlways.
  ///
  /// In en, this message translates to:
  /// **'Using Wi-Fi or mobile data'**
  String get autoUpdateAlways;

  /// No description provided for @settingsCalls.
  ///
  /// In en, this message translates to:
  /// **'Calls'**
  String get settingsCalls;

  /// No description provided for @settingsDialing.
  ///
  /// In en, this message translates to:
  /// **'Dialing'**
  String get settingsDialing;

  /// No description provided for @settingsSpamBlocking.
  ///
  /// In en, this message translates to:
  /// **'Spam & blocking'**
  String get settingsSpamBlocking;

  /// No description provided for @settingsPersonalisation.
  ///
  /// In en, this message translates to:
  /// **'Personalisation'**
  String get settingsPersonalisation;

  /// No description provided for @settingsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneral;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @displayAndEffects.
  ///
  /// In en, this message translates to:
  /// **'Display & effects'**
  String get displayAndEffects;

  /// No description provided for @keypadAndRecents.
  ///
  /// In en, this message translates to:
  /// **'Keypad & recents'**
  String get keypadAndRecents;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
