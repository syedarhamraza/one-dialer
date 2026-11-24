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
import { WhatsNew } from "@/components/WhatsNew";
import { GROUP_URL, PLAY_URL, RELEASED, REPO_URL, TESTING_URL } from "@/app/links";
import { DICTS, type Lang, alternates, fill, href } from "@/i18n";

export function homeMetadata(lang: Lang): Metadata {
  const t = DICTS[lang].meta;
  return {
    title: t.title,
    description: `${t.description} ${RELEASED ? t.released : t.beta}`,
    icons: { icon: "/one-dialer/icon.png", apple: "/one-dialer/icon.png" },
    alternates: alternates(lang),
    openGraph: { title: "One Dialer", description: t.description, images: ["/one-dialer/og.png"], locale: lang },
  };
}

// Real screenshots from the phone (tool/store_graphics/captures, synced by `npm run sync`).
// Appends a hash of the file, so a re-synced screenshot under the same name isn't served from
// browsers' caches.
const v = (src: string) =>
  `${src}?v=${createHash("md5").update(readFileSync(path.join(process.cwd(), "public", src.replace("/one-dialer", "")))).digest("hex").slice(0, 8)}`;

// The slab turns through these in order, with the dictionary's `screens` as their words.
const SHOTS = ["2-keypad", "1-calls", "3-contacts", "5-incoming", "6-in-call"].map((s) => v(`/one-dialer/app/${s}.webp`));

const pad = "px-[clamp(16px,4.4vw,64px)]";
const section = `mx-auto max-w-[1440px] ${pad} py-28 md:py-40`;
const h2 = "text-[clamp(2.5rem,5.6vw,5.25rem)] leading-[0.98] font-bold tracking-[-0.04em] text-balance";
const external = { target: "_blank", rel: "noopener noreferrer" };

function Step({ n, label, title, text, note, href, cta, icon }: { n: number; label: string; title: string; text: string; note: string; href: string; cta: string; icon: React.ReactNode }) {
  return (
    <li data-pop className="glass flex flex-col rounded-[var(--radius-card)] p-7 sm:p-10">
      {/* The numeral sits in a round key, like the 1 and 2 on the keypad's SIM call keys. */}
      <span aria-hidden className="tabular grid h-12 w-12 place-items-center rounded-full bg-white/10 text-[20px] font-semibold">
        {n}
      </span>
      <h3 className="mt-7 text-[clamp(1.6rem,2.4vw,2rem)] leading-tight font-bold tracking-[-0.035em]">
        <span className="sr-only">{label}</span>
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

export function Home({ lang }: { lang: Lang }) {
  const t = DICTS[lang];
  const screens = t.screens.map((s, i) => ({ ...s, src: SHOTS[i] }));
  const faq = t.faq.items.filter((f) => !(f.beta && RELEASED)).map((f) => ({ q: f.q, a: !RELEASED && f.aBeta ? f.aBeta : f.a }));
  const apk = (
    <>
      <span className="font-semibold text-ink">{t.apk.title}</span> {t.apk.text} {RELEASED ? t.apk.released : t.apk.beta}
    </>
  );

  return (
    <>
      <SmoothScroll />

      <header className={`site-header pointer-events-none fixed inset-x-0 top-0 z-50 flex items-center justify-between pt-4 ${pad}`}>
        <Link href={href(lang)} className="pointer-events-auto flex items-center gap-2.5 text-[17px] font-semibold tracking-[-0.02em]">
          <Image src="/one-dialer/icon.png" alt="" width={32} height={32} className="rounded-[9px]" priority />
          One Dialer
          {!RELEASED && <span className="rounded-full bg-white/10 px-2.5 py-0.5 text-[12px] font-semibold text-ink-2 max-sm:hidden">{t.nav.beta}</span>}
        </Link>
        <nav aria-label={t.nav.label} className="glass pointer-events-auto flex items-center rounded-full p-1.5 text-[15px] text-ink-2">
          <a href="#whats-new" className="px-4 whitespace-nowrap transition-colors hover:text-ink max-lg:hidden">
            {t.nav.whatsNew}
          </a>
          <Link href={href(lang, "/recorder/")} className="px-4 transition-colors hover:text-ink max-md:hidden">
            {t.nav.recorder}
          </Link>
          <Link href="/privacy/" className="px-4 transition-colors hover:text-ink max-md:hidden">
            {t.nav.privacy}
          </Link>
          <a href={REPO_URL} {...external} className="px-4 transition-colors hover:text-ink max-md:hidden">
            GitHub
          </a>
          <a
            {...(RELEASED ? { href: PLAY_URL, ...external } : { href: "#join" })}
            className="press inline-flex h-10 items-center gap-2 rounded-full bg-white/10 px-4 font-semibold whitespace-nowrap text-ink transition-colors hover:bg-white/[0.16] md:ml-2"
          >
            {RELEASED ? (
              <>
                <GooglePlayLogoIcon size={17} weight="fill" /> {t.nav.getApp}
              </>
            ) : (
              t.nav.joinBeta
            )}
          </a>
        </nav>
      </header>

      <main>
        <Stage screens={screens} t={{ ...t.stage, joinBeta: t.nav.joinBeta, play: t.play }} />

        <section className={`${section} grid grid-cols-1 gap-x-10 gap-y-12 lg:grid-cols-12`}>
          <h2 data-split className={`${h2} lg:sticky lg:top-28 lg:col-span-5 lg:self-start`}>
            {t.does.h}
            <br />
            <span className="text-ink-2">{t.does.h2}</span>
          </h2>
          <ul className="glow-list lg:col-span-7">
            {t.does.items.map((d, i) => (
              <li key={d.title} data-rise className="group grid grid-cols-1 gap-x-8 gap-y-2 border-t border-white/10 py-7 last:border-b sm:grid-cols-[5fr_6fr]">
                <h3 className="text-[clamp(1.4rem,2.2vw,1.9rem)] leading-tight font-semibold tracking-[-0.03em] transition-transform duration-500 ease-settle group-hover:translate-x-2">
                  {d.title}
                </h3>
                <p className="max-w-[46ch] text-[17px] leading-relaxed text-ink-2">
                  {d.text}
                  {/* The last one is Open source. */}
                  {i === t.does.items.length - 1 && (
                    <>
                      {" "}
                      <a href={REPO_URL} {...external} className="link whitespace-nowrap text-ink">
                        {t.does.github}
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
              {t.smooth.h}
              <br />
              <span className="text-ink-2">{t.smooth.h2}</span>
            </h2>
            <p data-rise className="mt-7 max-w-[44ch] text-[18px] leading-relaxed text-ink-2">
              {t.smooth.text}
            </p>
            <div data-rise className="mt-9">
              <EffectsPicker t={t.levels} />
            </div>
          </div>
          <div data-rise className="lg:col-span-5">
            <Keypad t={{ ...t.keypad, joinBeta: t.nav.joinBeta, play: t.play }} cyrillic={lang === "ru"} />
          </div>
        </section>

        <WhatsNew className={section} h2={h2} lang={lang} />

        {RELEASED ? (
          <section className={section}>
            <h2 data-split className={h2}>
              {t.get.h}
              <br />
              <span className="text-ink-2">{t.get.h2}</span>
            </h2>
            <p data-rise className="mt-7 max-w-[46ch] text-[18px] leading-relaxed text-ink-2">
              {t.get.text}
            </p>
            <div data-rise className="mt-10">
              <span data-magnetic className="inline-block">
                <PlayButton label={t.play} className="h-16 px-9 text-[18px]" />
              </span>
            </div>
            <p data-rise className="mt-14 max-w-[70ch] text-[16px] leading-relaxed text-ink-2">
              {apk}
            </p>
          </section>
        ) : (
          <section id="join" className={`${section} scroll-mt-10`}>
            <h2 data-split className={h2}>
              {t.join.h}
              <br />
              <span className="text-ink-2">{t.join.h2}</span>
            </h2>
            <p data-rise className="mt-7 max-w-[46ch] text-[18px] leading-relaxed text-ink-2">
              {t.join.text}
            </p>
            <ol className="mt-14 grid grid-cols-1 gap-5 md:grid-cols-2">
              <Step n={1} label={fill(t.join.step, { n: 1 })} {...t.join.group} href={GROUP_URL} icon={<UsersThreeIcon size={20} weight="fill" />} />
              <Step n={2} label={fill(t.join.step, { n: 2 })} {...t.join.tester} href={TESTING_URL} icon={<GooglePlayLogoIcon size={20} weight="fill" />} />
            </ol>
            <p data-rise className="mt-10 max-w-[70ch] text-[16px] leading-relaxed text-ink-2">
              {apk}
            </p>
          </section>
        )}

        <section className={`${section} grid grid-cols-1 gap-x-10 gap-y-12 lg:grid-cols-12`}>
          <h2 data-split className={`${h2} lg:sticky lg:top-28 lg:col-span-5 lg:self-start`}>
            {t.faq.h}
            <br />
            <span className="text-ink-2">{t.faq.h2}</span>
          </h2>
          <div className="lg:col-span-7">
            {faq.map((f) => (
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

      <Footer lang={lang} page="/" />

      <Motion />
    </>
  );
}
