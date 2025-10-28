namespace Bookstore.ViewModels;

public class ProductCardViewModel
{
    public Product? Product { get; set; }
    public bool IsFavorited { get; set; }
    public bool IsRecentlyViewed { get; set; }

    // Flash Sale Infomation
    public FlashSaleProduct? FlashSale { get; set; }

    // Helper Properties
    public bool HasFlashSale => FlashSale != null;
    public decimal EffectivePrice => FlashSale?.SalePrice ?? Product?.Price ?? 0;
    public decimal? Savings => HasFlashSale ? (Product?.Price - FlashSale?.SalePrice) : null;
    public decimal? DiscountPercentage => FlashSale?.DiscountPercentage;
}
