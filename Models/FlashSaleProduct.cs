public class FlashSaleProduct
{
    public int FlashSaleProductId { get; set; }
    public int FlashSaleId { get; set; }
    public int ProductId { get; set; }
    public decimal OriginalPrice { get; set; }
    public decimal SalePrice { get; set; }
    public decimal DiscountPercentage { get; set; }
    public int? StockLimit { get; set; }
    public int SoldCount { get; set; }
    // Navigation 
    public FlashSale? FlashSale { get; set; }
    public Product? Product { get; set; }
}