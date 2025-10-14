using System;
public class Payment
{
    public int PaymentId { get; set; }
    public int OrderId { get; set; }
    public string? PaymentMethod { get; set; }
    public string? Status { get; set; } // Pending, Completed, Failed, Refunded
    public DateTime PaymentDate { get; set; } = DateTime.UtcNow;
    public decimal Amount { get; set; }
    public string? TransactionId { get; set; } // Stripe charge id or COD reference
    public string? PaymentIntentId { get; set; } // Stripe payment intent id
    public Order? Order { get; set; }
}