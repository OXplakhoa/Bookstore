public class FlashSale
{
    public int FlashSaleId { get; set; }
    public string? Name { get; set; } // Black Friday Sale, Summer Sale, etc...
    public string? Description { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    // Navigation property
    public ICollection<FlashSaleProduct>? FlashSaleProducts { get; set; }
}