using Bookstore.Data;
using Bookstore.Models;
using Bookstore.Services;
using Bookstore.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Stripe;

namespace Bookstore.Controllers;
    [Authorize]
    public class CheckoutController : Controller
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IStripePaymentService _stripeService;

        public CheckoutController(
            ApplicationDbContext context, 
            UserManager<ApplicationUser> userManager,
            IStripePaymentService stripeService)
        {
            _context = context;
            _userManager = userManager;
            _stripeService = stripeService;
        }

        // GET: /Checkout
        public async Task<IActionResult> Index()
        {
            var userId = _userManager.GetUserId(User);
            if (userId == null)
            {
                return RedirectToAction("Login", "Account", new { area = "Identity" });
            }

            // Get user's cart items
            var cartItems = await _context.CartItems
                .Include(c => c.Product)
                .ThenInclude(p => p.ProductImages)
                .Where(c => c.UserId == userId)
                .ToListAsync();

            if (!cartItems.Any())
            {
                TempData["Error"] = "Giỏ hàng trống. Vui lòng thêm sản phẩm trước khi thanh toán.";
                return RedirectToAction("Index", "Cart");
            }

            // Get user profile for pre-filling
            var user = await _userManager.GetUserAsync(User);

            var viewModel = new CheckoutViewModel
            {
                ShippingName = user?.FullName ?? string.Empty,
                ShippingEmail = user?.Email ?? string.Empty,
                ShippingPhone = user?.PhoneNumber ?? string.Empty,
                CartItems = cartItems.Select(c => new CartItemViewModel
                {
                    ProductId = c.ProductId,
                    ProductTitle = c.Product?.Title ?? string.Empty,
                    ProductImageUrl = c.Product?.ProductImages?.FirstOrDefault()?.ImageUrl ?? "/images/no-image.svg",
                    UnitPrice = c.Product?.Price ?? 0,
                    Quantity = c.Quantity
                }).ToList()
            };

            viewModel.Subtotal = viewModel.CartItems.Sum(c => c.Total);
            viewModel.Total = viewModel.Subtotal + viewModel.ShippingCost;

            return View(viewModel);
        }

        // POST: /Checkout/ProcessOrder
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ProcessOrder(CheckoutViewModel model)
        {
            var userId = _userManager.GetUserId(User);
            if (userId == null)
            {
                return RedirectToAction("Login", "Account", new { area = "Identity" });
            }

            if (!ModelState.IsValid)
            {
                // Reload cart items for display
                var cartItems = await _context.CartItems
                    .Include(c => c.Product)
                    .ThenInclude(p => p.ProductImages)
                    .Where(c => c.UserId == userId)
                    .ToListAsync();

                model.CartItems = cartItems.Select(c => new CartItemViewModel
                {
                    ProductId = c.ProductId,
                    ProductTitle = c.Product?.Title ?? string.Empty,
                    ProductImageUrl = c.Product?.ProductImages?.FirstOrDefault()?.ImageUrl ?? "/images/no-image.svg",
                    UnitPrice = c.Product?.Price ?? 0,
                    Quantity = c.Quantity
                }).ToList();

                model.Subtotal = model.CartItems.Sum(c => c.Total);
                model.Total = model.Subtotal + model.ShippingCost;

                return View("Index", model);
            }

            // Get cart items
            var userCartItems = await _context.CartItems
                .Include(c => c.Product)
                .Where(c => c.UserId == userId)
                .ToListAsync();

            if (!userCartItems.Any())
            {
                TempData["Error"] = "Giỏ hàng trống.";
                return RedirectToAction("Index", "Cart");
            }

            // Create order
            var order = new Order
            {
                OrderNumber = GenerateOrderNumber(),
                UserId = userId,
                OrderDate = DateTime.UtcNow,
                ShippingName = model.ShippingName,
                ShippingPhone = model.ShippingPhone,
                ShippingEmail = model.ShippingEmail,
                ShippingAddress = model.ShippingAddress,
                PaymentMethod = model.PaymentMethod,
                OrderStatus = "Pending",
                PaymentStatus = model.PaymentMethod == "COD" ? "COD" : "Pending",
                Notes = model.Notes,
                Total = userCartItems.Sum(c => c.Quantity * c.Product.Price),
                OrderItems = userCartItems.Select(c => new OrderItem
                {
                    ProductId = c.ProductId,
                    Quantity = c.Quantity,
                    UnitPrice = c.Product.Price
                }).ToList()
            };

            _context.Orders.Add(order);
            await _context.SaveChangesAsync();

            // Clear cart
            _context.CartItems.RemoveRange(userCartItems);
            await _context.SaveChangesAsync();

            if (model.PaymentMethod == "COD")
            {
                // For COD, redirect to confirmation
                return RedirectToAction("Confirmation", new { orderId = order.OrderId });
            }
            else if (model.PaymentMethod == "Stripe")
            {
                // For Stripe, create checkout session
                try
                {
                    var successUrl = Url.Action("Confirmation", "Checkout", new { orderId = order.OrderId }, Request.Scheme);
                    var cancelUrl = Url.Action("PaymentCancelled", "Checkout", new { orderId = order.OrderId }, Request.Scheme);

                    var session = await _stripeService.CreateCheckoutSessionAsync(order, successUrl, cancelUrl);
                    return Redirect(session.Url);
                }
                catch (Exception ex)
                {
                    TempData["Error"] = "Có lỗi xảy ra khi tạo phiên thanh toán. Vui lòng thử lại.";
                    return RedirectToAction("Index");
                }
            }

            return RedirectToAction("Index");
        }

        // GET: /Checkout/Confirmation
        public async Task<IActionResult> Confirmation(int orderId)
        {
            var userId = _userManager.GetUserId(User);
            if (userId == null)
            {
                return RedirectToAction("Login", "Account", new { area = "Identity" });
            }

            var order = await _context.Orders
                .Include(o => o.OrderItems)
                .ThenInclude(oi => oi.Product)
                .ThenInclude(p => p.ProductImages)
                .FirstOrDefaultAsync(o => o.OrderId == orderId && o.UserId == userId);

            if (order == null)
            {
                return NotFound();
            }

            var viewModel = new OrderConfirmationViewModel
            {
                OrderId = order.OrderId,
                OrderNumber = order.OrderNumber ?? string.Empty,
                OrderDate = order.OrderDate,
                Total = order.Total,
                PaymentMethod = order.PaymentMethod ?? string.Empty,
                PaymentStatus = order.PaymentStatus ?? string.Empty,
                OrderStatus = order.OrderStatus ?? string.Empty,
                ShippingName = order.ShippingName ?? string.Empty,
                ShippingPhone = order.ShippingPhone ?? string.Empty,
                ShippingEmail = order.ShippingEmail ?? string.Empty,
                ShippingAddress = order.ShippingAddress ?? string.Empty,
                OrderItems = order.OrderItems?.Select(oi => new OrderItemViewModel
                {
                    ProductId = oi.ProductId,
                    ProductTitle = oi.Product?.Title ?? string.Empty,
                    ProductImageUrl = oi.Product?.ProductImages?.FirstOrDefault()?.ImageUrl ?? "/images/no-image.svg",
                    UnitPrice = oi.UnitPrice,
                    Quantity = oi.Quantity
                }).ToList() ?? new List<OrderItemViewModel>()
            };

            return View(viewModel);
        }

        // GET: /Checkout/PaymentCancelled
        public async Task<IActionResult> PaymentCancelled(int orderId)
        {
            var userId = _userManager.GetUserId(User);
            if (userId == null)
            {
                return RedirectToAction("Login", "Account", new { area = "Identity" });
            }

            var order = await _context.Orders
                .FirstOrDefaultAsync(o => o.OrderId == orderId && o.UserId == userId);

            if (order == null)
            {
                return NotFound();
            }

            // Update order status to cancelled
            order.OrderStatus = "Cancelled";
            order.PaymentStatus = "Cancelled";
            await _context.SaveChangesAsync();

            TempData["Error"] = "Thanh toán đã bị hủy. Đơn hàng của bạn đã được hủy.";
            return View();
        }

        private string GenerateOrderNumber()
        {
            return $"ORD{DateTime.UtcNow:yyyyMMddHHmmss}{Random.Shared.Next(1000, 9999)}";
        }
    }
