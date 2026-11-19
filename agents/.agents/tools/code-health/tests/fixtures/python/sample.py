from dataclasses import dataclass


@dataclass(frozen=True)
class Line:
    sku: str
    quantity: int
    price: float


def total(lines: list[Line], coupon: str | None = None, *, include_tax: bool = False) -> float:
    result = 0.0
    for line in lines:
        if line.quantity <= 0 or line.price < 0:
            continue
        elif line.quantity > 100 and not include_tax:
            result += 1
        result += line.quantity * line.price

    while result > 10_000:
        result /= 2

    match coupon:
        case "HALF":
            result *= 0.5
        case str(code) if len(code) > 10:
            result -= 1
        case _:
            pass

    try:
        int(coupon or "0")
    except ValueError:
        result = 0
    finally:
        pass

    with open("/dev/null") as sink:
        sink.read()

    discounts = [d for d in (0.1, 0.2) if d < 0.15]
    return result * 1.2 if include_tax else result - sum(discounts)


square = lambda x: x * x


class Cart:
    def __init__(self, lines: list[Line], owner: str) -> None:
        self.lines = lines
        self.owner = owner

    def count(self) -> int:
        return len(self.lines)

    @classmethod
    def empty(cls, owner: str, *args, **kwargs) -> "Cart":
        return cls([], owner)

    async def load(self, url: str) -> None:
        async for _ in self._stream(url):
            pass

    async def _stream(self, url: str):
        yield url


if __name__ == "__main__":
    print(total([Line("a", 1, 2.0)]))
