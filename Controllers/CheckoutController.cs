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
    private readonly IFlashSaleService _flashSaleService;

    public CheckoutController(
        ApplicationDbContext context,
        UserManager<ApplicationUser> userManager,
        IStripePaymentService stripeService,
        IFlashSaleService flashSaleService)
    {
        _context = context;
        _userManager = userManager;
        _stripeService = stripeService;
        _flashSaleService = flashSaleService;
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
                .ThenInclude(p => p!.ProductImages)
            .Include(c => c.FlashSaleProduct)
            .Where(c => c.UserId == userId)
            .ToListAsync();

        if (!cartItems.Any())
        {
            TempData["Error"] = "Giỏ hàng trống. Vui lòng thêm sản phẩm trước khi thanh toán.";
            return RedirectToAction("Index", "Cart");
        }

        // Get user profile for pre-filling
        var user = await _userManager.GetUserAsync(User);

        // Calculate total with effective prices
        decimal subtotal = 0;
        foreach (var item in cartItems)
        {
            var effectivePrice = item.LockedPrice ?? item.Product!.Price;
            subtotal += effectivePrice * item.Quantity;
        }


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
                UnitPrice = c.LockedPrice ?? c.Product?.Price ?? 0,
                Quantity = c.Quantity
            }).ToList(),
            Subtotal = subtotal
        };

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
                    .ThenInclude(p => p!.ProductImages)
                .Include(c => c.FlashSaleProduct)
                .Where(c => c.UserId == userId)
                .ToListAsync();

            decimal subtotal = 0;
            foreach (var item in cartItems)
            {
                var effectivePrice = item.LockedPrice ?? item.Product!.Price;
                subtotal += effectivePrice * item.Quantity;
            }

            model.CartItems = cartItems.Select(c => new CartItemViewModel
            {
                ProductId = c.ProductId,
                ProductTitle = c.Product?.Title ?? string.Empty,
                ProductImageUrl = c.Product?.ProductImages?.FirstOrDefault()?.ImageUrl ?? "/images/no-image.svg",
                UnitPrice = c.Product?.Price ?? 0,
                Quantity = c.Quantity
            }).ToList();

            model.Subtotal = subtotal;
            model.Total = model.Subtotal + model.ShippingCost;

            return View("Index", model);
        }

        // Get cart items
        var userCartItems = await _context.CartItems
            .Include(c => c.Product)
            .Include(c => c.FlashSaleProduct)
                .ThenInclude(fsp => fsp!.FlashSale)
            .Where(c => c.UserId == userId)
            .ToListAsync();

        if (!userCartItems.Any())
        {
            TempData["Error"] = "Giỏ hàng trống.";
            return RedirectToAction("Index", "Cart");
        }

        // Validate Flash Sale are still active and check stock limits
        foreach (var cartItem in userCartItems)
        {
            if (cartItem.FlashSaleProductId.HasValue)
            {
                var flashSale = cartItem.FlashSaleProduct;
                var now = DateTime.UtcNow;

                // Check flash sale still active
                if (flashSale == null ||
                    !flashSale.FlashSale!.IsActive ||
                    flashSale.FlashSale.StartDate > now ||
                    flashSale.FlashSale.EndDate < now)
                {
                    TempData["Error"] = $"Flash Sale cho sản phẩm '{cartItem.Product!.Title}' đã kết thúc.";
                    return RedirectToAction("Index", "Cart");
                }

                // Check stock limit
                if (!await _flashSaleService.CanPurchaseAtFlashPriceAsync(cartItem.FlashSaleProductId.Value, cartItem.Quantity))
                {
                    TempData["Error"] = $"Số lượng sản phẩm '{cartItem.Product!.Title}' vượt quá giới hạn mua trong Flash Sale.";
                    return RedirectToAction("Index", "Cart");
                }
            }
        }

        // Calculate order total with effective prices
        decimal orderTotal = 0;
        var orderItems = new List<OrderItem>();

        foreach (var cartItem in userCartItems)
        {
            var effectivePrice = cartItem.LockedPrice ?? cartItem.Product!.Price;
            var originalPrice = cartItem.Product!.Price;

            var orderItem = new OrderItem
            {
                ProductId = cartItem.ProductId,
                Quantity = cartItem.Quantity,
                UnitPrice = effectivePrice,
                FlashSaleProductId = cartItem.FlashSaleProductId,
                WasOnFlashSale = cartItem.FlashSaleProductId.HasValue,
                FlashSaleDiscount = cartItem.FlashSaleProductId.HasValue
                    ? (originalPrice - effectivePrice) * cartItem.Quantity
                    : null
            };

            orderItems.Add(orderItem);
            orderTotal += effectivePrice * cartItem.Quantity;
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
            Total = orderTotal,
            OrderItems = orderItems
        };

        _context.Orders.Add(order);
        await _context.SaveChangesAsync();

        // Increment flash sale sold count
        foreach (var cartItem in userCartItems)
        {
            if (cartItem.FlashSaleProductId.HasValue)
            {
                await _flashSaleService.IncrementSoldCountAsync(cartItem.FlashSaleProductId.Value, cartItem.Quantity);
            }
            
            // Decrease product stock
            cartItem.Product!.Stock -= cartItem.Quantity;
        }

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
