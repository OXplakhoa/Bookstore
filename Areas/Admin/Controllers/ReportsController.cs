using Bookstore.Services;
using Bookstore.Models.Dtos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Bookstore.Areas.Admin.Controllers
{
    /// <summary>
    /// Controller để quản lý báo cáo và thống kê
    /// Sử dụng các Stored Procedures: sp_GetDailyRevenue, sp_GetTopSellingProducts, 
    /// sp_GetCategoryStatistics, sp_GetTopCustomers
    /// </summary>
    [Area("Admin")]
    [Authorize(Roles = "Admin")]
    public class ReportsController : Controller
    {
        private readonly IDatabaseService _databaseService;

        public ReportsController(IDatabaseService databaseService)
        {
            _databaseService = databaseService;
        }

        public async Task<IActionResult> Index()
        {
            // Lấy dữ liệu cho 30 ngày gần đây
            var endDate = DateTime.UtcNow;
            var startDate = endDate.AddDays(-30);
            
            // Sử dụng các Stored Procedures
            var dailyRevenue = await _databaseService.GetDailyRevenueAsync(startDate, endDate);
            var topProducts = await _databaseService.GetTopSellingProductsAsync(10);
            var categoryStats = await _databaseService.GetCategoryStatisticsAsync();
            var topCustomers = await _databaseService.GetTopCustomersAsync(10);
            
            ViewBag.DailyRevenue = dailyRevenue;
            ViewBag.TopProducts = topProducts;
            ViewBag.CategoryStats = categoryStats;
            ViewBag.TopCustomers = topCustomers;
            ViewBag.StartDate = startDate;
            ViewBag.EndDate = endDate;
            
            return View();
        }

        [HttpGet]
        public async Task<IActionResult> Revenue(DateTime? startDate, DateTime? endDate)
        {
            var end = endDate ?? DateTime.UtcNow;
            var start = startDate ?? end.AddDays(-30);
            
            var dailyRevenue = await _databaseService.GetDailyRevenueAsync(start, end);
            
            ViewBag.DailyRevenue = dailyRevenue;
            ViewBag.StartDate = start;
            ViewBag.EndDate = end;
            ViewBag.TotalRevenue = dailyRevenue.Sum(r => r.TotalRevenue);
            ViewBag.TotalOrders = dailyRevenue.Sum(r => r.OrderCount);
            ViewBag.AverageOrderValue = dailyRevenue.Count > 0 
                ? dailyRevenue.Average(r => r.AverageOrderValue) 
                : 0;
            
            return View(dailyRevenue);
        }

        [HttpGet]
        public async Task<IActionResult> GetRevenueData(DateTime startDate, DateTime endDate)
        {
            var dailyRevenue = await _databaseService.GetDailyRevenueAsync(startDate, endDate);
            return Json(dailyRevenue);
        }

        [HttpGet]
        public async Task<IActionResult> TopProducts(int count = 10, DateTime? startDate = null, DateTime? endDate = null)
        {
            var topProducts = await _databaseService.GetTopSellingProductsAsync(count, startDate, endDate);
            
            ViewBag.TopProducts = topProducts;
            ViewBag.Count = count;
            ViewBag.StartDate = startDate;
            ViewBag.EndDate = endDate;
            
            return View(topProducts);
        }

        [HttpGet]
        public async Task<IActionResult> GetTopProductsData(int count = 10, DateTime? startDate = null, DateTime? endDate = null)
        {
            var topProducts = await _databaseService.GetTopSellingProductsAsync(count, startDate, endDate);
            return Json(topProducts);
        }

        [HttpGet]
        public async Task<IActionResult> Categories()
        {
            var categoryStats = await _databaseService.GetCategoryStatisticsAsync();
            
            ViewBag.CategoryStats = categoryStats;
            ViewBag.TotalProducts = categoryStats.Sum(c => c.ProductCount);
            ViewBag.TotalSold = categoryStats.Sum(c => c.TotalSold);
            ViewBag.TotalRevenue = categoryStats.Sum(c => c.TotalRevenue);
            
            return View(categoryStats);
        }

        [HttpGet]
        public async Task<IActionResult> GetCategoryData()
        {
            var categoryStats = await _databaseService.GetCategoryStatisticsAsync();
            return Json(categoryStats);
        }

        [HttpGet]
        public async Task<IActionResult> TopCustomers(int count = 10)
        {
            var topCustomers = await _databaseService.GetTopCustomersAsync(count);
            
            ViewBag.TopCustomers = topCustomers;
            ViewBag.Count = count;
            ViewBag.TotalSpent = topCustomers.Sum(c => c.TotalSpent);
            ViewBag.TotalOrders = topCustomers.Sum(c => c.OrderCount);
            
            return View(topCustomers);
        }

        [HttpGet]
        public async Task<IActionResult> GetTopCustomersData(int count = 10)
        {
            var topCustomers = await _databaseService.GetTopCustomersAsync(count);
            return Json(topCustomers);
        }

        [HttpGet]
        public async Task<IActionResult> LowStock(int threshold = 10)
        {
            var lowStockProducts = await _databaseService.GetLowStockProductsAsync(threshold);
            
            ViewBag.LowStockProducts = lowStockProducts;
            ViewBag.Threshold = threshold;
            ViewBag.CriticalCount = lowStockProducts.Count(p => p.Stock <= 5);
            ViewBag.WarningCount = lowStockProducts.Count(p => p.Stock > 5);
            
            return View(lowStockProducts);
        }

        [HttpGet]
        public async Task<IActionResult> GetLowStockData(int threshold = 10)
        {
            var lowStockProducts = await _databaseService.GetLowStockProductsAsync(threshold);
            return Json(lowStockProducts);
        }
    }
}
