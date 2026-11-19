export function total(lines, coupon, includeTax = false) {
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

  while (sum > 10000) {
    sum /= 2;
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
  } catch {
    sum = 0;
  }

  return includeTax ? sum * 1.2 : sum;
}

export const describe = (value) => (typeof value === "string" ? value : "other");

const square = function (x) {
  return x * x;
};

export class Cart {
  constructor(lines, owner) {
    this.lines = lines;
    this.owner = owner;
  }

  count() {
    return this.lines.length;
  }
}
