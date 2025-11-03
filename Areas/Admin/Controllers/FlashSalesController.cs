using Bookstore.Data;
using Bookstore.Services;
using Bookstore.ViewModels.Admin;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;

namespace Bookstore.Areas.Admin.Controllers;

[Area("Admin")]
[Authorize(Roles = "Admin")]
public class FlashSalesController : Controller
{
    private readonly ApplicationDbContext _context;
    private readonly IFlashSaleService _flashSaleService;
    private readonly IFlashSaleNotificationService _notificationService;

    public FlashSalesController(
        ApplicationDbContext context, 
        IFlashSaleService flashSaleService,
        IFlashSaleNotificationService notificationService)
    {
        _context = context;
        _flashSaleService = flashSaleService;
        _notificationService = notificationService;
    }

    // GET: Admin/FlashSales
    public async Task<IActionResult> Index()
    {
        var now = DateTime.UtcNow;
        var flashSales = await _context.FlashSales
            .Include(fs => fs.FlashSaleProducts)
            .OrderByDescending(fs => fs.CreatedAt)
            .Select(fs => new FlashSaleViewModel
            {
                FlashSaleId = fs.FlashSaleId,
                Name = fs.Name,
                StartDate = fs.StartDate,
                EndDate = fs.EndDate,
                IsActive = fs.StartDate <= now && fs.EndDate >= now,
                ProductCount = fs.FlashSaleProducts!.Count,
                Status = fs.EndDate < now ? "Expired" :
                         fs.StartDate > now ? "Upcoming" :
                         fs.IsActive ? "Active" : "Inactive"
            })
            .ToListAsync();

        return View(flashSales);
    }

    // GET: Admin/GetFlashSales/:id
    public async Task<IActionResult> Details(int? id)
    {
        if (id == null)
            return NotFound();
        var flashSale = await _context.FlashSales
            .Include(fs => fs.FlashSaleProducts!)
                .ThenInclude(fsp => fsp.Product)
            .FirstOrDefaultAsync(fs => fs.FlashSaleId == id);
        if (flashSale == null)
            return NotFound();
        return View(flashSale);
    }

    // GET: Admin/FlashSales/Create
    public IActionResult Create()
    {
        // Set default dates: start now, end in 7 days
        var model = new FlashSale
        {
            StartDate = DateTime.UtcNow,
            EndDate = DateTime.UtcNow.AddDays(7),
            IsActive = true
        };
        return View(model);
    }

    // POST: Admin/FlashSales/Create
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(FlashSale flashSale)
    {
        if (flashSale.StartDate >= flashSale.EndDate)
        {
            ModelState.AddModelError(string.Empty, "Ngày kết thúc phải sớm hơn ngày bắt đầu.");
        }
        if (ModelState.IsValid)
        {
            flashSale.CreatedAt = DateTime.UtcNow;
            _context.Add(flashSale);
            await _context.SaveChangesAsync();
            TempData["SuccessMessage"] = "Flash Sale đã được tạo thành công.";
            return RedirectToAction(nameof(ManageProducts), new { id = flashSale.FlashSaleId });
        }
        return View(flashSale);
    }
    
    // GET: Admin/FlashSales/Edit/:id
    public async Task<IActionResult> Edit(int? id)
    {
        if (id == null)
            return NotFound();

        var flashSale = await _context.FlashSales.FindAsync(id);
        if (flashSale == null)
            return NotFound();

        return View(flashSale);
    }

    // POST: Admin/FlashSales/Edit/:id
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(int id, FlashSale flashSale)
    {
        if (id != flashSale.FlashSaleId)
            return NotFound();

        // Validate dates
        if (flashSale.StartDate >= flashSale.EndDate)
        {
            ModelState.AddModelError("EndDate", "Ngày kết thúc phải sớm hơn ngày bắt đầu.");
        }

        if (ModelState.IsValid)
        {
            try
            {
                _context.Update(flashSale);
                await _context.SaveChangesAsync();

                // Invalidate Cache after update
                _flashSaleService.InvalidateFlashSaleCache(flashSale.FlashSaleId);

                TempData["SuccessMessage"] = "Flash Sale đã được cập nhật thành công.";

            }
            catch (DbUpdateConcurrencyException) // Catch race condition errors
            {
                if (!FlashSaleExists(flashSale.FlashSaleId))
                    return NotFound();
                else
                    throw;
            }
            return RedirectToAction(nameof(Index));
        }
        return View(flashSale);
    }

    // POST: Admin/FlashSales/ToggleActive/:id
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ToggleActive(int id)
    {
        var flashSale = await _context.FlashSales.FindAsync(id);
        if (flashSale == null)
            return NotFound();
        flashSale.IsActive = !flashSale.IsActive;
        _context.Update(flashSale);
        await _context.SaveChangesAsync();

        // Invalidate Cache after toggle
        _flashSaleService.InvalidateFlashSaleCache(flashSale.FlashSaleId);

        TempData["SuccessMessage"] = flashSale.IsActive
        ? "Flash Sale đã được kích hoạt."
        : "Flash Sale đã được vô hiệu hóa.";

        return RedirectToAction(nameof(Index));
    }

    // POST: Admin/FlashSales/Delete/:id
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Delete(int id)
    {
        var flashSale = await _context.FlashSales
            .Include(fs => fs.FlashSaleProducts)
            .FirstOrDefaultAsync(fs => fs.FlashSaleId == id);

        if (flashSale == null)
            return NotFound();

        // Soft delete: Set IsActive = false
        flashSale.IsActive = false;
        _context.Update(flashSale);
        await _context.SaveChangesAsync();

        // Invalidate Cache after deletion
        _flashSaleService.InvalidateFlashSaleCache(flashSale.FlashSaleId);

        TempData["SuccessMessage"] = "Flash Sale đã được xóa (vô hiệu hóa) thành công.";
        return RedirectToAction(nameof(Index));
    }
    // GET: Admin/FlashSales/ManageProducts/:id
    public async Task<IActionResult> ManageProducts(int? id)
    {
        if (id == null)
            return NotFound();
        var flashSale = await _context.FlashSales
            .Include(fs => fs.FlashSaleProducts!)
                .ThenInclude(fsp => fsp.Product)
            .FirstOrDefaultAsync(fs => fs.FlashSaleId == id);
        if (flashSale == null)
            return NotFound();

        // Get list products not in this flash sale
        var existingProductIds = flashSale.FlashSaleProducts!
            .Select(fsp => fsp.ProductId)
            .ToList();

        var availableProducts = await _context.Products
            .Where(p => !existingProductIds.Contains(p.ProductId)) // Exclude products already in the flash sale
            .Select(p => new 
            {
                p.ProductId,
                p.Title,
                p.Price
            })
            .ToListAsync();

        ViewBag.FlashSale = flashSale;
        ViewBag.AvailableProducts = availableProducts;

        return View(flashSale.FlashSaleProducts);
    }

    // POST: Admin/FlashSales/AddProduct
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> AddProduct(FlashSaleProductFormViewModel model)
    {
        if (!ModelState.IsValid)
        {
            TempData["ErrorMessage"] = "Dữ liệu không hợp lệ.";
            return RedirectToAction(nameof(ManageProducts), new { id = model.FlashSaleId });
        }
        // Get product info
        var product = await _context.Products.FindAsync(model.ProductId);
        if (product == null)
        {
            TempData["ErrorMessage"] = "Sản phẩm không tồn tại.";
            return RedirectToAction(nameof(ManageProducts), new { id = model.FlashSaleId });
        }
        // Validate: SalePrice < Product.Price
        if (model.SalePrice >= product.Price)
        {
            TempData["ErrorMessage"] = "Giá khuyến mãi phải thấp hơn giá gốc của sản phẩm.";
            return RedirectToAction(nameof(ManageProducts), new { id = model.FlashSaleId });
        }
        // Validiate: Product not in other active flash sales
        var now = DateTime.UtcNow;
        var existingInOtherSale = await _context.FlashSaleProducts
            .Include(fsp => fsp.FlashSale)
            .AnyAsync(fsp =>
                fsp.ProductId == model.ProductId &&
                fsp.FlashSaleId != model.FlashSaleId &&
                fsp.FlashSale!.IsActive &&
                fsp.FlashSale.StartDate <= now &&
                fsp.FlashSale.EndDate >= now);
        if (existingInOtherSale)
        {
            TempData["ErrorMessage"] = "Sản phẩm này đã tham gia vào một Flash Sale đang hoạt động khác.";
            return RedirectToAction(nameof(ManageProducts), new { id = model.FlashSaleId });
        }
        // Create FlashSaleProduct
        var flashSaleProduct = new FlashSaleProduct
        {
            FlashSaleId = model.FlashSaleId,
            ProductId = model.ProductId,
            OriginalPrice = product.Price, // ← Get from product, not model
            SalePrice = model.SalePrice,
            DiscountPercentage = (product.Price - model.SalePrice) / product.Price * 100,
            StockLimit = model.StockLimit,
            SoldCount = 0
        };
        _context.FlashSaleProducts.Add(flashSaleProduct);
        await _context.SaveChangesAsync();

        // Invalidate Cache after adding specific product
        _flashSaleService.InvalidateProductFlashSaleCache(model.ProductId);

        TempData["SuccessMessage"] = "Sản phẩm đã được thêm vào Flash Sale thành công.";
        return RedirectToAction(nameof(ManageProducts), new { id = model.FlashSaleId });

    }
    
    // POST: Admin/FlashSales/UpdateProduct
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateProduct(int FlashSaleProductId, int FlashSaleId, int ProductId, decimal SalePrice, int? StockLimit)
    {
        var flashSaleProduct = await _context.FlashSaleProducts.FindAsync(FlashSaleProductId);
        if (flashSaleProduct == null)
        {
            TempData["ErrorMessage"] = "Không tìm thấy sản phẩm trong Flash Sale.";
            return RedirectToAction(nameof(ManageProducts), new { id = FlashSaleId });
        }

        // Get product to validate price
        var product = await _context.Products.FindAsync(ProductId);
        if (product == null)
        {
            TempData["ErrorMessage"] = "Sản phẩm không tồn tại.";
            return RedirectToAction(nameof(ManageProducts), new { id = FlashSaleId });
        }

        // Validate: SalePrice < OriginalPrice
        if (SalePrice >= flashSaleProduct.OriginalPrice)
        {
            TempData["ErrorMessage"] = "Giá khuyến mãi phải nhỏ hơn giá gốc.";
            return RedirectToAction(nameof(ManageProducts), new { id = FlashSaleId });
        }

        // Update properties
        flashSaleProduct.SalePrice = SalePrice;
        flashSaleProduct.StockLimit = StockLimit;
        flashSaleProduct.DiscountPercentage = ((flashSaleProduct.OriginalPrice - SalePrice) / flashSaleProduct.OriginalPrice) * 100;

        _context.Update(flashSaleProduct);
        await _context.SaveChangesAsync();

        // Invalidate cache after update
        _flashSaleService.InvalidateProductFlashSaleCache(ProductId);

        TempData["SuccessMessage"] = "Cập nhật sản phẩm thành công!";
        return RedirectToAction(nameof(ManageProducts), new { id = FlashSaleId });
    }

    // POST: Admin/FlashSales/RemoveProduct
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> RemoveProduct(int id)
    {
        var flashSaleProduct = await _context.FlashSaleProducts.FindAsync(id);
        if (flashSaleProduct == null)
            return NotFound();

        var flashSaleId = flashSaleProduct.FlashSaleId;
        var productId = flashSaleProduct.ProductId;

        _context.FlashSaleProducts.Remove(flashSaleProduct);
        await _context.SaveChangesAsync();

        // Invalidate Cache after removing specific product
        _flashSaleService.InvalidateProductFlashSaleCache(productId);
        TempData["SuccessMessage"] = "Sản phẩm đã được gỡ khỏi Flash Sale thành công.";
        return RedirectToAction(nameof(ManageProducts), new { id = flashSaleId });
    }

    // GET: Admin/FlashSales/Analytics/:id
    public async Task<IActionResult> Analytics(int id)
    {
        var flashSale = await _context.FlashSales
            .Include(fs => fs.FlashSaleProducts!)
                .ThenInclude(fsp => fsp.Product)
                    .ThenInclude(p => p!.ProductImages)
            .AsNoTracking()
            .FirstOrDefaultAsync(fs => fs.FlashSaleId == id);

        if (flashSale == null)
        {
            TempData["ErrorMessage"] = "Flash Sale không tồn tại.";
            return RedirectToAction(nameof(Index));
        }

        var now = DateTime.UtcNow;
        var status = flashSale.EndDate < now ? "Expired" :
                     flashSale.StartDate > now ? "Upcoming" :
                     flashSale.IsActive ? "Active" : "Inactive";

        // Get all flash sale product IDs
        var flashSaleProductIds = flashSale.FlashSaleProducts!
            .Select(fsp => fsp.FlashSaleProductId)
            .ToList();

        // Get all order items related to this flash sale
        var orderItems = await _context.OrderItems
            .Include(oi => oi.Order)
            .Include(oi => oi.Product)
                .ThenInclude(p => p!.ProductImages)
            .Where(oi => oi.FlashSaleProductId != null && 
                         flashSaleProductIds.Contains(oi.FlashSaleProductId.Value))
            .AsNoTracking()
            .ToListAsync();

        // Calculate summary statistics
        var totalUnitsSold = orderItems.Sum(oi => oi.Quantity);
        var totalRevenue = orderItems.Sum(oi => oi.UnitPrice * oi.Quantity);
        var totalOrders = orderItems.Select(oi => oi.OrderId).Distinct().Count();
        var totalProducts = flashSale.FlashSaleProducts?.Count ?? 0;

        // Calculate total discount given
        var totalDiscount = flashSale.FlashSaleProducts?
            .Sum(fsp => (fsp.OriginalPrice - fsp.SalePrice) * fsp.SoldCount) ?? 0;

        // Calculate average order value
        var averageOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;

        // Get product breakdown with performance metrics
        var productBreakdown = flashSale.FlashSaleProducts?
            .Select(fsp =>
            {
                var soldCount = fsp.SoldCount;
                var revenue = orderItems
                    .Where(oi => oi.FlashSaleProductId == fsp.FlashSaleProductId)
                    .Sum(oi => oi.UnitPrice * oi.Quantity);
                
                var discountGiven = (fsp.OriginalPrice - fsp.SalePrice) * soldCount;
                var stockRemaining = fsp.StockLimit.HasValue 
                    ? Math.Max(0, fsp.StockLimit.Value - soldCount) 
                    : int.MaxValue;
                var sellThroughRate = fsp.StockLimit.HasValue && fsp.StockLimit.Value > 0
                    ? (double)soldCount / fsp.StockLimit.Value * 100
                    : 0;

                return new FlashSaleAnalyticsViewModel.ProductBreakdown
                {
                    ProductId = fsp.ProductId,
                    Title = fsp.Product?.Title ?? "Unknown",
                    Author = fsp.Product?.Author,
                    ImageUrl = fsp.Product?.ProductImages?.FirstOrDefault()?.ImageUrl,
                    OriginalPrice = fsp.OriginalPrice,
                    SalePrice = fsp.SalePrice,
                    DiscountPercentage = fsp.DiscountPercentage,
                    QuantitySold = soldCount,
                    Revenue = revenue,
                    TotalDiscount = discountGiven,
                    StockLimit = fsp.StockLimit,
                    StockRemaining = stockRemaining == int.MaxValue ? 0 : stockRemaining,
                    SellThroughRate = sellThroughRate
                };
            })
            .OrderByDescending(pb => pb.QuantitySold)
            .ToList();

        // Get daily sales data for chart
        var salesByDay = orderItems
            .GroupBy(oi => oi.Order!.OrderDate.Date)
            .Select(g => new FlashSaleAnalyticsViewModel.DailySales
            {
                Date = g.Key,
                Orders = g.Select(oi => oi.OrderId).Distinct().Count(),
                UnitsSold = g.Sum(oi => oi.Quantity),
                Revenue = g.Sum(oi => oi.UnitPrice * oi.Quantity)
            })
            .OrderBy(d => d.Date)
            .ToList();

        // For conversion rate, we would need view tracking
        // For now, we'll use a simplified metric based on sold vs stock limit
        var totalStockLimit = flashSale.FlashSaleProducts?
            .Where(fsp => fsp.StockLimit.HasValue)
            .Sum(fsp => fsp.StockLimit!.Value) ?? 0;
        
        var conversionRate = totalStockLimit > 0 
            ? (double)totalUnitsSold / totalStockLimit * 100 
            : 0;

        var viewModel = new FlashSaleAnalyticsViewModel
        {
            FlashSaleId = flashSale.FlashSaleId,
            Name = flashSale.Name ?? "Unnamed Flash Sale",
            Description = flashSale.Description,
            StartDate = flashSale.StartDate,
            EndDate = flashSale.EndDate,
            IsActive = flashSale.IsActive,
            Status = status,
            TotalUnitsSold = totalUnitsSold,
            TotalRevenue = totalRevenue,
            TotalDiscount = totalDiscount,
            TotalOrders = totalOrders,
            TotalProducts = totalProducts,
            ConversionRate = conversionRate,
            AverageOrderValue = averageOrderValue,
            TopProducts = productBreakdown ?? new List<FlashSaleAnalyticsViewModel.ProductBreakdown>(),
            SalesByDay = salesByDay
        };

        return View(viewModel);
    }

    // POST: Admin/FlashSales/SendNotifications/:id
    /// <summary>
    /// Gửi email thông báo Flash Sale cho users có favorite products
    /// </summary>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> SendNotifications(int id)
    {
        var flashSale = await _context.FlashSales
            .Include(fs => fs.FlashSaleProducts)
            .FirstOrDefaultAsync(fs => fs.FlashSaleId == id);

        if (flashSale == null)
        {
            TempData["ErrorMessage"] = "Không tìm thấy Flash Sale.";
            return RedirectToAction(nameof(Index));
        }

        if (!flashSale.IsActive)
        {
            TempData["ErrorMessage"] = "Flash Sale không hoạt động. Không thể gửi thông báo.";
            return RedirectToAction(nameof(Details), new { id });
        }

        if (flashSale.FlashSaleProducts == null || !flashSale.FlashSaleProducts.Any())
        {
            TempData["ErrorMessage"] = "Flash Sale chưa có sản phẩm nào. Vui lòng thêm sản phẩm trước khi gửi thông báo.";
            return RedirectToAction(nameof(ManageProducts), new { id });
        }

        try
        {
            var emailsSent = await _notificationService.SendFlashSaleNotificationsAsync(id);

            if (emailsSent > 0)
            {
                TempData["SuccessMessage"] = $"✅ Đã gửi {emailsSent} email thông báo Flash Sale thành công!";
            }
            else
            {
                TempData["WarningMessage"] = "⚠️ Không có user nào đã favorite các sản phẩm trong Flash Sale này.";
            }
        }
        catch (Exception ex)
        {
            TempData["ErrorMessage"] = $"❌ Lỗi khi gửi thông báo: {ex.Message}";
        }

        return RedirectToAction(nameof(Details), new { id });
    }

    // Private helper to check if FlashSale exists
    private bool FlashSaleExists(int id)
    {
        return _context.FlashSales.Any(e => e.FlashSaleId == id);
    }
}