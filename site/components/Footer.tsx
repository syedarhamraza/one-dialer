import Link from "next/link";
import { BugIcon, LightbulbIcon } from "@phosphor-icons/react/dist/ssr";
import { BUG_URL, EMAIL, FEATURE_URL, REPO_URL } from "@/app/links";

const pill = "press inline-flex h-12 items-center gap-2.5 rounded-full bg-white/10 px-6 text-[15px] font-semibold text-ink transition-colors hover:bg-white/[0.16]";

/** The page's close: feedback, the name at full width, then the small print. */
export function Footer() {
  return (
    <footer className="mx-auto max-w-[1440px] overflow-hidden px-[clamp(16px,4.4vw,64px)] pt-10 pb-10">
      <div className="mb-14 flex flex-wrap items-center justify-between gap-x-10 gap-y-6 border-t border-white/10 pt-10">
        <p className="text-[clamp(1.4rem,2.4vw,1.9rem)] leading-tight font-bold tracking-[-0.03em]">
          Found a bug? <span className="text-ink-2">Have an idea?</span>
        </p>
        <div className="flex flex-wrap gap-3">
          <a href={FEATURE_URL} target="_blank" rel="noopener noreferrer" className={pill}>
            <LightbulbIcon size={18} weight="fill" />
            Request a feature
          </a>
          <a href={BUG_URL} target="_blank" rel="noopener noreferrer" className={pill}>
            <BugIcon size={18} weight="fill" />
            Report a bug
          </a>
        </div>
      </div>
      <p data-wordmark aria-hidden className="text-[clamp(3.6rem,17.5vw,17rem)] leading-[0.9] font-bold tracking-[-0.04em] whitespace-nowrap text-card-hi">
        One Dialer
      </p>
      <div className="mt-10 flex flex-wrap items-center justify-between gap-4 border-t border-white/10 pt-8 text-[15px] text-ink-2">
        <span>© {new Date().getFullYear()} Syed Arham Raza</span>
        <nav aria-label="Footer" className="flex flex-wrap gap-x-7 gap-y-3">
          <Link href="/recorder/" className="link">
            One Recorder
          </Link>
          <Link href="/privacy/" className="link">
            Privacy policy
          </Link>
          <a href={REPO_URL} target="_blank" rel="noopener noreferrer" className="link">
            GitHub
          </a>
          <a href={`mailto:${EMAIL}?subject=One%20Dialer`} className="link">
            Contact
          </a>
        </nav>
      </div>
    </footer>
  );
}
