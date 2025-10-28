using System.Collections.Generic;
using Bookstore.Helpers;

namespace Bookstore.ViewModels
{
    public class ProductListViewModel
    {
        public PaginatedList<Product>? Products {get; set;}
        public IEnumerable<Category>? Categories {get; set;}

        // current query
        public string? Search {get; set;}
        public int? CategoryId {get; set;}
        public string? Sort {get; set;} //Determine the sorting order

        public HashSet<int> FavoriteProductIds { get; set; } = new();
        public HashSet<int> RecentlyViewedProductIds { get; set; } = new();

        // Flash Sale dictionary: ProductId -> FlashSaleProduct
        public Dictionary<int, FlashSaleProduct> FlashSales { get; set; } = new();
    }
}