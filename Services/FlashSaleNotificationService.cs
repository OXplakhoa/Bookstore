using Bookstore.Data;
using Microsoft.AspNetCore.Identity.UI.Services;
using Microsoft.EntityFrameworkCore;

namespace Bookstore.Services;

/// <summary>
/// Service để gửi email thông báo Flash Sale cho users
/// </summary>
public class FlashSaleNotificationService : IFlashSaleNotificationService
{
    private readonly ApplicationDbContext _context;
    private readonly IEmailSender _emailSender;
    private readonly EmailTemplateService _emailTemplateService;
    private readonly ILogger<FlashSaleNotificationService> _logger;
    private readonly IConfiguration _configuration;

    public FlashSaleNotificationService(
        ApplicationDbContext context,
        IEmailSender emailSender,
        EmailTemplateService emailTemplateService,
        ILogger<FlashSaleNotificationService> logger,
        IConfiguration configuration)
    {
        _context = context;
        _emailSender = emailSender;
        _emailTemplateService = emailTemplateService;
        _logger = logger;
        _configuration = configuration;
    }

    /// <summary>
    /// Gửi email thông báo flash sale cho users có favorite products trong flash sale
    /// </summary>
    public async Task<int> SendFlashSaleNotificationsAsync(int flashSaleId)
    {
        try
        {
            // Lấy flash sale với products
            var flashSale = await _context.FlashSales
                .Include(fs => fs.FlashSaleProducts!)
                    .ThenInclude(fsp => fsp.Product!)
                        .ThenInclude(p => p.ProductImages)
                .FirstOrDefaultAsync(fs => fs.FlashSaleId == flashSaleId);

            if (flashSale == null)
            {
                _logger.LogWarning("Flash sale not found: {FlashSaleId}", flashSaleId);
                return 0;
            }

            if (!flashSale.IsActive)
            {
                _logger.LogWarning("Flash sale is not active: {FlashSaleId}", flashSaleId);
                return 0;
            }

            // Lấy danh sách ProductIds trong flash sale
            var flashSaleProductIds = flashSale.FlashSaleProducts?
                .Select(fsp => fsp.ProductId)
                .ToList() ?? new List<int>();

            if (!flashSaleProductIds.Any())
            {
                _logger.LogWarning("Flash sale has no products: {FlashSaleId}", flashSaleId);
                return 0;
            }

            // Lấy users có favorite bất kỳ product nào trong flash sale
            // Group by user để gửi 1 email tổng hợp cho mỗi user
            var usersWithFavorites = await _context.FavoriteProducts
                .Where(fp => flashSaleProductIds.Contains(fp.ProductId))
                .Include(fp => fp.ApplicationUser)
                .Include(fp => fp.Product!)
                    .ThenInclude(p => p.ProductImages)
                .GroupBy(fp => fp.ApplicationUserId)
                .Select(g => new
                {
                    UserId = g.Key,
                    User = g.First().ApplicationUser,
                    FavoriteProducts = g.Select(fp => fp.Product).ToList()
                })
                .ToListAsync();

            if (!usersWithFavorites.Any())
            {
                _logger.LogInformation("No users have favorited products in flash sale: {FlashSaleId}", flashSaleId);
                return 0;
            }

            var emailsSent = 0;
            var baseUrl = _configuration["ApplicationUrl"] ?? "http://localhost:5119";

            foreach (var userGroup in usersWithFavorites)
            {
                try
                {
                    if (userGroup.User == null || string.IsNullOrEmpty(userGroup.User.Email))
                    {
                        _logger.LogWarning("User has no email: {UserId}", userGroup.UserId);
                        continue;
                    }

                    // Chỉ lấy products có trong flash sale
                    var userFlashSaleProducts = userGroup.FavoriteProducts
                        .Where(p => flashSaleProductIds.Contains(p!.ProductId))
                        .Select(p =>
                        {
                            var flashSaleProduct = flashSale.FlashSaleProducts?
                                .FirstOrDefault(fsp => fsp.ProductId == p!.ProductId);

                            return (
                                Title: p!.Title ?? "Unknown",
                                Author: p.Author ?? "Unknown",
                                OriginalPrice: p.Price,
                                SalePrice: flashSaleProduct?.SalePrice ?? p.Price,
                                DiscountPercent: flashSaleProduct?.DiscountPercentage ?? 0,
                                ImageUrl: p.ProductImages?.FirstOrDefault()?.ImageUrl
                            );
                        })
                        .ToList();

                    if (!userFlashSaleProducts.Any())
                    // Không có sản phẩm nào để thông báo, bỏ qua để tiếp tục những user khác
                        continue;

                    // Tạo HTML email
                    var htmlBody = _emailTemplateService.GenerateFlashSaleNotificationTemplate(
                        userName: userGroup.User.FullName ?? userGroup.User.Email,
                        flashSaleName: flashSale.Name ?? "Flash Sale",
                        flashSaleDescription: flashSale.Description ?? "",
                        startDate: flashSale.StartDate,
                        endDate: flashSale.EndDate,
                        products: userFlashSaleProducts,
                        shopUrl: $"{baseUrl}/"
                    );

                    // Gửi email
                    await _emailSender.SendEmailAsync(
                        email: userGroup.User.Email,
                        subject: $"⚡ Flash Sale Alert: {flashSale.Name}",
                        htmlMessage: htmlBody
                    );

                    emailsSent++;
                    _logger.LogInformation("Sent flash sale notification to {Email}", userGroup.User.Email);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to send flash sale notification to user {UserId}", userGroup.UserId);
                }
            }

            _logger.LogInformation("Sent {EmailsSent} flash sale notifications for flash sale {FlashSaleId}", 
                emailsSent, flashSaleId);

            return emailsSent;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending flash sale notifications for flash sale {FlashSaleId}", flashSaleId);
            throw;
        }
    }

    /// <summary>
    /// Gửi email cho một user cụ thể về flash sale
    /// </summary>
    public async Task<bool> SendFlashSaleNotificationToUserAsync(string userId, int flashSaleId)
    {
        try
        {
            // Lấy user
            var user = await _context.Users.FindAsync(userId);
            if (user == null || string.IsNullOrEmpty(user.Email))
            {
                _logger.LogWarning("User not found or has no email: {UserId}", userId);
                return false;
            }

            // Lấy flash sale với products
            var flashSale = await _context.FlashSales
                .Include(fs => fs.FlashSaleProducts!)
                    .ThenInclude(fsp => fsp.Product!)
                    .ThenInclude(p => p.ProductImages)
                .FirstOrDefaultAsync(fs => fs.FlashSaleId == flashSaleId);

            if (flashSale == null || !flashSale.IsActive)
            {
                _logger.LogWarning("Flash sale not found or not active: {FlashSaleId}", flashSaleId);
                return false;
            }

            // Lấy favorite products của user có trong flash sale
            var flashSaleProductIds = flashSale.FlashSaleProducts?
                .Select(fsp => fsp.ProductId)
                .ToList() ?? new List<int>();

            var userFavoriteProducts = await _context.FavoriteProducts
                .Where(fp => fp.ApplicationUserId == userId && flashSaleProductIds.Contains(fp.ProductId))
                .Include(fp => fp.Product!)
                    .ThenInclude(p => p.ProductImages)
                .Select(fp => fp.Product)
                .ToListAsync();

            if (!userFavoriteProducts.Any())
            {
                _logger.LogInformation("User has no favorited products in flash sale: {UserId}, {FlashSaleId}", 
                    userId, flashSaleId);
                return false;
            }

            // Chuẩn bị data cho email
            var productsForEmail = userFavoriteProducts
                .Select(p =>
                {
                    var flashSaleProduct = flashSale.FlashSaleProducts?
                        .FirstOrDefault(fsp => fsp.ProductId == p!.ProductId);

                    return (
                        Title: p!.Title ?? "Unknown",
                        Author: p.Author ?? "Unknown",
                        OriginalPrice: p.Price,
                        SalePrice: flashSaleProduct?.SalePrice ?? p.Price,
                        DiscountPercent: flashSaleProduct?.DiscountPercentage ?? 0,
                        ImageUrl: p.ProductImages?.FirstOrDefault()?.ImageUrl
                    );
                })
                .ToList();

            var baseUrl = _configuration["ApplicationUrl"] ?? "http://localhost:5119";

            // Tạo HTML email
            var htmlBody = _emailTemplateService.GenerateFlashSaleNotificationTemplate(
                userName: user.FullName ?? user.Email,
                flashSaleName: flashSale.Name ?? "Flash Sale",
                flashSaleDescription: flashSale.Description ?? "",
                startDate: flashSale.StartDate,
                endDate: flashSale.EndDate,
                products: productsForEmail,
                shopUrl: $"{baseUrl}/"
            );

            // Gửi email
            await _emailSender.SendEmailAsync(
                email: user.Email,
                subject: $"⚡ Flash Sale Alert: {flashSale.Name}",
                htmlMessage: htmlBody
            );

            _logger.LogInformation("Sent flash sale notification to user {UserId} for flash sale {FlashSaleId}", 
                userId, flashSaleId);

            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending flash sale notification to user {UserId} for flash sale {FlashSaleId}", 
                userId, flashSaleId);
            return false;
        }
    }
}
