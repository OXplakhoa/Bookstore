// Service để gọi Stored Procedures và Functions từ SQL Server
// Sử dụng EF Core để thực thi raw SQL
using Bookstore.Data;
using Bookstore.Models.Dtos;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using System.Data;

namespace Bookstore.Services;

public interface IDatabaseService
{
    // ===== STORED PROCEDURES =====
    
    Task<DashboardStatsDto> GetDashboardStatsAsync();
    
    Task<List<TopSellingProductDto>> GetTopSellingProductsAsync(int topN = 10, DateTime? startDate = null, DateTime? endDate = null);
    
    Task<List<DailyRevenueDto>> GetDailyRevenueAsync(DateTime startDate, DateTime endDate);
    
    Task<List<CategoryStatisticsDto>> GetCategoryStatisticsAsync();
    
    Task<List<TopCustomerDto>> GetTopCustomersAsync(int topN = 10);

    Task<List<LowStockProductDto>> GetLowStockProductsAsync(int threshold = 10);
    
    // ===== SCALAR FUNCTIONS =====

    Task<decimal> CalculateDiscountAsync(decimal originalPrice, decimal discountPercentage);

    Task<decimal> CalculateFinalPriceAsync(decimal originalPrice, decimal discountPercentage);

    Task<decimal> GetUserCartTotalAsync(string userId);
  
    Task<int> GetUserCartCountAsync(string userId);

    Task<CartSummaryDto> GetCartSummaryAsync(string userId);

    Task<decimal> GetProductAverageRatingAsync(int productId);

    Task<int> GetProductReviewCountAsync(int productId);

    Task<ProductRatingDto> GetProductRatingAsync(int productId);

    Task<decimal> CalculateTaxAsync(decimal amount);

    Task<string> FormatVNDCurrencyAsync(decimal amount);

    Task<string> GetOrderStatusDisplayAsync(string status);
}

/// Gọi các Stored Procedures và Functions từ SQL Server
public class DatabaseService : IDatabaseService
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<DatabaseService> _logger;

    public DatabaseService(ApplicationDbContext context, ILogger<DatabaseService> logger)
    {
        _context = context;
        _logger = logger;
    }

    #region Stored Procedures

    /// <inheritdoc/>
    public async Task<DashboardStatsDto> GetDashboardStatsAsync()
    {
        try
        {
            var result = await _context.Database
                .SqlQueryRaw<DashboardStatsDto>("EXEC sp_GetDashboardStats")
                .FirstOrDefaultAsync();
            
            return result ?? new DashboardStatsDto();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error executing sp_GetDashboardStats");
            // Fallback to LINQ query if stored procedure fails
            return await GetDashboardStatsFallbackAsync();
        }
    }

    private async Task<DashboardStatsDto> GetDashboardStatsFallbackAsync()
    {
        var stats = new DashboardStatsDto
        {
            TotalProducts = await _context.Products.CountAsync(),
            ActiveProducts = await _context.Products.CountAsync(p => p.IsActive),
            InactiveProducts = await _context.Products.CountAsync(p => !p.IsActive),
            OutOfStockProducts = await _context.Products.CountAsync(p => p.Stock == 0 && p.IsActive),
            LowStockProducts = await _context.Products.CountAsync(p => p.Stock > 0 && p.Stock <= 10 && p.IsActive),
            TotalCategories = await _context.Categories.CountAsync(),
            TotalOrders = await _context.Orders.CountAsync(),
            PendingOrders = await _context.Orders.CountAsync(o => o.OrderStatus == "Pending"),
            ProcessingOrders = await _context.Orders.CountAsync(o => o.OrderStatus == "Processing"),
            CompletedOrders = await _context.Orders.CountAsync(o => o.OrderStatus == "Delivered"),
            CancelledOrders = await _context.Orders.CountAsync(o => o.OrderStatus == "Cancelled"),
            TotalRevenue = await _context.Orders.Where(o => o.PaymentStatus == "Paid").SumAsync(o => o.Total),
            MonthlyRevenue = await _context.Orders
                .Where(o => o.PaymentStatus == "Paid" && o.OrderDate.Month == DateTime.UtcNow.Month && o.OrderDate.Year == DateTime.UtcNow.Year)
                .SumAsync(o => o.Total),
            TotalUsers = await _context.Users.CountAsync(),
            ActiveUsers = await _context.Users.CountAsync(u => u.IsActive)
        };
        return stats;
    }

    /// <inheritdoc/>
    public async Task<List<TopSellingProductDto>> GetTopSellingProductsAsync(int topN = 10, DateTime? startDate = null, DateTime? endDate = null)
    {
        try
        {
            var parameters = new[]
            {
                new SqlParameter("@TopN", topN),
                new SqlParameter("@StartDate", (object?)startDate ?? DBNull.Value),
                new SqlParameter("@EndDate", (object?)endDate ?? DBNull.Value)
            };

            var result = await _context.Database
                .SqlQueryRaw<TopSellingProductDto>("EXEC sp_GetTopSellingProducts @TopN, @StartDate, @EndDate", parameters)
                .ToListAsync();
            
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error executing sp_GetTopSellingProducts");
            // Fallback
            return await GetTopSellingProductsFallbackAsync(topN);
        }
    }

    private async Task<List<TopSellingProductDto>> GetTopSellingProductsFallbackAsync(int topN)
    {
        return await _context.OrderItems
            .Include(oi => oi.Product)
                .ThenInclude(p => p!.Category)
            .Include(oi => oi.Order)
            .Where(oi => oi.Order!.PaymentStatus == "Paid")
            .GroupBy(oi => new { oi.ProductId, oi.Product!.Title, oi.Product.Author, oi.Product.Price, CategoryName = oi.Product.Category!.Name })
            .Select(g => new TopSellingProductDto
            {
                ProductId = g.Key.ProductId,
                Title = g.Key.Title,
                Author = g.Key.Author,
                Price = g.Key.Price,
                CategoryName = g.Key.CategoryName,
                TotalSold = g.Sum(x => x.Quantity),
                TotalRevenue = g.Sum(x => x.Quantity * x.UnitPrice)
            })
            .OrderByDescending(x => x.TotalSold)
            .Take(topN)
            .ToListAsync();
    }

    /// <inheritdoc/>
    public async Task<List<DailyRevenueDto>> GetDailyRevenueAsync(DateTime startDate, DateTime endDate)
    {
        try
        {
            var parameters = new[]
            {
                new SqlParameter("@StartDate", startDate.Date),
                new SqlParameter("@EndDate", endDate.Date)
            };

            var result = await _context.Database
                .SqlQueryRaw<DailyRevenueDto>("EXEC sp_GetDailyRevenue @StartDate, @EndDate", parameters)
                .ToListAsync();
            
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error executing sp_GetDailyRevenue");
            return await GetDailyRevenueFallbackAsync(startDate, endDate);
        }
    }

    private async Task<List<DailyRevenueDto>> GetDailyRevenueFallbackAsync(DateTime startDate, DateTime endDate)
    {
        return await _context.Orders
            .Where(o => o.PaymentStatus == "Paid" && o.OrderDate.Date >= startDate.Date && o.OrderDate.Date <= endDate.Date)
            .GroupBy(o => o.OrderDate.Date)
            .Select(g => new DailyRevenueDto
            {
                ReportDate = g.Key,
                OrderCount = g.Count(),
                TotalRevenue = g.Sum(o => o.Total),
                AverageOrderValue = g.Average(o => o.Total)
            })
            .OrderBy(x => x.ReportDate)
            .ToListAsync();
    }

    /// <inheritdoc/>
    public async Task<List<CategoryStatisticsDto>> GetCategoryStatisticsAsync()
    {
        try
        {
            var result = await _context.Database
                .SqlQueryRaw<CategoryStatisticsDto>("EXEC sp_GetCategoryStatistics")
                .ToListAsync();
            
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error executing sp_GetCategoryStatistics");
            return await GetCategoryStatisticsFallbackAsync();
        }
    }

    private async Task<List<CategoryStatisticsDto>> GetCategoryStatisticsFallbackAsync()
    {
        // Get all order items with product and category info
        var orderItems = await _context.OrderItems
            .Include(oi => oi.Product)
                .ThenInclude(p => p!.Category)
            .Include(oi => oi.Order)
            .Where(oi => oi.Order!.PaymentStatus == "Paid" && oi.Product!.IsActive)
            .ToListAsync();

        // Group by category
        var categoryStats = orderItems
            .Where(oi => oi.Product?.Category != null)
            .GroupBy(oi => new { oi.Product!.Category!.CategoryId, oi.Product.Category.Name })
            .Select(g => new CategoryStatisticsDto
            {
                CategoryId = g.Key.CategoryId,
                CategoryName = g.Key.Name,
                ProductCount = g.Select(oi => oi.ProductId).Distinct().Count(),
                TotalSold = g.Sum(oi => oi.Quantity),
                TotalRevenue = g.Sum(oi => oi.Quantity * oi.UnitPrice)
            })
            .OrderByDescending(x => x.TotalRevenue)
            .ToList();

        // Add categories with no sales
        var categoriesWithSales = categoryStats.Select(c => c.CategoryId).ToHashSet();
        var categoriesWithoutSales = await _context.Categories
            .Where(c => !categoriesWithSales.Contains(c.CategoryId))
            .Select(c => new CategoryStatisticsDto
            {
                CategoryId = c.CategoryId,
                CategoryName = c.Name,
                ProductCount = c.Products != null ? c.Products.Count(p => p.IsActive) : 0,
                TotalSold = 0,
                TotalRevenue = 0
            })
            .ToListAsync();

        return categoryStats.Concat(categoriesWithoutSales).OrderByDescending(x => x.TotalRevenue).ToList();
    }

    /// <inheritdoc/>
    public async Task<List<TopCustomerDto>> GetTopCustomersAsync(int topN = 10)
    {
        try
        {
            var parameter = new SqlParameter("@TopN", topN);
            var result = await _context.Database
                .SqlQueryRaw<TopCustomerDto>("EXEC sp_GetTopCustomers @TopN", parameter)
                .ToListAsync();
            
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error executing sp_GetTopCustomers");
            return await GetTopCustomersFallbackAsync(topN);
        }
    }

    private async Task<List<TopCustomerDto>> GetTopCustomersFallbackAsync(int topN)
    {
        return await _context.Orders
            .Where(o => o.PaymentStatus == "Paid")
            .GroupBy(o => new { o.UserId, o.User!.Email, o.User.FullName })
            .Select(g => new TopCustomerDto
            {
                UserId = g.Key.UserId,
                Email = g.Key.Email,
                FullName = g.Key.FullName,
                OrderCount = g.Count(),
                TotalSpent = g.Sum(o => o.Total),
                LastOrderDate = g.Max(o => o.OrderDate)
            })
            .OrderByDescending(x => x.TotalSpent)
            .Take(topN)
            .ToListAsync();
    }

    /// <inheritdoc/>
    public async Task<List<LowStockProductDto>> GetLowStockProductsAsync(int threshold = 10)
    {
        try
        {
            var parameter = new SqlParameter("@Threshold", threshold);
            var result = await _context.Database
                .SqlQueryRaw<LowStockProductDto>("EXEC sp_GetLowStockProducts @Threshold", parameter)
                .ToListAsync();
            
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error executing sp_GetLowStockProducts");
            return await GetLowStockProductsFallbackAsync(threshold);
        }
    }

    private async Task<List<LowStockProductDto>> GetLowStockProductsFallbackAsync(int threshold)
    {
        return await _context.Products
            .Include(p => p.Category)
            .Where(p => p.IsActive && p.Stock <= threshold)
            .OrderBy(p => p.Stock)
            .Select(p => new LowStockProductDto
            {
                ProductId = p.ProductId,
                Title = p.Title,
                Author = p.Author,
                Price = p.Price,
                Stock = p.Stock,
                CategoryName = p.Category != null ? p.Category.Name : null
            })
            .ToListAsync();
    }

    #endregion

    #region Scalar Functions

    /// <inheritdoc/>
    public async Task<decimal> CalculateDiscountAsync(decimal originalPrice, decimal discountPercentage)
    {
        try
        {
            var result = await _context.Database
                .SqlQueryRaw<decimal>("SELECT dbo.fn_CalculateDiscount(@OriginalPrice, @DiscountPercentage) AS Value",
                    new SqlParameter("@OriginalPrice", originalPrice),
                    new SqlParameter("@DiscountPercentage", discountPercentage))
                .FirstOrDefaultAsync();
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Error executing fn_CalculateDiscount, using fallback calculation");
            return originalPrice * (discountPercentage / 100m);
        }
    }

    /// <inheritdoc/>
    public async Task<decimal> CalculateFinalPriceAsync(decimal originalPrice, decimal discountPercentage)
    {
        try
        {
            var result = await _context.Database
                .SqlQueryRaw<decimal>("SELECT dbo.fn_CalculateFinalPrice(@OriginalPrice, @DiscountPercentage) AS Value",
                    new SqlParameter("@OriginalPrice", originalPrice),
                    new SqlParameter("@DiscountPercentage", discountPercentage))
                .FirstOrDefaultAsync();
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Error executing fn_CalculateFinalPrice, using fallback calculation");
            return originalPrice - (originalPrice * discountPercentage / 100m);
        }
    }

    /// <inheritdoc/>
    public async Task<decimal> GetUserCartTotalAsync(string userId)
    {
        try
        {
            var result = await _context.Database
                .SqlQueryRaw<decimal>("SELECT dbo.fn_GetUserCartTotal(@UserId) AS Value",
                    new SqlParameter("@UserId", userId))
                .FirstOrDefaultAsync();
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Error executing fn_GetUserCartTotal, using fallback query");
            return await _context.CartItems
                .Include(c => c.Product)
                .Where(c => c.UserId == userId && c.Product!.IsActive)
                .SumAsync(c => c.Product!.Price * c.Quantity);
        }
    }

    /// <inheritdoc/>
    public async Task<int> GetUserCartCountAsync(string userId)
    {
        try
        {
            var result = await _context.Database
                .SqlQueryRaw<int>("SELECT dbo.fn_GetUserCartCount(@UserId) AS Value",
                    new SqlParameter("@UserId", userId))
                .FirstOrDefaultAsync();
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Error executing fn_GetUserCartCount, using fallback query");
            return await _context.CartItems
                .Where(c => c.UserId == userId)
                .SumAsync(c => c.Quantity);
        }
    }

    /// <inheritdoc/>
    public async Task<CartSummaryDto> GetCartSummaryAsync(string userId)
    {
        // Execute both functions in parallel for efficiency
        var totalTask = GetUserCartTotalAsync(userId);
        var countTask = GetUserCartCountAsync(userId);
        
        await Task.WhenAll(totalTask, countTask);
        
        return new CartSummaryDto
        {
            TotalAmount = await totalTask,
            ItemCount = await countTask
        };
    }

    /// <inheritdoc/>
    public async Task<decimal> GetProductAverageRatingAsync(int productId)
    {
        try
        {
            var result = await _context.Database
                .SqlQueryRaw<decimal>("SELECT dbo.fn_GetProductAverageRating(@ProductId) AS Value",
                    new SqlParameter("@ProductId", productId))
                .FirstOrDefaultAsync();
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Error executing fn_GetProductAverageRating, using fallback query");
            var reviews = await _context.Reviews.Where(r => r.ProductId == productId).ToListAsync();
            if (reviews.Count == 0) return 0;
            return (decimal)reviews.Average(r => r.Rating);
        }
    }

    /// <inheritdoc/>
    public async Task<int> GetProductReviewCountAsync(int productId)
    {
        try
        {
            var result = await _context.Database
                .SqlQueryRaw<int>("SELECT dbo.fn_GetProductReviewCount(@ProductId) AS Value",
                    new SqlParameter("@ProductId", productId))
                .FirstOrDefaultAsync();
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Error executing fn_GetProductReviewCount, using fallback query");
            return await _context.Reviews.CountAsync(r => r.ProductId == productId);
        }
    }

    /// <inheritdoc/>
    public async Task<ProductRatingDto> GetProductRatingAsync(int productId)
    {
        var avgTask = GetProductAverageRatingAsync(productId);
        var countTask = GetProductReviewCountAsync(productId);
        
        await Task.WhenAll(avgTask, countTask);
        
        return new ProductRatingDto
        {
            ProductId = productId,
            AverageRating = await avgTask,
            ReviewCount = await countTask
        };
    }

    /// <inheritdoc/>
    public async Task<decimal> CalculateTaxAsync(decimal amount)
    {
        try
        {
            var result = await _context.Database
                .SqlQueryRaw<decimal>("SELECT dbo.fn_CalculateTax(@Amount) AS Value",
                    new SqlParameter("@Amount", amount))
                .FirstOrDefaultAsync();
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Error executing fn_CalculateTax, using fallback calculation");
            return amount * 0.10m; // 10% VAT
        }
    }

    /// <inheritdoc/>
    public async Task<string> FormatVNDCurrencyAsync(decimal amount)
    {
        try
        {
            var result = await _context.Database
                .SqlQueryRaw<string>("SELECT dbo.fn_FormatVNDCurrency(@Amount) AS Value",
                    new SqlParameter("@Amount", amount))
                .FirstOrDefaultAsync();
            return result ?? $"{amount:N0}₫";
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Error executing fn_FormatVNDCurrency, using fallback format");
            return $"{amount:N0}₫";
        }
    }

    /// <inheritdoc/>
    public async Task<string> GetOrderStatusDisplayAsync(string status)
    {
        try
        {
            var result = await _context.Database
                .SqlQueryRaw<string>("SELECT dbo.fn_GetOrderStatusDisplay(@Status) AS Value",
                    new SqlParameter("@Status", status))
                .FirstOrDefaultAsync();
            return result ?? status;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Error executing fn_GetOrderStatusDisplay, using fallback mapping");
            return status switch
            {
                "Pending" => "Chờ xử lý",
                "Processing" => "Đang xử lý",
                "Shipped" => "Đang giao hàng",
                "Delivered" => "Đã giao hàng",
                "Cancelled" => "Đã hủy",
                _ => status
            };
        }
    }

    #endregion
}
