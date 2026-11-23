import { type Dict, en } from "./en";
import { de } from "./de";
import { es } from "./es";
import { it } from "./it";
import { ru } from "./ru";
import { tr } from "./tr";

export type { Block, Dict } from "./en";

// English stays at the site's own URLs (the app and Play link them); every other language lives under /<lang>/.
// The privacy policy and the release notes are English only.
export const LANGS = ["en", "it", "ru", "es", "tr", "de"] as const;
export type Lang = (typeof LANGS)[number];
export const NAMES: Record<Lang, string> = { en: "English", it: "Italiano", ru: "Русский", es: "Español", tr: "Türkçe", de: "Deutsch" };
export const DICTS: Record<Lang, Dict> = { en, it, ru, es, tr, de };

/** A page's path in a language, as next/link takes it ("/" or "/recorder/"). */
export const href = (lang: Lang, page = "/") => (lang === "en" ? page : `/${lang}${page}`);

/** Fills {name} placeholders. */
export const fill = (s: string, vars: Record<string, string | number>) => s.replace(/\{(\w+)\}/g, (_, k: string) => String(vars[k]));

// Absolute, as hreflang wants; the site is GitHub Pages' project site.
const SITE = "https://syedarhamraza.github.io/one-dialer";

/** hreflang links to every language of a page. */
export const alternates = (lang: Lang, page = "/") => ({
  canonical: `${SITE}${href(lang, page)}`,
  languages: { ...Object.fromEntries(LANGS.map((l) => [l, `${SITE}${href(l, page)}`])), "x-default": `${SITE}${page}` },
});
