using Bookstore.Data;
using Bookstore.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Stripe;
using Stripe.Checkout;

namespace Bookstore.Controllers;
    [ApiController]
    [Route("stripe/webhook")]
    public class StripeWebhookController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IStripePaymentService _stripeService;
        private readonly ILogger<StripeWebhookController> _logger;

        public StripeWebhookController(
            ApplicationDbContext context,
            IStripePaymentService stripeService,
            ILogger<StripeWebhookController> logger)
        {
            _context = context;
            _stripeService = stripeService;
            _logger = logger;
        }

        [HttpPost]
        public async Task<IActionResult> HandleWebhook()
        {
            var json = await new StreamReader(HttpContext.Request.Body).ReadToEndAsync();
            var signatureHeader = Request.Headers["Stripe-Signature"].FirstOrDefault();

            if (string.IsNullOrEmpty(signatureHeader))
            {
                _logger.LogWarning("Missing Stripe-Signature header");
                return BadRequest("Missing Stripe-Signature header");
            }

            try
            {
                var stripeEvent = _stripeService.ConstructEvent(json, signatureHeader);
                _logger.LogInformation("Received Stripe event: {EventType}", stripeEvent.Type);

                switch (stripeEvent.Type)
                {
                    case Events.CheckoutSessionCompleted:
                        await HandleCheckoutSessionCompleted(stripeEvent);
                        break;
                    case Events.ChargeSucceeded:
                        await HandleChargeSucceeded(stripeEvent);
                        break;
                    case Events.ChargeFailed:
                        await HandleChargeFailed(stripeEvent);
                        break;
                    default:
                        _logger.LogInformation("Unhandled event type: {EventType}", stripeEvent.Type);
                        break;
                }

                return Ok();
            }
            catch (StripeException ex)
            {
                _logger.LogError(ex, "Stripe webhook error: {Message}", ex.Message);
                return BadRequest($"Webhook error: {ex.Message}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error processing webhook");
                return StatusCode(500, "Internal server error");
            }
        }

        private async Task HandleCheckoutSessionCompleted(Event stripeEvent)
        {
            var session = stripeEvent.Data.Object as Session;
            if (session == null)
            {
                _logger.LogWarning("Checkout session is null");
                return;
            }

            var orderIdStr = session.Metadata?.GetValueOrDefault("OrderId");
            if (!int.TryParse(orderIdStr, out var orderId))
            {
                _logger.LogWarning("Invalid OrderId in session metadata: {OrderId}", orderIdStr);
                return;
            }

            var order = await _context.Orders
                .FirstOrDefaultAsync(o => o.OrderId == orderId);

            if (order == null)
            {
                _logger.LogWarning("Order not found: {OrderId}", orderId);
                return;
            }

            // Update order status
            order.PaymentStatus = "Paid";
            order.OrderStatus = "Processing";
            
            // Create payment record
            var payment = new Payment
            {
                OrderId = orderId,
                PaymentMethod = "Stripe",
                Amount = order.Total,
                Status = "Completed",
                TransactionId = session.Id,
                PaymentDate = DateTime.UtcNow
            };

            _context.Payments.Add(payment);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Order {OrderId} marked as paid via Stripe", orderId);
        }

        private async Task HandleChargeSucceeded(Event stripeEvent)
        {
            var charge = stripeEvent.Data.Object as Charge;
            if (charge == null)
            {
                _logger.LogWarning("Charge is null");
                return;
            }

            // Find payment by transaction ID (session ID)
            var payment = await _context.Payments
                .FirstOrDefaultAsync(p => p.TransactionId == charge.PaymentIntentId);

            if (payment != null)
            {
                payment.Status = "Completed";
                payment.TransactionId = charge.Id; // Update with actual charge ID
                await _context.SaveChangesAsync();

                _logger.LogInformation("Payment {PaymentId} confirmed via charge succeeded", payment.PaymentId);
            }
        }

        private async Task HandleChargeFailed(Event stripeEvent)
        {
            var charge = stripeEvent.Data.Object as Charge;
            if (charge == null)
            {
                _logger.LogWarning("Charge is null");
                return;
            }

            // Find payment by transaction ID
            var payment = await _context.Payments
                .FirstOrDefaultAsync(p => p.TransactionId == charge.PaymentIntentId);

            if (payment != null)
            {
                payment.Status = "Failed";
                await _context.SaveChangesAsync();

                // Update order status
                var order = await _context.Orders
                    .FirstOrDefaultAsync(o => o.OrderId == payment.OrderId);
                
                if (order != null)
                {
                    order.PaymentStatus = "Failed";
                    order.OrderStatus = "Cancelled";
                    await _context.SaveChangesAsync();
                }

                _logger.LogInformation("Payment {PaymentId} marked as failed", payment.PaymentId);
            }
    }
}
