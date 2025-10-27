using System.ComponentModel.DataAnnotations;
using System.Text;

namespace Bookstore.ViewModels.Admin;

public class FlashSaleProductFormViewModel
{
    [Required(ErrorMessage = "Vui lòng chọn Flash Sale")]
    public int FlashSaleId { get; set; }

    [Required(ErrorMessage = "Vui lòng chọn Sản phẩm")]
    public int ProductId { get; set; }

    [Required(ErrorMessage = "Vui lòng nhập Giá khuyến mãi")]
    [Range(0.01, double.MaxValue, ErrorMessage = "Giá khuyến mãi phải lớn hơn 0")]
    [Display(Name = "Giá khuyến mãi (₫)")]
    public decimal SalePrice { get; set; }

    [Range(0, int.MaxValue, ErrorMessage = "Giới hạn số lượng không hợp lệ")]
    [Display(Name = "Giới hạn số lượng (để trống = không giới hạn)")]
    public int? StockLimit { get; set; }

    // For display
    public string? ProductTitle { get; set; }
    public decimal OriginalPrice { get; set; }
    public decimal DiscountPercentage => OriginalPrice > 0
    ? (OriginalPrice - SalePrice) / OriginalPrice * 100 : 0;
}