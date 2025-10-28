using System.Collections.Generic;

namespace Bookstore.ViewModels
{
    public class ProductDetailsViewModel
    {
        public Product? Product { get; set; }
        public IEnumerable<ProductCardViewModel>? RelatedProducts { get; set; }
        public IEnumerable<ProductCardViewModel>? RecentlyViewedProducts { get; set; }
        public bool IsFavorited { get; set; }
        
        // Flash Sale for current product
        public FlashSaleProduct? FlashSale { get; set; }
    }
}