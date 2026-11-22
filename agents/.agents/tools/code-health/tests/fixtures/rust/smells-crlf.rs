// One function per smell, for the end-to-end smell test.

pub fn describe(code: i32) -> &'static str {
    match code {
        0 => "0",
        1 => "1",
        2 => "2",
        3 => "3",
        4 => "4",
        5 => "5",
        6 => "6",
        7 => "7",
        8 => "8",
        9 => "9",
        _ => "unknown",
    }
}

pub fn deep(a: i32, b: i32) -> i32 {
    if a > 0 {
        if b > 0 {
            if a > b {
                if a > 100 {
                    return 1;
                }
            }
        }
    }
    0
}

pub fn bumpy(xs: &[i32], ys: &[i32]) -> i32 {
    let mut total = 0;
    for x in xs {
        if *x > 0 { total += x; }
    }
    for y in ys {
        if *y > 0 { total += y; }
    }
    total
}

pub fn eligible(c: &Customer) -> bool {
    if c.active && c.age > 17 || c.over {
        return true;
    }
    false
}

pub fn large() -> i32 {
    let mut total = 0;
    total += 0;
    total += 1;
    total += 2;
    total += 3;
    total += 4;
    total += 5;
    total += 6;
    total += 7;
    total += 8;
    total += 9;
    total += 10;
    total += 11;
    total += 12;
    total += 13;
    total += 14;
    total += 15;
    total += 16;
    total += 17;
    total += 18;
    total += 19;
    total += 20;
    total += 21;
    total += 22;
    total += 23;
    total += 24;
    total += 25;
    total += 26;
    total += 27;
    total += 28;
    total += 29;
    total += 30;
    total += 31;
    total += 32;
    total += 33;
    total += 34;
    total += 35;
    total += 36;
    total += 37;
    total += 38;
    total += 39;
    total += 40;
    total += 41;
    total += 42;
    total += 43;
    total += 44;
    total += 45;
    total += 46;
    total += 47;
    total += 48;
    total += 49;
    total += 50;
    total += 51;
    total += 52;
    total += 53;
    total += 54;
    total += 55;
    total += 56;
    total += 57;
    total += 58;
    total += 59;
    total += 60;
    total += 61;
    total += 62;
    total += 63;
    total += 64;
    total += 65;
    total += 66;
    total += 67;
    total
}

impl Shipper {
    pub fn ship(&self, order: Order, to: Addr, from: Addr, carrier: Carrier, when: Time) {
        let _ = (order, to, from, carrier, when);
    }
}
