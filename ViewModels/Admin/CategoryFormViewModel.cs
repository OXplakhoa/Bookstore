using System.ComponentModel.DataAnnotations;

namespace Bookstore.ViewModels.Admin
{
    public class CategoryFormViewModel
    {
        public int CategoryId { get; set; }

        [Required(ErrorMessage = "Tên danh mục là bắt buộc")]
        [StringLength(100, ErrorMessage = "Tên danh mục không được vượt quá 100 ký tự")]
        [Display(Name = "Tên danh mục")]
        public string Name { get; set; } = string.Empty;

        [StringLength(100, ErrorMessage = "Slug không được vượt quá 100 ký tự")]
        [Display(Name = "Slug (URL)")]
        public string? Slug { get; set; }

        [StringLength(500, ErrorMessage = "Mô tả không được vượt quá 500 ký tự")]
        [Display(Name = "Mô tả")]
        public string? Description { get; set; }

        // For displaying product count
        public int ProductCount { get; set; }
    }
}

