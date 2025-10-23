using Bookstore.Helpers;
using Bookstore.ViewModels;
using Bookstore.Data;
using Bookstore.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace Bookstore.Controllers
{
    public class ProductsController : Controller
    {
        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IUserActivityService _userActivityService;
        private const int DefaultPageSize = 12;
        public ProductsController(ApplicationDbContext context, UserManager<ApplicationUser> userManager, IUserActivityService userActivityService)
        {
            _context = context;
            _userManager = userManager;
            _userActivityService = userActivityService;
        }
        //Get: /Products 
        // supports: ?search=xxx&categoryId=1&page=2&sort=price_asc or price_desc or newest
        public async Task<IActionResult> Index(string search, int? categoryId, int page = 1, string sort = "newest", int pageSize = DefaultPageSize)
        {
            var categories = await _context.Categories.OrderBy(c => c.Name).ToListAsync();

            var userId = _userManager.GetUserId(User);
            var favoriteProductIds = new HashSet<int>();
            if (!string.IsNullOrEmpty(userId))
            {
                favoriteProductIds = await _context.FavoriteProducts
                    .Where(fp => fp.ApplicationUserId == userId)
                    .Select(fp => fp.ProductId)
                    .ToHashSetAsync();
            }

            var recentlyViewedIds = new HashSet<int>(await _userActivityService.GetRecentlyViewedProductIdsAsync(userId));

            var query = _context.Products
                .Include(p => p.ProductImages) //Left join
                .Include(p => p.Category)
                .Where(p => p.IsActive) //Ensure only active products are queried
                .AsQueryable(); // Starts building the query
            if (!string.IsNullOrWhiteSpace(search))
            {
                search = search.Trim();
                //Check is null since declare string?
                query = query.Where(p => p.Title != null && p.Title.Contains(search) ||
                                        p.Author != null && p.Author.Contains(search));
            }
            if(categoryId.HasValue && categoryId.Value > 0)
            {
                query = query.Where(p => p.CategoryId == categoryId.Value);
            }

            //sorting
            query = sort switch
            {
                "price_asc" => query.OrderBy(p => p.Price),
                "price_desc" => query.OrderByDescending(p => p.Price),
                "title_asc" => query.OrderBy(p => p.Title),
                "title_desc" => query.OrderByDescending(p => p.Title),
                _ => query.OrderByDescending(p => p.CreatedAt) //default case: newest
            };
            
            var paged = await PaginatedList<Product>.CreateAsync(
                query.AsNoTracking(), //Not to track unnecessary data
                Math.Max(page,1), //Guarantee page number never < 1
                pageSize);
            
            var vm = new ProductListViewModel
            {
                Products = paged,
                Categories = categories,
                Search = search,
                CategoryId = categoryId,
                Sort = sort,
                FavoriteProductIds = favoriteProductIds,
                RecentlyViewedProductIds = recentlyViewedIds
            };
            return View(vm);
        }
        // Get: /Products/Details/5 or  /Products/Details/5?slug=...
        public async Task<IActionResult> Details(int id)
        {
            if (id <= 0) return NotFound();
            var product = await _context.Products
                .Include(p => p.ProductImages)
                .Include(p => p.Category)
                .FirstOrDefaultAsync(p => p.ProductId == id && p.IsActive);
            if (product == null) return NotFound();

            var userId = _userManager.GetUserId(User);
            await _userActivityService.TrackProductViewAsync(product.ProductId, userId);

            var favoriteProductIds = new HashSet<int>();
            if (!string.IsNullOrEmpty(userId))
            {
                favoriteProductIds = await _context.FavoriteProducts
                    .Where(fp => fp.ApplicationUserId == userId)
                    .Select(fp => fp.ProductId)
                    .ToHashSetAsync();
            }

            // related: same category, top 4
            var related = await _context.Products
                .Include(p => p.ProductImages)
                .Include(p => p.Category)
                .Where(p => p.CategoryId == product.CategoryId && p.ProductId != product.ProductId && p.IsActive)
                .OrderByDescending(p => p.CreatedAt)
                .Take(4)
                .AsNoTracking() // Optimizing 
                .ToListAsync();
            var relatedCards = related
                .Select(rp => new ProductCardViewModel
                {
                    Product = rp,
                    IsFavorited = favoriteProductIds.Contains(rp.ProductId),
                    IsRecentlyViewed = false
                })
                .ToList();

            var recentlyViewed = await _userActivityService.GetRecentlyViewedProductsAsync(userId);
            var recentCards = recentlyViewed
                .Where(rv => rv.ProductId != product.ProductId)
                .Select(rv => new ProductCardViewModel
                {
                    Product = rv,
                    IsFavorited = favoriteProductIds.Contains(rv.ProductId),
                    IsRecentlyViewed = true
                })
                .ToList();

            var vm = new ProductDetailsViewModel
            {
                Product = product,
                RelatedProducts = relatedCards,
                RecentlyViewedProducts = recentCards,
                IsFavorited = favoriteProductIds.Contains(product.ProductId)
            };
            return View(vm);
        }

        public async Task<IActionResult> RecentlyViewed()
        {
            var userId = _userManager.GetUserId(User);
            var favoriteProductIds = new HashSet<int>();
            if (!string.IsNullOrEmpty(userId))
            {
                favoriteProductIds = await _context.FavoriteProducts
                    .Where(fp => fp.ApplicationUserId == userId)
                    .Select(fp => fp.ProductId)
                    .ToHashSetAsync();
            }

            var recentlyViewedProducts = await _userActivityService.GetRecentlyViewedProductsAsync(userId);
            var items = recentlyViewedProducts
                .Select(product => new ProductCardViewModel
                {
                    Product = product,
                    IsFavorited = favoriteProductIds.Contains(product.ProductId),
                    IsRecentlyViewed = true
                })
                .ToList();

            var vm = new RecentlyViewedViewModel
            {
                Products = items
            };

            return View("~/Views/Products/RecentlyViewed.cshtml", vm);
        }
    }
}