using Bookstore.Helpers;
using Bookstore.ViewModels;
using Bookstore.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Bookstore.Controllers
{
    public class ProductsController : Controller
    {
        private readonly ApplicationDbContext _context;
        private const int DefaultPageSize = 12;
        public ProductsController(ApplicationDbContext context)
        {
            _context = context;
        }
        //Get: /Products 
        // supports: ?search=xxx&categoryId=1&page=2&sort=price_asc or price_desc or newest
        public async Task<IActionResult> Index(string search, int? categoryId, int page = 1, string sort = "newest", int pageSize = DefaultPageSize)
        {
            var categories = await _context.Categories.OrderBy(c => c.Name).ToListAsync();

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
                Sort = sort
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

            // related: same category, top 4
            var related = await _context.Products
                .Where(p => p.CategoryId == product.CategoryId && p.ProductId != product.ProductId && p.IsActive)
                .OrderByDescending(p => p.CreatedAt)
                .Take(4)
                .AsNoTracking() // Optimizing 
                .ToListAsync();
            var vm = new ProductDetailsViewModel //VM to encapsulate data 
            {
                Product = product,
                RelatedProducts = related
            };
            return View(vm);
        }
    }
}