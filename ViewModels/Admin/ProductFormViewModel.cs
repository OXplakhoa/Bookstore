using Bookstore.Models;
using System.ComponentModel.DataAnnotations;

namespace Bookstore.ViewModels.Admin
{
    public class ProductFormViewModel
    {
        public int ProductId { get; set; }

        [Required(ErrorMessage = "Tiêu đề sách là bắt buộc")]
        [StringLength(200, ErrorMessage = "Tiêu đề không được vượt quá 200 ký tự")]
        [Display(Name = "Tiêu đề sách")]
        public string Title { get; set; } = string.Empty;

        [Required(ErrorMessage = "Tác giả là bắt buộc")]
        [StringLength(100, ErrorMessage = "Tên tác giả không được vượt quá 100 ký tự")]
        [Display(Name = "Tác giả")]
        public string Author { get; set; } = string.Empty;

        [Display(Name = "Mô tả")]
        public string? Description { get; set; }

        [Required(ErrorMessage = "Giá sách là bắt buộc")]
        [Range(0.01, double.MaxValue, ErrorMessage = "Giá sách phải lớn hơn 0")]
        [Display(Name = "Giá (₫)")]
        public decimal Price { get; set; }

        [Required(ErrorMessage = "Số lượng tồn kho là bắt buộc")]
        [Range(0, int.MaxValue, ErrorMessage = "Số lượng tồn kho không được âm")]
        [Display(Name = "Số lượng tồn kho")]
        public int Stock { get; set; }

        [Required(ErrorMessage = "Danh mục là bắt buộc")]
        [Display(Name = "Danh mục")]
        public int CategoryId { get; set; }

        [Display(Name = "Kích hoạt")]
        public bool IsActive { get; set; } = true;

        [Display(Name = "Hình ảnh")]
        public IFormFileCollection? ImageFiles { get; set; }

        [Display(Name = "Hình ảnh chính (chọn số thứ tự)")]
        public int? MainImageIndex { get; set; }

        // For dropdown
        public IEnumerable<Category> Categories { get; set; } = new List<Category>();

        // For displaying existing images
        public List<ProductImage> ExistingImages { get; set; } = new List<ProductImage>();
    }
}

