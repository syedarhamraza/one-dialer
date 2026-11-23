const KEYS = ["abc", "def", "ghi", "jkl", "mno", "pqrs", "tuv", "wxyz"];
/** The Russian letters on each key, as AOSP's dialer has them; the Russian page shows them on the keys. */
export const CYRILLIC: Record<string, string> = { "2": "АБВГ", "3": "ДЕЁЖЗ", "4": "ИЙКЛ", "5": "МНОП", "6": "РСТУ", "7": "ФХЦЧ", "8": "ШЩЪЫ", "9": "ЬЭЮЯ" };
const CYR = Object.entries(CYRILLIC).map(([d, l]) => [d, l.toLowerCase()]);

// Accents fold onto their base letter (é → e, ß → s, ı → i), and Cyrillic is always searched, like the app's T9.
const digit = (ch: string) => {
  const c = ch.normalize("NFD").replace(/[̀-ͯ]/g, "").replace("ß", "s").replace("ı", "i");
  const i = KEYS.findIndex((k) => k.includes(c));
  if (i >= 0) return `${i + 2}`;
  return CYR.find(([, l]) => l.includes(ch))?.[0] ?? " ";
};

/**
 * Where typed keypad digits match a name, T9-style: at the start of any word ("32" finds "Daniel" and
 * "Emma Clarke" is found by "25"). Returns the matched letters' [start, end), or null.
 * The page's keypad demo only; the app's own search is lib/features/keypad/t9.dart.
 */
export function t9Match(name: string, digits: string): [number, number] | null {
  if (!digits) return null;
  // One code per UTF-16 unit of the name, so the range slices the name itself.
  const code = name
    .toLowerCase()
    .split("")
    .map(digit)
    .join("");
  for (let i = 0; i < code.length; i++) {
    if ((i === 0 || code[i - 1] === " ") && code.startsWith(digits, i)) return [i, i + digits.length];
  }
  return null;
}
