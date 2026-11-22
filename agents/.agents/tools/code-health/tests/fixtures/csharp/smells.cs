namespace Samples.Smells;

// One method per smell, for the end-to-end smell test.
public sealed class Orders(IRepo repo, ILog log, IClock clock, IBus bus, ICache cache, IMapper mapper, IAuth auth, IFlags flags)
{
    public Orders(IRepo repo, ILog log, IClock clock, IBus bus, ICache cache, IMapper mapper, IAuth auth, IFlags flags, int retries)
        : this(repo, log, clock, bus, cache, mapper, auth, flags)
    {
    }

    public string Describe(int code)
    {
        switch (code)
        {
            case 0: return "0";
            case 1: return "1";
            case 2: return "2";
            case 3: return "3";
            case 4: return "4";
            case 5: return "5";
            case 6: return "6";
            case 7: return "7";
            case 8: return "8";
            case 9: return "9";
            default: return "unknown";
        }
    }

    public int Deep(int a, int b)
    {
        if (a > 0)
        {
            if (b > 0)
            {
                if (a > b)
                {
                    if (a > 100)
                    {
                        return 1;
                    }
                }
            }
        }
        return 0;
    }

    public int Bumpy(int[] xs, int[] ys)
    {
        var total = 0;
        foreach (var x in xs)
        {
            if (x > 0) { total += x; }
        }
        foreach (var y in ys)
        {
            if (y > 0) { total += y; }
        }
        return total;
    }

    public bool Eligible(Customer c) { if (c.Active && c.Age > 17 || c.Override) { return true; } return false; }

    public int Large()
    {
        var total = 0;
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
        return total;
    }

    public void Ship(Order order, Address to, Address from, Carrier carrier, DateTime when)
    {
    }
}

public sealed class Lean(IRepo repo, ILog log, IClock clock, IBus bus, ICache cache, IMapper mapper, IAuth auth)
{
}
