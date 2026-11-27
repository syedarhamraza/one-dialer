import { Fragment } from "react";
import type { Metadata } from "next";
import Link from "next/link";
import { CaretLeftIcon } from "@phosphor-icons/react/dist/ssr";
import { Blocks } from "@/components/Blocks";
import { Footer } from "@/components/Footer";
import { SmoothScroll } from "@/components/SmoothScroll";
import { Toc } from "@/components/Toc";
import { DICTS, type Lang, alternates, href } from "@/i18n";

export function guideMetadata(lang: Lang): Metadata {
  const t = DICTS[lang].meta;
  return { title: t.guideTitle, description: t.guideDescription, alternates: alternates(lang, "/guide/"), openGraph: { locale: lang } };
}

/** One Dialer's guide: each part of the app with screenshots, then setups for common situations. Laid out like the recorder guide. */
export function DialerGuide({ lang }: { lang: Lang }) {
  const t = DICTS[lang].guide;
  return (
    <>
      <SmoothScroll />
      <header className="subpage-bar sticky top-0 z-50 flex h-[72px] items-center gap-4 px-[clamp(16px,4.4vw,64px)]">
        <Link href={href(lang)} aria-label={t.back} className="glass press grid h-11 w-11 place-items-center rounded-full">
          <CaretLeftIcon size={20} weight="bold" />
        </Link>
        <span aria-hidden className="subpage-title text-[18px] font-semibold tracking-[-0.02em]">
          {t.title}
        </span>
      </header>

      <main className="mx-auto max-w-[1440px] px-[clamp(16px,4.4vw,64px)] pt-8 pb-28 md:pt-14 md:pb-40">
        <h1 className="text-[clamp(3rem,8vw,6rem)] leading-[0.94] font-bold tracking-[-0.04em]">
          {t.h1}
          <br />
          <span className="text-ink-2">{t.h1b}</span>
        </h1>
        <p className="mt-7 max-w-[46ch] text-[18px] leading-relaxed text-ink-2">{t.lead}</p>

        <div className="mt-14 grid grid-cols-1 gap-x-10 gap-y-12 md:mt-20 lg:grid-cols-12">
          <Toc sections={t.sections} label={t.toc} className="lg:sticky lg:top-28 lg:col-span-4 lg:self-start" />
          <article className="policy guide lg:col-span-8">
            <p>{t.intro}</p>
            {t.sections.map((s) => (
              <Fragment key={s.id}>
                <h2 id={s.id}>{s.title}</h2>
                <Blocks blocks={s.blocks} />
              </Fragment>
            ))}
          </article>
        </div>
      </main>

      <Footer lang={lang} page="/guide/" />
    </>
  );
}
