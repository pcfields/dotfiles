namespace Samples.Orders;

public record OrderLine(string Sku, int Quantity, decimal Price);

public sealed class OrderService(IOrderRepository repository, ILogger logger)
{
    public decimal Total(IReadOnlyList<OrderLine> lines, string? coupon, bool includeTax)
    {
        decimal total = 0;
        foreach (var line in lines)
        {
            if (line.Quantity <= 0 || line.Price < 0)
            {
                continue;
            }
            total += line.Quantity * line.Price;
        }

        for (var i = 0; i < 3 && total > 100; i++)
        {
            total -= 1;
        }

        while (total > 10_000)
        {
            total /= 2;
        }

        var discount = coupon switch
        {
            "HALF" => 0.5m,
            { Length: > 10 } => 0.1m,
            _ => 0m,
        };

        try
        {
            repository.Save(total);
        }
        catch (InvalidOperationException ex) when (ex.Message.Length > 0)
        {
            logger.Warn(ex.Message);
        }

        var label = coupon ?? "none";
        return includeTax ? total * (1 - discount) * 1.2m : total;
    }

    public string Describe(object value)
    {
        switch (value)
        {
            case int n when n > 0:
                return "positive";
            case string s:
                return s;
            default:
                return value is OrderLine { Quantity: > 1 } ? "many" : "other";
        }
    }

    private static int Square(int x) => x * x;

    public int Count
    {
        get { return 0; }
    }
}

public interface IOrderRepository
{
    void Save(decimal total);
}

public interface ILogger
{
    void Warn(string message);
}
