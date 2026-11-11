import type { Metadata } from "next";
import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";
import path from "node:path";
import Image from "next/image";
import Link from "next/link";
import {
  ArrowUpRightIcon,
  CaretDownIcon,
  GooglePlayLogoIcon,
  LockKeyIcon,
  ProhibitIcon,
  SimCardIcon,
  UsersThreeIcon,
} from "@phosphor-icons/react/dist/ssr";
import { SmoothScroll } from "@/components/SmoothScroll";
import { ScreensPan } from "@/components/ScreensPan";
import { Hero } from "./Hero";
import { Reveal } from "./Reveal";
import { WhatsNew } from "./WhatsNew";
import { BETA, EMAIL, GROUP_URL, PLAY_URL, TESTING_URL } from "./links";

export const metadata: Metadata = {
  title: "One Dialer · Phone & call blocker for Android",
  description: "Fast T9 dialer with call blocking, dual SIM and a frosted glass design. Now in closed beta on Google Play.",
  icons: { icon: "/one-dialer/icon.png", apple: "/one-dialer/icon.png" },
  openGraph: {
    title: "One Dialer",
    description: "Fast T9 dialer with call blocking, dual SIM and a frosted glass design.",
    images: ["/one-dialer/og.png"],
  },
};

// Real screenshots from the phone (dialer repo tool/store_graphics/captures, synced by
// `npm run sync:dialer`).
// Appends a hash of the file, so a re-synced screenshot under the same name isn't served from
// browsers' caches.
const v = (src: string) =>
  `${src}?v=${createHash("md5").update(readFileSync(path.join(process.cwd(), "public", src.replace("/one-dialer", "")))).digest("hex").slice(0, 8)}`;

const SCREENS = [
  { src: v("/one-dialer/app/1-calls.webp"), title: "Calls", body: "Missed calls in red, repeat calls grouped, blocked ones marked. The keypad is one tap away." },
  { src: v("/one-dialer/app/2-keypad.webp"), title: "Keypad", body: "Frosted keys over your calls, with a Call key for each SIM." },
  { src: v("/one-dialer/app/3-contacts.webp"), title: "Contacts", body: "Favourites first, then an A–Z index under your thumb." },
  { src: v("/one-dialer/app/5-incoming.webp"), title: "Incoming call", body: "Full screen, tinted by the caller, right on the lock screen." },
  { src: v("/one-dialer/app/6-in-call.webp"), title: "In call", body: "Big glass controls for mute, hold, speaker and the dial pad." },
];

const MORE = [
  {
    icon: <ProhibitIcon size={26} weight="fill" />,
    title: "Blocks before it rings",
    text: "Private numbers, unknown callers, or anyone not in your contacts. Plus your phone's own block list.",
  },
  {
    icon: <SimCardIcon size={26} weight="fill" />,
    title: "Dual SIM, done right",
    text: "A SIM for every contact, a default SIM, or ask every time. The call key shows which SIM you're on.",
  },
  {
    icon: <LockKeyIcon size={26} weight="fill" />,
    title: "Stays on your phone",
    text: "No account, no ads. Your calls and contacts never leave the device.",
  },
];

const FAQ = [
  {
    q: "Why a closed beta?",
    a: "Google Play asks new apps to be tested by a group of people before they go public. Joining helps One Dialer get there, and you get every update first.",
  },
  {
    q: "The Play link says the app isn't available.",
    a: "Make sure you joined the Google Group with the same Google account that's signed in on your phone's Play Store. After joining, it can take a few minutes for the testing link to work.",
  },
  { q: "Which phones does it work on?", a: "Android 10 or newer. To make and receive calls, set One Dialer as your default phone app when it asks." },
  { q: "Is it free? Are there ads?", a: "It's free and has no ads." },
  {
    q: "Do my calls and contacts leave my phone?",
    a: "No. Your call history and contacts stay on your phone. The privacy policy lists exactly what is sent, such as crash reports.",
  },
  { q: "I got One Dialer as an APK file.", a: "That copy isn't official: it won't get updates and may have been changed. Uninstall it, then join the beta here to get it from Google Play." },
  { q: "How do I leave the beta?", a: "Open the Google Play testing link and choose Leave the program, then uninstall the app if you like." },
];

const h2 = "text-[clamp(2.5rem,5.6vw,5.25rem)] leading-[0.98] font-bold tracking-[-0.05em]";
const section = "mx-auto max-w-[1400px] px-4 py-28 sm:px-8 md:py-36";

function Step({ n, title, text, note, href, cta, icon }: { n: number; title: string; text: string; note: string; href: string; cta: string; icon: React.ReactNode }) {
  return (
    <div className="glass-3d rim flex h-full flex-col rounded-[var(--radius-card)] p-7 sm:p-10">
      <span className="text-[15px] font-semibold text-green">Step {n}</span>
      <h3 className="mt-3 text-[clamp(1.6rem,2.4vw,2rem)] leading-tight font-bold tracking-[-0.035em]">{title}</h3>
      <p className="mt-3 text-[17px] leading-relaxed text-ink-2">{text}</p>
      <p className="mt-3 text-[15px] leading-relaxed text-ink-3">{note}</p>
      <div className="mt-auto pt-9">
        <a
          href={href}
          target="_blank"
          rel="noopener noreferrer"
          className={`group inline-flex h-14 items-center gap-2.5 rounded-[var(--radius-pill)] px-7 text-[16px] font-semibold transition-[transform,background-color] active:scale-[0.97] ${
            n === 1 ? "bg-[linear-gradient(180deg,#5fd88a,#2fae5c)] text-black shadow-[0_10px_40px_rgb(0_192_90/0.3),inset_0_1px_0_rgb(255_255_255/0.4)]" : "bg-white/[0.08] hover:bg-white/[0.12]"
          }`}
        >
          {icon}
          {cta}
          <ArrowUpRightIcon size={16} weight="bold" className="transition-transform group-hover:-translate-y-0.5 group-hover:translate-x-0.5" />
        </a>
      </div>
    </div>
  );
}

export default function OneDialer() {
  return (
    <>
      <SmoothScroll />
      {/* One fixed aurora for the page, in the call screen's violet and the Call button's green. */}
      <div aria-hidden className="pointer-events-none fixed inset-0 -z-10 overflow-hidden">
        <div className="absolute -top-[30vmax] -right-[20vmax] h-[70vmax] w-[70vmax] rounded-full bg-[#6e3cd2] opacity-[0.13] blur-[100px]" />
        <div className="absolute -bottom-[35vmax] -left-[25vmax] h-[70vmax] w-[70vmax] rounded-full bg-[#00c05a] opacity-[0.08] blur-[100px]" />
      </div>

      <header className="pointer-events-none fixed inset-x-0 top-0 z-50 flex justify-center px-4 pt-3 sm:px-8">
        <div className="glass pointer-events-auto flex w-full max-w-[1400px] items-center justify-between rounded-[var(--radius-pill)] py-1.5 pr-1.5 pl-3">
          <Link href="/" className="flex items-center gap-2.5 text-[17px] font-semibold tracking-[-0.02em]">
            <Image src="/one-dialer/icon.png" alt="" width={32} height={32} className="rounded-[9px]" priority />
            One Dialer
            {BETA && <span className="rounded-full bg-green/15 px-2.5 py-0.5 text-[12px] font-semibold text-green max-sm:hidden">Beta</span>}
          </Link>
          <a href={BETA ? "#join" : PLAY_URL} className="inline-flex h-11 items-center rounded-[var(--radius-pill)] bg-white/[0.08] px-5 text-[15px] font-semibold transition-colors hover:bg-white/[0.14]">
            {BETA ? "Join the beta" : "Get it on Google Play"}
          </a>
        </div>
      </header>

      <main>
        <Hero phone={v("/one-dialer/app/5-incoming.webp")} />

        <ScreensPan
          screens={SCREENS}
          app="One Dialer"
          heading={
            <>
              Every screen,
              <br />
              <span className="text-ink-2">on true black.</span>
            </>
          }
          intro="Real screens from the app. Frosted glass, soft glow and spring motion, from your calls to the call screen."
        />

        <WhatsNew />

        {/* More */}
        <section className={section}>
          <div className="grid grid-cols-1 gap-5 md:grid-cols-3">
            {MORE.map((m, i) => (
              <Reveal key={m.title} delay={i * 0.08}>
                <div className="h-full rounded-[var(--radius-card)] bg-card p-8 sm:p-9">
                  <span className="grid h-14 w-14 place-items-center rounded-full bg-green/12 text-green">{m.icon}</span>
                  <h3 className="mt-7 text-[24px] font-bold tracking-[-0.03em]">{m.title}</h3>
                  <p className="mt-3 text-[16.5px] leading-relaxed text-ink-2">{m.text}</p>
                </div>
              </Reveal>
            ))}
          </div>
        </section>

        {/* Join */}
        {BETA && (
          <section id="join" className={`${section} scroll-mt-16`}>
            <Reveal>
              <h2 className={h2}>
                Join the beta.
                <br />
                <span className="text-ink-2">Two steps.</span>
              </h2>
              <p className="mt-7 max-w-[46ch] text-[18px] leading-relaxed text-ink-2">
                One Dialer is in closed testing on Google Play. Join the testers group, then install it from Play like any other app.
              </p>
            </Reveal>
            <div className="mt-14 grid grid-cols-1 gap-5 md:grid-cols-2">
              <Reveal>
                <Step
                  n={1}
                  title="Join the Google Group"
                  text="Open the group and tap Join group. That puts your Google account on the testers list."
                  note="Use the same Google account that's signed in on your phone's Play Store."
                  href={GROUP_URL}
                  cta="Join the group"
                  icon={<UsersThreeIcon size={20} weight="fill" />}
                />
              </Reveal>
              <Reveal delay={0.1}>
                <Step
                  n={2}
                  title="Become a tester on Google Play"
                  text="Open the testing page, tap Become a tester, then Download it on Google Play and install."
                  note="After joining the group it can take a few minutes for this page to let you in."
                  href={TESTING_URL}
                  cta="Become a tester"
                  icon={<GooglePlayLogoIcon size={20} weight="fill" />}
                />
              </Reveal>
            </div>
            <Reveal>
              <p className="mt-6 rounded-[var(--radius-inner)] bg-card px-7 py-5 text-[16px] leading-relaxed text-ink-2">
                <span className="font-semibold text-ink">Got One Dialer as an APK file?</span> Copies shared as files, or pulled out of a phone by
                another app, aren&apos;t official. They don&apos;t get updates and may have been changed. Uninstall it and join here instead.
              </p>
            </Reveal>
          </section>
        )}

        {/* FAQ */}
        <section className={`${section} grid grid-cols-1 gap-12 lg:grid-cols-12`}>
          <Reveal className="lg:col-span-4">
            <h2 className={h2}>
              Questions, <span className="text-ink-2">answered.</span>
            </h2>
          </Reveal>
          <Reveal className="overflow-hidden rounded-[var(--radius-card)] bg-card lg:col-span-8">
            {FAQ.map((f, i) => (
              <details key={f.q} className={`group ${i ? "border-t border-white/[0.06]" : ""}`}>
                <summary className="flex cursor-pointer list-none items-center gap-4 px-6 py-5 transition-colors hover:bg-white/[0.02] sm:px-8 [&::-webkit-details-marker]:hidden">
                  <span className="flex-1 text-[17px] sm:text-[18px] group-open:font-semibold">{f.q}</span>
                  <span className="grid h-8 w-8 shrink-0 place-items-center rounded-full bg-white/[0.05] text-ink-2 transition-transform duration-300 group-open:rotate-180 group-open:bg-green/15 group-open:text-green">
                    <CaretDownIcon size={16} weight="bold" />
                  </span>
                </summary>
                <p className="max-w-[62ch] px-6 pb-6 text-[16px] leading-relaxed text-ink-2 sm:px-8">{f.a}</p>
              </details>
            ))}
          </Reveal>
        </section>
      </main>

      <footer className="mx-auto flex max-w-[1400px] flex-wrap items-center justify-between gap-4 border-t border-white/[0.06] px-4 py-10 text-[14px] text-ink-3 sm:px-8">
        <span>© {new Date().getFullYear()} Syed Arham Raza</span>
        <nav className="flex gap-6">
          <Link href="/privacy/" className="hover:text-ink">
            Privacy policy
          </Link>
          <a href={`mailto:${EMAIL}?subject=One%20Dialer`} className="hover:text-ink">
            Contact
          </a>
        </nav>
      </footer>
    </>
  );
}
