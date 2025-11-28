# Bookstore Database Scripts

This folder contains SQL Server scripts for the Bookstore application database enhancements.

## Script Files

| File | Description | Objects Created |
|------|-------------|-----------------|
| `00_RunAll.sql` | Master script with verification queries | - |
| `01_Triggers.sql` | Database triggers for automation and auditing | 8 triggers |
| `02_StoredProcedures.sql` | Stored procedures for business operations | 12 stored procedures |
| `03_Functions.sql` | Scalar and table-valued functions | 15 functions |
| `04_DatabaseBackup.sql` | Backup and restore procedures | 5 backup procedures |
| `05_UserRoleManagement.sql` | User roles, permissions, and security | 5 roles, 9 procedures |

## Prerequisites

- SQL Server 2016 or later
- BookstoreDb database must exist (created by EF Core migrations)
- Appropriate permissions to create triggers, procedures, functions, and roles

## Installation Order

Run scripts in the following order:

1. **01_Triggers.sql** - Creates triggers first as they enhance table behavior
2. **02_StoredProcedures.sql** - Creates stored procedures for business logic
3. **03_Functions.sql** - Creates functions (some procedures may use these)
4. **04_DatabaseBackup.sql** - Creates backup procedures
5. **05_UserRoleManagement.sql** - Creates database roles and permissions

## Quick Start

```sql
-- Connect to SQL Server and run each script
USE BookstoreDb;
GO

-- Option 1: Run individual scripts in SSMS
-- Open each .sql file and execute

-- Option 2: Use sqlcmd from command line
sqlcmd -S YOUR_SERVER -d BookstoreDb -i 01_Triggers.sql
sqlcmd -S YOUR_SERVER -d BookstoreDb -i 02_StoredProcedures.sql
sqlcmd -S YOUR_SERVER -d BookstoreDb -i 03_Functions.sql
sqlcmd -S YOUR_SERVER -d BookstoreDb -i 04_DatabaseBackup.sql
sqlcmd -S YOUR_SERVER -d BookstoreDb -i 05_UserRoleManagement.sql
```

## Objects Created

### Triggers (8)

| Trigger | Table | Description |
|---------|-------|-------------|
| tr_Products_UpdateTimestamp | Products | Auto-set CreatedAt on insert |
| tr_Orders_GenerateOrderNumber | Orders | Auto-generate order number |
| tr_Products_StockAlert | Products | Notify admin on low stock |
| tr_OrderItems_UpdateProductStock | OrderItems | Decrease stock on order |
| tr_Users_UpdateTimestamp | AspNetUsers | Update timestamp on modify |
| tr_FlashSaleProducts_ValidateDates | FlashSaleProducts | Validate flash sale dates |
| tr_Reviews_PreventDuplicate | Reviews | Prevent duplicate reviews |
| tr_Payments_UpdateOrderStatus | Payments | Update order on payment |

### Stored Procedures (12)

| Procedure | Description |
|-----------|-------------|
| sp_GetDashboardStats | Get admin dashboard statistics |
| sp_GetProductsByCategory | Get products with pagination |
| sp_GetOrderDetails | Get complete order details |
| sp_CreateOrder | Create order with items (transaction) |
| sp_UpdateOrderStatus | Update order status with validation |
| sp_GetUserOrders | Get user orders with pagination |
| sp_AddToCart | Add product to cart with flash sale support |
| sp_GetActiveFlashSales | Get active flash sales |
| sp_GetRevenueReport | Revenue report by date range |
| sp_GetTopProducts | Top selling products |
| sp_GetUserStats | User statistics for admin |
| sp_SearchProducts | Full-text product search |

### Functions (15)

#### Scalar Functions (10)

| Function | Returns | Description |
|----------|---------|-------------|
| fn_GetEffectivePrice | DECIMAL | Get price (flash sale or regular) |
| fn_IsProductOnFlashSale | BIT | Check if on flash sale |
| fn_GetDiscountPercentage | DECIMAL | Get current discount % |
| fn_GetUserCartTotal | DECIMAL | Calculate cart total |
| fn_GetUserCartCount | INT | Get cart item count |
| fn_GetProductAverageRating | DECIMAL | Get average rating |
| fn_GetProductReviewCount | INT | Get review count |
| fn_FormatVNDCurrency | NVARCHAR | Format as VND currency |
| fn_GetOrderStatusDisplay | NVARCHAR | Localized order status |
| fn_GetPaymentStatusDisplay | NVARCHAR | Localized payment status |

#### Table-Valued Functions (5)

| Function | Description |
|----------|-------------|
| fn_GetTopSellingProducts | Top selling products as table |
| fn_GetProductsInCategory | Products in a category |
| fn_GetUserFavorites | User's favorite products |
| fn_GetRecentlyViewedProducts | Recently viewed products |
| fn_GetFlashSaleProducts | Products on flash sale |

### Database Roles (5)

| Role | Description |
|------|-------------|
| BookstoreReader | Read-only access to all tables |
| BookstoreWriter | Read/Write for customer operations |
| BookstoreAdmin | Full administrative access |
| BookstoreReporter | Reporting and analytics |
| BookstoreBackupOperator | Backup operations |

### User Management Procedures (9)

| Procedure | Description |
|-----------|-------------|
| sp_AddUserToAppRole | Add user to application role |
| sp_RemoveUserFromAppRole | Remove user from role |
| sp_GetUserAppRoles | Get user's roles |
| sp_GetUsersInAppRole | Get users in a role |
| sp_CreateAppRole | Create new application role |
| sp_DeactivateUser | Deactivate user account |
| sp_ReactivateUser | Reactivate user account |
| sp_GetFailedLogins | Audit failed logins |
| sp_ResetUserLockout | Reset user lockout |

## Usage Examples

### Get Dashboard Statistics

```sql
EXEC sp_GetDashboardStats;
```

### Search Products

```sql
EXEC sp_SearchProducts 
    @SearchTerm = 'tiểu thuyết',
    @CategoryId = 1,
    @MinPrice = 50000,
    @MaxPrice = 200000,
    @InStock = 1,
    @PageNumber = 1,
    @PageSize = 12;
```

### Create Order

```sql
DECLARE @NewOrderId INT;
EXEC sp_CreateOrder 
    @UserId = 'user-guid-here',
    @ShippingName = N'Nguyễn Văn A',
    @ShippingPhone = '0123456789',
    @ShippingEmail = 'email@example.com',
    @ShippingAddress = N'123 Đường ABC, Quận 1, TP.HCM',
    @PaymentMethod = 'COD',
    @OrderId = @NewOrderId OUTPUT;
    
SELECT @NewOrderId AS CreatedOrderId;
```

### Use Functions

```sql
-- Get effective price for a product
SELECT dbo.fn_GetEffectivePrice(1) AS EffectivePrice;

-- Format currency
SELECT dbo.fn_FormatVNDCurrency(150000) AS FormattedPrice;
-- Returns: 150,000₫

-- Get products on flash sale
SELECT * FROM dbo.fn_GetFlashSaleProducts();

-- Get top 10 selling products this month
SELECT * FROM dbo.fn_GetTopSellingProducts(10, DATEADD(MONTH, -1, GETDATE()), GETDATE());
```

### Backup Database

```sql
-- Full backup
EXEC sp_BackupDatabase_Full @BackupPath = 'C:\SQLBackups\', @Compress = 1;

-- Get backup history
EXEC sp_GetBackupHistory @Days = 30;
```

### User Management

```sql
-- Add user to Admin role
EXEC sp_AddUserToAppRole @UserId = 'user-guid', @RoleName = 'Admin';

-- Get all admins
EXEC sp_GetUsersInAppRole @RoleName = 'Admin';

-- Deactivate a user
EXEC sp_DeactivateUser @UserId = 'user-guid', @Reason = N'Violation of terms';
```

## Integration with .NET 4.7.2

### Using Entity Framework 6

```csharp
// Call stored procedure
using (var context = new ApplicationDbContext())
{
    var stats = context.Database.SqlQuery<DashboardStats>("EXEC sp_GetDashboardStats").FirstOrDefault();
    
    // Call with parameters
    var products = context.Database.SqlQuery<Product>(
        "EXEC sp_SearchProducts @SearchTerm, @CategoryId, @PageNumber, @PageSize",
        new SqlParameter("@SearchTerm", searchTerm),
        new SqlParameter("@CategoryId", categoryId ?? (object)DBNull.Value),
        new SqlParameter("@PageNumber", page),
        new SqlParameter("@PageSize", pageSize)
    ).ToList();
}
```

### Using ADO.NET

```csharp
using (var connection = new SqlConnection(connectionString))
{
    using (var command = new SqlCommand("sp_GetDashboardStats", connection))
    {
        command.CommandType = CommandType.StoredProcedure;
        connection.Open();
        
        using (var reader = command.ExecuteReader())
        {
            while (reader.Read())
            {
                var totalProducts = reader.GetInt32(reader.GetOrdinal("TotalProducts"));
                var totalOrders = reader.GetInt32(reader.GetOrdinal("TotalOrders"));
                // ... read more columns
            }
        }
    }
}
```

## Security Notes

1. **Change default passwords** in `05_UserRoleManagement.sql` before running in production
2. **Review permissions** before applying to production environment
3. **Test backup procedures** in development first
4. **Update backup paths** to match your server configuration
5. **Use SQL Server Authentication** only when necessary; prefer Windows Authentication

## Maintenance

### Recommended Backup Schedule

| Backup Type | Frequency | Retention |
|-------------|-----------|-----------|
| Full | Weekly (Sunday 2AM) | 30 days |
| Differential | Daily (2AM) | 7 days |
| Transaction Log | Every 15 minutes | 3 days |

### Monitoring

Regularly check:
- Low stock alerts (Notifications table)
- Failed login attempts (`sp_GetFailedLogins`)
- Backup history (`sp_GetBackupHistory`)
- Dashboard statistics (`sp_GetDashboardStats`)

## Support

For issues:
1. Check error messages in SQL Server error log
2. Verify database exists and user has permissions
3. Run scripts individually to identify failures
4. Review the main `DOWNGRADE_GUIDE.md` for migration guidance
