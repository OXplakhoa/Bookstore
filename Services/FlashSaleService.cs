using Bookstore.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

namespace Bookstore.Services;

public interface IFlashSaleService
{
    Task<FlashSaleProduct?> GetActiveFlashSaleForProductAsync(int productId); //Get specific active flash sale for a product
    Task<Dictionary<int, FlashSaleProduct>> GetActiveFlashSalesForProductsAsync(IEnumerable<int> productIds); //Get list of active flash sales for multiple products
    Task<bool> IsProductOnFlashSaleAsync(int productId);
    Task<decimal> GetEffectivePriceAsync(int productId, decimal originalPrice);
    Task<bool> CanPurchaseAtFlashPriceAsync(int flashSaleProductId, int quantity);
    Task IncrementSoldCountAsync(int flashSaleProductId, int quantity);
    void InvalidateProductFlashSaleCache(int productId);
    void InvalidateFlashSaleCache(int flashSaleId);
}

public class FlashSaleService : IFlashSaleService
{
    private readonly ApplicationDbContext _context;
    private readonly IMemoryCache _cache;
    public FlashSaleService(ApplicationDbContext context, IMemoryCache cache)
    {
        _context = context;
        _cache = cache;
    }
    public async Task<FlashSaleProduct?> GetActiveFlashSaleForProductAsync(int productId)
    {
        var now = DateTime.UtcNow;
        var cacheKey = $"flash_sale_{productId}"; //Cache key based on product ID
        if(!_cache.TryGetValue(cacheKey, out FlashSaleProduct? flashSale)) 
        {
            flashSale = await _context.FlashSaleProducts
                .AsNoTracking() //Read-only query optimization
                .Include(fsp => fsp.FlashSale) //Join with FlashSale
                .Where(fsp =>
                    fsp.ProductId == productId &&
                    fsp.FlashSale!.IsActive &&
                    fsp.FlashSale.StartDate <= now &&
                    fsp.FlashSale.EndDate >= now
                )
                .OrderByDescending(fsp => fsp.DiscountPercentage)
                .FirstOrDefaultAsync();
            var cacheOptions = new MemoryCacheEntryOptions()
                .SetAbsoluteExpiration(TimeSpan.FromMinutes(5)); //Cache for 5 minutes
            _cache.Set(cacheKey, flashSale, cacheOptions);
        }

        return flashSale;
    }
    public async Task<Dictionary<int, FlashSaleProduct>> GetActiveFlashSalesForProductsAsync(IEnumerable<int> productIds)
    {
        if (productIds == null || !productIds.Any())
            return new Dictionary<int, FlashSaleProduct>();
        var now = DateTime.UtcNow;
        var activeFlashSales = await _context.FlashSaleProducts
            .AsNoTracking()
            .Include(fsp => fsp.FlashSale)
            .Where(fsp =>
                productIds.Contains(fsp.ProductId) &&
                fsp.FlashSale!.IsActive &&
                fsp.FlashSale.StartDate <= now &&
                fsp.FlashSale.EndDate >= now
                )
            .ToListAsync();

        return activeFlashSales
            .GroupBy(fsp => fsp.ProductId)
            .ToDictionary(
                g => g.Key,
                g => g.OrderByDescending(fsp => fsp.DiscountPercentage).First()
                // For each product, take the flash sale with the highest discount
            );
    }
    public async Task<bool> IsProductOnFlashSaleAsync(int productId)
    {
        var now = DateTime.UtcNow;
        return await _context.FlashSaleProducts
            .AsNoTracking()
            .Include(fsp => fsp.FlashSale)
            .AnyAsync(fsp =>
                fsp.ProductId == productId &&
                fsp.FlashSale!.IsActive &&
                fsp.FlashSale.StartDate <= now &&
                fsp.FlashSale.EndDate >= now);
    }
    public async Task<decimal> GetEffectivePriceAsync(int productId, decimal originalPrice)
    {
        var activeFlashSales = await GetActiveFlashSaleForProductAsync(productId);
        return activeFlashSales?.SalePrice ?? originalPrice; //If no active flash sale, return original price
    }
    public async Task<bool> CanPurchaseAtFlashPriceAsync(int flashSaleProductId, int quantity)
    {
        var flashSaleProduct = await _context.FlashSaleProducts
            .AsNoTracking()
            .Include(fsp => fsp.FlashSale)
            .FirstOrDefaultAsync(fsp => fsp.FlashSaleProductId == flashSaleProductId);
        if (flashSaleProduct == null)
            return false;
        var now = DateTime.UtcNow;
        if (!flashSaleProduct.FlashSale!.IsActive ||
            flashSaleProduct.FlashSale.StartDate > now ||
            flashSaleProduct.FlashSale.EndDate < now)
            return false;
        if (flashSaleProduct.StockLimit == null)
            return true; //Unlimited stock if not set StockLimit
        var remainingStock = flashSaleProduct.StockLimit.Value - flashSaleProduct.SoldCount; //If StockLimit is set, check remaining stock
        return remainingStock >= quantity;
    }
    public async Task IncrementSoldCountAsync(int flashSaleProductId, int quantity)
    {
        var flashSaleProduct = await _context.FlashSaleProducts
            .FirstOrDefaultAsync(fsp => fsp.FlashSaleProductId == flashSaleProductId);
        if (flashSaleProduct == null)
            throw new InvalidOperationException($"FlashSaleProduct with ID {flashSaleProductId} not found.");
        flashSaleProduct.SoldCount += quantity; //Increase with quantity since in one order can buy multiple items
        await _context.SaveChangesAsync();
    }
    public void InvalidateProductFlashSaleCache(int productId)
    {
        // Use to remove cache for specific product
        var cacheKey = $"flash_sale_{productId}";
        _cache.Remove(cacheKey);
    }
    public void InvalidateFlashSaleCache(int flashSaleId)
    {
        // Use to remove cache for all products in a specific flash sale
        // Get all product IDs associated with the flash sale
        var productIds = _context.FlashSaleProducts
            .Where(fsp => fsp.FlashSaleId == flashSaleId)
            .Select(fsp => fsp.ProductId) // Take only ProductId
            .ToList();

        foreach (var productId in productIds)
        {
            InvalidateProductFlashSaleCache(productId);
        }
    }
}