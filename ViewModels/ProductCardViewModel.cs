namespace Bookstore.ViewModels;

public class ProductCardViewModel
{
    public Product? Product { get; set; }
    public bool IsFavorited { get; set; }
    public bool IsRecentlyViewed { get; set; }
}
