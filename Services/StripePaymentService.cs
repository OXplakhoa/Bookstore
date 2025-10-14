using Microsoft.Extensions.Options;
using Stripe;
using Stripe.Checkout;
// Services/StripePaymentService.cs
public class StripeSettings
{
    public string? PublishableKey { get; set; }
    public string? SecretKey { get; set; }
    public string? WebhookSecret { get; set; }
}

public interface IStripePaymentService
{
    Task<Session> CreateCheckoutSessionAsync(Order order, string successUrl, string cancelUrl);
    Event ConstructEvent(string json, string signatureHeader);
}

public class StripePaymentService : IStripePaymentService
{
    private readonly StripeSettings _settings;

    public StripePaymentService(IOptions<StripeSettings> options)
    {
        _settings = options.Value;
        if (!string.IsNullOrWhiteSpace(_settings.SecretKey))
        {
            StripeConfiguration.ApiKey = _settings.SecretKey;
        }
    }

    public async Task<Session> CreateCheckoutSessionAsync(Order order, string successUrl, string cancelUrl)
    {
        var lineItems = order.OrderItems?.Select(oi => new SessionLineItemOptions
        {
            Quantity = oi.Quantity,
            PriceData = new SessionLineItemPriceDataOptions
            {
                Currency = "vnd",
                UnitAmount = (long)(oi.UnitPrice * 100),
                ProductData = new SessionLineItemPriceDataProductDataOptions
                {
                    Name = oi.Product?.Title ?? $"Product #{oi.ProductId}"
                }
            }
        }).ToList() ?? new List<SessionLineItemOptions>();

        var options = new SessionCreateOptions
        {
            Mode = "payment",
            SuccessUrl = successUrl,
            CancelUrl = cancelUrl,
            LineItems = lineItems,
            Metadata = new Dictionary<string, string>
            {
                ["OrderId"] = order.OrderId.ToString() //Embedding OrderId to Stripe when receive webhook event
            }
        };

        var service = new SessionService();
        var session = await service.CreateAsync(options);
        return session;
    }

    public Event ConstructEvent(string json, string signatureHeader)
    {
        return EventUtility.ConstructEvent(json, signatureHeader, _settings.WebhookSecret);
        // Convert JSON payload to Stripe Event Object
    }
}


