// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get languageName => 'Türkçe';

  @override
  String get cancel => 'İptal';

  @override
  String get save => 'Kaydet';

  @override
  String get delete => 'Sil';

  @override
  String get dismiss => 'Kapat';

  @override
  String get dismissMenu => 'Menüyü kapat';

  @override
  String get share => 'Paylaş';

  @override
  String get more => 'Diğer';

  @override
  String get back => 'Geri';

  @override
  String get soon => 'Yakında';

  @override
  String get all => 'Tümü';

  @override
  String get selectAll => 'Tümünü seç';

  @override
  String get deselectAll => 'Seçimi kaldır';

  @override
  String get selectItems => 'Öğe seçin';

  @override
  String get search => 'Ara';

  @override
  String get searchContacts => 'Kişilerde ara';

  @override
  String get clear => 'Temizle';

  @override
  String get clearSearch => 'Aramayı temizle';

  @override
  String get searchByVoice => 'Sesle ara';

  @override
  String get scrollToTop => 'Başa dön';

  @override
  String dateWheelDay(String day) {
    return 'Gün $day';
  }

  @override
  String dateWheelYear(String year) {
    return 'Yıl $year';
  }

  @override
  String get navCalls => 'Aramalar';

  @override
  String get navContacts => 'Kişiler';

  @override
  String get returnToCall => 'Aramaya dön';

  @override
  String get createContact => 'Kişi oluştur';

  @override
  String get showKeypad => 'Tuş takımını göster';

  @override
  String get settingsLanguageHeader => 'Dil';

  @override
  String get settingsAppLanguage => 'Uygulama dili';

  @override
  String get settingsAppLanguageSubtitle => 'Yalnızca bu uygulamayı değiştirir';

  @override
  String get settingsLanguageSystem => 'Telefonla aynı';

  @override
  String get settingsAndroidLanguage => 'Android dil ayarları';

  @override
  String get settingsAndroidLanguageSubtitle =>
      'Dili Android ayarlarından seçin';

  @override
  String get call => 'Ara';

  @override
  String get message => 'Mesaj';

  @override
  String get add => 'Ekle';

  @override
  String get block => 'Engelle';

  @override
  String get unblock => 'Engeli kaldır';

  @override
  String get settings => 'Ayarlar';

  @override
  String get notes => 'Notlar';

  @override
  String get moreOptions => 'Diğer seçenekler';

  @override
  String get voicemail => 'Sesli mesaj';

  @override
  String get today => 'Bugün';

  @override
  String get yesterday => 'Dün';

  @override
  String durationHoursMinutes(String hours, String minutes) {
    return '$hours sa $minutes dk';
  }

  @override
  String durationMinutesSeconds(String minutes, String seconds) {
    return '$minutes dk $seconds sn';
  }

  @override
  String durationSeconds(String seconds) {
    return '$seconds sn';
  }

  @override
  String get privateNumber => 'Gizli numara';

  @override
  String appVideo(String app) {
    return '$app görüntülü';
  }

  @override
  String videoCallOnApp(String app) {
    return '$app ile görüntülü arama';
  }

  @override
  String callOnApp(String app) {
    return '$app ile ara';
  }

  @override
  String get callTypeOutgoing => 'Giden arama';

  @override
  String get callTypeMissed => 'Cevapsız arama';

  @override
  String get callTypeRejected => 'Reddedilen arama';

  @override
  String get callTypeBlocked => 'Engellenen arama';

  @override
  String get callTypeVoicemail => 'Sesli mesaj';

  @override
  String get callNotConnected => '(Bağlanmadı)';

  @override
  String get callTypeIncoming => 'Gelen arama';

  @override
  String get speedDialNoNumber => 'Hızlı arama numarası yok';

  @override
  String speedDialAssignPrompt(String digit) {
    return '$digit tuşuna bir kişi atansın mı?';
  }

  @override
  String get assign => 'Ata';

  @override
  String get couldNotPlaceCall => 'Arama yapılamadı';

  @override
  String get keypadNumberEmpty => 'Numara, boş. Yapıştırmak için basılı tutun';

  @override
  String keypadNumber(String number) {
    return 'Numara $number';
  }

  @override
  String get keypadZeroHint => '0, artı için basılı tutun';

  @override
  String get keypadVoicemailHint => '1, sesli mesaj için basılı tutun';

  @override
  String keypadDigitHint(String digit) {
    return '$digit, hızlı arama için basılı tutun';
  }

  @override
  String get hideKeypad => 'Tuş takımını gizle';

  @override
  String callWithSim(String slot, String sim) {
    return 'SIM $slot ile ara, $sim';
  }

  @override
  String get keypadDeleteHint => 'Sil, tümünü silmek için basılı tutun';

  @override
  String get addPause => '2 sn duraklama ekle';

  @override
  String get addWait => 'Bekleme ekle';

  @override
  String get sendMessage => 'Mesaj gönder';

  @override
  String get speedDialNumbers => 'Hızlı arama numaraları';

  @override
  String speedDialKey(String digit) {
    return 'Hızlı arama $digit';
  }

  @override
  String get speedDial => 'Hızlı arama';

  @override
  String get speedDialAssignContacts => 'Kişi ata';

  @override
  String speedDialRemoved(String name, String digit) {
    return '$name, $digit tuşundan kaldırıldı';
  }

  @override
  String get callLogs => 'Arama kayıtları';

  @override
  String get deleteCallHistory => 'Arama geçmişini sil';

  @override
  String deleteCallsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arama silinsin mi?',
      one: 'Arama silinsin mi?',
    );
    return '$_temp0';
  }

  @override
  String get deleteCallsMessage =>
      'Seçilen arama geçmişi bu telefondan kaldırılacak.';

  @override
  String get couldNotDeleteCalls => 'Arama geçmişi silinemedi. Tekrar deneyin.';

  @override
  String get showAllCalls => 'Tüm aramaları göster';

  @override
  String get showAppCallsOnly => 'Yalnızca uygulama aramalarını göster';

  @override
  String get showBlockedCalls => 'Engellenen aramaları göster';

  @override
  String get hideBlockedCalls => 'Engellenen aramaları gizle';

  @override
  String blockNumberTitle(String number) {
    return '$number engellensin mi?';
  }

  @override
  String blockNumbersTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count numara engellensin mi?',
      one: '1 numara engellensin mi?',
    );
    return '$_temp0';
  }

  @override
  String get blockNumbersMessage => 'Engellenen numaralardan arama almazsınız.';

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seçildi',
    );
    return '$_temp0';
  }

  @override
  String get recentsSetDefaultMessage =>
      'Son aramaları görmek için Dialer\'ı varsayılan telefon uygulaması yapın';

  @override
  String get setAsDefault => 'Varsayılan yap';

  @override
  String get recentsNoAppCalls => 'Uygulama araması yok';

  @override
  String get recentsNoRecentCalls => 'Son arama yok';

  @override
  String get recentsNoMissedCalls => 'Cevapsız arama yok';

  @override
  String get recentsFilterMissed => 'Cevapsız';

  @override
  String get addToContacts => 'Kişilere ekle';

  @override
  String get callDetails => 'Arama ayrıntıları';

  @override
  String contactLabel(String label) {
    String _temp0 = intl.Intl.selectLogic(label, {
      'mobile': 'Mobil',
      'home': 'Ev',
      'work': 'İş',
      'workMobile': 'İş mobil',
      'main': 'Ana',
      'phone': 'Telefon',
      'faxHome': 'Ev faksı',
      'faxWork': 'İş faksı',
      'faxOther': 'Diğer faks',
      'pager': 'Çağrı cihazı',
      'workPager': 'İş çağrı cihazı',
      'school': 'Okul',
      'car': 'Araba',
      'companyMain': 'Şirket ana hattı',
      'callback': 'Geri arama',
      'assistant': 'Asistan',
      'birthday': 'Doğum günü',
      'anniversary': 'Yıldönümü',
      'homepage': 'Ana sayfa',
      'blog': 'Blog',
      'profile': 'Profil',
      'brother': 'Erkek kardeş',
      'sister': 'Kız kardeş',
      'child': 'Çocuk',
      'father': 'Baba',
      'mother': 'Anne',
      'parent': 'Ebeveyn',
      'friend': 'Arkadaş',
      'manager': 'Yönetici',
      'partner': 'Partner',
      'relative': 'Akraba',
      'spouse': 'Eş',
      'domesticPartner': 'Hayat arkadaşı',
      'referredBy': 'Öneren',
      'other': 'Diğer',
    });
    return '$_temp0';
  }

  @override
  String addressLabel(String label) {
    return 'Adres ($label)';
  }

  @override
  String get accountSamsung => 'Samsung hesabı';

  @override
  String get accountSimServiceNumbers => 'SIM servis numaraları';

  @override
  String get accountSimCard => 'SIM kart';

  @override
  String get accountThisDevice => 'Bu cihaz';

  @override
  String contactsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kişi',
      one: '1 kişi',
    );
    return '$_temp0';
  }

  @override
  String get justOnce => 'Yalnızca bir kez';

  @override
  String get close => 'Kapat';

  @override
  String get ok => 'Tamam';

  @override
  String get edit => 'Düzenle';

  @override
  String get video => 'Görüntülü';

  @override
  String get videoCallMark => 'Görüntülü arama';

  @override
  String get wifiCallMark => 'Wi-Fi araması';

  @override
  String get volteCall => 'VoLTE araması';

  @override
  String get vonrCall => '5G sesli arama';

  @override
  String get remove => 'Kaldır';

  @override
  String get custom => 'Özel';

  @override
  String get allow => 'İzin ver';

  @override
  String get select => 'Seç';

  @override
  String get merge => 'Birleştir';

  @override
  String get import => 'İçe aktar';

  @override
  String get qrScanHint => 'Bu kişiyi eklemek için telefon kamerasıyla tarayın';

  @override
  String deleteContactTitle(String name) {
    return '$name silinsin mi?';
  }

  @override
  String get deleteContactMessage =>
      'Bu kişi bu telefondan ve hesaplarından kaldırılacak.';

  @override
  String get shareVcf => 'vCard dosyası (VCF)';

  @override
  String get shareText => 'Metin';

  @override
  String get qrCode => 'QR kod';

  @override
  String get blockContact => 'Kişiyi engelle';

  @override
  String get unblockContact => 'Kişinin engelini kaldır';

  @override
  String get askEveryTime => 'Her seferinde sor';

  @override
  String get contactNotFound => 'Kişi bulunamadı';

  @override
  String get addToFavourites => 'Favorilere ekle';

  @override
  String get removeFromFavourites => 'Favorilerden kaldır';

  @override
  String get defaultNumber => 'Varsayılan';

  @override
  String get ringtone => 'Zil sesi';

  @override
  String get organization => 'İş';

  @override
  String get website => 'Web sitesi';

  @override
  String get simForCalls => 'Aramalar için SIM kart';

  @override
  String get storageLocations => 'Depolama konumları';

  @override
  String get viewAll => 'Tümünü gör';

  @override
  String get selectContact => 'Kişi seçin';

  @override
  String get noMatchingContacts => 'Eşleşen kişi yok';

  @override
  String get noCallsWithContact => 'Bu kişiyle henüz arama yok';

  @override
  String get unlink => 'Bağlantıyı kaldır';

  @override
  String get unlinkAll => 'Tüm bağlantıları kaldır';

  @override
  String deleteContactsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kişi silinsin mi?',
      one: 'Kişi silinsin mi?',
    );
    return '$_temp0';
  }

  @override
  String get deleteContactsMessage =>
      'Bu telefondan ve hesaplarından kaldırılacaklar.';

  @override
  String get manageContacts => 'Kişileri yönet';

  @override
  String get contactsAccessMessage =>
      'Kişilerinizi burada görmek ve aramalarda adları göstermek için kişilere erişime izin verin';

  @override
  String get alphabetIndex => 'Alfabe dizini';

  @override
  String get createNewContact => 'Yeni kişi oluştur';

  @override
  String get updateExistingContact => 'Mevcut kişiyi güncelle';

  @override
  String get customLabel => 'Özel etiket';

  @override
  String get noContactsToExport => 'Dışa aktarılacak kişi yok';

  @override
  String get couldNotOpenFile => 'Dosya açılamadı';

  @override
  String get noContactsInFile => 'Bu dosyada kişi yok';

  @override
  String importContactsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kişi içe aktarılsın mı?',
      one: '1 kişi içe aktarılsın mı?',
    );
    return '$_temp0';
  }

  @override
  String importContactsMessage(String account) {
    return 'Şuraya kaydedilecekler: $account.';
  }

  @override
  String contactsImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kişi içe aktarıldı',
      one: 'Kişi içe aktarıldı',
    );
    return '$_temp0';
  }

  @override
  String get couldNotImportContacts => 'Bu kişiler içe aktarılamadı';

  @override
  String get display => 'Görünüm';

  @override
  String get showContactPhotos => 'Kişinin profil resmini göster';

  @override
  String get onlyContactsWithNumbers =>
      'Yalnızca numarası olan kişileri göster';

  @override
  String get contactsToDisplay => 'Gösterilecek kişiler';

  @override
  String get sortBy => 'Sıralama';

  @override
  String get firstName => 'Ad';

  @override
  String get lastName => 'Soyad';

  @override
  String get nameFormat => 'Ad biçimi';

  @override
  String get firstNameFirst => 'Önce ad';

  @override
  String get lastNameFirst => 'Önce soyad';

  @override
  String get defaultSaveLocation => 'Varsayılan kayıt yeri';

  @override
  String get phoneDefault => 'Telefon varsayılanı';

  @override
  String get importContacts => 'Kişileri içe aktar';

  @override
  String get fromVcf => '.vcf dosyasından';

  @override
  String get exportContacts => 'Kişileri dışa aktar';

  @override
  String get asVcf => '.vcf dosyası olarak';

  @override
  String get simContacts => 'SIM kart kişileri';

  @override
  String get mergeDuplicates => 'Yinelenen kişileri birleştir';

  @override
  String get simReadError => 'SIM kart okunamadı';

  @override
  String get simReading => 'SIM kart okunuyor…';

  @override
  String get simEmpty => 'SIM kartta kişi yok';

  @override
  String get allSavedInContacts => 'Tümü Kişiler\'e kaydedildi';

  @override
  String importToContacts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kişiyi Kişiler\'e aktar',
    );
    return '$_temp0';
  }

  @override
  String mergeGroupTitle(String count) {
    return '$count kişi birleştirilsin mi?';
  }

  @override
  String mergeGroupMessage(String name) {
    return 'Tüm numaraları ve bilgileriyle $name adlı tek bir kişi olurlar.';
  }

  @override
  String contactsMerged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kişi birleştirildi',
      one: 'Kişiler birleştirildi',
    );
    return '$_temp0';
  }

  @override
  String get couldNotMergeContacts => 'Bu kişiler birleştirilemedi';

  @override
  String get noDuplicateContacts => 'Yinelenen kişi yok';

  @override
  String get recentSearches => 'Son aramalar';

  @override
  String get clearAll => 'Tümünü temizle';

  @override
  String get noResultsFound => 'Sonuç bulunamadı';

  @override
  String foundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bulundu',
    );
    return '$_temp0';
  }

  @override
  String removeItem(String item) {
    return 'Kaldır: $item';
  }

  @override
  String get done => 'Bitti';

  @override
  String get discard => 'Vazgeç';

  @override
  String get change => 'Değiştir';

  @override
  String get contactReadOnly =>
      'Bu kişinin hesabı salt okunur, bu yüzden burada değiştirilemez';

  @override
  String get couldNotSaveContact => 'Kişi kaydedilemedi';

  @override
  String alreadySavedAs(String number, String name) {
    return '$number zaten $name olarak kayıtlı.';
  }

  @override
  String alreadyInContacts(String name) {
    return '$name zaten kişilerinizde.';
  }

  @override
  String get alreadyInContactsTitle => 'Zaten kişilerde';

  @override
  String saveAnotherAnyway(String duplicate) {
    return '$duplicate Yine de başka bir kişi kaydedilsin mi?';
  }

  @override
  String get saveAnyway => 'Yine de kaydet';

  @override
  String get saveOrDiscard => 'Değişiklikler kaydedilsin mi?';

  @override
  String get couldNotLoadContactRetry => 'Kişi yüklenemedi. Tekrar dene';

  @override
  String get email => 'E-posta';

  @override
  String get addEmail => 'E-posta ekle';

  @override
  String get addWebsite => 'Web sitesi ekle';

  @override
  String get relationships => 'İlişkiler';

  @override
  String get addRelationship => 'İlişki ekle';

  @override
  String get showLess => 'Daha az göster';

  @override
  String get showMore => 'Daha fazla göster';

  @override
  String get newContact => 'Yeni kişi';

  @override
  String get addToExistingContact => 'Mevcut kişiye ekle';

  @override
  String get editContact => 'Kişiyi düzenle';

  @override
  String get couldNotLoadAccounts => 'Hesaplar yüklenemedi';

  @override
  String get loadingAccounts => 'Hesaplar yükleniyor…';

  @override
  String saveToAccount(String account) {
    return 'Kaydet: $account';
  }

  @override
  String get profilePicture => 'Profil resmi';

  @override
  String get camera => 'Kamera';

  @override
  String get selectPhotos => 'Fotoğraf seç';

  @override
  String get deleteProfilePicture => 'Profil resmini sil';

  @override
  String get couldNotOpenCamera => 'Kamera açılamadı';

  @override
  String get couldNotOpenApp => 'Uygulama açılamadı';

  @override
  String get followSystem => 'Sistemi izle';

  @override
  String get customRingtone => 'Özel zil sesi';

  @override
  String get fromFollowingAccount => 'Şu hesaptan';

  @override
  String get fewerNameFields => 'Daha az ad alanı';

  @override
  String get moreNameFields => 'Daha fazla ad alanı';

  @override
  String get namePrefix => 'Ad öneki';

  @override
  String get middleName => 'İkinci ad';

  @override
  String get nameSuffix => 'Ad soneki';

  @override
  String get name => 'Ad';

  @override
  String get number => 'Numara';

  @override
  String get workInfo => 'İş bilgisi';

  @override
  String get company => 'Şirket';

  @override
  String get jobTitle => 'Unvan';

  @override
  String get department => 'Departman';

  @override
  String get address => 'Adres';

  @override
  String get street => 'Sokak';

  @override
  String get city => 'Şehir';

  @override
  String get stateProvince => 'İl/Bölge';

  @override
  String get postalCode => 'Posta kodu';

  @override
  String get country => 'Ülke';

  @override
  String get addAddress => 'Adres ekle';

  @override
  String get importantDate => 'Önemli tarih';

  @override
  String get importantDates => 'Önemli tarihler';

  @override
  String get addImportantDate => 'Önemli tarih ekle';

  @override
  String get noGroupsInAccount => 'Bu hesapta grup yok';

  @override
  String get groups => 'Gruplar';

  @override
  String get enterNumber => 'Numara girin';

  @override
  String get chooseFromContacts => 'Kişilerden seç';

  @override
  String get blockingNeedsScreeningRole =>
      'Bu aramaları engellemek için Dialer\'ı arayan kimliği ve spam uygulaması yapın';

  @override
  String get phoneNumber => 'Telefon numarası';

  @override
  String get blockAndFilter => 'Engelle ve filtrele';

  @override
  String get blockingPaused => 'Engelleme kuralları duraklatıldı';

  @override
  String get blockingPausedSubtitle =>
      'Aramalarınızı başka bir uygulama denetliyor. Dialer\'ın denetlemesi için dokunun.';

  @override
  String get blockUnknown => 'Bilinmeyen/gizli numaraları engelle';

  @override
  String get blockUnknownSubtitle => 'Numarasını gizleyen arayanlar';

  @override
  String get blockNonContacts =>
      'Kişilerde olmayan numaralardan gelen aramaları engelle';

  @override
  String get blockNonContactsSubtitle => 'Yalnızca kişileriniz sizi arayabilir';

  @override
  String get blockedNumbers => 'Engellenen numaralar';

  @override
  String get blockedCalls => 'Engellenen aramalar';

  @override
  String get addCall => 'Arama ekle';

  @override
  String get note => 'Not';

  @override
  String get editNote => 'Notu düzenle';

  @override
  String get videoCall => 'Görüntülü arama (Meet)';

  @override
  String get switchToVideoCall => 'Görüntülü aramaya geç';

  @override
  String get carrierVideo => 'Operatör görüntülü araması';

  @override
  String get cameraNeeded => 'Görüntülü arama için kameraya izin ver';

  @override
  String get answerAsVoice => 'Sesli arama olarak cevapla';

  @override
  String get videoRequest => 'Görüntülü aramaya geçilsin mi?';

  @override
  String get accept => 'Kabul et';

  @override
  String get switchToVoice => 'Sesli aramaya geç';

  @override
  String get cameraOff => 'Kamerayı kapat';

  @override
  String get cameraOn => 'Kamerayı aç';

  @override
  String get flipCamera => 'Kamerayı çevir';

  @override
  String get incomingVideo => 'Görüntülü arama';

  @override
  String get incomingVideoCall => 'Gelen görüntülü arama';

  @override
  String get videoUnavailable => 'Görüntülü arama kullanılamıyor';

  @override
  String get networkUnreachable => 'Ağa ulaşılamadı';

  @override
  String get networkBusy => 'Ağ meşgul';

  @override
  String get noService => 'Servis yok';

  @override
  String get voiceCall => 'Sesli arama';

  @override
  String get mute => 'Sessiz';

  @override
  String get hold => 'Beklet';

  @override
  String get resume => 'Devam';

  @override
  String get headset => 'Kulaklık';

  @override
  String get speaker => 'Hoparlör';

  @override
  String get audioPhone => 'Telefon';

  @override
  String get wiredHeadset => 'Kablolu kulaklık';

  @override
  String get endCall => 'Aramayı bitir';

  @override
  String get end => 'Bitir';

  @override
  String get dialPad => 'Tuş takımı';

  @override
  String get callNote => 'Arama notu';

  @override
  String get callNoteHint => 'Bu aramadan hatırlamak istediğiniz bir şey yazın';

  @override
  String get conferenceCall => 'Konferans araması';

  @override
  String get unknown => 'Bilinmiyor';

  @override
  String get lineBusy => 'Hat meşgul';

  @override
  String get callDeclined => 'Arama reddedildi';

  @override
  String get callCancelled => 'Arama iptal edildi';

  @override
  String get callFailed => 'Arama başarısız';

  @override
  String get callEnded => 'Arama sona erdi';

  @override
  String get connected => 'Bağlandı';

  @override
  String get calling => 'Aranıyor';

  @override
  String get onHold => 'Beklemede';

  @override
  String get phoneCall => 'Telefon araması';

  @override
  String get hdCall => 'HD arama';

  @override
  String switchToOnHold(String name) {
    return '$name kişisine geç, beklemede';
  }

  @override
  String get switchCall => 'Geç';

  @override
  String get declineWithSms => 'SMS ile yanıtla';

  @override
  String get answer => 'Yanıtla';

  @override
  String get decline => 'Reddet';

  @override
  String get answerVerb => 'yanıtlamak';

  @override
  String get declineVerb => 'reddetmek';

  @override
  String swipeUpDownHint(String up, String down) {
    return '$up için yukarı, $down için aşağı kaydırın';
  }

  @override
  String swipeUpHint(String action) {
    return '$action için yukarı kaydırın';
  }

  @override
  String get effectsFull => 'Tüm efektler';

  @override
  String get effectsReduced => 'Azaltılmış efektler';

  @override
  String get effectsOff => 'Efektler kapalı';

  @override
  String get off => 'Kapalı';

  @override
  String get always => 'Her zaman';

  @override
  String get onlyWithHeadphones => 'Yalnızca kulaklıkla';

  @override
  String get incomingCallReminders => 'Gelen aramalar';

  @override
  String get incomingFootnote =>
      'Yalnızca cihazınızın kilidi açıkken gelen aramalar için geçerlidir.';

  @override
  String get banner => 'Afiş';

  @override
  String get fullScreen => 'Tam ekran';

  @override
  String get announceCalls => 'Gelen aramaları sesli bildir';

  @override
  String get announceCallsSubtitle => 'Çalarken arayanın adını söyler';

  @override
  String get flashOnCall => 'Flaş bildirimi';

  @override
  String get flashOnCallSubtitle => 'Arama çalarken kamera flaşı yanıp söner';

  @override
  String get systemFlash => 'Telefonunuzun kendi flaş bildirimi var';

  @override
  String get systemFlashSubtitle =>
      'Birini kapatın, yoksa ikisi de yanıp söner. Ayarlar\'da Bildirimler veya Erişilebilirlik altında bulabilirsiniz';

  @override
  String get swipeUpToAnswer => 'Yanıtlamak için yukarı kaydırın';

  @override
  String get swipeDownToAnswer => 'Yanıtlamak için aşağı kaydırın';

  @override
  String get answerButtons => 'Arama ekranı';

  @override
  String get twoButtons => '2 düğme';

  @override
  String get oneButton => '1 düğme';

  @override
  String get answerCall => 'Aramayı yanıtla';

  @override
  String get callScreenEffects => 'Arama ekranı efektleri';

  @override
  String get callScreenEffectsSubtitle => 'Arama ekranında cam ve parlaklık';

  @override
  String get callScreenAnimations => 'Arama ekranı animasyonları';

  @override
  String get callScreenAnimationsSubtitle =>
      'Arama ekranı açılırken, yanıtlanırken ve değişirken hareket';

  @override
  String get hideContactNumbers => 'Kişilerin numaralarını gizle';

  @override
  String get hideContactNumbersSubtitle =>
      'Arama ekranında ve Aramalar\'da kayıtlı kişilerin yalnızca adını göster';

  @override
  String get callerPhoto => 'Arayanın fotoğrafı';

  @override
  String get callerPhotoSubtitle =>
      'Kişinin fotoğrafının arama ekranındaki yeri';

  @override
  String get callerPhotoSide => 'Adın yanında';

  @override
  String get callerPhotoStacked => 'Adın üstünde';

  @override
  String secondsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saniye',
      one: '1 saniye',
    );
    return '$_temp0';
  }

  @override
  String get answerEndCalls => 'Aramaları yanıtlama ve bitirme';

  @override
  String get vibrateAnswerEnd => 'Aramalar yanıtlanınca/bitince titret';

  @override
  String get autoAnswer =>
      'Harici ses cihazı bağlıyken aramaları otomatik yanıtla';

  @override
  String get autoAnswerSubtitle => 'Bluetooth ve kablolu kulaklıklar dahil';

  @override
  String get autoAnswerDelay => 'Otomatik yanıt gecikmesi';

  @override
  String get replyWithSms => 'SMS ile yanıtla';

  @override
  String get speakerDefault => 'Aramalar varsayılan olarak hoparlörde';

  @override
  String get speakerDefaultSubtitle =>
      'Harici cihazlar bağlıyken geçerli olmaz.';

  @override
  String get quickDeclineMessage => 'Hızlı ret mesajı';

  @override
  String get quickDeclineMessages => 'Hızlı ret mesajları';

  @override
  String get quickDeclineHint =>
      'Bir aramayı mesajla reddettiğinizde gönderilir';

  @override
  String get addMessage => 'Mesaj ekle';

  @override
  String get settingNotAvailable => 'Bu telefonda o ayar yok';

  @override
  String get notDefaultApp => 'Varsayılan telefon uygulamanız değil';

  @override
  String get notDefaultAppSubtitle =>
      'Gelen aramalar başka bir uygulamayı kullanıyor';

  @override
  String get notificationsOff => 'Bildirimler kapalı';

  @override
  String get notificationsOffSubtitle =>
      'Gelen veya cevapsız aramaları görmezsiniz';

  @override
  String get fullScreenOff => 'Tam ekran aramalar kapalı';

  @override
  String get fullScreenOffSubtitle =>
      'Gelen aramalar yalnızca bildirim olarak görünür';

  @override
  String get blockingPausedShort =>
      'Aramalarınızı başka bir uygulama denetliyor';

  @override
  String get bluetoothNamesHidden => 'Bluetooth adları gizli';

  @override
  String get bluetoothNamesHiddenSubtitle =>
      'Aramalar saatinizi kulaklığınızdan ayıramaz';

  @override
  String get fix => 'Düzelt';

  @override
  String get callSettings => 'Arama ayarları';

  @override
  String get needsAttention => 'Dikkat gerekiyor';

  @override
  String get callerIdentification => 'Arayan kimliği';

  @override
  String get callerIdSpamApp => 'Arayan kimliği ve spam uygulaması';

  @override
  String get carrierSettings => 'Operatör ayarları';

  @override
  String get softwareUpdate => 'Yazılım güncellemesi';

  @override
  String get supportOneDialer => 'One Dialer\'ı destekle';

  @override
  String get supportIntro =>
      'One Dialer ücretsizdir; reklam ve takip içermez ve böyle kalacak. İşine yarıyorsa ve gelişmesine yardım etmek istersen tek seferlik bahşiş bırakabilirsin. Bahşişler hiçbir özelliğin kilidini açmaz.';

  @override
  String get leaveATip => 'Bahşiş bırak';

  @override
  String get tipSmall => 'Küçük bahşiş';

  @override
  String get tipMedium => 'Orta bahşiş';

  @override
  String get tipLarge => 'Büyük bahşiş';

  @override
  String get tipsLoading => 'Yükleniyor…';

  @override
  String get tipsUnavailable =>
      'Bahşişler şu anda kullanılamıyor. Bahşiş için Google Play gerekir.';

  @override
  String get tipThanks => 'One Dialer\'ı desteklediğin için teşekkürler!';

  @override
  String get tipPending =>
      'Bahşişin beklemede. Ödeme onaylanınca tamamlanacak.';

  @override
  String get tipFailed => 'Bahşiş gerçekleşmedi. Senden ücret alınmadı.';

  @override
  String get helpFeedback => 'Yardım ve geri bildirim';

  @override
  String get privacyPolicy => 'Gizlilik politikası';

  @override
  String get aboutOneDialer => 'One Dialer hakkında';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get openDetails => 'Ayrıntıları aç';

  @override
  String get writeInKeypad => 'Tuş takımına yaz';

  @override
  String get tapRecentCall => 'Son aramaya dokunma';

  @override
  String get chooseSimForCalls => 'Hangi SIM ile aranacak';

  @override
  String get appearance => 'Görünüm';

  @override
  String get reduceVisualEffects => 'Görsel efektleri azalt';

  @override
  String get displaySize => 'Ekran boyutu';

  @override
  String get displaySizeSmall => 'Küçük';

  @override
  String get displaySizeDefault => 'Varsayılan';

  @override
  String get displaySizeLarge => 'Büyük';

  @override
  String get displaySizeLarger => 'Daha büyük';

  @override
  String get displaySizeApp => 'Uygulama';

  @override
  String get displaySizeNavBar => 'Gezinme çubuğu';

  @override
  String get reduceVisualEffectsSubtitle =>
      'Daha az bulanıklık, yavaş telefonlarda daha akıcı çalışır';

  @override
  String get callScreenEdgeGlow => 'Arama ekranı kenar ışıltısı';

  @override
  String get darkModeEdgeGlow => 'Işıltı gücü';

  @override
  String get edgeGlowClassic => 'Klasik';

  @override
  String get edgeGlowSoft => 'Yumuşak';

  @override
  String get edgeGlowBold => 'Güçlü';

  @override
  String get glassStyle => 'Cam stili';

  @override
  String get navBarFrosted => 'Kenar ışıltısı';

  @override
  String get navBarLiquid => 'Sıvı cam';

  @override
  String get navBarGlass => 'Cam efekti';

  @override
  String get navGlassPremium => 'Tam kırılma';

  @override
  String get navGlassStandard => 'Hafif';

  @override
  String get navGlassAuto => 'Otomatik';

  @override
  String get glassSettings => 'Cam ve bulanıklık';

  @override
  String get splashIcon => 'Açılış ekranında uygulama simgesi';

  @override
  String get splashIconSubtitle =>
      'Ana ekranınız farklı bir simge kullanıyorsa boş açılış ekranı için kapatın';

  @override
  String get liquidGlassOn => 'Sıvı cam kullanan yerler';

  @override
  String get liquidScopeAll => 'Her yer';

  @override
  String get liquidScopeControls => 'Gezinme çubuğu ve düğmeler';

  @override
  String get liquidScopeNavbar => 'Yalnızca gezinme çubuğu';

  @override
  String get glassExperimentalNote =>
      'Sıvı cam deneyseldir ve en ağır stildir: zaten zorlayıcı olan Kenar ışıltısından da fazla grafik gücü gerektirir. Kaydırma takılıyorsa Yalnızca gezinme çubuğu\'nu veya Cam efekti › Otomatik\'i deneyin ya da Kenar ışıltısı\'na dönün. Yavaş telefonlarda en akıcısı Ekran ve efektler › Görsel efektleri azalt\'tır.';

  @override
  String get callsFromOtherApps => 'Diğer uygulamalardan aramalar';

  @override
  String get callsFromOtherAppsSubtitle =>
      'WhatsApp ve diğer uygulamaların aramalarını Son aramalar\'da göster';

  @override
  String get manageContactsSubtitle =>
      'Görünüm, kayıt yeri, içe ve dışa aktarma, SIM, yinelenenler';

  @override
  String get googleContactsSync => 'Google Kişiler senkronizasyonu';

  @override
  String get googleContactsSyncSubtitle =>
      'Hangi hesapların senkronize edildiği ve telefon kişilerinin yedeği';

  @override
  String get defaultApps => 'Varsayılan uygulamalar';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get setupTitle => 'One Dialer\'ı varsayılan telefon uygulamanız yapın';

  @override
  String get setupBody =>
      'Arama yapmak ve yanıtlamak, arama geçmişinizi ve kişilerinizi göstermek ve numaraları engellemek için gereklidir.';

  @override
  String get settingUp => 'Ayarlanıyor…';

  @override
  String get setupDisclosure =>
      'One Dialer; SIM\'lerinizde arama yapmak ve aramaları yönetmek için Telefon\'u, Son aramalar ve cevapsız aramalar için Arama kayıtları\'nı, adlar, fotoğraflar ve arama için Kişiler\'i, gelen, devam eden ve cevapsız aramalar için Bildirimler\'i kullanır. Aramalarınız, arama geçmişiniz ve kişileriniz telefonunuzdan asla çıkmaz. Kilitlenme raporları (kişisel veri içermez) hataları düzeltmeye yardımcı olur.';

  @override
  String get installedDirectly => 'Doğrudan yüklendi';

  @override
  String get anotherAppStore => 'Başka bir uygulama mağazası';

  @override
  String aboutApp(String app) {
    return '$app hakkında';
  }

  @override
  String get updateAvailable => 'Güncelleme var';

  @override
  String get versionUpToDate => 'Sürüm güncel';

  @override
  String get checkForUpdates => 'Güncellemeleri denetle';

  @override
  String get checking => 'Denetleniyor…';

  @override
  String get version => 'Sürüm';

  @override
  String get build => 'Derleme';

  @override
  String get installedFrom => 'Yükleme kaynağı';

  @override
  String get device => 'Cihaz';

  @override
  String get androidVersion => 'Android sürümü';

  @override
  String get openSourceLicences => 'Açık kaynak lisansları';

  @override
  String get copyrightNotice =>
      'Copyright (C) 2026 Syed Arham Raza\nGNU General Public License v3.0 kapsamında özgür yazılım, hiçbir garanti olmaksızın';

  @override
  String get changelog => 'Değişiklik günlüğü';

  @override
  String installedOn(String date) {
    return 'Yüklenme: $date';
  }

  @override
  String get earlierVersions => 'Önceki sürümler';

  @override
  String get aboutThisUpdate => 'Bu güncelleme hakkında';

  @override
  String get reportLag => 'Takılmayı bildir';

  @override
  String get reportLagMessage =>
      'Yavaşlamaları bulmaya yardımcı olmak için son performans ölçümlerini, ekran ve işlem adlarını ve cihaz bilgilerini gönderir. Telefon numaraları, kişiler ve mesajlar dahil değildir.';

  @override
  String get sendReport => 'Rapor gönder';

  @override
  String get reportUnavailable =>
      'Raporlama kullanılamıyor veya az önce istendi. Bir dakika sonra tekrar deneyin.';

  @override
  String get reportQueued => 'Rapor sırada';

  @override
  String reportQueuedMessage(String id) {
    return 'Raporunuz kaydedildi, raporlama kullanılabilir olunca yüklenecek. Bu kimliği geri bildiriminizle paylaşın:\\n\\n$id';
  }

  @override
  String get copy => 'Kopyala';

  @override
  String get paste => 'Yapıştır';

  @override
  String get copyId => 'Kimliği kopyala';

  @override
  String get reportIdCopied => 'Rapor kimliği kopyalandı';

  @override
  String get editSpeedDial => 'Hızlı aramayı düzenle';

  @override
  String get clearNumber => 'Numarayı temizle';

  @override
  String get changeNumber => 'Numarayı değiştir';

  @override
  String get numberCopied => 'Numara kopyalandı';

  @override
  String get noEmailApp => 'E-posta uygulaması bulunamadı';

  @override
  String get noBrowser => 'Tarayıcı bulunamadı';

  @override
  String get sendFeedback => 'Geri bildirim gönder';

  @override
  String get feedbackTypeTitle => 'Konu nedir?';

  @override
  String get feedbackBug => 'Sorun bildir';

  @override
  String get feedbackIdea => 'Fikir öner';

  @override
  String get feedbackQuestion => 'Soru sor';

  @override
  String get developer => 'Geliştirici';

  @override
  String get downloadStopped =>
      'İndirme durdu. Bağlandığınızda tekrar deneyin.';

  @override
  String get couldNotInstallUpdate => 'Güncelleme yüklenemedi. Tekrar deneyin.';

  @override
  String get updateCancelled =>
      'Güncelleme iptal edildi. İstediğiniz zaman buradan indirebilirsiniz.';

  @override
  String get noInternet => 'İnternet bağlantısı yok. Bağlanıp tekrar deneyin.';

  @override
  String get couldNotDownloadUpdate =>
      'Güncelleme indirilemedi. Tekrar deneyin.';

  @override
  String get softwareInformation => 'Yazılım bilgileri';

  @override
  String get autoDownload => 'Otomatik indirme';

  @override
  String get downloadAndInstall => 'İndir ve yükle';

  @override
  String get installAndRestart => 'Yükle ve yeniden başlat';

  @override
  String get tryAgain => 'Tekrar dene';

  @override
  String get downloading => 'İndiriliyor…';

  @override
  String get noNetwork => 'Ağ bağlantısı yok';

  @override
  String get notFromPlay =>
      'Güncellemeler Google Play\'den gelir. Bu kopya Play\'den yüklenmedi.';

  @override
  String get notFromPlayTitle => 'Google Play\'den değil';

  @override
  String get notFromPlayWarning =>
      'Bu kopya Google Play\'den yüklenmediği için güncelleme almaz ve değiştirilmiş olabilir. Kullanmaya devam edebilir veya resmi sürümü betadan alabilirsiniz.';

  @override
  String get keepUsing => 'Devam et';

  @override
  String get getOfficialVersion => 'Resmi sürümü al';

  @override
  String get couldNotReachPlay => 'Google Play\'e ulaşılamadı';

  @override
  String get softwareVersion => 'Yazılım sürümü';

  @override
  String get closedBeta => 'Kapalı beta';

  @override
  String get newVersionAvailable => 'Yeni bir sürüm var';

  @override
  String get autoDownloadExplainer =>
      'One Dialer\'ın açılırken Google Play\'de güncelleme araması. Güncellemeler yalnızca İndir ve yükle\'ye dokunduğunuzda yüklenir.';

  @override
  String get autoUpdateNeverSubtitle =>
      'Yalnızca Güncellemeleri denetle\'ye dokunduğunuzda';

  @override
  String get autoUpdateAlwaysSubtitle => 'Denetleme çok az veri kullanır';

  @override
  String get autoUpdateNever => 'Asla';

  @override
  String get autoUpdateWifiOnly => 'Yalnızca Wi-Fi ile';

  @override
  String get autoUpdateAlways => 'Wi-Fi veya mobil veriyle';

  @override
  String get displayAndEffects => 'Ekran ve efektler';

  @override
  String get keypadAndRecents => 'Tuş takımı ve son aramalar';

  @override
  String get logIncoming => 'Gelen';

  @override
  String get logOutgoing => 'Giden';

  @override
  String get logMissed => 'Cevapsız';

  @override
  String get logRejected => 'Reddedildi';

  @override
  String get logBlocked => 'Engellendi';

  @override
  String logRangFor(String type, String duration) {
    return '$type (Çalma süresi: $duration)';
  }

  @override
  String get record => 'Kaydet';

  @override
  String get stopRecording => 'Kaydı durdur';

  @override
  String get recordSetUpFirst => 'Kaydet (Ayarlar\'da kurun)';

  @override
  String get recordingNow => 'Kaydediliyor';

  @override
  String get callRecording => 'Arama kaydı';

  @override
  String get recorderApp => 'One Recorder';

  @override
  String get recorderBothSides => 'Aramalarınızın iki tarafını da kaydeder';

  @override
  String get recorderNeedsSetup => 'İki tarafı One Recorder\'da kurun';

  @override
  String get recorderHelperStopped =>
      'İki taraf duraklatıldı: One Recorder\'da hizmeti başlatın';

  @override
  String get recorderUntrusted =>
      'Kaydedici yalnızca Google Play\'deki One Dialer ile çalışır. Play\'den yükleyin veya iki uygulamayı da güncelleyin.';

  @override
  String get recordingConsentTitle => 'Kaydetmeden önce';

  @override
  String get recordingConsentBody =>
      'Kayıt yasaları ülkeye göre değişir ve bazıları görüşmedeki herkesin onayını gerektirir. Karşı tarafı bilgilendirmek ve onayını almak sizin sorumluluğunuzdadır. Kayıtlar bu telefonda kalır ve asla yüklenmez.';

  @override
  String get recordingConsentAccept => 'Anladım';

  @override
  String get recordings => 'Kayıtlar';

  @override
  String get noRecordings => 'Henüz kayıt yok';

  @override
  String get noRecordingsSubtitle =>
      'Arama sırasında arama ekranında ⋮ › Kaydet\'e dokunun';

  @override
  String get deleteAllRecordings => 'Tüm kayıtları sil';

  @override
  String get deleteAllRecordingsTitle => 'Tüm kayıtlar silinsin mi?';

  @override
  String get deleteAllRecordingsMessage => 'Geri getirilemezler.';

  @override
  String get recordingNotSetUp => 'Aramalar kaydedilmiyor';

  @override
  String get recordingNotSetUpSubtitle =>
      'Otomatik kayıt açık ama One Recorder kurulmadı';

  @override
  String get rename => 'Yeniden adlandır';

  @override
  String get star => 'Yıldızla';

  @override
  String get unstar => 'Yıldızı kaldır';

  @override
  String get filterStarred => 'Yıldızlı';

  @override
  String get filterUnknown => 'Bilinmeyen';

  @override
  String get saveToPhone => 'Telefona kaydet';

  @override
  String get searchRecordings => 'Kayıtlarda ara';

  @override
  String get renameRecording => 'Kaydı yeniden adlandır';

  @override
  String recordingsSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kayıt Recordings/One Dialer klasörüne kaydedildi',
      one: 'Recordings/One Dialer klasörüne kaydedildi',
    );
    return '$_temp0';
  }

  @override
  String get recordingSaveFailed => 'Telefona kaydedilemedi';

  @override
  String deleteRecordings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kayıt silinsin mi?',
      one: 'Bu kayıt silinsin mi?',
    );
    return '$_temp0';
  }

  @override
  String get noMatchingRecordings => 'Eşleşen kayıt yok';

  @override
  String get addContact => 'Kişi ekle';

  @override
  String get autoRecord => 'Otomatik kayıt';

  @override
  String get autoRecordOff => 'Kapalı';

  @override
  String get autoRecordAll => 'Tüm aramalar';

  @override
  String get autoRecordUnknown => 'Bilinmeyen numaralar';

  @override
  String get autoRecordContacts => 'Seçili kişiler';

  @override
  String get recordTheseContacts => 'Kaydedilecek kişiler';

  @override
  String get neverRecord => 'Asla kaydetme';

  @override
  String get neverRecordSubtitle =>
      'Otomatik kaydın her zaman atladığı kişiler';

  @override
  String get storage => 'Depolama';

  @override
  String get storageUsed => 'Kullanılan alan';

  @override
  String get autoDelete => 'Otomatik silme';

  @override
  String get autoDeleteSubtitle => 'Yıldızlı kayıtlar her zaman saklanır';

  @override
  String get autoDeleteNever => 'Asla';

  @override
  String autoDeleteDays(int days) {
    return '$days gün sonra';
  }

  @override
  String get imeiTitle => 'IMEI';

  @override
  String get imeiUnavailable =>
      'Android, uygulamaların IMEI\'yi göstermesine izin vermez. Telefonunuzun ayarlarında Telefon hakkında altında bulabilirsiniz.';

  @override
  String get aboutPhone => 'Telefon hakkında';

  @override
  String get glassStyleSubtitle =>
      'Sıvı cam arkasındakini büker ama daha fazla güç kullanır';

  @override
  String get darkModeEdgeGlowSubtitle =>
      'Koyu modda cam kenarlarının ne kadar parladığı';

  @override
  String get liquidGlassOnSubtitle =>
      'Uygulamanın hangi bölümlerinin sıvı cam kullandığı';

  @override
  String get navBarGlassSubtitle =>
      'Tam kırılma en iyi görünür; Hafif, yavaş telefonlarda daha akıcıdır';

  @override
  String get tapRecentCallSubtitle =>
      'Aramalar\'da bir aramaya dokununca ne olacağı';

  @override
  String get callScreenEdgeGlowSubtitle =>
      'Arama düğmelerinin cam kenarlarının ne kadar parladığı';

  @override
  String get answerButtonsSubtitle =>
      'Yanıtlama şekli, efektler, arayanın fotoğrafı ve arka plan';

  @override
  String get incomingCallsSubtitle =>
      'Çalma stili, arayanı bildir, flaş, Live Update';

  @override
  String get answerEndCallsSubtitle =>
      'Otomatik yanıt, SMS ile yanıt, hoparlör';

  @override
  String get sectionCalls => 'Aramalar';

  @override
  String get sectionMakingCalls => 'Arama yapma';

  @override
  String get sectionBlocking => 'Engelleme ve arayan kimliği';

  @override
  String get sectionDisplay => 'Görünüm';

  @override
  String get sectionSystem => 'Kişiler ve sistem';

  @override
  String get searchSettings => 'Ayarlarda ara';

  @override
  String get carrierSettingsSubtitle =>
      'Arama yönlendirme, arama bekletme ve arayan kimliği';

  @override
  String get callBackground => 'Arama arka planı';

  @override
  String get callBackgroundAllSubtitle =>
      'Kendi arka planı olan kişiler dışında tüm aramalar için';

  @override
  String get callBackgroundDefault => 'Varsayılan';

  @override
  String get callBackgroundColour => 'Renk';

  @override
  String get callBackgroundPhoto => 'Fotoğraf';

  @override
  String get callBackgroundAurora => 'Aurora';

  @override
  String get callBackgroundAuto => 'Otomatik';

  @override
  String get callBackgroundAutoNote =>
      'Otomatik: her arayan, kişi fotoğrafından veya adından kendi renklerini alır.';

  @override
  String get callBackgroundColourNote => 'Tüm aramalar bu rengi kullanır.';

  @override
  String get callBackgroundChangePhoto => 'Fotoğrafı değiştir';

  @override
  String get callBackgroundPhotoBackupNote =>
      'Fotoğraflar yalnızca bu telefona kaydedilir. One Dialer\'ı yeniden yükledikten sonra veya yeni bir telefonda saklamak için';

  @override
  String get callBackgroundPhotoBackupLink => 'ayarlarınızı yedekleyin';

  @override
  String get callBackgroundSoft => 'Bulanıklaştır ve karart';

  @override
  String get callBackgroundSoftSubtitle =>
      'Aramanın arkasındaki fotoğrafı yumuşatır';

  @override
  String get callBackgroundContactPhoto => 'Kişinin fotoğrafı';

  @override
  String get callBackgroundContactPhotoSubtitle =>
      'Android kişi fotoğraflarını küçük tutar; daha net görüntü için bir fotoğraf seçin';

  @override
  String get callBackgroundSameAsAll => 'Tüm aramalarla aynı';

  @override
  String get callBackgroundAllNote =>
      'Kişi sayfasında kendi arka planı ayarlanmış bir kişi onun yerine kendi arka planını kullanır.';

  @override
  String get callBackgroundContactNote =>
      'Bu kişi için tüm aramaların arka planı yerine kullanılır.';

  @override
  String get backUpRestore => 'Yedekle ve geri yükle';

  @override
  String get backUpRestoreSubtitle =>
      'Ayarlar, arama notları ve arama arka planları, bu telefonda tek dosyada';

  @override
  String get backUpNow => 'Şimdi yedekle';

  @override
  String lastBackup(String time) {
    return 'Son yedek: $time';
  }

  @override
  String get backupNever => 'Henüz yedeklenmedi';

  @override
  String get restoreBackup => 'Geri yükle';

  @override
  String get restoreBackupSubtitle =>
      'Bir yedek dosyası seçin; dosyalar uygulaması Belgeler\'de açılır';

  @override
  String get autoBackup => 'Otomatik yedekleme';

  @override
  String get backupFrequency => 'Sıklık';

  @override
  String get backupEveryDay => 'Her gün';

  @override
  String get backupEvery3Days => '3 günde bir';

  @override
  String get backupEveryWeek => 'Her hafta';

  @override
  String get backupEveryMonth => 'Her ay';

  @override
  String get backupLocation => 'Konum';

  @override
  String get backupLocationNone => 'Bir klasör seçin; Belgeler iyi bir yer';

  @override
  String get backupFailed =>
      'Son yedekleme başarısız oldu. Klasörü yeniden seçmek için Konum\'a dokunun.';

  @override
  String get backupFootnote =>
      'Bir yedek; ayarlarınızı, hızlı aramayı, arama notlarını ve fotoğraflarıyla arama arka planlarını içerir. Her yedeklemede değiştirilen tek bir dosyadır, bu yüzden depolama alanınızı asla doldurmaz. Otomatik yedekleme, One Dialer\'ı açtığınızda veya bir arama bittiğinde çalışır.';

  @override
  String get backedUp => 'Yedeklendi';

  @override
  String get couldNotBackUp => 'O klasöre yedeklenemedi';

  @override
  String get importSettingsTitle => 'Ayarlarınız değiştirilsin mi?';

  @override
  String get importSettingsMessage =>
      'Ayarlarınız, hızlı arama, arama notları ve arama arka planları dosyadakilerle değiştirilir. Ardından One Dialer yeniden başlar.';

  @override
  String get importSettingsInCall => 'Arama sırasında ayarlar içe aktarılamaz';

  @override
  String get notASettingsFile => 'Bu bir One Dialer ayar dosyası değil';

  @override
  String endHeldCall(String name) {
    return 'Aramayı bitir: $name';
  }

  @override
  String get fullScreenAsk =>
      'Gelen aramalar yalnızca bildirim panelinde görünüyor. Sonraki sayfada One Dialer için tam ekran bildirimleri açın. Zaten açık görünüyorsa kapatıp yeniden açın.';

  @override
  String get notNow => 'Şimdi değil';

  @override
  String get vipCalls => 'VIP aramaları';

  @override
  String get vipCallsSubtitle => 'Sessiz veya Titreşim\'de bile çalar';

  @override
  String get vipRing => 'VIP\'ler için Sessiz\'de çal';

  @override
  String get vipRingSubtitle =>
      'VIP\'lerinizden gelen aramalar telefon Sessiz veya Titreşim\'deyken bile çalar, ardından eski haline döner';

  @override
  String get vipFavourites => 'Favorileri dahil et';

  @override
  String get vipFavouritesSubtitle => 'Yıldızlı kişileriniz VIP sayılır';

  @override
  String get vipContacts => 'VIP kişiler';

  @override
  String get vipNeedsAccess => 'VIP aramaları Sessiz\'de çalamıyor';

  @override
  String get vipNeedsAccessSubtitle =>
      'Arama denetimine ve Rahatsız Etmeyin erişimine izin verin';

  @override
  String get vipDndHint =>
      'Rahatsız Etmeyin açıkken kimin çalacağına Android karar verir: Rahatsız Etmeyin ayarlarında yıldızlı kişilere izin verin.';

  @override
  String get rowCallButton => 'Satırlarda arama düğmesi';

  @override
  String get rowCallButtonSubtitle =>
      'Aramalar\'daki her satırda bir arama düğmesi';

  @override
  String get swipeToCall => 'Aramak veya mesaj için kaydır';

  @override
  String get swipeToCallSubtitle =>
      'Aramak için satırı sağa, mesaj için sola kaydırın';

  @override
  String get clearDefault => 'Varsayılanı temizle';

  @override
  String get swipeStyle => 'Kaydırma stili';

  @override
  String get swipeStylePill => 'Cam düğme';

  @override
  String get swipeStyleFlat => 'Düz';

  @override
  String get quickCalling => 'Hızlı arama yapma';

  @override
  String get quickCallingSubtitle =>
      'Satırlarda dokunma, arama düğmesi ve kaydırma';

  @override
  String get useRecentSim => 'Son kullanılan SIM';

  @override
  String get simSameAsPhone => 'Telefonla aynı';

  @override
  String alwaysSim(Object sim) {
    return 'Her zaman $sim';
  }

  @override
  String get keypadSimButtons => 'İki Ara düğmesi';

  @override
  String get keypadSimButtonsSubtitle =>
      'Tek bir Ara düğmesi yerine her SIM için bir tane';

  @override
  String get keypadSimButtonsOneSim => 'Yalnızca iki SIM\'li telefonlarda';

  @override
  String get keypadSettings => 'Tuş takımı';

  @override
  String get keypadSettingsSubtitle => 'İki Ara düğmesi, hızlı arama';

  @override
  String get phoneDefaultSim => 'Telefonun varsayılan SIM\'i';

  @override
  String get simRulesHint =>
      'Kişinin sayfasında ayarlanan kendi SIM\'i her zaman önce gelir.';

  @override
  String get callButtonStyle => 'Ara düğmesi stili';

  @override
  String get callButtonTint => 'Hafif renk';

  @override
  String get callButtonGlyph => 'Yalnızca simge';

  @override
  String get callButtonLit => 'Yeşil daire';

  @override
  String get callsAndContactsRows => 'Aramalar ve Kişiler\'deki satırlar';

  @override
  String get callsRows => 'Aramalar\'daki satırlar';

  @override
  String get tapAlreadyCalls => 'Aramaya dokunmak zaten arar';

  @override
  String get simCards => 'SIM kartlar';

  @override
  String get groupByContact => 'Kişiye göre grupla';

  @override
  String get dontGroupByContact => 'Kişiye göre gruplama';

  @override
  String get keypadAndContacts => 'Tuş takımı ve kişiler';

  @override
  String get swipeToCallSim => 'Aramak için kaydır';

  @override
  String get sameAsKeypad => 'Tuş takımıyla aynı';

  @override
  String get tapSimUnused =>
      'Yalnızca Hızlı arama yapma\'da Son aramaya dokunma Ara olarak ayarlıysa kullanılır';

  @override
  String get swipeSimUnused =>
      'Yalnızca Hızlı arama yapma\'da Aramak için kaydır açıksa kullanılır';

  @override
  String get onboardingSkip => 'Atla';

  @override
  String get onboardingNext => 'İleri';

  @override
  String get onboardingStart => 'Başlayın';

  @override
  String get onboardingLookTitle => 'Size göre ayarlayın';

  @override
  String get onboardingLookBody =>
      'Uygulamanın dilini ve açık mı koyu mu olacağını seçin.';

  @override
  String get onboardingAnswerTitle => 'Aramaları yanıtlama';

  @override
  String get onboardingAnswerBody =>
      'Gelen aramaların nasıl görüneceğini ve nasıl yanıtlayacağınızı seçin.';

  @override
  String get onboardingHealthTitle => 'Aramalara hazır';

  @override
  String get onboardingHealthBody =>
      'Gelen aramalar için Android\'den bunlar gerekiyor. Düzeltmek için birine dokunun.';

  @override
  String get onboardingAllSet => 'Her şey hazır';

  @override
  String get onboardingCallingTitle => 'Arama yapma';

  @override
  String get onboardingCallingBody =>
      'Aramalar için SIM\'i ve bir aramaya dokunmanın ya da kaydırmanın ne yapacağını seçin.';

  @override
  String get mergeDuplicatedNames => 'Yinelenen adları birleştir';

  @override
  String get mergeDuplicatedNumbers => 'Yinelenen numaraları birleştir';

  @override
  String get manuallyMergeDuplicates => 'Yinelenenleri elle birleştir';

  @override
  String get sameNumberContacts => 'Aynı numaraya sahip kişiler';

  @override
  String get sameNameContacts => 'Aynı ada sahip kişiler';

  @override
  String groupCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count grup',
      one: '1 grup',
    );
    return '$_temp0';
  }

  @override
  String get mergeManually => 'Elle birleştir';

  @override
  String get manualMergingDetails => 'Birleştirme ayrıntıları';

  @override
  String get nameRequired => 'Ad (zorunlu)';

  @override
  String get numbersSelectMany => 'Numara (birden fazla seçilebilir)';

  @override
  String mergeDeletesNumbers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'İşaretlenmeyen $count numara kişiden silinecek.',
      one: 'İşaretlenmeyen numara kişiden silinecek.',
    );
    return '$_temp0';
  }

  @override
  String get blockCalls => 'Aramaları engelle';

  @override
  String get blocklist => 'Engellenenler listesi';

  @override
  String get blocklistSubtitle =>
      'Engellenenler listesindeki numaralardan gelen aramalar engellenir.';

  @override
  String get allowlist => 'İzin verilenler listesi';

  @override
  String get allowlistSubtitle =>
      'İzin verilenler listesindeki numaralardan gelen aramalar engellenmez.';

  @override
  String get none => 'Yok';

  @override
  String get noNumbers => 'Numara yok';

  @override
  String get blockByPrefix => 'Ön eke göre engelle';

  @override
  String get numberPrefix => 'Ön ek, ör. 0300';

  @override
  String startsWith(String prefix) {
    return '$prefix ile başlar';
  }

  @override
  String removeFromBlocklist(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count numara engellenenler listesinden kaldırılsın mı?',
      one: '1 numara engellenenler listesinden kaldırılsın mı?',
    );
    return '$_temp0';
  }

  @override
  String removeFromAllowlist(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count numara izin verilenler listesinden kaldırılsın mı?',
      one: '1 numara izin verilenler listesinden kaldırılsın mı?',
    );
    return '$_temp0';
  }

  @override
  String searchContactNumbers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kişi numarasında ara',
      one: '1 kişi numarasında ara',
    );
    return '$_temp0';
  }

  @override
  String get unofficialBuildTitle => 'Resmi olmayan sürüm';

  @override
  String get unofficialBuildCredit =>
      'Syed Arham Raza\'nın One Dialer uygulamasına dayanır, github.com/syedarhamraza/one-dialer';

  @override
  String get unofficialBuildNotice =>
      'Resmi olmayan sürüm. Syed Arham Raza\'nın One Dialer uygulamasına dayanır, github.com/syedarhamraza/one-dialer';

  @override
  String mergeAll(String count) {
    return 'Tümünü birleştir ($count)';
  }

  @override
  String mergeGroupsTitle(String count, String groups) {
    return '$count kişi $groups kişide birleştirilsin mi?';
  }

  @override
  String get mergeGroupsMessage =>
      'Her grup, tüm numaraları ve bilgileriyle tek bir kişi olur.';

  @override
  String get privacySecurity => 'Gizlilik ve güvenlik';

  @override
  String get privacySecuritySubtitle => 'Uygulama kilidi, özel kasa';

  @override
  String get appLock => 'Uygulama kilidi';

  @override
  String get appLockSubtitle =>
      'One Dialer\'ı açmak için parmak izi, yüz veya ekran kilidi iste';

  @override
  String get appLockNeedsScreenLock =>
      'Önce telefon ayarlarından bir ekran kilidi ayarlayın';

  @override
  String get appLockCalls =>
      'Gelen aramalar uygulama kilitliyken de çalar ve yanıtlanabilir.';

  @override
  String get lockAfter => 'Kilitle';

  @override
  String get lockImmediately => 'Hemen';

  @override
  String get lockAfterOneMinute => '1 dakika sonra';

  @override
  String get lockAfterFiveMinutes => '5 dakika sonra';

  @override
  String get appLocked => 'One Dialer kilitli';

  @override
  String get unlock => 'Kilidi aç';

  @override
  String get unlockOneDialer => 'One Dialer\'ın kilidini aç';

  @override
  String get privateVault => 'Özel kasa';

  @override
  String get privateVaultSubtitle =>
      'Yalnızca One Dialer\'ın görebildiği kişiler ve aramalar';

  @override
  String get unlockPrivateVault => 'Özel kasanın kilidini aç';

  @override
  String get moveToVault => 'Özel kasaya taşı';

  @override
  String moveToVaultTitle(String name) {
    return '$name özel kasaya taşınsın mı?';
  }

  @override
  String get moveToVaultMessage =>
      'Kişi ve arama geçmişi telefonun kişilerinden ve arama kaydından çıkar, böylece diğer uygulamalar göremez. Aramaları yine çalar ve adını gösterir.';

  @override
  String get move => 'Taşı';

  @override
  String get movedToVault => 'Özel kasaya taşındı';

  @override
  String get moveOutOfVault => 'Kişilere geri taşı';

  @override
  String get movedOutOfVault => 'Kişilere geri taşındı';

  @override
  String get couldNotOpenVault => 'Özel kasa güncellenemedi';

  @override
  String get deleteFromVaultMessage =>
      'Kişiyi ve aramalarını kasadan kalıcı olarak siler.';

  @override
  String get vaultEmpty =>
      'Henüz özel kişi yok. Bir kişiyi açıp ⋮ › Özel kasaya taşı\'yı seçin.';

  @override
  String get vaultCalls => 'Arama geçmişi';

  @override
  String get vaultImport => 'Kasaya içe aktar';

  @override
  String get vaultExportMessage =>
      'Dışa aktarılan dosya şifreli değildir: dosyaya sahip olan herkes bu kişileri okuyabilir.';

  @override
  String get vaultUninstallNote =>
      'Kasa yalnızca bu telefonda şifreli olarak tutulur ve asla yedeklenmez. One Dialer\'ı kaldırmak veya verilerini silmek kasayı siler; önce dışa aktarın.';

  @override
  String get appLockedHint =>
      'Açmak için parmak izi, yüz veya ekran kilidini kullanın';
}
