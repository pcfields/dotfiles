// Mixed constructs for the LF/CRLF comparison.

export class Checkout {
  constructor(private readonly rates: Map<string, number>, public currency: string) {}

  /**
   * Multi-line doc comment.
   */
  total(lines: { price: number; quantity: number }[], coupon?: string): number {
    let sum = 0;
    for (const line of lines) {
      if (line.quantity > 0 && line.price >= 0) {
        if (line.quantity > 100 || coupon) {
          sum += 1;
        }
        sum += line.price * line.quantity;
      }
    }

    while (sum > 10_000) {
      if (coupon) {
        sum /= 2;
      }
    }

    const label = `total
for ${this.currency}`;
    return coupon ? sum * 0.9 : sum + label.length;
  }
}

export const describe = (items: string[]) => items.map((item) => (item.length > 3 ? item : "short"));
