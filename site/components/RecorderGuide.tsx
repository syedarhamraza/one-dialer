import { Fragment } from "react";
import type { Metadata } from "next";
import Link from "next/link";
import { CaretLeftIcon, CheckIcon, DownloadSimpleIcon, MinusIcon } from "@phosphor-icons/react/dist/ssr";
import { Footer } from "@/components/Footer";
import { Rich } from "@/components/Rich";
import { SmoothScroll } from "@/components/SmoothScroll";
import { Toc } from "@/components/Toc";
import { RECORDER_URL } from "@/app/links";
import { type Block, DICTS, type Lang, alternates, href } from "@/i18n";

export function recorderMetadata(lang: Lang): Metadata {
  const t = DICTS[lang].meta;
  return { title: t.recorderTitle, description: t.recorderDescription, alternates: alternates(lang, "/recorder/"), openGraph: { locale: lang } };
}

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

function Blocks({ blocks }: { blocks: Block[] }) {
  return blocks.map((b, i) => {
    if ("p" in b)
      return (
        <p key={i}>
          <Rich text={b.p} />
        </p>
      );
    const items = "ul" in b ? b.ul : b.ol;
    const List = "ul" in b ? "ul" : "ol";
    return (
      <List key={i}>
        {items.map((s) => (
          <li key={s}>
            <Rich text={s} />
          </li>
        ))}
      </List>
    );
  });
}

export function RecorderGuide({ lang }: { lang: Lang }) {
  const t = DICTS[lang].recorder;
  return (
    <>
      <SmoothScroll />
      {/* The app's pushed-page header, as on the privacy policy. */}
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
        <div className="mt-10 flex flex-wrap items-center gap-x-6 gap-y-4">
          <a href={RECORDER_URL} className="press lit inline-flex h-14 items-center gap-2.5 rounded-full px-7 text-[16px] font-semibold">
            <DownloadSimpleIcon size={20} weight="bold" />
            {t.download}
          </a>
          <span className="text-[15px] text-ink-2">{t.downloadNote}</span>
        </div>

        <div className="mt-20 grid grid-cols-1 gap-5 md:mt-28 lg:grid-cols-2">
          <Card title={t.prosTitle} items={t.pros} good />
          <Card title={t.consTitle} items={t.cons} good={false} />
        </div>

        <h2 className="mt-24 text-[clamp(2.5rem,5.6vw,5.25rem)] leading-[0.98] font-bold tracking-[-0.04em] md:mt-36">
          {t.setup}
          <br />
          <span className="text-ink-2">{t.setupB}</span>
        </h2>

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

      <Footer lang={lang} page="/recorder/" />
    </>
  );
}
