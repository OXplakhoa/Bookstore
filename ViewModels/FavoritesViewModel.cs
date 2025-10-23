using System.Collections.Generic;

namespace Bookstore.ViewModels;

public class FavoritesViewModel
{
    public IEnumerable<ProductCardViewModel>? Favorites { get; set; }
}
