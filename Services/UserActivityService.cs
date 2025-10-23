using Bookstore.Data;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;

namespace Bookstore.Services;

public interface IUserActivityService
{
    Task TrackProductViewAsync(int productId, string? userId);
    Task<IReadOnlyCollection<int>> GetRecentlyViewedProductIdsAsync(string? userId);
    Task<IReadOnlyList<Product>> GetRecentlyViewedProductsAsync(string? userId);
}

public class UserActivityService : IUserActivityService
{
    private const string RecentlyViewedCookieName = "recently_viewed_products";
    private const int MaxItems = 20;

    private readonly ApplicationDbContext _context;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public UserActivityService(ApplicationDbContext context, IHttpContextAccessor httpContextAccessor)
    {
        _context = context;
        _httpContextAccessor = httpContextAccessor;
    }

    public async Task TrackProductViewAsync(int productId, string? userId)
    {
        var httpContext = _httpContextAccessor.HttpContext;
        if (httpContext == null)
        {
            return;
        }

        if (!string.IsNullOrEmpty(userId))
        {
            await MergeAnonymousViewsAsync(userId);
            await TrackForAuthenticatedUserAsync(productId, userId);
        }
        else
        {
            TrackForAnonymousUser(productId, httpContext);
        }
    }

    public async Task<IReadOnlyCollection<int>> GetRecentlyViewedProductIdsAsync(string? userId)
    {
        if (!string.IsNullOrEmpty(userId))
        {
            return await _context.RecentlyViewedProducts
                .Where(rv => rv.ApplicationUserId == userId)
                .OrderByDescending(rv => rv.ViewedAt)
                .Select(rv => rv.ProductId)
                .Take(MaxItems)
                .ToListAsync();
        }

        return GetCookieProductIds();
    }

    public async Task<IReadOnlyList<Product>> GetRecentlyViewedProductsAsync(string? userId)
    {
        IReadOnlyList<int> productIds;

        if (!string.IsNullOrEmpty(userId))
        {
            productIds = await _context.RecentlyViewedProducts
                .Where(rv => rv.ApplicationUserId == userId)
                .OrderByDescending(rv => rv.ViewedAt)
                .Select(rv => rv.ProductId)
                .Take(MaxItems)
                .ToListAsync();
        }
        else
        {
            productIds = GetCookieProductIds();
        }

        if (productIds.Count == 0)
        {
            return Array.Empty<Product>();
        }

        var products = await _context.Products
            .Where(p => productIds.Contains(p.ProductId) && p.IsActive)
            .Include(p => p.ProductImages)
            .Include(p => p.Category)
            .AsNoTracking()
            .ToListAsync();

        var lookup = products.ToDictionary(p => p.ProductId);
        var ordered = new List<Product>(products.Count);
        foreach (var productId in productIds)
        {
            if (lookup.TryGetValue(productId, out var product))
            {
                ordered.Add(product);
            }
        }

        return ordered;
    }

    private async Task TrackForAuthenticatedUserAsync(int productId, string userId)
    {
        var now = DateTime.UtcNow;
        var items = await _context.RecentlyViewedProducts
            .Where(rv => rv.ApplicationUserId == userId)
            .ToListAsync();

        var existing = items.FirstOrDefault(rv => rv.ProductId == productId);
        if (existing != null)
        {
            existing.ViewedAt = now;
        }
        else
        {
            var entity = new RecentlyViewedProduct
            {
                ApplicationUserId = userId,
                ProductId = productId,
                ViewedAt = now
            };
            items.Add(entity);
            _context.RecentlyViewedProducts.Add(entity);
        }

        var overflow = items
            .OrderByDescending(rv => rv.ViewedAt)
            .Skip(MaxItems)
            .ToList();

        if (overflow.Count > 0)
        {
            _context.RecentlyViewedProducts.RemoveRange(overflow);
        }

        await _context.SaveChangesAsync();
    }

    private void TrackForAnonymousUser(int productId, HttpContext httpContext)
    {
        var ids = GetCookieProductIds();
        ids.Remove(productId);
        ids.Insert(0, productId);

        if (ids.Count > MaxItems)
        {
            ids = ids.Take(MaxItems).ToList();
        }

        WriteCookie(ids, httpContext);
    }

    private List<int> GetCookieProductIds()
    {
        var httpContext = _httpContextAccessor.HttpContext;
        if (httpContext == null)
        {
            return new List<int>();
        }

        if (!httpContext.Request.Cookies.TryGetValue(RecentlyViewedCookieName, out var raw) || string.IsNullOrWhiteSpace(raw))
        {
            return new List<int>();
        }

        var parts = raw.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        var ids = new List<int>(parts.Length);
        foreach (var part in parts)
        {
            if (int.TryParse(part, out var value) && !ids.Contains(value))
            {
                ids.Add(value);
            }
        }

        if (ids.Count > MaxItems)
        {
            ids = ids.Take(MaxItems).ToList();
        }

        return ids;
    }

    private void WriteCookie(IReadOnlyCollection<int> ids, HttpContext httpContext)
    {
        var cookieValue = string.Join(',', ids);
        var options = new CookieOptions
        {
            Expires = DateTimeOffset.UtcNow.AddDays(30),
            HttpOnly = true,
            IsEssential = true,
            SameSite = SameSiteMode.Lax,
            Secure = httpContext.Request.IsHttps
        };

        httpContext.Response.Cookies.Append(RecentlyViewedCookieName, cookieValue, options);
    }

    private async Task MergeAnonymousViewsAsync(string userId)
    {
        var httpContext = _httpContextAccessor.HttpContext;
        if (httpContext == null)
        {
            return;
        }

        if (!httpContext.Request.Cookies.ContainsKey(RecentlyViewedCookieName))
        {
            return;
        }

        var cookieIds = GetCookieProductIds();
        if (cookieIds.Count == 0)
        {
            httpContext.Response.Cookies.Delete(RecentlyViewedCookieName);
            return;
        }

        var existingItems = await _context.RecentlyViewedProducts
            .Where(rv => rv.ApplicationUserId == userId)
            .ToListAsync();

        var timestamp = DateTime.UtcNow;
        foreach (var productId in cookieIds)
        {
            var existing = existingItems.FirstOrDefault(rv => rv.ProductId == productId);
            if (existing != null)
            {
                existing.ViewedAt = timestamp;
            }
            else
            {
                var entity = new RecentlyViewedProduct
                {
                    ApplicationUserId = userId,
                    ProductId = productId,
                    ViewedAt = timestamp
                };
                existingItems.Add(entity);
                _context.RecentlyViewedProducts.Add(entity);
            }

            timestamp = timestamp.AddSeconds(-1);
        }

        var overflow = existingItems
            .OrderByDescending(rv => rv.ViewedAt)
            .Skip(MaxItems)
            .ToList();

        if (overflow.Count > 0)
        {
            _context.RecentlyViewedProducts.RemoveRange(overflow);
        }

        await _context.SaveChangesAsync();

        httpContext.Response.Cookies.Delete(RecentlyViewedCookieName);
    }
}