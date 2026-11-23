import { Rich } from "@/components/Rich";
import { Shot } from "@/components/Shot";
import type { Block } from "@/i18n";

/** A guide section's body: paragraphs, lists, screenshots and setups, from the dictionary. */
export function Blocks({ blocks }: { blocks: Block[] }) {
  return blocks.map((b, i) => {
    if ("p" in b)
      return (
        <p key={i}>
          <Rich text={b.p} />
        </p>
      );
    if ("shot" in b) return <Shot key={i} id={b.shot} alt={b.alt} caption={b.caption} />;
    if ("setup" in b)
      return (
        <div key={i} className="setup">
          <h3>{b.setup}</h3>
          <p>
            <Rich text={b.when} />
          </p>
          <ol>
            {b.steps.map((s) => (
              <li key={s}>
                <Rich text={s} />
              </li>
            ))}
          </ol>
        </div>
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
