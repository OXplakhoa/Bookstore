/*
=============================================
Bookstore Database Stored Procedures
=============================================
File: 02_StoredProcedures.sql
Description: SQL Server stored procedures for business operations
Version: 1.0
=============================================
*/

USE BookstoreDb;
GO

-- =============================================
-- STORED PROCEDURE 1: sp_GetDashboardStats
-- Description: Get admin dashboard statistics
-- =============================================
IF OBJECT_ID('dbo.sp_GetDashboardStats', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetDashboardStats;
GO

CREATE PROCEDURE sp_GetDashboardStats
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        -- Product Stats
        (SELECT COUNT(*) FROM dbo.Products) AS TotalProducts,
        (SELECT COUNT(*) FROM dbo.Products WHERE IsActive = 1) AS ActiveProducts,
        (SELECT COUNT(*) FROM dbo.Products WHERE Stock < 10 AND IsActive = 1) AS LowStockProducts,
        (SELECT COUNT(*) FROM dbo.Products WHERE Stock = 0 AND IsActive = 1) AS OutOfStockProducts,
        
        -- Category Stats
        (SELECT COUNT(*) FROM dbo.Categories) AS TotalCategories,
        
        -- Order Stats
        (SELECT COUNT(*) FROM dbo.Orders) AS TotalOrders,
        (SELECT COUNT(*) FROM dbo.Orders WHERE OrderStatus = 'Pending') AS PendingOrders,
        (SELECT COUNT(*) FROM dbo.Orders WHERE OrderStatus = 'Processing') AS ProcessingOrders,
        (SELECT COUNT(*) FROM dbo.Orders WHERE OrderStatus = 'Shipped') AS ShippedOrders,
        (SELECT COUNT(*) FROM dbo.Orders WHERE OrderStatus = 'Delivered') AS DeliveredOrders,
        (SELECT COUNT(*) FROM dbo.Orders WHERE OrderStatus = 'Cancelled') AS CancelledOrders,
        
        -- Revenue Stats
        (SELECT ISNULL(SUM(Total), 0) FROM dbo.Orders WHERE PaymentStatus = 'Paid') AS TotalRevenue,
        (SELECT ISNULL(SUM(Total), 0) FROM dbo.Orders 
         WHERE PaymentStatus = 'Paid' AND CAST(OrderDate AS DATE) = CAST(GETUTCDATE() AS DATE)) AS TodayRevenue,
        (SELECT ISNULL(SUM(Total), 0) FROM dbo.Orders 
         WHERE PaymentStatus = 'Paid' AND OrderDate >= DATEADD(DAY, -7, GETUTCDATE())) AS WeekRevenue,
        (SELECT ISNULL(SUM(Total), 0) FROM dbo.Orders 
         WHERE PaymentStatus = 'Paid' AND OrderDate >= DATEADD(MONTH, -1, GETUTCDATE())) AS MonthRevenue,
        
        -- User Stats
        (SELECT COUNT(*) FROM dbo.AspNetUsers) AS TotalUsers,
        (SELECT COUNT(*) FROM dbo.AspNetUsers WHERE IsActive = 1) AS ActiveUsers,
        (SELECT COUNT(*) FROM dbo.AspNetUsers 
         WHERE CreatedAt >= DATEADD(DAY, -7, GETUTCDATE())) AS NewUsersThisWeek,
        
        -- Flash Sale Stats
        (SELECT COUNT(*) FROM dbo.FlashSales WHERE IsActive = 1 AND EndDate >= GETUTCDATE()) AS ActiveFlashSales;
END
GO

PRINT 'Stored Procedure sp_GetDashboardStats created successfully.';
GO

-- =============================================
-- STORED PROCEDURE 2: sp_GetProductsByCategory
-- Description: Get products by category with pagination
-- =============================================
IF OBJECT_ID('dbo.sp_GetProductsByCategory', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetProductsByCategory;
GO

CREATE PROCEDURE sp_GetProductsByCategory
    @CategoryId INT = NULL,
    @SearchTerm NVARCHAR(100) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 12,
    @SortBy NVARCHAR(20) = 'CreatedAt',
    @SortOrder NVARCHAR(4) = 'DESC'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    -- Get total count
    DECLARE @TotalCount INT;
    SELECT @TotalCount = COUNT(*)
    FROM dbo.Products p
    WHERE p.IsActive = 1
    AND (@CategoryId IS NULL OR p.CategoryId = @CategoryId)
    AND (@SearchTerm IS NULL OR p.Title LIKE '%' + @SearchTerm + '%' OR p.Author LIKE '%' + @SearchTerm + '%');
    
    -- Get paginated products
    SELECT 
        p.ProductId,
        p.Title,
        p.Author,
        p.Description,
        p.Price,
        p.Stock,
        p.CategoryId,
        p.IsActive,
        p.CreatedAt,
        c.Name AS CategoryName,
        (SELECT TOP 1 ImageUrl FROM dbo.ProductImages WHERE ProductId = p.ProductId AND IsMain = 1) AS MainImageUrl,
        @TotalCount AS TotalCount,
        CEILING(@TotalCount * 1.0 / @PageSize) AS TotalPages
    FROM dbo.Products p
    LEFT JOIN dbo.Categories c ON p.CategoryId = c.CategoryId
    WHERE p.IsActive = 1
    AND (@CategoryId IS NULL OR p.CategoryId = @CategoryId)
    AND (@SearchTerm IS NULL OR p.Title LIKE '%' + @SearchTerm + '%' OR p.Author LIKE '%' + @SearchTerm + '%')
    ORDER BY 
        CASE WHEN @SortBy = 'Price' AND @SortOrder = 'ASC' THEN p.Price END ASC,
        CASE WHEN @SortBy = 'Price' AND @SortOrder = 'DESC' THEN p.Price END DESC,
        CASE WHEN @SortBy = 'Title' AND @SortOrder = 'ASC' THEN p.Title END ASC,
        CASE WHEN @SortBy = 'Title' AND @SortOrder = 'DESC' THEN p.Title END DESC,
        CASE WHEN @SortBy = 'CreatedAt' AND @SortOrder = 'ASC' THEN p.CreatedAt END ASC,
        CASE WHEN @SortBy = 'CreatedAt' AND @SortOrder = 'DESC' THEN p.CreatedAt END DESC
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
END
GO

PRINT 'Stored Procedure sp_GetProductsByCategory created successfully.';
GO

-- =============================================
-- STORED PROCEDURE 3: sp_GetOrderDetails
-- Description: Get complete order details with items
-- =============================================
IF OBJECT_ID('dbo.sp_GetOrderDetails', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetOrderDetails;
GO

CREATE PROCEDURE sp_GetOrderDetails
    @OrderId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get order header
    SELECT 
        o.OrderId,
        o.OrderNumber,
        o.OrderDate,
        o.Total,
        o.OrderStatus,
        o.PaymentMethod,
        o.PaymentStatus,
        o.ShippingName,
        o.ShippingPhone,
        o.ShippingEmail,
        o.ShippingAddress,
        o.TrackingNumber,
        o.Notes,
        u.Email AS CustomerEmail,
        u.FullName AS CustomerName
    FROM dbo.Orders o
    LEFT JOIN dbo.AspNetUsers u ON o.UserId = u.Id
    WHERE o.OrderId = @OrderId;
    
    -- Get order items
    SELECT 
        oi.OrderItemId,
        oi.ProductId,
        oi.Quantity,
        oi.UnitPrice,
        oi.WasOnFlashSale,
        oi.FlashSaleDiscount,
        p.Title AS ProductTitle,
        p.Author AS ProductAuthor,
        (SELECT TOP 1 ImageUrl FROM dbo.ProductImages WHERE ProductId = p.ProductId AND IsMain = 1) AS ProductImageUrl,
        (oi.Quantity * oi.UnitPrice) AS Subtotal
    FROM dbo.OrderItems oi
    INNER JOIN dbo.Products p ON oi.ProductId = p.ProductId
    WHERE oi.OrderId = @OrderId;
    
    -- Get payments
    SELECT 
        PaymentId,
        PaymentMethod,
        Status,
        PaymentDate,
        Amount,
        TransactionId,
        PaymentIntentId
    FROM dbo.Payments
    WHERE OrderId = @OrderId
    ORDER BY PaymentDate DESC;
END
GO

PRINT 'Stored Procedure sp_GetOrderDetails created successfully.';
GO

-- =============================================
-- STORED PROCEDURE 4: sp_CreateOrder
-- Description: Create new order with items (transaction)
-- =============================================
IF OBJECT_ID('dbo.sp_CreateOrder', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_CreateOrder;
GO

CREATE PROCEDURE sp_CreateOrder
    @UserId NVARCHAR(450),
    @ShippingName NVARCHAR(100),
    @ShippingPhone NVARCHAR(20),
    @ShippingEmail NVARCHAR(256),
    @ShippingAddress NVARCHAR(500),
    @PaymentMethod NVARCHAR(50),
    @Notes NVARCHAR(1000) = NULL,
    @OrderId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Calculate total from cart
        DECLARE @Total DECIMAL(18, 2);
        SELECT @Total = SUM(
            CASE 
                WHEN ci.LockedPrice IS NOT NULL THEN ci.LockedPrice * ci.Quantity
                ELSE p.Price * ci.Quantity
            END
        )
        FROM dbo.CartItems ci
        INNER JOIN dbo.Products p ON ci.ProductId = p.ProductId
        WHERE ci.UserId = @UserId;
        
        IF @Total IS NULL OR @Total = 0
        BEGIN
            RAISERROR(N'Giỏ hàng trống.', 16, 1);
            RETURN;
        END
        
        -- Create order
        INSERT INTO dbo.Orders (
            UserId, OrderDate, Total, ShippingName, ShippingPhone,
            ShippingEmail, ShippingAddress, PaymentMethod, PaymentStatus,
            OrderStatus, Notes
        )
        VALUES (
            @UserId, GETUTCDATE(), @Total, @ShippingName, @ShippingPhone,
            @ShippingEmail, @ShippingAddress, @PaymentMethod,
            CASE WHEN @PaymentMethod = 'COD' THEN 'COD' ELSE 'Pending' END,
            'Pending', @Notes
        );
        
        SET @OrderId = SCOPE_IDENTITY();
        
        -- Create order items from cart
        INSERT INTO dbo.OrderItems (
            OrderId, ProductId, Quantity, UnitPrice,
            FlashSaleProductId, WasOnFlashSale, FlashSaleDiscount
        )
        SELECT 
            @OrderId,
            ci.ProductId,
            ci.Quantity,
            CASE 
                WHEN ci.LockedPrice IS NOT NULL THEN ci.LockedPrice
                ELSE p.Price
            END,
            ci.FlashSaleProductId,
            CASE WHEN ci.FlashSaleProductId IS NOT NULL THEN 1 ELSE 0 END,
            CASE 
                WHEN ci.FlashSaleProductId IS NOT NULL 
                THEN (p.Price - ci.LockedPrice) * ci.Quantity
                ELSE NULL
            END
        FROM dbo.CartItems ci
        INNER JOIN dbo.Products p ON ci.ProductId = p.ProductId
        WHERE ci.UserId = @UserId;
        
        -- Update flash sale sold counts
        UPDATE fsp
        SET fsp.SoldCount = fsp.SoldCount + ci.Quantity
        FROM dbo.FlashSaleProducts fsp
        INNER JOIN dbo.CartItems ci ON fsp.FlashSaleProductId = ci.FlashSaleProductId
        WHERE ci.UserId = @UserId AND ci.FlashSaleProductId IS NOT NULL;
        
        -- Clear cart
        DELETE FROM dbo.CartItems WHERE UserId = @UserId;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

PRINT 'Stored Procedure sp_CreateOrder created successfully.';
GO

-- =============================================
-- STORED PROCEDURE 5: sp_UpdateOrderStatus
-- Description: Update order status with validation
-- =============================================
IF OBJECT_ID('dbo.sp_UpdateOrderStatus', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_UpdateOrderStatus;
GO

CREATE PROCEDURE sp_UpdateOrderStatus
    @OrderId INT,
    @NewStatus NVARCHAR(50),
    @TrackingNumber NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Valid status transitions
    DECLARE @CurrentStatus NVARCHAR(50);
    SELECT @CurrentStatus = OrderStatus FROM dbo.Orders WHERE OrderId = @OrderId;
    
    IF @CurrentStatus IS NULL
    BEGIN
        RAISERROR(N'Không tìm thấy đơn hàng.', 16, 1);
        RETURN;
    END
    
    -- Validate status transition
    IF @NewStatus NOT IN ('Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled')
    BEGIN
        RAISERROR(N'Trạng thái đơn hàng không hợp lệ.', 16, 1);
        RETURN;
    END
    
    -- Cannot change from Delivered or Cancelled
    IF @CurrentStatus IN ('Delivered', 'Cancelled')
    BEGIN
        RAISERROR(N'Không thể thay đổi trạng thái đơn hàng đã hoàn thành hoặc đã hủy.', 16, 1);
        RETURN;
    END
    
    -- Update order
    UPDATE dbo.Orders
    SET OrderStatus = @NewStatus,
        TrackingNumber = CASE WHEN @NewStatus = 'Shipped' THEN @TrackingNumber ELSE TrackingNumber END
    WHERE OrderId = @OrderId;
    
    -- Notify customer
    DECLARE @UserId NVARCHAR(450);
    SELECT @UserId = UserId FROM dbo.Orders WHERE OrderId = @OrderId;
    
    INSERT INTO dbo.Notifications (UserId, Message, CreatedAt)
    VALUES (
        @UserId,
        N'📦 Đơn hàng #' + CAST(@OrderId AS NVARCHAR(10)) + N' đã được cập nhật sang trạng thái: ' + @NewStatus,
        GETUTCDATE()
    );
END
GO

PRINT 'Stored Procedure sp_UpdateOrderStatus created successfully.';
GO

-- =============================================
-- STORED PROCEDURE 6: sp_GetUserOrders
-- Description: Get all orders for a user with pagination
-- =============================================
IF OBJECT_ID('dbo.sp_GetUserOrders', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetUserOrders;
GO

CREATE PROCEDURE sp_GetUserOrders
    @UserId NVARCHAR(450),
    @PageNumber INT = 1,
    @PageSize INT = 10,
    @Status NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    SELECT 
        o.OrderId,
        o.OrderNumber,
        o.OrderDate,
        o.Total,
        o.OrderStatus,
        o.PaymentMethod,
        o.PaymentStatus,
        (SELECT COUNT(*) FROM dbo.OrderItems WHERE OrderId = o.OrderId) AS ItemCount,
        (SELECT TOP 1 pi.ImageUrl 
         FROM dbo.OrderItems oi 
         INNER JOIN dbo.ProductImages pi ON oi.ProductId = pi.ProductId AND pi.IsMain = 1
         WHERE oi.OrderId = o.OrderId) AS FirstProductImage
    FROM dbo.Orders o
    WHERE o.UserId = @UserId
    AND (@Status IS NULL OR o.OrderStatus = @Status)
    ORDER BY o.OrderDate DESC
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
END
GO

PRINT 'Stored Procedure sp_GetUserOrders created successfully.';
GO

-- =============================================
-- STORED PROCEDURE 7: sp_AddToCart
-- Description: Add product to user's cart with flash sale support
-- =============================================
IF OBJECT_ID('dbo.sp_AddToCart', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_AddToCart;
GO

CREATE PROCEDURE sp_AddToCart
    @UserId NVARCHAR(450),
    @ProductId INT,
    @Quantity INT,
    @FlashSaleProductId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @LockedPrice DECIMAL(18, 2) = NULL;
    DECLARE @CurrentStock INT;
    DECLARE @FlashSaleStock INT;
    
    -- Get product stock
    SELECT @CurrentStock = Stock FROM dbo.Products WHERE ProductId = @ProductId AND IsActive = 1;
    
    IF @CurrentStock IS NULL
    BEGIN
        RAISERROR(N'Sản phẩm không tồn tại hoặc đã ngừng bán.', 16, 1);
        RETURN;
    END
    
    -- Check stock availability
    DECLARE @CurrentCartQuantity INT = ISNULL((
        SELECT Quantity FROM dbo.CartItems WHERE UserId = @UserId AND ProductId = @ProductId
    ), 0);
    
    IF @CurrentCartQuantity + @Quantity > @CurrentStock
    BEGIN
        RAISERROR(N'Không đủ hàng trong kho.', 16, 1);
        RETURN;
    END
    
    -- Check flash sale if provided
    IF @FlashSaleProductId IS NOT NULL
    BEGIN
        SELECT @LockedPrice = fsp.SalePrice,
               @FlashSaleStock = CASE 
                   WHEN fsp.StockLimit IS NOT NULL 
                   THEN fsp.StockLimit - fsp.SoldCount 
                   ELSE 999999 
               END
        FROM dbo.FlashSaleProducts fsp
        INNER JOIN dbo.FlashSales fs ON fsp.FlashSaleId = fs.FlashSaleId
        WHERE fsp.FlashSaleProductId = @FlashSaleProductId
        AND fs.IsActive = 1
        AND fs.StartDate <= GETUTCDATE()
        AND fs.EndDate >= GETUTCDATE();
        
        IF @LockedPrice IS NULL
        BEGIN
            RAISERROR(N'Flash Sale không còn hiệu lực.', 16, 1);
            RETURN;
        END
        
        IF @Quantity > @FlashSaleStock
        BEGIN
            RAISERROR(N'Đã vượt quá giới hạn mua Flash Sale.', 16, 1);
            RETURN;
        END
    END
    
    -- Upsert cart item
    IF EXISTS (SELECT 1 FROM dbo.CartItems WHERE UserId = @UserId AND ProductId = @ProductId)
    BEGIN
        UPDATE dbo.CartItems
        SET Quantity = Quantity + @Quantity,
            FlashSaleProductId = ISNULL(@FlashSaleProductId, FlashSaleProductId),
            LockedPrice = ISNULL(@LockedPrice, LockedPrice)
        WHERE UserId = @UserId AND ProductId = @ProductId;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.CartItems (UserId, ProductId, Quantity, DateAdded, FlashSaleProductId, LockedPrice)
        VALUES (@UserId, @ProductId, @Quantity, GETUTCDATE(), @FlashSaleProductId, @LockedPrice);
    END
    
    -- Return cart count
    SELECT SUM(Quantity) AS CartCount FROM dbo.CartItems WHERE UserId = @UserId;
END
GO

PRINT 'Stored Procedure sp_AddToCart created successfully.';
GO

-- =============================================
-- STORED PROCEDURE 8: sp_GetActiveFlashSales
-- Description: Get all active flash sales with products
-- =============================================
IF OBJECT_ID('dbo.sp_GetActiveFlashSales', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetActiveFlashSales;
GO

CREATE PROCEDURE sp_GetActiveFlashSales
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Now DATETIME = GETUTCDATE();
    
    -- Get active flash sales
    SELECT 
        fs.FlashSaleId,
        fs.Name,
        fs.Description,
        fs.StartDate,
        fs.EndDate,
        DATEDIFF(SECOND, @Now, fs.EndDate) AS SecondsRemaining
    FROM dbo.FlashSales fs
    WHERE fs.IsActive = 1
    AND fs.StartDate <= @Now
    AND fs.EndDate >= @Now
    ORDER BY fs.EndDate;
    
    -- Get flash sale products
    SELECT 
        fsp.FlashSaleProductId,
        fsp.FlashSaleId,
        fsp.ProductId,
        fsp.OriginalPrice,
        fsp.SalePrice,
        fsp.DiscountPercentage,
        fsp.StockLimit,
        fsp.SoldCount,
        CASE 
            WHEN fsp.StockLimit IS NOT NULL 
            THEN fsp.StockLimit - fsp.SoldCount 
            ELSE NULL 
        END AS RemainingStock,
        p.Title AS ProductTitle,
        p.Author AS ProductAuthor,
        (SELECT TOP 1 ImageUrl FROM dbo.ProductImages WHERE ProductId = p.ProductId AND IsMain = 1) AS ProductImageUrl
    FROM dbo.FlashSaleProducts fsp
    INNER JOIN dbo.FlashSales fs ON fsp.FlashSaleId = fs.FlashSaleId
    INNER JOIN dbo.Products p ON fsp.ProductId = p.ProductId
    WHERE fs.IsActive = 1
    AND fs.StartDate <= @Now
    AND fs.EndDate >= @Now
    AND p.IsActive = 1
    ORDER BY fsp.DiscountPercentage DESC;
END
GO

PRINT 'Stored Procedure sp_GetActiveFlashSales created successfully.';
GO

-- =============================================
-- STORED PROCEDURE 9: sp_GetRevenueReport
-- Description: Get revenue report by date range
-- =============================================
IF OBJECT_ID('dbo.sp_GetRevenueReport', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetRevenueReport;
GO

CREATE PROCEDURE sp_GetRevenueReport
    @StartDate DATE,
    @EndDate DATE,
    @GroupBy NVARCHAR(10) = 'DAY' -- DAY, WEEK, MONTH
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @GroupBy = 'DAY'
    BEGIN
        SELECT 
            CAST(OrderDate AS DATE) AS ReportDate,
            COUNT(*) AS OrderCount,
            SUM(Total) AS TotalRevenue,
            AVG(Total) AS AverageOrderValue
        FROM dbo.Orders
        WHERE PaymentStatus = 'Paid'
        AND CAST(OrderDate AS DATE) BETWEEN @StartDate AND @EndDate
        GROUP BY CAST(OrderDate AS DATE)
        ORDER BY ReportDate;
    END
    ELSE IF @GroupBy = 'WEEK'
    BEGIN
        SELECT 
            DATEPART(YEAR, OrderDate) AS Year,
            DATEPART(WEEK, OrderDate) AS Week,
            MIN(CAST(OrderDate AS DATE)) AS WeekStart,
            COUNT(*) AS OrderCount,
            SUM(Total) AS TotalRevenue,
            AVG(Total) AS AverageOrderValue
        FROM dbo.Orders
        WHERE PaymentStatus = 'Paid'
        AND CAST(OrderDate AS DATE) BETWEEN @StartDate AND @EndDate
        GROUP BY DATEPART(YEAR, OrderDate), DATEPART(WEEK, OrderDate)
        ORDER BY Year, Week;
    END
    ELSE IF @GroupBy = 'MONTH'
    BEGIN
        SELECT 
            DATEPART(YEAR, OrderDate) AS Year,
            DATEPART(MONTH, OrderDate) AS Month,
            COUNT(*) AS OrderCount,
            SUM(Total) AS TotalRevenue,
            AVG(Total) AS AverageOrderValue
        FROM dbo.Orders
        WHERE PaymentStatus = 'Paid'
        AND CAST(OrderDate AS DATE) BETWEEN @StartDate AND @EndDate
        GROUP BY DATEPART(YEAR, OrderDate), DATEPART(MONTH, OrderDate)
        ORDER BY Year, Month;
    END
END
GO

PRINT 'Stored Procedure sp_GetRevenueReport created successfully.';
GO

-- =============================================
-- STORED PROCEDURE 10: sp_GetTopProducts
-- Description: Get top selling products
-- =============================================
IF OBJECT_ID('dbo.sp_GetTopProducts', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetTopProducts;
GO

CREATE PROCEDURE sp_GetTopProducts
    @TopN INT = 10,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT TOP (@TopN)
        p.ProductId,
        p.Title,
        p.Author,
        p.Price,
        c.Name AS CategoryName,
        (SELECT TOP 1 ImageUrl FROM dbo.ProductImages WHERE ProductId = p.ProductId AND IsMain = 1) AS MainImageUrl,
        SUM(oi.Quantity) AS TotalSold,
        SUM(oi.Quantity * oi.UnitPrice) AS TotalRevenue
    FROM dbo.Products p
    INNER JOIN dbo.OrderItems oi ON p.ProductId = oi.ProductId
    INNER JOIN dbo.Orders o ON oi.OrderId = o.OrderId
    LEFT JOIN dbo.Categories c ON p.CategoryId = c.CategoryId
    WHERE o.PaymentStatus = 'Paid'
    AND (@StartDate IS NULL OR CAST(o.OrderDate AS DATE) >= @StartDate)
    AND (@EndDate IS NULL OR CAST(o.OrderDate AS DATE) <= @EndDate)
    GROUP BY p.ProductId, p.Title, p.Author, p.Price, c.Name
    ORDER BY TotalSold DESC;
END
GO

PRINT 'Stored Procedure sp_GetTopProducts created successfully.';
GO

-- =============================================
-- STORED PROCEDURE 11: sp_GetUserStats
-- Description: Get user statistics for admin dashboard
-- =============================================
IF OBJECT_ID('dbo.sp_GetUserStats', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetUserStats;
GO

CREATE PROCEDURE sp_GetUserStats
    @Days INT = 30
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartDate DATETIME = DATEADD(DAY, -@Days, GETUTCDATE());
    
    -- New registrations by day
    SELECT 
        CAST(CreatedAt AS DATE) AS RegistrationDate,
        COUNT(*) AS NewUsers
    FROM dbo.AspNetUsers
    WHERE CreatedAt >= @StartDate
    GROUP BY CAST(CreatedAt AS DATE)
    ORDER BY RegistrationDate;
    
    -- Users by role
    SELECT 
        r.Name AS RoleName,
        COUNT(ur.UserId) AS UserCount
    FROM dbo.AspNetRoles r
    LEFT JOIN dbo.AspNetUserRoles ur ON r.Id = ur.RoleId
    GROUP BY r.Name;
    
    -- Top customers by order value
    SELECT TOP 10
        u.Id AS UserId,
        u.FullName,
        u.Email,
        COUNT(o.OrderId) AS OrderCount,
        SUM(o.Total) AS TotalSpent
    FROM dbo.AspNetUsers u
    INNER JOIN dbo.Orders o ON u.Id = o.UserId
    WHERE o.PaymentStatus = 'Paid'
    GROUP BY u.Id, u.FullName, u.Email
    ORDER BY TotalSpent DESC;
END
GO

PRINT 'Stored Procedure sp_GetUserStats created successfully.';
GO

-- =============================================
-- STORED PROCEDURE 12: sp_SearchProducts
-- Description: Full-text search for products
-- =============================================
IF OBJECT_ID('dbo.sp_SearchProducts', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_SearchProducts;
GO

CREATE PROCEDURE sp_SearchProducts
    @SearchTerm NVARCHAR(200),
    @CategoryId INT = NULL,
    @MinPrice DECIMAL(18, 2) = NULL,
    @MaxPrice DECIMAL(18, 2) = NULL,
    @InStock BIT = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 12
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
    
    SELECT 
        p.ProductId,
        p.Title,
        p.Author,
        p.Description,
        p.Price,
        p.Stock,
        p.CategoryId,
        c.Name AS CategoryName,
        (SELECT TOP 1 ImageUrl FROM dbo.ProductImages WHERE ProductId = p.ProductId AND IsMain = 1) AS MainImageUrl,
        -- Check for active flash sale
        fsp.SalePrice AS FlashSalePrice,
        fsp.DiscountPercentage
    FROM dbo.Products p
    LEFT JOIN dbo.Categories c ON p.CategoryId = c.CategoryId
    LEFT JOIN dbo.FlashSaleProducts fsp ON p.ProductId = fsp.ProductId
        AND EXISTS (
            SELECT 1 FROM dbo.FlashSales fs 
            WHERE fs.FlashSaleId = fsp.FlashSaleId 
            AND fs.IsActive = 1 
            AND fs.StartDate <= GETUTCDATE() 
            AND fs.EndDate >= GETUTCDATE()
        )
    WHERE p.IsActive = 1
    AND (p.Title LIKE '%' + @SearchTerm + '%' 
         OR p.Author LIKE '%' + @SearchTerm + '%' 
         OR p.Description LIKE '%' + @SearchTerm + '%')
    AND (@CategoryId IS NULL OR p.CategoryId = @CategoryId)
    AND (@MinPrice IS NULL OR p.Price >= @MinPrice)
    AND (@MaxPrice IS NULL OR p.Price <= @MaxPrice)
    AND (@InStock IS NULL OR (@InStock = 1 AND p.Stock > 0) OR (@InStock = 0))
    ORDER BY 
        CASE WHEN p.Title LIKE @SearchTerm + '%' THEN 0 ELSE 1 END,
        p.Title
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
END
GO

PRINT 'Stored Procedure sp_SearchProducts created successfully.';
GO

-- =============================================
-- Summary: All stored procedures created
-- =============================================
PRINT '';
PRINT '=============================================';
PRINT 'All 12 stored procedures have been created successfully!';
PRINT '=============================================';
PRINT '1.  sp_GetDashboardStats';
PRINT '2.  sp_GetProductsByCategory';
PRINT '3.  sp_GetOrderDetails';
PRINT '4.  sp_CreateOrder';
PRINT '5.  sp_UpdateOrderStatus';
PRINT '6.  sp_GetUserOrders';
PRINT '7.  sp_AddToCart';
PRINT '8.  sp_GetActiveFlashSales';
PRINT '9.  sp_GetRevenueReport';
PRINT '10. sp_GetTopProducts';
PRINT '11. sp_GetUserStats';
PRINT '12. sp_SearchProducts';
PRINT '=============================================';
GO
