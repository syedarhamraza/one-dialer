// The site's English text: the reference every other language in this folder follows, key for key.
// In the recorder guide, **bold** and `code` mark up words (components/Rich.tsx); {name} is filled in.

export type Block = { p: string } | { ul: string[] } | { ol: string[] };

export const en = {
  meta: {
    title: "One Dialer · Phone & call blocker for Android",
    description: "Fast T9 dialer with call blocking, dual SIM and a frosted glass design.",
    released: "Free on Google Play.",
    beta: "Now in closed beta on Google Play.",
    recorderTitle: "One Recorder · One Dialer",
    recorderDescription: "Record your calls in One Dialer with One Recorder, a small companion app you install from this website. How to set it up, and what to expect.",
  },
  nav: {
    label: "Site",
    whatsNew: "What's new",
    recorder: "Recorder",
    privacy: "Privacy",
    getApp: "Get the app",
    joinBeta: "Join the beta",
    beta: "Beta",
  },
  stage: {
    // The three words of the first screen's headline; the last one is green.
    headline: ["Calls,", "in", "glass."],
    intro: "A fast, private phone app for Android. Smart T9, call blocking and dual SIM, on true black.",
    small: "Free · No ads · Android 10 and newer",
    screens: "Screens",
    alt: "{title} screen in One Dialer",
  },
  // The slab turns through these in order; each title is also the giant word behind it, so keep them short.
  screens: [
    { title: "Keypad", body: "Frosted keys over your calls, with a Call key for each SIM." },
    { title: "Calls", body: "Missed calls in red, repeat calls grouped, blocked ones marked. The keypad is one tap away." },
    { title: "Contacts", body: "Favourites first, then an A–Z index under your thumb." },
    { title: "Incoming", body: "Full screen, tinted by the caller, right on the lock screen." },
    { title: "In call", body: "Big glass controls for mute, hold, speaker and the dial pad." },
  ],
  does: {
    h: "What it does.",
    h2: "And what it doesn't.",
    items: [
      { title: "Blocks before it rings", text: "Private numbers, unknown callers, or anyone not in your contacts. Plus your phone's own block list." },
      { title: "Dual SIM, done right", text: "A SIM for every contact, a default SIM, or ask every time. The call key shows which SIM you're on." },
      { title: "A real phone app", text: "Every call goes through Android's own Telecom framework, so calls behave exactly like the system dialer's." },
      { title: "Stays on your phone", text: "No account, no ads. Your calls and contacts never leave the device." },
      { title: "Open source", text: "GPL-3.0. Read the code, report a bug or add your language." },
    ],
    github: "One Dialer on GitHub",
  },
  smooth: {
    h: "Smooth on",
    h2: "every phone.",
    text: "On first launch One Dialer reads your phone's chip and picks a level of visual effects, and you can change it in Settings. Try the three levels here: this page's glass follows, the keypad and the slab at the top included.",
  },
  levels: {
    label: "Visual effects",
    full: { label: "Full", text: "Frosted call glass with its edge glow. Flagship chips start here." },
    reduced: { label: "Reduced", text: "One flat translucent fill over a single shared blur. Midrange chips start here." },
    off: { label: "Off", text: "Solid fills and no blur at all. Budget chips and low-memory phones start here." },
  },
  keypad: {
    hint: "Try 3662 on the keys",
    none: "No one by that name or number.",
    delete: "Delete",
  },
  whatsNew: {
    h: "What's new.",
    beta: "Beta {n}",
    version: "Version {v}",
    // Shown under the notes in other languages: release notes are written in English only.
    note: "",
  },
  get: {
    h: "Get One Dialer.",
    h2: "Free on Google Play.",
    text: "Install it like any other app, then set One Dialer as your default phone app when it asks. Android 10 and newer.",
  },
  join: {
    h: "Join the beta.",
    h2: "Two steps.",
    text: "One Dialer is in closed testing on Google Play. Join the testers group, then install it from Play like any other app.",
    step: "Step {n}: ",
    group: {
      title: "Join the Google Group",
      text: "Open the group and tap Join group. That puts your Google account on the testers list.",
      note: "Use the same Google account that's signed in on your phone's Play Store.",
      cta: "Join the group",
    },
    tester: {
      title: "Become a tester on Google Play",
      text: "Open the testing page, tap Become a tester, then Download it on Google Play and install.",
      note: "After joining the group it can take a few minutes for this page to let you in.",
      cta: "Become a tester",
    },
  },
  apk: {
    title: "Got One Dialer as an APK file?",
    text: "Copies shared as files, or pulled out of a phone by another app, aren't official. They don't get updates and may have been changed.",
    released: "Uninstall it and install it from Google Play instead.",
    beta: "Uninstall it and join here instead.",
  },
  faq: {
    h: "Questions,",
    h2: "answered.",
    // `beta` questions only make sense during the closed test; they go when RELEASED. `aBeta` replaces `a` before then.
    items: [
      {
        beta: true,
        q: "Why a closed beta?",
        a: "Google Play asks new apps to be tested by a group of people before they go public. Joining helps One Dialer get there, and you get every update first.",
      },
      {
        beta: true,
        q: "The Play link says the app isn't available.",
        a: "Make sure you joined the Google Group with the same Google account that's signed in on your phone's Play Store. After joining, it can take a few minutes for the testing link to work.",
      },
      { q: "Which phones does it work on?", a: "Android 10 or newer. To make and receive calls, set One Dialer as your default phone app when it asks." },
      { q: "Is it free? Are there ads?", a: "It's free and has no ads." },
      {
        q: "Do my calls and contacts leave my phone?",
        a: "No. Your call history and contacts stay on your phone. The privacy policy lists exactly what is sent, such as crash reports.",
      },
      {
        q: "I got One Dialer as an APK file.",
        a: "That copy isn't official: it won't get updates and may have been changed. Uninstall it, then install One Dialer from Google Play.",
        aBeta: "That copy isn't official: it won't get updates and may have been changed. Uninstall it, then join the beta here to get it from Google Play.",
      },
      { beta: true, q: "How do I leave the beta?", a: "Open the Google Play testing link and choose Leave the program, then uninstall the app if you like." },
    ] as { q: string; a: string; aBeta?: string; beta?: boolean }[],
  },
  play: "Get it on Google Play",
  footer: {
    bug: "Found a bug?",
    idea: "Have an idea?",
    feature: "Request a feature",
    report: "Report a bug",
    label: "Footer",
    recorder: "One Recorder",
    privacy: "Privacy policy",
    contact: "Contact",
    language: "Language",
  },
  recorder: {
    back: "Back to One Dialer",
    title: "One Recorder",
    h1: "One",
    h1b: "Recorder.",
    lead: "Call recording for One Dialer. It's a separate app, so One Dialer from Google Play never records anything itself.",
    download: "Download APK",
    downloadNote: "Latest version, from GitHub Releases · Android 12 or later",
    prosTitle: "What you get",
    pros: [
      "Both sides of the call at full volume, on Android 12 and later: you and the other person, on the earpiece, speaker, Bluetooth or headphones. No root, no computer, no separate Shizuku app.",
      "After a reboot it starts again by itself once you're on Wi-Fi.",
      "No microphone permission and no accessibility service. One Recorder records the call itself, only during a call you record.",
      "Recordings stay on your phone. Nothing is uploaded, there's no account and no ads.",
      "Record when you choose, or automatically: every call, unknown numbers, or only the contacts you pick.",
      "Your recordings live in One Dialer, with contact names, search, stars, sharing and auto-delete.",
      "Open source, like One Dialer. Anyone can check what it does.",
    ],
    consTitle: "What to expect",
    cons: [
      "Both sides needs Developer options and Wireless debugging turned on once, and Wi-Fi whenever it starts. If it can't start again after a reboot (no Wi-Fi, or Developer options off), you tap Start in One Recorder.",
      "Some banking and payment apps refuse to open while Developer options is on.",
      "On some phones, calls over Wi-Fi calling record only one side. That's the phone's audio driver, not One Recorder.",
      "It needs Android 12 or later. Android 10 and 11 can't start the helper over Wireless debugging, and there's no other way to record there.",
      "It doesn't update itself. Google Play doesn't know about it, so you come back here for new versions.",
      "It works only with One Dialer from Google Play, version 1.0.0-beta.9 or later, not with a copy installed from a file.",
      "The other person isn't told you're recording. That's on you, and in some places it's against the law without their consent.",
    ],
    setup: "Set it up,",
    setupB: "step by step.",
    toc: "On this page",
    intro: "About five minutes, once. After that you record from One Dialer's call screen and never open One Recorder again.",
    sections: [
      {
        id: "before",
        title: "Before you start",
        blocks: [
          {
            ul: [
              "An Android phone on Android 12 or later, and Wi-Fi for the first setup and whenever the helper starts.",
              "**One Dialer from Google Play**, version 1.0.0-beta.9 or later, set as your default phone app. One Recorder checks that it's talking to the official app and ignores any other.",
              "A few megabytes free for the app, and room for recordings: roughly half a megabyte per minute of call.",
            ],
          },
        ],
      },
      {
        id: "install",
        title: "Install the app",
        blocks: [
          {
            ol: [
              "On your phone, tap **Download APK** at the top of this page. The file is called `one-dialer-recorder.apk`.",
              "Open it from the download notification, or from your Files app's Downloads.",
              "If Android says your browser isn't allowed to install apps, tap **Settings**, turn on **Allow from this source**, then go back.",
              "Tap **Install**. Google Play Protect may offer to scan the app, since it didn't come from Play. Let it; it's the same app that's published on GitHub.",
            ],
          },
        ],
      },
      {
        id: "both",
        title: "Record both sides",
        blocks: [
          { p: "Open One Recorder: **Record both sides** is at the top, and each row turns to Ready as you go." },
          {
            ol: [
              "**Developer options.** If they're off, open **Settings › About phone** (on some phones, About phone › Software information) and tap **Build number** seven times.",
              "**Pair with Wireless debugging.** Tap the row. One Recorder opens Developer options and posts a notification. Turn on **Wireless debugging**, open it, and tap **Pair device with pairing code**.",
              "Keep that code on screen, pull down the notification from One Recorder, tap **Enter code** and type the six digits. One Recorder pairs and starts its helper. You only pair once.",
              "**Helper: Ready.** If it says Not running, make sure you're on Wi-Fi and tap **Start**. **Start after a reboot** turns on by itself the first time the helper starts.",
            ],
          },
          {
            p: "You can turn Wireless debugging off again: One Recorder switches it on for a moment when it needs to start the helper, and back off afterwards. If your phone stops the helper when Wireless debugging goes off, One Recorder leaves it on.",
          },
        ],
      },
      {
        id: "setup",
        title: "Notifications and battery",
        blocks: [
          {
            ol: [
              "**Notifications.** Allow them, so you can see when a call is being recorded.",
              "**Battery: Unrestricted.** Optional, but recommended. It stops the phone from closing the recorder while it waits for a call.",
            ],
          },
        ],
      },
      {
        id: "record",
        title: "Record a call",
        blocks: [
          {
            ul: [
              "During a call, tap **⋮ › Record** on One Dialer's call screen. Tap it again to stop. Recording also stops by itself when the call ends.",
              "The first time, One Dialer shows a short notice about consent. Recording starts once you accept it.",
              "To record automatically, open One Dialer's **Settings › Call recording**. Auto-record can be off, every call, unknown numbers only, or only the contacts you pick, and a **Never record** list keeps chosen contacts out.",
            ],
          },
        ],
      },
      {
        id: "recordings",
        title: "Your recordings",
        blocks: [
          {
            p: "Find them in One Dialer under **Calls › ⋮ › Recordings**, or **Settings › Call recording**. They're grouped by day, with the contact's name, and you can search, filter (All, Starred, Contacts, Unknown), play, star, rename, share or delete them.",
          },
          {
            p: "The files live inside One Recorder. **Save to phone** copies one to your phone's `Recordings/One Dialer` folder, where your other apps can see it. **Auto-delete** can clear recordings after 30 or 90 days, always keeping starred ones.",
          },
        ],
      },
      {
        id: "how",
        title: "How it works",
        blocks: [
          {
            p: "The cleanest way to record a call is straight from the phone line, with both voices at full volume. Android keeps that for apps built into the phone, and for the **shell**: the account Android's own debugging tools run commands as. Wireless debugging lets an app on the phone start a program as that account, the way Shizuku does.",
          },
          {
            p: "That's what **Record both sides** does. Once paired, One Recorder starts a small helper from its own app as the shell. The helper does one thing: while One Recorder asks, it records the call and hands the sound back over a private connection inside the phone that only One Recorder holds the key to. It stops when One Recorder is updated or removed.",
          },
          { p: "One Dialer tells One Recorder when to start and stop. One Recorder records the audio, keeps the files, and answers only the Play-signed One Dialer." },
        ],
      },
      {
        id: "nomic",
        title: "Why there's no microphone method",
        blocks: [
          {
            p: "Earlier versions could also record with the microphone, using an accessibility service. Since Android 10, an app using the microphone during a call gets silence, and Android makes an exception only for some accessibility apps, in narrow cases. Phone makers close even those: on the phone we tested, a vivo on Android 17, recordings made that way were silent, with Android muting the microphone for the whole call.",
          },
          {
            p: "A method that silently records nothing is worse than none, so it's gone, along with the microphone permission, the accessibility service, and the Volume boost and Microphone source settings that only it used. Recording both sides through Wireless debugging is the only way now, and it records both voices at full volume.",
          },
        ],
      },
      {
        id: "privacy",
        title: "Privacy",
        blocks: [
          {
            p: "One Recorder records only while a call you chose to record is going on. The audio is saved only inside One Recorder on your phone. It's never uploaded, there's no account, and nothing about you or your calls leaves the phone unless you share a recording yourself. Recordings are deleted when you delete them or uninstall One Recorder.",
          },
          {
            p: "Its pairing with Wireless debugging is a key kept in One Recorder's private storage on your phone; it can't be backed up or read by other apps. The helper only records calls for One Recorder and can't run anything else. One Recorder has no microphone permission and no accessibility service. Recording laws differ by country, and you're responsible for getting the other person's consent where it's required.",
          },
          {
            p: "**Legal notice.** One Recorder is provided as is, without any warranty. It can record both sides of a call, and call recording laws differ by country and region: some places need everyone on the call to agree, and some don't allow recording at all. You alone are responsible for knowing and following the laws where you and the other person are, for telling them and getting their consent where it's required, and for how you use your recordings. Syed Arham Raza, who makes One Recorder and One Dialer, isn't responsible for how you use it or for any recording you make with it.",
          },
        ],
      },
      {
        id: "legal",
        title: "Legal notice",
        blocks: [
          {
            p: "One Recorder is provided as is, without any warranty. It can record both sides of a call, and call recording laws differ by country and region: some places need everyone on the call to agree, and some don't allow recording at all. You alone are responsible for knowing and following the laws where you and the other person are, for telling them and getting their consent where it's required, and for how you use your recordings. Syed Arham Raza, who makes One Recorder and One Dialer, isn't responsible for how you use it or for any recording you make with it.",
          },
        ],
      },
      {
        id: "trouble",
        title: "If it doesn't work",
        blocks: [
          {
            ul: [
              "**“Both sides is paused” in One Dialer, or Helper: Not running:** the phone restarted away from Wi-Fi, or Developer options was turned off. Connect to Wi-Fi and tap **Start** in One Recorder. Until it's running, calls can't be recorded.",
              "**The pairing code isn't accepted:** keep the pairing dialog open while you type the code, on the same Wi-Fi network. If it still fails, close the dialog, open it again for a new code and try once more.",
              "**The recording has only one voice, or nothing:** some phones lose one side over Wi-Fi calling, and a few don't allow recording the line at all. Try the same call over the mobile network.",
              "**“Calls aren't being recorded” in One Dialer:** auto-record is on but One Recorder isn't ready. Open it and fix any row that isn't Ready, usually the helper.",
              "**“The recorder works only with One Dialer from Google Play”:** One Dialer was installed from a file, or it's older than 1.0.0-beta.9. Install it from Google Play, or update both apps.",
              "**No Record option on the call screen:** One Recorder isn't installed. One Dialer hides everything about recording until it is.",
            ],
          },
        ],
      },
      {
        id: "update",
        title: "Update or remove it",
        blocks: [
          {
            ul: [
              "**To update,** download the APK from this page again and install it over the old one. Your recordings and settings stay.",
              "**To remove it,** uninstall One Recorder like any app. That deletes every recording inside it, so save the ones you want to your phone first. One Dialer keeps working and hides its recording options again.",
              "Recording laws differ by country. Some need everyone on the call to agree. You're responsible for telling the other person and getting their consent where it's required.",
            ],
          },
        ],
      },
    ] as { id: string; title: string; blocks: Block[] }[],
  },
};

export type Dict = typeof en;
