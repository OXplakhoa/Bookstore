using Bookstore.Data;
using Bookstore.Services;
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
        private readonly IDatabaseService _databaseService;

        public HomeController(ApplicationDbContext context, IDatabaseService databaseService)
        {
            _context = context;
            _databaseService = databaseService;
        }

        public async Task<IActionResult> Index()
        {
            // Sử dụng Stored Procedure sp_GetDashboardStats thay vì nhiều LINQ queries
            var dashboardStats = await _databaseService.GetDashboardStatsAsync();
            
            // Lấy thêm thông tin cảnh báo sản phẩm sắp hết hàng
            var lowStockProducts = await _databaseService.GetLowStockProductsAsync(10);
            
            // Lấy top 5 sản phẩm bán chạy
            var topSellingProducts = await _databaseService.GetTopSellingProductsAsync(5);
            
            ViewBag.Stats = dashboardStats;
            ViewBag.LowStockProducts = lowStockProducts;
            ViewBag.TopSellingProducts = topSellingProducts;
            
            return View();
        }

        [HttpGet]
        public async Task<IActionResult> GetDashboardStats()
        {
            var stats = await _databaseService.GetDashboardStatsAsync();
            return Json(stats);
        }

        [HttpGet]
        public async Task<IActionResult> GetLowStockAlerts(int threshold = 10)
        {
            var lowStockProducts = await _databaseService.GetLowStockProductsAsync(threshold);
            return Json(lowStockProducts);
        }
    }
}

