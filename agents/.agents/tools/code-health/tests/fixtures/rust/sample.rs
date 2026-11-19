pub struct Line {
    pub quantity: i64,
    pub price: i64,
}

pub fn total(lines: &[Line], coupon: Option<&str>, include_tax: bool) -> i64 {
    let mut sum = 0;
    for line in lines {
        if line.quantity <= 0 || line.price < 0 {
            continue;
        } else if line.quantity > 100 && !include_tax {
            sum += 1;
        }
        sum += line.quantity * line.price;
    }

    while sum > 10_000 {
        sum /= 2;
    }

    loop {
        if sum >= 0 {
            break;
        }
        sum += 1;
    }

    sum = match coupon {
        Some("HALF") => sum / 2,
        Some(code) if code.len() > 10 => sum - 1,
        _ => sum,
    };

    if let Some(code) = coupon {
        sum += code.len() as i64;
    }

    while let Some(_) = None::<i32> {}

    let parsed = "42".parse::<i64>().unwrap_or_default();
    if include_tax { sum * 12 / 10 + parsed } else { sum }
}

pub struct Cart {
    lines: Vec<Line>,
}

impl Cart {
    pub fn new(lines: Vec<Line>) -> Self {
        Self { lines }
    }

    pub fn count(&self) -> usize {
        self.lines.iter().filter(|line| line.quantity > 0).count()
    }
}
