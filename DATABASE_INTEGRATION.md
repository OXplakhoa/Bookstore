# Database Stored Procedures & Functions Integration

## Tổng quan

Dự án này đã được cập nhật để tích hợp các Stored Procedures và Functions từ SQL Server vào ứng dụng ASP.NET Core. Điều này minh họa việc sử dụng các đối tượng database nâng cao trong một dự án thực tế.

## Các file đã tạo/sửa đổi

### 1. Models/Dtos/DatabaseDtos.cs (MỚI)
Chứa các DTO (Data Transfer Objects) để mapping kết quả từ Stored Procedures và Functions:
- `DashboardStatsDto` - Thống kê tổng quan dashboard
- `SearchProductResultDto` - Kết quả tìm kiếm sản phẩm
- `TopSellingProductDto` - Top sản phẩm bán chạy
- `DailyRevenueDto` - Doanh thu theo ngày
- `CategoryStatisticsDto` - Thống kê theo danh mục
- `TopCustomerDto` - Khách hàng VIP
- `LowStockProductDto` - Sản phẩm sắp hết hàng
- `CartSummaryDto` - Tổng hợp giỏ hàng
- `ProductRatingDto` - Đánh giá sản phẩm

### 2. Services/DatabaseService.cs (MỚI)
Service layer để gọi các Stored Procedures và Functions:

**Stored Procedures được sử dụng:**
- `sp_GetDashboardStats` - Lấy thống kê dashboard
- `sp_GetTopSellingProducts` - Top sản phẩm bán chạy
- `sp_GetDailyRevenue` - Doanh thu theo ngày
- `sp_GetCategoryStatistics` - Thống kê danh mục
- `sp_GetTopCustomers` - Top khách hàng VIP
- `sp_GetLowStockProducts` - Sản phẩm sắp hết hàng

**Scalar Functions được sử dụng:**
- `fn_CalculateDiscount` - Tính tiền giảm giá
- `fn_CalculateFinalPrice` - Tính giá sau giảm
- `fn_GetUserCartTotal` - Tổng tiền giỏ hàng
- `fn_GetUserCartCount` - Đếm số sản phẩm trong giỏ
- `fn_GetProductAverageRating` - Điểm đánh giá TB
- `fn_GetProductReviewCount` - Đếm số đánh giá
- `fn_CalculateTax` - Tính thuế VAT
- `fn_FormatVNDCurrency` - Định dạng tiền VND
- `fn_GetOrderStatusDisplay` - Trạng thái đơn hàng tiếng Việt

### 3. Areas/Admin/Controllers/HomeController.cs (SỬA ĐỔI)
- Cập nhật để sử dụng `IDatabaseService` thay vì LINQ queries
- Sử dụng `sp_GetDashboardStats` cho thống kê dashboard
- Thêm API endpoints: `GetDashboardStats()`, `GetLowStockAlerts()`

### 4. Areas/Admin/Controllers/ReportsController.cs (MỚI)
Controller mới cho tính năng báo cáo:
- `Index()` - Trang báo cáo tổng quan
- `Revenue()` - Báo cáo doanh thu (sp_GetDailyRevenue)
- `TopProducts()` - Top sản phẩm bán chạy (sp_GetTopSellingProducts)
- `Categories()` - Thống kê danh mục (sp_GetCategoryStatistics)
- `TopCustomers()` - Khách hàng VIP (sp_GetTopCustomers)
- `LowStock()` - Cảnh báo hàng sắp hết (sp_GetLowStockProducts)

### 5. Controllers/CartController.cs (SỬA ĐỔI)
- Thêm `IDatabaseService` dependency
- `GetCartCount()` - Sử dụng `fn_GetUserCartCount`
- `GetCartSummary()` - Sử dụng `fn_GetUserCartTotal` + `fn_GetUserCartCount`

### 6. Views đã tạo mới
- `Areas/Admin/Views/Home/Index.cshtml` - Dashboard cải tiến
- `Areas/Admin/Views/Reports/Index.cshtml` - Trang báo cáo tổng quan
- `Areas/Admin/Views/Reports/LowStock.cshtml` - Danh sách sản phẩm sắp hết
- `Areas/Admin/Views/Reports/TopProducts.cshtml` - Top sản phẩm bán chạy

### 7. Program.cs (SỬA ĐỔI)
Đăng ký `IDatabaseService` trong Dependency Injection:
```csharp
builder.Services.AddScoped<IDatabaseService, DatabaseService>();
```

## Cách chạy các SQL Scripts

Trước khi chạy ứng dụng, cần thực thi các SQL scripts trong SQL Server Management Studio (SSMS) hoặc Azure Data Studio:

```sql
-- 1. Chạy script tạo Functions
:r F:\CODE\NET\Bookstore\Database\Scripts\Functions.sql

-- 2. Chạy script tạo Stored Procedures
:r F:\CODE\NET\Bookstore\Database\Scripts\StoreProcedures.sql

-- 3. Chạy script tạo Triggers (đã cấu hình trong ApplicationDbContext)
:r F:\CODE\NET\Bookstore\Database\Scripts\Triggers.sql
```

Hoặc mở từng file và chạy trong SSMS.

## Kiến trúc

```
┌─────────────────────────────────────────────────────────────┐
│                      Controllers                              │
│  (HomeController, ReportsController, CartController)          │
└─────────────────────────────┬───────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   IDatabaseService                            │
│  - GetDashboardStatsAsync()                                   │
│  - GetTopSellingProductsAsync()                               │
│  - GetUserCartTotalAsync()                                    │
│  - ... (other methods)                                        │
└─────────────────────────────┬───────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              SQL Server Database                              │
│  ┌──────────────────┐  ┌──────────────────┐                  │
│  │ Stored Procedures│  │    Functions     │                  │
│  │ - sp_GetDashboard│  │ - fn_GetCart...  │                  │
│  │ - sp_GetTop...   │  │ - fn_Calculate..│                  │
│  └──────────────────┘  └──────────────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

## Lợi ích của việc sử dụng SP/Functions

1. **Performance**: 
   - Stored Procedures được biên dịch sẵn trên server
   - Giảm network traffic (chỉ gửi tên SP + params)
   
2. **Security**:
   - Có thể cấp quyền EXECUTE trên SP thay vì SELECT trên tables
   - Ngăn chặn SQL Injection

3. **Maintainability**:
   - Logic nghiệp vụ tập trung trong database
   - Thay đổi SP không cần deploy lại ứng dụng

4. **Code Reuse**:
   - Các ứng dụng khác nhau có thể tái sử dụng SP
   - Functions có thể dùng trong các SP khác

## Fallback Pattern

Service sử dụng pattern Fallback - nếu SP/Function không tồn tại hoặc có lỗi, sẽ tự động chuyển sang LINQ query:

```csharp
public async Task<DashboardStatsDto> GetDashboardStatsAsync()
{
    try
    {
        // Thử gọi Stored Procedure
        var result = await _context.Database
            .SqlQueryRaw<DashboardStatsDto>("EXEC sp_GetDashboardStats")
            .FirstOrDefaultAsync();
        return result ?? new DashboardStatsDto();
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Error executing sp_GetDashboardStats");
        // Fallback to LINQ
        return await GetDashboardStatsFallbackAsync();
    }
}
```

## Triggers đã cấu hình

Trong `ApplicationDbContext.OnModelCreating()`:
```csharp
builder.Entity<ApplicationUser>()
    .ToTable(tb => tb.HasTrigger("tr_Users_UpdateTimestamp"));

builder.Entity<Order>()
    .ToTable(tb => tb.HasTrigger("tr_Orders_SetCreatedAt"));

builder.Entity<Product>()
    .ToTable(tb => tb.HasTrigger("tr_Products_SetCreatedAt"));

builder.Entity<Review>()
    .ToTable(tb => tb.HasTrigger("tr_Reviews_SetCreatedAt"));

builder.Entity<CartItem>()
    .ToTable(tb => tb.HasTrigger("tr_CartItems_SetAddedAt"));
```

## Testing

1. **Chạy ứng dụng**: `dotnet run`
2. **Truy cập Admin Dashboard**: https://localhost:7197/Admin
3. **Đăng nhập**: admin@bookstore.local / Admin@123
4. **Kiểm tra các trang**:
   - Dashboard: /Admin/Home
   - Reports: /Admin/Reports
   - Low Stock: /Admin/Reports/LowStock
   - Top Products: /Admin/Reports/TopProducts

## Ghi chú

- Nếu chưa chạy SQL scripts, ứng dụng vẫn hoạt động bình thường nhờ Fallback pattern
- Các warnings về nullable references đã tồn tại từ trước, không ảnh hưởng đến chức năng mới
