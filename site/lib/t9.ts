const KEYS = ["abc", "def", "ghi", "jkl", "mno", "pqrs", "tuv", "wxyz"];
const digit = (c: string) => {
  const i = KEYS.findIndex((k) => k.includes(c));
  return i < 0 ? " " : `${i + 2}`;
};

/**
 * Where typed keypad digits match a name, T9-style: at the start of any word ("32" finds "Daniel" and
 * "Emma Clarke" is found by "25"). Returns the matched letters' [start, end), or null.
 * The page's keypad demo only; the app's own search is lib/features/keypad/t9.dart.
 */
export function t9Match(name: string, digits: string): [number, number] | null {
  if (!digits) return null;
  const code = [...name.toLowerCase()].map(digit).join("");
  for (let i = 0; i < code.length; i++) {
    if ((i === 0 || code[i - 1] === " ") && code.startsWith(digits, i)) return [i, i + digits.length];
  }
  return null;
}
