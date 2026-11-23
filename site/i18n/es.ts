import type { Dict } from "./en";

// Spanish, "tú" like the app. Labels match lib/l10n/app_es.arb and One Recorder's values-es.
export const es: Dict = {
  meta: {
    title: "One Dialer · Teléfono y bloqueo de llamadas para Android",
    description: "Marcador T9 rápido con bloqueo de llamadas, doble SIM y un diseño de cristal esmerilado.",
    released: "Gratis en Google Play.",
    beta: "Ahora en beta cerrada en Google Play.",
    recorderTitle: "One Recorder · One Dialer",
    recorderDescription: "Graba tus llamadas en One Dialer con One Recorder, una pequeña app complementaria que instalas desde esta web. Cómo configurarla y qué esperar.",
    guideTitle: "Guía · One Dialer",
    guideDescription: "Cómo usar One Dialer: SIM, llamar desde Llamadas, el teclado, contactos, bloqueo, la pantalla de llamada y los efectos, con configuraciones para situaciones habituales.",
  },
  nav: {
    label: "Sitio",
    whatsNew: "Novedades",
    guide: "Guía",
    recorder: "Recorder",
    privacy: "Privacidad",
    getApp: "Descargar la app",
    joinBeta: "Únete a la beta",
    beta: "Beta",
  },
  stage: {
    headline: ["Llamadas,", "en", "cristal."],
    intro: "Una app de teléfono rápida y privada para Android. T9 inteligente, bloqueo de llamadas y doble SIM, sobre negro puro.",
    small: "Gratis · Sin anuncios · Android 10 o posterior",
    screens: "Pantallas",
    alt: "Pantalla {title} de One Dialer",
  },
  screens: [
    { title: "Teclado", body: "Teclas esmeriladas sobre tus llamadas, con una tecla de llamada para cada SIM." },
    { title: "Llamadas", body: "Las perdidas en rojo, las repetidas agrupadas, las bloqueadas marcadas. El teclado está a un toque." },
    { title: "Contactos", body: "Primero los favoritos, luego un índice A–Z bajo tu pulgar." },
    { title: "Entrante", body: "A pantalla completa, con los colores de quien llama, directamente en la pantalla de bloqueo." },
    { title: "En llamada", body: "Grandes controles de cristal para silenciar, poner en espera, altavoz y teclado." },
  ],
  does: {
    h: "Lo que hace.",
    h2: "Y lo que no.",
    items: [
      { title: "Bloquea antes de sonar", text: "Números privados, desconocidos o cualquiera que no esté en tus contactos. Además de la lista de bloqueo de tu teléfono." },
      { title: "Doble SIM, bien hecha", text: "Una SIM para cada contacto, una SIM predeterminada o preguntar siempre. La tecla de llamada muestra qué SIM usas." },
      { title: "Una app de teléfono de verdad", text: "Cada llamada pasa por el framework Telecom de Android, así que las llamadas se comportan igual que con el marcador del sistema." },
      { title: "Se queda en tu teléfono", text: "Sin cuenta, sin anuncios. Tus llamadas y contactos nunca salen del dispositivo." },
      { title: "Código abierto", text: "GPL-3.0. Lee el código, informa de un error o añade tu idioma." },
    ],
    github: "One Dialer en GitHub",
  },
  smooth: {
    h: "Fluido en",
    h2: "cualquier teléfono.",
    text: "Al abrirla por primera vez, One Dialer lee el chip de tu teléfono y elige un nivel de efectos visuales, que puedes cambiar en Ajustes. Prueba aquí los tres niveles: el cristal de esta página los sigue, incluidos el teclado y la placa de arriba.",
  },
  levels: {
    label: "Efectos visuales",
    full: { label: "Todos", text: "Cristal esmerilado con su brillo en los bordes. Los chips de gama alta empiezan aquí." },
    reduced: { label: "Reducidos", text: "Un relleno translúcido plano sobre un único desenfoque compartido. Los chips de gama media empiezan aquí." },
    off: { label: "Sin", text: "Rellenos sólidos y nada de desenfoque. Los chips económicos y los teléfonos con poca memoria empiezan aquí." },
  },
  keypad: {
    hint: "Prueba 3662 en las teclas",
    none: "Nadie con ese nombre o número.",
    delete: "Borrar",
  },
  whatsNew: {
    h: "Novedades.",
    beta: "Beta {n}",
    version: "Versión {v}",
    note: "Las notas de la versión solo están en inglés.",
  },
  get: {
    h: "Consigue One Dialer.",
    h2: "Gratis en Google Play.",
    text: "Instálala como cualquier otra app y, cuando te lo pida, elige One Dialer como app de teléfono predeterminada. Android 10 o posterior.",
  },
  join: {
    h: "Únete a la beta.",
    h2: "Dos pasos.",
    text: "One Dialer está en pruebas cerradas en Google Play. Únete al grupo de testers y luego instálala desde Play como cualquier otra app.",
    step: "Paso {n}: ",
    group: {
      title: "Únete al grupo de Google",
      text: "Abre el grupo y toca Unirse al grupo. Así tu cuenta de Google entra en la lista de testers.",
      note: "Usa la misma cuenta de Google con la que has iniciado sesión en Play Store en tu teléfono.",
      cta: "Unirme al grupo",
    },
    tester: {
      title: "Hazte tester en Google Play",
      text: "Abre la página de pruebas, toca Convertirse en tester, luego Descárgala en Google Play e instálala.",
      note: "Después de unirte al grupo, puede tardar unos minutos en dejarte entrar esta página.",
      cta: "Hacerme tester",
    },
  },
  apk: {
    title: "¿Tienes One Dialer como archivo APK?",
    text: "Las copias compartidas como archivo, o sacadas de un teléfono con otra app, no son oficiales. No reciben actualizaciones y podrían estar modificadas.",
    released: "Desinstálala e instálala desde Google Play.",
    beta: "Desinstálala y únete desde aquí.",
  },
  faq: {
    h: "Preguntas,",
    h2: "respondidas.",
    items: [
      {
        beta: true,
        q: "¿Por qué una beta cerrada?",
        a: "Google Play pide que un grupo de personas pruebe las apps nuevas antes de hacerlas públicas. Unirte ayuda a One Dialer a llegar ahí, y recibes cada actualización antes que nadie.",
      },
      {
        beta: true,
        q: "El enlace de Play dice que la app no está disponible.",
        a: "Comprueba que te uniste al grupo de Google con la misma cuenta de Google que usas en Play Store en tu teléfono. Después de unirte, el enlace de pruebas puede tardar unos minutos en funcionar.",
      },
      { q: "¿En qué teléfonos funciona?", a: "Android 10 o posterior. Para hacer y recibir llamadas, elige One Dialer como app de teléfono predeterminada cuando te lo pida." },
      { q: "¿Es gratis? ¿Tiene anuncios?", a: "Es gratis y no tiene anuncios." },
      {
        q: "¿Mis llamadas y contactos salen de mi teléfono?",
        a: "No. Tu historial de llamadas y tus contactos se quedan en tu teléfono. La política de privacidad indica exactamente qué se envía, como los informes de fallos.",
      },
      {
        q: "Tengo One Dialer como archivo APK.",
        a: "Esa copia no es oficial: no recibirá actualizaciones y podría estar modificada. Desinstálala y luego instala One Dialer desde Google Play.",
        aBeta: "Esa copia no es oficial: no recibirá actualizaciones y podría estar modificada. Desinstálala y luego únete aquí a la beta para conseguirla desde Google Play.",
      },
      { beta: true, q: "¿Cómo salgo de la beta?", a: "Abre el enlace de pruebas de Google Play y elige Abandonar el programa; después desinstala la app si quieres." },
    ],
  },
  play: "Consíguela en Google Play",
  footer: {
    bug: "¿Has encontrado un error?",
    idea: "¿Tienes una idea?",
    feature: "Pedir una función",
    report: "Informar de un error",
    label: "Pie de página",
    guide: "Guía",
    recorder: "One Recorder",
    privacy: "Política de privacidad (inglés)",
    contact: "Contacto",
    language: "Idioma",
  },
  guide: {
    back: "Volver a One Dialer",
    title: "Guía",
    h1: "One Dialer,",
    h1b: "explicado.",
    lead: "Dónde está todo, qué hace cada ajuste y los ajustes que encajan con tu situación.",
    toc: "En esta página",
    intro: "Imágenes y grabaciones cortas muestran cada paso. Los ajustes están en el menú ⋮ de la pestaña Llamadas.",
    sections: [
      {
        id: "start",
        title: "Primeros pasos",
        blocks: [
          {
            ol: [
              "Abre One Dialer y toca **Predeterminar** para que sea tu **app de teléfono predeterminada**. Las llamadas, las recientes y los avisos de llamadas perdidas solo funcionan así.",
              "Permite **Contactos**, **Teléfono** y **Notificaciones** cuando Android lo pida.",
              "Abre **Ajustes**. Si algo falla, arriba aparece una tarjeta **Requiere atención**, por ejemplo “No es tu app de teléfono predeterminada” o las notificaciones desactivadas, con un botón **Arreglar** que te lleva directamente.",
            ],
          },
          { shot: "start-default", alt: "Poner One Dialer como app de teléfono predeterminada" },
          { shot: "settings-health", alt: "Ajustes con la tarjeta Requiere atención y los botones Arreglar" },
        ],
      },
      {
        id: "calls",
        title: "Llamadas y llamadas recientes",
        blocks: [
          { p: "La pestaña **Llamadas** muestra tus llamadas recientes. Las perdidas están en rojo, las repetidas se agrupan y las bloqueadas están marcadas." },
          { p: "Lo que pasa al tocar una llamada lo decides tú, en **Ajustes › Llamada rápida › Tocar una llamada reciente**:" },
          {
            ul: [
              "**Abrir detalles**: la opción segura. Se abre la página de la llamada, con el número, las llamadas anteriores, las notas y un botón Llamar.",
              "**Llamar**: devuelve la llamada al momento. Rápido, pero fácil de hacer sin querer.",
              "**Escribir en el teclado**: pone el número en el teclado, para revisarlo o cambiarlo antes de llamar.",
            ],
          },
          { shot: "recents-tap", alt: "El ajuste Tocar una llamada reciente con Llamar, Abrir detalles y Escribir en el teclado" },
          {
            ul: [
              "**Botón de llamada en las filas** pone un botón de llamada en cada fila, así el toque puede abrir los detalles y el botón llama. **Estilo del botón de llamada** cambia su aspecto.",
              "**Deslizar para llamar o escribir**: desliza una fila a la derecha para llamar y a la izquierda para escribir.",
              "**Agrupar por contacto** junta las llamadas de cada persona.",
              "Mantén pulsada una fila para seleccionar varias llamadas, por ejemplo para borrarlas.",
            ],
          },
          { shot: "recents-swipe", alt: "Deslizar una llamada reciente a la derecha para llamar" },
        ],
      },
      {
        id: "sims",
        title: "Dos SIM",
        blocks: [
          { p: "Con dos SIM, **Ajustes › Tarjetas SIM** decide cuál usa cada llamada. Se elige por separado para:" },
          {
            ul: [
              "**Teclado y contactos**: **SIM predeterminada del teléfono**, o **Preguntar siempre**, que muestra un selector de SIM al llamar.",
              "**Tocar una llamada reciente** y **Deslizar para llamar**: **Igual que el teclado**, **Usar la SIM reciente** (la SIM de esa llamada), **Preguntar siempre** o siempre una SIM. Solo se usan si ese tipo de llamada está activado en Llamada rápida.",
            ],
          },
          { shot: "sim-settings", alt: "Ajustes de Tarjetas SIM" },
          { p: "Un contacto puede tener **su propia SIM**: abre su página y elígela. Siempre va primero, antes que cualquier regla de arriba." },
          { shot: "sim-contact", alt: "Elegir una SIM en la página de un contacto" },
          { p: "En el teclado, **Ajustes › Teclado › Dos botones de llamada** muestra un botón Llamar por SIM en lugar de uno, para elegir al llamar." },
          { shot: "sim-chooser", alt: "El selector de SIM al llamar con Preguntar siempre" },
        ],
      },
      {
        id: "keypad",
        title: "Teclado",
        blocks: [
          {
            ul: [
              "Escribe números o letras: los contactos que coinciden aparecen mientras escribes (**T9**). Toca uno para llamarlo o abrirlo.",
              "Mantén pulsado **1** para el buzón de voz y **2–9** para la marcación rápida. Configúrala en **Ajustes › Teclado › Marcación rápida**.",
              "Mantén pulsado **0** para **+**. Mantén pulsada la tecla de asterisco (*) para una pausa y **#** para una espera, en números con extensión.",
              "Mantén pulsado el número para pegar uno copiado. Mantén pulsado **Borrar** para vaciarlo.",
              "Desliza el teclado hacia abajo, o toca el asa, para ver tus llamadas. El botón verde junto a la barra de navegación lo trae de vuelta con el número intacto.",
            ],
          },
          { shot: "keypad-t9", alt: "Escribir en el teclado con los contactos que coinciden" },
          { shot: "keypad-speed-dial", alt: "Ajustes de marcación rápida" },
        ],
      },
      {
        id: "contacts",
        title: "Contactos",
        blocks: [
          {
            ul: [
              "Los favoritos están arriba, bajo ★. Desliza por el índice **A–Z** de la derecha para saltar.",
              "Toca un contacto para ver su página: números, su propia SIM, el fondo de llamada y el bloqueo. Mantén pulsado para seleccionar varios.",
              "**⋮ › Gestionar contactos** elige qué cuentas se muestran, el orden y el formato del nombre, dónde se guardan los nuevos contactos, importar y exportar, los contactos de la SIM y **Combinar contactos duplicados**.",
            ],
          },
          { shot: "contacts-index", alt: "Contactos con los favoritos y el índice A–Z" },
          { shot: "contacts-manage", alt: "Gestionar contactos" },
        ],
      },
      {
        id: "blocking",
        title: "Bloqueo",
        blocks: [
          {
            ul: [
              "Bloquea un número desde la página de la llamada o del contacto. **Ajustes › Bloquear y filtrar › Números bloqueados** los muestra; Android mismo rechaza esas llamadas.",
              "**Bloquear números desconocidos/privados** frena a quien oculta su número. **Bloquear llamadas de números que no están en Contactos** deja sonar solo a tus contactos.",
              "Estas dos reglas necesitan One Dialer como **App de identificación y spam**. One Dialer lo pide al activar una. Si otra app toma ese papel, Ajustes muestra “Las reglas de bloqueo están en pausa”.",
              "**Ocultar llamadas bloqueadas** las saca de la lista de Llamadas.",
            ],
          },
          { shot: "blocking-rules", alt: "Ajustes de Bloquear y filtrar" },
        ],
      },
      {
        id: "callscreen",
        title: "La pantalla de llamada",
        blocks: [
          {
            ul: [
              "Las llamadas entrantes ocupan la pantalla, incluso en la pantalla de bloqueo. **Ajustes › Pantalla de llamada** elige cómo respondes (deslizando arriba o abajo, o con botones), los efectos, la foto de quien llama y el fondo.",
              "Durante una llamada: silencio, espera, altavoz, el teclado y añadir llamada están en grandes botones de cristal. **⋮** tiene más, como Grabar cuando One Recorder está instalado.",
              "Los **Mensajes de rechazo rápido** son los textos que puedes enviar al rechazar una llamada.",
              "**Responder y finalizar llamadas** tiene respuesta automática, responder con SMS y altavoz. **Ocultar números de los contactos** muestra solo los nombres de los contactos guardados.",
            ],
          },
          { shot: "call-incoming", alt: "Una llamada entrante en la pantalla de bloqueo" },
          { shot: "call-controls", alt: "Controles durante la llamada" },
        ],
      },
      {
        id: "look",
        title: "Aspecto y velocidad",
        blocks: [
          { p: "**Ajustes › Pantalla y efectos › Reducir efectos visuales** fija cuánto cristal y desenfoque dibuja la app. One Dialer elige un nivel para tu teléfono la primera vez; cámbialo cuando quieras:" },
          {
            ul: [
              "**Todos los efectos**: todo tal como se diseñó, cristal y desenfoque.",
              "**Efectos reducidos**: cristal más plano, mucho menos trabajo para el teléfono.",
              "**Sin efectos**: colores sólidos, sin desenfoque. Lo más rápido.",
            ],
          },
          { shot: "effects-levels", alt: "Reducir efectos visuales: todos, reducidos y sin efectos" },
          { p: "Con todos los efectos, **Cristal y desenfoque › Estilo de cristal** puede ser **Brillo de bordes** o el experimental **Cristal líquido**, que curva lo que hay detrás pero necesita más potencia. **Tamaño de pantalla** agranda o reduce la app y la barra de navegación, y la pantalla de llamada tiene sus propios **Efectos de la pantalla de llamada**." },
          { shot: "glass-style", alt: "Estilo de cristal: Brillo de bordes y Cristal líquido" },
        ],
      },
      {
        id: "more",
        title: "Idioma, copia de seguridad y actualizaciones",
        blocks: [
          {
            ul: [
              "**Ajustes › Idioma › Idioma de la app** cambia solo el idioma de One Dialer. **Igual que el teléfono** sigue a Android.",
              "**Copia de seguridad y restauración** guarda tus ajustes, la marcación rápida, las notas de llamada y los fondos de llamada en un archivo, para un teléfono nuevo o una reinstalación.",
              "**Actualización de software** avisa cuando hay una versión nueva en Google Play, con sus novedades.",
            ],
          },
          { shot: "settings-language", alt: "Ajustes del idioma de la app" },
        ],
      },
      {
        id: "setups",
        title: "Configuraciones para situaciones habituales",
        blocks: [
          { p: "Elige la situación que se parece a la tuya y cambia estos ajustes." },
          {
            setup: "Llamo a la gente sin querer",
            when: "Un toque en una llamada reciente, o un deslizamiento al desplazarte, empieza una llamada que no querías.",
            steps: [
              "**Ajustes › Llamada rápida › Tocar una llamada reciente** → **Abrir detalles**.",
              "Desactiva **Deslizar para llamar o escribir**.",
              "Opcional: activa **Botón de llamada en las filas**, así llamar es un toque deliberado en el botón.",
            ],
          },
          { shot: "setup-no-accidents", alt: "Llamada rápida configurada para evitar llamadas sin querer" },
          {
            setup: "SIM del trabajo y SIM personal",
            when: "Quieres los contactos del trabajo en una SIM y el resto en la otra, sin elegir cada vez.",
            steps: [
              "**Ajustes › Tarjetas SIM › Teclado y contactos** → tu SIM personal (o SIM predeterminada del teléfono).",
              "En la página de cada contacto del trabajo, elige la **SIM del trabajo**. Siempre gana.",
              "**Tocar una llamada reciente** → **Usar la SIM reciente**, para devolver la llamada con la SIM por la que llegó.",
            ],
          },
          { shot: "setup-two-sims", alt: "Ajustes de SIM para trabajo y uso personal" },
          {
            setup: "Nunca sé qué SIM se va a usar",
            when: "Dos SIM y prefieres decidir en cada llamada.",
            steps: [
              "**Ajustes › Tarjetas SIM › Teclado y contactos** → **Preguntar siempre**.",
              "Activa **Ajustes › Teclado › Dos botones de llamada**, para que el teclado muestre un botón por SIM.",
            ],
          },
          {
            setup: "Mi teléfono va lento",
            when: "El desplazamiento se traba o la pantalla de llamada tarda en abrirse.",
            steps: [
              "**Ajustes › Pantalla y efectos › Reducir efectos visuales** → **Efectos reducidos**, o **Sin efectos** en un teléfono antiguo.",
              "**Estilo de cristal** → **Brillo de bordes** (no Cristal líquido).",
              "Baja también los **Efectos de la pantalla de llamada**.",
            ],
          },
          { shot: "setup-slow-phone", alt: "Reducir efectos visuales en Efectos reducidos" },
          {
            setup: "Solo debe llamarme gente que conozco",
            when: "Spam, números privados o desconocidos.",
            steps: [
              "**Ajustes › Bloquear y filtrar** → activa **Bloquear números desconocidos/privados** y, si quieres, **Bloquear llamadas de números que no están en Contactos**.",
              "Acepta One Dialer como **App de identificación y spam** cuando te lo pida.",
              "Activa **Ocultar llamadas bloqueadas** para tener Llamadas en orden.",
            ],
          },
          {
            setup: "Quiero grabar llamadas",
            when: "One Dialer de Google Play nunca graba por sí misma. La grabación viene de una app aparte, One Recorder.",
            steps: [
              "Sigue la guía de **One Recorder** en este sitio: lleva unos cinco minutos, una sola vez.",
            ],
          },
        ],
      },
    ],
  },
  recorder: {
    back: "Volver a One Dialer",
    title: "One Recorder",
    h1: "One",
    h1b: "Recorder.",
    lead: "Grabación de llamadas para One Dialer. Es una app aparte, así que One Dialer de Google Play nunca graba nada por sí misma.",
    download: "Descargar APK",
    downloadNote: "Última versión, desde GitHub Releases · Android 12 o posterior",
    prosTitle: "Lo que obtienes",
    pros: [
      "Las dos partes de la llamada a volumen completo, en Android 12 o posterior: tú y la otra persona, con el auricular, el altavoz, Bluetooth o auriculares. Sin root, sin ordenador, sin una app Shizuku aparte.",
      "Tras un reinicio vuelve a arrancar sola en cuanto estás en una Wi-Fi.",
      "Sin permiso de micrófono y sin servicio de accesibilidad. One Recorder graba la propia llamada, solo durante las llamadas que grabas.",
      "Las grabaciones se quedan en tu teléfono. No se sube nada, no hay cuenta ni anuncios.",
      "Graba cuando quieras o automáticamente: todas las llamadas, los números desconocidos o solo los contactos que elijas.",
      "Tus grabaciones viven en One Dialer, con nombres de contacto, búsqueda, estrellas, compartir y eliminación automática.",
      "Código abierto, como One Dialer. Cualquiera puede comprobar lo que hace.",
      "Comprueba cada pocas horas que sigue activo, y si se ha parado vuelve a arrancar solo.",
      "Tras arrancar desactiva solo las Opciones para desarrolladores, así la mayoría de las apps bancarias se abren.",
      "Comprobar ahora verifica que la grabación funciona de verdad, y el resultado de la última llamada muestra si se grabó.",
    ],
    consTitle: "Qué esperar",
    cons: [
      "Grabar las dos partes necesita activar una vez las Opciones para desarrolladores y la Depuración inalámbrica, y Wi-Fi cada vez que arranca. Si no puede volver a arrancar tras un reinicio (sin Wi-Fi, u Opciones para desarrolladores desactivadas), lo inicias tocando en One Recorder.",
      "En algunos teléfonos la depuración USB o la inalámbrica tiene que seguir activada para que la grabación siga funcionando, y aun así algunas apps bancarias no se abren.",
      "En algunos teléfonos, las llamadas por Wi-Fi solo graban una parte. Es cosa del controlador de audio del teléfono, no de One Recorder.",
      "Necesita Android 12 o posterior. Android 10 y 11 no pueden iniciar el servicio por Depuración inalámbrica, y ahí no hay otra forma de grabar.",
      "No está en Google Play. Busca nuevas versiones en GitHub por sí misma y las instala desde Actualización de software.",
      "Solo funciona con One Dialer de Google Play, versión 1.0.0-beta.9 o posterior, no con una copia instalada desde un archivo.",
      "A la otra persona no se le avisa de que grabas. Eso depende de ti, y en algunos lugares es ilegal sin su consentimiento.",
    ],
    setup: "Configúrala,",
    setupB: "paso a paso.",
    toc: "En esta página",
    intro: "Unos cinco minutos, una sola vez. Después grabas desde la pantalla de llamada de One Dialer y no vuelves a abrir One Recorder.",
    sections: [
      {
        id: "before",
        title: "Antes de empezar",
        blocks: [
          {
            ul: [
              "Un teléfono con Android 12 o posterior, y Wi-Fi para la primera configuración y cada vez que el servicio arranca.",
              "**One Dialer de Google Play**, versión 1.0.0-beta.9 o posterior, como app de teléfono predeterminada. One Recorder comprueba que habla con la app oficial e ignora cualquier otra.",
              "Unos megas libres para la app, y espacio para grabaciones: aproximadamente medio mega por minuto de llamada.",
            ],
          },
        ],
      },
      {
        id: "install",
        title: "Instala la app",
        blocks: [
          {
            ol: [
              "En tu teléfono, toca **Descargar APK** arriba en esta página. El archivo se llama `one-dialer-recorder.apk`.",
              "Ábrelo desde la notificación de descarga o desde Descargas en tu app de Archivos.",
              "Si Android dice que tu navegador no puede instalar apps, toca **Ajustes**, activa **Permitir de esta fuente** y vuelve atrás.",
              "Toca **Instalar**. Google Play Protect puede ofrecerse a analizar la app, ya que no viene de Play. Déjale; es la misma app publicada en GitHub.",
            ],
          },
        ],
      },
      {
        id: "both",
        title: "Grabar las dos voces",
        blocks: [
          { p: "Abre One Recorder: los pasos están en **Configurar** y cada uno recibe una marca verde a medida que avanzas. **Continuar** arriba siempre hace el siguiente." },
          { shot: "rec-setup", alt: "Los pasos de configuración de One Recorder" },
          {
            ol: [
              "**Notificaciones.** Permítelas primero: el código de vinculación se escribe en la notificación de One Recorder.",
              "**Opciones para desarrolladores.** Si están desactivadas, abre **Ajustes › Información del teléfono** (en algunos teléfonos, Información del teléfono › Información de software) y toca **Número de compilación** siete veces.",
              "**Vincular con Depuración inalámbrica.** Toca la fila. One Recorder abre las Opciones para desarrolladores y muestra una notificación. Activa **Depuración inalámbrica**, ábrela y toca **Vincular dispositivo con código de vinculación**.",
              "Deja el código en pantalla, baja la notificación de One Recorder, toca **Introducir código** y escribe los seis dígitos. One Recorder se vincula y arranca su servicio. Solo se vincula una vez.",
              "**O vincula automáticamente:** activa **Vincular automáticamente (opcional)** en One Recorder. Lee el código del cuadro de vinculación por sí mismo y luego se desactiva. Desde Android 13, si aparece en gris, abre antes Info. de la app de One Recorder › ⋮ › **Permitir ajustes restringidos**.",
              "**Iniciar el servicio de grabación.** Si no está activo, asegúrate de estar en Wi-Fi y toca la fila. **Iniciar tras reiniciar** se activa solo la primera vez que arranca.",
            ],
          },
          { shot: "rec-pair", alt: "Escribir el código de vinculación en la notificación de One Recorder" },
          { p: "**Batería: sin restricciones** es el último paso. Evita que el teléfono cierre el grabador mientras espera una llamada." },
        ],
      },
      {
        id: "devoptions",
        title: "Opciones para desarrolladores y apps bancarias",
        blocks: [
          { p: "Muchas apps bancarias y de pago no se abren si las Opciones para desarrolladores, la depuración USB o la inalámbrica están activadas. **Desactivar Opciones para desarrolladores** viene activado: cuando el servicio de grabación arranca, One Recorder las apaga una a una y comprueba tras cada una que la grabación sigue funcionando." },
          { p: "Algunos teléfonos paran el servicio de grabación al apagar la depuración USB o la inalámbrica. One Recorder vuelve a encenderla y la deja así, y la fila lo indica. Cuando tiene que volver a arrancar el servicio (tras un reinicio, o al volver al Wi-Fi), las enciende un momento y las vuelve a apagar." },
          { shot: "rec-devoptions", alt: "El ajuste Desactivar Opciones para desarrolladores" },
        ],
      },
      {
        id: "check",
        title: "Comprueba que funciona",
        blocks: [
          {
            ul: [
              "**Comprobar ahora** (en Configurar) arranca el servicio de grabación si está parado, lo que demuestra que One Recorder sigue vinculado, y luego le hace abrir el audio de la llamada un momento. Muestra la hora y el resultado.",
              "Si la depuración inalámbrica ya no acepta One Recorder, Comprobar ahora te devuelve al paso de vinculación en lugar de seguir diciendo Vinculado.",
              "Tras cada llamada grabada, arriba en One Recorder aparece el resultado: cuándo y cuánto duró, o en rojo si la grabación estaba en silencio o la llamada no se grabó.",
            ],
          },
          { shot: "rec-check", alt: "Comprobar ahora y el resultado de la última llamada" },
        ],
      },
      {
        id: "record",
        title: "Graba una llamada",
        blocks: [
          {
            ul: [
              "Durante una llamada, toca **⋮ › Grabar** en la pantalla de llamada de One Dialer. Vuelve a tocarlo para parar. La grabación también se detiene sola cuando termina la llamada.",
              "La primera vez, One Dialer muestra un breve aviso sobre el consentimiento. La grabación empieza cuando lo aceptas.",
              "Para grabar automáticamente, abre **Ajustes › Grabación de llamadas** en One Dialer. La grabación automática puede estar desactivada o grabar todas las llamadas, solo los números desconocidos o solo los contactos que elijas, y una lista **No grabar nunca** deja fuera los contactos que quieras.",
            ],
          },
        ],
      },
      {
        id: "recordings",
        title: "Tus grabaciones",
        blocks: [
          {
            p: "Las encuentras en One Dialer en **Llamadas › ⋮ › Grabaciones**, o en **Ajustes › Grabación de llamadas**. Están agrupadas por día, con el nombre del contacto, y puedes buscarlas, filtrarlas (Todo, Destacadas, Contactos, Desconocidos), reproducirlas, destacarlas, renombrarlas, compartirlas o eliminarlas.",
          },
          { shot: "rec-recordings", alt: "Las grabaciones en One Dialer" },
          {
            p: "Los archivos viven dentro de One Recorder. **Guardar en el teléfono** copia uno a la carpeta `Recordings/One Dialer` de tu teléfono, donde tus otras apps pueden verlo. La **Eliminación automática** puede borrar grabaciones tras 30 o 90 días, conservando siempre las destacadas.",
          },
        ],
      },
      {
        id: "how",
        title: "Cómo funciona",
        blocks: [
          {
            p: "La forma más limpia de grabar una llamada es directamente desde la línea, con las dos voces a volumen completo. Android lo reserva para las apps integradas en el teléfono y para la **shell**: la cuenta con la que las herramientas de depuración de Android ejecutan comandos. La Depuración inalámbrica permite que una app del teléfono inicie un programa con esa cuenta, como hace Shizuku.",
          },
          {
            p: "Eso es lo que hace **Grabar las dos partes**. Una vez vinculada, One Recorder inicia desde su propia app un pequeño servicio como shell. El servicio hace una sola cosa: mientras One Recorder se lo pide, graba la llamada y devuelve el sonido por una conexión privada dentro del teléfono cuya llave solo tiene One Recorder. Se detiene cuando One Recorder se actualiza o se desinstala.",
          },
          { p: "One Dialer le dice a One Recorder cuándo empezar y parar. One Recorder graba el audio, guarda los archivos y solo responde al One Dialer firmado por Play." },
        ],
      },
      {
        id: "nomic",
        title: "Por qué no hay método con micrófono",
        blocks: [
          {
            p: "Las versiones anteriores también podían grabar con el micrófono, mediante un servicio de accesibilidad. Desde Android 10, una app que usa el micrófono durante una llamada solo recibe silencio, y Android solo hace una excepción con algunas apps de accesibilidad, en casos concretos. Los fabricantes cierran incluso esos: en el teléfono que probamos, un vivo con Android 17, las grabaciones hechas así salían mudas, con Android silenciando el micrófono durante toda la llamada.",
          },
          {
            p: "Un método que en silencio no graba nada es peor que ninguno, así que se ha eliminado, junto con el permiso de micrófono, el servicio de accesibilidad y los ajustes Aumento de volumen y Fuente del micrófono que solo usaba él. Grabar las dos partes por Depuración inalámbrica es ahora la única forma, y graba las dos voces a volumen completo.",
          },
        ],
      },
      {
        id: "privacy",
        title: "Privacidad",
        blocks: [
          { p: "Esta traducción es orientativa: el texto en inglés de esta página es el que vale." },
          {
            p: "One Recorder solo graba mientras hay una llamada que has elegido grabar. El audio se guarda únicamente dentro de One Recorder en tu teléfono. Nunca se sube, no hay cuenta, y nada sobre ti o tus llamadas sale del teléfono salvo que compartas tú una grabación. Las grabaciones se borran cuando las eliminas o desinstalas One Recorder.",
          },
          {
            p: "Su vinculación con la Depuración inalámbrica es una llave guardada en el almacenamiento privado de One Recorder en tu teléfono; no se puede incluir en copias de seguridad ni la pueden leer otras apps. El servicio solo graba llamadas para One Recorder y no puede ejecutar nada más. One Recorder no tiene permiso de micrófono ni servicio de accesibilidad. Las leyes sobre grabación varían según el país, y eres responsable de obtener el consentimiento de la otra persona cuando se exija.",
          },
          {
            p: "**Aviso legal.** One Recorder se ofrece tal cual, sin ninguna garantía. Puede grabar las dos partes de una llamada, y las leyes sobre grabación de llamadas varían según el país y la región: en algunos lugares todos los participantes deben estar de acuerdo, y en otros no se permite grabar en absoluto. Solo tú eres responsable de conocer y cumplir las leyes del lugar donde estáis tú y la otra persona, de avisarla y obtener su consentimiento cuando se exija, y del uso que hagas de tus grabaciones. Syed Arham Raza, que crea One Recorder y One Dialer, no es responsable de cómo la uses ni de ninguna grabación que hagas con ella.",
          },
        ],
      },
      {
        id: "legal",
        title: "Aviso legal",
        blocks: [
          { p: "Esta traducción es orientativa: el texto en inglés de esta página es el que vale." },
          {
            p: "One Recorder se ofrece tal cual, sin ninguna garantía. Puede grabar las dos partes de una llamada, y las leyes sobre grabación de llamadas varían según el país y la región: en algunos lugares todos los participantes deben estar de acuerdo, y en otros no se permite grabar en absoluto. Solo tú eres responsable de conocer y cumplir las leyes del lugar donde estáis tú y la otra persona, de avisarla y obtener su consentimiento cuando se exija, y del uso que hagas de tus grabaciones. Syed Arham Raza, que crea One Recorder y One Dialer, no es responsable de cómo la uses ni de ninguna grabación que hagas con ella.",
          },
        ],
      },
      {
        id: "setups",
        title: "Configuraciones para situaciones habituales",
        blocks: [
          {
            setup: "Uso apps bancarias",
            when: "Quieres grabar y usar tu app bancaria en el mismo teléfono.",
            steps: [
              "Deja activado **Desactivar Opciones para desarrolladores** (viene así).",
              "Deja desactivado **Seguir grabando sin Wi-Fi**: mantiene la depuración USB encendida.",
              "Si la fila dice que tu teléfono necesita una depuración activada, prueba la app bancaria de todos modos: muchas solo miran las Opciones para desarrolladores.",
            ],
          },
          {
            setup: "Quiero grabar también sin Wi-Fi",
            when: "El servicio de grabación se para cuando se va el Wi-Fi, porque la depuración inalámbrica lo necesita.",
            steps: [
              "Activa **Seguir grabando sin Wi-Fi**. Mantiene la depuración USB encendida, así el servicio sigue con datos móviles.",
              "Algunas apps bancarias no se abren mientras está activado.",
            ],
          },
          { shot: "rec-away-wifi", alt: "Seguir grabando sin Wi-Fi" },
          {
            setup: "Mi teléfono se reinicia a menudo lejos del Wi-Fi",
            when: "Tras un reinicio el servicio espera al Wi-Fi para arrancar.",
            steps: [
              "Comprueba que **Iniciar tras reiniciar** dice que arranca solo.",
              "De Android 12 a 16, prueba **Iniciar sin Wi-Fi (experimental)**. Necesita la Ubicación activada y puede no funcionar en todos los teléfonos.",
            ],
          },
          {
            setup: "Mis grabaciones están en silencio o bajas",
            when: "Una grabación no tiene sonido, o a la otra persona se la oye poco.",
            steps: [
              "Toca **Comprobar ahora**. Si no funciona todo, arregla el paso que indique.",
              "Prueba la misma llamada por la red móvil en lugar de con llamadas por Wi-Fi.",
              "Sigue mal: **Compartir diagnóstico** y envíalo con un reporte de error.",
            ],
          },
        ],
      },
      {
        id: "trouble",
        title: "Si no funciona",
        blocks: [
          {
            ul: [
              "**One Dialer dice que la grabación está en pausa, o el servicio no se está ejecutando:** el teléfono se reinició sin Wi-Fi, o se desactivaron las Opciones para desarrolladores. Conéctate a una Wi-Fi e inicia el servicio en One Recorder. Hasta que se ejecute, no se pueden grabar llamadas.",
              "**No se acepta el código de vinculación:** deja abierto el cuadro de vinculación mientras escribes el código, en la misma red Wi-Fi. Si sigue fallando, cierra el cuadro, vuelve a abrirlo para un código nuevo e inténtalo otra vez.",
              "**La grabación solo tiene una voz, o nada:** algunos teléfonos pierden una parte en las llamadas por Wi-Fi, y unos pocos no permiten grabar la línea en absoluto. Prueba la misma llamada por la red móvil.",
              "**One Dialer dice que no se están grabando las llamadas:** la grabación automática está activada pero One Recorder no está listo. Ábrelo y arregla cualquier fila que no esté Lista, normalmente el servicio.",
              "**One Dialer dice que la grabadora solo funciona con One Dialer de Google Play:** One Dialer se instaló desde un archivo o es anterior a la 1.0.0-beta.9. Instálala desde Google Play o actualiza las dos apps.",
              "**No aparece la opción Grabar en la pantalla de llamada:** One Recorder no está instalado. One Dialer oculta todo lo relacionado con la grabación hasta que lo esté.",
              "**Una app bancaria sigue sin abrirse:** tu teléfono necesita la depuración USB o la inalámbrica activada (la fila Desactivar Opciones para desarrolladores de One Recorder dice cuál). Desactiva **Seguir grabando sin Wi-Fi** si está activado, porque mantiene la depuración USB encendida.",
              "**Sigue sin funcionar:** toca **Compartir diagnóstico** en One Recorder y envía el informe con tu reporte de error. Incluye versiones, el modelo del teléfono, el estado de la configuración y líneas de registro recientes, sin números ni nombres.",
            ],
          },
        ],
      },
      {
        id: "update",
        title: "Actualizarla o quitarla",
        blocks: [
          {
            ul: [
              "**Para actualizarla,** abre One Recorder › **Actualización de software**. Mientras el servicio de grabación está activo, instala la nueva versión por sí misma, sin preguntar; si no, la descarga para que la instales. También puedes descargar el APK de esta página e instalarlo encima del anterior. Las grabaciones y los ajustes se mantienen.",
              "**Para quitarla,** desinstala One Recorder como cualquier app. Eso borra todas las grabaciones que contiene, así que guarda antes en el teléfono las que quieras conservar. One Dialer sigue funcionando y vuelve a ocultar sus opciones de grabación.",
              "Las leyes sobre grabación varían según el país. En algunos todos los participantes deben estar de acuerdo. Eres responsable de avisar a la otra persona y obtener su consentimiento cuando se exija.",
            ],
          },
        ],
      },
    ],
  },
};
