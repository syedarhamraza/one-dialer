import Link from "next/link";
import { EMAIL, REPO_URL } from "@/app/links";

/** The page's close: the name at full width, then the small print. */
export function Footer() {
  return (
    <footer className="mx-auto max-w-[1440px] overflow-hidden px-[clamp(16px,4.4vw,64px)] pt-10 pb-10">
      <p data-wordmark aria-hidden className="text-[clamp(3.6rem,17.5vw,17rem)] leading-[0.9] font-bold tracking-[-0.04em] whitespace-nowrap text-card-hi">
        One Dialer
      </p>
      <div className="mt-10 flex flex-wrap items-center justify-between gap-4 border-t border-white/10 pt-8 text-[15px] text-ink-2">
        <span>© {new Date().getFullYear()} Syed Arham Raza</span>
        <nav aria-label="Footer" className="flex gap-7">
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
