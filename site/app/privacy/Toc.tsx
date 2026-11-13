"use client";

import { useEffect, useState } from "react";

/** The policy's sections, with the one being read marked as the page scrolls. */
export function Toc({ sections, className = "" }: { sections: { id: string; title: string }[]; className?: string }) {
  const [active, setActive] = useState(sections[0]?.id);

  useEffect(() => {
    // A heading becomes the current one as it crosses a band near the top of the screen.
    const io = new IntersectionObserver((entries) => entries.forEach((e) => e.isIntersecting && setActive(e.target.id)), { rootMargin: "-15% 0px -75% 0px" });
    sections.forEach((s) => {
      const el = document.getElementById(s.id);
      if (el) io.observe(el);
    });
    return () => io.disconnect();
  }, [sections]);

  return (
    <nav aria-label="On this page" className={className}>
      <ol>
        {sections.map((s) => (
          <li key={s.id}>
            <a
              href={`#${s.id}`}
              aria-current={active === s.id ? "true" : undefined}
              className="block border-l border-white/10 py-2.5 pl-5 text-[16px] leading-snug text-ink-2 transition-[color,border-color,padding] duration-500 ease-settle hover:text-ink aria-[current]:border-white aria-[current]:pl-6 aria-[current]:text-ink"
            >
              {s.title}
            </a>
          </li>
        ))}
      </ol>
    </nav>
  );
}
