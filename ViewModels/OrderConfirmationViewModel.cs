namespace Bookstore.ViewModels
{
    public class OrderConfirmationViewModel
    {
        public int OrderId { get; set; }
        public string OrderNumber { get; set; } = string.Empty;
        public DateTime OrderDate { get; set; }
        public decimal Total { get; set; }
        public string PaymentMethod { get; set; } = string.Empty;
        public string PaymentStatus { get; set; } = string.Empty;
        public string OrderStatus { get; set; } = string.Empty;
        
        // Shipping Information
        public string ShippingName { get; set; } = string.Empty;
        public string ShippingPhone { get; set; } = string.Empty;
        public string ShippingEmail { get; set; } = string.Empty;
        public string ShippingAddress { get; set; } = string.Empty;
        
        // Order Items
        public List<OrderItemViewModel> OrderItems { get; set; } = new List<OrderItemViewModel>();
    }

    public class OrderItemViewModel
    {
        public int ProductId { get; set; }
        public string ProductTitle { get; set; } = string.Empty;
        public string? ProductImageUrl { get; set; }
        public decimal UnitPrice { get; set; }
        public int Quantity { get; set; }
        public decimal Total => UnitPrice * Quantity;
    }
}

