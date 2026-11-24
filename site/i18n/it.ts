import type { Dict } from "./en";

// Italian. Labels match the app's own Italian (lib/l10n/app_it.arb) and One Recorder's values-it.
export const it: Dict = {
  meta: {
    title: "One Dialer · Telefono e blocco chiamate per Android",
    description: "Tastiera T9 veloce con blocco chiamate, doppia SIM e un design in vetro smerigliato.",
    released: "Gratis su Google Play.",
    beta: "Ora in beta chiusa su Google Play.",
    recorderTitle: "One Recorder · One Dialer",
    recorderDescription: "Registra le chiamate in One Dialer con One Recorder, una piccola app compagna che installi da questo sito. Come configurarla e cosa aspettarsi.",
    guideTitle: "Guida · One Dialer",
    guideDescription: "Come usare One Dialer: SIM, chiamare da Chiamate, tastierino, contatti, blocco, schermata di chiamata ed effetti, con configurazioni per le situazioni più comuni.",
  },
  nav: {
    label: "Sito",
    whatsNew: "Novità",
    guide: "Guida",
    recorder: "Recorder",
    privacy: "Privacy",
    getApp: "Scarica l'app",
    joinBeta: "Entra nella beta",
    beta: "Beta",
  },
  stage: {
    headline: ["Chiamate,", "in", "vetro."],
    intro: "Un'app Telefono veloce e privata per Android. T9 intelligente, blocco chiamate e doppia SIM, su nero puro.",
    small: "Gratis · Senza pubblicità · Android 10 e successivi",
    screens: "Schermate",
    alt: "Schermata {title} di One Dialer",
  },
  screens: [
    { title: "Tastiera", body: "Tasti smerigliati sopra le tue chiamate, con un tasto Chiama per ogni SIM." },
    { title: "Chiamate", body: "Le perse in rosso, le ripetute raggruppate, le bloccate segnate. La tastiera è a un tocco." },
    { title: "Contatti", body: "Prima i preferiti, poi un indice A–Z sotto il pollice." },
    { title: "In arrivo", body: "A tutto schermo, con i colori di chi chiama, direttamente sulla schermata di blocco." },
    { title: "In chiamata", body: "Grandi controlli in vetro per silenzioso, attesa, vivavoce e tastiera." },
  ],
  does: {
    h: "Cosa fa.",
    h2: "E cosa non fa.",
    items: [
      { title: "Blocca prima che squilli", text: "Numeri privati, sconosciuti o chiunque non sia nei tuoi contatti. In più l'elenco dei numeri bloccati del telefono." },
      { title: "Doppia SIM, fatta bene", text: "Una SIM per ogni contatto, una SIM predefinita o chiedi ogni volta. Il tasto Chiama mostra quale SIM stai usando." },
      { title: "Una vera app Telefono", text: "Ogni chiamata passa dal framework Telecom di Android, quindi le chiamate si comportano esattamente come con il telefono di sistema." },
      { title: "Resta sul tuo telefono", text: "Nessun account, nessuna pubblicità. Chiamate e contatti non lasciano mai il dispositivo." },
      { title: "Open source", text: "GPL-3.0. Leggi il codice, segnala un bug o aggiungi la tua lingua." },
    ],
    github: "One Dialer su GitHub",
  },
  smooth: {
    h: "Fluido su",
    h2: "ogni telefono.",
    text: "Al primo avvio One Dialer legge il chip del telefono e sceglie un livello di effetti visivi, che puoi cambiare nelle Impostazioni. Prova qui i tre livelli: il vetro di questa pagina li segue, tastiera e lastra in alto comprese.",
  },
  levels: {
    label: "Effetti visivi",
    full: { label: "Completi", text: "Vetro di chiamata smerigliato con il suo bagliore sui bordi. I chip di punta partono da qui." },
    reduced: { label: "Ridotti", text: "Un unico riempimento traslucido sopra una sola sfocatura condivisa. I chip di fascia media partono da qui." },
    off: { label: "Off", text: "Riempimenti pieni e nessuna sfocatura. I chip economici e i telefoni con poca memoria partono da qui." },
  },
  keypad: {
    hint: "Prova 3662 sui tasti",
    none: "Nessuno con questo nome o numero.",
    delete: "Elimina",
  },
  whatsNew: {
    h: "Novità.",
    beta: "Beta {n}",
    version: "Versione {v}",
    note: "Le note di rilascio sono solo in inglese.",
  },
  get: {
    h: "Scarica One Dialer.",
    h2: "Gratis su Google Play.",
    text: "Installala come qualsiasi altra app, poi imposta One Dialer come app Telefono predefinita quando te lo chiede. Android 10 e successivi.",
  },
  join: {
    h: "Entra nella beta.",
    h2: "Due passaggi.",
    text: "One Dialer è in test chiuso su Google Play. Entra nel gruppo dei tester, poi installala da Play come qualsiasi altra app.",
    step: "Passaggio {n}: ",
    group: {
      title: "Entra nel Google Group",
      text: "Apri il gruppo e tocca Partecipa al gruppo. Così il tuo account Google entra nell'elenco dei tester.",
      note: "Usa lo stesso account Google con cui hai effettuato l'accesso al Play Store del telefono.",
      cta: "Entra nel gruppo",
    },
    tester: {
      title: "Diventa tester su Google Play",
      text: "Apri la pagina del test, tocca Diventa un tester, poi Scaricala su Google Play e installala.",
      note: "Dopo essere entrato nel gruppo, possono servire alcuni minuti prima che questa pagina ti faccia entrare.",
      cta: "Diventa tester",
    },
  },
  apk: {
    title: "Hai One Dialer come file APK?",
    text: "Le copie condivise come file, o estratte da un telefono con un'altra app, non sono ufficiali. Non ricevono aggiornamenti e potrebbero essere state modificate.",
    released: "Disinstallala e installala invece da Google Play.",
    beta: "Disinstallala ed entra invece da qui.",
  },
  faq: {
    h: "Domande,",
    h2: "risposte.",
    items: [
      {
        beta: true,
        q: "Perché una beta chiusa?",
        a: "Google Play chiede che le nuove app vengano provate da un gruppo di persone prima di diventare pubbliche. Partecipare aiuta One Dialer ad arrivarci, e ricevi ogni aggiornamento per primo.",
      },
      {
        beta: true,
        q: "Il link di Play dice che l'app non è disponibile.",
        a: "Assicurati di essere entrato nel Google Group con lo stesso account Google usato nel Play Store del telefono. Dopo l'iscrizione possono servire alcuni minuti prima che il link del test funzioni.",
      },
      { q: "Su quali telefoni funziona?", a: "Android 10 o successivo. Per fare e ricevere chiamate, imposta One Dialer come app Telefono predefinita quando te lo chiede." },
      { q: "È gratis? Ci sono pubblicità?", a: "È gratis e senza pubblicità." },
      {
        q: "Le mie chiamate e i miei contatti lasciano il telefono?",
        a: "No. Registro chiamate e contatti restano sul telefono. L'informativa sulla privacy elenca esattamente cosa viene inviato, come i rapporti sugli arresti anomali.",
      },
      {
        q: "Ho One Dialer come file APK.",
        a: "Quella copia non è ufficiale: non riceve aggiornamenti e potrebbe essere stata modificata. Disinstallala, poi installa One Dialer da Google Play.",
        aBeta: "Quella copia non è ufficiale: non riceve aggiornamenti e potrebbe essere stata modificata. Disinstallala, poi entra nella beta da qui per averla da Google Play.",
      },
      { beta: true, q: "Come lascio la beta?", a: "Apri il link del test su Google Play e scegli Abbandona il programma, poi disinstalla l'app se vuoi." },
    ],
  },
  play: "Scarica su Google Play",
  footer: {
    bug: "Trovato un bug?",
    idea: "Hai un'idea?",
    feature: "Chiedi una funzione",
    report: "Segnala un bug",
    label: "Piè di pagina",
    guide: "Guida",
    recorder: "One Recorder",
    privacy: "Informativa sulla privacy (inglese)",
    contact: "Contatti",
    language: "Lingua",
  },
  guide: {
    back: "Torna a One Dialer",
    title: "Guida",
    h1: "One Dialer,",
    h1b: "spiegata.",
    lead: "Dove si trova tutto, cosa fa ogni impostazione e le impostazioni adatte alla tua situazione.",
    toc: "In questa pagina",
    intro: "Immagini e brevi registrazioni mostrano ogni passaggio. Le impostazioni sono nel menu ⋮ della scheda Chiamate.",
    sections: [
      {
        id: "start",
        title: "Per iniziare",
        blocks: [
          {
            ol: [
              "Apri One Dialer e tocca **Imposta** per renderla la tua **app Telefono predefinita**. Chiamate, recenti e notifiche delle chiamate perse funzionano solo così.",
              "Consenti **Contatti**, **Telefono** e **Notifiche** quando Android lo chiede.",
              "Apri **Impostazioni**. Se qualcosa non va, in alto c'è una scheda **Richiede attenzione**, per esempio “Non è l'app Telefono predefinita” o notifiche disattivate, con un pulsante **Risolvi** che ti porta direttamente lì.",
            ],
          },
          { shot: "start-default", alt: "Impostare One Dialer come app Telefono predefinita" },
          { shot: "settings-health", alt: "Impostazioni con la scheda Richiede attenzione e i pulsanti Risolvi" },
        ],
      },
      {
        id: "calls",
        title: "Chiamate e chiamate recenti",
        blocks: [
          { p: "La scheda **Chiamate** elenca le chiamate recenti. Le chiamate perse sono in rosso, quelle ripetute sono raggruppate e quelle bloccate sono segnate." },
          { p: "Cosa succede quando tocchi una chiamata lo decidi tu, in **Impostazioni › Chiamata veloce › Tocco su una chiamata recente**:" },
          {
            ul: [
              "**Apri dettagli**: la scelta sicura. Si apre la pagina della chiamata, con il numero, le chiamate passate, le note e un pulsante Chiama.",
              "**Chiama**: richiama subito. Veloce, ma facile da fare per sbaglio.",
              "**Scrivi nel tastierino**: mette il numero nel tastierino, così puoi controllarlo o modificarlo prima di chiamare.",
            ],
          },
          { shot: "recents-tap", alt: "L'impostazione Tocco su una chiamata recente con Chiama, Apri dettagli e Scrivi nel tastierino" },
          {
            ul: [
              "**Pulsante di chiamata sulle righe** mette un pulsante di chiamata su ogni riga, così il tocco può aprire i dettagli mentre il pulsante chiama. **Stile del pulsante di chiamata** ne cambia l'aspetto.",
              "**Scorri per chiamare o scrivere**: scorri una riga a destra per chiamare, a sinistra per scrivere.",
              "**Raggruppa per contatto** riunisce le chiamate di una persona.",
              "Tieni premuta una riga per selezionare più chiamate, per esempio per eliminarle.",
            ],
          },
          { shot: "recents-swipe", alt: "Scorrere una chiamata recente a destra per chiamare" },
        ],
      },
      {
        id: "sims",
        title: "Due SIM",
        blocks: [
          { p: "Con due SIM, **Impostazioni › Schede SIM** decide quale usa ogni chiamata. Si sceglie separatamente per:" },
          {
            ul: [
              "**Tastierino e contatti**: **SIM predefinita del telefono**, oppure **Chiedi ogni volta**, che mostra la scelta della SIM quando chiami.",
              "**Tocco su una chiamata recente** e **Scorri per chiamare**: **Come tastierino**, **Usa la SIM recente** (la SIM usata da quella chiamata), **Chiedi ogni volta** o sempre una SIM. Valgono solo se quel tipo di chiamata è attivo in Chiamata veloce.",
            ],
          },
          { shot: "sim-settings", alt: "Impostazioni Schede SIM" },
          { p: "Un contatto può avere **la sua SIM**: apri la sua pagina e sceglila. Viene sempre prima di qualsiasi regola qui sopra." },
          { shot: "sim-contact", alt: "Scegliere una SIM nella pagina di un contatto" },
          { p: "Sul tastierino, **Impostazioni › Tastierino › Due pulsanti Chiama** mostra un pulsante Chiama per ogni SIM invece di uno solo, così scegli mentre chiami." },
          { shot: "sim-chooser", alt: "La scelta della SIM quando si chiama con Chiedi ogni volta" },
        ],
      },
      {
        id: "keypad",
        title: "Tastierino",
        blocks: [
          {
            ul: [
              "Scrivi cifre o lettere: i contatti corrispondenti compaiono mentre scrivi (**T9**). Toccane uno per chiamarlo o aprirlo.",
              "Tieni premuto **1** per la segreteria e **2–9** per la chiamata rapida. Imposta la chiamata rapida in **Impostazioni › Tastierino › Chiamata rapida**.",
              "Tieni premuto **0** per **+**. Tieni premuto il tasto asterisco (*) per una pausa e **#** per un'attesa, per i numeri con interno.",
              "Tieni premuto il numero per incollarne uno copiato. Tieni premuto **Elimina** per cancellarlo.",
              "Abbassa il tastierino, o tocca la maniglia, per vedere le chiamate. Il pulsante verde accanto alla barra di navigazione lo riporta su con il numero ancora lì.",
            ],
          },
          { shot: "keypad-t9", alt: "Scrivere sul tastierino con i contatti corrispondenti" },
          { shot: "keypad-speed-dial", alt: "Impostazioni della chiamata rapida" },
        ],
      },
      {
        id: "contacts",
        title: "Contatti",
        blocks: [
          {
            ul: [
              "I preferiti sono in cima, sotto ★. Scorri l'indice **A–Z** a destra per saltare.",
              "Tocca un contatto per la sua pagina: numeri, la sua SIM, lo sfondo di chiamata e il blocco. Tieni premuto per selezionarne più di uno.",
              "**⋮ › Gestisci contatti** imposta quali account mostrare, ordine e formato del nome, dove salvare i nuovi contatti, importazione ed esportazione, contatti della SIM e **Unisci contatti duplicati**.",
            ],
          },
          { shot: "contacts-index", alt: "Contatti con i preferiti e l'indice A–Z" },
          { shot: "contacts-manage", alt: "Gestisci contatti" },
        ],
      },
      {
        id: "blocking",
        title: "Blocco",
        blocks: [
          {
            ul: [
              "Blocca un numero dalla pagina della chiamata o del contatto. **Impostazioni › Blocca e filtra › Numeri bloccati** li elenca; è Android stesso a rifiutare quelle chiamate.",
              "**Blocca numeri sconosciuti/privati** ferma chi nasconde il numero. **Blocca chiamate da numeri non presenti nei contatti** fa squillare solo i tuoi contatti.",
              "Queste due regole richiedono One Dialer come **App ID chiamante e spam**. One Dialer lo chiede quando ne attivi una. Se un'altra app prende quel ruolo, le Impostazioni mostrano “Le regole di blocco sono in pausa”.",
              "**Nascondi chiamate bloccate** le toglie dall'elenco Chiamate.",
            ],
          },
          { shot: "blocking-rules", alt: "Impostazioni Blocca e filtra" },
        ],
      },
      {
        id: "callscreen",
        title: "La schermata di chiamata",
        blocks: [
          {
            ul: [
              "Le chiamate in arrivo riempiono lo schermo, anche sulla schermata di blocco. **Impostazioni › Schermata di chiamata** sceglie come rispondi (scorrendo su o giù, o con i pulsanti), gli effetti, la foto del chiamante e lo sfondo.",
              "Durante una chiamata: muto, attesa, vivavoce, tastierino e aggiunta di una chiamata sono su grandi pulsanti di vetro. **⋮** ha altro, come Registra quando One Recorder è installato.",
              "I **Messaggi di rifiuto rapido** sono i testi che puoi inviare quando rifiuti una chiamata.",
              "**Risposta e fine chiamate** ha la risposta automatica, la risposta con SMS e il vivavoce. **Nascondi i numeri dei contatti** mostra solo i nomi dei contatti salvati.",
            ],
          },
          { shot: "call-incoming", alt: "Una chiamata in arrivo sulla schermata di blocco" },
          { shot: "call-controls", alt: "I controlli durante la chiamata" },
        ],
      },
      {
        id: "look",
        title: "Aspetto e velocità",
        blocks: [
          { p: "**Impostazioni › Schermo ed effetti › Riduci effetti visivi** stabilisce quanto vetro e sfocatura disegna l'app. One Dialer sceglie un livello per il tuo telefono la prima volta; puoi cambiarlo quando vuoi:" },
          {
            ul: [
              "**Effetti completi**: tutto come progettato, vetro e sfocatura.",
              "**Effetti ridotti**: vetro più piatto, molto meno lavoro per il telefono.",
              "**Effetti disattivati**: colori pieni, nessuna sfocatura. Il più veloce.",
            ],
          },
          { shot: "effects-levels", alt: "Riduci effetti visivi: completi, ridotti e disattivati" },
          { p: "Con gli effetti completi, **Vetro e sfocatura › Stile vetro** può essere **Bagliore bordi** o lo sperimentale **Vetro liquido**, che piega ciò che sta dietro ma richiede più potenza. **Dimensioni schermo** ingrandisce o riduce l'app e la barra di navigazione, e la schermata di chiamata ha i suoi **Effetti schermata di chiamata**." },
          { shot: "glass-style", alt: "Stile vetro: Bagliore bordi e Vetro liquido" },
        ],
      },
      {
        id: "more",
        title: "Lingua, backup e aggiornamenti",
        blocks: [
          {
            ul: [
              "**Impostazioni › Lingua › Lingua dell'app** cambia solo la lingua di One Dialer. **Come il telefono** segue Android.",
              "**Backup e ripristino** salva impostazioni, chiamata rapida, note delle chiamate e sfondi di chiamata in un file, per un nuovo telefono o una reinstallazione.",
              "**Aggiornamento software** mostra quando c'è una nuova versione su Google Play, con le novità.",
            ],
          },
          { shot: "settings-language", alt: "Impostazioni della lingua dell'app" },
        ],
      },
      {
        id: "setups",
        title: "Configurazioni per le situazioni comuni",
        blocks: [
          { p: "Scegli la situazione che ti somiglia e cambia queste impostazioni." },
          {
            setup: "Chiamo le persone per sbaglio",
            when: "Un tocco su una chiamata recente, o uno scorrimento mentre scorri l'elenco, avvia una chiamata che non volevi.",
            steps: [
              "**Impostazioni › Chiamata veloce › Tocco su una chiamata recente** → **Apri dettagli**.",
              "Disattiva **Scorri per chiamare o scrivere**.",
              "Facoltativo: attiva **Pulsante di chiamata sulle righe**, così chiamare è un tocco deciso sul pulsante.",
            ],
          },
          { shot: "setup-no-accidents", alt: "Chiamata veloce impostata per evitare chiamate per sbaglio" },
          {
            setup: "SIM di lavoro e SIM personale",
            when: "Vuoi i contatti di lavoro su una SIM e tutti gli altri sull'altra, senza scegliere ogni volta.",
            steps: [
              "**Impostazioni › Schede SIM › Tastierino e contatti** → la tua SIM personale (o SIM predefinita del telefono).",
              "Nella pagina di ogni contatto di lavoro, scegli la **SIM di lavoro**. Vince sempre.",
              "**Tocco su una chiamata recente** → **Usa la SIM recente**, così richiamare usa la SIM su cui è arrivata la chiamata.",
            ],
          },
          { shot: "setup-two-sims", alt: "Impostazioni SIM per lavoro e uso personale" },
          {
            setup: "Non so mai quale SIM verrà usata",
            when: "Due SIM e preferisci decidere a ogni chiamata.",
            steps: [
              "**Impostazioni › Schede SIM › Tastierino e contatti** → **Chiedi ogni volta**.",
              "Attiva **Impostazioni › Tastierino › Due pulsanti Chiama**, così il tastierino mostra un pulsante per SIM.",
            ],
          },
          {
            setup: "Il mio telefono sembra lento",
            when: "Lo scorrimento scatta o la schermata di chiamata si apre lentamente.",
            steps: [
              "**Impostazioni › Schermo ed effetti › Riduci effetti visivi** → **Effetti ridotti**, o **Effetti disattivati** su un telefono più vecchio.",
              "**Stile vetro** → **Bagliore bordi** (non Vetro liquido).",
              "Abbassa anche gli **Effetti schermata di chiamata**.",
            ],
          },
          { shot: "setup-slow-phone", alt: "Riduci effetti visivi impostato su Effetti ridotti" },
          {
            setup: "Devono chiamarmi solo le persone che conosco",
            when: "Spam, numeri privati o sconosciuti.",
            steps: [
              "**Impostazioni › Blocca e filtra** → attiva **Blocca numeri sconosciuti/privati** e, se vuoi, **Blocca chiamate da numeri non presenti nei contatti**.",
              "Accetta One Dialer come **App ID chiamante e spam** quando te lo chiede.",
              "Attiva **Nascondi chiamate bloccate** per tenere in ordine Chiamate.",
            ],
          },
          {
            setup: "Voglio registrare le chiamate",
            when: "One Dialer da Google Play non registra mai da sola. La registrazione arriva da un'app separata, One Recorder.",
            steps: [
              "Segui la guida di **One Recorder** su questo sito: bastano circa cinque minuti, una volta sola.",
            ],
          },
        ],
      },
    ],
  },
  recorder: {
    back: "Torna a One Dialer",
    title: "One Recorder",
    h1: "One",
    h1b: "Recorder.",
    lead: "La registrazione delle chiamate per One Dialer. È un'app separata, così One Dialer da Google Play non registra mai nulla da sé.",
    download: "Scarica l'APK",
    downloadNote: "Ultima versione, da GitHub Releases · Android 12 o successivo",
    prosTitle: "Cosa ottieni",
    pros: [
      "Entrambe le voci a pieno volume, da Android 12 in poi: tu e l'altra persona, con l'auricolare, il vivavoce, il Bluetooth o le cuffie. Niente root, niente computer, niente app Shizuku a parte.",
      "Dopo un riavvio ripartisce da sola appena sei sul Wi-Fi.",
      "Nessun permesso del microfono. One Recorder registra la chiamata stessa, solo durante le chiamate che registri. Il suo unico servizio di accessibilità è facoltativo: legge solo il codice di associazione, poi si disattiva.",
      "Le registrazioni restano sul telefono. Non viene caricato nulla, non c'è un account e non ci sono pubblicità.",
      "Registra quando vuoi tu o in automatico: ogni chiamata, i numeri sconosciuti o solo i contatti che scegli.",
      "Le registrazioni vivono in One Dialer, con nomi dei contatti, ricerca, stelle, condivisione ed eliminazione automatica.",
      "Open source, come One Dialer. Chiunque può verificare cosa fa.",
      "Controlla ogni poche ore di essere ancora attivo, e se si è fermato riparte da solo.",
      "Dopo l'avvio disattiva da solo le Opzioni sviluppatore, così la maggior parte delle app bancarie si apre.",
      "Verifica ora controlla che la registrazione funzioni davvero, e il risultato dell'ultima chiamata mostra se è stata registrata.",
    ],
    consTitle: "Cosa aspettarsi",
    cons: [
      "Per entrambe le voci servono le Opzioni sviluppatore e il Debug wireless attivati una volta, e il Wi-Fi ogni volta che si avvia. Se dopo un riavvio non riesce a ripartire (niente Wi-Fi, o Opzioni sviluppatore disattivate), tocchi Avvia in One Recorder.",
      "Su alcuni telefoni il debug USB o il debug wireless deve restare attivo perché la registrazione continui a funzionare, e alcune app bancarie in quel caso non si aprono comunque.",
      "Su alcuni telefoni, le chiamate via Wi-Fi registrano una sola voce. Dipende dal driver audio del telefono, non da One Recorder.",
      "Serve Android 12 o successivo. Android 10 e 11 non possono avviare il servizio tramite il Debug wireless, e lì non c'è altro modo di registrare.",
      "Non è su Google Play. Cerca da solo le nuove versioni su GitHub e le installa da Aggiornamento software.",
      "Funziona solo con One Dialer da Google Play, versione 1.0.0-beta.9 o successiva, non con una copia installata da file.",
      "L'altra persona non viene avvisata che stai registrando. Spetta a te, e in alcuni paesi senza il suo consenso è vietato.",
    ],
    setup: "Configurala,",
    setupB: "passo dopo passo.",
    toc: "In questa pagina",
    intro: "Circa cinque minuti, una volta sola. Dopo registri dalla schermata di chiamata di One Dialer e non apri più One Recorder.",
    sections: [
      {
        id: "before",
        title: "Prima di iniziare",
        blocks: [
          {
            ul: [
              "Un telefono con Android 12 o successivo, e il Wi-Fi per la prima configurazione e ogni volta che il servizio si avvia.",
              "**One Dialer da Google Play**, versione 1.0.0-beta.9 o successiva, impostata come app Telefono predefinita. One Recorder controlla di parlare con l'app ufficiale e ignora tutte le altre.",
              "Qualche megabyte libero per l'app, e spazio per le registrazioni: circa mezzo megabyte per minuto di chiamata.",
            ],
          },
        ],
      },
      {
        id: "install",
        title: "Installa l'app",
        blocks: [
          {
            ol: [
              "Sul telefono, tocca **Scarica l'APK** in cima a questa pagina. Il file si chiama `one-dialer-recorder.apk`.",
              "Aprilo dalla notifica del download, o dai Download della tua app File.",
              "Se Android dice che il browser non può installare app, tocca **Impostazioni**, attiva **Consenti da questa fonte**, poi torna indietro.",
              "Tocca **Installa**. Google Play Protect potrebbe proporre di analizzare l'app, perché non arriva da Play. Lascialo fare: è la stessa app pubblicata su GitHub.",
            ],
          },
        ],
      },
      {
        id: "both",
        title: "Registra entrambe le voci",
        blocks: [
          { p: "Apri One Recorder: i passaggi sono in **Configura**, e ognuno riceve una spunta verde man mano che procedi. **Continua** in alto fa sempre il passaggio successivo." },
          { shot: "rec-setup", alt: "I passaggi di configurazione di One Recorder" },
          {
            ol: [
              "**Notifiche.** Consentile per prime: il codice di associazione si scrive nella notifica di One Recorder.",
              "**Opzioni sviluppatore.** Se sono disattivate, apri **Impostazioni › Info telefono** (su alcuni telefoni Info telefono › Informazioni software) e tocca **Numero build** sette volte.",
              "**Associa con il Debug wireless.** Tocca la riga. One Recorder apre le Opzioni sviluppatore e mostra una notifica. Attiva **Debug wireless**, aprilo e tocca **Associa dispositivo con codice di accoppiamento**.",
              "Lascia il codice sullo schermo, abbassa la notifica di One Recorder, tocca **Inserisci codice** e scrivi le sei cifre. One Recorder si associa e avvia il suo servizio. L'associazione si fa una volta sola.",
              "**Oppure associa automaticamente:** attiva **Associa automaticamente (facoltativo)** in One Recorder. Legge da solo il codice nella finestra di associazione, poi si disattiva. Da Android 13, se è disattivato in grigio, apri prima Info app di One Recorder › ⋮ › **Consenti impostazioni con restrizioni**.",
              "**Avvia il servizio di registrazione.** Se non è attivo, assicurati di essere sul Wi-Fi e tocca la riga. **Avvio dopo il riavvio** si attiva da solo al primo avvio.",
            ],
          },
          { shot: "rec-pair", alt: "Scrivere il codice di associazione nella notifica di One Recorder" },
          { p: "**Batteria: senza restrizioni** è l'ultimo passaggio. Impedisce al telefono di chiudere il registratore mentre aspetta una chiamata." },
        ],
      },
      {
        id: "devoptions",
        title: "Opzioni sviluppatore e app bancarie",
        blocks: [
          { p: "Molte app bancarie e di pagamento non si aprono se Opzioni sviluppatore, debug USB o debug wireless sono attivi. **Disattiva Opzioni sviluppatore** è attivo per impostazione predefinita: dopo l'avvio del servizio di registrazione, One Recorder li spegne uno alla volta e controlla dopo ognuno che la registrazione funzioni ancora." },
          { p: "Alcuni telefoni fermano il servizio di registrazione quando il debug USB o wireless si spegne. One Recorder allora lo riaccende e lo lascia attivo, e la riga lo dice. Quando deve riavviare il servizio (dopo un riavvio, o quando torni sul Wi-Fi), li accende per un momento e poi li spegne di nuovo." },
          { shot: "rec-devoptions", alt: "L'impostazione Disattiva Opzioni sviluppatore" },
        ],
      },
      {
        id: "check",
        title: "Controlla che funzioni",
        blocks: [
          {
            ul: [
              "**Verifica ora** (in Configura) avvia il servizio di registrazione se è fermo, il che dimostra che One Recorder è ancora associato, poi gli fa aprire l'audio della chiamata per un momento. Mostra l'ora e il risultato.",
              "Se il debug wireless non accetta più One Recorder, Verifica ora ti riporta al passaggio di associazione invece di continuare a dire Associato.",
              "Dopo ogni chiamata registrata, in cima a One Recorder compare il risultato: quando e quanto è durata, oppure in rosso se la registrazione era muta o la chiamata non è stata registrata.",
            ],
          },
          { shot: "rec-check", alt: "Verifica ora e il risultato dell'ultima chiamata" },
        ],
      },
      {
        id: "record",
        title: "Registra una chiamata",
        blocks: [
          {
            ul: [
              "Durante una chiamata, tocca **⋮ › Registra** nella schermata di chiamata di One Dialer. Toccalo di nuovo per fermare. La registrazione si ferma anche da sola a fine chiamata.",
              "La prima volta One Dialer mostra un breve avviso sul consenso. La registrazione inizia quando lo accetti.",
              "Per registrare in automatico, apri **Impostazioni › Registrazione chiamate** di One Dialer. La registrazione automatica può essere disattivata, per ogni chiamata, solo per i numeri sconosciuti o solo per i contatti che scegli, e un elenco **Non registrare mai** esclude i contatti scelti.",
            ],
          },
        ],
      },
      {
        id: "recordings",
        title: "Le tue registrazioni",
        blocks: [
          {
            p: "Le trovi in One Dialer in **Chiamate › ⋮ › Registrazioni**, o in **Impostazioni › Registrazione chiamate**. Sono raggruppate per giorno, con il nome del contatto, e puoi cercarle, filtrarle (Tutti, Preferiti, Contatti, Sconosciuti), riprodurle, aggiungerle ai preferiti, rinominarle, condividerle o eliminarle.",
          },
          { shot: "rec-recordings", alt: "Le registrazioni in One Dialer" },
          {
            p: "I file restano dentro One Recorder. **Salva sul telefono** ne copia uno nella cartella `Recordings/One Dialer` del telefono, dove le altre app possono vederlo. L'**Eliminazione automatica** può cancellare le registrazioni dopo 30 o 90 giorni, tenendo sempre quelle con la stella.",
          },
        ],
      },
      {
        id: "how",
        title: "Come funziona",
        blocks: [
          {
            p: "Il modo più pulito per registrare una chiamata è direttamente dalla linea, con entrambe le voci a pieno volume. Android lo riserva alle app integrate nel telefono e alla **shell**: l'account con cui girano gli strumenti di debug di Android. Il Debug wireless permette a un'app sul telefono di avviare un programma con quell'account, come fa Shizuku.",
          },
          {
            p: "È quello che fa **Registra entrambe le voci**. Una volta associato, One Recorder avvia dalla propria app un piccolo servizio come shell. Il servizio fa una cosa sola: finché One Recorder lo chiede, registra la chiamata e restituisce l'audio tramite una connessione privata dentro il telefono di cui solo One Recorder ha la chiave. Si ferma quando One Recorder viene aggiornato o rimosso.",
          },
          { p: "One Dialer dice a One Recorder quando iniziare e fermarsi. One Recorder registra l'audio, tiene i file e risponde solo al One Dialer firmato da Play." },
        ],
      },
      {
        id: "nomic",
        title: "Perché non c'è il metodo con il microfono",
        blocks: [
          {
            p: "Le versioni precedenti potevano registrare anche con il microfono, tramite un servizio di accessibilità. Da Android 10, un'app che usa il microfono durante una chiamata riceve silenzio, e Android fa un'eccezione solo per alcune app di accessibilità, in casi limitati. I produttori chiudono anche quelli: sul telefono che abbiamo provato, un vivo con Android 17, le registrazioni fatte così erano mute, con Android che silenziava il microfono per tutta la chiamata.",
          },
          {
            p: "Un metodo che in silenzio non registra nulla è peggio di nessuno, quindi è stato tolto, insieme al permesso del microfono, a quel servizio di accessibilità e alle impostazioni Aumento volume e Sorgente microfono che usava solo lui. Registrare entrambe le voci tramite il Debug wireless è ora l'unico modo, e registra entrambe le voci a pieno volume.",
          },
        ],
      },
      {
        id: "privacy",
        title: "Privacy",
        blocks: [
          { p: "Questa traduzione è per comodità: fa fede il testo inglese di questa pagina." },
          {
            p: "One Recorder registra solo mentre è in corso una chiamata che hai scelto di registrare. L'audio viene salvato solo dentro One Recorder sul telefono. Non viene mai caricato, non c'è un account e nulla su di te o sulle tue chiamate lascia il telefono, a meno che tu non condivida una registrazione. Le registrazioni vengono cancellate quando le elimini o disinstalli One Recorder.",
          },
          {
            p: "L'associazione con il Debug wireless è una chiave conservata nella memoria privata di One Recorder sul telefono; non può essere inclusa nei backup né letta da altre app. Il servizio registra solo chiamate per One Recorder e non può eseguire altro, a parte disattivare e riattivare le Opzioni sviluppatore e il debug. One Recorder non ha il permesso del microfono. Il suo servizio di accessibilità facoltativo per l'associazione legge solo l'app Impostazioni, non tocca mai nulla e si disattiva una volta associato o dopo cinque minuti. Dispositivi nelle vicinanze o Posizione viene chiesto solo se attivi Avvia senza Wi-Fi, per aprire l'hotspot locale. Le leggi sulla registrazione cambiano da paese a paese, e sei responsabile di ottenere il consenso dell'altra persona dove è richiesto.",
          },
          {
            p: "**Note legali.** One Recorder è fornito così com'è, senza alcuna garanzia. Può registrare entrambe le voci di una chiamata, e le leggi sulla registrazione delle chiamate cambiano da paese a paese e da regione a regione: in alcuni posti tutti i partecipanti devono essere d'accordo, in altri registrare non è consentito affatto. Sei l'unico responsabile di conoscere e rispettare le leggi del luogo in cui ti trovi tu e quello dell'altra persona, di informarla e di ottenere il suo consenso dove è richiesto, e di come usi le tue registrazioni. Syed Arham Raza, che realizza One Recorder e One Dialer, non è responsabile di come la usi né delle registrazioni che fai con essa.",
          },
        ],
      },
      {
        id: "legal",
        title: "Note legali",
        blocks: [
          { p: "Questa traduzione è per comodità: fa fede il testo inglese di questa pagina." },
          {
            p: "One Recorder è fornito così com'è, senza alcuna garanzia. Può registrare entrambe le voci di una chiamata, e le leggi sulla registrazione delle chiamate cambiano da paese a paese e da regione a regione: in alcuni posti tutti i partecipanti devono essere d'accordo, in altri registrare non è consentito affatto. Sei l'unico responsabile di conoscere e rispettare le leggi del luogo in cui ti trovi tu e quello dell'altra persona, di informarla e di ottenere il suo consenso dove è richiesto, e di come usi le tue registrazioni. Syed Arham Raza, che realizza One Recorder e One Dialer, non è responsabile di come la usi né delle registrazioni che fai con essa.",
          },
        ],
      },
      {
        id: "setups",
        title: "Configurazioni per le situazioni comuni",
        blocks: [
          {
            setup: "Uso app bancarie",
            when: "Vuoi la registrazione e la tua app bancaria sullo stesso telefono.",
            steps: [
              "Lascia attivo **Disattiva Opzioni sviluppatore** (è l'impostazione predefinita).",
              "Lascia disattivato **Continua a registrare senza Wi-Fi**: tiene acceso il debug USB.",
              "Se la riga dice che il tuo telefono ha bisogno di un debug attivo, prova comunque l'app bancaria: molte controllano solo le Opzioni sviluppatore.",
            ],
          },
          {
            setup: "Voglio registrare anche senza Wi-Fi",
            when: "Il servizio di registrazione si ferma quando il Wi-Fi se ne va, perché il debug wireless ha bisogno del Wi-Fi.",
            steps: [
              "Attiva **Continua a registrare senza Wi-Fi**. Tiene acceso il debug USB, così il servizio continua a funzionare con i dati mobili.",
              "Alcune app bancarie non si aprono mentre è attivo.",
            ],
          },
          { shot: "rec-away-wifi", alt: "Continua a registrare senza Wi-Fi" },
          {
            setup: "Il mio telefono si riavvia spesso lontano dal Wi-Fi",
            when: "Dopo un riavvio il servizio aspetta il Wi-Fi prima di partire.",
            steps: [
              "Controlla che **Avvio dopo il riavvio** dica che parte da solo.",
              "Da Android 12 a 16, prova **Avvia senza Wi-Fi (sperimentale)**. Richiede la Posizione attiva e potrebbe non funzionare su tutti i telefoni.",
            ],
          },
          {
            setup: "Le mie registrazioni sono mute o basse",
            when: "Una registrazione non ha suono, o l'altra persona si sente poco.",
            steps: [
              "Tocca **Verifica ora**. Se non funziona tutto, sistema il passaggio che indica.",
              "Prova la stessa chiamata sulla rete mobile invece che con le chiamate via Wi-Fi.",
              "Ancora niente: **Condividi diagnostica** e invialo con una segnalazione.",
            ],
          },
        ],
      },
      {
        id: "trouble",
        title: "Se non funziona",
        blocks: [
          {
            ul: [
              "**One Dialer dice che la registrazione è in pausa, o il servizio è Non attivo:** il telefono si è riavviato lontano dal Wi-Fi, o le Opzioni sviluppatore sono state disattivate. Connettiti al Wi-Fi e avvia il servizio in One Recorder. Finché non è attivo, le chiamate non si possono registrare.",
              "**Il codice di associazione non viene accettato:** lascia aperta la finestra di associazione mentre scrivi il codice, sulla stessa rete Wi-Fi. Se non funziona ancora, chiudi la finestra, riaprila per un nuovo codice e riprova.",
              "**La registrazione ha una sola voce, o niente:** alcuni telefoni perdono una voce con le chiamate via Wi-Fi, e alcuni non permettono affatto di registrare la linea. Prova la stessa chiamata sulla rete mobile.",
              "**One Dialer dice che le chiamate non vengono registrate:** la registrazione automatica è attiva ma One Recorder non è pronto. Aprilo e sistema ogni riga che non è Pronto, di solito il servizio.",
              "**One Dialer dice che il registratore funziona solo con One Dialer da Google Play:** One Dialer è stata installata da file, o è precedente alla 1.0.0-beta.9. Installala da Google Play, o aggiorna entrambe le app.",
              "**Nessuna opzione Registra nella schermata di chiamata:** One Recorder non è installato. One Dialer nasconde tutto ciò che riguarda la registrazione finché non lo è.",
              "**Un'app bancaria continua a non aprirsi:** il tuo telefono ha bisogno che il debug USB o wireless resti attivo (la riga Disattiva Opzioni sviluppatore di One Recorder dice quale). Disattiva **Continua a registrare senza Wi-Fi** se è attivo, perché tiene acceso il debug USB.",
              "**Ancora bloccato:** tocca **Condividi diagnostica** in One Recorder e invia il rapporto con la tua segnalazione. Contiene versioni, modello del telefono, stato della configurazione e righe di log recenti, senza numeri né nomi.",
            ],
          },
        ],
      },
      {
        id: "update",
        title: "Aggiornala o rimuovila",
        blocks: [
          {
            ul: [
              "**Per aggiornarla,** apri One Recorder › **Aggiornamento software**. Mentre il servizio di registrazione è attivo, installa da solo la nuova versione, senza chiedere; altrimenti la scarica perché tu la installi. Puoi anche scaricare l'APK da questa pagina e installarlo sopra quello vecchio. Registrazioni e impostazioni restano.",
              "**Per rimuoverla,** disinstalla One Recorder come qualsiasi app. Così si cancellano tutte le registrazioni al suo interno, quindi salva prima sul telefono quelle che vuoi tenere. One Dialer continua a funzionare e nasconde di nuovo le opzioni di registrazione.",
              "Le leggi sulla registrazione cambiano da paese a paese. In alcuni tutti i partecipanti devono essere d'accordo. Sei responsabile di informare l'altra persona e di ottenere il suo consenso dove è richiesto.",
            ],
          },
        ],
      },
    ],
  },
};
