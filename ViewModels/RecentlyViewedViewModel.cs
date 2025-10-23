using System.Collections.Generic;

namespace Bookstore.ViewModels;

public class RecentlyViewedViewModel
{
    public IEnumerable<ProductCardViewModel>? Products { get; set; }
}
