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
  },
  nav: {
    label: "Website",
    whatsNew: "Neuigkeiten",
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
    recorder: "One Recorder",
    privacy: "Datenschutzerklärung (Englisch)",
    contact: "Kontakt",
    language: "Sprache",
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
      "Keine Mikrofonberechtigung und kein Bedienungshilfen-Dienst. One Recorder nimmt den Anruf selbst auf, nur während eines Anrufs, den du aufnimmst.",
      "Aufnahmen bleiben auf deinem Telefon. Nichts wird hochgeladen, es gibt kein Konto und keine Werbung.",
      "Nimm auf, wann du willst, oder automatisch: jeden Anruf, unbekannte Nummern oder nur Kontakte, die du auswählst.",
      "Deine Aufnahmen leben in One Dialer, mit Kontaktnamen, Suche, Sternen, Teilen und automatischem Löschen.",
      "Open Source, wie One Dialer. Jeder kann prüfen, was sie tut.",
    ],
    consTitle: "Was dich erwartet",
    cons: [
      "Beide Seiten brauchen einmal eingeschaltete Entwickleroptionen und Drahtloses Debugging, und WLAN bei jedem Start. Kann sie nach einem Neustart nicht wieder starten (kein WLAN, oder Entwickleroptionen aus), startest du sie in One Recorder per Tipp.",
      "Manche Banking- und Bezahl-Apps öffnen sich nicht, solange die Entwickleroptionen an sind.",
      "Auf manchen Telefonen nehmen Anrufe über WLAN-Telefonie nur eine Seite auf. Das liegt am Audiotreiber des Telefons, nicht an One Recorder.",
      "Sie braucht Android 12 oder neuer. Android 10 und 11 können den Dienst nicht über Drahtloses Debugging starten, und dort gibt es keinen anderen Weg aufzunehmen.",
      "Sie aktualisiert sich nicht selbst. Google Play kennt sie nicht, also kommst du für neue Versionen hierher zurück.",
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
          { p: "Öffne One Recorder: **Beide Seiten aufnehmen** steht oben, und jede Zeile wird nach und nach Bereit." },
          {
            ol: [
              "**Entwickleroptionen.** Sind sie aus, öffne **Einstellungen › Über das Telefon** (auf manchen Telefonen Über das Telefon › Softwareinformationen) und tippe siebenmal auf **Build-Nummer**.",
              "**Mit Drahtlosem Debugging koppeln.** Tippe auf die Zeile. One Recorder öffnet die Entwickleroptionen und zeigt eine Benachrichtigung. Schalte **Drahtloses Debugging** ein, öffne es und tippe auf **Gerät über einen Kopplungscode koppeln**.",
              "Lass den Code auf dem Bildschirm, zieh die Benachrichtigung von One Recorder herunter, tippe auf **Code eingeben** und gib die sechs Ziffern ein. One Recorder koppelt sich und startet seinen Dienst. Gekoppelt wird nur einmal.",
              "**Aufnahmedienst: bereit.** Steht dort Läuft nicht, sorge für WLAN und tippe auf die Zeile, um ihn zu starten. **Nach Neustart starten** schaltet sich beim ersten Start des Dienstes von selbst ein.",
            ],
          },
          {
            p: "Du kannst Drahtloses Debugging wieder ausschalten: One Recorder schaltet es kurz ein, wenn es den Dienst starten muss, und danach wieder aus. Beendet dein Telefon den Dienst, wenn Drahtloses Debugging ausgeht, lässt One Recorder es an.",
          },
        ],
      },
      {
        id: "setup",
        title: "Benachrichtigungen und Akku",
        blocks: [
          {
            ol: [
              "**Benachrichtigungen.** Erlaube sie, damit du siehst, wenn ein Anruf aufgenommen wird.",
              "**Akku: Nicht eingeschränkt.** Optional, aber empfohlen. So beendet das Telefon den Recorder nicht, während er auf einen Anruf wartet.",
            ],
          },
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
            p: "Ein Weg, der still gar nichts aufnimmt, ist schlimmer als keiner, also ist er weg, zusammen mit der Mikrofonberechtigung, dem Bedienungshilfen-Dienst und den Einstellungen Lautstärke anheben und Mikrofonquelle, die nur er nutzte. Beide Seiten über Drahtloses Debugging aufzunehmen ist jetzt der einzige Weg, und er nimmt beide Stimmen in voller Lautstärke auf.",
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
            p: "Die Kopplung mit Drahtlosem Debugging ist ein Schlüssel im privaten Speicher von One Recorder auf deinem Telefon; er kann nicht gesichert oder von anderen Apps gelesen werden. Der Dienst nimmt nur Anrufe für One Recorder auf und kann nichts anderes ausführen. One Recorder hat keine Mikrofonberechtigung und keinen Bedienungshilfen-Dienst. Aufnahmegesetze unterscheiden sich je nach Land, und du bist dafür verantwortlich, die Zustimmung der anderen Person einzuholen, wo sie nötig ist.",
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
              "**Zum Aktualisieren** lade die APK erneut von dieser Seite herunter und installiere sie über die alte. Deine Aufnahmen und Einstellungen bleiben.",
              "**Zum Entfernen** deinstalliere One Recorder wie jede App. Dabei werden alle Aufnahmen darin gelöscht, also speichere die gewünschten vorher auf deinem Telefon. One Dialer läuft weiter und blendet seine Aufnahmeoptionen wieder aus.",
              "Aufnahmegesetze unterscheiden sich je nach Land. Manche verlangen, dass alle Beteiligten zustimmen. Du bist dafür verantwortlich, die andere Person zu informieren und ihre Zustimmung einzuholen, wo sie nötig ist.",
            ],
          },
        ],
      },
    ],
  },
};
