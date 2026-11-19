export function List({ items, title, compact }) {
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

export const Empty = (props) => <p>{props.label ?? "Nothing here"}</p>;
