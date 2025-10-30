public class CartItem 
{
    public int CartItemId { get; set; }
    public string? UserId { get; set; }
    public int ProductId { get; set; }
    public int Quantity { get; set; }
    public DateTime DateAdded { get; set; } = DateTime.UtcNow;
    
    // Flash Sale Support - lock in the price when added
    public int? FlashSaleProductId { get; set; }
    public decimal? LockedPrice { get; set; } // Lock the flash sale price at time of adding to cart

    // Navigation properties
    public Product? Product { get; set; }
    public ApplicationUser? User { get; set; }
    public FlashSaleProduct? FlashSaleProduct { get; set; }
}