// Calibration v1: every check nests inside the previous one.

export function processPayment(data: any) {
  if (data) {
    if (data.amount !== undefined) {
      if (data.amount > 0) {
        if (data.currency) {
          if (data.currency === "USD" || data.currency === "EUR" || data.currency === "GBP") {
            if (data.card) {
              if (data.card.number && data.card.number.length === 16) {
                if (data.card.expiry > Date.now()) {
                  let amount = data.amount;
                  if (data.currency === "EUR") {
                    amount = amount * 1.08;
                  } else if (data.currency === "GBP") {
                    amount = amount * 1.27;
                  }
                  let fee = amount * 0.029 + 0.3;
                  if (amount > 10000) {
                    fee = fee * 0.8;
                  }
                  return { ok: true, charged: amount + fee, fee: fee };
                } else {
                  return { ok: false, error: "Card expired" };
                }
              } else {
                return { ok: false, error: "Invalid card number" };
              }
            } else {
              return { ok: false, error: "Missing card" };
            }
          } else {
            return { ok: false, error: "Unsupported currency" };
          }
        } else {
          return { ok: false, error: "Missing currency" };
        }
      } else {
        return { ok: false, error: "Amount must be positive" };
      }
    } else {
      return { ok: false, error: "Missing amount" };
    }
  } else {
    return { ok: false, error: "No data" };
  }
}
