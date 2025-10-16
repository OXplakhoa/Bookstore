using Bookstore.Data;
using Bookstore.ViewModels;
using Bookstore.ViewModels.Admin;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Bookstore.Areas.Admin.Controllers
{
    [Area("Admin")]
    [Authorize(Roles = "Admin")]
    public class ProductsController : Controller
    {
        private readonly ApplicationDbContext _context;

        public ProductsController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET: Admin/Products
        public async Task<IActionResult> Index(string search, int? categoryId, int page = 1)
        {
            var query = _context.Products
                .Include(p => p.Category)
                .Include(p => p.ProductImages)
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(search))
            {
                search = search.Trim();
                query = query.Where(p => p.Title != null && p.Title.Contains(search) ||
                                        p.Author != null && p.Author.Contains(search));
            }

            if (categoryId.HasValue && categoryId.Value > 0)
            {
                query = query.Where(p => p.CategoryId == categoryId.Value);
            }

            var products = await query
                .OrderByDescending(p => p.CreatedAt)
                .ToListAsync();

            var categories = await _context.Categories.OrderBy(c => c.Name).ToListAsync();

            ViewBag.Categories = categories;
            ViewBag.Search = search;
            ViewBag.CategoryId = categoryId;

            return View(products);
        }

        // GET: Admin/Products/Details/5
        public async Task<IActionResult> Details(int? id)
        {
            if (id == null)
            {
                return NotFound();
            }

            var product = await _context.Products
                .Include(p => p.Category)
                .Include(p => p.ProductImages)
                .FirstOrDefaultAsync(m => m.ProductId == id);

            if (product == null)
            {
                return NotFound();
            }

            return View(product);
        }

        // GET: Admin/Products/Create
        public async Task<IActionResult> Create()
        {
            var categories = await _context.Categories.OrderBy(c => c.Name).ToListAsync();
            var viewModel = new ProductFormViewModel
            {
                Categories = categories
            };
            return View(viewModel);
        }

        // POST: Admin/Products/Create
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(ProductFormViewModel model)
        {
            if (ModelState.IsValid)
            {
                var product = new Product
                {
                    Title = model.Title,
                    Author = model.Author,
                    Description = model.Description,
                    Price = model.Price,
                    Stock = model.Stock,
                    CategoryId = model.CategoryId,
                    IsActive = model.IsActive,
                    CreatedAt = DateTime.UtcNow
                };

                _context.Add(product);
                await _context.SaveChangesAsync();

                // Handle image uploads if any
                if (model.ImageFiles != null && model.ImageFiles.Any())
                {
                    await HandleImageUploads(product.ProductId, model.ImageFiles, model.MainImageIndex);
                }

                TempData["SuccessMessage"] = "Sản phẩm đã được tạo thành công.";
                return RedirectToAction(nameof(Index));
            }

            // Reload categories if validation fails
            model.Categories = await _context.Categories.OrderBy(c => c.Name).ToListAsync();
            return View(model);
        }

        // GET: Admin/Products/Edit/5
        public async Task<IActionResult> Edit(int? id)
        {
            if (id == null)
            {
                return NotFound();
            }

            var product = await _context.Products
                .Include(p => p.ProductImages)
                .FirstOrDefaultAsync(p => p.ProductId == id);

            if (product == null)
            {
                return NotFound();
            }

            var categories = await _context.Categories.OrderBy(c => c.Name).ToListAsync();
            var viewModel = new ProductFormViewModel
            {
                ProductId = product.ProductId,
                Title = product.Title,
                Author = product.Author,
                Description = product.Description,
                Price = product.Price,
                Stock = product.Stock,
                CategoryId = product.CategoryId,
                IsActive = product.IsActive,
                Categories = categories,
                ExistingImages = product.ProductImages?.ToList() ?? new List<ProductImage>()
            };

            return View(viewModel);
        }

        // POST: Admin/Products/Edit/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(int id, ProductFormViewModel model)
        {
            if (id != model.ProductId)
            {
                return NotFound();
            }

            if (ModelState.IsValid)
            {
                try
                {
                    var product = await _context.Products.FindAsync(id);
                    if (product == null)
                    {
                        return NotFound();
                    }

                    product.Title = model.Title;
                    product.Author = model.Author;
                    product.Description = model.Description;
                    product.Price = model.Price;
                    product.Stock = model.Stock;
                    product.CategoryId = model.CategoryId;
                    product.IsActive = model.IsActive;

                    _context.Update(product);
                    await _context.SaveChangesAsync();

                    // Handle new image uploads
                    if (model.ImageFiles != null && model.ImageFiles.Any())
                    {
                        await HandleImageUploads(product.ProductId, model.ImageFiles, model.MainImageIndex);
                    }

                    TempData["SuccessMessage"] = "Sản phẩm đã được cập nhật thành công.";
                }
                catch (DbUpdateConcurrencyException)
                {
                    if (!ProductExists(model.ProductId))
                    {
                        return NotFound();
                    }
                    else
                    {
                        throw;
                    }
                }
                return RedirectToAction(nameof(Index));
            }

            // Reload categories if validation fails
            model.Categories = await _context.Categories.OrderBy(c => c.Name).ToListAsync();
            return View(model);
        }

        // POST: Admin/Products/Delete/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Delete(int id)
        {
            var product = await _context.Products.FindAsync(id);
            if (product != null)
            {
                // Soft delete - just set IsActive to false
                product.IsActive = false;
                _context.Update(product);
                await _context.SaveChangesAsync();
                TempData["SuccessMessage"] = "Sản phẩm đã được xóa thành công.";
            }

            return RedirectToAction(nameof(Index));
        }

        // POST: Admin/Products/ToggleActive/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ToggleActive(int id)
        {
            var product = await _context.Products.FindAsync(id);
            if (product != null)
            {
                product.IsActive = !product.IsActive;
                _context.Update(product);
                await _context.SaveChangesAsync();
                
                var message = product.IsActive ? "Sản phẩm đã được kích hoạt." : "Sản phẩm đã được vô hiệu hóa.";
                TempData["SuccessMessage"] = message;
            }

            return RedirectToAction(nameof(Index));
        }

        private bool ProductExists(int id)
        {
            return _context.Products.Any(e => e.ProductId == id);
        }

        private async Task HandleImageUploads(int productId, IFormFileCollection imageFiles, int? mainImageIndex)
        {
            var uploadsFolder = Path.Combine("wwwroot", "images", "products");
            if (!Directory.Exists(uploadsFolder))
            {
                Directory.CreateDirectory(uploadsFolder);
            }

            for (int i = 0; i < imageFiles.Count; i++)
            {
                var file = imageFiles[i];
                if (file.Length > 0)
                {
                    var fileName = $"{productId}_{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
                    var filePath = Path.Combine(uploadsFolder, fileName);

                    using (var stream = new FileStream(filePath, FileMode.Create))
                    {
                        await file.CopyToAsync(stream);
                    }

                    var productImage = new ProductImage
                    {
                        ProductId = productId,
                        ImageUrl = $"/images/products/{fileName}",
                        IsMain = mainImageIndex.HasValue && mainImageIndex.Value == i
                    };

                    _context.ProductImages.Add(productImage);
                }
            }

            await _context.SaveChangesAsync();
        }
    }
}

