using System;
using System.Collections.Generic;

public class Order 
{
    public int OrderId { get; set; }
    public string? OrderNumber { get; set; }

    // User
    public string? UserId { get; set; } // Foreign key to ApplicationUser
    public ApplicationUser? User { get; set; }

    // Timestamps
    public DateTime OrderDate { get; set; }

    // Financials
    public decimal Total { get; set; }

    // Shipping information
    public string? ShippingName { get; set; }
    public string? ShippingPhone { get; set; }
    public string? ShippingEmail { get; set; }
    public string? ShippingAddress { get; set; }

    // Status & tracking
    public string? OrderStatus { get; set; } // Pending, Processing, Shipped, Delivered, Cancelled
    public string? PaymentMethod { get; set; } // Stripe, COD
    public string? PaymentStatus { get; set; } // Pending, Paid, Failed, COD, Refunded
    public string? TrackingNumber { get; set; }
    public string? Notes { get; set; }

    // Navigation
    public ICollection<OrderItem>? OrderItems { get; set; }
    public ICollection<Payment>? Payments { get; set; }
}