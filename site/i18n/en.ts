// The site's English text: the reference every other language in this folder follows, key for key.
// In the recorder guide, **bold** and `code` mark up words (components/Rich.tsx); {name} is filled in.

// A shot is a screenshot or screen recording slot (components/Shot.tsx, public/guide/<shot>.mp4 or .webp);
// a setup is a recipe: the situation, then the settings to change.
export type Block =
  | { p: string }
  | { ul: string[] }
  | { ol: string[] }
  | { shot: string; alt: string; caption?: string }
  | { setup: string; when: string; steps: string[] };

export const en = {
  meta: {
    title: "One Dialer · Phone & call blocker for Android",
    description: "Fast T9 dialer with call blocking, dual SIM and a frosted glass design.",
    released: "Free on Google Play.",
    beta: "Now in closed beta on Google Play.",
    recorderTitle: "One Recorder · One Dialer",
    recorderDescription: "Record your calls in One Dialer with One Recorder, a small companion app you install from this website. How to set it up, and what to expect.",
    guideTitle: "Guide · One Dialer",
    guideDescription: "How to use One Dialer: SIMs, calling from Calls, the keypad, contacts, blocking, the call screen and effects, with setups for common situations.",
  },
  nav: {
    label: "Site",
    whatsNew: "What's new",
    guide: "Guide",
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
    guide: "Guide",
    recorder: "One Recorder",
    privacy: "Privacy policy",
    contact: "Contact",
    language: "Language",
  },
  // The One Dialer guide (/guide/). Setting names match the app's own (lib/l10n/app_en.arb).
  guide: {
    back: "Back to One Dialer",
    title: "Guide",
    h1: "One Dialer,",
    h1b: "explained.",
    lead: "Where everything is, what each setting does, and the settings that fit your situation.",
    toc: "On this page",
    intro: "Pictures and short recordings show each step. Settings are under the ⋮ menu on the Calls tab.",
    sections: [
      {
        id: "start",
        title: "Get started",
        blocks: [
          {
            ol: [
              "Open One Dialer and tap **Set** to make it your **default phone app**. Calls, Recents and missed-call notifications only work once it is.",
              "Allow **Contacts**, **Phone** and **Notifications** when Android asks.",
              "Open **Settings**. If anything is wrong, a **Needs attention** card sits at the top, for example “Not your default phone app” or notifications turned off, with a **Fix** button that takes you straight to it.",
            ],
          },
          { shot: "start-default", alt: "Setting One Dialer as the default phone app" },
          { shot: "settings-health", alt: "Settings with the Needs attention card and Fix buttons" },
        ],
      },
      {
        id: "calls",
        title: "Calls and recent calls",
        blocks: [
          { p: "The **Calls** tab lists your recent calls. Missed calls are red, repeat calls are grouped, and blocked calls are marked." },
          {
            p: "What tapping a call does is up to you, in **Settings › Quick calling › Tap a recent call**:",
          },
          {
            ul: [
              "**Open details**: the safe choice. The call's page opens, with the number, past calls, notes and a Call button.",
              "**Call**: calls back straight away. Fast, but easy to do by accident.",
              "**Write in keypad**: puts the number in the keypad, so you can check or change it before calling.",
            ],
          },
          { shot: "recents-tap", alt: "The Tap a recent call setting with Call, Open details and Write in keypad" },
          {
            ul: [
              "**Call button on rows** puts a call button on every row, so a tap can open details while the button calls. **Call button style** changes its look.",
              "**Swipe to call or message**: swipe a row right to call, left to message.",
              "**Group by contact** puts a person's calls together.",
              "Hold a row to select several calls, for example to delete them.",
            ],
          },
          { shot: "recents-swipe", alt: "Swiping a recent call right to call" },
        ],
      },
      {
        id: "sims",
        title: "Two SIMs",
        blocks: [
          { p: "With two SIMs, **Settings › SIM cards** decides which one each call uses. Choose it separately for:" },
          {
            ul: [
              "**Keypad and contacts**: **Phone's default SIM**, or **Ask every time**, which shows a SIM chooser when you call.",
              "**Tap a recent call** and **Swipe to call**: **Same as keypad and contacts**, **Use the recent SIM** (the SIM that call used), **Ask every time**, or always one SIM. These are used only when that kind of calling is turned on in Quick calling.",
            ],
          },
          { shot: "sim-settings", alt: "SIM cards settings: Which SIM to call with" },
          {
            p: "A contact can have **their own SIM**: open their page and pick it. It always comes first, before any rule above.",
          },
          { shot: "sim-contact", alt: "Choosing a SIM on a contact's page" },
          {
            p: "On the keypad, **Settings › Keypad › Two Call buttons** shows one Call button per SIM instead of one, so you choose as you call.",
          },
          { shot: "sim-chooser", alt: "The SIM chooser when calling with Ask every time" },
        ],
      },
      {
        id: "keypad",
        title: "Keypad",
        blocks: [
          {
            ul: [
              "Type digits or letters: matching contacts appear as you type (**T9**). Tap one to call or open it.",
              "Hold **1** for voicemail, and **2–9** for speed dial. Set speed dial in **Settings › Keypad › Speed dial**.",
              "Hold **0** for **+**. Hold the star key (*) for a pause and **#** for a wait, for numbers with extensions.",
              "Hold the number to paste one you copied. Hold **Delete** to clear it.",
              "Swipe the keypad down, or tap the handle, to see your calls. The green button beside the nav bar brings it back with your number kept.",
            ],
          },
          { shot: "keypad-t9", alt: "Typing on the keypad with matching contacts" },
          { shot: "keypad-speed-dial", alt: "Speed dial settings" },
        ],
      },
      {
        id: "contacts",
        title: "Contacts",
        blocks: [
          {
            ul: [
              "Favourites are at the top, under ★. Drag along the **A–Z** index on the right to jump.",
              "Tap a contact for their page: numbers, their own SIM, call background, and blocking. Hold to select several.",
              "**⋮ › Manage contacts** sets which accounts show, sort order and name format, where new contacts are saved, importing and exporting, SIM contacts and **Merge duplicate contacts**.",
            ],
          },
          { shot: "contacts-index", alt: "Contacts with favourites and the A–Z index" },
          { shot: "contacts-manage", alt: "Manage contacts" },
        ],
      },
      {
        id: "blocking",
        title: "Blocking",
        blocks: [
          {
            ul: [
              "Block a number from its call's page or a contact's page. **Settings › Block & filter › Blocked numbers** lists them; Android itself rejects those calls.",
              "**Block unknown/private numbers** stops callers who hide their number. **Block calls from numbers not in Contacts** lets only your contacts ring.",
              "These two rules need One Dialer as your **Caller ID & spam app**. One Dialer asks when you turn one on. If another app takes that role, Settings shows “Blocking rules are paused”.",
              "**Hide blocked calls** keeps them out of the Calls list.",
            ],
          },
          { shot: "blocking-rules", alt: "Block & filter settings" },
        ],
      },
      {
        id: "callscreen",
        title: "The call screen",
        blocks: [
          {
            ul: [
              "Incoming calls fill the screen, even on the lock screen. **Settings › Call screen** chooses how you answer (swipe up or down, or buttons), its effects, the caller's photo and the background.",
              "During a call: mute, hold, speaker, the dial pad and adding a call are on big glass buttons. **⋮** has more, such as Record when One Recorder is installed.",
              "**Quick decline messages** are the texts you can send when you decline a call.",
              "**Answering and ending calls** has auto-answer, reply with SMS and speaker options. **Hide contact phone numbers** shows only names for saved contacts.",
            ],
          },
          { shot: "call-incoming", alt: "An incoming call on the lock screen" },
          { shot: "call-controls", alt: "In-call controls" },
        ],
      },
      {
        id: "look",
        title: "Look and speed",
        blocks: [
          {
            p: "**Settings › Display & effects › Reduce visual effects** sets how much glass and blur the app draws. One Dialer picks a level for your phone the first time; change it any time:",
          },
          {
            ul: [
              "**Full effects**: everything as designed, glass and blur.",
              "**Reduced effects**: flatter glass, much less work for the phone.",
              "**Effects off**: solid colours, no blur. The fastest.",
            ],
          },
          { shot: "effects-levels", alt: "Reduce visual effects: Full, Reduced and Off" },
          {
            p: "With Full effects, **Glass & blur › Glass style** can be **Edge glow** or the experimental **Liquid glass**, which bends what's behind it but needs the most power. **Display size** makes the app and the nav bar larger or smaller, and the call screen has its own **Call screen effects**.",
          },
          { shot: "glass-style", alt: "Glass style: Edge glow and Liquid glass" },
        ],
      },
      {
        id: "more",
        title: "Language, backup and updates",
        blocks: [
          {
            ul: [
              "**Settings › Language › App language** changes only One Dialer's language. **Same as phone** follows Android.",
              "**Back up & restore** saves your settings, speed dial, call notes and call backgrounds to a file, for a new phone or a reinstall.",
              "**Software update** shows when a new version is on Google Play, with what's new.",
            ],
          },
          { shot: "settings-language", alt: "App language settings" },
        ],
      },
      {
        id: "setups",
        title: "Setups for common situations",
        blocks: [
          { p: "Pick the situation that sounds like you, and change these settings." },
          {
            setup: "I keep calling people by accident",
            when: "A tap on a recent call, or a swipe while scrolling, starts a call you didn't mean.",
            steps: [
              "**Settings › Quick calling › Tap a recent call** → **Open details**.",
              "Turn off **Swipe to call or message**.",
              "Optional: turn on **Call button on rows**, so calling is one deliberate tap on the button.",
            ],
          },
          { shot: "setup-no-accidents", alt: "Quick calling set up to avoid accidental calls" },
          {
            setup: "Work SIM and personal SIM",
            when: "You want work contacts on one SIM and everyone else on the other, without choosing every time.",
            steps: [
              "**Settings › SIM cards › Keypad and contacts** → your personal SIM (or Phone's default SIM).",
              "On each work contact's page, choose the **work SIM**. It always wins.",
              "**Tap a recent call** → **Use the recent SIM**, so calling back uses the SIM the call came in on.",
            ],
          },
          { shot: "setup-two-sims", alt: "SIM settings for work and personal SIMs" },
          {
            setup: "I'm never sure which SIM will be used",
            when: "Two SIMs and you'd rather decide on each call.",
            steps: [
              "**Settings › SIM cards › Keypad and contacts** → **Ask every time**.",
              "**Settings › Keypad › Two Call buttons** on, so the keypad shows one button per SIM.",
            ],
          },
          {
            setup: "My phone feels slow",
            when: "Scrolling stutters or the call screen opens slowly.",
            steps: [
              "**Settings › Display & effects › Reduce visual effects** → **Reduced effects**, or **Effects off** on an older phone.",
              "**Glass style** → **Edge glow** (not Liquid glass).",
              "Lower **Call screen effects** too.",
            ],
          },
          { shot: "setup-slow-phone", alt: "Reduce visual effects set to Reduced" },
          {
            setup: "Only people I know should ring",
            when: "Spam, private numbers or unknown callers.",
            steps: [
              "**Settings › Block & filter** → turn on **Block unknown/private numbers**, and if you want, **Block calls from numbers not in Contacts**.",
              "Accept One Dialer as **Caller ID & spam app** when asked.",
              "Turn on **Hide blocked calls** to keep Calls tidy.",
            ],
          },
          {
            setup: "I want to record calls",
            when: "One Dialer from Google Play never records itself. Recording comes from a separate app, One Recorder.",
            steps: ["Follow the **One Recorder** guide on this site: it takes about five minutes, once."],
          },
        ],
      },
    ] as { id: string; title: string; blocks: Block[] }[],
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
      "After a reboot it starts again by itself once you're on Wi-Fi, and it checks every few hours that it's still running.",
      "It turns Developer options off again by itself once it has started, so most banking apps open.",
      "Check now tests that recording really works, and the last call's result shows whether it was recorded.",
      "No microphone permission. One Recorder records the call itself, only during a call you record. Its one accessibility service is optional: it only reads the pairing code, then turns itself off.",
      "Recordings stay on your phone. Nothing is uploaded, there's no account and no ads.",
      "Record when you choose, or automatically: every call, unknown numbers, or only the contacts you pick.",
      "Your recordings live in One Dialer, with contact names, search, stars, sharing and auto-delete.",
      "Open source, like One Dialer. Anyone can check what it does.",
    ],
    consTitle: "What to expect",
    cons: [
      "Both sides needs Developer options and Wireless debugging turned on once, and Wi-Fi whenever it starts. If it can't start again after a reboot (no Wi-Fi, or Developer options off), you tap Start in One Recorder.",
      "On some phones USB or Wireless debugging has to stay on for recording to keep working, and some banking apps still refuse to open then.",
      "On some phones, calls over Wi-Fi calling record only one side. That's the phone's audio driver, not One Recorder.",
      "It needs Android 12 or later. Android 10 and 11 can't start the helper over Wireless debugging, and there's no other way to record there.",
      "It isn't on Google Play. It checks GitHub for new versions itself and installs them from Software update.",
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
          { p: "Open One Recorder: the steps are under **Set up**, and each one gets a green tick as you go. **Continue** at the top always does the next one." },
          { shot: "rec-setup", alt: "One Recorder's setup steps" },
          {
            ol: [
              "**Notifications.** Allow them first: the pairing code is typed into One Recorder's notification.",
              "**Developer options.** If they're off, open **Settings › About phone** (on some phones, About phone › Software information) and tap **Build number** seven times.",
              "**Pair with Wireless debugging.** Tap the row. One Recorder opens Developer options and posts a notification. Turn on **Wireless debugging**, open it, and tap **Pair device with pairing code**.",
              "Keep that code on screen, pull down the notification from One Recorder, tap **Enter code** and type the six digits. One Recorder pairs and starts its helper. You only pair once.",
              "**Or pair automatically:** turn on **Pair automatically (optional)** in One Recorder. It reads the code from the pairing dialog itself, then switches itself off. On Android 13 and later, if it's greyed out, open One Recorder's App info › ⋮ › **Allow restricted settings** first.",
              "**Start the recording service.** If it isn't running, make sure you're on Wi-Fi and tap it. **Start after a reboot** turns on by itself the first time it starts.",
            ],
          },
          { shot: "rec-pair", alt: "Typing the pairing code into One Recorder's notification" },
          {
            p: "**Battery: Unrestricted** is the last step. It stops the phone from closing the recorder while it waits for a call.",
          },
        ],
      },
      {
        id: "devoptions",
        title: "Developer options and banking apps",
        blocks: [
          {
            p: "Many banking and payment apps refuse to open while Developer options, USB debugging or Wireless debugging is on. **Turn off Developer options** is on by default: once the recording service has started, One Recorder turns them off one by one and checks that recording still works after each.",
          },
          {
            p: "Some phones stop the recording service when USB or Wireless debugging goes off. One Recorder then turns that one back on and leaves it on, and the row says so. When it needs to start the service again (after a reboot, or when you're back on Wi-Fi), it turns them on for a moment and off again.",
          },
          { shot: "rec-devoptions", alt: "The Turn off Developer options setting" },
        ],
      },
      {
        id: "check",
        title: "Check that it works",
        blocks: [
          {
            ul: [
              "**Check now** (under Set up) starts the recording service if it's down, which proves One Recorder is still paired, then has it open the call audio for a moment. It shows the time and the result.",
              "If Wireless debugging no longer accepts One Recorder, Check now takes you back to the pairing step instead of still saying Paired.",
              "After each call you record, the top of One Recorder shows the result: when and how long, or in red if the recording was silent or the call wasn't recorded.",
            ],
          },
          { shot: "rec-check", alt: "Check now and the last call's result" },
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
          { shot: "rec-recordings", alt: "Recordings in One Dialer" },
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
            p: "A method that silently records nothing is worse than none, so it's gone, along with the microphone permission, that accessibility service, and the Volume boost and Microphone source settings that only it used. Recording both sides through Wireless debugging is the only way now, and it records both voices at full volume.",
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
            p: "Its pairing with Wireless debugging is a key kept in One Recorder's private storage on your phone; it can't be backed up or read by other apps. The helper only records calls for One Recorder and can't run anything else, apart from turning Developer options and debugging off and on. One Recorder has no microphone permission. Its optional pairing accessibility service reads only the Settings app, never taps anything, and turns itself off once paired or after five minutes. Nearby devices or Location is asked for only if you turn on Start without Wi-Fi, to open the local hotspot. Recording laws differ by country, and you're responsible for getting the other person's consent where it's required.",
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
        id: "setups",
        title: "Setups for common situations",
        blocks: [
          {
            setup: "I use banking apps",
            when: "You want recording and your banking app on the same phone.",
            steps: [
              "Leave **Turn off Developer options** on (the default).",
              "Leave **Keep recording away from Wi-Fi** off: it keeps USB debugging on.",
              "If the row says your phone needs a debugging switch left on, try the banking app anyway: many only check Developer options.",
            ],
          },
          {
            setup: "I want calls recorded away from Wi-Fi",
            when: "The recording service ends when Wi-Fi goes, because Wireless debugging needs Wi-Fi.",
            steps: [
              "Turn on **Keep recording away from Wi-Fi**. It keeps USB debugging on, so the service keeps running on mobile data.",
              "Some banking apps won't open while it's on.",
            ],
          },
          { shot: "rec-away-wifi", alt: "Keep recording away from Wi-Fi" },
          {
            setup: "My phone often restarts away from Wi-Fi",
            when: "After a reboot the service waits for Wi-Fi before it starts.",
            steps: [
              "Make sure **Start after a reboot** says it starts by itself.",
              "On Android 12 to 16, try **Start without Wi-Fi (experimental)**. It needs Location on, and may not work on every phone.",
            ],
          },
          {
            setup: "My recordings are silent or quiet",
            when: "A recording has no sound, or the other person is hard to hear.",
            steps: [
              "Tap **Check now**. If it isn't all working, fix the step it points to.",
              "Try the same call over the mobile network instead of Wi-Fi calling.",
              "Still wrong: **Share diagnostics** and send it with a bug report.",
            ],
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
              "**A banking app still won't open:** your phone needs USB or Wireless debugging left on (One Recorder's Turn off Developer options row says which). Turn off **Keep recording away from Wi-Fi** if it's on, since that keeps USB debugging on.",
              "**Still stuck:** tap **Share diagnostics** in One Recorder and send the report with your bug report. It has versions, your phone model, the setup state and recent log lines, and no numbers or names.",
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
              "**To update,** open One Recorder › **Software update**. While the recording service runs, it installs the new version itself, with no prompt; otherwise it downloads it for you to install. You can also download the APK from this page and install it over the old one. Your recordings and settings stay.",
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
