namespace Bookstore.ViewModels
{
    public class OrderSummaryViewModel
    {
        public int OrderId { get; set; }
        public string OrderNumber { get; set; } = string.Empty;
        public DateTime OrderDate { get; set; }
        public decimal Total { get; set; }
        public string PaymentMethod { get; set; } = string.Empty;
        public string PaymentStatus { get; set; } = string.Empty;
        public string OrderStatus { get; set; } = string.Empty;
        public int ItemCount { get; set; }
        public string? FirstProductImage { get; set; }
    }
}

