// DTOs for mapping stored procedure and function results
namespace Bookstore.Models.Dtos;

public class DashboardStatsDto
{
    public int TotalProducts { get; set; }
    public int ActiveProducts { get; set; }
    public int InactiveProducts { get; set; }
    public int OutOfStockProducts { get; set; }
    public int LowStockProducts { get; set; }
    public int TotalCategories { get; set; }
    public int TotalOrders { get; set; }
    public int PendingOrders { get; set; }
    public int ProcessingOrders { get; set; }
    public int CompletedOrders { get; set; }
    public int CancelledOrders { get; set; }
    public decimal TotalRevenue { get; set; }
    public decimal MonthlyRevenue { get; set; }
    public int TotalUsers { get; set; }
    public int ActiveUsers { get; set; }
}

public class SearchProductResultDto
{
    public int ProductId { get; set; }
    public string? Title { get; set; }
    public string? Author { get; set; }
    public string? Description { get; set; }
    public decimal Price { get; set; }
    public int Stock { get; set; }
    public DateTime CreatedAt { get; set; }
    public string? CategoryName { get; set; }
    public int TotalCount { get; set; }
    public int TotalPages { get; set; }
}

public class TopSellingProductDto
{
    public int ProductId { get; set; }
    public string? Title { get; set; }
    public string? Author { get; set; }
    public decimal Price { get; set; }
    public string? CategoryName { get; set; }
    public int TotalSold { get; set; }
    public decimal TotalRevenue { get; set; }
}

public class DailyRevenueDto
{
    public DateTime ReportDate { get; set; }
    public int OrderCount { get; set; }
    public decimal TotalRevenue { get; set; }
    public decimal AverageOrderValue { get; set; }
}

public class CategoryStatisticsDto
{
    public int CategoryId { get; set; }
    public string? CategoryName { get; set; }
    public int ProductCount { get; set; }
    public int TotalSold { get; set; }
    public decimal TotalRevenue { get; set; }
}

public class TopCustomerDto
{
    public string? UserId { get; set; }
    public string? Email { get; set; }
    public string? FullName { get; set; }
    public int OrderCount { get; set; }
    public decimal TotalSpent { get; set; }
    public DateTime LastOrderDate { get; set; }
}

public class LowStockProductDto
{
    public int ProductId { get; set; }
    public string? Title { get; set; }
    public string? Author { get; set; }
    public decimal Price { get; set; }
    public int Stock { get; set; }
    public string? CategoryName { get; set; }
}

public class CartSummaryDto
{
    public decimal TotalAmount { get; set; }
    public int ItemCount { get; set; }
}

public class ProductRatingDto
{
    public int ProductId { get; set; }
    public decimal AverageRating { get; set; }
    public int ReviewCount { get; set; }
}
