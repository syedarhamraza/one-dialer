import type { Metadata } from "next";
import Link from "next/link";
import { CaretLeftIcon, CheckIcon, DownloadSimpleIcon, MinusIcon } from "@phosphor-icons/react/dist/ssr";
import { Footer } from "@/components/Footer";
import { SmoothScroll } from "@/components/SmoothScroll";
import { Toc } from "../privacy/Toc";
import { RECORDER_URL } from "../links";

export const metadata: Metadata = {
  title: "One Recorder · One Dialer",
  description: "Record your calls in One Dialer with One Recorder, a small companion app you install from this website. How to set it up, and what to expect.",
};

const PROS = [
  "Both sides of the call at full volume, on Android 12 and later: you and the other person, on the earpiece, speaker, Bluetooth or headphones. No root, no computer, no separate Shizuku app.",
  "After a reboot it starts again by itself once you're on Wi-Fi.",
  "On Android 10 and 11, or if you'd rather not use Wireless debugging, the microphone method still works.",
  "One Dialer from Google Play never gets your microphone. Only One Recorder does, and only during a call you record.",
  "Recordings stay on your phone. Nothing is uploaded, there's no account and no ads.",
  "Record when you choose, or automatically: every call, unknown numbers, or only the contacts you pick.",
  "Your recordings live in One Dialer, with contact names, search, stars, sharing and auto-delete.",
  "Open source, like One Dialer. Anyone can check what it does.",
];

const CONS = [
  "Both sides needs Developer options and Wireless debugging turned on once, and Wi-Fi whenever it starts. If it can't start again after a reboot (no Wi-Fi, or Developer options off), you tap Start in One Recorder.",
  "Some banking and payment apps refuse to open while Developer options is on.",
  "On some phones, calls over Wi-Fi calling record only one side. That's the phone's audio driver, not One Recorder.",
  "With the microphone method, the caller's volume depends on your phone: clear on speaker, but on the earpiece some phones record them much quieter, or barely at all. It also needs an accessibility service, which some phones switch off after an update or to save battery.",
  "Android 13 and later hide the accessibility switch for apps installed from a file until you allow restricted settings. It's one extra step, but it looks alarming.",
  "It doesn't update itself. Google Play doesn't know about it, so you come back here for new versions.",
  "It works only with One Dialer from Google Play, not with a copy installed from a file.",
  "The other person isn't told you're recording. That's on you, and in some places it's against the law without their consent.",
];

const SECTIONS = [
  { id: "before", title: "Before you start" },
  { id: "install", title: "Install the app" },
  { id: "both", title: "Record both sides" },
  { id: "setup", title: "Microphone method" },
  { id: "record", title: "Record a call" },
  { id: "recordings", title: "Your recordings" },
  { id: "sound", title: "Getting a clearer caller" },
  { id: "how", title: "How it works" },
  { id: "privacy", title: "Privacy" },
  { id: "trouble", title: "If it doesn't work" },
  { id: "update", title: "Update or remove it" },
];

function Card({ title, items, good }: { title: string; items: string[]; good: boolean }) {
  return (
    <div className="glass rounded-[var(--radius-card)] p-7 sm:p-10">
      <h2 className="text-[clamp(1.6rem,2.4vw,2rem)] leading-tight font-bold tracking-[-0.035em]">{title}</h2>
      <ul className="mt-7 space-y-5">
        {items.map((t) => (
          <li key={t} className="flex gap-4 text-[16px] leading-relaxed text-ink-2">
            <span aria-hidden className={`mt-0.5 grid h-7 w-7 shrink-0 place-items-center rounded-full ${good ? "lit" : "bg-white/10"}`}>
              {good ? <CheckIcon size={14} weight="bold" /> : <MinusIcon size={14} weight="bold" />}
            </span>
            <span>{t}</span>
          </li>
        ))}
      </ul>
    </div>
  );
}

export default function OneRecorder() {
  return (
    <>
      <SmoothScroll />
      {/* The app's pushed-page header, as on the privacy policy. */}
      <header className="subpage-bar sticky top-0 z-50 flex h-[72px] items-center gap-4 px-[clamp(16px,4.4vw,64px)]">
        <Link href="/" aria-label="Back to One Dialer" className="glass press grid h-11 w-11 place-items-center rounded-full">
          <CaretLeftIcon size={20} weight="bold" />
        </Link>
        <span aria-hidden className="subpage-title text-[18px] font-semibold tracking-[-0.02em]">
          One Recorder
        </span>
      </header>

      <main className="mx-auto max-w-[1440px] px-[clamp(16px,4.4vw,64px)] pt-8 pb-28 md:pt-14 md:pb-40">
        <h1 className="text-[clamp(3rem,8vw,6rem)] leading-[0.94] font-bold tracking-[-0.04em]">
          One
          <br />
          <span className="text-ink-2">Recorder.</span>
        </h1>
        <p className="mt-7 max-w-[46ch] text-[18px] leading-relaxed text-ink-2">
          Call recording for One Dialer. It&apos;s a separate app, so One Dialer from Google Play never touches your microphone.
        </p>
        <div className="mt-10 flex flex-wrap items-center gap-x-6 gap-y-4">
          <a href={RECORDER_URL} className="press lit inline-flex h-14 items-center gap-2.5 rounded-full px-7 text-[16px] font-semibold">
            <DownloadSimpleIcon size={20} weight="bold" />
            Download APK
          </a>
          <span className="text-[15px] text-ink-2">Latest version, from GitHub Releases · Android 10 or later · both sides on Android 12+</span>
        </div>

        <div className="mt-20 grid grid-cols-1 gap-5 md:mt-28 lg:grid-cols-2">
          <Card title="What you get" items={PROS} good />
          <Card title="What to expect" items={CONS} good={false} />
        </div>

        <h2 className="mt-24 text-[clamp(2.5rem,5.6vw,5.25rem)] leading-[0.98] font-bold tracking-[-0.04em] md:mt-36">
          Set it up,
          <br />
          <span className="text-ink-2">step by step.</span>
        </h2>

        <div className="mt-14 grid grid-cols-1 gap-x-10 gap-y-12 md:mt-20 lg:grid-cols-12">
          <Toc sections={SECTIONS} className="lg:sticky lg:top-28 lg:col-span-4 lg:self-start" />
          <article className="policy guide lg:col-span-8">
            <p>About five minutes, once. After that you record from One Dialer&apos;s call screen and never open One Recorder again.</p>

            <h2 id="before">Before you start</h2>
            <ul>
              <li>An Android phone on Android 10 or later. Recording both sides needs Android 12 or later, and Wi-Fi.</li>
              <li>
                <strong>One Dialer from Google Play</strong>, set as your default phone app. One Recorder checks that it&apos;s talking to the official app and ignores any other.
              </li>
              <li>A few megabytes free for the app, and room for recordings: roughly half a megabyte per minute of call.</li>
            </ul>

            <h2 id="install">Install the app</h2>
            <ol>
              <li>
                On your phone, tap <strong>Download APK</strong> at the top of this page. The file is called <code>one-dialer-recorder.apk</code>.
              </li>
              <li>Open it from the download notification, or from your Files app&apos;s Downloads.</li>
              <li>
                If Android says your browser isn&apos;t allowed to install apps, tap <strong>Settings</strong>, turn on <strong>Allow from this source</strong>, then go back.
              </li>
              <li>
                Tap <strong>Install</strong>. Google Play Protect may offer to scan the app, since it didn&apos;t come from Play. Let it; it&apos;s the same app that&apos;s published on GitHub.
              </li>
            </ol>

            <h2 id="both">Record both sides</h2>
            <p>
              On Android 12 and later, start here. Open One Recorder: <strong>Record both sides</strong> is at the top, and each row turns to Ready as you go.
            </p>
            <ol>
              <li>
                <strong>Developer options.</strong> If they&apos;re off, open <strong>Settings › About phone</strong> (on some phones, About phone › Software information) and tap{" "}
                <strong>Build number</strong> seven times.
              </li>
              <li>
                <strong>Pair with Wireless debugging.</strong> Tap the row. One Recorder opens Developer options and posts a notification. Turn on <strong>Wireless debugging</strong>, open it, and
                tap <strong>Pair device with pairing code</strong>.
              </li>
              <li>
                Keep that code on screen, pull down the notification from One Recorder, tap <strong>Enter code</strong> and type the six digits. One Recorder pairs and starts its helper. You only
                pair once.
              </li>
              <li>
                <strong>Helper: Ready.</strong> If it says Not running, make sure you&apos;re on Wi-Fi and tap <strong>Start</strong>. <strong>Start after a reboot</strong> turns on by itself the
                first time the helper starts.
              </li>
            </ol>
            <p>
              You can turn Wireless debugging off again: One Recorder switches it on for a moment when it needs to start the helper, and back off afterwards. If your phone stops the helper when
              Wireless debugging goes off, One Recorder leaves it on.
            </p>

            <h2 id="setup">Microphone method</h2>
            <p>
              For Android 10 and 11, or as a backup when the helper isn&apos;t running. With both sides ready, this is optional. It&apos;s the next section in One Recorder.
            </p>
            <ol>
              <li>
                <strong>Microphone.</strong> Tap it and choose Allow. This is how it records.
              </li>
              <li>
                <strong>Accessibility service.</strong> Tap it, find One Recorder under Installed apps (or Downloaded apps) and turn it on. Android warns that the app could see your screen. It doesn&apos;t: the
                service reads nothing and does nothing by itself. It&apos;s there only because Android lets apps with one use the microphone during a call.
              </li>
              <li>
                <strong>If the switch is grey or says Restricted setting</strong> (Android 13 and later): go back, tap <strong>Open App info</strong>, tap <strong>⋮</strong> in the top corner, choose{" "}
                <strong>Allow restricted settings</strong> and confirm with your PIN or fingerprint. Then turn the service on.
              </li>
              <li>
                <strong>Notifications.</strong> Allow them, so you can see when a call is being recorded.
              </li>
              <li>
                <strong>Battery: Unrestricted.</strong> Optional, but recommended. It stops the phone from closing the recorder while it waits for a call, which on some phones also turns the accessibility
                service off.
              </li>
            </ol>

            <h2 id="record">Record a call</h2>
            <ul>
              <li>
                During a call, tap <strong>⋮ › Record</strong> on One Dialer&apos;s call screen. Tap it again to stop. Recording also stops by itself when the call ends.
              </li>
              <li>The first time, One Dialer shows a short notice about consent. Recording starts once you accept it.</li>
              <li>
                <strong>Recording method</strong> (in One Recorder): <strong>Auto</strong> records both sides when the helper is running and falls back to the microphone when it isn&apos;t.{" "}
                <strong>Both sides only</strong> or <strong>Microphone only</strong> never switch.
              </li>
              <li>
                To record automatically, open One Dialer&apos;s <strong>Settings › Call recording</strong>. Auto-record can be off, every call, unknown numbers only, or only the contacts you pick, and a{" "}
                <strong>Never record</strong> list keeps chosen contacts out.
              </li>
            </ul>

            <h2 id="recordings">Your recordings</h2>
            <p>
              Find them in One Dialer under <strong>Calls › ⋮ › Recordings</strong>, or <strong>Settings › Call recording</strong>. They&apos;re grouped by day, with the contact&apos;s name, and you can
              search, filter (All, Starred, Contacts, Unknown), play, star, rename, share or delete them.
            </p>
            <p>
              The files live inside One Recorder. <strong>Save to phone</strong> copies one to your phone&apos;s <code>Recordings/One Dialer</code> folder, where your other apps can see it.{" "}
              <strong>Auto-delete</strong> can clear recordings after 30 or 90 days, always keeping starred ones.
            </p>

            <h2 id="sound">Getting a clearer caller</h2>
            <p>
              With both sides, the call is recorded straight from the line, so both voices are already at full volume. With the microphone method your own voice is always clear, and how well the
              other person comes through depends on your phone. These help:
            </p>
            <ul>
              <li>
                <strong>Use the speaker.</strong> The microphone hears the caller properly only when they&apos;re loud enough in the room.
              </li>
              <li>
                <strong>Volume boost</strong> (Settings › Call recording › Sound): Normal or Strong lifts quiet voices in the recording. Off by default.
              </li>
              <li>
                <strong>Microphone source</strong> (microphone method only): Automatic tries each of the phone&apos;s sources for a second on the first call and keeps the loudest. If one phone records the caller better on a
                particular source, pick it here.
              </li>
            </ul>

            <h2 id="how">How it works</h2>
            <p>
              The cleanest way to record a call is straight from the phone line, with both voices at full volume. Android keeps that for apps built into the phone, and for the{" "}
              <strong>shell</strong>: the account Android&apos;s own debugging tools run commands as. Wireless debugging lets an app on the phone start a program as that account, the way Shizuku does.
            </p>
            <p>
              That&apos;s what <strong>Record both sides</strong> does. Once paired, One Recorder starts a small helper from its own app as the shell. The helper does one thing: while One Recorder asks,
              it records the call and hands the sound back over a private connection inside the phone that only One Recorder holds the key to. It stops when One Recorder is updated or removed.
            </p>
            <p>
              The microphone method is the other way. Since Android 10, an app using the microphone during a call gets silence, unless it has an accessibility service turned on. That&apos;s why One Recorder has one, and why it does nothing
              else with it. It&apos;s also why recording lives in a separate app instead of One Dialer: Google Play doesn&apos;t allow accessibility services that are only there for this, and it keeps the
              Play app free of microphone access.
            </p>
            <p>
              One Dialer tells One Recorder when to start and stop. One Recorder records the audio, keeps the files, and answers only the Play-signed One Dialer.
            </p>

            <h2 id="privacy">Privacy</h2>
            <p>
              One Recorder records only while a call you chose to record is going on. The audio is saved only inside One Recorder on your phone. It&apos;s never uploaded, there&apos;s no
              account, and nothing about you or your calls leaves the phone unless you share a recording yourself. Recordings are deleted when you delete them or uninstall One Recorder.
            </p>
            <p>
              Its pairing with Wireless debugging is a key kept in One Recorder&apos;s private storage on your phone; it can&apos;t be backed up or read by other apps. The helper only records calls
              for One Recorder and can&apos;t run anything else. The accessibility service reads nothing on your screen and does nothing by itself; it&apos;s there only because Android needs it for the microphone during a call. Recording laws differ by
              country, and you&apos;re responsible for getting the other person&apos;s consent where it&apos;s required.
            </p>

            <h2 id="trouble">If it doesn&apos;t work</h2>
            <ul>
              <li>
                <strong>&ldquo;Both sides is paused&rdquo; in One Dialer, or Helper: Not running:</strong> the phone restarted away from Wi-Fi, or Developer options was turned off. Connect to
                Wi-Fi and tap <strong>Start</strong> in One Recorder. Until then, Auto records with the microphone.
              </li>
              <li>
                <strong>The pairing code isn&apos;t accepted:</strong> keep the pairing dialog open while you type the code, on the same Wi-Fi network. If it still fails, close the dialog, open it again
                for a new code and try once more.
              </li>
              <li>
                <strong>Both sides records only one voice, or nothing:</strong> some phones lose one side over Wi-Fi calling, and a few don&apos;t allow it at all. Switch Recording method to{" "}
                <strong>Microphone only</strong> on those.
              </li>
              <li>
                <strong>&ldquo;Calls aren&apos;t being recorded&rdquo; in One Dialer:</strong> auto-record is on but One Recorder isn&apos;t ready. Open it and fix any row that isn&apos;t Ready, usually
                the accessibility service.
              </li>
              <li>
                <strong>Recordings are silent:</strong> the accessibility service has been switched off. Turn it back on, and set Battery to Unrestricted so the phone doesn&apos;t switch it off again.
              </li>
              <li>
                <strong>Only your voice is in the recording:</strong> use the speaker, turn on Volume boost, or try a different Microphone source. On some phones the earpiece is simply too quiet for the
                microphone.
              </li>
              <li>
                <strong>&ldquo;The recorder works only with One Dialer from Google Play&rdquo;:</strong> One Dialer was installed from a file. Uninstall it and install it from Google Play, or update
                both apps.
              </li>
              <li>
                <strong>No Record option on the call screen:</strong> One Recorder isn&apos;t installed. One Dialer hides everything about recording until it is.
              </li>
            </ul>

            <h2 id="update">Update or remove it</h2>
            <ul>
              <li>
                <strong>To update,</strong> download the APK from this page again and install it over the old one. Your recordings and settings stay.
              </li>
              <li>
                <strong>To remove it,</strong> uninstall One Recorder like any app. That deletes every recording inside it, so save the ones you want to your phone first. One Dialer keeps working
                and hides its recording options again.
              </li>
              <li>Recording laws differ by country. Some need everyone on the call to agree. You&apos;re responsible for telling the other person and getting their consent where it&apos;s required.</li>
            </ul>
          </article>
        </div>
      </main>

      <Footer />
    </>
  );
}
