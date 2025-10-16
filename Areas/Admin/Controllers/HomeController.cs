using Bookstore.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Bookstore.Areas.Admin.Controllers
{
    [Area("Admin")]
    [Authorize(Roles = "Admin")]
    public class HomeController : Controller
    {
        private readonly ApplicationDbContext _context;

        public HomeController(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<IActionResult> Index()
        {
            var stats = new
            {
                TotalProducts = await _context.Products.CountAsync(),
                ActiveProducts = await _context.Products.CountAsync(p => p.IsActive),
                TotalCategories = await _context.Categories.CountAsync(),
                TotalOrders = await _context.Orders.CountAsync(),
                LowStockProducts = await _context.Products.CountAsync(p => p.Stock < 10 && p.IsActive)
            };

            ViewBag.Stats = stats;
            return View();
        }
    }
}

