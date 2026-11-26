// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get languageName => 'Español';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get dismiss => 'Descartar';

  @override
  String get dismissMenu => 'Cerrar menú';

  @override
  String get share => 'Compartir';

  @override
  String get more => 'Más';

  @override
  String get back => 'Atrás';

  @override
  String get soon => 'Pronto';

  @override
  String get all => 'Todo';

  @override
  String get selectAll => 'Seleccionar todo';

  @override
  String get deselectAll => 'Deseleccionar';

  @override
  String get selectItems => 'Seleccionar elementos';

  @override
  String get search => 'Buscar';

  @override
  String get searchContacts => 'Buscar contactos';

  @override
  String get clear => 'Borrar';

  @override
  String get clearSearch => 'Borrar búsqueda';

  @override
  String get searchByVoice => 'Buscar por voz';

  @override
  String get scrollToTop => 'Ir arriba';

  @override
  String dateWheelDay(String day) {
    return 'Día $day';
  }

  @override
  String dateWheelYear(String year) {
    return 'Año $year';
  }

  @override
  String get navCalls => 'Llamadas';

  @override
  String get navContacts => 'Contactos';

  @override
  String get returnToCall => 'Volver a la llamada';

  @override
  String get createContact => 'Crear contacto';

  @override
  String get showKeypad => 'Mostrar teclado';

  @override
  String get settingsLanguageHeader => 'Idioma';

  @override
  String get settingsAppLanguage => 'Idioma de la app';

  @override
  String get settingsAppLanguageSubtitle => 'Solo cambia esta app';

  @override
  String get settingsLanguageSystem => 'Igual que el teléfono';

  @override
  String get settingsAndroidLanguage => 'Ajustes de idioma de Android';

  @override
  String get settingsAndroidLanguageSubtitle =>
      'Elige el idioma en los ajustes de Android';

  @override
  String get call => 'Llamar';

  @override
  String get message => 'Mensaje';

  @override
  String get add => 'Añadir';

  @override
  String get block => 'Bloquear';

  @override
  String get unblock => 'Desbloquear';

  @override
  String get settings => 'Ajustes';

  @override
  String get notes => 'Notas';

  @override
  String get moreOptions => 'Más opciones';

  @override
  String get voicemail => 'Buzón de voz';

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

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
  String get privateNumber => 'Número privado';

  @override
  String appVideo(String app) {
    return 'Vídeo de $app';
  }

  @override
  String videoCallOnApp(String app) {
    return 'Videollamada por $app';
  }

  @override
  String callOnApp(String app) {
    return 'Llamada por $app';
  }

  @override
  String get callTypeOutgoing => 'Llamada saliente';

  @override
  String get callTypeMissed => 'Llamada perdida';

  @override
  String get callTypeRejected => 'Llamada rechazada';

  @override
  String get callTypeBlocked => 'Llamada bloqueada';

  @override
  String get callTypeVoicemail => 'Buzón de voz';

  @override
  String get callNotConnected => '(No conectada)';

  @override
  String get callTypeIncoming => 'Llamada entrante';

  @override
  String get speedDialNoNumber => 'Sin número de marcación rápida';

  @override
  String speedDialAssignPrompt(String digit) {
    return '¿Asignar un contacto a la tecla $digit?';
  }

  @override
  String get assign => 'Asignar';

  @override
  String get couldNotPlaceCall => 'No se pudo hacer la llamada';

  @override
  String get keypadNumberEmpty => 'Número, vacío. Mantén pulsado para pegar';

  @override
  String keypadNumber(String number) {
    return 'Número $number';
  }

  @override
  String get keypadZeroHint => '0, mantén pulsado para el signo más';

  @override
  String get keypadVoicemailHint => '1, mantén pulsado para el buzón de voz';

  @override
  String keypadDigitHint(String digit) {
    return '$digit, mantén pulsado para marcación rápida';
  }

  @override
  String get hideKeypad => 'Ocultar teclado';

  @override
  String callWithSim(String slot, String sim) {
    return 'Llamar con la SIM $slot, $sim';
  }

  @override
  String get keypadDeleteHint => 'Eliminar, mantén pulsado para borrar todo';

  @override
  String get addPause => 'Añadir pausa de 2 s';

  @override
  String get addWait => 'Añadir espera';

  @override
  String get sendMessage => 'Enviar mensaje';

  @override
  String get speedDialNumbers => 'Números de marcación rápida';

  @override
  String speedDialKey(String digit) {
    return 'Marcación rápida $digit';
  }

  @override
  String get speedDial => 'Marcación rápida';

  @override
  String get speedDialAssignContacts => 'Asignar contactos';

  @override
  String speedDialRemoved(String name, String digit) {
    return 'Se quitó a $name de la tecla $digit';
  }

  @override
  String get callLogs => 'Registros de llamadas';

  @override
  String get deleteCallHistory => 'Eliminar historial de llamadas';

  @override
  String deleteCallsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Eliminar $count llamadas?',
      one: '¿Eliminar la llamada?',
    );
    return '$_temp0';
  }

  @override
  String get deleteCallsMessage =>
      'El historial de llamadas seleccionado se eliminará de este teléfono.';

  @override
  String get couldNotDeleteCalls =>
      'No se pudo eliminar el historial. Inténtalo de nuevo.';

  @override
  String get showAllCalls => 'Mostrar todas las llamadas';

  @override
  String get showAppCallsOnly => 'Mostrar solo llamadas de apps';

  @override
  String get showBlockedCalls => 'Mostrar llamadas bloqueadas';

  @override
  String get hideBlockedCalls => 'Ocultar llamadas bloqueadas';

  @override
  String blockNumberTitle(String number) {
    return '¿Bloquear $number?';
  }

  @override
  String blockNumbersTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Bloquear $count números?',
      one: '¿Bloquear 1 número?',
    );
    return '$_temp0';
  }

  @override
  String get blockNumbersMessage =>
      'No recibirás llamadas de los números bloqueados.';

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seleccionados',
      one: '1 seleccionado',
    );
    return '$_temp0';
  }

  @override
  String get recentsSetDefaultMessage =>
      'Configura Dialer como app de teléfono predeterminada para ver las llamadas recientes';

  @override
  String get setAsDefault => 'Predeterminar';

  @override
  String get recentsNoAppCalls => 'No hay llamadas de apps';

  @override
  String get recentsNoRecentCalls => 'No hay llamadas recientes';

  @override
  String get recentsNoMissedCalls => 'No hay llamadas perdidas';

  @override
  String get recentsFilterMissed => 'Perdidas';

  @override
  String get addToContacts => 'Añadir a Contactos';

  @override
  String get callDetails => 'Detalles de la llamada';

  @override
  String contactLabel(String label) {
    String _temp0 = intl.Intl.selectLogic(label, {
      'mobile': 'Móvil',
      'home': 'Casa',
      'work': 'Trabajo',
      'workMobile': 'Móvil del trabajo',
      'main': 'Principal',
      'phone': 'Teléfono',
      'faxHome': 'Fax de casa',
      'faxWork': 'Fax del trabajo',
      'faxOther': 'Otro fax',
      'pager': 'Buscapersonas',
      'workPager': 'Buscapersonas del trabajo',
      'school': 'Escuela',
      'car': 'Coche',
      'companyMain': 'Principal de la empresa',
      'callback': 'Devolución de llamada',
      'assistant': 'Asistente',
      'birthday': 'Cumpleaños',
      'anniversary': 'Aniversario',
      'homepage': 'Página principal',
      'blog': 'Blog',
      'profile': 'Perfil',
      'brother': 'Hermano',
      'sister': 'Hermana',
      'child': 'Hijo/a',
      'father': 'Padre',
      'mother': 'Madre',
      'parent': 'Padre/madre',
      'friend': 'Amigo/a',
      'manager': 'Responsable',
      'partner': 'Pareja',
      'relative': 'Familiar',
      'spouse': 'Cónyuge',
      'domesticPartner': 'Pareja de hecho',
      'referredBy': 'Recomendado por',
      'other': 'Otro',
    });
    return '$_temp0';
  }

  @override
  String addressLabel(String label) {
    return 'Dirección ($label)';
  }

  @override
  String get accountSamsung => 'Cuenta Samsung';

  @override
  String get accountSimServiceNumbers => 'Números de servicio de la SIM';

  @override
  String get accountSimCard => 'Tarjeta SIM';

  @override
  String get accountThisDevice => 'Este dispositivo';

  @override
  String contactsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contactos',
      one: '1 contacto',
    );
    return '$_temp0';
  }

  @override
  String get justOnce => 'Solo una vez';

  @override
  String get close => 'Cerrar';

  @override
  String get ok => 'Aceptar';

  @override
  String get edit => 'Editar';

  @override
  String get video => 'Vídeo';

  @override
  String get videoCallMark => 'Videollamada';

  @override
  String get wifiCallMark => 'Llamada por Wi-Fi';

  @override
  String get volteCall => 'Llamada VoLTE';

  @override
  String get vonrCall => 'Llamada de voz 5G';

  @override
  String get remove => 'Quitar';

  @override
  String get custom => 'Personalizado';

  @override
  String get allow => 'Permitir';

  @override
  String get select => 'Seleccionar';

  @override
  String get merge => 'Combinar';

  @override
  String get import => 'Importar';

  @override
  String get qrScanHint =>
      'Escanea con la cámara de un teléfono para añadir este contacto';

  @override
  String deleteContactTitle(String name) {
    return '¿Eliminar a $name?';
  }

  @override
  String get deleteContactMessage =>
      'Este contacto se eliminará de este teléfono y de sus cuentas.';

  @override
  String get shareVcf => 'Archivo vCard (VCF)';

  @override
  String get shareText => 'Texto';

  @override
  String get qrCode => 'Código QR';

  @override
  String get blockContact => 'Bloquear contacto';

  @override
  String get unblockContact => 'Desbloquear contacto';

  @override
  String get askEveryTime => 'Preguntar siempre';

  @override
  String get contactNotFound => 'Contacto no encontrado';

  @override
  String get addToFavourites => 'Añadir a favoritos';

  @override
  String get removeFromFavourites => 'Quitar de favoritos';

  @override
  String get defaultNumber => 'Predeterminado';

  @override
  String get ringtone => 'Tono de llamada';

  @override
  String get organization => 'Trabajo';

  @override
  String get website => 'Sitio web';

  @override
  String get simForCalls => 'Tarjeta SIM para llamadas';

  @override
  String get storageLocations => 'Ubicaciones de almacenamiento';

  @override
  String get viewAll => 'Ver todo';

  @override
  String get selectContact => 'Seleccionar contacto';

  @override
  String get noMatchingContacts => 'No hay contactos que coincidan';

  @override
  String get noCallsWithContact => 'Aún no hay llamadas con este contacto';

  @override
  String get unlink => 'Desvincular';

  @override
  String get unlinkAll => 'Desvincular todo';

  @override
  String deleteContactsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Eliminar $count contactos?',
      one: '¿Eliminar el contacto?',
    );
    return '$_temp0';
  }

  @override
  String get deleteContactsMessage =>
      'Se eliminarán de este teléfono y de sus cuentas.';

  @override
  String get manageContacts => 'Gestionar contactos';

  @override
  String get contactsAccessMessage =>
      'Permite el acceso a tus contactos para verlos aquí y mostrar nombres en las llamadas';

  @override
  String get alphabetIndex => 'Índice alfabético';

  @override
  String get createNewContact => 'Crear contacto nuevo';

  @override
  String get updateExistingContact => 'Actualizar contacto existente';

  @override
  String get customLabel => 'Etiqueta personalizada';

  @override
  String get noContactsToExport => 'No hay contactos para exportar';

  @override
  String get couldNotOpenFile => 'No se pudo abrir el archivo';

  @override
  String get noContactsInFile => 'No hay contactos en este archivo';

  @override
  String importContactsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Importar $count contactos?',
      one: '¿Importar 1 contacto?',
    );
    return '$_temp0';
  }

  @override
  String importContactsMessage(String account) {
    return 'Se guardarán en $account.';
  }

  @override
  String contactsImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contactos importados',
      one: 'Contacto importado',
    );
    return '$_temp0';
  }

  @override
  String get couldNotImportContacts =>
      'No se pudieron importar estos contactos';

  @override
  String get display => 'Pantalla';

  @override
  String get showContactPhotos => 'Mostrar la foto de perfil del contacto';

  @override
  String get onlyContactsWithNumbers => 'Mostrar solo contactos con número';

  @override
  String get contactsToDisplay => 'Contactos que mostrar';

  @override
  String get sortBy => 'Ordenar por';

  @override
  String get firstName => 'Nombre';

  @override
  String get lastName => 'Apellido';

  @override
  String get nameFormat => 'Formato del nombre';

  @override
  String get firstNameFirst => 'Nombre primero';

  @override
  String get lastNameFirst => 'Apellido primero';

  @override
  String get defaultSaveLocation => 'Ubicación de guardado predeterminada';

  @override
  String get phoneDefault => 'Predeterminado del teléfono';

  @override
  String get importContacts => 'Importar contactos';

  @override
  String get fromVcf => 'Desde un archivo .vcf';

  @override
  String get exportContacts => 'Exportar contactos';

  @override
  String get asVcf => 'Como archivo .vcf';

  @override
  String get simContacts => 'Contactos de la tarjeta SIM';

  @override
  String get mergeDuplicates => 'Combinar contactos duplicados';

  @override
  String get simReadError => 'No se pudo leer la tarjeta SIM';

  @override
  String get simReading => 'Leyendo la tarjeta SIM…';

  @override
  String get simEmpty => 'No hay contactos en la tarjeta SIM';

  @override
  String get allSavedInContacts => 'Todos guardados en Contactos';

  @override
  String importToContacts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importar $count a Contactos',
    );
    return '$_temp0';
  }

  @override
  String mergeGroupTitle(String count) {
    return '¿Combinar $count contactos?';
  }

  @override
  String mergeGroupMessage(String name) {
    return 'Se convierten en un contacto llamado $name, con todos sus números y datos.';
  }

  @override
  String contactsMerged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contactos combinados',
      one: 'Contactos combinados',
    );
    return '$_temp0';
  }

  @override
  String get couldNotMergeContacts => 'No se pudieron combinar estos contactos';

  @override
  String get noDuplicateContacts => 'No hay contactos duplicados';

  @override
  String get recentSearches => 'Búsquedas recientes';

  @override
  String get clearAll => 'Borrar todo';

  @override
  String get noResultsFound => 'No se encontraron resultados';

  @override
  String foundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count encontrados',
      one: '1 encontrado',
    );
    return '$_temp0';
  }

  @override
  String removeItem(String item) {
    return 'Quitar $item';
  }

  @override
  String get done => 'Listo';

  @override
  String get discard => 'Descartar';

  @override
  String get change => 'Cambiar';

  @override
  String get contactReadOnly =>
      'La cuenta de este contacto es de solo lectura, así que no se puede cambiar aquí';

  @override
  String get couldNotSaveContact => 'No se pudo guardar el contacto';

  @override
  String alreadySavedAs(String number, String name) {
    return '$number ya está guardado como $name.';
  }

  @override
  String alreadyInContacts(String name) {
    return '$name ya está en tus contactos.';
  }

  @override
  String get alreadyInContactsTitle => 'Ya está en contactos';

  @override
  String saveAnotherAnyway(String duplicate) {
    return '$duplicate ¿Guardar otro contacto de todos modos?';
  }

  @override
  String get saveAnyway => 'Guardar igualmente';

  @override
  String get saveOrDiscard => '¿Guardar los cambios?';

  @override
  String get couldNotLoadContactRetry =>
      'No se pudo cargar el contacto. Reintentar';

  @override
  String get email => 'Correo';

  @override
  String get addEmail => 'Añadir correo';

  @override
  String get addWebsite => 'Añadir sitio web';

  @override
  String get relationships => 'Relaciones';

  @override
  String get addRelationship => 'Añadir relación';

  @override
  String get showLess => 'Mostrar menos';

  @override
  String get showMore => 'Mostrar más';

  @override
  String get newContact => 'Nuevo contacto';

  @override
  String get addToExistingContact => 'Añadir a un contacto';

  @override
  String get editContact => 'Editar contacto';

  @override
  String get couldNotLoadAccounts => 'No se pudieron cargar las cuentas';

  @override
  String get loadingAccounts => 'Cargando cuentas…';

  @override
  String saveToAccount(String account) {
    return 'Guardar en $account';
  }

  @override
  String get profilePicture => 'Foto de perfil';

  @override
  String get camera => 'Cámara';

  @override
  String get selectPhotos => 'Seleccionar fotos';

  @override
  String get deleteProfilePicture => 'Eliminar foto de perfil';

  @override
  String get couldNotOpenCamera => 'No se pudo abrir la cámara';

  @override
  String get couldNotOpenApp => 'No se pudo abrir la app';

  @override
  String get followSystem => 'Seguir el sistema';

  @override
  String get customRingtone => 'Tono personalizado';

  @override
  String get fromFollowingAccount => 'De la siguiente cuenta';

  @override
  String get fewerNameFields => 'Menos campos de nombre';

  @override
  String get moreNameFields => 'Más campos de nombre';

  @override
  String get namePrefix => 'Prefijo';

  @override
  String get middleName => 'Segundo nombre';

  @override
  String get nameSuffix => 'Sufijo';

  @override
  String get name => 'Nombre';

  @override
  String get number => 'Número';

  @override
  String get workInfo => 'Trabajo';

  @override
  String get company => 'Empresa';

  @override
  String get jobTitle => 'Cargo';

  @override
  String get department => 'Departamento';

  @override
  String get address => 'Dirección';

  @override
  String get street => 'Calle';

  @override
  String get city => 'Ciudad';

  @override
  String get stateProvince => 'Provincia/Estado';

  @override
  String get postalCode => 'Código postal';

  @override
  String get country => 'País';

  @override
  String get addAddress => 'Añadir dirección';

  @override
  String get importantDate => 'Fecha importante';

  @override
  String get importantDates => 'Fechas importantes';

  @override
  String get addImportantDate => 'Añadir fecha importante';

  @override
  String get noGroupsInAccount => 'No hay grupos en esta cuenta';

  @override
  String get groups => 'Grupos';

  @override
  String get enterNumber => 'Introduce un número';

  @override
  String get chooseFromContacts => 'Elegir de los contactos';

  @override
  String get blockingNeedsScreeningRole =>
      'Configura Dialer como app de identificación de llamadas y spam para bloquear estas llamadas';

  @override
  String get phoneNumber => 'Número de teléfono';

  @override
  String get blockAndFilter => 'Bloquear y filtrar';

  @override
  String get blockingPaused => 'Las reglas de bloqueo están en pausa';

  @override
  String get blockingPausedSubtitle =>
      'Otra app filtra tus llamadas. Toca para que las filtre Dialer.';

  @override
  String get blockUnknown => 'Bloquear números desconocidos/privados';

  @override
  String get blockUnknownSubtitle => 'Quien oculta su número';

  @override
  String get blockNonContacts =>
      'Bloquear llamadas de números que no están en Contactos';

  @override
  String get blockNonContactsSubtitle => 'Solo tus contactos pueden llamarte';

  @override
  String get blockedNumbers => 'Números bloqueados';

  @override
  String get blockedCalls => 'Llamadas bloqueadas';

  @override
  String get addCall => 'Añadir';

  @override
  String get note => 'Nota';

  @override
  String get editNote => 'Editar nota';

  @override
  String get videoCall => 'Videollamada (Meet)';

  @override
  String get switchToVideoCall => 'Cambiar a videollamada';

  @override
  String get carrierVideo => 'Videollamada del operador';

  @override
  String get cameraNeeded => 'Permite la cámara para hacer videollamadas';

  @override
  String get answerAsVoice => 'Responder como llamada de voz';

  @override
  String get videoRequest => '¿Cambiar a videollamada?';

  @override
  String get accept => 'Aceptar';

  @override
  String get switchToVoice => 'Cambiar a llamada de voz';

  @override
  String get cameraOff => 'Apagar cámara';

  @override
  String get cameraOn => 'Encender cámara';

  @override
  String get flipCamera => 'Girar cámara';

  @override
  String get incomingVideo => 'Videollamada';

  @override
  String get incomingVideoCall => 'Videollamada entrante';

  @override
  String get videoUnavailable => 'Las videollamadas no están disponibles';

  @override
  String get networkUnreachable => 'No se pudo conectar con la red';

  @override
  String get networkBusy => 'La red está ocupada';

  @override
  String get noService => 'Sin servicio';

  @override
  String get voiceCall => 'Llamada de voz';

  @override
  String get mute => 'Silenciar';

  @override
  String get hold => 'Retener';

  @override
  String get resume => 'Reanudar';

  @override
  String get headset => 'Auriculares';

  @override
  String get speaker => 'Altavoz';

  @override
  String get audioPhone => 'Teléfono';

  @override
  String get wiredHeadset => 'Auriculares con cable';

  @override
  String get endCall => 'Finalizar llamada';

  @override
  String get end => 'Finalizar';

  @override
  String get dialPad => 'Teclado';

  @override
  String get callNote => 'Nota de llamada';

  @override
  String get callNoteHint =>
      'Escribe algo que quieras recordar de esta llamada';

  @override
  String get conferenceCall => 'Llamada de conferencia';

  @override
  String get unknown => 'Desconocido';

  @override
  String get lineBusy => 'Línea ocupada';

  @override
  String get callDeclined => 'Llamada rechazada';

  @override
  String get callCancelled => 'Llamada cancelada';

  @override
  String get callFailed => 'Error en la llamada';

  @override
  String get callEnded => 'Llamada finalizada';

  @override
  String get connected => 'Conectada';

  @override
  String get calling => 'Llamando';

  @override
  String get onHold => 'En espera';

  @override
  String get phoneCall => 'Llamada telefónica';

  @override
  String get hdCall => 'Llamada HD';

  @override
  String switchToOnHold(String name) {
    return 'Cambiar a $name, en espera';
  }

  @override
  String get switchCall => 'Cambiar';

  @override
  String get declineWithSms => 'Responder por SMS';

  @override
  String get answer => 'Responder';

  @override
  String get decline => 'Rechazar';

  @override
  String get answerVerb => 'responder';

  @override
  String get declineVerb => 'rechazar';

  @override
  String swipeUpDownHint(String up, String down) {
    return 'Desliza hacia arriba para $up y hacia abajo para $down';
  }

  @override
  String swipeUpHint(String action) {
    return 'Desliza hacia arriba para $action';
  }

  @override
  String get effectsFull => 'Todos los efectos';

  @override
  String get effectsReduced => 'Efectos reducidos';

  @override
  String get effectsOff => 'Sin efectos';

  @override
  String get off => 'Desactivado';

  @override
  String get always => 'Siempre';

  @override
  String get onlyWithHeadphones => 'Solo con auriculares';

  @override
  String get incomingCallReminders => 'Llamadas entrantes';

  @override
  String get incomingFootnote =>
      'Solo se aplica a las llamadas entrantes recibidas con el dispositivo desbloqueado.';

  @override
  String get banner => 'Banner';

  @override
  String get fullScreen => 'Pantalla completa';

  @override
  String get announceCalls => 'Anunciar llamadas entrantes';

  @override
  String get announceCallsSubtitle =>
      'Dice el nombre de quien llama mientras suena';

  @override
  String get flashOnCall => 'Notificación con flash';

  @override
  String get flashOnCallSubtitle =>
      'El flash de la cámara parpadea mientras suena una llamada';

  @override
  String get systemFlash =>
      'Tu teléfono tiene su propia notificación con flash';

  @override
  String get systemFlashSubtitle =>
      'Desactiva una de las dos o parpadearán ambas. Está en Ajustes, en Notificaciones o Accesibilidad';

  @override
  String get swipeUpToAnswer => 'Desliza hacia arriba para responder';

  @override
  String get swipeDownToAnswer => 'Desliza hacia abajo para responder';

  @override
  String get answerButtons => 'Pantalla de llamada';

  @override
  String get twoButtons => '2 botones';

  @override
  String get oneButton => '1 botón';

  @override
  String get answerCall => 'Responder llamada';

  @override
  String get callScreenEffects => 'Efectos de la pantalla de llamada';

  @override
  String get callScreenEffectsSubtitle =>
      'Cristal y brillo en la pantalla de llamada';

  @override
  String get callScreenAnimations => 'Animaciones de la pantalla de llamada';

  @override
  String get callScreenAnimationsSubtitle =>
      'Movimiento al abrir, responder y cambiar la pantalla de llamada';

  @override
  String get hideContactNumbers => 'Ocultar números de los contactos';

  @override
  String get hideContactNumbersSubtitle =>
      'Mostrar solo el nombre de los contactos guardados en la pantalla de llamada y en Llamadas';

  @override
  String get callerPhoto => 'Foto de quien llama';

  @override
  String get callerPhotoSubtitle =>
      'Dónde va la foto de un contacto en la pantalla de llamada';

  @override
  String get callerPhotoSide => 'Junto al nombre';

  @override
  String get callerPhotoStacked => 'Sobre el nombre';

  @override
  String secondsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count segundos',
      one: '1 segundo',
    );
    return '$_temp0';
  }

  @override
  String get answerEndCalls => 'Responder y finalizar llamadas';

  @override
  String get vibrateAnswerEnd => 'Vibrar al responder/finalizar las llamadas';

  @override
  String get autoAnswer =>
      'Responder automáticamente con un dispositivo de audio externo conectado';

  @override
  String get autoAnswerSubtitle => 'Incluye auriculares Bluetooth y con cable';

  @override
  String get autoAnswerDelay => 'Retraso de respuesta automática';

  @override
  String get replyWithSms => 'Responder con SMS';

  @override
  String get speakerDefault => 'Llamadas con altavoz por defecto';

  @override
  String get speakerDefaultSubtitle =>
      'No se aplica si hay dispositivos externos conectados.';

  @override
  String get quickDeclineMessage => 'Mensaje de rechazo rápido';

  @override
  String get quickDeclineMessages => 'Mensajes de rechazo rápido';

  @override
  String get quickDeclineHint =>
      'Se envía al rechazar una llamada con un mensaje';

  @override
  String get addMessage => 'Añadir mensaje';

  @override
  String get settingNotAvailable => 'Este teléfono no tiene ese ajuste';

  @override
  String get notDefaultApp => 'No es tu app de teléfono predeterminada';

  @override
  String get notDefaultAppSubtitle => 'Las llamadas entrantes usan otra app';

  @override
  String get notificationsOff => 'Las notificaciones están desactivadas';

  @override
  String get notificationsOffSubtitle =>
      'No verás llamadas entrantes ni perdidas';

  @override
  String get fullScreenOff =>
      'Las llamadas a pantalla completa están desactivadas';

  @override
  String get fullScreenOffSubtitle =>
      'Las llamadas entrantes solo aparecen como notificación';

  @override
  String get blockingPausedShort => 'Otra app filtra tus llamadas';

  @override
  String get bluetoothNamesHidden => 'Nombres Bluetooth ocultos';

  @override
  String get bluetoothNamesHiddenSubtitle =>
      'Las llamadas no distinguen tu reloj de tus auriculares';

  @override
  String get fix => 'Arreglar';

  @override
  String get callSettings => 'Ajustes de llamadas';

  @override
  String get needsAttention => 'Requiere atención';

  @override
  String get callerIdentification => 'Identificación de llamadas';

  @override
  String get callerIdSpamApp => 'App de identificación y spam';

  @override
  String get carrierSettings => 'Ajustes del operador';

  @override
  String get softwareUpdate => 'Actualización de software';

  @override
  String get supportOneDialer => 'Apoyar One Dialer';

  @override
  String get supportIntro =>
      'One Dialer es gratis, sin anuncios ni rastreo, y seguirá así. Si te resulta útil y quieres ayudar a que siga adelante, puedes dejar una propina única. Las propinas no desbloquean nada.';

  @override
  String get leaveATip => 'Dejar una propina';

  @override
  String get tipSmall => 'Propina pequeña';

  @override
  String get tipMedium => 'Propina mediana';

  @override
  String get tipLarge => 'Propina grande';

  @override
  String get tipsLoading => 'Cargando…';

  @override
  String get tipsUnavailable =>
      'Las propinas no están disponibles ahora. Se necesita Google Play para dejar una.';

  @override
  String get tipThanks => '¡Gracias por apoyar One Dialer!';

  @override
  String get tipPending =>
      'Tu propina está pendiente. Se completará cuando se confirme el pago.';

  @override
  String get tipFailed =>
      'La propina no se completó. No se te ha cobrado nada.';

  @override
  String get helpFeedback => 'Ayuda y comentarios';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get aboutOneDialer => 'Acerca de One Dialer';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get openDetails => 'Abrir detalles';

  @override
  String get writeInKeypad => 'Escribir en el teclado';

  @override
  String get tapRecentCall => 'Tocar una llamada reciente';

  @override
  String get chooseSimForCalls => 'Con qué SIM llamar';

  @override
  String get appearance => 'Aspecto';

  @override
  String get reduceVisualEffects => 'Reducir efectos visuales';

  @override
  String get displaySize => 'Tamaño de pantalla';

  @override
  String get displaySizeSmall => 'Pequeño';

  @override
  String get displaySizeDefault => 'Predeterminado';

  @override
  String get displaySizeLarge => 'Grande';

  @override
  String get displaySizeLarger => 'Más grande';

  @override
  String get displaySizeApp => 'App';

  @override
  String get displaySizeNavBar => 'Barra de navegación';

  @override
  String get reduceVisualEffectsSubtitle =>
      'Menos desenfoque va más fluido en teléfonos lentos';

  @override
  String get callScreenEdgeGlow => 'Brillo de bordes en la llamada';

  @override
  String get darkModeEdgeGlow => 'Intensidad del brillo';

  @override
  String get edgeGlowClassic => 'Clásico';

  @override
  String get edgeGlowSoft => 'Suave';

  @override
  String get edgeGlowBold => 'Intenso';

  @override
  String get glassStyle => 'Estilo de cristal';

  @override
  String get navBarFrosted => 'Brillo de bordes';

  @override
  String get navBarLiquid => 'Cristal líquido';

  @override
  String get navBarGlass => 'Efecto cristal';

  @override
  String get navGlassPremium => 'Refracción completa';

  @override
  String get navGlassStandard => 'Ligero';

  @override
  String get navGlassAuto => 'Automático';

  @override
  String get glassSettings => 'Cristal y desenfoque';

  @override
  String get splashIcon => 'Icono de la app al iniciar';

  @override
  String get splashIconSubtitle =>
      'Desactívalo para una pantalla de inicio vacía si tu pantalla principal usa otro icono';

  @override
  String get liquidGlassOn => 'Cristal líquido en';

  @override
  String get liquidScopeAll => 'Todo';

  @override
  String get liquidScopeControls => 'Barra y botones';

  @override
  String get liquidScopeNavbar => 'Solo la barra de navegación';

  @override
  String get glassExperimentalNote =>
      'El cristal líquido es experimental y el estilo más pesado: necesita aún más potencia gráfica que Brillo de bordes, que ya es exigente. Si el desplazamiento va a tirones, prueba Solo la barra de navegación o Efecto cristal › Automático, o vuelve a Brillo de bordes. En teléfonos lentos, Pantalla y efectos › Reducir efectos visuales es lo más fluido.';

  @override
  String get callsFromOtherApps => 'Llamadas de otras apps';

  @override
  String get callsFromOtherAppsSubtitle =>
      'Mostrar llamadas de WhatsApp y otras apps en Recientes';

  @override
  String get manageContactsSubtitle =>
      'Pantalla, ubicación de guardado, importar y exportar, SIM, duplicados';

  @override
  String get googleContactsSync => 'Sincronización de Google Contactos';

  @override
  String get googleContactsSyncSubtitle =>
      'Qué cuentas se sincronizan y copia de los contactos del teléfono';

  @override
  String get defaultApps => 'Apps predeterminadas';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get setupTitle =>
      'Configura One Dialer como app de teléfono predeterminada';

  @override
  String get setupBody =>
      'Es necesario para hacer y responder llamadas, mostrar tu historial de llamadas y tus contactos, y bloquear números.';

  @override
  String get settingUp => 'Configurando…';

  @override
  String get setupDisclosure =>
      'One Dialer usa Teléfono para hacer y gestionar llamadas en tus SIM, Registro de llamadas para Recientes y llamadas perdidas, Contactos para nombres, fotos y búsqueda, y Notificaciones para llamadas entrantes, en curso y perdidas. Tus llamadas, tu historial de llamadas y tus contactos nunca salen de tu teléfono. Los informes de fallos (sin datos personales) ayudan a corregir errores.';

  @override
  String get installedDirectly => 'Instalada directamente';

  @override
  String get anotherAppStore => 'Otra tienda de apps';

  @override
  String aboutApp(String app) {
    return 'Acerca de $app';
  }

  @override
  String get updateAvailable => 'Actualización disponible';

  @override
  String get versionUpToDate => 'Versión actualizada';

  @override
  String get checkForUpdates => 'Buscar actualizaciones';

  @override
  String get checking => 'Comprobando…';

  @override
  String get version => 'Versión';

  @override
  String get build => 'Compilación';

  @override
  String get installedFrom => 'Instalada desde';

  @override
  String get device => 'Dispositivo';

  @override
  String get androidVersion => 'Versión de Android';

  @override
  String get openSourceLicences => 'Licencias de código abierto';

  @override
  String get copyrightNotice =>
      'Copyright (C) 2026 Syed Arham Raza\nSoftware libre bajo la GNU General Public License v3.0, sin garantía';

  @override
  String get changelog => 'Novedades';

  @override
  String installedOn(String date) {
    return 'Instalada el $date';
  }

  @override
  String get earlierVersions => 'Versiones anteriores';

  @override
  String get aboutThisUpdate => 'Acerca de esta actualización';

  @override
  String get reportLag => 'Informar de lentitud';

  @override
  String get reportLagMessage =>
      'Envía tiempos de rendimiento recientes, nombres de pantallas y acciones, y datos del dispositivo para encontrar ralentizaciones. No se incluyen números de teléfono, contactos ni mensajes.';

  @override
  String get sendReport => 'Enviar informe';

  @override
  String get reportUnavailable =>
      'Los informes no están disponibles o se acaban de pedir. Inténtalo de nuevo en un minuto.';

  @override
  String get reportQueued => 'Informe en cola';

  @override
  String reportQueuedMessage(String id) {
    return 'Tu informe se ha guardado y se subirá cuando sea posible. Comparte este ID con tus comentarios:\\n\\n$id';
  }

  @override
  String get copy => 'Copiar';

  @override
  String get paste => 'Pegar';

  @override
  String get copyId => 'Copiar ID';

  @override
  String get reportIdCopied => 'ID del informe copiado';

  @override
  String get editSpeedDial => 'Editar marcación rápida';

  @override
  String get clearNumber => 'Borrar número';

  @override
  String get changeNumber => 'Cambiar número';

  @override
  String get numberCopied => 'Número copiado';

  @override
  String get noEmailApp => 'No hay app de correo';

  @override
  String get noBrowser => 'No hay navegador';

  @override
  String get sendFeedback => 'Enviar comentarios';

  @override
  String get feedbackTypeTitle => '¿De qué se trata?';

  @override
  String get feedbackBug => 'Informar de un problema';

  @override
  String get feedbackIdea => 'Sugerir una idea';

  @override
  String get feedbackQuestion => 'Hacer una pregunta';

  @override
  String get developer => 'Desarrollador';

  @override
  String get downloadStopped =>
      'La descarga se detuvo. Inténtalo de nuevo cuando tengas conexión.';

  @override
  String get couldNotInstallUpdate =>
      'No se pudo instalar la actualización. Inténtalo de nuevo.';

  @override
  String get updateCancelled =>
      'Actualización cancelada. Puedes descargarla cuando quieras desde aquí.';

  @override
  String get noInternet =>
      'Sin conexión a internet. Conéctate e inténtalo de nuevo.';

  @override
  String get couldNotDownloadUpdate =>
      'No se pudo descargar la actualización. Inténtalo de nuevo.';

  @override
  String get softwareInformation => 'Información de software';

  @override
  String get autoDownload => 'Descarga automática';

  @override
  String get downloadAndInstall => 'Descargar e instalar';

  @override
  String get installAndRestart => 'Instalar y reiniciar';

  @override
  String get tryAgain => 'Reintentar';

  @override
  String get downloading => 'Descargando…';

  @override
  String get noNetwork => 'Sin conexión de red';

  @override
  String get notFromPlay =>
      'Las actualizaciones llegan por Google Play. Esta copia no se instaló desde Play.';

  @override
  String get notFromPlayTitle => 'No es de Google Play';

  @override
  String get notFromPlayWarning =>
      'Esta copia no se instaló desde Google Play, así que no recibirá actualizaciones y puede haber sido modificada. Puedes seguir usándola u obtener la versión oficial desde la beta.';

  @override
  String get keepUsing => 'Seguir usándola';

  @override
  String get getOfficialVersion => 'Versión oficial';

  @override
  String get couldNotReachPlay => 'No se pudo conectar con Google Play';

  @override
  String get softwareVersion => 'Versión de software';

  @override
  String get closedBeta => 'Beta cerrada';

  @override
  String get newVersionAvailable => 'Hay una nueva versión disponible';

  @override
  String get autoDownloadExplainer =>
      'Cuándo One Dialer busca actualizaciones en Google Play al abrirla. Las actualizaciones solo se instalan cuando tocas Descargar e instalar.';

  @override
  String get autoUpdateNeverSubtitle =>
      'Solo cuando tocas Buscar actualizaciones';

  @override
  String get autoUpdateAlwaysSubtitle => 'La comprobación usa muy pocos datos';

  @override
  String get autoUpdateNever => 'Nunca';

  @override
  String get autoUpdateWifiOnly => 'Solo con Wi-Fi';

  @override
  String get autoUpdateAlways => 'Con Wi-Fi o datos móviles';

  @override
  String get displayAndEffects => 'Pantalla y efectos';

  @override
  String get keypadAndRecents => 'Teclado y recientes';

  @override
  String get logIncoming => 'Entrante';

  @override
  String get logOutgoing => 'Saliente';

  @override
  String get logMissed => 'Perdida';

  @override
  String get logRejected => 'Rechazada';

  @override
  String get logBlocked => 'Bloqueada';

  @override
  String logRangFor(String type, String duration) {
    return '$type (sonó $duration)';
  }

  @override
  String get record => 'Grabar';

  @override
  String get stopRecording => 'Detener grabación';

  @override
  String get recordSetUpFirst => 'Grabar (configurar en Ajustes)';

  @override
  String get recordingNow => 'Grabando';

  @override
  String get callRecording => 'Grabación de llamadas';

  @override
  String get recorderApp => 'One Recorder';

  @override
  String get recorderBothSides => 'Graba las dos partes de tus llamadas';

  @override
  String get recorderNeedsSetup => 'Configura las dos partes en One Recorder';

  @override
  String get recorderHelperStopped =>
      'Las dos partes está en pausa: inicia el servicio en One Recorder';

  @override
  String get recorderUntrusted =>
      'La grabadora solo funciona con One Dialer de Google Play. Instálala desde Play o actualiza las dos apps.';

  @override
  String get recordingConsentTitle => 'Antes de grabar';

  @override
  String get recordingConsentBody =>
      'Las leyes sobre grabación cambian según el país y algunas exigen que todos los participantes estén de acuerdo. Eres responsable de avisar a la otra persona y obtener su consentimiento. Las grabaciones se quedan en este teléfono y nunca se suben.';

  @override
  String get recordingConsentAccept => 'Entendido';

  @override
  String get recordings => 'Grabaciones';

  @override
  String get noRecordings => 'Aún no hay grabaciones';

  @override
  String get noRecordingsSubtitle =>
      'Toca ⋮ › Grabar en la pantalla de llamada durante una llamada';

  @override
  String get deleteAllRecordings => 'Eliminar todas las grabaciones';

  @override
  String get deleteAllRecordingsTitle => '¿Eliminar todas las grabaciones?';

  @override
  String get deleteAllRecordingsMessage => 'No se podrán recuperar.';

  @override
  String get recordingNotSetUp => 'No se están grabando las llamadas';

  @override
  String get recordingNotSetUpSubtitle =>
      'La grabación automática está activada, pero One Recorder no está configurada';

  @override
  String get rename => 'Renombrar';

  @override
  String get star => 'Destacar';

  @override
  String get unstar => 'Quitar destacado';

  @override
  String get filterStarred => 'Destacadas';

  @override
  String get filterUnknown => 'Desconocidos';

  @override
  String get saveToPhone => 'Guardar en el teléfono';

  @override
  String get searchRecordings => 'Buscar grabaciones';

  @override
  String get renameRecording => 'Renombrar grabación';

  @override
  String recordingsSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count grabaciones guardadas en Recordings/One Dialer',
      one: 'Guardada en Recordings/One Dialer',
    );
    return '$_temp0';
  }

  @override
  String get recordingSaveFailed => 'No se pudo guardar en el teléfono';

  @override
  String deleteRecordings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Eliminar $count grabaciones?',
      one: '¿Eliminar esta grabación?',
    );
    return '$_temp0';
  }

  @override
  String get noMatchingRecordings => 'No hay grabaciones que coincidan';

  @override
  String get addContact => 'Añadir contacto';

  @override
  String get autoRecord => 'Grabación automática';

  @override
  String get autoRecordOff => 'Desactivada';

  @override
  String get autoRecordAll => 'Todas las llamadas';

  @override
  String get autoRecordUnknown => 'Números desconocidos';

  @override
  String get autoRecordContacts => 'Contactos seleccionados';

  @override
  String get recordTheseContacts => 'Contactos que grabar';

  @override
  String get neverRecord => 'No grabar nunca';

  @override
  String get neverRecordSubtitle =>
      'Contactos que la grabación automática siempre omite';

  @override
  String get storage => 'Almacenamiento';

  @override
  String get storageUsed => 'Espacio usado';

  @override
  String get autoDelete => 'Eliminación automática';

  @override
  String get autoDeleteSubtitle =>
      'Las grabaciones destacadas se conservan siempre';

  @override
  String get autoDeleteNever => 'Nunca';

  @override
  String autoDeleteDays(int days) {
    return 'Después de $days días';
  }

  @override
  String get imeiTitle => 'IMEI';

  @override
  String get imeiUnavailable =>
      'Android no deja que las apps muestren el IMEI. Lo encontrarás en los ajustes del teléfono, en Información del teléfono.';

  @override
  String get aboutPhone => 'Información del teléfono';

  @override
  String get glassStyleSubtitle =>
      'El cristal líquido curva lo que hay detrás, pero consume más batería';

  @override
  String get darkModeEdgeGlowSubtitle =>
      'Cuánto brillan los bordes del cristal en modo oscuro';

  @override
  String get liquidGlassOnSubtitle =>
      'Qué partes de la app usan cristal líquido';

  @override
  String get navBarGlassSubtitle =>
      'Refracción completa se ve mejor; Ligero va más fluido en teléfonos lentos';

  @override
  String get tapRecentCallSubtitle =>
      'Qué pasa al tocar una llamada en Llamadas';

  @override
  String get callScreenEdgeGlowSubtitle =>
      'Cuánto brillan los bordes de cristal de los botones de llamada';

  @override
  String get answerButtonsSubtitle =>
      'Cómo respondes, efectos, foto de quien llama y fondo';

  @override
  String get incomingCallsSubtitle =>
      'Estilo de llamada, anunciar, flash, Live Update';

  @override
  String get answerEndCallsSubtitle =>
      'Respuesta automática, responder con SMS, altavoz';

  @override
  String get sectionCalls => 'Llamadas';

  @override
  String get sectionMakingCalls => 'Hacer llamadas';

  @override
  String get sectionBlocking => 'Bloqueo e identificación';

  @override
  String get sectionDisplay => 'Pantalla';

  @override
  String get sectionSystem => 'Contactos y sistema';

  @override
  String get searchSettings => 'Buscar en ajustes';

  @override
  String get carrierSettingsSubtitle =>
      'Desvío de llamadas, llamada en espera e identificación de llamada';

  @override
  String get callBackground => 'Fondo de llamada';

  @override
  String get callBackgroundAllSubtitle =>
      'Para todas las llamadas, salvo que un contacto tenga el suyo';

  @override
  String get callBackgroundDefault => 'Predeterminado';

  @override
  String get callBackgroundColour => 'Color';

  @override
  String get callBackgroundPhoto => 'Foto';

  @override
  String get callBackgroundAurora => 'Aurora';

  @override
  String get callBackgroundAuto => 'Auto';

  @override
  String get callBackgroundAutoNote =>
      'Auto: cada persona tiene sus propios colores, a partir de su foto de contacto o su nombre.';

  @override
  String get callBackgroundColourNote => 'Todas las llamadas usan este color.';

  @override
  String get callBackgroundChangePhoto => 'Cambiar foto';

  @override
  String get callBackgroundPhotoBackupNote =>
      'Las fotos solo se guardan en este teléfono. Para conservarlas al reinstalar One Dialer o en un teléfono nuevo,';

  @override
  String get callBackgroundPhotoBackupLink => 'haz una copia de tus ajustes';

  @override
  String get callBackgroundSoft => 'Desenfocar y oscurecer';

  @override
  String get callBackgroundSoftSubtitle =>
      'Suaviza la foto detrás de la llamada';

  @override
  String get callBackgroundContactPhoto => 'Foto del contacto';

  @override
  String get callBackgroundContactPhotoSubtitle =>
      'Android guarda las fotos de contacto pequeñas; elige una foto para que se vea más nítida';

  @override
  String get callBackgroundSameAsAll => 'Igual que todas las llamadas';

  @override
  String get callBackgroundAllNote =>
      'Un contacto con su propio fondo de llamada, elegido en su página, usa ese.';

  @override
  String get callBackgroundContactNote =>
      'Se usa para este contacto en lugar del fondo de todas las llamadas.';

  @override
  String get backUpRestore => 'Copia de seguridad y restauración';

  @override
  String get backUpRestoreSubtitle =>
      'Ajustes, notas y fondos de llamada, en un archivo en este teléfono';

  @override
  String get backUpNow => 'Hacer copia ahora';

  @override
  String lastBackup(String time) {
    return 'Última copia: $time';
  }

  @override
  String get backupNever => 'Aún sin copia';

  @override
  String get restoreBackup => 'Restaurar';

  @override
  String get restoreBackupSubtitle =>
      'Elige un archivo de copia; la app de archivos se abre en Documentos';

  @override
  String get autoBackup => 'Copia automática';

  @override
  String get backupFrequency => 'Frecuencia';

  @override
  String get backupEveryDay => 'Cada día';

  @override
  String get backupEvery3Days => 'Cada 3 días';

  @override
  String get backupEveryWeek => 'Cada semana';

  @override
  String get backupEveryMonth => 'Cada mes';

  @override
  String get backupLocation => 'Ubicación';

  @override
  String get backupLocationNone =>
      'Elige una carpeta; Documentos es un buen sitio';

  @override
  String get backupFailed =>
      'La última copia falló. Toca Ubicación para volver a elegir la carpeta.';

  @override
  String get backupFootnote =>
      'Una copia guarda tus ajustes, marcación rápida, notas de llamada y fondos de llamada con sus fotos. Es un solo archivo que cada copia reemplaza, así que nunca llena tu almacenamiento. La copia automática se hace al abrir One Dialer o al terminar una llamada.';

  @override
  String get backedUp => 'Copia hecha';

  @override
  String get couldNotBackUp => 'No se pudo hacer la copia en esa carpeta';

  @override
  String get importSettingsTitle => '¿Reemplazar tus ajustes?';

  @override
  String get importSettingsMessage =>
      'Tus ajustes, marcación rápida, notas de llamada y fondos de llamada se reemplazan por los del archivo. Después One Dialer se reinicia.';

  @override
  String get importSettingsInCall =>
      'No se pueden importar ajustes durante una llamada';

  @override
  String get notASettingsFile =>
      'Este no es un archivo de ajustes de One Dialer';

  @override
  String endHeldCall(String name) {
    return 'Finalizar llamada con $name';
  }

  @override
  String get fullScreenAsk =>
      'Las llamadas entrantes solo aparecen en el panel de notificaciones. En la página siguiente, activa las notificaciones a pantalla completa para One Dialer. Si ya parece activado, desactívalo y vuelve a activarlo.';

  @override
  String get notNow => 'Ahora no';

  @override
  String get vipCalls => 'Llamadas VIP';

  @override
  String get vipCallsSubtitle => 'Suenan incluso en Silencio o Vibración';

  @override
  String get vipRing => 'Sonar en Silencio para VIP';

  @override
  String get vipRingSubtitle =>
      'Las llamadas de tus VIP suenan aunque el teléfono esté en Silencio o Vibración, y luego vuelve como estaba';

  @override
  String get vipFavourites => 'Incluir favoritos';

  @override
  String get vipFavouritesSubtitle =>
      'Tus contactos destacados cuentan como VIP';

  @override
  String get vipContacts => 'Contactos VIP';

  @override
  String get vipNeedsAccess => 'Las llamadas VIP no pueden sonar en Silencio';

  @override
  String get vipNeedsAccessSubtitle =>
      'Permite el filtrado de llamadas y el acceso a No molestar';

  @override
  String get vipDndHint =>
      'Con No molestar activado, Android decide quién suena: permite los contactos destacados en sus ajustes de No molestar.';

  @override
  String get rowCallButton => 'Botón de llamada en las filas';

  @override
  String get rowCallButtonSubtitle =>
      'Un botón de llamada en cada fila de Llamadas';

  @override
  String get swipeToCall => 'Deslizar para llamar o escribir';

  @override
  String get swipeToCallSubtitle =>
      'Desliza una fila a la derecha para llamar y a la izquierda para escribir';

  @override
  String get clearDefault => 'Quitar predeterminado';

  @override
  String get swipeStyle => 'Estilo al deslizar';

  @override
  String get swipeStylePill => 'Botón de cristal';

  @override
  String get swipeStyleFlat => 'Plano';

  @override
  String get quickCalling => 'Llamada rápida';

  @override
  String get quickCallingSubtitle =>
      'Tocar, botón de llamada y deslizar en las filas';

  @override
  String get useRecentSim => 'Usar la SIM reciente';

  @override
  String get simSameAsPhone => 'Igual que el teléfono';

  @override
  String alwaysSim(Object sim) {
    return 'Siempre $sim';
  }

  @override
  String get keypadSimButtons => 'Dos botones de llamada';

  @override
  String get keypadSimButtonsSubtitle =>
      'Uno por cada SIM, en lugar de un solo botón de llamada';

  @override
  String get keypadSimButtonsOneSim => 'Solo en teléfonos con dos SIM';

  @override
  String get keypadSettings => 'Teclado';

  @override
  String get keypadSettingsSubtitle =>
      'Dos botones de llamada, marcación rápida';

  @override
  String get phoneDefaultSim => 'SIM predeterminada del teléfono';

  @override
  String get simRulesHint =>
      'La SIM propia de un contacto, elegida en su página, siempre tiene prioridad.';

  @override
  String get callButtonStyle => 'Estilo del botón de llamada';

  @override
  String get callButtonTint => 'Tono suave';

  @override
  String get callButtonGlyph => 'Solo icono';

  @override
  String get callButtonLit => 'Círculo verde';

  @override
  String get callsAndContactsRows => 'Filas en Llamadas y Contactos';

  @override
  String get callsRows => 'Filas en Llamadas';

  @override
  String get tapAlreadyCalls => 'Tocar una llamada ya llama';

  @override
  String get simCards => 'Tarjetas SIM';

  @override
  String get groupByContact => 'Agrupar por contacto';

  @override
  String get dontGroupByContact => 'No agrupar por contacto';

  @override
  String get keypadAndContacts => 'Teclado y contactos';

  @override
  String get swipeToCallSim => 'Deslizar para llamar';

  @override
  String get sameAsKeypad => 'Igual que el teclado';

  @override
  String get tapSimUnused =>
      'Solo se usa cuando Tocar una llamada reciente está en Llamar, en Llamada rápida';

  @override
  String get swipeSimUnused =>
      'Solo se usa cuando Deslizar para llamar está activado, en Llamada rápida';

  @override
  String get onboardingSkip => 'Omitir';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingStart => 'Empezar';

  @override
  String get onboardingLookTitle => 'Hazla tuya';

  @override
  String get onboardingLookBody =>
      'Elige el idioma de la app y si se ve clara u oscura.';

  @override
  String get onboardingAnswerTitle => 'Responder llamadas';

  @override
  String get onboardingAnswerBody =>
      'Elige cómo se ven las llamadas entrantes y cómo las respondes.';

  @override
  String get onboardingHealthTitle => 'Lista para llamadas';

  @override
  String get onboardingHealthBody =>
      'Las llamadas entrantes necesitan esto de Android. Toca uno para arreglarlo.';

  @override
  String get onboardingAllSet => 'Todo listo';

  @override
  String get onboardingCallingTitle => 'Hacer llamadas';

  @override
  String get onboardingCallingBody =>
      'Elige la SIM para llamar y qué hace un toque o un deslizamiento sobre una llamada.';

  @override
  String get mergeDuplicatedNames => 'Combinar nombres duplicados';

  @override
  String get mergeDuplicatedNumbers => 'Combinar números duplicados';

  @override
  String get manuallyMergeDuplicates => 'Combinar duplicados manualmente';

  @override
  String get sameNumberContacts => 'Contactos con el mismo número';

  @override
  String get sameNameContacts => 'Contactos con el mismo nombre';

  @override
  String groupCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count grupos',
      one: '1 grupo',
    );
    return '$_temp0';
  }

  @override
  String get mergeManually => 'Combinar manualmente';

  @override
  String get manualMergingDetails => 'Detalles de la combinación';

  @override
  String get nameRequired => 'Nombre (obligatorio)';

  @override
  String get numbersSelectMany => 'Número (puedes elegir más de uno)';

  @override
  String mergeDeletesNumbers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Los $count números sin marcar se eliminarán del contacto.',
      one: 'El número sin marcar se eliminará del contacto.',
    );
    return '$_temp0';
  }

  @override
  String get blockCalls => 'Bloquear llamadas';

  @override
  String get blockMessages => 'Bloquear mensajes';

  @override
  String get blockMessagesUnavailable =>
      'One Dialer no es tu app de mensajes, así que no puede bloquearlos. El bloqueo de llamadas, la lista de bloqueados y la de permitidos no cambian.';

  @override
  String get blocklist => 'Lista de bloqueados';

  @override
  String get blocklistSubtitle =>
      'Las llamadas de los números de la lista de bloqueados se bloquearán.';

  @override
  String get allowlist => 'Lista de permitidos';

  @override
  String get allowlistSubtitle =>
      'Las llamadas de los números de la lista de permitidos no se bloquearán.';

  @override
  String get none => 'Ninguno';

  @override
  String get noNumbers => 'Sin números';

  @override
  String get blockByPrefix => 'Bloquear por prefijo';

  @override
  String get numberPrefix => 'Prefijo, p. ej. 0300';

  @override
  String startsWith(String prefix) {
    return 'Empieza por $prefix';
  }

  @override
  String removeFromBlocklist(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Quitar $count números de la lista de bloqueados?',
      one: '¿Quitar 1 número de la lista de bloqueados?',
    );
    return '$_temp0';
  }

  @override
  String removeFromAllowlist(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Quitar $count números de la lista de permitidos?',
      one: '¿Quitar 1 número de la lista de permitidos?',
    );
    return '$_temp0';
  }

  @override
  String searchContactNumbers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Buscar en $count números de contactos',
      one: 'Buscar en 1 número de contactos',
    );
    return '$_temp0';
  }

  @override
  String get unofficialBuildTitle => 'Versión no oficial';

  @override
  String get unofficialBuildCredit =>
      'Basada en One Dialer de Syed Arham Raza, github.com/syedarhamraza/one-dialer';

  @override
  String get unofficialBuildNotice =>
      'Versión no oficial. Basada en One Dialer de Syed Arham Raza, github.com/syedarhamraza/one-dialer';

  @override
  String mergeAll(String count) {
    return 'Combinar todo ($count)';
  }

  @override
  String mergeGroupsTitle(String count, String groups) {
    return '¿Combinar $count contactos en $groups?';
  }

  @override
  String get mergeGroupsMessage =>
      'Cada grupo se convierte en un contacto, con todos sus números y datos.';
}
