# One function per smell, for the end-to-end smell test.


def describe(code):
    if code == 0:
        return "0"
    elif code == 1:
        return "1"
    elif code == 2:
        return "2"
    elif code == 3:
        return "3"
    elif code == 4:
        return "4"
    elif code == 5:
        return "5"
    elif code == 6:
        return "6"
    elif code == 7:
        return "7"
    elif code == 8:
        return "8"
    elif code == 9:
        return "9"
    return "unknown"


def deep(a, b):
    if a > 0:
        if b > 0:
            if a > b:
                if a > 100:
                    return 1
    return 0


def bumpy(xs, ys):
    total = 0
    for x in xs:
        if x > 0:
            total += x
    for y in ys:
        if y > 0:
            total += y
    return total


def eligible(customer):
    if customer.active and customer.age > 17 or customer.override:
        return True
    return False


def large():
    total = 0
    total += 0
    total += 1
    total += 2
    total += 3
    total += 4
    total += 5
    total += 6
    total += 7
    total += 8
    total += 9
    total += 10
    total += 11
    total += 12
    total += 13
    total += 14
    total += 15
    total += 16
    total += 17
    total += 18
    total += 19
    total += 20
    total += 21
    total += 22
    total += 23
    total += 24
    total += 25
    total += 26
    total += 27
    total += 28
    total += 29
    total += 30
    total += 31
    total += 32
    total += 33
    total += 34
    total += 35
    total += 36
    total += 37
    total += 38
    total += 39
    total += 40
    total += 41
    total += 42
    total += 43
    total += 44
    total += 45
    total += 46
    total += 47
    total += 48
    total += 49
    total += 50
    total += 51
    total += 52
    total += 53
    total += 54
    total += 55
    total += 56
    total += 57
    total += 58
    total += 59
    total += 60
    total += 61
    total += 62
    total += 63
    total += 64
    total += 65
    total += 66
    total += 67
    total += 68
    return total


class Shipper:
    def __init__(self, repo, log, clock, bus, cache, mapper, auth):
        self.repo = repo

    def ship(self, order, to, sender, carrier, when):
        pass
