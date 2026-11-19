type Props = { items: string[]; title?: string; compact: boolean };

export function List({ items, title, compact }: Props) {
  if (items.length === 0 && !title) {
    return null;
  }
  return (
    <section>
      {title ? <h2>{title}</h2> : null}
      <ul className={compact || items.length > 10 ? "compact" : "full"}>
        {items.map((item) => (
          <li key={item}>{item}</li>
        ))}
      </ul>
    </section>
  );
}

export const Empty = (props: { label: string }) => <p>{props.label ?? "Nothing here"}</p>;
