namespace Bookstore.ViewModels.Admin;

public class FlashSaleAnalyticsViewModel
{
    public int FlashSaleId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public bool IsActive { get; set; }
    public string Status { get; set; } = string.Empty;
    
    // Summary Statistics
    public int TotalUnitsSold { get; set; }
    public decimal TotalRevenue { get; set; }
    public decimal TotalDiscount { get; set; }
    public int TotalOrders { get; set; }
    public int TotalProducts { get; set; }
    
    // Conversion Metrics
    public int TotalViews { get; set; }
    public int UniqueViewers { get; set; }
    public double ConversionRate { get; set; } // (TotalOrders / TotalViews) * 100
    public decimal AverageOrderValue { get; set; }
    
    // Product Performance
    public List<ProductBreakdown> TopProducts { get; set; } = new();
    
    // Time Series Data (for charts)
    public List<DailySales> SalesByDay { get; set; } = new();
    
    public class ProductBreakdown
    {
        public int ProductId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string? Author { get; set; }
        public string? ImageUrl { get; set; }
        public decimal OriginalPrice { get; set; }
        public decimal SalePrice { get; set; }
        public decimal DiscountPercentage { get; set; }
        public int QuantitySold { get; set; }
        public decimal Revenue { get; set; }
        public decimal TotalDiscount { get; set; }
        public int? StockLimit { get; set; }
        public int StockRemaining { get; set; }
        public double SellThroughRate { get; set; } // (Sold / Limit) * 100
    }
    
    public class DailySales
    {
        public DateTime Date { get; set; }
        public int Orders { get; set; }
        public int UnitsSold { get; set; }
        public decimal Revenue { get; set; }
    }
}
