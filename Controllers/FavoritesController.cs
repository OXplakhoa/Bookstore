using Bookstore.Data;
using Bookstore.ViewModels;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Bookstore.Controllers;

[Authorize]
public class FavoritesController : Controller
{
    private readonly ApplicationDbContext _context;
    private readonly UserManager<ApplicationUser> _userManager;

    public FavoritesController(ApplicationDbContext context, UserManager<ApplicationUser> userManager)
    {
        _context = context;
        _userManager = userManager;
    }

    [HttpGet]
    public async Task<IActionResult> Index()
    {
        var userId = _userManager.GetUserId(User);
        if (string.IsNullOrEmpty(userId))
        {
            return Challenge();
        }

        var favoriteIds = await _context.FavoriteProducts
            .Where(fp => fp.ApplicationUserId == userId)
            .Select(fp => fp.ProductId)
            .ToListAsync();

        var products = favoriteIds.Count == 0
            ? new List<Product>()
            : await _context.Products
                .Where(p => favoriteIds.Contains(p.ProductId) && p.IsActive)
                .Include(p => p.ProductImages)
                .Include(p => p.Category)
                .AsNoTracking()
                .ToListAsync();

        var productLookup = products.ToDictionary(p => p.ProductId);
        var ordered = favoriteIds
            .Select(id => productLookup.TryGetValue(id, out var product) ? product : null)
            .Where(p => p != null)
            .Select(p => new ProductCardViewModel
            {
                Product = p,
                IsFavorited = true,
                IsRecentlyViewed = false
            })
            .ToList();

        if (ordered.Count == 0)
        {
            ordered = products
                .OrderBy(p => p.Title)
                .Select(p => new ProductCardViewModel
                {
                    Product = p,
                    IsFavorited = true,
                    IsRecentlyViewed = false
                })
                .ToList();
        }

        var viewModel = new FavoritesViewModel
        {
            Favorites = ordered
        };

        return View("~/Views/Products/Favorites.cshtml", viewModel);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Toggle([FromBody] ToggleFavoriteRequest request)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(new { success = false });
        }

        var userId = _userManager.GetUserId(User);
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized(new { success = false });
        }

        var product = await _context.Products
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.ProductId == request.ProductId && p.IsActive);

        if (product == null)
        {
            return NotFound(new { success = false });
        }

        var favorite = await _context.FavoriteProducts
            .FirstOrDefaultAsync(fp => fp.ApplicationUserId == userId && fp.ProductId == request.ProductId);

        var isFavorited = favorite == null;

        if (favorite == null)
        {
            _context.FavoriteProducts.Add(new FavoriteProduct
            {
                ApplicationUserId = userId,
                ProductId = request.ProductId
            });
            isFavorited = true;
        }
        else
        {
            _context.FavoriteProducts.Remove(favorite);
            isFavorited = false;
        }

        await _context.SaveChangesAsync();

        return Json(new { success = true, isFavorited });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Remove(int productId)
    {
        var userId = _userManager.GetUserId(User);
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        var favorite = await _context.FavoriteProducts
            .FirstOrDefaultAsync(fp => fp.ApplicationUserId == userId && fp.ProductId == productId);

        if (favorite != null)
        {
            _context.FavoriteProducts.Remove(favorite);
            await _context.SaveChangesAsync();
        }

        return RedirectToAction(nameof(Index));
    }

    public record ToggleFavoriteRequest(int ProductId);
}
