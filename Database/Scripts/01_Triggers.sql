/*
=============================================
Bookstore Database Triggers
=============================================
File: 01_Triggers.sql
Description: SQL Server triggers for data automation and auditing
Version: 1.0
=============================================
*/

USE BookstoreDb;
GO

-- =============================================
-- TRIGGER 1: tr_Products_UpdateTimestamp
-- Description: Auto-update CreatedAt when product is inserted
-- =============================================
IF OBJECT_ID('dbo.tr_Products_UpdateTimestamp', 'TR') IS NOT NULL
    DROP TRIGGER dbo.tr_Products_UpdateTimestamp;
GO

CREATE TRIGGER tr_Products_UpdateTimestamp
ON dbo.Products
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Ensure CreatedAt is set to current UTC time on insert
    UPDATE p
    SET p.CreatedAt = GETUTCDATE()
    FROM dbo.Products p
    INNER JOIN inserted i ON p.ProductId = i.ProductId
    WHERE p.CreatedAt IS NULL OR p.CreatedAt = '1900-01-01';
END
GO

PRINT 'Trigger tr_Products_UpdateTimestamp created successfully.';
GO

-- =============================================
-- TRIGGER 2: tr_Orders_GenerateOrderNumber
-- Description: Auto-generate order number when order is created
-- =============================================
IF OBJECT_ID('dbo.tr_Orders_GenerateOrderNumber', 'TR') IS NOT NULL
    DROP TRIGGER dbo.tr_Orders_GenerateOrderNumber;
GO

CREATE TRIGGER tr_Orders_GenerateOrderNumber
ON dbo.Orders
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Generate order number if not provided
    UPDATE o
    SET o.OrderNumber = 'ORD' + FORMAT(GETUTCDATE(), 'yyyyMMddHHmmss') + CAST(o.OrderId % 10000 AS VARCHAR(4))
    FROM dbo.Orders o
    INNER JOIN inserted i ON o.OrderId = i.OrderId
    WHERE o.OrderNumber IS NULL OR o.OrderNumber = '';
END
GO

PRINT 'Trigger tr_Orders_GenerateOrderNumber created successfully.';
GO

-- =============================================
-- TRIGGER 3: tr_Products_StockAlert
-- Description: Log notification when product stock falls below threshold
-- =============================================
IF OBJECT_ID('dbo.tr_Products_StockAlert', 'TR') IS NOT NULL
    DROP TRIGGER dbo.tr_Products_StockAlert;
GO

CREATE TRIGGER tr_Products_StockAlert
ON dbo.Products
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @LowStockThreshold INT = 10;
    DECLARE @AdminUserId NVARCHAR(450);
    
    -- Get first admin user ID
    SELECT TOP 1 @AdminUserId = u.Id 
    FROM dbo.AspNetUsers u
    INNER JOIN dbo.AspNetUserRoles ur ON u.Id = ur.UserId
    INNER JOIN dbo.AspNetRoles r ON ur.RoleId = r.Id
    WHERE r.Name = 'Admin';
    
    -- Insert notification for low stock products
    INSERT INTO dbo.Notifications (UserId, Message, CreatedAt)
    SELECT 
        @AdminUserId,
        N'⚠️ Cảnh báo: Sản phẩm "' + i.Title + N'" còn lại ' + CAST(i.Stock AS NVARCHAR(10)) + N' sản phẩm trong kho.',
        GETUTCDATE()
    FROM inserted i
    INNER JOIN deleted d ON i.ProductId = d.ProductId
    WHERE i.Stock < @LowStockThreshold
    AND d.Stock >= @LowStockThreshold -- Only trigger when crossing threshold
    AND @AdminUserId IS NOT NULL;
END
GO

PRINT 'Trigger tr_Products_StockAlert created successfully.';
GO

-- =============================================
-- TRIGGER 4: tr_OrderItems_UpdateProductStock
-- Description: Decrease product stock when order items are added
-- =============================================
IF OBJECT_ID('dbo.tr_OrderItems_UpdateProductStock', 'TR') IS NOT NULL
    DROP TRIGGER dbo.tr_OrderItems_UpdateProductStock;
GO

CREATE TRIGGER tr_OrderItems_UpdateProductStock
ON dbo.OrderItems
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Decrease stock for each product in the order
    UPDATE p
    SET p.Stock = p.Stock - i.Quantity
    FROM dbo.Products p
    INNER JOIN inserted i ON p.ProductId = i.ProductId;
    
    -- Log warning for out-of-stock products
    DECLARE @AdminUserId NVARCHAR(450);
    SELECT TOP 1 @AdminUserId = u.Id 
    FROM dbo.AspNetUsers u
    INNER JOIN dbo.AspNetUserRoles ur ON u.Id = ur.UserId
    INNER JOIN dbo.AspNetRoles r ON ur.RoleId = r.Id
    WHERE r.Name = 'Admin';
    
    INSERT INTO dbo.Notifications (UserId, Message, CreatedAt)
    SELECT 
        @AdminUserId,
        N'🚨 Sản phẩm "' + p.Title + N'" đã hết hàng (Stock = ' + CAST(p.Stock AS NVARCHAR(10)) + N')',
        GETUTCDATE()
    FROM dbo.Products p
    INNER JOIN inserted i ON p.ProductId = i.ProductId
    WHERE p.Stock <= 0
    AND @AdminUserId IS NOT NULL;
END
GO

PRINT 'Trigger tr_OrderItems_UpdateProductStock created successfully.';
GO

-- =============================================
-- TRIGGER 5: tr_Users_UpdateTimestamp
-- Description: Auto-update UpdatedAt when user is modified
-- =============================================
IF OBJECT_ID('dbo.tr_Users_UpdateTimestamp', 'TR') IS NOT NULL
    DROP TRIGGER dbo.tr_Users_UpdateTimestamp;
GO

CREATE TRIGGER tr_Users_UpdateTimestamp
ON dbo.AspNetUsers
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Update the UpdatedAt timestamp
    UPDATE u
    SET u.UpdatedAt = GETUTCDATE()
    FROM dbo.AspNetUsers u
    INNER JOIN inserted i ON u.Id = i.Id;
END
GO

PRINT 'Trigger tr_Users_UpdateTimestamp created successfully.';
GO

-- =============================================
-- TRIGGER 6: tr_FlashSaleProducts_ValidateDates
-- Description: Validate flash sale product dates match parent flash sale
-- =============================================
IF OBJECT_ID('dbo.tr_FlashSaleProducts_ValidateDates', 'TR') IS NOT NULL
    DROP TRIGGER dbo.tr_FlashSaleProducts_ValidateDates;
GO

CREATE TRIGGER tr_FlashSaleProducts_ValidateDates
ON dbo.FlashSaleProducts
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if flash sale is valid and active
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        INNER JOIN dbo.FlashSales fs ON i.FlashSaleId = fs.FlashSaleId
        WHERE fs.EndDate < GETUTCDATE()
    )
    BEGIN
        RAISERROR(N'Không thể thêm sản phẩm vào Flash Sale đã kết thúc.', 16, 1);
        RETURN;
    END
    
    -- Insert valid records
    INSERT INTO dbo.FlashSaleProducts (
        FlashSaleId, ProductId, OriginalPrice, SalePrice, 
        DiscountPercentage, StockLimit, SoldCount
    )
    SELECT 
        i.FlashSaleId, i.ProductId, i.OriginalPrice, i.SalePrice,
        i.DiscountPercentage, i.StockLimit, ISNULL(i.SoldCount, 0)
    FROM inserted i
    INNER JOIN dbo.FlashSales fs ON i.FlashSaleId = fs.FlashSaleId
    WHERE fs.EndDate >= GETUTCDATE();
END
GO

PRINT 'Trigger tr_FlashSaleProducts_ValidateDates created successfully.';
GO

-- =============================================
-- TRIGGER 7: tr_Reviews_PreventDuplicate
-- Description: Prevent duplicate reviews from same user on same product
-- =============================================
IF OBJECT_ID('dbo.tr_Reviews_PreventDuplicate', 'TR') IS NOT NULL
    DROP TRIGGER dbo.tr_Reviews_PreventDuplicate;
GO

CREATE TRIGGER tr_Reviews_PreventDuplicate
ON dbo.Reviews
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check for existing reviews
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        INNER JOIN dbo.Reviews r ON i.UserId = r.UserId AND i.ProductId = r.ProductId
    )
    BEGIN
        RAISERROR(N'Bạn đã đánh giá sản phẩm này rồi. Vui lòng cập nhật đánh giá hiện có.', 16, 1);
        RETURN;
    END
    
    -- Insert new reviews
    INSERT INTO dbo.Reviews (UserId, ProductId, Rating, Comment, CreatedAt)
    SELECT UserId, ProductId, Rating, Comment, ISNULL(CreatedAt, GETUTCDATE())
    FROM inserted;
END
GO

PRINT 'Trigger tr_Reviews_PreventDuplicate created successfully.';
GO

-- =============================================
-- TRIGGER 8: tr_Payments_UpdateOrderStatus
-- Description: Update order payment status when payment is recorded
-- =============================================
IF OBJECT_ID('dbo.tr_Payments_UpdateOrderStatus', 'TR') IS NOT NULL
    DROP TRIGGER dbo.tr_Payments_UpdateOrderStatus;
GO

CREATE TRIGGER tr_Payments_UpdateOrderStatus
ON dbo.Payments
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Update order payment status based on payment status
    UPDATE o
    SET o.PaymentStatus = 
        CASE i.Status
            WHEN 'Completed' THEN 'Paid'
            WHEN 'Failed' THEN 'Failed'
            WHEN 'Refunded' THEN 'Refunded'
            ELSE o.PaymentStatus
        END,
    o.OrderStatus = 
        CASE i.Status
            WHEN 'Completed' THEN 
                CASE WHEN o.OrderStatus = 'Pending' THEN 'Processing' ELSE o.OrderStatus END
            WHEN 'Failed' THEN 'Cancelled'
            ELSE o.OrderStatus
        END
    FROM dbo.Orders o
    INNER JOIN inserted i ON o.OrderId = i.OrderId
    WHERE i.Status IN ('Completed', 'Failed', 'Refunded');
END
GO

PRINT 'Trigger tr_Payments_UpdateOrderStatus created successfully.';
GO

-- =============================================
-- Summary: All triggers created
-- =============================================
PRINT '';
PRINT '=============================================';
PRINT 'All 8 triggers have been created successfully!';
PRINT '=============================================';
PRINT '1. tr_Products_UpdateTimestamp';
PRINT '2. tr_Orders_GenerateOrderNumber';
PRINT '3. tr_Products_StockAlert';
PRINT '4. tr_OrderItems_UpdateProductStock';
PRINT '5. tr_Users_UpdateTimestamp';
PRINT '6. tr_FlashSaleProducts_ValidateDates';
PRINT '7. tr_Reviews_PreventDuplicate';
PRINT '8. tr_Payments_UpdateOrderStatus';
PRINT '=============================================';
GO
