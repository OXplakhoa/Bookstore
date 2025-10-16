using System.ComponentModel.DataAnnotations;

namespace Bookstore.ViewModels
{
    public class CheckoutViewModel
    {
        // Shipping Information
        [Required(ErrorMessage = "Tên người nhận là bắt buộc")]
        [Display(Name = "Tên người nhận")]
        public string ShippingName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Số điện thoại là bắt buộc")]
        [Phone(ErrorMessage = "Số điện thoại không hợp lệ")]
        [Display(Name = "Số điện thoại")]
        public string ShippingPhone { get; set; } = string.Empty;

        [Required(ErrorMessage = "Email là bắt buộc")]
        [EmailAddress(ErrorMessage = "Email không hợp lệ")]
        [Display(Name = "Email")]
        public string ShippingEmail { get; set; } = string.Empty;

        [Required(ErrorMessage = "Địa chỉ giao hàng là bắt buộc")]
        [Display(Name = "Địa chỉ giao hàng")]
        public string ShippingAddress { get; set; } = string.Empty;

        // Payment Method
        [Required(ErrorMessage = "Vui lòng chọn phương thức thanh toán")]
        [Display(Name = "Phương thức thanh toán")]
        public string PaymentMethod { get; set; } = string.Empty;

        // Order Notes
        [Display(Name = "Ghi chú đơn hàng")]
        public string? Notes { get; set; }

        // Cart Items (for display)
        public List<CartItemViewModel> CartItems { get; set; } = new List<CartItemViewModel>();
        
        // Totals
        public decimal Subtotal { get; set; }
        public decimal ShippingCost { get; set; } = 0; // Free shipping for now
        public decimal Total { get; set; }
    }

    public class CartItemViewModel
    {
        public int ProductId { get; set; }
        public string ProductTitle { get; set; } = string.Empty;
        public string? ProductImageUrl { get; set; }
        public decimal UnitPrice { get; set; }
        public int Quantity { get; set; }
        public decimal Total => UnitPrice * Quantity;
    }
}

