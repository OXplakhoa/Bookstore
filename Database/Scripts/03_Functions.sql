/*
=============================================
Bookstore Database Functions
=============================================
File: 03_Functions.sql
Description: SQL Server scalar and table-valued functions
Version: 1.0
=============================================
*/

USE BookstoreDb;
GO

-- =============================================
-- FUNCTION 1: fn_GetEffectivePrice
-- Description: Get effective price (flash sale or regular)
-- =============================================
IF OBJECT_ID('dbo.fn_GetEffectivePrice', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_GetEffectivePrice;
GO

CREATE FUNCTION fn_GetEffectivePrice
(
    @ProductId INT
)
RETURNS DECIMAL(18, 2)
AS
BEGIN
    DECLARE @EffectivePrice DECIMAL(18, 2);
    DECLARE @Now DATETIME = GETUTCDATE();
    
    -- Check for active flash sale first
    SELECT TOP 1 @EffectivePrice = fsp.SalePrice
    FROM dbo.FlashSaleProducts fsp
    INNER JOIN dbo.FlashSales fs ON fsp.FlashSaleId = fs.FlashSaleId
    WHERE fsp.ProductId = @ProductId
    AND fs.IsActive = 1
    AND fs.StartDate <= @Now
    AND fs.EndDate >= @Now
    ORDER BY fsp.DiscountPercentage DESC;
    
    -- If no flash sale, get regular price
    IF @EffectivePrice IS NULL
    BEGIN
        SELECT @EffectivePrice = Price
        FROM dbo.Products
        WHERE ProductId = @ProductId;
    END
    
    RETURN @EffectivePrice;
END
GO

PRINT 'Function fn_GetEffectivePrice created successfully.';
GO

-- =============================================
-- FUNCTION 2: fn_IsProductOnFlashSale
-- Description: Check if product is currently on flash sale
-- =============================================
IF OBJECT_ID('dbo.fn_IsProductOnFlashSale', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_IsProductOnFlashSale;
GO

CREATE FUNCTION fn_IsProductOnFlashSale
(
    @ProductId INT
)
RETURNS BIT
AS
BEGIN
    DECLARE @IsOnSale BIT = 0;
    DECLARE @Now DATETIME = GETUTCDATE();
    
    IF EXISTS (
        SELECT 1
        FROM dbo.FlashSaleProducts fsp
        INNER JOIN dbo.FlashSales fs ON fsp.FlashSaleId = fs.FlashSaleId
        WHERE fsp.ProductId = @ProductId
        AND fs.IsActive = 1
        AND fs.StartDate <= @Now
        AND fs.EndDate >= @Now
    )
    BEGIN
        SET @IsOnSale = 1;
    END
    
    RETURN @IsOnSale;
END
GO

PRINT 'Function fn_IsProductOnFlashSale created successfully.';
GO

-- =============================================
-- FUNCTION 3: fn_GetDiscountPercentage
-- Description: Get current discount percentage for a product
-- =============================================
IF OBJECT_ID('dbo.fn_GetDiscountPercentage', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_GetDiscountPercentage;
GO

CREATE FUNCTION fn_GetDiscountPercentage
(
    @ProductId INT
)
RETURNS DECIMAL(5, 2)
AS
BEGIN
    DECLARE @DiscountPercentage DECIMAL(5, 2) = 0;
    DECLARE @Now DATETIME = GETUTCDATE();
    
    SELECT TOP 1 @DiscountPercentage = fsp.DiscountPercentage
    FROM dbo.FlashSaleProducts fsp
    INNER JOIN dbo.FlashSales fs ON fsp.FlashSaleId = fs.FlashSaleId
    WHERE fsp.ProductId = @ProductId
    AND fs.IsActive = 1
    AND fs.StartDate <= @Now
    AND fs.EndDate >= @Now
    ORDER BY fsp.DiscountPercentage DESC;
    
    RETURN ISNULL(@DiscountPercentage, 0);
END
GO

PRINT 'Function fn_GetDiscountPercentage created successfully.';
GO

-- =============================================
-- FUNCTION 4: fn_GetUserCartTotal
-- Description: Calculate user's cart total
-- =============================================
IF OBJECT_ID('dbo.fn_GetUserCartTotal', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_GetUserCartTotal;
GO

CREATE FUNCTION fn_GetUserCartTotal
(
    @UserId NVARCHAR(450)
)
RETURNS DECIMAL(18, 2)
AS
BEGIN
    DECLARE @Total DECIMAL(18, 2);
    
    SELECT @Total = SUM(
        CASE 
            WHEN ci.LockedPrice IS NOT NULL THEN ci.LockedPrice * ci.Quantity
            ELSE dbo.fn_GetEffectivePrice(ci.ProductId) * ci.Quantity
        END
    )
    FROM dbo.CartItems ci
    WHERE ci.UserId = @UserId;
    
    RETURN ISNULL(@Total, 0);
END
GO

PRINT 'Function fn_GetUserCartTotal created successfully.';
GO

-- =============================================
-- FUNCTION 5: fn_GetUserCartCount
-- Description: Get total items in user's cart
-- =============================================
IF OBJECT_ID('dbo.fn_GetUserCartCount', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_GetUserCartCount;
GO

CREATE FUNCTION fn_GetUserCartCount
(
    @UserId NVARCHAR(450)
)
RETURNS INT
AS
BEGIN
    DECLARE @Count INT;
    
    SELECT @Count = SUM(Quantity)
    FROM dbo.CartItems
    WHERE UserId = @UserId;
    
    RETURN ISNULL(@Count, 0);
END
GO

PRINT 'Function fn_GetUserCartCount created successfully.';
GO

-- =============================================
-- FUNCTION 6: fn_GetProductAverageRating
-- Description: Get average rating for a product
-- =============================================
IF OBJECT_ID('dbo.fn_GetProductAverageRating', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_GetProductAverageRating;
GO

CREATE FUNCTION fn_GetProductAverageRating
(
    @ProductId INT
)
RETURNS DECIMAL(3, 2)
AS
BEGIN
    DECLARE @AvgRating DECIMAL(3, 2);
    
    SELECT @AvgRating = AVG(CAST(Rating AS DECIMAL(3, 2)))
    FROM dbo.Reviews
    WHERE ProductId = @ProductId;
    
    RETURN ISNULL(@AvgRating, 0);
END
GO

PRINT 'Function fn_GetProductAverageRating created successfully.';
GO

-- =============================================
-- FUNCTION 7: fn_GetProductReviewCount
-- Description: Get review count for a product
-- =============================================
IF OBJECT_ID('dbo.fn_GetProductReviewCount', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_GetProductReviewCount;
GO

CREATE FUNCTION fn_GetProductReviewCount
(
    @ProductId INT
)
RETURNS INT
AS
BEGIN
    DECLARE @Count INT;
    
    SELECT @Count = COUNT(*)
    FROM dbo.Reviews
    WHERE ProductId = @ProductId;
    
    RETURN ISNULL(@Count, 0);
END
GO

PRINT 'Function fn_GetProductReviewCount created successfully.';
GO

-- =============================================
-- FUNCTION 8: fn_FormatVNDCurrency
-- Description: Format decimal as Vietnamese Dong currency
-- =============================================
IF OBJECT_ID('dbo.fn_FormatVNDCurrency', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_FormatVNDCurrency;
GO

CREATE FUNCTION fn_FormatVNDCurrency
(
    @Amount DECIMAL(18, 2)
)
RETURNS NVARCHAR(50)
AS
BEGIN
    RETURN FORMAT(@Amount, 'N0') + N'₫';
END
GO

PRINT 'Function fn_FormatVNDCurrency created successfully.';
GO

-- =============================================
-- FUNCTION 9: fn_GetOrderStatusDisplay
-- Description: Get localized order status display text
-- =============================================
IF OBJECT_ID('dbo.fn_GetOrderStatusDisplay', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_GetOrderStatusDisplay;
GO

CREATE FUNCTION fn_GetOrderStatusDisplay
(
    @Status NVARCHAR(50)
)
RETURNS NVARCHAR(100)
AS
BEGIN
    RETURN CASE @Status
        WHEN 'Pending' THEN N'Chờ xử lý'
        WHEN 'Processing' THEN N'Đang xử lý'
        WHEN 'Shipped' THEN N'Đang giao hàng'
        WHEN 'Delivered' THEN N'Đã giao hàng'
        WHEN 'Cancelled' THEN N'Đã hủy'
        ELSE @Status
    END;
END
GO

PRINT 'Function fn_GetOrderStatusDisplay created successfully.';
GO

-- =============================================
-- FUNCTION 10: fn_GetPaymentStatusDisplay
-- Description: Get localized payment status display text
-- =============================================
IF OBJECT_ID('dbo.fn_GetPaymentStatusDisplay', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_GetPaymentStatusDisplay;
GO

CREATE FUNCTION fn_GetPaymentStatusDisplay
(
    @Status NVARCHAR(50)
)
RETURNS NVARCHAR(100)
AS
BEGIN
    RETURN CASE @Status
        WHEN 'Pending' THEN N'Chờ thanh toán'
        WHEN 'Paid' THEN N'Đã thanh toán'
        WHEN 'Failed' THEN N'Thanh toán thất bại'
        WHEN 'Refunded' THEN N'Đã hoàn tiền'
        WHEN 'COD' THEN N'Thanh toán khi nhận hàng'
        ELSE @Status
    END;
END
GO

PRINT 'Function fn_GetPaymentStatusDisplay created successfully.';
GO

-- =============================================
-- TABLE-VALUED FUNCTION 11: fn_GetTopSellingProducts
-- Description: Get top selling products as table
-- =============================================
IF OBJECT_ID('dbo.fn_GetTopSellingProducts', 'IF') IS NOT NULL
    DROP FUNCTION dbo.fn_GetTopSellingProducts;
GO

CREATE FUNCTION fn_GetTopSellingProducts
(
    @TopN INT,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
)
RETURNS TABLE
AS
RETURN
(
    SELECT TOP (@TopN)
        p.ProductId,
        p.Title,
        p.Author,
        p.Price,
        p.Stock,
        c.Name AS CategoryName,
        SUM(oi.Quantity) AS TotalSold,
        SUM(oi.Quantity * oi.UnitPrice) AS TotalRevenue
    FROM dbo.Products p
    INNER JOIN dbo.OrderItems oi ON p.ProductId = oi.ProductId
    INNER JOIN dbo.Orders o ON oi.OrderId = o.OrderId
    LEFT JOIN dbo.Categories c ON p.CategoryId = c.CategoryId
    WHERE o.PaymentStatus = 'Paid'
    AND (@StartDate IS NULL OR CAST(o.OrderDate AS DATE) >= @StartDate)
    AND (@EndDate IS NULL OR CAST(o.OrderDate AS DATE) <= @EndDate)
    GROUP BY p.ProductId, p.Title, p.Author, p.Price, p.Stock, c.Name
    ORDER BY TotalSold DESC
);
GO

PRINT 'Table-Valued Function fn_GetTopSellingProducts created successfully.';
GO

-- =============================================
-- TABLE-VALUED FUNCTION 12: fn_GetProductsInCategory
-- Description: Get all active products in a category
-- =============================================
IF OBJECT_ID('dbo.fn_GetProductsInCategory', 'IF') IS NOT NULL
    DROP FUNCTION dbo.fn_GetProductsInCategory;
GO

CREATE FUNCTION fn_GetProductsInCategory
(
    @CategoryId INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        p.ProductId,
        p.Title,
        p.Author,
        p.Description,
        p.Price,
        dbo.fn_GetEffectivePrice(p.ProductId) AS EffectivePrice,
        dbo.fn_IsProductOnFlashSale(p.ProductId) AS IsOnFlashSale,
        dbo.fn_GetDiscountPercentage(p.ProductId) AS DiscountPercentage,
        p.Stock,
        p.CreatedAt,
        dbo.fn_GetProductAverageRating(p.ProductId) AS AverageRating,
        dbo.fn_GetProductReviewCount(p.ProductId) AS ReviewCount
    FROM dbo.Products p
    WHERE p.CategoryId = @CategoryId
    AND p.IsActive = 1
);
GO

PRINT 'Table-Valued Function fn_GetProductsInCategory created successfully.';
GO

-- =============================================
-- TABLE-VALUED FUNCTION 13: fn_GetUserFavorites
-- Description: Get user's favorite products
-- =============================================
IF OBJECT_ID('dbo.fn_GetUserFavorites', 'IF') IS NOT NULL
    DROP FUNCTION dbo.fn_GetUserFavorites;
GO

CREATE FUNCTION fn_GetUserFavorites
(
    @UserId NVARCHAR(450)
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        p.ProductId,
        p.Title,
        p.Author,
        p.Price,
        dbo.fn_GetEffectivePrice(p.ProductId) AS EffectivePrice,
        dbo.fn_IsProductOnFlashSale(p.ProductId) AS IsOnFlashSale,
        p.Stock,
        c.Name AS CategoryName
    FROM dbo.FavoriteProducts fp
    INNER JOIN dbo.Products p ON fp.ProductId = p.ProductId
    LEFT JOIN dbo.Categories c ON p.CategoryId = c.CategoryId
    WHERE fp.ApplicationUserId = @UserId
    AND p.IsActive = 1
);
GO

PRINT 'Table-Valued Function fn_GetUserFavorites created successfully.';
GO

-- =============================================
-- TABLE-VALUED FUNCTION 14: fn_GetRecentlyViewedProducts
-- Description: Get user's recently viewed products
-- =============================================
IF OBJECT_ID('dbo.fn_GetRecentlyViewedProducts', 'IF') IS NOT NULL
    DROP FUNCTION dbo.fn_GetRecentlyViewedProducts;
GO

CREATE FUNCTION fn_GetRecentlyViewedProducts
(
    @UserId NVARCHAR(450),
    @TopN INT = 10
)
RETURNS TABLE
AS
RETURN
(
    SELECT TOP (@TopN)
        p.ProductId,
        p.Title,
        p.Author,
        p.Price,
        dbo.fn_GetEffectivePrice(p.ProductId) AS EffectivePrice,
        dbo.fn_IsProductOnFlashSale(p.ProductId) AS IsOnFlashSale,
        p.Stock,
        c.Name AS CategoryName,
        rvp.ViewedAt
    FROM dbo.RecentlyViewedProducts rvp
    INNER JOIN dbo.Products p ON rvp.ProductId = p.ProductId
    LEFT JOIN dbo.Categories c ON p.CategoryId = c.CategoryId
    WHERE rvp.ApplicationUserId = @UserId
    AND p.IsActive = 1
    ORDER BY rvp.ViewedAt DESC
);
GO

PRINT 'Table-Valued Function fn_GetRecentlyViewedProducts created successfully.';
GO

-- =============================================
-- TABLE-VALUED FUNCTION 15: fn_GetFlashSaleProducts
-- Description: Get products currently on flash sale
-- =============================================
IF OBJECT_ID('dbo.fn_GetFlashSaleProducts', 'IF') IS NOT NULL
    DROP FUNCTION dbo.fn_GetFlashSaleProducts;
GO

CREATE FUNCTION fn_GetFlashSaleProducts()
RETURNS TABLE
AS
RETURN
(
    SELECT 
        fsp.FlashSaleProductId,
        fsp.FlashSaleId,
        fs.Name AS FlashSaleName,
        fs.EndDate AS FlashSaleEndDate,
        p.ProductId,
        p.Title,
        p.Author,
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
        p.Stock AS ProductStock,
        c.Name AS CategoryName,
        DATEDIFF(SECOND, GETUTCDATE(), fs.EndDate) AS SecondsRemaining
    FROM dbo.FlashSaleProducts fsp
    INNER JOIN dbo.FlashSales fs ON fsp.FlashSaleId = fs.FlashSaleId
    INNER JOIN dbo.Products p ON fsp.ProductId = p.ProductId
    LEFT JOIN dbo.Categories c ON p.CategoryId = c.CategoryId
    WHERE fs.IsActive = 1
    AND fs.StartDate <= GETUTCDATE()
    AND fs.EndDate >= GETUTCDATE()
    AND p.IsActive = 1
);
GO

PRINT 'Table-Valued Function fn_GetFlashSaleProducts created successfully.';
GO

-- =============================================
-- Summary: All functions created
-- =============================================
PRINT '';
PRINT '=============================================';
PRINT 'All 15 functions have been created successfully!';
PRINT '=============================================';
PRINT 'Scalar Functions:';
PRINT '1.  fn_GetEffectivePrice';
PRINT '2.  fn_IsProductOnFlashSale';
PRINT '3.  fn_GetDiscountPercentage';
PRINT '4.  fn_GetUserCartTotal';
PRINT '5.  fn_GetUserCartCount';
PRINT '6.  fn_GetProductAverageRating';
PRINT '7.  fn_GetProductReviewCount';
PRINT '8.  fn_FormatVNDCurrency';
PRINT '9.  fn_GetOrderStatusDisplay';
PRINT '10. fn_GetPaymentStatusDisplay';
PRINT '';
PRINT 'Table-Valued Functions:';
PRINT '11. fn_GetTopSellingProducts';
PRINT '12. fn_GetProductsInCategory';
PRINT '13. fn_GetUserFavorites';
PRINT '14. fn_GetRecentlyViewedProducts';
PRINT '15. fn_GetFlashSaleProducts';
PRINT '=============================================';
GO
