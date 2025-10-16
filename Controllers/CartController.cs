using Bookstore.ViewModels;
using Bookstore.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Bookstore.Controllers
{
    public class CartController : Controller
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;

        public CartController(ApplicationDbContext context, UserManager<ApplicationUser> userManager)
        {
            _context = context;
            _userManager = userManager;
        }

        // GET: /Cart
        public async Task<IActionResult> Index()
        {
            var userId = _userManager.GetUserId(User);
            if (userId == null)
            {
                return RedirectToAction("Login", "Account", new { area = "Identity" });
            }

            var cartItems = await _context.CartItems
                .Include(c => c.Product)
                .ThenInclude(p => p.ProductImages)
                .Where(c => c.UserId == userId)
                .ToListAsync();

            var viewModel = new CartViewModel
            {
                CartItems = cartItems,
                TotalPrice = cartItems.Sum(c => c.Quantity * c.Product.Price)
            };

            return View(viewModel);
        }

        // POST: /Cart/AddToCart
        [HttpPost]
        public async Task<IActionResult> AddToCart([FromBody] AddToCartRequest request)
        {
            var userId = _userManager.GetUserId(User);
            if (userId == null)
            {
                return Json(new { success = false, message = "Please log in to add items to cart" });
            }

            var product = await _context.Products
                .FirstOrDefaultAsync(p => p.ProductId == request.ProductId && p.IsActive);

            if (product == null)
            {
                return Json(new { success = false, message = "Product not found" });
            }

            if (request.Quantity > product.Stock)
            {
                return Json(new { success = false, message = "Not enough stock available" });
            }

            var existingCartItem = await _context.CartItems
                .FirstOrDefaultAsync(c => c.UserId == userId && c.ProductId == request.ProductId);

            if (existingCartItem != null)
            {
                existingCartItem.Quantity += request.Quantity;
                if (existingCartItem.Quantity > product.Stock)
                {
                    return Json(new { success = false, message = "Not enough stock available" });
                }
            }
            else
            {
                var cartItem = new CartItem
                {
                    UserId = userId,
                    ProductId = request.ProductId,
                    Quantity = request.Quantity,
                    DateAdded = DateTime.UtcNow
                };
                _context.CartItems.Add(cartItem);
            }

            await _context.SaveChangesAsync();

            var cartCount = await _context.CartItems
                .Where(c => c.UserId == userId)
                .SumAsync(c => c.Quantity);

            return Json(new { success = true, message = "Added to cart", cartCount = cartCount });
        }

        // POST: /Cart/UpdateQuantity
        [HttpPost]
        public async Task<IActionResult> UpdateQuantity(int cartItemId, int quantity)
        {
            var userId = _userManager.GetUserId(User);
            if (userId == null)
            {
                return Json(new { success = false, message = "Please log in" });
            }

            var cartItem = await _context.CartItems
                .Include(c => c.Product)
                .FirstOrDefaultAsync(c => c.CartItemId == cartItemId && c.UserId == userId);

            if (cartItem == null)
            {
                return Json(new { success = false, message = "Cart item not found" });
            }

            if (quantity <= 0)
            {
                _context.CartItems.Remove(cartItem);
            }
            else if (quantity > cartItem.Product.Stock)
            {
                return Json(new { success = false, message = "Not enough stock available" });
            }
            else
            {
                cartItem.Quantity = quantity;
            }

            await _context.SaveChangesAsync();

            var cartCount = await _context.CartItems
                .Where(c => c.UserId == userId)
                .SumAsync(c => c.Quantity);

            var totalPrice = await _context.CartItems
                .Include(c => c.Product)
                .Where(c => c.UserId == userId)
                .SumAsync(c => c.Quantity * c.Product.Price);

            return Json(new { success = true, cartCount = cartCount, totalPrice = totalPrice.ToString("N0") });
        }

        // POST: /Cart/RemoveFromCart
        [HttpPost]
        public async Task<IActionResult> RemoveFromCart(int cartItemId)
        {
            var userId = _userManager.GetUserId(User);
            if (userId == null)
            {
                return Json(new { success = false, message = "Please log in" });
            }

            var cartItem = await _context.CartItems
                .FirstOrDefaultAsync(c => c.CartItemId == cartItemId && c.UserId == userId);

            if (cartItem == null)
            {
                return Json(new { success = false, message = "Cart item not found" });
            }

            _context.CartItems.Remove(cartItem);
            await _context.SaveChangesAsync();

            var cartCount = await _context.CartItems
                .Where(c => c.UserId == userId)
                .SumAsync(c => c.Quantity);

            var totalPrice = await _context.CartItems
                .Include(c => c.Product)
                .Where(c => c.UserId == userId)
                .SumAsync(c => c.Quantity * c.Product.Price);

            return Json(new { success = true, cartCount = cartCount, totalPrice = totalPrice.ToString("N0") });
        }

        // GET: /Cart/GetCartCount
        public async Task<IActionResult> GetCartCount()
        {
            var userId = _userManager.GetUserId(User);
            if (userId == null)
            {
                return Json(new { cartCount = 0 });
            }

            var cartCount = await _context.CartItems
                .Where(c => c.UserId == userId)
                .SumAsync(c => c.Quantity);

            return Json(new { cartCount = cartCount });
        }
    }

    public class AddToCartRequest
    {
        public int ProductId { get; set; }
        public int Quantity { get; set; }
    }
}
