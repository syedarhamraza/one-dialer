import { LANGS, type Lang } from "@/i18n";

// The translated copies of the home page and the recorder guide; English is the site's own root.
export const translated = () => LANGS.filter((l) => l !== "en").map((lang) => ({ lang }));
export type Params = { params: Promise<{ lang: Lang }> };
