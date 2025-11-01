public class OrderItem 
{
    public int OrderItemId { get; set; }
    public int OrderId { get; set; }
    public int ProductId { get; set; }
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }

    // Flash Sale tracking for historical record
    public int? FlashSaleProductId { get; set; }
    public bool WasOnFlashSale { get; set; }
    public decimal? FlashSaleDiscount { get; set; } // Amount saved
    
    // Navigation properties 
    public Product? Product { get; set; }
    public Order? Order { get; set; }
    public FlashSaleProduct? FlashSaleProduct { get; set; }
}