using Bookstore.Data;
using Microsoft.EntityFrameworkCore;

namespace Bookstore.Services;

public interface IFlashSaleService
{
    Task<FlashSaleProduct?> GetActiveFlashSaleForProductAsync(int productId); //Get specific active flash sale for a product
    Task<Dictionary<int, FlashSaleProduct>> GetActiveFlashSalesForProductsAsync(IEnumerable<int> productIds); //Get list of active flash sales for multiple products
    Task<bool> IsProductOnFlashSaleAsync(int productId);
    Task<decimal> GetEffectivePriceAsync(int productId, decimal originalPrice);
    Task<bool> CanPurchaseAtFlashPriceAsync(int flashSaleProductId, int quantity);
    Task IncrementSoldCountAsync(int flashSaleProductId, int quantity);
}

public class FlashSaleService : IFlashSaleService
{
    private readonly ApplicationDbContext _context;
    public FlashSaleService(ApplicationDbContext context)
    {
        _context = context;
    }
    public async Task<FlashSaleProduct?> GetActiveFlashSaleForProductAsync(int productId)
    {
        var now = DateTime.UtcNow;

        return await _context.FlashSaleProducts
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
}