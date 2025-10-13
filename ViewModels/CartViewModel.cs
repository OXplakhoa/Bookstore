using Bookstore.Models;

namespace Bookstore.ViewModels
{
    public class CartViewModel
    {
        public IEnumerable<CartItem> CartItems { get; set; } = new List<CartItem>();
        public decimal TotalPrice { get; set; }
        public int ItemCount => CartItems.Sum(c => c.Quantity);
    }
}
