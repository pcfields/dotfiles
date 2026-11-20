// Calibration v2: guard clauses, with card validation and currency conversion extracted.

export function processPayment(data: any) {
  if (!data) {
    return { ok: false, error: "No data" };
  }
  if (data.amount === undefined || data.amount <= 0) {
    return { ok: false, error: "Amount must be positive" };
  }
  if (data.currency !== "USD" && data.currency !== "EUR" && data.currency !== "GBP") {
    return { ok: false, error: "Unsupported currency" };
  }
  const cardError = validateCard(data.card);
  if (cardError) {
    return { ok: false, error: cardError };
  }

  const amount = convert(data.amount, data.currency);
  let fee = amount * 0.029 + 0.3;
  if (amount > 10000) {
    fee = fee * 0.8;
  }
  return { ok: true, charged: amount + fee, fee: fee };
}

function validateCard(card: any): string | null {
  if (!card) {
    return "Missing card";
  }
  if (!card.number || card.number.length !== 16) {
    return "Invalid card number";
  }
  return card.expiry > Date.now() ? null : "Card expired";
}

function convert(amount: number, currency: string): number {
  if (currency === "EUR") {
    return amount * 1.08;
  }
  return currency === "GBP" ? amount * 1.27 : amount;
}
