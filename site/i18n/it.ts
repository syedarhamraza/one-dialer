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
  },
  nav: {
    label: "Sito",
    whatsNew: "Novità",
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
    recorder: "One Recorder",
    privacy: "Informativa sulla privacy (inglese)",
    contact: "Contatti",
    language: "Lingua",
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
      "Nessun permesso del microfono e nessun servizio di accessibilità. One Recorder registra la chiamata stessa, solo durante le chiamate che registri.",
      "Le registrazioni restano sul telefono. Non viene caricato nulla, non c'è un account e non ci sono pubblicità.",
      "Registra quando vuoi tu o in automatico: ogni chiamata, i numeri sconosciuti o solo i contatti che scegli.",
      "Le registrazioni vivono in One Dialer, con nomi dei contatti, ricerca, stelle, condivisione ed eliminazione automatica.",
      "Open source, come One Dialer. Chiunque può verificare cosa fa.",
    ],
    consTitle: "Cosa aspettarsi",
    cons: [
      "Per entrambe le voci servono le Opzioni sviluppatore e il Debug wireless attivati una volta, e il Wi-Fi ogni volta che si avvia. Se dopo un riavvio non riesce a ripartire (niente Wi-Fi, o Opzioni sviluppatore disattivate), tocchi Avvia in One Recorder.",
      "Alcune app di banche e pagamenti non si aprono finché le Opzioni sviluppatore sono attive.",
      "Su alcuni telefoni, le chiamate via Wi-Fi registrano una sola voce. Dipende dal driver audio del telefono, non da One Recorder.",
      "Serve Android 12 o successivo. Android 10 e 11 non possono avviare il servizio tramite il Debug wireless, e lì non c'è altro modo di registrare.",
      "Non si aggiorna da sola. Google Play non la conosce, quindi torni qui per le nuove versioni.",
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
          { p: "Apri One Recorder: **Registra entrambe le voci** è in cima, e ogni riga diventa Pronto man mano che procedi." },
          {
            ol: [
              "**Opzioni sviluppatore.** Se sono disattivate, apri **Impostazioni › Info telefono** (su alcuni telefoni Info telefono › Informazioni software) e tocca **Numero build** sette volte.",
              "**Associa con il Debug wireless.** Tocca la riga. One Recorder apre le Opzioni sviluppatore e mostra una notifica. Attiva **Debug wireless**, aprilo e tocca **Associa dispositivo con codice di accoppiamento**.",
              "Lascia il codice sullo schermo, abbassa la notifica di One Recorder, tocca **Inserisci codice** e scrivi le sei cifre. One Recorder si associa e avvia il suo servizio. L'associazione si fa una volta sola.",
              "**Servizio di registrazione: pronto.** Se dice Non attivo, assicurati di essere sul Wi-Fi e tocca la riga per avviarlo. **Avvio dopo il riavvio** si attiva da solo al primo avvio del servizio.",
            ],
          },
          {
            p: "Puoi disattivare di nuovo il Debug wireless: One Recorder lo accende per un momento quando deve avviare il servizio, e poi lo spegne. Se il tuo telefono ferma il servizio quando il Debug wireless si spegne, One Recorder lo lascia acceso.",
          },
        ],
      },
      {
        id: "setup",
        title: "Notifiche e batteria",
        blocks: [
          {
            ol: [
              "**Notifiche.** Consentile, così vedi quando una chiamata viene registrata.",
              "**Batteria: senza restrizioni.** Facoltativo ma consigliato. Impedisce al telefono di chiudere il registratore mentre aspetta una chiamata.",
            ],
          },
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
            p: "Un metodo che in silenzio non registra nulla è peggio di nessuno, quindi è stato tolto, insieme al permesso del microfono, al servizio di accessibilità e alle impostazioni Aumento volume e Sorgente microfono che usava solo lui. Registrare entrambe le voci tramite il Debug wireless è ora l'unico modo, e registra entrambe le voci a pieno volume.",
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
            p: "L'associazione con il Debug wireless è una chiave conservata nella memoria privata di One Recorder sul telefono; non può essere inclusa nei backup né letta da altre app. Il servizio registra solo chiamate per One Recorder e non può eseguire altro. One Recorder non ha il permesso del microfono né un servizio di accessibilità. Le leggi sulla registrazione cambiano da paese a paese, e sei responsabile di ottenere il consenso dell'altra persona dove è richiesto.",
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
              "**Per aggiornarla,** scarica di nuovo l'APK da questa pagina e installalo sopra quello vecchio. Registrazioni e impostazioni restano.",
              "**Per rimuoverla,** disinstalla One Recorder come qualsiasi app. Così si cancellano tutte le registrazioni al suo interno, quindi salva prima sul telefono quelle che vuoi tenere. One Dialer continua a funzionare e nasconde di nuovo le opzioni di registrazione.",
              "Le leggi sulla registrazione cambiano da paese a paese. In alcuni tutti i partecipanti devono essere d'accordo. Sei responsabile di informare l'altra persona e di ottenere il suo consenso dove è richiesto.",
            ],
          },
        ],
      },
    ],
  },
};
