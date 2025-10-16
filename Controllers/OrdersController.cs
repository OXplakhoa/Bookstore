using Bookstore.Data;
using Bookstore.Models;
using Bookstore.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Bookstore.Controllers;
    [Authorize]
    public class OrdersController : Controller
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;

        public OrdersController(ApplicationDbContext context, UserManager<ApplicationUser> userManager)
        {
            _context = context;
            _userManager = userManager;
        }

        // GET: /Orders
        public async Task<IActionResult> Index()
        {
            var userId = _userManager.GetUserId(User);
            if (userId == null)
            {
                return RedirectToAction("Login", "Account", new { area = "Identity" });
            }

            var orders = await _context.Orders
                .Include(o => o.OrderItems)
                .ThenInclude(oi => oi.Product)
                .ThenInclude(p => p.ProductImages)
                .Where(o => o.UserId == userId)
                .OrderByDescending(o => o.OrderDate)
                .ToListAsync();

            var viewModel = orders.Select(o => new OrderSummaryViewModel
            {
                OrderId = o.OrderId,
                OrderNumber = o.OrderNumber ?? string.Empty,
                OrderDate = o.OrderDate,
                Total = o.Total,
                PaymentMethod = o.PaymentMethod ?? string.Empty,
                PaymentStatus = o.PaymentStatus ?? string.Empty,
                OrderStatus = o.OrderStatus ?? string.Empty,
                ItemCount = o.OrderItems?.Sum(oi => oi.Quantity) ?? 0,
                FirstProductImage = o.OrderItems?.FirstOrDefault()?.Product?.ProductImages?.FirstOrDefault()?.ImageUrl ?? "/images/no-image.svg"
            }).ToList();

            return View(viewModel);
        }

        // GET: /Orders/Details/{id}
        public async Task<IActionResult> Details(int id)
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
                .FirstOrDefaultAsync(o => o.OrderId == id && o.UserId == userId);

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
    }
