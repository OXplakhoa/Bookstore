namespace Bookstore.ViewModels
{
    public class ProductDetailsViewModel
    {
        public Product? Product { get; set; }
        public IEnumerable<Product>? RelatedProducts { get; set; } //Loopable but not a list
    }
}