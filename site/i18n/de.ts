import type { Dict } from "./en";

// German, informal "du" like the app. Labels match lib/l10n/app_de.arb and One Recorder's values-de.
export const de: Dict = {
  meta: {
    title: "One Dialer · Telefon und Anrufblocker für Android",
    description: "Schnelle T9-Wähltastatur mit Anrufblockierung, Dual-SIM und einem Design aus Milchglas.",
    released: "Kostenlos bei Google Play.",
    beta: "Jetzt in der geschlossenen Beta bei Google Play.",
    recorderTitle: "One Recorder · One Dialer",
    recorderDescription: "Nimm deine Anrufe in One Dialer mit One Recorder auf, einer kleinen Begleit-App, die du von dieser Website installierst. Wie du sie einrichtest und was dich erwartet.",
    guideTitle: "Anleitung · One Dialer",
    guideDescription: "So nutzt du One Dialer: SIMs, Anrufe aus der Anrufliste, Wähltastatur, Kontakte, Blockieren, Anrufbildschirm und Effekte, mit Einstellungen für typische Situationen.",
  },
  nav: {
    label: "Website",
    whatsNew: "Neuigkeiten",
    guide: "Anleitung",
    recorder: "Recorder",
    privacy: "Datenschutz",
    getApp: "App holen",
    joinBeta: "Zur Beta",
    beta: "Beta",
  },
  stage: {
    headline: ["Anrufe,", "aus", "Glas."],
    intro: "Eine schnelle, private Telefon-App für Android. Smartes T9, Anrufblockierung und Dual-SIM, auf echtem Schwarz.",
    small: "Kostenlos · Keine Werbung · Android 10 und neuer",
    screens: "Bildschirme",
    alt: "Bildschirm {title} in One Dialer",
  },
  screens: [
    { title: "Tastatur", body: "Milchglas-Tasten über deinen Anrufen, mit einer Anruftaste für jede SIM." },
    { title: "Anrufe", body: "Verpasste Anrufe in Rot, wiederholte gruppiert, blockierte markiert. Die Tastatur ist einen Tipp entfernt." },
    { title: "Kontakte", body: "Zuerst die Favoriten, dann ein A–Z-Index unter deinem Daumen." },
    { title: "Eingehend", body: "Im Vollbild, in den Farben des Anrufers, direkt auf dem Sperrbildschirm." },
    { title: "Im Anruf", body: "Große Glas-Schaltflächen für Stumm, Halten, Lautsprecher und Tastatur." },
  ],
  does: {
    h: "Was sie kann.",
    h2: "Und was nicht.",
    items: [
      { title: "Blockt, bevor es klingelt", text: "Unterdrückte Nummern, Unbekannte oder alle, die nicht in deinen Kontakten sind. Dazu die Sperrliste deines Telefons." },
      { title: "Dual-SIM, richtig gemacht", text: "Eine SIM pro Kontakt, eine Standard-SIM oder jedes Mal fragen. Die Anruftaste zeigt, welche SIM du nutzt." },
      { title: "Eine echte Telefon-App", text: "Jeder Anruf läuft über das Telecom-Framework von Android, also verhalten sich Anrufe genau wie in der System-App." },
      { title: "Bleibt auf deinem Telefon", text: "Kein Konto, keine Werbung. Deine Anrufe und Kontakte verlassen nie das Gerät." },
      { title: "Open Source", text: "GPL-3.0. Lies den Code, melde einen Fehler oder füge deine Sprache hinzu." },
    ],
    github: "One Dialer auf GitHub",
  },
  smooth: {
    h: "Flüssig auf",
    h2: "jedem Telefon.",
    text: "Beim ersten Start liest One Dialer den Chip deines Telefons und wählt eine Stufe für visuelle Effekte, die du in den Einstellungen ändern kannst. Probier die drei Stufen hier aus: Das Glas dieser Seite folgt, samt Tastatur und der Glasplatte oben.",
  },
  levels: {
    label: "Visuelle Effekte",
    full: { label: "Alle", text: "Milchglas mit leuchtendem Rand. Top-Chips starten hier." },
    reduced: { label: "Weniger", text: "Eine flache, durchscheinende Füllung über einer einzigen geteilten Unschärfe. Mittelklasse-Chips starten hier." },
    off: { label: "Aus", text: "Deckende Flächen und gar keine Unschärfe. Einsteiger-Chips und Telefone mit wenig Speicher starten hier." },
  },
  keypad: {
    hint: "Tipp 3662 auf den Tasten",
    none: "Niemand mit diesem Namen oder dieser Nummer.",
    delete: "Löschen",
  },
  whatsNew: {
    h: "Neuigkeiten.",
    beta: "Beta {n}",
    version: "Version {v}",
    note: "Die Versionshinweise gibt es nur auf Englisch.",
  },
  get: {
    h: "Hol dir One Dialer.",
    h2: "Kostenlos bei Google Play.",
    text: "Installiere sie wie jede andere App und lege One Dialer dann als Standard-Telefon-App fest, wenn sie fragt. Android 10 und neuer.",
  },
  join: {
    h: "Mach bei der Beta mit.",
    h2: "Zwei Schritte.",
    text: "One Dialer ist im geschlossenen Test bei Google Play. Tritt der Testergruppe bei und installiere die App dann wie jede andere aus Play.",
    step: "Schritt {n}: ",
    group: {
      title: "Tritt der Google Group bei",
      text: "Öffne die Gruppe und tippe auf Gruppe beitreten. Damit steht dein Google-Konto auf der Testerliste.",
      note: "Nutze dasselbe Google-Konto, mit dem du im Play Store deines Telefons angemeldet bist.",
      cta: "Gruppe beitreten",
    },
    tester: {
      title: "Werde Tester bei Google Play",
      text: "Öffne die Testseite, tippe auf Tester werden, dann auf Bei Google Play herunterladen und installiere sie.",
      note: "Nach dem Beitritt zur Gruppe kann es ein paar Minuten dauern, bis dich diese Seite hereinlässt.",
      cta: "Tester werden",
    },
  },
  apk: {
    title: "Hast du One Dialer als APK-Datei?",
    text: "Als Datei geteilte oder von einer anderen App aus einem Telefon gezogene Kopien sind nicht offiziell. Sie bekommen keine Updates und könnten verändert sein.",
    released: "Deinstalliere sie und installiere die App stattdessen von Google Play.",
    beta: "Deinstalliere sie und mach stattdessen hier mit.",
  },
  faq: {
    h: "Fragen,",
    h2: "beantwortet.",
    items: [
      {
        beta: true,
        q: "Warum eine geschlossene Beta?",
        a: "Google Play verlangt, dass neue Apps von einer Gruppe getestet werden, bevor sie öffentlich werden. Mitmachen hilft One Dialer dorthin, und du bekommst jedes Update zuerst.",
      },
      {
        beta: true,
        q: "Der Play-Link sagt, die App ist nicht verfügbar.",
        a: "Achte darauf, dass du der Google Group mit demselben Google-Konto beigetreten bist, mit dem du im Play Store deines Telefons angemeldet bist. Nach dem Beitritt kann es ein paar Minuten dauern, bis der Testlink funktioniert.",
      },
      { q: "Auf welchen Telefonen läuft sie?", a: "Android 10 oder neuer. Um Anrufe zu tätigen und anzunehmen, lege One Dialer als Standard-Telefon-App fest, wenn sie fragt." },
      { q: "Ist sie kostenlos? Gibt es Werbung?", a: "Sie ist kostenlos und hat keine Werbung." },
      {
        q: "Verlassen meine Anrufe und Kontakte mein Telefon?",
        a: "Nein. Anrufliste und Kontakte bleiben auf deinem Telefon. Die Datenschutzerklärung führt genau auf, was gesendet wird, etwa Absturzberichte.",
      },
      {
        q: "Ich habe One Dialer als APK-Datei.",
        a: "Diese Kopie ist nicht offiziell: Sie bekommt keine Updates und könnte verändert sein. Deinstalliere sie und installiere One Dialer dann von Google Play.",
        aBeta: "Diese Kopie ist nicht offiziell: Sie bekommt keine Updates und könnte verändert sein. Deinstalliere sie und tritt dann hier der Beta bei, um sie von Google Play zu bekommen.",
      },
      { beta: true, q: "Wie verlasse ich die Beta?", a: "Öffne den Testlink bei Google Play und wähle Programm verlassen. Deinstalliere die App danach, wenn du möchtest." },
    ],
  },
  play: "Bei Google Play holen",
  footer: {
    bug: "Einen Fehler gefunden?",
    idea: "Eine Idee?",
    feature: "Funktion vorschlagen",
    report: "Fehler melden",
    label: "Fußzeile",
    guide: "Anleitung",
    recorder: "One Recorder",
    privacy: "Datenschutzerklärung (Englisch)",
    contact: "Kontakt",
    language: "Sprache",
  },
  guide: {
    back: "Zurück zu One Dialer",
    title: "Anleitung",
    h1: "One Dialer,",
    h1b: "erklärt.",
    lead: "Wo alles ist, was jede Einstellung macht, und welche Einstellungen zu deiner Situation passen.",
    toc: "Auf dieser Seite",
    intro: "Bilder und kurze Aufnahmen zeigen jeden Schritt. Die Einstellungen findest du im ⋮-Menü des Tabs Anrufe.",
    sections: [
      {
        id: "start",
        title: "Erste Schritte",
        blocks: [
          {
            ol: [
              "Öffne One Dialer und tippe auf **Als Standard festlegen**, damit es deine **Standard-Telefon-App** wird. Anrufe, Anrufliste und Benachrichtigungen über verpasste Anrufe funktionieren nur dann.",
              "Erlaube **Kontakte**, **Telefon** und **Benachrichtigungen**, wenn Android fragt.",
              "Öffne **Einstellungen**. Stimmt etwas nicht, steht oben eine Karte **Erfordert Aufmerksamkeit**, etwa „Nicht deine Standard-Telefon-App“ oder ausgeschaltete Benachrichtigungen, mit einer Taste **Beheben**, die dich direkt hinbringt.",
            ],
          },
          { shot: "start-default", alt: "One Dialer als Standard-Telefon-App festlegen" },
          { shot: "settings-health", alt: "Einstellungen mit der Karte Erfordert Aufmerksamkeit und Beheben-Tasten" },
        ],
      },
      {
        id: "calls",
        title: "Anrufe und letzte Anrufe",
        blocks: [
          { p: "Der Tab **Anrufe** zeigt deine letzten Anrufe. Verpasste sind rot, wiederholte werden gruppiert und blockierte markiert." },
          { p: "Was ein Tippen auf einen Anruf macht, legst du in **Einstellungen › Schnell anrufen › Auf letzten Anruf tippen** fest:" },
          {
            ul: [
              "**Details öffnen**: die sichere Wahl. Die Seite des Anrufs öffnet sich, mit Nummer, früheren Anrufen, Notizen und einer Anruftaste.",
              "**Anrufen**: ruft sofort zurück. Schnell, aber leicht aus Versehen.",
              "**In Wähltastatur schreiben**: setzt die Nummer in die Wähltastatur, damit du sie vor dem Anruf prüfen oder ändern kannst.",
            ],
          },
          { shot: "recents-tap", alt: "Die Einstellung Auf letzten Anruf tippen mit Anrufen, Details öffnen und In Wähltastatur schreiben" },
          {
            ul: [
              "**Anruftaste in Zeilen** setzt eine Anruftaste in jede Zeile, sodass ein Tippen die Details öffnet und die Taste anruft. **Stil der Anruftaste** ändert ihr Aussehen.",
              "**Wischen zum Anrufen oder Schreiben**: eine Zeile nach rechts wischen ruft an, nach links schreibt eine Nachricht.",
              "**Nach Kontakt gruppieren** fasst die Anrufe einer Person zusammen.",
              "Halte eine Zeile gedrückt, um mehrere Anrufe auszuwählen, etwa um sie zu löschen.",
            ],
          },
          { shot: "recents-swipe", alt: "Einen letzten Anruf nach rechts wischen, um anzurufen" },
        ],
      },
      {
        id: "sims",
        title: "Zwei SIMs",
        blocks: [
          { p: "Mit zwei SIMs legt **Einstellungen › SIM-Karten** fest, welche jeder Anruf nutzt. Das wählst du getrennt für:" },
          {
            ul: [
              "**Wähltastatur und Kontakte**: **Standard-SIM des Telefons** oder **Jedes Mal fragen**, das beim Anrufen eine SIM-Auswahl zeigt.",
              "**Auf letzten Anruf tippen** und **Wischen zum Anrufen**: **Wie Wähltastatur**, **Zuletzt genutzte SIM** (die SIM dieses Anrufs), **Jedes Mal fragen** oder immer eine SIM. Sie gelten nur, wenn diese Art zu anrufen unter Schnell anrufen eingeschaltet ist.",
            ],
          },
          { shot: "sim-settings", alt: "Einstellungen SIM-Karten" },
          { p: "Ein Kontakt kann **eine eigene SIM** haben: Öffne seine Seite und wähle sie. Sie geht immer vor, vor jeder Regel oben." },
          { shot: "sim-contact", alt: "Eine SIM auf der Seite eines Kontakts wählen" },
          { p: "Auf der Wähltastatur zeigt **Einstellungen › Wähltastatur › Zwei Anruftasten** eine Anruftaste pro SIM statt einer, damit du beim Anrufen wählst." },
          { shot: "sim-chooser", alt: "Die SIM-Auswahl beim Anrufen mit Jedes Mal fragen" },
        ],
      },
      {
        id: "keypad",
        title: "Wähltastatur",
        blocks: [
          {
            ul: [
              "Tippe Ziffern oder Buchstaben: Passende Kontakte erscheinen beim Tippen (**T9**). Tippe einen an, um ihn anzurufen oder zu öffnen.",
              "Halte **1** für die Mailbox und **2–9** für Kurzwahl. Kurzwahl stellst du in **Einstellungen › Wähltastatur › Kurzwahl** ein.",
              "Halte **0** für **+**. Halte die Sterntaste (*) für eine Pause und **#** für ein Warten, für Nummern mit Durchwahl.",
              "Halte die Nummer gedrückt, um eine kopierte einzufügen. Halte **Löschen**, um sie zu leeren.",
              "Wische die Wähltastatur nach unten oder tippe auf den Griff, um deine Anrufe zu sehen. Die grüne Taste neben der Navigationsleiste holt sie mit deiner Nummer zurück.",
            ],
          },
          { shot: "keypad-t9", alt: "Tippen auf der Wähltastatur mit passenden Kontakten" },
          { shot: "keypad-speed-dial", alt: "Kurzwahl-Einstellungen" },
        ],
      },
      {
        id: "contacts",
        title: "Kontakte",
        blocks: [
          {
            ul: [
              "Favoriten stehen oben unter ★. Fahre am **A–Z**-Index rechts entlang, um zu springen.",
              "Tippe auf einen Kontakt für seine Seite: Nummern, eigene SIM, Anrufhintergrund und Blockieren. Gedrückt halten wählt mehrere aus.",
              "**⋮ › Kontakte verwalten** legt fest, welche Konten erscheinen, Sortierung und Namensformat, wo neue Kontakte gespeichert werden, Import und Export, SIM-Kontakte und **Doppelte Kontakte zusammenführen**.",
            ],
          },
          { shot: "contacts-index", alt: "Kontakte mit Favoriten und A–Z-Index" },
          { shot: "contacts-manage", alt: "Kontakte verwalten" },
        ],
      },
      {
        id: "blocking",
        title: "Blockieren",
        blocks: [
          {
            ul: [
              "Blockiere eine Nummer auf der Seite des Anrufs oder des Kontakts. **Einstellungen › Blockieren & filtern › Blockierte Nummern** listet sie auf; Android selbst lehnt diese Anrufe ab.",
              "**Unbekannte/private Nummern blockieren** stoppt Anrufer, die ihre Nummer verbergen. **Anrufe von Nummern außerhalb der Kontakte blockieren** lässt nur deine Kontakte klingeln.",
              "Diese beiden Regeln brauchen One Dialer als **App für Anrufer-ID und Spam**. One Dialer fragt danach, wenn du eine einschaltest. Übernimmt eine andere App diese Rolle, zeigen die Einstellungen „Blockierregeln sind pausiert“.",
              "**Blockierte Anrufe ausblenden** hält sie aus der Anrufliste heraus.",
            ],
          },
          { shot: "blocking-rules", alt: "Einstellungen Blockieren & filtern" },
        ],
      },
      {
        id: "callscreen",
        title: "Der Anrufbildschirm",
        blocks: [
          {
            ul: [
              "Eingehende Anrufe füllen den Bildschirm, auch auf dem Sperrbildschirm. **Einstellungen › Anrufbildschirm** legt fest, wie du annimmst (nach oben oder unten wischen oder Tasten), die Effekte, das Foto des Anrufers und den Hintergrund.",
              "Während eines Anrufs: Stumm, Halten, Lautsprecher, Wähltastatur und Anruf hinzufügen liegen auf großen Glastasten. **⋮** hat mehr, etwa Aufnehmen, wenn One Recorder installiert ist.",
              "**Ablehnungsnachrichten** sind die Texte, die du senden kannst, wenn du einen Anruf ablehnst.",
              "**Anrufe annehmen und beenden** hat automatische Annahme, Antwort per SMS und Lautsprecher. **Nummern von Kontakten ausblenden** zeigt bei gespeicherten Kontakten nur den Namen.",
            ],
          },
          { shot: "call-incoming", alt: "Ein eingehender Anruf auf dem Sperrbildschirm" },
          { shot: "call-controls", alt: "Tasten während des Anrufs" },
        ],
      },
      {
        id: "look",
        title: "Aussehen und Tempo",
        blocks: [
          { p: "**Einstellungen › Anzeige & Effekte › Visuelle Effekte reduzieren** legt fest, wie viel Glas und Unschärfe die App zeichnet. One Dialer wählt beim ersten Start eine Stufe für dein Telefon; du kannst sie jederzeit ändern:" },
          {
            ul: [
              "**Alle Effekte**: alles wie entworfen, Glas und Unschärfe.",
              "**Weniger Effekte**: flacheres Glas, viel weniger Arbeit für das Telefon.",
              "**Effekte aus**: volle Farben, keine Unschärfe. Am schnellsten.",
            ],
          },
          { shot: "effects-levels", alt: "Visuelle Effekte reduzieren: alle, weniger und aus" },
          { p: "Mit allen Effekten kann **Glas & Unschärfe › Glasstil** **Kantenleuchten** sein oder das experimentelle **Flüssigglas**, das den Hintergrund krümmt, aber am meisten Leistung braucht. **Anzeigegröße** macht die App und die Navigationsleiste größer oder kleiner, und der Anrufbildschirm hat eigene **Effekte im Anrufbildschirm**." },
          { shot: "glass-style", alt: "Glasstil: Kantenleuchten und Flüssigglas" },
        ],
      },
      {
        id: "more",
        title: "Sprache, Sicherung und Updates",
        blocks: [
          {
            ul: [
              "**Einstellungen › Sprache › App-Sprache** ändert nur die Sprache von One Dialer. **Wie Telefon** folgt Android.",
              "**Sichern & wiederherstellen** speichert deine Einstellungen, Kurzwahl, Anrufnotizen und Anrufhintergründe in einer Datei, für ein neues Telefon oder eine Neuinstallation.",
              "**Software-Update** zeigt, wenn eine neue Version auf Google Play ist, mit den Neuerungen.",
            ],
          },
          { shot: "settings-language", alt: "Einstellungen der App-Sprache" },
        ],
      },
      {
        id: "setups",
        title: "Einstellungen für typische Situationen",
        blocks: [
          { p: "Such dir die Situation aus, die zu dir passt, und ändere diese Einstellungen." },
          {
            setup: "Ich rufe Leute aus Versehen an",
            when: "Ein Tippen auf einen letzten Anruf oder ein Wischen beim Scrollen startet einen Anruf, den du nicht wolltest.",
            steps: [
              "**Einstellungen › Schnell anrufen › Auf letzten Anruf tippen** → **Details öffnen**.",
              "Schalte **Wischen zum Anrufen oder Schreiben** aus.",
              "Optional: Schalte **Anruftaste in Zeilen** ein, dann ist Anrufen ein bewusstes Tippen auf die Taste.",
            ],
          },
          { shot: "setup-no-accidents", alt: "Schnell anrufen so eingestellt, dass keine versehentlichen Anrufe passieren" },
          {
            setup: "Arbeits-SIM und private SIM",
            when: "Arbeitskontakte sollen über eine SIM laufen, alle anderen über die andere, ohne jedes Mal zu wählen.",
            steps: [
              "**Einstellungen › SIM-Karten › Wähltastatur und Kontakte** → deine private SIM (oder Standard-SIM des Telefons).",
              "Wähle auf der Seite jedes Arbeitskontakts die **Arbeits-SIM**. Sie gewinnt immer.",
              "**Auf letzten Anruf tippen** → **Zuletzt genutzte SIM**, damit ein Rückruf die SIM nutzt, über die der Anruf kam.",
            ],
          },
          { shot: "setup-two-sims", alt: "SIM-Einstellungen für Arbeit und Privates" },
          {
            setup: "Ich weiß nie, welche SIM benutzt wird",
            when: "Zwei SIMs, und du entscheidest lieber bei jedem Anruf.",
            steps: [
              "**Einstellungen › SIM-Karten › Wähltastatur und Kontakte** → **Jedes Mal fragen**.",
              "Schalte **Einstellungen › Wähltastatur › Zwei Anruftasten** ein, dann zeigt die Wähltastatur eine Taste pro SIM.",
            ],
          },
          {
            setup: "Mein Telefon fühlt sich langsam an",
            when: "Scrollen ruckelt oder der Anrufbildschirm öffnet sich langsam.",
            steps: [
              "**Einstellungen › Anzeige & Effekte › Visuelle Effekte reduzieren** → **Weniger Effekte**, auf einem älteren Telefon **Effekte aus**.",
              "**Glasstil** → **Kantenleuchten** (nicht Flüssigglas).",
              "Senke auch die **Effekte im Anrufbildschirm**.",
            ],
          },
          { shot: "setup-slow-phone", alt: "Visuelle Effekte reduzieren auf Weniger Effekte" },
          {
            setup: "Nur Leute, die ich kenne, sollen anrufen",
            when: "Spam, private oder unbekannte Nummern.",
            steps: [
              "**Einstellungen › Blockieren & filtern** → schalte **Unbekannte/private Nummern blockieren** ein und, wenn du willst, **Anrufe von Nummern außerhalb der Kontakte blockieren**.",
              "Akzeptiere One Dialer als **App für Anrufer-ID und Spam**, wenn danach gefragt wird.",
              "Schalte **Blockierte Anrufe ausblenden** ein, damit die Anrufliste aufgeräumt bleibt.",
            ],
          },
          {
            setup: "Ich möchte Anrufe aufnehmen",
            when: "One Dialer von Google Play nimmt selbst nie auf. Die Aufnahme kommt von einer eigenen App, One Recorder.",
            steps: [
              "Folge der Anleitung zu **One Recorder** auf dieser Website: Das dauert einmalig etwa fünf Minuten.",
            ],
          },
        ],
      },
    ],
  },
  recorder: {
    back: "Zurück zu One Dialer",
    title: "One Recorder",
    h1: "One",
    h1b: "Recorder.",
    lead: "Anrufaufzeichnung für One Dialer. Es ist eine eigene App, damit One Dialer aus Google Play selbst nie etwas aufnimmt.",
    download: "APK herunterladen",
    downloadNote: "Neueste Version, von GitHub Releases · Android 12 oder neuer",
    prosTitle: "Was du bekommst",
    pros: [
      "Beide Seiten des Anrufs in voller Lautstärke, ab Android 12: du und die andere Person, über Hörmuschel, Lautsprecher, Bluetooth oder Kopfhörer. Kein Root, kein Computer, keine eigene Shizuku-App.",
      "Nach einem Neustart startet sie von selbst wieder, sobald du im WLAN bist.",
      "Keine Mikrofonberechtigung. One Recorder nimmt den Anruf selbst auf, nur während eines Anrufs, den du aufnimmst. Sein einziger Bedienungshilfen-Dienst ist optional: Er liest nur den Kopplungscode und schaltet sich dann aus.",
      "Aufnahmen bleiben auf deinem Telefon. Nichts wird hochgeladen, es gibt kein Konto und keine Werbung.",
      "Nimm auf, wann du willst, oder automatisch: jeden Anruf, unbekannte Nummern oder nur Kontakte, die du auswählst.",
      "Deine Aufnahmen leben in One Dialer, mit Kontaktnamen, Suche, Sternen, Teilen und automatischem Löschen.",
      "Open Source, wie One Dialer. Jeder kann prüfen, was sie tut.",
      "Es prüft alle paar Stunden, ob es noch läuft, und startet von selbst neu, wenn es gestoppt wurde.",
      "Nach dem Start schaltet es die Entwickleroptionen selbst wieder aus, damit sich die meisten Banking-Apps öffnen.",
      "Jetzt prüfen testet, ob die Aufnahme wirklich funktioniert, und das Ergebnis des letzten Anrufs zeigt, ob er aufgenommen wurde.",
    ],
    consTitle: "Was dich erwartet",
    cons: [
      "Beide Seiten brauchen einmal eingeschaltete Entwickleroptionen und Drahtloses Debugging, und WLAN bei jedem Start. Kann sie nach einem Neustart nicht wieder starten (kein WLAN, oder Entwickleroptionen aus), startest du sie in One Recorder per Tipp.",
      "Auf manchen Telefonen muss USB- oder drahtloses Debugging eingeschaltet bleiben, damit die Aufnahme weiter funktioniert, und manche Banking-Apps öffnen sich dann trotzdem nicht.",
      "Auf manchen Telefonen nehmen Anrufe über WLAN-Telefonie nur eine Seite auf. Das liegt am Audiotreiber des Telefons, nicht an One Recorder.",
      "Sie braucht Android 12 oder neuer. Android 10 und 11 können den Dienst nicht über Drahtloses Debugging starten, und dort gibt es keinen anderen Weg aufzunehmen.",
      "Es ist nicht auf Google Play. Es sucht selbst auf GitHub nach neuen Versionen und installiert sie über Software-Update.",
      "Sie funktioniert nur mit One Dialer aus Google Play, Version 1.0.0-beta.9 oder neuer, nicht mit einer aus einer Datei installierten Kopie.",
      "Die andere Person erfährt nicht, dass du aufnimmst. Das liegt bei dir, und an manchen Orten ist es ohne ihre Zustimmung verboten.",
    ],
    setup: "Richte sie ein,",
    setupB: "Schritt für Schritt.",
    toc: "Auf dieser Seite",
    intro: "Etwa fünf Minuten, einmal. Danach nimmst du im Anrufbildschirm von One Dialer auf und öffnest One Recorder nie wieder.",
    sections: [
      {
        id: "before",
        title: "Bevor du anfängst",
        blocks: [
          {
            ul: [
              "Ein Telefon mit Android 12 oder neuer, und WLAN für die erste Einrichtung und bei jedem Start des Dienstes.",
              "**One Dialer aus Google Play**, Version 1.0.0-beta.9 oder neuer, als Standard-Telefon-App. One Recorder prüft, dass es mit der offiziellen App spricht, und ignoriert jede andere.",
              "Ein paar Megabyte frei für die App, und Platz für Aufnahmen: etwa ein halbes Megabyte pro Gesprächsminute.",
            ],
          },
        ],
      },
      {
        id: "install",
        title: "Die App installieren",
        blocks: [
          {
            ol: [
              "Tippe auf deinem Telefon oben auf dieser Seite auf **APK herunterladen**. Die Datei heißt `one-dialer-recorder.apk`.",
              "Öffne sie über die Download-Benachrichtigung oder in den Downloads deiner Dateien-App.",
              "Sagt Android, dass dein Browser keine Apps installieren darf, tippe auf **Einstellungen**, schalte **Von dieser Quelle zulassen** ein und geh zurück.",
              "Tippe auf **Installieren**. Google Play Protect bietet vielleicht an, die App zu prüfen, weil sie nicht aus Play kommt. Lass es; es ist dieselbe App, die auf GitHub veröffentlicht ist.",
            ],
          },
        ],
      },
      {
        id: "both",
        title: "Beide Seiten aufnehmen",
        blocks: [
          { p: "Öffne One Recorder: Die Schritte stehen unter **Einrichten**, und jeder bekommt ein grünes Häkchen, sobald er erledigt ist. **Weiter** oben macht immer den nächsten." },
          { shot: "rec-setup", alt: "Die Einrichtungsschritte von One Recorder" },
          {
            ol: [
              "**Benachrichtigungen.** Erlaube sie zuerst: Der Kopplungscode wird in die Benachrichtigung von One Recorder eingegeben.",
              "**Entwickleroptionen.** Wenn sie aus sind, öffne **Einstellungen › Über das Telefon** (auf manchen Telefonen Über das Telefon › Softwareinformationen) und tippe siebenmal auf **Build-Nummer**.",
              "**Mit Drahtlosem Debugging koppeln.** Tippe auf die Zeile. One Recorder öffnet die Entwickleroptionen und zeigt eine Benachrichtigung. Schalte **Drahtloses Debugging** ein, öffne es und tippe auf **Gerät über Kopplungscode koppeln**.",
              "Lass den Code auf dem Bildschirm, zieh die Benachrichtigung von One Recorder herunter, tippe auf **Code eingeben** und gib die sechs Ziffern ein. One Recorder koppelt sich und startet seinen Dienst. Gekoppelt wird nur einmal.",
              "**Oder automatisch koppeln:** Schalte **Automatisch koppeln (optional)** in One Recorder ein. Es liest den Code selbst aus dem Kopplungsdialog und schaltet sich danach aus. Ab Android 13: Ist es ausgegraut, öffne zuerst die App-Info von One Recorder › ⋮ › **Eingeschränkte Einstellungen zulassen**.",
              "**Aufnahmedienst starten.** Läuft er nicht, sorge für WLAN und tippe auf die Zeile. **Nach Neustart starten** schaltet sich beim ersten Start von selbst ein.",
            ],
          },
          { shot: "rec-pair", alt: "Den Kopplungscode in die Benachrichtigung von One Recorder eingeben" },
          { p: "**Akku: Nicht eingeschränkt** ist der letzte Schritt. So schließt das Telefon den Recorder nicht, während er auf einen Anruf wartet." },
        ],
      },
      {
        id: "devoptions",
        title: "Entwickleroptionen und Banking-Apps",
        blocks: [
          { p: "Viele Banking- und Bezahl-Apps öffnen sich nicht, solange Entwickleroptionen, USB-Debugging oder drahtloses Debugging eingeschaltet sind. **Entwickleroptionen ausschalten** ist standardmäßig an: Sobald der Aufnahmedienst läuft, schaltet One Recorder sie nacheinander aus und prüft nach jedem Schritt, ob die Aufnahme noch funktioniert." },
          { p: "Manche Telefone beenden den Aufnahmedienst, wenn USB- oder drahtloses Debugging ausgeht. One Recorder schaltet es dann wieder ein und lässt es an, und die Zeile sagt das. Wenn der Dienst neu starten muss (nach einem Neustart oder zurück im WLAN), schaltet es sie kurz ein und wieder aus." },
          { shot: "rec-devoptions", alt: "Die Einstellung Entwickleroptionen ausschalten" },
        ],
      },
      {
        id: "check",
        title: "Prüfen, ob es funktioniert",
        blocks: [
          {
            ul: [
              "**Jetzt prüfen** (unter Einrichten) startet den Aufnahmedienst, wenn er nicht läuft – das beweist, dass One Recorder noch gekoppelt ist – und lässt ihn dann kurz den Anrufton öffnen. Es zeigt die Uhrzeit und das Ergebnis.",
              "Akzeptiert das drahtlose Debugging One Recorder nicht mehr, führt dich Jetzt prüfen zurück zum Kopplungsschritt, statt weiter Gekoppelt anzuzeigen.",
              "Nach jedem aufgenommenen Anruf zeigt One Recorder oben das Ergebnis: wann und wie lange, oder rot, wenn die Aufnahme stumm war oder der Anruf nicht aufgenommen wurde.",
            ],
          },
          { shot: "rec-check", alt: "Jetzt prüfen und das Ergebnis des letzten Anrufs" },
        ],
      },
      {
        id: "record",
        title: "Einen Anruf aufnehmen",
        blocks: [
          {
            ul: [
              "Tippe während eines Anrufs im Anrufbildschirm von One Dialer auf **⋮ › Aufnehmen**. Tippe noch einmal, um zu stoppen. Die Aufnahme endet auch von selbst, wenn der Anruf endet.",
              "Beim ersten Mal zeigt One Dialer einen kurzen Hinweis zur Zustimmung. Die Aufnahme startet, sobald du ihn bestätigst.",
              "Um automatisch aufzunehmen, öffne in One Dialer **Einstellungen › Anrufaufzeichnung**. Automatisches Aufnehmen kann aus sein, jeden Anruf, nur unbekannte Nummern oder nur ausgewählte Kontakte aufnehmen, und eine Liste **Nie aufnehmen** hält gewählte Kontakte heraus.",
            ],
          },
        ],
      },
      {
        id: "recordings",
        title: "Deine Aufnahmen",
        blocks: [
          {
            p: "Du findest sie in One Dialer unter **Anrufe › ⋮ › Aufnahmen** oder **Einstellungen › Anrufaufzeichnung**. Sie sind nach Tag gruppiert, mit dem Namen des Kontakts, und du kannst sie suchen, filtern (Alle, Markiert, Kontakte, Unbekannt), abspielen, markieren, umbenennen, teilen oder löschen.",
          },
          { shot: "rec-recordings", alt: "Aufnahmen in One Dialer" },
          {
            p: "Die Dateien liegen in One Recorder. **Auf Telefon speichern** kopiert eine in den Ordner `Recordings/One Dialer` deines Telefons, wo deine anderen Apps sie sehen. **Automatisch löschen** kann Aufnahmen nach 30 oder 90 Tagen entfernen und behält markierte immer.",
          },
        ],
      },
      {
        id: "how",
        title: "Wie es funktioniert",
        blocks: [
          {
            p: "Am saubersten nimmt man einen Anruf direkt von der Leitung auf, mit beiden Stimmen in voller Lautstärke. Android behält das den fest eingebauten Apps vor, und der **Shell**: dem Konto, unter dem die Debugging-Werkzeuge von Android Befehle ausführen. Drahtloses Debugging lässt eine App auf dem Telefon ein Programm unter diesem Konto starten, so wie Shizuku es tut.",
          },
          {
            p: "Genau das macht **Beide Seiten aufnehmen**. Nach dem Koppeln startet One Recorder aus seiner eigenen App einen kleinen Dienst als Shell. Der Dienst tut genau eines: Solange One Recorder darum bittet, nimmt er den Anruf auf und gibt den Ton über eine private Verbindung im Telefon zurück, für die nur One Recorder den Schlüssel hat. Er endet, wenn One Recorder aktualisiert oder entfernt wird.",
          },
          { p: "One Dialer sagt One Recorder, wann es starten und stoppen soll. One Recorder nimmt den Ton auf, verwaltet die Dateien und antwortet nur dem von Play signierten One Dialer." },
        ],
      },
      {
        id: "nomic",
        title: "Warum es keinen Mikrofon-Weg gibt",
        blocks: [
          {
            p: "Frühere Versionen konnten auch mit dem Mikrofon aufnehmen, über einen Bedienungshilfen-Dienst. Seit Android 10 bekommt eine App, die während eines Anrufs das Mikrofon nutzt, nur Stille, und Android macht nur für manche Bedienungshilfen-Apps eine Ausnahme, in engen Fällen. Hersteller schließen selbst diese: Auf dem getesteten Telefon, einem vivo mit Android 17, waren so gemachte Aufnahmen stumm, weil Android das Mikrofon für den ganzen Anruf stummschaltete.",
          },
          {
            p: "Ein Weg, der still gar nichts aufnimmt, ist schlimmer als keiner, also ist er weg, zusammen mit der Mikrofonberechtigung, diesem Bedienungshilfen-Dienst und den Einstellungen Lautstärke anheben und Mikrofonquelle, die nur er nutzte. Beide Seiten über Drahtloses Debugging aufzunehmen ist jetzt der einzige Weg, und er nimmt beide Stimmen in voller Lautstärke auf.",
          },
        ],
      },
      {
        id: "privacy",
        title: "Datenschutz",
        blocks: [
          { p: "Diese Übersetzung dient nur dem Verständnis; maßgeblich ist der englische Text dieser Seite." },
          {
            p: "One Recorder nimmt nur auf, während ein Anruf läuft, den du aufnehmen willst. Der Ton wird nur in One Recorder auf deinem Telefon gespeichert. Er wird nie hochgeladen, es gibt kein Konto, und nichts über dich oder deine Anrufe verlässt das Telefon, außer du teilst selbst eine Aufnahme. Aufnahmen werden gelöscht, wenn du sie löschst oder One Recorder deinstallierst.",
          },
          {
            p: "Die Kopplung mit Drahtlosem Debugging ist ein Schlüssel im privaten Speicher von One Recorder auf deinem Telefon; er kann nicht gesichert oder von anderen Apps gelesen werden. Der Dienst nimmt nur Anrufe für One Recorder auf und kann nichts anderes ausführen, außer die Entwickleroptionen und das Debugging aus- und einzuschalten. One Recorder hat keine Mikrofonberechtigung. Sein optionaler Bedienungshilfen-Dienst zum Koppeln liest nur die Einstellungen-App, tippt nie etwas an und schaltet sich nach dem Koppeln oder nach fünf Minuten aus. Geräte in der Nähe oder Standort wird nur abgefragt, wenn du Ohne WLAN starten einschaltest, um den lokalen Hotspot zu öffnen. Aufnahmegesetze unterscheiden sich je nach Land, und du bist dafür verantwortlich, die Zustimmung der anderen Person einzuholen, wo sie nötig ist.",
          },
          {
            p: "**Rechtlicher Hinweis.** One Recorder wird ohne Mängelgewähr und ohne jede Garantie bereitgestellt. Sie kann beide Seiten eines Anrufs aufnehmen, und die Gesetze zur Anrufaufzeichnung unterscheiden sich je nach Land und Region: An manchen Orten müssen alle Beteiligten zustimmen, an manchen ist Aufnehmen gar nicht erlaubt. Du allein bist dafür verantwortlich, die Gesetze dort zu kennen und einzuhalten, wo du und die andere Person sich befinden, sie zu informieren und ihre Zustimmung einzuholen, wo das nötig ist, und dafür, wie du deine Aufnahmen verwendest. Syed Arham Raza, der One Recorder und One Dialer entwickelt, ist nicht dafür verantwortlich, wie du sie nutzt, oder für Aufnahmen, die du damit machst.",
          },
        ],
      },
      {
        id: "legal",
        title: "Rechtlicher Hinweis",
        blocks: [
          { p: "Diese Übersetzung dient nur dem Verständnis; maßgeblich ist der englische Text dieser Seite." },
          {
            p: "One Recorder wird ohne Mängelgewähr und ohne jede Garantie bereitgestellt. Sie kann beide Seiten eines Anrufs aufnehmen, und die Gesetze zur Anrufaufzeichnung unterscheiden sich je nach Land und Region: An manchen Orten müssen alle Beteiligten zustimmen, an manchen ist Aufnehmen gar nicht erlaubt. Du allein bist dafür verantwortlich, die Gesetze dort zu kennen und einzuhalten, wo du und die andere Person sich befinden, sie zu informieren und ihre Zustimmung einzuholen, wo das nötig ist, und dafür, wie du deine Aufnahmen verwendest. Syed Arham Raza, der One Recorder und One Dialer entwickelt, ist nicht dafür verantwortlich, wie du sie nutzt, oder für Aufnahmen, die du damit machst.",
          },
        ],
      },
      {
        id: "setups",
        title: "Einstellungen für typische Situationen",
        blocks: [
          {
            setup: "Ich nutze Banking-Apps",
            when: "Du willst Aufnahme und deine Banking-App auf demselben Telefon.",
            steps: [
              "Lass **Entwickleroptionen ausschalten** an (Standard).",
              "Lass **Ohne WLAN weiter aufnehmen** aus: Es hält USB-Debugging an.",
              "Sagt die Zeile, dass dein Telefon ein Debugging eingeschaltet braucht, probier die Banking-App trotzdem: Viele prüfen nur die Entwickleroptionen.",
            ],
          },
          {
            setup: "Ich will auch ohne WLAN aufnehmen",
            when: "Der Aufnahmedienst endet, wenn das WLAN weg ist, weil drahtloses Debugging WLAN braucht.",
            steps: [
              "Schalte **Ohne WLAN weiter aufnehmen** ein. Es hält USB-Debugging an, sodass der Dienst mit mobilen Daten weiterläuft.",
              "Manche Banking-Apps öffnen sich nicht, solange es an ist.",
            ],
          },
          { shot: "rec-away-wifi", alt: "Ohne WLAN weiter aufnehmen" },
          {
            setup: "Mein Telefon startet oft ohne WLAN neu",
            when: "Nach einem Neustart wartet der Dienst auf WLAN, bevor er startet.",
            steps: [
              "Prüfe, dass **Nach Neustart starten** sagt, dass er von selbst startet.",
              "Auf Android 12 bis 16 probier **Ohne WLAN starten (experimentell)**. Es braucht eingeschalteten Standort und funktioniert vielleicht nicht auf jedem Telefon.",
            ],
          },
          {
            setup: "Meine Aufnahmen sind stumm oder leise",
            when: "Eine Aufnahme hat keinen Ton, oder die andere Person ist kaum zu hören.",
            steps: [
              "Tippe auf **Jetzt prüfen**. Funktioniert nicht alles, behebe den Schritt, auf den es zeigt.",
              "Probier denselben Anruf über das Mobilfunknetz statt über WLAN-Telefonie.",
              "Immer noch falsch: **Diagnose teilen** und mit einer Fehlermeldung schicken.",
            ],
          },
        ],
      },
      {
        id: "trouble",
        title: "Wenn es nicht klappt",
        blocks: [
          {
            ul: [
              "**One Dialer meldet, dass die Aufnahme pausiert ist, oder der Dienst läuft nicht:** Das Telefon wurde ohne WLAN neu gestartet, oder die Entwickleroptionen wurden ausgeschaltet. Verbinde dich mit dem WLAN und starte den Dienst in One Recorder. Solange er nicht läuft, können Anrufe nicht aufgenommen werden.",
              "**Der Kopplungscode wird nicht angenommen:** Lass den Kopplungsdialog offen, während du den Code eingibst, im selben WLAN. Klappt es dann nicht, schließ den Dialog, öffne ihn für einen neuen Code und versuch es noch einmal.",
              "**Die Aufnahme hat nur eine Stimme oder gar nichts:** Manche Telefone verlieren bei WLAN-Telefonie eine Seite, und einige erlauben gar keine Aufnahme der Leitung. Versuch denselben Anruf über das Mobilfunknetz.",
              "**One Dialer meldet, dass Anrufe nicht aufgenommen werden:** Automatisches Aufnehmen ist an, aber One Recorder ist nicht bereit. Öffne es und behebe jede Zeile, die nicht Bereit ist, meist den Dienst.",
              "**One Dialer meldet, dass der Recorder nur mit One Dialer aus Google Play funktioniert:** One Dialer wurde aus einer Datei installiert oder ist älter als 1.0.0-beta.9. Installiere die App aus Google Play oder aktualisiere beide Apps.",
              "**Keine Aufnahme-Option im Anrufbildschirm:** One Recorder ist nicht installiert. One Dialer blendet alles rund ums Aufnehmen aus, bis es installiert ist.",
              "**Eine Banking-App öffnet sich immer noch nicht:** Dein Telefon braucht USB- oder drahtloses Debugging eingeschaltet (die Zeile Entwickleroptionen ausschalten in One Recorder sagt, welches). Schalte **Ohne WLAN weiter aufnehmen** aus, falls es an ist, denn es hält USB-Debugging an.",
              "**Es klappt immer noch nicht:** Tippe in One Recorder auf **Diagnose teilen** und schick den Bericht mit deiner Fehlermeldung. Er enthält Versionen, Telefonmodell, Einrichtungsstatus und aktuelle Protokollzeilen, ohne Nummern oder Namen.",
            ],
          },
        ],
      },
      {
        id: "update",
        title: "Aktualisieren oder entfernen",
        blocks: [
          {
            ul: [
              "**Zum Aktualisieren** öffne One Recorder › **Softwareupdate**. Während der Aufnahmedienst läuft, installiert es die neue Version selbst, ohne Nachfrage; sonst lädt es sie herunter, damit du sie installierst. Du kannst die APK auch von dieser Seite laden und über die alte installieren. Aufnahmen und Einstellungen bleiben erhalten.",
              "**Zum Entfernen** deinstalliere One Recorder wie jede App. Dabei werden alle Aufnahmen darin gelöscht, also speichere die gewünschten vorher auf deinem Telefon. One Dialer läuft weiter und blendet seine Aufnahmeoptionen wieder aus.",
              "Aufnahmegesetze unterscheiden sich je nach Land. Manche verlangen, dass alle Beteiligten zustimmen. Du bist dafür verantwortlich, die andere Person zu informieren und ihre Zustimmung einzuholen, wo sie nötig ist.",
            ],
          },
        ],
      },
    ],
  },
};
