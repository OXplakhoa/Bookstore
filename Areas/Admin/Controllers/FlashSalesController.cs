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

    public FlashSalesController(ApplicationDbContext context, IFlashSaleService flashSaleService)
    {
        _context = context;
        _flashSaleService = flashSaleService;
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
            .Select(p => new SelectListItem
            {
                Value = p.ProductId.ToString(),
                Text = $"{p.Title} - {p.Price:C}"
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
            OriginalPrice = model.OriginalPrice,
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

    // Private helper to check if FlashSale exists
    private bool FlashSaleExists(int id)
    {
        return _context.FlashSales.Any(e => e.FlashSaleId == id);
    }
}