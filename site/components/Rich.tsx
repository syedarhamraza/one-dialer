/** The recorder guide's light markup: **bold** and `code`. */
export function Rich({ text }: { text: string }) {
  return text
    .split(/(\*\*[^*]+\*\*|`[^`]+`)/)
    .map((s, i) => (s.startsWith("**") ? <strong key={i}>{s.slice(2, -2)}</strong> : s.startsWith("`") ? <code key={i}>{s.slice(1, -1)}</code> : s));
}
