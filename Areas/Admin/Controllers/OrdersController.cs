using System;
using System.Linq;
using System.Threading.Tasks;
using Bookstore.Data;
using Bookstore.Helpers;
using Bookstore.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Bookstore.Areas.Admin.Controllers
{
    [Area("Admin")]
    [Authorize(Roles = "Admin")]
    public class OrdersController : Controller
    {
        private readonly ApplicationDbContext _context;
        private const int PageSize = 10;
        private static readonly string[] StatusOptions = new[]
        {
            "Pending",
            "Processing",
            "Shipped",
            "Delivered",
            "Cancelled"
        };

        public OrdersController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET: Admin/Orders
        public async Task<IActionResult> Index(int page = 1)
        {
            if (page < 1)
            {
                page = 1;
            }

            var ordersQuery = _context.Orders
                .Include(o => o.User)
                .OrderByDescending(o => o.OrderDate)
                .AsNoTracking();

            var paginatedOrders = await PaginatedList<Order>.CreateAsync(ordersQuery, page, PageSize);

            return View(paginatedOrders);
        }

        // GET: Admin/Orders/Details/5
        public async Task<IActionResult> Details(int id)
        {
            var order = await _context.Orders
                .Include(o => o.User)
                .Include(o => o.OrderItems!)
                    .ThenInclude(oi => oi.Product)
                        .ThenInclude(p => p.ProductImages)
                .AsNoTracking()
                .FirstOrDefaultAsync(o => o.OrderId == id);

            if (order == null)
            {
                return NotFound();
            }

            ViewBag.StatusOptions = StatusOptions;
            return View(order);
        }

        // POST: Admin/Orders/UpdateOrderStatus
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> UpdateOrderStatus(int orderId, string newStatus)
        {
            if (string.IsNullOrWhiteSpace(newStatus))
            {
                TempData["ErrorMessage"] = "Vui lòng chọn trạng thái đơn hàng hợp lệ.";
                return RedirectToAction(nameof(Details), new { id = orderId });
            }

            var order = await _context.Orders.FirstOrDefaultAsync(o => o.OrderId == orderId);
            if (order == null)
            {
                TempData["ErrorMessage"] = "Không tìm thấy đơn hàng.";
                return RedirectToAction(nameof(Index));
            }

            if (!StatusOptions.Contains(newStatus, StringComparer.OrdinalIgnoreCase))
            {
                TempData["ErrorMessage"] = "Trạng thái đơn hàng không hợp lệ.";
                return RedirectToAction(nameof(Details), new { id = orderId });
            }

            order.OrderStatus = StatusOptions.First(status =>
                string.Equals(status, newStatus, StringComparison.OrdinalIgnoreCase));

            _context.Orders.Update(order);
            await _context.SaveChangesAsync();

            TempData["SuccessMessage"] = "Trạng thái đơn hàng đã được cập nhật.";
            return RedirectToAction(nameof(Details), new { id = orderId });
        }
    }
}
