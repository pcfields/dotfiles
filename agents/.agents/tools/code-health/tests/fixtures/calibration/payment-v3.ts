// Calibration v3: validation fully extracted, named constants, small functions.

const SUPPORTED_CURRENCIES = new Set(["USD", "EUR", "GBP"]);
const RATES_TO_USD: Record<string, number> = { USD: 1, EUR: 1.08, GBP: 1.27 };
const CARD_NUMBER_LENGTH = 16;
const FEE_RATE = 0.029;
const FIXED_FEE = 0.3;
const LARGE_PAYMENT = 10000;
const LARGE_PAYMENT_FEE_DISCOUNT = 0.8;

type Payment = { amount: number; currency: string; card: Card };
type Card = { number: string; expiry: number };
type Result = { ok: true; charged: number; fee: number } | { ok: false; error: string };

export function processPayment(data: Payment | undefined): Result {
  const error = validatePayment(data);
  if (error) {
    return { ok: false, error };
  }
  const amount = toUsd(data.amount, data.currency);
  const fee = feeFor(amount);
  return { ok: true, charged: amount + fee, fee };
}

function validatePayment(data: Payment | undefined): string | null {
  if (!data) {
    return "No data";
  }
  return validateAmount(data.amount) ?? validateCurrency(data.currency) ?? validateCard(data.card);
}

function validateAmount(amount: number | undefined): string | null {
  return amount > 0 ? null : "Amount must be positive";
}

function validateCurrency(currency: string): string | null {
  return SUPPORTED_CURRENCIES.has(currency) ? null : "Unsupported currency";
}

function validateCard(card: Card | undefined): string | null {
  if (!card) {
    return "Missing card";
  }
  if (card.number?.length !== CARD_NUMBER_LENGTH) {
    return "Invalid card number";
  }
  return card.expiry > Date.now() ? null : "Card expired";
}

function toUsd(amount: number, currency: string): number {
  return amount * RATES_TO_USD[currency];
}

function feeFor(amount: number): number {
  const fee = amount * FEE_RATE + FIXED_FEE;
  return amount > LARGE_PAYMENT ? fee * LARGE_PAYMENT_FEE_DISCOUNT : fee;
}
