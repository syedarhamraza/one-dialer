import type { Metadata } from "next";
import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";
import path from "node:path";
import Image from "next/image";
import Link from "next/link";
import { ArrowUpRightIcon, CaretDownIcon, GooglePlayLogoIcon, UsersThreeIcon } from "@phosphor-icons/react/dist/ssr";
import { Footer } from "@/components/Footer";
import { EffectsPicker, Keypad } from "@/components/Keypad";
import { Motion } from "@/components/Motion";
import { PlayButton } from "@/components/PlayButton";
import { SmoothScroll } from "@/components/SmoothScroll";
import { Stage } from "@/components/Stage";
import { WhatsNew } from "./WhatsNew";
import { GROUP_URL, PLAY_URL, RELEASED, REPO_URL, TESTING_URL } from "./links";

export const metadata: Metadata = {
  title: "One Dialer · Phone & call blocker for Android",
  description: `Fast T9 dialer with call blocking, dual SIM and a frosted glass design. ${RELEASED ? "Free on Google Play." : "Now in closed beta on Google Play."}`,
  icons: { icon: "/one-dialer/icon.png", apple: "/one-dialer/icon.png" },
  openGraph: {
    title: "One Dialer",
    description: "Fast T9 dialer with call blocking, dual SIM and a frosted glass design.",
    images: ["/one-dialer/og.png"],
  },
};

// Real screenshots from the phone (tool/store_graphics/captures, synced by `npm run sync`).
// Appends a hash of the file, so a re-synced screenshot under the same name isn't served from
// browsers' caches.
const v = (src: string) =>
  `${src}?v=${createHash("md5").update(readFileSync(path.join(process.cwd(), "public", src.replace("/one-dialer", "")))).digest("hex").slice(0, 8)}`;

// The slab turns through these in order; each title is also the giant word behind it.
const SCREENS = [
  { src: v("/one-dialer/app/2-keypad.webp"), title: "Keypad", body: "Frosted keys over your calls, with a Call key for each SIM." },
  { src: v("/one-dialer/app/1-calls.webp"), title: "Calls", body: "Missed calls in red, repeat calls grouped, blocked ones marked. The keypad is one tap away." },
  { src: v("/one-dialer/app/3-contacts.webp"), title: "Contacts", body: "Favourites first, then an A–Z index under your thumb." },
  { src: v("/one-dialer/app/5-incoming.webp"), title: "Incoming", body: "Full screen, tinted by the caller, right on the lock screen." },
  { src: v("/one-dialer/app/6-in-call.webp"), title: "In call", body: "Big glass controls for mute, hold, speaker and the dial pad." },
];

const DOES = [
  {
    title: "Blocks before it rings",
    text: "Private numbers, unknown callers, or anyone not in your contacts. Plus your phone's own block list.",
  },
  {
    title: "Dual SIM, done right",
    text: "A SIM for every contact, a default SIM, or ask every time. The call key shows which SIM you're on.",
  },
  {
    title: "A real phone app",
    text: "Every call goes through Android's own Telecom framework, so calls behave exactly like the system dialer's.",
  },
  {
    title: "Stays on your phone",
    text: "No account, no ads. Your calls and contacts never leave the device.",
  },
  {
    title: "Open source",
    text: "GPL-3.0. Read the code, report a bug or add your language.",
    href: REPO_URL,
    cta: "One Dialer on GitHub",
  },
];

// `beta` questions only make sense during the closed test; they go when RELEASED.
const FAQ = [
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
    a: `That copy isn't official: it won't get updates and may have been changed. Uninstall it, then ${RELEASED ? "install One Dialer" : "join the beta here to get it"} from Google Play.`,
  },
  { beta: true, q: "How do I leave the beta?", a: "Open the Google Play testing link and choose Leave the program, then uninstall the app if you like." },
].filter((f) => !(f.beta && RELEASED));

const pad = "px-[clamp(16px,4.4vw,64px)]";
const section = `mx-auto max-w-[1440px] ${pad} py-28 md:py-40`;
const h2 = "text-[clamp(2.5rem,5.6vw,5.25rem)] leading-[0.98] font-bold tracking-[-0.04em] text-balance";
const external = { target: "_blank", rel: "noopener noreferrer" };

function Step({ n, title, text, note, href, cta, icon }: { n: number; title: string; text: string; note: string; href: string; cta: string; icon: React.ReactNode }) {
  return (
    <li data-pop className="glass flex flex-col rounded-[var(--radius-card)] p-7 sm:p-10">
      {/* The numeral sits in a round key, like the 1 and 2 on the keypad's SIM call keys. */}
      <span aria-hidden className="tabular grid h-12 w-12 place-items-center rounded-full bg-white/10 text-[20px] font-semibold">
        {n}
      </span>
      <h3 className="mt-7 text-[clamp(1.6rem,2.4vw,2rem)] leading-tight font-bold tracking-[-0.035em]">
        <span className="sr-only">Step {n}: </span>
        {title}
      </h3>
      <p className="mt-3 max-w-[44ch] text-[17px] leading-relaxed text-ink-2">{text}</p>
      <p className="mt-3 max-w-[44ch] text-[15px] leading-relaxed text-ink-2">{note}</p>
      <div className="mt-auto pt-9">
        <a href={href} {...external} className={`press group inline-flex h-14 items-center gap-2.5 rounded-full px-7 text-[16px] font-semibold ${n === 1 ? "lit" : "bg-white/10 transition-colors hover:bg-white/[0.16]"}`}>
          {icon}
          {cta}
          <ArrowUpRightIcon size={16} weight="bold" className="transition-transform duration-500 ease-settle group-hover:translate-x-0.5 group-hover:-translate-y-0.5" />
        </a>
      </div>
    </li>
  );
}

export default function OneDialer() {
  return (
    <>
      <SmoothScroll />

      <header className={`site-header pointer-events-none fixed inset-x-0 top-0 z-50 flex items-center justify-between pt-4 ${pad}`}>
        <Link href="/" className="pointer-events-auto flex items-center gap-2.5 text-[17px] font-semibold tracking-[-0.02em]">
          <Image src="/one-dialer/icon.png" alt="" width={32} height={32} className="rounded-[9px]" priority />
          One Dialer
          {!RELEASED && <span className="rounded-full bg-white/10 px-2.5 py-0.5 text-[12px] font-semibold text-ink-2 max-sm:hidden">Beta</span>}
        </Link>
        <nav aria-label="Site" className="glass pointer-events-auto flex items-center rounded-full p-1.5 text-[15px] text-ink-2">
          <a href="#whats-new" className="px-4 transition-colors hover:text-ink max-md:hidden">
            What&apos;s new
          </a>
          <Link href="/recorder/" className="px-4 transition-colors hover:text-ink max-md:hidden">
            Recorder
          </Link>
          <Link href="/privacy/" className="px-4 transition-colors hover:text-ink max-md:hidden">
            Privacy
          </Link>
          <a href={REPO_URL} {...external} className="px-4 transition-colors hover:text-ink max-md:hidden">
            GitHub
          </a>
          <a
            {...(RELEASED ? { href: PLAY_URL, ...external } : { href: "#join" })}
            className="press inline-flex h-10 items-center gap-2 rounded-full bg-white/10 px-4 font-semibold text-ink transition-colors hover:bg-white/[0.16] md:ml-2"
          >
            {RELEASED ? (
              <>
                <GooglePlayLogoIcon size={17} weight="fill" /> Get the app
              </>
            ) : (
              "Join the beta"
            )}
          </a>
        </nav>
      </header>

      <main>
        <Stage screens={SCREENS} />

        <section className={`${section} grid grid-cols-1 gap-x-10 gap-y-12 lg:grid-cols-12`}>
          <h2 data-split className={`${h2} lg:sticky lg:top-28 lg:col-span-5 lg:self-start`}>
            What it does.
            <br />
            <span className="text-ink-2">And what it doesn&apos;t.</span>
          </h2>
          <ul className="glow-list lg:col-span-7">
            {DOES.map((d) => (
              <li key={d.title} data-rise className="group grid grid-cols-1 gap-x-8 gap-y-2 border-t border-white/10 py-7 last:border-b sm:grid-cols-[5fr_6fr]">
                <h3 className="text-[clamp(1.4rem,2.2vw,1.9rem)] leading-tight font-semibold tracking-[-0.03em] transition-transform duration-500 ease-settle group-hover:translate-x-2">
                  {d.title}
                </h3>
                <p className="max-w-[46ch] text-[17px] leading-relaxed text-ink-2">
                  {d.text}
                  {d.href && (
                    <>
                      {" "}
                      <a href={d.href} {...external} className="link whitespace-nowrap text-ink">
                        {d.cta}
                      </a>
                    </>
                  )}
                </p>
              </li>
            ))}
          </ul>
        </section>

        <section className={`${section} grid grid-cols-1 items-center gap-x-10 gap-y-16 lg:grid-cols-12`}>
          <div className="lg:order-2 lg:col-span-6 lg:col-start-7">
            <h2 data-split className={h2}>
              Smooth on
              <br />
              <span className="text-ink-2">every phone.</span>
            </h2>
            <p data-rise className="mt-7 max-w-[44ch] text-[18px] leading-relaxed text-ink-2">
              On first launch One Dialer reads your phone&apos;s chip and picks a level of visual effects, and you can change it in Settings. Try the three levels here: this
              page&apos;s glass follows, the keypad and the slab at the top included.
            </p>
            <div data-rise className="mt-9">
              <EffectsPicker />
            </div>
          </div>
          <div data-rise className="lg:col-span-5">
            <Keypad />
          </div>
        </section>

        <WhatsNew className={section} h2={h2} />

        {RELEASED ? (
          <section className={section}>
            <h2 data-split className={h2}>
              Get One Dialer.
              <br />
              <span className="text-ink-2">Free on Google Play.</span>
            </h2>
            <p data-rise className="mt-7 max-w-[46ch] text-[18px] leading-relaxed text-ink-2">
              Install it like any other app, then set One Dialer as your default phone app when it asks. Android 10 and newer.
            </p>
            <div data-rise className="mt-10">
              <span data-magnetic className="inline-block">
                <PlayButton className="h-16 px-9 text-[18px]" />
              </span>
            </div>
            <p data-rise className="mt-14 max-w-[70ch] text-[16px] leading-relaxed text-ink-2">
              <span className="font-semibold text-ink">Got One Dialer as an APK file?</span> Copies shared as files, or pulled out of a phone by another app, aren&apos;t official.
              They don&apos;t get updates and may have been changed. Uninstall it and install it from Google Play instead.
            </p>
          </section>
        ) : (
          <section id="join" className={`${section} scroll-mt-10`}>
            <h2 data-split className={h2}>
              Join the beta.
              <br />
              <span className="text-ink-2">Two steps.</span>
            </h2>
            <p data-rise className="mt-7 max-w-[46ch] text-[18px] leading-relaxed text-ink-2">
              One Dialer is in closed testing on Google Play. Join the testers group, then install it from Play like any other app.
            </p>
            <ol className="mt-14 grid grid-cols-1 gap-5 md:grid-cols-2">
              <Step
                n={1}
                title="Join the Google Group"
                text="Open the group and tap Join group. That puts your Google account on the testers list."
                note="Use the same Google account that's signed in on your phone's Play Store."
                href={GROUP_URL}
                cta="Join the group"
                icon={<UsersThreeIcon size={20} weight="fill" />}
              />
              <Step
                n={2}
                title="Become a tester on Google Play"
                text="Open the testing page, tap Become a tester, then Download it on Google Play and install."
                note="After joining the group it can take a few minutes for this page to let you in."
                href={TESTING_URL}
                cta="Become a tester"
                icon={<GooglePlayLogoIcon size={20} weight="fill" />}
              />
            </ol>
            <p data-rise className="mt-10 max-w-[70ch] text-[16px] leading-relaxed text-ink-2">
              <span className="font-semibold text-ink">Got One Dialer as an APK file?</span> Copies shared as files, or pulled out of a phone by another app, aren&apos;t official.
              They don&apos;t get updates and may have been changed. Uninstall it and join here instead.
            </p>
          </section>
        )}

        <section className={`${section} grid grid-cols-1 gap-x-10 gap-y-12 lg:grid-cols-12`}>
          <h2 data-split className={`${h2} lg:sticky lg:top-28 lg:col-span-5 lg:self-start`}>
            Questions,
            <br />
            <span className="text-ink-2">answered.</span>
          </h2>
          <div className="lg:col-span-7">
            {FAQ.map((f) => (
              <details key={f.q} data-rise className="faq group border-t border-white/10 last:border-b">
                <summary className="flex cursor-pointer list-none items-center gap-4 py-6 [&::-webkit-details-marker]:hidden">
                  <span className="flex-1 text-[clamp(1.05rem,1.5vw,1.3rem)] leading-snug transition-transform duration-500 ease-settle group-hover:translate-x-2">{f.q}</span>
                  <span className="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-white/[0.07] text-ink-2 transition-transform duration-500 ease-spring group-open:rotate-180 group-open:text-ink">
                    <CaretDownIcon size={16} weight="bold" />
                  </span>
                </summary>
                <p className="max-w-[60ch] pb-7 text-[17px] leading-relaxed text-ink-2">{f.a}</p>
              </details>
            ))}
          </div>
        </section>
      </main>

      <Footer />

      <Motion />
    </>
  );
}
