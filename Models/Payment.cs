using System;
public class Payment
{
    public int PaymentId { get; set; }
    public int OrderId { get; set; }
    public string? PaymentMethod { get; set; }
    public string? Status { get; set; }
    public DateTime PaymentDate { get; set; } = DateTime.UtcNow;
    public decimal Amount { get; set; }
    public Order? Order { get; set; }
}