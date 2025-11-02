using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Bookstore.Models;
using Bookstore.Data;

namespace Bookstore.Controllers;

public class HomeController : Controller
{
    private readonly ILogger<HomeController> _logger;
    private readonly ApplicationDbContext _context;

    public HomeController(ILogger<HomeController> logger, ApplicationDbContext context)
    {
        _logger = logger;
        _context = context;
    }

    public async Task<IActionResult> Index()
    {
        var now = DateTime.UtcNow;
        
        // Get active flash sale products
        var flashSaleProducts = await _context.FlashSaleProducts
            .Include(fsp => fsp.Product)
                .ThenInclude(p => p!.ProductImages)
            .Include(fsp => fsp.FlashSale)
            .Where(fsp =>
                fsp.FlashSale!.IsActive &&
                fsp.FlashSale.StartDate <= now &&
                fsp.FlashSale.EndDate >= now &&
                fsp.Product!.IsActive)
            .OrderByDescending(fsp => fsp.DiscountPercentage)
            .Take(8)
            .AsNoTracking()
            .ToListAsync();

        ViewBag.FlashSaleProducts = flashSaleProducts;
        
        return View();
    }

    public IActionResult Privacy()
    {
        return View();
    }

    // Flash Sale Testing Page - Remove in production
    public IActionResult TestFlashSale()
    {
        return View();
    }

    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
    {
        return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }
}
