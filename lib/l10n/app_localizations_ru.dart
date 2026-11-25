// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get languageName => 'Русский';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get delete => 'Удалить';

  @override
  String get dismiss => 'Закрыть';

  @override
  String get dismissMenu => 'Закрыть меню';

  @override
  String get share => 'Поделиться';

  @override
  String get more => 'Ещё';

  @override
  String get back => 'Назад';

  @override
  String get soon => 'Скоро';

  @override
  String get all => 'Все';

  @override
  String get selectAll => 'Выбрать все';

  @override
  String get deselectAll => 'Снять выбор';

  @override
  String get selectItems => 'Выберите элементы';

  @override
  String get search => 'Поиск';

  @override
  String get searchContacts => 'Поиск контактов';

  @override
  String get clear => 'Очистить';

  @override
  String get clearSearch => 'Очистить поиск';

  @override
  String get searchByVoice => 'Голосовой поиск';

  @override
  String get scrollToTop => 'Наверх';

  @override
  String dateWheelDay(String day) {
    return 'День $day';
  }

  @override
  String dateWheelYear(String year) {
    return 'Год $year';
  }

  @override
  String get navCalls => 'Вызовы';

  @override
  String get navContacts => 'Контакты';

  @override
  String get returnToCall => 'Вернуться к вызову';

  @override
  String get createContact => 'Создать контакт';

  @override
  String get showKeypad => 'Показать клавиатуру';

  @override
  String get settingsLanguageHeader => 'Язык';

  @override
  String get settingsAppLanguage => 'Язык приложения';

  @override
  String get settingsAppLanguageSubtitle => 'Меняет только это приложение';

  @override
  String get settingsLanguageSystem => 'Как в телефоне';

  @override
  String get settingsAndroidLanguage => 'Языковые настройки Android';

  @override
  String get settingsAndroidLanguageSubtitle =>
      'Выберите язык в настройках Android';

  @override
  String get call => 'Вызов';

  @override
  String get message => 'Сообщение';

  @override
  String get add => 'Добавить';

  @override
  String get block => 'Заблокировать';

  @override
  String get unblock => 'Разблокировать';

  @override
  String get settings => 'Настройки';

  @override
  String get notes => 'Заметки';

  @override
  String get moreOptions => 'Другие параметры';

  @override
  String get voicemail => 'Голосовая почта';

  @override
  String get today => 'Сегодня';

  @override
  String get yesterday => 'Вчера';

  @override
  String durationHoursMinutes(String hours, String minutes) {
    return '$hours ч $minutes мин';
  }

  @override
  String durationMinutesSeconds(String minutes, String seconds) {
    return '$minutes мин $seconds с';
  }

  @override
  String durationSeconds(String seconds) {
    return '$seconds с';
  }

  @override
  String get privateNumber => 'Скрытый номер';

  @override
  String appVideo(String app) {
    return 'Видео $app';
  }

  @override
  String videoCallOnApp(String app) {
    return 'Видеовызов в $app';
  }

  @override
  String callOnApp(String app) {
    return 'Вызов в $app';
  }

  @override
  String get callTypeOutgoing => 'Исходящий вызов';

  @override
  String get callTypeMissed => 'Пропущенный вызов';

  @override
  String get callTypeRejected => 'Отклонённый вызов';

  @override
  String get callTypeBlocked => 'Заблокированный вызов';

  @override
  String get callTypeVoicemail => 'Голосовая почта';

  @override
  String get callNotConnected => '(Не соединено)';

  @override
  String get callTypeIncoming => 'Входящий вызов';

  @override
  String get speedDialNoNumber => 'Нет номера быстрого набора';

  @override
  String speedDialAssignPrompt(String digit) {
    return 'Назначить контакт на клавишу $digit?';
  }

  @override
  String get assign => 'Назначить';

  @override
  String get couldNotPlaceCall => 'Не удалось позвонить';

  @override
  String get keypadNumberEmpty => 'Номер, пусто. Удерживайте, чтобы вставить';

  @override
  String keypadNumber(String number) {
    return 'Номер $number';
  }

  @override
  String get keypadZeroHint => '0, удерживайте для плюса';

  @override
  String get keypadVoicemailHint => '1, удерживайте для голосовой почты';

  @override
  String keypadDigitHint(String digit) {
    return '$digit, удерживайте для быстрого набора';
  }

  @override
  String get hideKeypad => 'Скрыть клавиатуру';

  @override
  String callWithSim(String slot, String sim) {
    return 'Вызов с SIM $slot, $sim';
  }

  @override
  String get keypadDeleteHint => 'Удалить, удерживайте, чтобы стереть всё';

  @override
  String get addPause => 'Пауза 2 сек';

  @override
  String get addWait => 'Добавить ожидание';

  @override
  String get sendMessage => 'Отправить сообщение';

  @override
  String get speedDialNumbers => 'Номера быстрого набора';

  @override
  String speedDialKey(String digit) {
    return 'Быстрый набор $digit';
  }

  @override
  String get speedDial => 'Быстрый набор';

  @override
  String get speedDialAssignContacts => 'Назначить контакты';

  @override
  String speedDialRemoved(String name, String digit) {
    return '$name убран с клавиши $digit';
  }

  @override
  String get callLogs => 'Журналы вызовов';

  @override
  String get deleteCallHistory => 'Удалить журнал вызовов';

  @override
  String deleteCallsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Удалить $count вызова?',
      many: 'Удалить $count вызовов?',
      few: 'Удалить $count вызова?',
      one: 'Удалить $count вызов?',
    );
    return '$_temp0';
  }

  @override
  String get deleteCallsMessage =>
      'Выбранные записи журнала будут удалены с этого телефона.';

  @override
  String get couldNotDeleteCalls =>
      'Не удалось удалить журнал вызовов. Повторите попытку.';

  @override
  String get showAllCalls => 'Показать все вызовы';

  @override
  String get showAppCallsOnly => 'Только вызовы из приложений';

  @override
  String get showBlockedCalls => 'Показать заблокированные';

  @override
  String get hideBlockedCalls => 'Скрыть заблокированные';

  @override
  String blockNumberTitle(String number) {
    return 'Заблокировать $number?';
  }

  @override
  String blockNumbersTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Заблокировать $count номера?',
      many: 'Заблокировать $count номеров?',
      few: 'Заблокировать $count номера?',
      one: 'Заблокировать $count номер?',
    );
    return '$_temp0';
  }

  @override
  String get blockNumbersMessage =>
      'Вызовы с заблокированных номеров не будут поступать.';

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Выбрано $count',
      many: 'Выбрано $count',
      few: 'Выбрано $count',
      one: 'Выбран $count',
    );
    return '$_temp0';
  }

  @override
  String get recentsSetDefaultMessage =>
      'Сделайте Dialer приложением для звонков по умолчанию, чтобы видеть последние вызовы';

  @override
  String get setAsDefault => 'По умолчанию';

  @override
  String get recentsNoAppCalls => 'Нет вызовов из приложений';

  @override
  String get recentsNoRecentCalls => 'Нет последних вызовов';

  @override
  String get recentsNoMissedCalls => 'Нет пропущенных вызовов';

  @override
  String get recentsFilterMissed => 'Пропущенные';

  @override
  String get addToContacts => 'Добавить в контакты';

  @override
  String get callDetails => 'Сведения о вызове';

  @override
  String contactLabel(String label) {
    String _temp0 = intl.Intl.selectLogic(label, {
      'mobile': 'Мобильный',
      'home': 'Домашний',
      'work': 'Рабочий',
      'workMobile': 'Рабочий мобильный',
      'main': 'Основной',
      'phone': 'Телефон',
      'faxHome': 'Домашний факс',
      'faxWork': 'Рабочий факс',
      'faxOther': 'Другой факс',
      'pager': 'Пейджер',
      'workPager': 'Рабочий пейджер',
      'school': 'Учёба',
      'car': 'Автомобиль',
      'companyMain': 'Основной в компании',
      'callback': 'Обратный вызов',
      'assistant': 'Ассистент',
      'birthday': 'День рождения',
      'anniversary': 'Годовщина',
      'homepage': 'Домашняя страница',
      'blog': 'Блог',
      'profile': 'Профиль',
      'brother': 'Брат',
      'sister': 'Сестра',
      'child': 'Ребёнок',
      'father': 'Отец',
      'mother': 'Мать',
      'parent': 'Родитель',
      'friend': 'Друг',
      'manager': 'Руководитель',
      'partner': 'Партнёр',
      'relative': 'Родственник',
      'spouse': 'Супруг(а)',
      'domesticPartner': 'Гражданский партнёр',
      'referredBy': 'По рекомендации',
      'other': 'Другое',
    });
    return '$_temp0';
  }

  @override
  String addressLabel(String label) {
    return 'Адрес ($label)';
  }

  @override
  String get accountSamsung => 'Аккаунт Samsung';

  @override
  String get accountSimServiceNumbers => 'Сервисные номера SIM';

  @override
  String get accountSimCard => 'SIM-карта';

  @override
  String get accountThisDevice => 'Это устройство';

  @override
  String contactsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count контакта',
      many: '$count контактов',
      few: '$count контакта',
      one: '$count контакт',
    );
    return '$_temp0';
  }

  @override
  String get justOnce => 'Только сейчас';

  @override
  String get close => 'Закрыть';

  @override
  String get ok => 'ОК';

  @override
  String get edit => 'Изменить';

  @override
  String get video => 'Видео';

  @override
  String get remove => 'Убрать';

  @override
  String get custom => 'Свой вариант';

  @override
  String get allow => 'Разрешить';

  @override
  String get select => 'Выбрать';

  @override
  String get merge => 'Объединить';

  @override
  String get import => 'Импорт';

  @override
  String get qrScanHint =>
      'Отсканируйте камерой телефона, чтобы добавить этот контакт';

  @override
  String deleteContactTitle(String name) {
    return 'Удалить $name?';
  }

  @override
  String get deleteContactMessage =>
      'Контакт будет удалён с этого телефона и из его аккаунтов.';

  @override
  String get shareVcf => 'Файл vCard (VCF)';

  @override
  String get shareText => 'Текст';

  @override
  String get qrCode => 'QR-код';

  @override
  String get blockContact => 'Заблокировать контакт';

  @override
  String get unblockContact => 'Разблокировать контакт';

  @override
  String get askEveryTime => 'Всегда спрашивать';

  @override
  String get contactNotFound => 'Контакт не найден';

  @override
  String get addToFavourites => 'Добавить в избранное';

  @override
  String get removeFromFavourites => 'Убрать из избранного';

  @override
  String get defaultNumber => 'По умолчанию';

  @override
  String get ringtone => 'Мелодия';

  @override
  String get organization => 'Работа';

  @override
  String get website => 'Сайт';

  @override
  String get simForCalls => 'SIM-карта для вызовов';

  @override
  String get storageLocations => 'Места хранения';

  @override
  String get viewAll => 'Показать все';

  @override
  String get selectContact => 'Выберите контакт';

  @override
  String get noMatchingContacts => 'Нет подходящих контактов';

  @override
  String get noCallsWithContact => 'С этим контактом ещё не было вызовов';

  @override
  String get unlink => 'Разъединить';

  @override
  String get unlinkAll => 'Разъединить все';

  @override
  String deleteContactsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Удалить $count контакта?',
      many: 'Удалить $count контактов?',
      few: 'Удалить $count контакта?',
      one: 'Удалить $count контакт?',
    );
    return '$_temp0';
  }

  @override
  String get deleteContactsMessage =>
      'Они будут удалены с этого телефона и из своих аккаунтов.';

  @override
  String get manageContacts => 'Управление контактами';

  @override
  String get contactsAccessMessage =>
      'Разрешите доступ к контактам, чтобы видеть их здесь и показывать имена при вызовах';

  @override
  String get alphabetIndex => 'Алфавитный указатель';

  @override
  String get createNewContact => 'Создать новый контакт';

  @override
  String get updateExistingContact => 'Изменить существующий контакт';

  @override
  String get customLabel => 'Своя метка';

  @override
  String get noContactsToExport => 'Нет контактов для экспорта';

  @override
  String get couldNotOpenFile => 'Не удалось открыть файл';

  @override
  String get noContactsInFile => 'В этом файле нет контактов';

  @override
  String importContactsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Импортировать $count контакта?',
      many: 'Импортировать $count контактов?',
      few: 'Импортировать $count контакта?',
      one: 'Импортировать $count контакт?',
    );
    return '$_temp0';
  }

  @override
  String importContactsMessage(String account) {
    return 'Они будут сохранены в $account.';
  }

  @override
  String contactsImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Импортировано $count контакта',
      many: 'Импортировано $count контактов',
      few: 'Импортировано $count контакта',
      one: 'Импортирован $count контакт',
    );
    return '$_temp0';
  }

  @override
  String get couldNotImportContacts => 'Не удалось импортировать эти контакты';

  @override
  String get display => 'Отображение';

  @override
  String get showContactPhotos => 'Показывать фото профиля контакта';

  @override
  String get onlyContactsWithNumbers => 'Показывать только контакты с номерами';

  @override
  String get contactsToDisplay => 'Показываемые контакты';

  @override
  String get sortBy => 'Сортировка';

  @override
  String get firstName => 'Имя';

  @override
  String get lastName => 'Фамилия';

  @override
  String get nameFormat => 'Формат имени';

  @override
  String get firstNameFirst => 'Сначала имя';

  @override
  String get lastNameFirst => 'Сначала фамилия';

  @override
  String get defaultSaveLocation => 'Сохранять по умолчанию';

  @override
  String get phoneDefault => 'Как в телефоне';

  @override
  String get importContacts => 'Импорт контактов';

  @override
  String get fromVcf => 'Из файла .vcf';

  @override
  String get exportContacts => 'Экспорт контактов';

  @override
  String get asVcf => 'В файл .vcf';

  @override
  String get simContacts => 'Контакты на SIM-карте';

  @override
  String get mergeDuplicates => 'Объединить дубликаты';

  @override
  String get simReadError => 'Не удалось прочитать SIM-карту';

  @override
  String get simReading => 'Чтение SIM-карты…';

  @override
  String get simEmpty => 'На SIM-карте нет контактов';

  @override
  String get allSavedInContacts => 'Все сохранены в контактах';

  @override
  String importToContacts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Импортировать $count в Контакты',
      many: 'Импортировать $count в Контакты',
      few: 'Импортировать $count в Контакты',
      one: 'Импортировать $count в Контакты',
    );
    return '$_temp0';
  }

  @override
  String mergeGroupTitle(String count) {
    return 'Объединить контакты ($count)?';
  }

  @override
  String mergeGroupMessage(String name) {
    return 'Они станут одним контактом $name со всеми номерами и данными.';
  }

  @override
  String contactsMerged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Объединено $count контакта',
      many: 'Объединено $count контактов',
      few: 'Объединено $count контакта',
      one: 'Объединён $count контакт',
    );
    return '$_temp0';
  }

  @override
  String get couldNotMergeContacts => 'Не удалось объединить эти контакты';

  @override
  String get noDuplicateContacts => 'Нет дубликатов';

  @override
  String get recentSearches => 'Недавние запросы';

  @override
  String get clearAll => 'Очистить все';

  @override
  String get noResultsFound => 'Ничего не найдено';

  @override
  String foundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Найдено $count',
      many: 'Найдено $count',
      few: 'Найдено $count',
      one: 'Найден $count',
    );
    return '$_temp0';
  }

  @override
  String removeItem(String item) {
    return 'Убрать: $item';
  }

  @override
  String get done => 'Готово';

  @override
  String get discard => 'Отменить';

  @override
  String get change => 'Изменить';

  @override
  String get contactReadOnly =>
      'Аккаунт этого контакта доступен только для чтения, поэтому его нельзя изменить здесь';

  @override
  String get couldNotSaveContact => 'Не удалось сохранить контакт';

  @override
  String alreadySavedAs(String number, String name) {
    return '$number уже сохранён как $name.';
  }

  @override
  String alreadyInContacts(String name) {
    return '$name уже есть в контактах.';
  }

  @override
  String get alreadyInContactsTitle => 'Уже в контактах';

  @override
  String saveAnotherAnyway(String duplicate) {
    return '$duplicate Всё равно сохранить ещё один контакт?';
  }

  @override
  String get saveAnyway => 'Всё равно сохранить';

  @override
  String get saveOrDiscard => 'Сохранить изменения?';

  @override
  String get couldNotLoadContactRetry =>
      'Не удалось загрузить контакт. Повторить';

  @override
  String get email => 'Эл. почта';

  @override
  String get addEmail => 'Добавить эл. почту';

  @override
  String get addWebsite => 'Добавить сайт';

  @override
  String get relationships => 'Отношения';

  @override
  String get addRelationship => 'Добавить отношение';

  @override
  String get showLess => 'Свернуть';

  @override
  String get showMore => 'Показать ещё';

  @override
  String get newContact => 'Новый контакт';

  @override
  String get addToExistingContact => 'Добавить к контакту';

  @override
  String get editContact => 'Изменить контакт';

  @override
  String get couldNotLoadAccounts => 'Не удалось загрузить аккаунты';

  @override
  String get loadingAccounts => 'Загрузка аккаунтов…';

  @override
  String saveToAccount(String account) {
    return 'Сохранить в $account';
  }

  @override
  String get profilePicture => 'Фото профиля';

  @override
  String get camera => 'Камера';

  @override
  String get selectPhotos => 'Выбрать фото';

  @override
  String get deleteProfilePicture => 'Удалить фото профиля';

  @override
  String get couldNotOpenCamera => 'Не удалось открыть камеру';

  @override
  String get couldNotOpenApp => 'Не удалось открыть приложение';

  @override
  String get followSystem => 'Как в системе';

  @override
  String get customRingtone => 'Своя мелодия';

  @override
  String get fromFollowingAccount => 'Из аккаунта';

  @override
  String get fewerNameFields => 'Меньше полей имени';

  @override
  String get moreNameFields => 'Больше полей имени';

  @override
  String get namePrefix => 'Обращение';

  @override
  String get middleName => 'Отчество';

  @override
  String get nameSuffix => 'Суффикс имени';

  @override
  String get name => 'Имя';

  @override
  String get number => 'Номер';

  @override
  String get workInfo => 'Работа';

  @override
  String get company => 'Компания';

  @override
  String get jobTitle => 'Должность';

  @override
  String get department => 'Отдел';

  @override
  String get address => 'Адрес';

  @override
  String get street => 'Улица';

  @override
  String get city => 'Город';

  @override
  String get stateProvince => 'Область/регион';

  @override
  String get postalCode => 'Индекс';

  @override
  String get country => 'Страна';

  @override
  String get addAddress => 'Добавить адрес';

  @override
  String get importantDate => 'Важная дата';

  @override
  String get importantDates => 'Важные даты';

  @override
  String get addImportantDate => 'Добавить важную дату';

  @override
  String get noGroupsInAccount => 'В этом аккаунте нет групп';

  @override
  String get groups => 'Группы';

  @override
  String get enterNumber => 'Введите номер';

  @override
  String get chooseFromContacts => 'Выбрать из контактов';

  @override
  String get blockingNeedsScreeningRole =>
      'Чтобы блокировать эти вызовы, сделайте Dialer приложением для определения номера и защиты от спама';

  @override
  String get phoneNumber => 'Номер телефона';

  @override
  String get blockAndFilter => 'Блокировка и фильтры';

  @override
  String get blockingPaused => 'Правила блокировки приостановлены';

  @override
  String get blockingPausedSubtitle =>
      'Вызовы проверяет другое приложение. Нажмите, чтобы их проверял Dialer.';

  @override
  String get blockUnknown => 'Блокировать неизвестные/скрытые номера';

  @override
  String get blockUnknownSubtitle => 'Те, кто скрывает свой номер';

  @override
  String get blockNonContacts => 'Блокировать вызовы с номеров не из контактов';

  @override
  String get blockNonContactsSubtitle => 'Звонить смогут только ваши контакты';

  @override
  String get blockedNumbers => 'Заблокированные номера';

  @override
  String get blockedCalls => 'Заблокированные вызовы';

  @override
  String get addCall => 'Добавить';

  @override
  String get note => 'Заметка';

  @override
  String get editNote => 'Изменить заметку';

  @override
  String get videoCall => 'Видеовызов (Meet)';

  @override
  String get switchToVideoCall => 'Перейти к видеовызову';

  @override
  String get carrierVideo => 'Видеовызов оператора';

  @override
  String get cameraNeeded => 'Разрешите камеру для видеовызовов';

  @override
  String get answerAsVoice => 'Ответить голосом';

  @override
  String get videoRequest => 'Перейти к видеовызову?';

  @override
  String get accept => 'Принять';

  @override
  String get switchToVoice => 'Перейти к голосовому вызову';

  @override
  String get cameraOff => 'Выключить камеру';

  @override
  String get cameraOn => 'Включить камеру';

  @override
  String get flipCamera => 'Сменить камеру';

  @override
  String get incomingVideo => 'Видеовызов';

  @override
  String get incomingVideoCall => 'Входящий видеовызов';

  @override
  String get videoUnavailable => 'Видеозвонки недоступны';

  @override
  String get networkUnreachable => 'Сеть недоступна';

  @override
  String get networkBusy => 'Сеть перегружена';

  @override
  String get noService => 'Нет сети';

  @override
  String get voiceCall => 'Голосовой вызов';

  @override
  String get mute => 'Без звука';

  @override
  String get hold => 'Удержать';

  @override
  String get resume => 'Продолжить';

  @override
  String get headset => 'Гарнитура';

  @override
  String get speaker => 'Динамик';

  @override
  String get audioPhone => 'Телефон';

  @override
  String get wiredHeadset => 'Проводная гарнитура';

  @override
  String get endCall => 'Завершить вызов';

  @override
  String get end => 'Завершить';

  @override
  String get dialPad => 'Клавиатура';

  @override
  String get callNote => 'Заметка к вызову';

  @override
  String get callNoteHint => 'Запишите, что нужно запомнить из этого разговора';

  @override
  String get conferenceCall => 'Конференц-связь';

  @override
  String get unknown => 'Неизвестный';

  @override
  String get lineBusy => 'Линия занята';

  @override
  String get callDeclined => 'Вызов отклонён';

  @override
  String get callCancelled => 'Вызов отменён';

  @override
  String get callFailed => 'Ошибка вызова';

  @override
  String get callEnded => 'Вызов завершён';

  @override
  String get connected => 'Соединено';

  @override
  String get calling => 'Вызов';

  @override
  String get onHold => 'На удержании';

  @override
  String get phoneCall => 'Телефонный вызов';

  @override
  String get hdCall => 'HD-вызов';

  @override
  String switchToOnHold(String name) {
    return 'Переключиться на $name, на удержании';
  }

  @override
  String get switchCall => 'Переключить';

  @override
  String get declineWithSms => 'Ответ по SMS';

  @override
  String get answer => 'Ответить';

  @override
  String get decline => 'Отклонить';

  @override
  String get answerVerb => 'ответить';

  @override
  String get declineVerb => 'отклонить';

  @override
  String swipeUpDownHint(String up, String down) {
    return 'Проведите вверх, чтобы $up, вниз, чтобы $down';
  }

  @override
  String swipeUpHint(String action) {
    return 'Проведите вверх, чтобы $action';
  }

  @override
  String get effectsFull => 'Все эффекты';

  @override
  String get effectsReduced => 'Меньше эффектов';

  @override
  String get effectsOff => 'Без эффектов';

  @override
  String get off => 'Выкл.';

  @override
  String get always => 'Всегда';

  @override
  String get onlyWithHeadphones => 'Только с наушниками';

  @override
  String get incomingCallReminders => 'Входящие вызовы';

  @override
  String get incomingFootnote =>
      'Действует только для входящих вызовов, когда устройство разблокировано.';

  @override
  String get banner => 'Баннер';

  @override
  String get fullScreen => 'Во весь экран';

  @override
  String get announceCalls => 'Объявлять входящие вызовы';

  @override
  String get announceCallsSubtitle => 'Называет имя звонящего во время звонка';

  @override
  String get flashOnCall => 'Уведомление вспышкой';

  @override
  String get flashOnCallSubtitle => 'Вспышка камеры мигает, пока звонит вызов';

  @override
  String get systemFlash => 'В телефоне есть своё уведомление вспышкой';

  @override
  String get systemFlashSubtitle =>
      'Отключите одно из них, иначе будут мигать оба. Оно в Настройках, в разделе Уведомления или Спец. возможности';

  @override
  String get swipeUpToAnswer => 'Проведите вверх, чтобы ответить';

  @override
  String get swipeDownToAnswer => 'Проведите вниз, чтобы ответить';

  @override
  String get answerButtons => 'Экран вызова';

  @override
  String get twoButtons => '2 кнопки';

  @override
  String get oneButton => '1 кнопка';

  @override
  String get answerCall => 'Ответить на вызов';

  @override
  String get callScreenEffects => 'Эффекты экрана вызова';

  @override
  String get callScreenEffectsSubtitle => 'Стекло и свечение на экране вызова';

  @override
  String get callScreenAnimations => 'Анимации экрана вызова';

  @override
  String get callScreenAnimationsSubtitle =>
      'Движение при открытии, ответе и смене экрана вызова';

  @override
  String get hideContactNumbers => 'Скрывать номера контактов';

  @override
  String get hideContactNumbersSubtitle =>
      'Показывать только имя сохранённых контактов на экране вызова и в Вызовах';

  @override
  String get callerPhoto => 'Фото звонящего';

  @override
  String get callerPhotoSubtitle => 'Где фото контакта на экране вызова';

  @override
  String get callerPhotoSide => 'Рядом с именем';

  @override
  String get callerPhotoStacked => 'Над именем';

  @override
  String secondsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count секунды',
      many: '$count секунд',
      few: '$count секунды',
      one: '$count секунда',
    );
    return '$_temp0';
  }

  @override
  String get answerEndCalls => 'Ответ и завершение вызовов';

  @override
  String get vibrateAnswerEnd => 'Вибрация при ответе/завершении вызова';

  @override
  String get autoAnswer => 'Автоответ при подключённом внешнем аудиоустройстве';

  @override
  String get autoAnswerSubtitle => 'Включая Bluetooth и проводные наушники';

  @override
  String get autoAnswerDelay => 'Задержка автоответа';

  @override
  String get replyWithSms => 'Ответ по SMS';

  @override
  String get speakerDefault => 'Вызовы через динамик по умолчанию';

  @override
  String get speakerDefaultSubtitle =>
      'Не действует, если подключены внешние устройства.';

  @override
  String get quickDeclineMessage => 'Сообщение при отклонении';

  @override
  String get quickDeclineMessages => 'Сообщения при отклонении';

  @override
  String get quickDeclineHint =>
      'Отправляется, когда вы отклоняете вызов с сообщением';

  @override
  String get addMessage => 'Добавить сообщение';

  @override
  String get settingNotAvailable => 'В этом телефоне нет такой настройки';

  @override
  String get notDefaultApp => 'Не основное приложение для звонков';

  @override
  String get notDefaultAppSubtitle =>
      'Входящие вызовы идут в другое приложение';

  @override
  String get notificationsOff => 'Уведомления отключены';

  @override
  String get notificationsOffSubtitle =>
      'Вы не увидите входящие и пропущенные вызовы';

  @override
  String get fullScreenOff => 'Полноэкранные вызовы отключены';

  @override
  String get fullScreenOffSubtitle =>
      'Входящие вызовы показываются только как уведомление';

  @override
  String get blockingPausedShort => 'Вызовы проверяет другое приложение';

  @override
  String get bluetoothNamesHidden => 'Имена Bluetooth скрыты';

  @override
  String get bluetoothNamesHiddenSubtitle =>
      'Вызовы не отличают часы от наушников';

  @override
  String get fix => 'Исправить';

  @override
  String get callSettings => 'Настройки вызовов';

  @override
  String get needsAttention => 'Требует внимания';

  @override
  String get callerIdentification => 'Определение номера';

  @override
  String get callerIdSpamApp => 'Определитель номера и спам';

  @override
  String get carrierSettings => 'Настройки оператора';

  @override
  String get softwareUpdate => 'Обновление ПО';

  @override
  String get helpFeedback => 'Справка и отзывы';

  @override
  String get privacyPolicy => 'Политика конфиденциальности';

  @override
  String get aboutOneDialer => 'О One Dialer';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get openDetails => 'Открыть сведения';

  @override
  String get writeInKeypad => 'Ввести на клавиатуре';

  @override
  String get tapRecentCall => 'Нажатие на недавний вызов';

  @override
  String get chooseSimForCalls => 'С какой SIM звонить';

  @override
  String get appearance => 'Оформление';

  @override
  String get reduceVisualEffects => 'Меньше визуальных эффектов';

  @override
  String get displaySize => 'Размер интерфейса';

  @override
  String get displaySizeSmall => 'Мелкий';

  @override
  String get displaySizeDefault => 'Обычный';

  @override
  String get displaySizeLarge => 'Крупный';

  @override
  String get displaySizeLarger => 'Крупнее';

  @override
  String get displaySizeApp => 'Приложение';

  @override
  String get displaySizeNavBar => 'Панель навигации';

  @override
  String get reduceVisualEffectsSubtitle =>
      'Меньше размытия — плавнее на медленных телефонах';

  @override
  String get callScreenEdgeGlow => 'Свечение краёв на экране вызова';

  @override
  String get darkModeEdgeGlow => 'Сила свечения';

  @override
  String get edgeGlowClassic => 'Классика';

  @override
  String get edgeGlowSoft => 'Мягкое';

  @override
  String get edgeGlowBold => 'Яркое';

  @override
  String get glassStyle => 'Стиль стекла';

  @override
  String get navBarFrosted => 'Свечение краёв';

  @override
  String get navBarLiquid => 'Жидкое стекло';

  @override
  String get navBarGlass => 'Эффект стекла';

  @override
  String get navGlassPremium => 'Полное преломление';

  @override
  String get navGlassStandard => 'Лёгкий';

  @override
  String get navGlassAuto => 'Автоматически';

  @override
  String get glassSettings => 'Стекло и размытие';

  @override
  String get splashIcon => 'Значок на экране запуска';

  @override
  String get splashIconSubtitle =>
      'Отключите для пустого экрана запуска, если на главном экране другой значок';

  @override
  String get liquidGlassOn => 'Жидкое стекло';

  @override
  String get liquidScopeAll => 'Везде';

  @override
  String get liquidScopeControls => 'Панель и кнопки';

  @override
  String get liquidScopeNavbar => 'Только панель навигации';

  @override
  String get glassExperimentalNote =>
      'Жидкое стекло — экспериментальный и самый тяжёлый стиль: ему нужно ещё больше графической мощности, чем Свечению краёв, которое и так требовательно. Если прокрутка дёргается, попробуйте Только панель навигации или Эффект стекла › Автоматически либо вернитесь к Свечению краёв. На медленных телефонах плавнее всего Отображение и эффекты › Меньше визуальных эффектов.';

  @override
  String get callsFromOtherApps => 'Вызовы из других приложений';

  @override
  String get callsFromOtherAppsSubtitle =>
      'Показывать вызовы WhatsApp и других приложений в Недавних';

  @override
  String get manageContactsSubtitle =>
      'Отображение, место сохранения, импорт и экспорт, SIM, дубликаты';

  @override
  String get googleContactsSync => 'Синхронизация Google Контактов';

  @override
  String get googleContactsSyncSubtitle =>
      'Какие аккаунты синхронизируются и резервная копия контактов телефона';

  @override
  String get defaultApps => 'Приложения по умолчанию';

  @override
  String get notifications => 'Уведомления';

  @override
  String get setupTitle =>
      'Сделайте One Dialer приложением для звонков по умолчанию';

  @override
  String get setupBody =>
      'Нужно, чтобы звонить и отвечать на вызовы, показывать журнал вызовов и контакты и блокировать номера.';

  @override
  String get settingUp => 'Настройка…';

  @override
  String get setupDisclosure =>
      'One Dialer использует разрешение «Телефон», чтобы совершать вызовы и управлять ими на ваших SIM-картах, «Журнал звонков» — для Недавних и пропущенных вызовов, «Контакты» — для имён, фото и поиска, и «Уведомления» — для входящих, текущих и пропущенных вызовов. Ваши вызовы, журнал вызовов и контакты никогда не покидают телефон. Отчёты о сбоях (без личных данных) помогают исправлять ошибки.';

  @override
  String get installedDirectly => 'Установлено напрямую';

  @override
  String get anotherAppStore => 'Другой магазин приложений';

  @override
  String aboutApp(String app) {
    return 'О $app';
  }

  @override
  String get updateAvailable => 'Доступно обновление';

  @override
  String get versionUpToDate => 'Установлена последняя версия';

  @override
  String get checkForUpdates => 'Проверить обновления';

  @override
  String get checking => 'Проверка…';

  @override
  String get version => 'Версия';

  @override
  String get build => 'Сборка';

  @override
  String get installedFrom => 'Источник установки';

  @override
  String get device => 'Устройство';

  @override
  String get androidVersion => 'Версия Android';

  @override
  String get openSourceLicences => 'Лицензии открытого ПО';

  @override
  String get copyrightNotice =>
      'Copyright (C) 2026 Syed Arham Raza\nСвободное программное обеспечение по лицензии GNU General Public License v3.0, без каких-либо гарантий';

  @override
  String get changelog => 'Список изменений';

  @override
  String installedOn(String date) {
    return 'Установлено $date';
  }

  @override
  String get earlierVersions => 'Предыдущие версии';

  @override
  String get aboutThisUpdate => 'Об этом обновлении';

  @override
  String get reportLag => 'Сообщить о задержках';

  @override
  String get reportLagMessage =>
      'Отправляет недавние замеры производительности, названия экранов и действий и сведения об устройстве, чтобы найти замедления. Номера телефонов, контакты и сообщения не отправляются.';

  @override
  String get sendReport => 'Отправить отчёт';

  @override
  String get reportUnavailable =>
      'Отправка недоступна или уже была запрошена. Повторите через минуту.';

  @override
  String get reportQueued => 'Отчёт в очереди';

  @override
  String reportQueuedMessage(String id) {
    return 'Отчёт сохранён и будет отправлен, когда это станет возможно. Укажите этот ID в отзыве:\\n\\n$id';
  }

  @override
  String get copy => 'Копировать';

  @override
  String get paste => 'Вставить';

  @override
  String get copyId => 'Копировать ID';

  @override
  String get reportIdCopied => 'ID отчёта скопирован';

  @override
  String get editSpeedDial => 'Изменить быстрый набор';

  @override
  String get clearNumber => 'Очистить номер';

  @override
  String get changeNumber => 'Изменить номер';

  @override
  String get numberCopied => 'Номер скопирован';

  @override
  String get noEmailApp => 'Нет почтового приложения';

  @override
  String get noBrowser => 'Нет браузера';

  @override
  String get sendFeedback => 'Отправить отзыв';

  @override
  String get feedbackTypeTitle => 'О чём речь?';

  @override
  String get feedbackBug => 'Сообщить о проблеме';

  @override
  String get feedbackIdea => 'Предложить идею';

  @override
  String get feedbackQuestion => 'Задать вопрос';

  @override
  String get developer => 'Разработчик';

  @override
  String get downloadStopped =>
      'Загрузка остановлена. Повторите, когда будет подключение.';

  @override
  String get couldNotInstallUpdate =>
      'Не удалось установить обновление. Повторите попытку.';

  @override
  String get updateCancelled =>
      'Обновление отменено. Загрузить его можно здесь в любое время.';

  @override
  String get noInternet =>
      'Нет подключения к интернету. Подключитесь и повторите попытку.';

  @override
  String get couldNotDownloadUpdate =>
      'Не удалось загрузить обновление. Повторите попытку.';

  @override
  String get softwareInformation => 'Сведения о ПО';

  @override
  String get autoDownload => 'Автозагрузка';

  @override
  String get downloadAndInstall => 'Загрузить и установить';

  @override
  String get installAndRestart => 'Установить и перезапустить';

  @override
  String get tryAgain => 'Повторить';

  @override
  String get downloading => 'Загрузка…';

  @override
  String get noNetwork => 'Нет подключения к сети';

  @override
  String get notFromPlay =>
      'Обновления приходят из Google Play. Эта копия установлена не из Play.';

  @override
  String get notFromPlayTitle => 'Не из Google Play';

  @override
  String get notFromPlayWarning =>
      'Эта копия установлена не из Google Play, поэтому не будет получать обновления и могла быть изменена. Можно продолжить пользоваться ею или получить официальную версию из бета-программы.';

  @override
  String get keepUsing => 'Продолжить';

  @override
  String get getOfficialVersion => 'Официальная версия';

  @override
  String get couldNotReachPlay => 'Нет связи с Google Play';

  @override
  String get softwareVersion => 'Версия ПО';

  @override
  String get closedBeta => 'Закрытая бета';

  @override
  String get newVersionAvailable => 'Доступна новая версия';

  @override
  String get autoDownloadExplainer =>
      'Когда One Dialer проверяет обновления в Google Play при открытии. Обновления устанавливаются только после нажатия Загрузить и установить.';

  @override
  String get autoUpdateNeverSubtitle =>
      'Только по нажатию Проверить обновления';

  @override
  String get autoUpdateAlwaysSubtitle =>
      'Проверка расходует очень мало трафика';

  @override
  String get autoUpdateNever => 'Никогда';

  @override
  String get autoUpdateWifiOnly => 'Только по Wi-Fi';

  @override
  String get autoUpdateAlways => 'По Wi-Fi или мобильной сети';

  @override
  String get displayAndEffects => 'Отображение и эффекты';

  @override
  String get keypadAndRecents => 'Клавиатура и недавние';

  @override
  String get logIncoming => 'Входящий';

  @override
  String get logOutgoing => 'Исходящий';

  @override
  String get logMissed => 'Пропущенный';

  @override
  String get logRejected => 'Отклонённый';

  @override
  String get logBlocked => 'Заблокированный';

  @override
  String logRangFor(String type, String duration) {
    return '$type (звонил $duration)';
  }

  @override
  String get record => 'Записать';

  @override
  String get stopRecording => 'Остановить запись';

  @override
  String get recordSetUpFirst => 'Записать (настройте в Настройках)';

  @override
  String get recordingNow => 'Идёт запись';

  @override
  String get callRecording => 'Запись вызовов';

  @override
  String get recorderApp => 'One Recorder';

  @override
  String get recorderBothSides => 'Записывает обе стороны разговора';

  @override
  String get recorderNeedsSetup => 'Настройте обе стороны в One Recorder';

  @override
  String get recorderHelperStopped =>
      'Обе стороны на паузе: запустите службу в One Recorder';

  @override
  String get recorderUntrusted =>
      'Запись работает только с One Dialer из Google Play. Установите его из Play или обновите оба приложения.';

  @override
  String get recordingConsentTitle => 'Перед записью';

  @override
  String get recordingConsentBody =>
      'Законы о записи разговоров различаются по странам, и в некоторых нужно согласие всех участников. Вы отвечаете за то, чтобы предупредить собеседника и получить его согласие. Записи остаются на этом телефоне и никуда не загружаются.';

  @override
  String get recordingConsentAccept => 'Понятно';

  @override
  String get recordings => 'Записи';

  @override
  String get noRecordings => 'Записей пока нет';

  @override
  String get noRecordingsSubtitle =>
      'Во время вызова нажмите ⋮ › Записать на экране вызова';

  @override
  String get deleteAllRecordings => 'Удалить все записи';

  @override
  String get deleteAllRecordingsTitle => 'Удалить все записи?';

  @override
  String get deleteAllRecordingsMessage => 'Их нельзя будет восстановить.';

  @override
  String get recordingNotSetUp => 'Вызовы не записываются';

  @override
  String get recordingNotSetUpSubtitle =>
      'Автозапись включена, но One Recorder не настроен';

  @override
  String get rename => 'Переименовать';

  @override
  String get star => 'Отметить';

  @override
  String get unstar => 'Снять отметку';

  @override
  String get filterStarred => 'Отмеченные';

  @override
  String get filterUnknown => 'Неизвестные';

  @override
  String get saveToPhone => 'Сохранить в телефон';

  @override
  String get searchRecordings => 'Поиск записей';

  @override
  String get renameRecording => 'Переименовать запись';

  @override
  String recordingsSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count записи сохранено в Recordings/One Dialer',
      many: '$count записей сохранено в Recordings/One Dialer',
      few: '$count записи сохранены в Recordings/One Dialer',
      one: '$count запись сохранена в Recordings/One Dialer',
    );
    return '$_temp0';
  }

  @override
  String get recordingSaveFailed => 'Не удалось сохранить в телефон';

  @override
  String deleteRecordings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Удалить $count записи?',
      many: 'Удалить $count записей?',
      few: 'Удалить $count записи?',
      one: 'Удалить $count запись?',
    );
    return '$_temp0';
  }

  @override
  String get noMatchingRecordings => 'Нет подходящих записей';

  @override
  String get addContact => 'Добавить контакт';

  @override
  String get autoRecord => 'Автозапись';

  @override
  String get autoRecordOff => 'Выкл.';

  @override
  String get autoRecordAll => 'Все вызовы';

  @override
  String get autoRecordUnknown => 'Неизвестные номера';

  @override
  String get autoRecordContacts => 'Выбранные контакты';

  @override
  String get recordTheseContacts => 'Записывать контакты';

  @override
  String get neverRecord => 'Никогда не записывать';

  @override
  String get neverRecordSubtitle =>
      'Контакты, которые автозапись всегда пропускает';

  @override
  String get storage => 'Хранилище';

  @override
  String get storageUsed => 'Занято';

  @override
  String get autoDelete => 'Автоудаление';

  @override
  String get autoDeleteSubtitle => 'Отмеченные записи сохраняются всегда';

  @override
  String get autoDeleteNever => 'Никогда';

  @override
  String autoDeleteDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Через $days дня',
      many: 'Через $days дней',
      few: 'Через $days дня',
      one: 'Через $days день',
    );
    return '$_temp0';
  }

  @override
  String get imeiTitle => 'IMEI';

  @override
  String get imeiUnavailable =>
      'Android не позволяет приложениям показывать IMEI. Его можно найти в настройках телефона, в разделе О телефоне.';

  @override
  String get aboutPhone => 'О телефоне';

  @override
  String get glassStyleSubtitle =>
      'Жидкое стекло искажает то, что за ним, но расходует больше энергии';

  @override
  String get darkModeEdgeGlowSubtitle =>
      'Насколько ярко светятся края стекла в тёмной теме';

  @override
  String get liquidGlassOnSubtitle =>
      'Какие части приложения используют жидкое стекло';

  @override
  String get navBarGlassSubtitle =>
      'Полное преломление выглядит лучше всего; Лёгкий плавнее на медленных телефонах';

  @override
  String get tapRecentCallSubtitle =>
      'Что происходит при нажатии на вызов в Вызовах';

  @override
  String get callScreenEdgeGlowSubtitle =>
      'Насколько ярко светятся стеклянные края кнопок вызова';

  @override
  String get answerButtonsSubtitle =>
      'Способ ответа, эффекты, фото звонящего и фон';

  @override
  String get incomingCallsSubtitle =>
      'Стиль звонка, объявление, вспышка, Live Update';

  @override
  String get answerEndCallsSubtitle => 'Автоответ, ответ по SMS, динамик';

  @override
  String get sectionCalls => 'Вызовы';

  @override
  String get sectionMakingCalls => 'Исходящие вызовы';

  @override
  String get sectionBlocking => 'Блокировка и определение номера';

  @override
  String get sectionDisplay => 'Отображение';

  @override
  String get sectionSystem => 'Контакты и система';

  @override
  String get searchSettings => 'Поиск настроек';

  @override
  String get carrierSettingsSubtitle =>
      'Переадресация, ожидание вызова и определение номера';

  @override
  String get callBackground => 'Фон вызова';

  @override
  String get callBackgroundAllSubtitle =>
      'Для всех вызовов, если у контакта нет своего';

  @override
  String get callBackgroundDefault => 'По умолчанию';

  @override
  String get callBackgroundColour => 'Цвет';

  @override
  String get callBackgroundPhoto => 'Фото';

  @override
  String get callBackgroundAurora => 'Аврора';

  @override
  String get callBackgroundAuto => 'Авто';

  @override
  String get callBackgroundAutoNote =>
      'Авто: у каждого звонящего свои цвета, по фото контакта или по имени.';

  @override
  String get callBackgroundColourNote => 'Все вызовы используют этот цвет.';

  @override
  String get callBackgroundChangePhoto => 'Сменить фото';

  @override
  String get callBackgroundPhotoBackupNote =>
      'Фото хранятся только на этом телефоне. Чтобы сохранить их после переустановки One Dialer или на новом телефоне,';

  @override
  String get callBackgroundPhotoBackupLink =>
      'создайте резервную копию настроек';

  @override
  String get callBackgroundSoft => 'Размыть и затемнить';

  @override
  String get callBackgroundSoftSubtitle => 'Смягчает фото за вызовом';

  @override
  String get callBackgroundContactPhoto => 'Фото контакта';

  @override
  String get callBackgroundContactPhotoSubtitle =>
      'Android хранит фото контактов маленькими; выберите фото для более чёткого изображения';

  @override
  String get callBackgroundSameAsAll => 'Как для всех вызовов';

  @override
  String get callBackgroundAllNote =>
      'Контакт со своим фоном вызова, заданным на его странице, использует свой фон.';

  @override
  String get callBackgroundContactNote =>
      'Используется для этого контакта вместо общего фона вызова.';

  @override
  String get backUpRestore => 'Резервное копирование';

  @override
  String get backUpRestoreSubtitle =>
      'Настройки, заметки и фоны вызовов в одном файле на этом телефоне';

  @override
  String get backUpNow => 'Создать копию';

  @override
  String lastBackup(String time) {
    return 'Последняя копия: $time';
  }

  @override
  String get backupNever => 'Копий ещё нет';

  @override
  String get restoreBackup => 'Восстановить';

  @override
  String get restoreBackupSubtitle =>
      'Выберите файл копии; Файлы откроются в папке Документы';

  @override
  String get autoBackup => 'Автокопирование';

  @override
  String get backupFrequency => 'Частота';

  @override
  String get backupEveryDay => 'Каждый день';

  @override
  String get backupEvery3Days => 'Раз в 3 дня';

  @override
  String get backupEveryWeek => 'Каждую неделю';

  @override
  String get backupEveryMonth => 'Каждый месяц';

  @override
  String get backupLocation => 'Папка';

  @override
  String get backupLocationNone =>
      'Выберите папку; Документы — хороший вариант';

  @override
  String get backupFailed =>
      'Последнее копирование не удалось. Нажмите Папка, чтобы выбрать её заново.';

  @override
  String get backupFootnote =>
      'В копии хранятся настройки, быстрый набор, заметки к вызовам и фоны вызовов с фото. Это один файл, который заменяется при каждом копировании, поэтому он не заполнит память. Автокопирование выполняется при открытии One Dialer или после завершения вызова.';

  @override
  String get backedUp => 'Копия создана';

  @override
  String get couldNotBackUp => 'Не удалось сохранить копию в эту папку';

  @override
  String get importSettingsTitle => 'Заменить настройки?';

  @override
  String get importSettingsMessage =>
      'Ваши настройки, быстрый набор, заметки к вызовам и фоны вызовов будут заменены данными из файла. Затем One Dialer перезапустится.';

  @override
  String get importSettingsInCall =>
      'Во время вызова нельзя импортировать настройки';

  @override
  String get notASettingsFile => 'Это не файл настроек One Dialer';

  @override
  String endHeldCall(String name) {
    return 'Завершить вызов: $name';
  }

  @override
  String get fullScreenAsk =>
      'Входящие вызовы показываются только в панели уведомлений. На следующей странице включите полноэкранные уведомления для One Dialer. Если уже включено, выключите и включите снова.';

  @override
  String get notNow => 'Не сейчас';

  @override
  String get vipCalls => 'VIP-вызовы';

  @override
  String get vipCallsSubtitle => 'Звонят даже в режиме Без звука или Вибрация';

  @override
  String get vipRing => 'Звонок VIP в режиме Без звука';

  @override
  String get vipRingSubtitle =>
      'Вызовы от VIP звонят, даже если телефон в режиме Без звука или Вибрация, затем режим возвращается';

  @override
  String get vipFavourites => 'Включить избранные';

  @override
  String get vipFavouritesSubtitle => 'Избранные контакты считаются VIP';

  @override
  String get vipContacts => 'VIP-контакты';

  @override
  String get vipNeedsAccess => 'VIP-вызовы не звонят в режиме Без звука';

  @override
  String get vipNeedsAccessSubtitle =>
      'Разрешите проверку вызовов и доступ к режиму Не беспокоить';

  @override
  String get vipDndHint =>
      'Когда включён режим Не беспокоить, Android сам решает, кто может звонить: разрешите избранные контакты в настройках Не беспокоить.';

  @override
  String get rowCallButton => 'Кнопка вызова в строках';

  @override
  String get rowCallButtonSubtitle => 'Кнопка вызова в каждой строке Вызовов';

  @override
  String get swipeToCall => 'Свайп для вызова или сообщения';

  @override
  String get swipeToCallSubtitle =>
      'Проведите строку вправо — вызов, влево — сообщение';

  @override
  String get clearDefault => 'Сбросить по умолчанию';

  @override
  String get swipeStyle => 'Стиль свайпа';

  @override
  String get swipeStylePill => 'Стеклянная кнопка';

  @override
  String get swipeStyleFlat => 'Плоский';

  @override
  String get quickCalling => 'Быстрый вызов';

  @override
  String get quickCallingSubtitle => 'Нажатие, кнопка вызова и свайп в строках';

  @override
  String get useRecentSim => 'Недавняя SIM';

  @override
  String get simSameAsPhone => 'Как в телефоне';

  @override
  String alwaysSim(Object sim) {
    return 'Всегда $sim';
  }

  @override
  String get keypadSimButtons => 'Две кнопки вызова';

  @override
  String get keypadSimButtonsSubtitle =>
      'По одной на каждую SIM вместо одной кнопки вызова';

  @override
  String get keypadSimButtonsOneSim => 'Только на телефонах с двумя SIM';

  @override
  String get keypadSettings => 'Клавиатура';

  @override
  String get keypadSettingsSubtitle => 'Две кнопки вызова, быстрый набор';

  @override
  String get phoneDefaultSim => 'SIM по умолчанию в телефоне';

  @override
  String get simRulesHint =>
      'Собственная SIM контакта, заданная на его странице, всегда в приоритете.';

  @override
  String get callButtonStyle => 'Стиль кнопки вызова';

  @override
  String get callButtonTint => 'Мягкий оттенок';

  @override
  String get callButtonGlyph => 'Только значок';

  @override
  String get callButtonLit => 'Зелёный круг';

  @override
  String get callsAndContactsRows => 'Строки в Вызовах и Контактах';

  @override
  String get callsRows => 'Строки в Вызовах';

  @override
  String get tapAlreadyCalls => 'Нажатие на вызов уже звонит';

  @override
  String get simCards => 'SIM-карты';

  @override
  String get groupByContact => 'Группировать по контактам';

  @override
  String get dontGroupByContact => 'Не группировать по контактам';

  @override
  String get keypadAndContacts => 'Клавиатура и контакты';

  @override
  String get swipeToCallSim => 'Свайп для вызова';

  @override
  String get sameAsKeypad => 'Как на клавиатуре';

  @override
  String get tapSimUnused =>
      'Используется, только если в Быстром вызове Нажатие на недавний вызов — Вызов';

  @override
  String get swipeSimUnused =>
      'Используется, только если в Быстром вызове включён Свайп для вызова';

  @override
  String get onboardingSkip => 'Пропустить';

  @override
  String get onboardingNext => 'Далее';

  @override
  String get onboardingStart => 'Начать';

  @override
  String get onboardingLookTitle => 'Под себя';

  @override
  String get onboardingLookBody =>
      'Выберите язык приложения и светлую или тёмную тему.';

  @override
  String get onboardingAnswerTitle => 'Ответ на вызовы';

  @override
  String get onboardingAnswerBody =>
      'Выберите, как выглядят входящие вызовы и как на них отвечать.';

  @override
  String get onboardingHealthTitle => 'Готово к вызовам';

  @override
  String get onboardingHealthBody =>
      'Для входящих вызовов это нужно от Android. Нажмите на пункт, чтобы исправить.';

  @override
  String get onboardingAllSet => 'Всё готово';

  @override
  String get onboardingCallingTitle => 'Исходящие вызовы';

  @override
  String get onboardingCallingBody =>
      'Выберите SIM для вызовов и что делает нажатие или свайп по вызову.';

  @override
  String get mergeDuplicatedNames => 'Объединить одинаковые имена';

  @override
  String get mergeDuplicatedNumbers => 'Объединить одинаковые номера';

  @override
  String get manuallyMergeDuplicates => 'Объединить дубликаты вручную';

  @override
  String get sameNumberContacts => 'Контакты с одинаковым номером';

  @override
  String get sameNameContacts => 'Контакты с одинаковым именем';

  @override
  String groupCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count группы',
      many: '$count групп',
      few: '$count группы',
      one: '$count группа',
    );
    return '$_temp0';
  }

  @override
  String get mergeManually => 'Объединить вручную';

  @override
  String get manualMergingDetails => 'Параметры объединения';

  @override
  String get nameRequired => 'Имя (обязательно)';

  @override
  String get numbersSelectMany => 'Номер (можно выбрать несколько)';

  @override
  String mergeDeletesNumbers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Неотмеченные номера ($count) будут удалены из контакта.',
      one: 'Неотмеченный номер будет удалён из контакта.',
    );
    return '$_temp0';
  }

  @override
  String get blockCalls => 'Блокировка вызовов';

  @override
  String get blockMessages => 'Блокировка сообщений';

  @override
  String get blockMessagesUnavailable =>
      'One Dialer не является приложением для сообщений, поэтому не может их блокировать. Блокировка вызовов, чёрный и белый списки работают как прежде.';

  @override
  String get blocklist => 'Чёрный список';

  @override
  String get blocklistSubtitle =>
      'Вызовы с номеров из чёрного списка будут блокироваться.';

  @override
  String get allowlist => 'Белый список';

  @override
  String get allowlistSubtitle =>
      'Вызовы с номеров из белого списка не будут блокироваться.';

  @override
  String get none => 'Нет';

  @override
  String get noNumbers => 'Нет номеров';

  @override
  String get blockByPrefix => 'Блокировать по префиксу';

  @override
  String get numberPrefix => 'Префикс, например 0300';

  @override
  String startsWith(String prefix) {
    return 'Начинается с $prefix';
  }

  @override
  String removeFromBlocklist(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Удалить $count номера из чёрного списка?',
      many: 'Удалить $count номеров из чёрного списка?',
      few: 'Удалить $count номера из чёрного списка?',
      one: 'Удалить $count номер из чёрного списка?',
    );
    return '$_temp0';
  }

  @override
  String removeFromAllowlist(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Удалить $count номера из белого списка?',
      many: 'Удалить $count номеров из белого списка?',
      few: 'Удалить $count номера из белого списка?',
      one: 'Удалить $count номер из белого списка?',
    );
    return '$_temp0';
  }

  @override
  String searchContactNumbers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Поиск среди $count номеров контактов',
      one: 'Поиск среди $count номера контактов',
    );
    return '$_temp0';
  }

  @override
  String get unofficialBuildTitle => 'Неофициальная сборка';

  @override
  String get unofficialBuildCredit =>
      'Основано на One Dialer от Syed Arham Raza, github.com/syedarhamraza/one-dialer';

  @override
  String get unofficialBuildNotice =>
      'Неофициальная сборка. Основано на One Dialer от Syed Arham Raza, github.com/syedarhamraza/one-dialer';

  @override
  String mergeAll(String count) {
    return 'Объединить все ($count)';
  }

  @override
  String mergeGroupsTitle(String count, String groups) {
    return 'Объединить контакты ($count) в $groups?';
  }

  @override
  String get mergeGroupsMessage =>
      'Каждая группа станет одним контактом со всеми номерами и данными.';
}
