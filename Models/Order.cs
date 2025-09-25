using System;
using System.Collections.Generic;

public class Order 
{
    public int OrderId { get; set; }
    public string? UserId { get; set; } // Foreign key to ApplicationUser
    public DateTime OrderDate { get; set; }
    public decimal Total { get; set; }
    public string? Status { get; set; }
    public string? ShippingAddress { get; set; }
    public ICollection<OrderItem>? OrderItems { get; set; }
}