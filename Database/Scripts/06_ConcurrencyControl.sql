/*
=============================================
Bookstore Database Concurrency Control
=============================================
File: 06_ConcurrencyControl.sql
Description: SQL Server concurrency handling mechanisms including
             optimistic locking, row versioning, deadlock handling,
             and concurrent operation procedures
Version: 1.0
=============================================

CONCURRENCY STRATEGIES IMPLEMENTED:
1. Optimistic Concurrency with Row Versioning (ROWVERSION/timestamp)
2. Pessimistic Locking with Lock Hints
3. Deadlock Detection and Retry Logic
4. Atomic Operations for Inventory Management
5. Queue-based Processing for Flash Sales
=============================================
*/

USE BookstoreDb;
GO

-- =============================================
-- SECTION 1: Add RowVersion columns for Optimistic Concurrency
-- =============================================

-- Add RowVersion to Products table for optimistic concurrency
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Products') AND name = 'RowVersion')
BEGIN
    ALTER TABLE dbo.Products ADD RowVersion ROWVERSION NOT NULL;
    PRINT 'Added RowVersion column to Products table.';
END
GO

-- Add RowVersion to Orders table for optimistic concurrency
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Orders') AND name = 'RowVersion')
BEGIN
    ALTER TABLE dbo.Orders ADD RowVersion ROWVERSION NOT NULL;
    PRINT 'Added RowVersion column to Orders table.';
END
GO

-- Add RowVersion to FlashSaleProducts table for optimistic concurrency
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.FlashSaleProducts') AND name = 'RowVersion')
BEGIN
    ALTER TABLE dbo.FlashSaleProducts ADD RowVersion ROWVERSION NOT NULL;
    PRINT 'Added RowVersion column to FlashSaleProducts table.';
END
GO

-- Add RowVersion to CartItems table for optimistic concurrency
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.CartItems') AND name = 'RowVersion')
BEGIN
    ALTER TABLE dbo.CartItems ADD RowVersion ROWVERSION NOT NULL;
    PRINT 'Added RowVersion column to CartItems table.';
END
GO

PRINT 'RowVersion columns added for optimistic concurrency.';
GO

-- =============================================
-- SECTION 2: Optimistic Concurrency Update Procedures
-- =============================================

-- =============================================
-- STORED PROCEDURE: sp_UpdateProductStock_Optimistic
-- Description: Update product stock with optimistic concurrency check
-- =============================================
IF OBJECT_ID('dbo.sp_UpdateProductStock_Optimistic', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_UpdateProductStock_Optimistic;
GO

CREATE PROCEDURE sp_UpdateProductStock_Optimistic
    @ProductId INT,
    @NewStock INT,
    @ExpectedRowVersion BINARY(8),
    @Success BIT OUTPUT,
    @ErrorMessage NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    SET @Success = 0;
    SET @ErrorMessage = NULL;
    
    -- Validate stock is non-negative
    IF @NewStock < 0
    BEGIN
        SET @ErrorMessage = N'Stock cannot be negative.';
        RETURN;
    END
    
    -- Update with optimistic concurrency check
    UPDATE dbo.Products
    SET Stock = @NewStock
    WHERE ProductId = @ProductId
    AND RowVersion = @ExpectedRowVersion;
    
    IF @@ROWCOUNT = 0
    BEGIN
        -- Check if product exists
        IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductId = @ProductId)
        BEGIN
            SET @ErrorMessage = N'Product not found.';
        END
        ELSE
        BEGIN
            SET @ErrorMessage = N'Concurrency conflict: The product has been modified by another user. Please refresh and try again.';
        END
        RETURN;
    END
    
    SET @Success = 1;
END
GO

PRINT 'Stored Procedure sp_UpdateProductStock_Optimistic created successfully.';
GO

-- =============================================
-- STORED PROCEDURE: sp_UpdateOrderStatus_Optimistic
-- Description: Update order status with optimistic concurrency check
-- =============================================
IF OBJECT_ID('dbo.sp_UpdateOrderStatus_Optimistic', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_UpdateOrderStatus_Optimistic;
GO

CREATE PROCEDURE sp_UpdateOrderStatus_Optimistic
    @OrderId INT,
    @NewStatus NVARCHAR(50),
    @TrackingNumber NVARCHAR(100) = NULL,
    @ExpectedRowVersion BINARY(8),
    @Success BIT OUTPUT,
    @ErrorMessage NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    SET @Success = 0;
    SET @ErrorMessage = NULL;
    
    -- Validate status value
    IF @NewStatus NOT IN ('Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled')
    BEGIN
        SET @ErrorMessage = N'Invalid order status.';
        RETURN;
    END
    
    -- Update with optimistic concurrency check
    UPDATE dbo.Orders
    SET OrderStatus = @NewStatus,
        TrackingNumber = CASE WHEN @NewStatus = 'Shipped' THEN @TrackingNumber ELSE TrackingNumber END
    WHERE OrderId = @OrderId
    AND RowVersion = @ExpectedRowVersion;
    
    IF @@ROWCOUNT = 0
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM dbo.Orders WHERE OrderId = @OrderId)
        BEGIN
            SET @ErrorMessage = N'Order not found.';
        END
        ELSE
        BEGIN
            SET @ErrorMessage = N'Concurrency conflict: The order has been modified by another user. Please refresh and try again.';
        END
        RETURN;
    END
    
    SET @Success = 1;
END
GO

PRINT 'Stored Procedure sp_UpdateOrderStatus_Optimistic created successfully.';
GO

-- =============================================
-- SECTION 3: Atomic Stock Operations with Pessimistic Locking
-- =============================================

-- =============================================
-- STORED PROCEDURE: sp_DecrementStock_Atomic
-- Description: Atomically decrement stock with lock to prevent overselling
-- =============================================
IF OBJECT_ID('dbo.sp_DecrementStock_Atomic', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_DecrementStock_Atomic;
GO

CREATE PROCEDURE sp_DecrementStock_Atomic
    @ProductId INT,
    @Quantity INT,
    @Success BIT OUTPUT,
    @NewStock INT OUTPUT,
    @ErrorMessage NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- Ensure transaction is rolled back on error
    
    SET @Success = 0;
    SET @NewStock = NULL;
    SET @ErrorMessage = NULL;
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        DECLARE @CurrentStock INT;
        
        -- Lock the row exclusively to prevent concurrent reads/writes
        SELECT @CurrentStock = Stock
        FROM dbo.Products WITH (UPDLOCK, HOLDLOCK)
        WHERE ProductId = @ProductId AND IsActive = 1;
        
        IF @CurrentStock IS NULL
        BEGIN
            SET @ErrorMessage = N'Product not found or inactive.';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        IF @CurrentStock < @Quantity
        BEGIN
            SET @ErrorMessage = N'Insufficient stock. Available: ' + CAST(@CurrentStock AS NVARCHAR(10)) + 
                               N', Requested: ' + CAST(@Quantity AS NVARCHAR(10));
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Perform atomic decrement
        UPDATE dbo.Products
        SET Stock = Stock - @Quantity
        WHERE ProductId = @ProductId;
        
        SET @NewStock = @CurrentStock - @Quantity;
        SET @Success = 1;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @ErrorMessage = ERROR_MESSAGE();
    END CATCH
END
GO

PRINT 'Stored Procedure sp_DecrementStock_Atomic created successfully.';
GO

-- =============================================
-- STORED PROCEDURE: sp_IncrementStock_Atomic
-- Description: Atomically increment stock (for returns/cancellations)
-- =============================================
IF OBJECT_ID('dbo.sp_IncrementStock_Atomic', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_IncrementStock_Atomic;
GO

CREATE PROCEDURE sp_IncrementStock_Atomic
    @ProductId INT,
    @Quantity INT,
    @Success BIT OUTPUT,
    @NewStock INT OUTPUT,
    @ErrorMessage NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    SET @Success = 0;
    SET @NewStock = NULL;
    SET @ErrorMessage = NULL;
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Lock and update atomically
        UPDATE dbo.Products WITH (UPDLOCK)
        SET Stock = Stock + @Quantity
        WHERE ProductId = @ProductId;
        
        IF @@ROWCOUNT = 0
        BEGIN
            SET @ErrorMessage = N'Product not found.';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        SELECT @NewStock = Stock
        FROM dbo.Products
        WHERE ProductId = @ProductId;
        
        SET @Success = 1;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @ErrorMessage = ERROR_MESSAGE();
    END CATCH
END
GO

PRINT 'Stored Procedure sp_IncrementStock_Atomic created successfully.';
GO

-- =============================================
-- SECTION 4: Flash Sale Concurrent Purchase Handling
-- =============================================

-- =============================================
-- STORED PROCEDURE: sp_PurchaseFlashSaleItem_Concurrent
-- Description: Safely purchase flash sale item with concurrency control
-- =============================================
IF OBJECT_ID('dbo.sp_PurchaseFlashSaleItem_Concurrent', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_PurchaseFlashSaleItem_Concurrent;
GO

CREATE PROCEDURE sp_PurchaseFlashSaleItem_Concurrent
    @FlashSaleProductId INT,
    @UserId NVARCHAR(450),
    @Quantity INT,
    @Success BIT OUTPUT,
    @ActualPrice DECIMAL(18, 2) OUTPUT,
    @ErrorMessage NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    SET @Success = 0;
    SET @ActualPrice = NULL;
    SET @ErrorMessage = NULL;
    
    DECLARE @MaxRetries INT = 3;
    DECLARE @RetryCount INT = 0;
    DECLARE @Deadlock BIT = 0;
    
    WHILE @RetryCount < @MaxRetries
    BEGIN
        SET @RetryCount = @RetryCount + 1;
        
        BEGIN TRY
            BEGIN TRANSACTION;
            
            DECLARE @StockLimit INT;
            DECLARE @SoldCount INT;
            DECLARE @SalePrice DECIMAL(18, 2);
            DECLARE @ProductId INT;
            DECLARE @ProductStock INT;
            DECLARE @FlashSaleEndDate DATETIME;
            DECLARE @IsActive BIT;
            
            -- Lock flash sale product row
            SELECT 
                @StockLimit = fsp.StockLimit,
                @SoldCount = fsp.SoldCount,
                @SalePrice = fsp.SalePrice,
                @ProductId = fsp.ProductId,
                @FlashSaleEndDate = fs.EndDate,
                @IsActive = fs.IsActive
            FROM dbo.FlashSaleProducts fsp WITH (UPDLOCK, HOLDLOCK)
            INNER JOIN dbo.FlashSales fs ON fsp.FlashSaleId = fs.FlashSaleId
            WHERE fsp.FlashSaleProductId = @FlashSaleProductId;
            
            -- Validate flash sale is active
            IF @IsActive IS NULL OR @IsActive = 0 OR @FlashSaleEndDate < GETUTCDATE()
            BEGIN
                SET @ErrorMessage = N'Flash sale is no longer active.';
                ROLLBACK TRANSACTION;
                RETURN;
            END
            
            -- Check flash sale stock limit
            IF @StockLimit IS NOT NULL AND (@SoldCount + @Quantity) > @StockLimit
            BEGIN
                SET @ErrorMessage = N'Flash sale stock limit exceeded. Available: ' + 
                                   CAST((@StockLimit - @SoldCount) AS NVARCHAR(10));
                ROLLBACK TRANSACTION;
                RETURN;
            END
            
            -- Check product stock
            SELECT @ProductStock = Stock
            FROM dbo.Products WITH (UPDLOCK, HOLDLOCK)
            WHERE ProductId = @ProductId AND IsActive = 1;
            
            IF @ProductStock IS NULL
            BEGIN
                SET @ErrorMessage = N'Product not found or inactive.';
                ROLLBACK TRANSACTION;
                RETURN;
            END
            
            IF @ProductStock < @Quantity
            BEGIN
                SET @ErrorMessage = N'Insufficient product stock.';
                ROLLBACK TRANSACTION;
                RETURN;
            END
            
            -- Update flash sale sold count
            UPDATE dbo.FlashSaleProducts
            SET SoldCount = SoldCount + @Quantity
            WHERE FlashSaleProductId = @FlashSaleProductId;
            
            -- Update product stock
            UPDATE dbo.Products
            SET Stock = Stock - @Quantity
            WHERE ProductId = @ProductId;
            
            SET @ActualPrice = @SalePrice;
            SET @Success = 1;
            
            COMMIT TRANSACTION;
            RETURN; -- Success, exit retry loop
            
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            
            -- Check if it's a deadlock
            IF ERROR_NUMBER() = 1205
            BEGIN
                SET @Deadlock = 1;
                -- Exponential backoff: 100ms, 200ms, 400ms
                DECLARE @BackoffMs INT = POWER(2, @RetryCount - 1) * 100;
                DECLARE @BackoffStr NVARCHAR(12) = '00:00:00.' + RIGHT('000' + CAST(@BackoffMs AS NVARCHAR(3)), 3);
                WAITFOR DELAY @BackoffStr;
                CONTINUE;
            END
            ELSE
            BEGIN
                SET @ErrorMessage = ERROR_MESSAGE();
                RETURN;
            END
        END CATCH
    END
    
    -- Max retries exceeded
    IF @Deadlock = 1
        SET @ErrorMessage = N'Transaction failed due to high concurrency. Please try again.';
    ELSE
        SET @ErrorMessage = N'Transaction failed after multiple attempts.';
END
GO

PRINT 'Stored Procedure sp_PurchaseFlashSaleItem_Concurrent created successfully.';
GO

-- =============================================
-- SECTION 5: Deadlock-Resistant Order Creation
-- =============================================

-- =============================================
-- STORED PROCEDURE: sp_CreateOrder_ConcurrencySafe
-- Description: Create order with deadlock handling and retry logic
-- =============================================
IF OBJECT_ID('dbo.sp_CreateOrder_ConcurrencySafe', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_CreateOrder_ConcurrencySafe;
GO

CREATE PROCEDURE sp_CreateOrder_ConcurrencySafe
    @UserId NVARCHAR(450),
    @ShippingName NVARCHAR(100),
    @ShippingPhone NVARCHAR(20),
    @ShippingEmail NVARCHAR(256),
    @ShippingAddress NVARCHAR(500),
    @PaymentMethod NVARCHAR(50),
    @Notes NVARCHAR(1000) = NULL,
    @OrderId INT OUTPUT,
    @Success BIT OUTPUT,
    @ErrorMessage NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET DEADLOCK_PRIORITY LOW; -- Allow other transactions to win on deadlock
    
    SET @OrderId = NULL;
    SET @Success = 0;
    SET @ErrorMessage = NULL;
    
    DECLARE @MaxRetries INT = 3;
    DECLARE @RetryCount INT = 0;
    
    WHILE @RetryCount < @MaxRetries
    BEGIN
        SET @RetryCount = @RetryCount + 1;
        
        BEGIN TRY
            BEGIN TRANSACTION;
            
            -- Get cart items with locks in consistent order (by ProductId) to prevent deadlocks
            DECLARE @CartData TABLE (
                CartItemId INT,
                ProductId INT,
                Quantity INT,
                LockedPrice DECIMAL(18, 2),
                FlashSaleProductId INT,
                ProductPrice DECIMAL(18, 2),
                ProductStock INT,
                IsActive BIT
            );
            
            INSERT INTO @CartData
            SELECT 
                ci.CartItemId,
                ci.ProductId,
                ci.Quantity,
                ci.LockedPrice,
                ci.FlashSaleProductId,
                p.Price,
                p.Stock,
                p.IsActive
            FROM dbo.CartItems ci WITH (UPDLOCK, HOLDLOCK)
            INNER JOIN dbo.Products p WITH (UPDLOCK, HOLDLOCK) ON ci.ProductId = p.ProductId
            WHERE ci.UserId = @UserId
            ORDER BY ci.ProductId; -- Consistent lock order
            
            -- Validate cart is not empty
            IF NOT EXISTS (SELECT 1 FROM @CartData)
            BEGIN
                SET @ErrorMessage = N'Cart is empty.';
                ROLLBACK TRANSACTION;
                RETURN;
            END
            
            -- Validate all products are active
            IF EXISTS (SELECT 1 FROM @CartData WHERE IsActive = 0)
            BEGIN
                SET @ErrorMessage = N'One or more products are no longer available.';
                ROLLBACK TRANSACTION;
                RETURN;
            END
            
            -- Validate stock for all products
            IF EXISTS (SELECT 1 FROM @CartData WHERE Quantity > ProductStock)
            BEGIN
                SET @ErrorMessage = N'Insufficient stock for one or more products.';
                ROLLBACK TRANSACTION;
                RETURN;
            END
            
            -- Calculate total
            DECLARE @Total DECIMAL(18, 2);
            SELECT @Total = SUM(
                CASE 
                    WHEN LockedPrice IS NOT NULL THEN LockedPrice * Quantity
                    ELSE ProductPrice * Quantity
                END
            )
            FROM @CartData;
            
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
            
            -- Create order items
            INSERT INTO dbo.OrderItems (
                OrderId, ProductId, Quantity, UnitPrice,
                FlashSaleProductId, WasOnFlashSale, FlashSaleDiscount
            )
            SELECT 
                @OrderId,
                ProductId,
                Quantity,
                CASE WHEN LockedPrice IS NOT NULL THEN LockedPrice ELSE ProductPrice END,
                FlashSaleProductId,
                CASE WHEN FlashSaleProductId IS NOT NULL THEN 1 ELSE 0 END,
                CASE 
                    WHEN FlashSaleProductId IS NOT NULL 
                    THEN (ProductPrice - LockedPrice) * Quantity
                    ELSE NULL
                END
            FROM @CartData;
            
            -- Update product stock
            UPDATE p
            SET p.Stock = p.Stock - cd.Quantity
            FROM dbo.Products p
            INNER JOIN @CartData cd ON p.ProductId = cd.ProductId;
            
            -- Update flash sale sold counts
            UPDATE fsp
            SET fsp.SoldCount = fsp.SoldCount + cd.Quantity
            FROM dbo.FlashSaleProducts fsp
            INNER JOIN @CartData cd ON fsp.FlashSaleProductId = cd.FlashSaleProductId
            WHERE cd.FlashSaleProductId IS NOT NULL;
            
            -- Clear cart
            DELETE FROM dbo.CartItems WHERE UserId = @UserId;
            
            SET @Success = 1;
            COMMIT TRANSACTION;
            RETURN; -- Success, exit retry loop
            
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            
            -- Check if it's a deadlock (error 1205)
            IF ERROR_NUMBER() = 1205
            BEGIN
                -- Exponential backoff before retry: 100ms, 200ms, 400ms
                DECLARE @BackoffMs INT = POWER(2, @RetryCount - 1) * 100;
                -- Use seconds format for delays >= 1000ms
                DECLARE @BackoffSec INT = @BackoffMs / 1000;
                DECLARE @BackoffMsRemainder INT = @BackoffMs % 1000;
                DECLARE @WaitStr NVARCHAR(12) = '00:00:' + RIGHT('0' + CAST(@BackoffSec AS NVARCHAR(2)), 2) + 
                                                '.' + RIGHT('000' + CAST(@BackoffMsRemainder AS NVARCHAR(3)), 3);
                WAITFOR DELAY @WaitStr;
                CONTINUE;
            END
            ELSE
            BEGIN
                SET @ErrorMessage = ERROR_MESSAGE();
                RETURN;
            END
        END CATCH
    END
    
    -- Max retries exceeded
    SET @ErrorMessage = N'Order creation failed due to high concurrency. Please try again.';
END
GO

PRINT 'Stored Procedure sp_CreateOrder_ConcurrencySafe created successfully.';
GO

-- =============================================
-- SECTION 6: Cart Item Concurrent Updates
-- =============================================

-- =============================================
-- STORED PROCEDURE: sp_UpdateCartQuantity_Concurrent
-- Description: Update cart quantity with concurrency control
-- =============================================
IF OBJECT_ID('dbo.sp_UpdateCartQuantity_Concurrent', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_UpdateCartQuantity_Concurrent;
GO

CREATE PROCEDURE sp_UpdateCartQuantity_Concurrent
    @CartItemId INT,
    @UserId NVARCHAR(450),
    @NewQuantity INT,
    @ExpectedRowVersion BINARY(8),
    @Success BIT OUTPUT,
    @ErrorMessage NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    SET @Success = 0;
    SET @ErrorMessage = NULL;
    
    IF @NewQuantity < 0
    BEGIN
        SET @ErrorMessage = N'Quantity cannot be negative.';
        RETURN;
    END
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Get product stock with lock
        DECLARE @ProductId INT;
        DECLARE @ProductStock INT;
        
        SELECT @ProductId = ci.ProductId
        FROM dbo.CartItems ci
        WHERE ci.CartItemId = @CartItemId AND ci.UserId = @UserId;
        
        IF @ProductId IS NULL
        BEGIN
            SET @ErrorMessage = N'Cart item not found.';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        SELECT @ProductStock = Stock
        FROM dbo.Products WITH (HOLDLOCK)
        WHERE ProductId = @ProductId AND IsActive = 1;
        
        IF @ProductStock IS NULL
        BEGIN
            SET @ErrorMessage = N'Product no longer available.';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        IF @NewQuantity > @ProductStock
        BEGIN
            SET @ErrorMessage = N'Requested quantity exceeds available stock (' + CAST(@ProductStock AS NVARCHAR(10)) + N').';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Handle quantity = 0 as removal
        IF @NewQuantity = 0
        BEGIN
            DELETE FROM dbo.CartItems
            WHERE CartItemId = @CartItemId 
            AND UserId = @UserId
            AND RowVersion = @ExpectedRowVersion;
        END
        ELSE
        BEGIN
            UPDATE dbo.CartItems
            SET Quantity = @NewQuantity
            WHERE CartItemId = @CartItemId 
            AND UserId = @UserId
            AND RowVersion = @ExpectedRowVersion;
        END
        
        IF @@ROWCOUNT = 0
        BEGIN
            SET @ErrorMessage = N'Concurrency conflict: Cart item was modified. Please refresh and try again.';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        SET @Success = 1;
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @ErrorMessage = ERROR_MESSAGE();
    END CATCH
END
GO

PRINT 'Stored Procedure sp_UpdateCartQuantity_Concurrent created successfully.';
GO

-- =============================================
-- SECTION 7: Utility Procedures for Concurrency
-- =============================================

-- =============================================
-- STORED PROCEDURE: sp_GetProductWithVersion
-- Description: Get product details including RowVersion for optimistic locking
-- =============================================
IF OBJECT_ID('dbo.sp_GetProductWithVersion', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetProductWithVersion;
GO

CREATE PROCEDURE sp_GetProductWithVersion
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        ProductId,
        Title,
        Author,
        Description,
        Price,
        Stock,
        CategoryId,
        IsActive,
        CreatedAt,
        RowVersion
    FROM dbo.Products
    WHERE ProductId = @ProductId;
END
GO

PRINT 'Stored Procedure sp_GetProductWithVersion created successfully.';
GO

-- =============================================
-- STORED PROCEDURE: sp_GetOrderWithVersion
-- Description: Get order details including RowVersion for optimistic locking
-- =============================================
IF OBJECT_ID('dbo.sp_GetOrderWithVersion', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetOrderWithVersion;
GO

CREATE PROCEDURE sp_GetOrderWithVersion
    @OrderId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        OrderId,
        OrderNumber,
        UserId,
        OrderDate,
        Total,
        OrderStatus,
        PaymentStatus,
        PaymentMethod,
        ShippingName,
        ShippingPhone,
        ShippingEmail,
        ShippingAddress,
        TrackingNumber,
        Notes,
        RowVersion
    FROM dbo.Orders
    WHERE OrderId = @OrderId;
END
GO

PRINT 'Stored Procedure sp_GetOrderWithVersion created successfully.';
GO

-- =============================================
-- SECTION 8: Isolation Level Configuration
-- =============================================

/*
ISOLATION LEVEL RECOMMENDATIONS:

1. For READ operations (dashboards, reports):
   SET TRANSACTION ISOLATION LEVEL READ COMMITTED SNAPSHOT;
   -- Reduces blocking, allows consistent reads without locks

2. For WRITE operations (orders, stock updates):
   SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
   -- Highest isolation, prevents phantom reads
   -- Use with UPDLOCK/HOLDLOCK hints as shown in procedures above

3. To enable READ_COMMITTED_SNAPSHOT for the database:
   (Run this in master database by a sysadmin)
   
   ALTER DATABASE BookstoreDb SET READ_COMMITTED_SNAPSHOT ON;
   
   This allows readers to not block writers and vice versa.
*/

-- =============================================
-- Summary: All concurrency control procedures created
-- =============================================
PRINT '';
PRINT '=============================================';
PRINT 'Concurrency Control scripts created successfully!';
PRINT '=============================================';
PRINT '';
PRINT 'Schema Changes:';
PRINT '- Added RowVersion column to Products table';
PRINT '- Added RowVersion column to Orders table';
PRINT '- Added RowVersion column to FlashSaleProducts table';
PRINT '- Added RowVersion column to CartItems table';
PRINT '';
PRINT 'Optimistic Concurrency Procedures:';
PRINT '1. sp_UpdateProductStock_Optimistic';
PRINT '2. sp_UpdateOrderStatus_Optimistic';
PRINT '3. sp_GetProductWithVersion';
PRINT '4. sp_GetOrderWithVersion';
PRINT '';
PRINT 'Atomic/Pessimistic Locking Procedures:';
PRINT '5. sp_DecrementStock_Atomic';
PRINT '6. sp_IncrementStock_Atomic';
PRINT '7. sp_PurchaseFlashSaleItem_Concurrent';
PRINT '8. sp_CreateOrder_ConcurrencySafe';
PRINT '9. sp_UpdateCartQuantity_Concurrent';
PRINT '';
PRINT 'IMPORTANT: Consider enabling READ_COMMITTED_SNAPSHOT';
PRINT 'for better read/write concurrency:';
PRINT 'ALTER DATABASE BookstoreDb SET READ_COMMITTED_SNAPSHOT ON;';
PRINT '=============================================';
GO
