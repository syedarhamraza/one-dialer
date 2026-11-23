import Link from "next/link";
import { BugIcon, LightbulbIcon } from "@phosphor-icons/react/dist/ssr";
import { BUG_URL, EMAIL, FEATURE_URL, REPO_URL } from "@/app/links";
import { DICTS, LANGS, type Lang, NAMES, href } from "@/i18n";

const pill = "press inline-flex h-12 items-center gap-2.5 rounded-full bg-white/10 px-6 text-[15px] font-semibold text-ink transition-colors hover:bg-white/[0.16]";

/**
 * The page's close: feedback, the name at full width, then the small print. `recorder={false}` on the
 * privacy page: it's One Dialer's privacy URL on Google Play, which mustn't point to the recorder.
 * With a `page`, it lists that page in every language.
 */
export function Footer({ recorder = true, lang = "en", page }: { recorder?: boolean; lang?: Lang; page?: string }) {
  const t = DICTS[lang].footer;
  return (
    <footer className="mx-auto max-w-[1440px] overflow-hidden px-[clamp(16px,4.4vw,64px)] pt-10 pb-10">
      <div className="mb-14 flex flex-wrap items-center justify-between gap-x-10 gap-y-6 border-t border-white/10 pt-10">
        <p className="text-[clamp(1.4rem,2.4vw,1.9rem)] leading-tight font-bold tracking-[-0.03em]">
          {t.bug} <span className="text-ink-2">{t.idea}</span>
        </p>
        <div className="flex flex-wrap gap-3">
          <a href={FEATURE_URL} target="_blank" rel="noopener noreferrer" className={pill}>
            <LightbulbIcon size={18} weight="fill" />
            {t.feature}
          </a>
          <a href={BUG_URL} target="_blank" rel="noopener noreferrer" className={pill}>
            <BugIcon size={18} weight="fill" />
            {t.report}
          </a>
        </div>
      </div>
      <p data-wordmark aria-hidden className="text-[clamp(3.6rem,17.5vw,17rem)] leading-[0.9] font-bold tracking-[-0.04em] whitespace-nowrap text-card-hi">
        One Dialer
      </p>
      {page && (
        <nav aria-label={t.language} className="mt-10 flex flex-wrap gap-2 border-t border-white/10 pt-8">
          {LANGS.map((l) => (
            <Link
              key={l}
              href={href(l, page)}
              lang={l}
              hrefLang={l}
              aria-current={l === lang ? "page" : undefined}
              className="press inline-flex h-10 items-center rounded-full px-4 text-[15px] text-ink-2 transition-colors hover:text-ink aria-[current]:bg-white/10 aria-[current]:font-semibold aria-[current]:text-ink"
            >
              {NAMES[l]}
            </Link>
          ))}
        </nav>
      )}
      <div className={`flex flex-wrap items-center justify-between gap-4 border-t border-white/10 pt-8 text-[15px] text-ink-2 ${page ? "mt-8" : "mt-10"}`}>
        <span>© {new Date().getFullYear()} Syed Arham Raza</span>
        <nav aria-label={t.label} className="flex flex-wrap gap-x-7 gap-y-3">
          {recorder && (
            <Link href={href(lang, "/recorder/")} className="link">
              {t.recorder}
            </Link>
          )}
          <Link href="/privacy/" className="link">
            {t.privacy}
          </Link>
          <a href={REPO_URL} target="_blank" rel="noopener noreferrer" className="link">
            GitHub
          </a>
          <a href={`mailto:${EMAIL}?subject=One%20Dialer`} className="link">
            {t.contact}
          </a>
        </nav>
      </div>
    </footer>
  );
}
