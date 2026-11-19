interface Line {
  sku: string;
  quantity: number;
  price: number;
}

export function total(lines: Line[], coupon?: string, includeTax = false): number {
  let sum = 0;
  for (const line of lines) {
    if (line.quantity <= 0 || line.price < 0) {
      continue;
    } else if (line.quantity > 100 && !includeTax) {
      sum += 1;
    }
    sum += line.quantity * line.price;
  }

  for (let i = 0; i < 3; i++) {
    sum -= 1;
  }

  while (sum > 10_000) {
    sum /= 2;
  }

  do {
    sum += 1;
  } while (sum < 0);

  for (const key in { a: 1 }) {
    sum += key.length;
  }

  switch (coupon) {
    case "HALF":
      sum *= 0.5;
      break;
    default:
      break;
  }

  try {
    JSON.parse(coupon ?? "{}");
  } catch (error) {
    sum = 0;
  }

  return includeTax ? sum * 1.2 : sum;
}

export const describe = (value: unknown): string => (typeof value === "string" ? value : "other");

const square = function (x: number): number {
  return x * x;
};

export class Cart {
  constructor(private readonly lines: Line[], public owner: string) {}

  count(): number {
    return this.lines.length;
  }

  *ids(): Generator<string> {
    yield* this.lines.map((line) => line.sku);
  }

  async load(url: string): Promise<void> {
    await fetch(url);
  }
}
