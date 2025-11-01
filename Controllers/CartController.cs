using Bookstore.ViewModels;
using Bookstore.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Bookstore.Services;
using System.Collections.Frozen;

namespace Bookstore.Controllers
{
    public class CartController : Controller
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IFlashSaleService _flashSaleService;

        public CartController(ApplicationDbContext context, UserManager<ApplicationUser> userManager, IFlashSaleService flashSaleService)
        {
            _context = context;
            _userManager = userManager;
            _flashSaleService = flashSaleService;
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
                    .ThenInclude(p => p!.ProductImages)
                .Include(c => c.FlashSaleProduct) // Through FlashSaleProductId
                    .ThenInclude(fsp => fsp!.FlashSale) 
                .Where(c => c.UserId == userId)
                .ToListAsync();

            // Calculate total with effective prices (flash sale / regular)
            decimal totalPrice = 0;
            foreach (var item in cartItems)
            {
                var effectivePrice = item.LockedPrice ?? item.Product!.Price;
                totalPrice += effectivePrice * item.Quantity;
            }
            var viewModel = new CartViewModel
            {
                CartItems = cartItems,
                TotalPrice = totalPrice
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

            // Check if product has active flash sale
            FlashSaleProduct? flashSale = null;
            decimal lockedPrice = product.Price;

            if(request.FlashSaleProductId.HasValue)
            {
                flashSale = await _context.FlashSaleProducts
                    .Include(fsp => fsp.FlashSale)
                    .FirstOrDefaultAsync(fsp => fsp.FlashSaleProductId == request.FlashSaleProductId.Value);
                
                if (flashSale != null)
                {
                    var now = DateTime.UtcNow;
                    if (!flashSale.FlashSale!.IsActive ||
                        flashSale.FlashSale.StartDate > now ||
                        flashSale.FlashSale.EndDate < now)
                    {
                        return Json(new { success = false, message = "Flash sale is no longer active" });
                    }
                    // Check flash sale stock limit
                    if (!await _flashSaleService.CanPurchaseAtFlashPriceAsync(flashSale.FlashSaleProductId, request.Quantity))
                    {
                        return Json(new { success = false, message = "Flash Sale stock limit reached" });
                    }
                    lockedPrice = flashSale.SalePrice; // Lock flash sale price
                }
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

                // Update flash sale info if adding with flash sale
                // This handles the scenario where:
                //  1. User previously added Product X to cart without flash sale (at regular price)
                //  2. Now user adds the same Product X but with flash sale (at discounted price)
                if (flashSale != null && existingCartItem.FlashSaleProductId == null)
                {
                    existingCartItem.FlashSaleProductId = flashSale.FlashSaleProductId;
                    existingCartItem.LockedPrice = lockedPrice;
                }
            }
            else
            {
                var cartItem = new CartItem
                {
                    UserId = userId,
                    ProductId = request.ProductId,
                    Quantity = request.Quantity,
                    DateAdded = DateTime.UtcNow,
                    FlashSaleProductId = flashSale?.FlashSaleProductId,
                    LockedPrice = flashSale != null ? lockedPrice : null
                };
                _context.CartItems.Add(cartItem);
            }

            await _context.SaveChangesAsync();

            var cartCount = await _context.CartItems
                .Where(c => c.UserId == userId)
                .SumAsync(c => c.Quantity);

            var message = flashSale != null 
                ? $"Đã thêm vào giỏ với giá Flash Sale: {lockedPrice:N0}₫"
                : "Đã thêm vào giỏ hàng";
            return Json(new { success = true, message, cartCount });
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
                .Include(c => c.FlashSaleProduct)
                .FirstOrDefaultAsync(c => c.CartItemId == cartItemId && c.UserId == userId);

            if (cartItem == null)
            {
                return Json(new { success = false, message = "Cart item not found" });
            }

            if (quantity <= 0)
            {
                _context.CartItems.Remove(cartItem);
            }
            else
            {
                // Check product stock
                if (quantity > cartItem.Product!.Stock)
                {
                    return Json(new { success = false, message = "Không đủ hàng trong kho" });
                }
                // Check flash sale stock limit if applicable
                if (cartItem.FlashSaleProductId.HasValue)
                {
                    if (!await _flashSaleService.CanPurchaseAtFlashPriceAsync(cartItem.FlashSaleProductId.Value, quantity))
                    {
                        return Json(new { success = false, message = "Đã vượt quá giới hạn mua hàng của Flash Sale" });
                    }
                }
                cartItem.Quantity = quantity;
            }
            await _context.SaveChangesAsync();

            var cartCount = await _context.CartItems
                .Where(c => c.UserId == userId)
                .SumAsync(c => c.Quantity);

            var cartItems = await _context.CartItems
                .Include(c => c.Product)
                .Where(c => c.UserId == userId)
                .ToListAsync();

            decimal totalPrice = 0;
            foreach (var item in cartItems)
            {
                var effectivePrice = item.LockedPrice ?? item.Product!.Price;
                totalPrice += effectivePrice * item.Quantity;
            }

            return Json(new { success = true, cartCount, totalPrice = totalPrice.ToString("N0") });
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

            var cartItems = await _context.CartItems
                .Include(c => c.Product)
                .Where (c => c.UserId == userId)
                .ToListAsync();
            
            decimal totalPrice = 0;
            foreach (var item in cartItems)
            {
                var effectivePrice = item.LockedPrice ?? item.Product!.Price;
                totalPrice += effectivePrice * item.Quantity;
            }

            return Json(new { success = true, cartCount, totalPrice = totalPrice.ToString("N0") });
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
        public int? FlashSaleProductId { get; set; }
    }
}
