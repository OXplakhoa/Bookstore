-- Flash Sale Testing SQL Scripts
-- Run these in SQL Server Management Studio or Azure Data Studio
-- Database: BookstoreDb

USE BookstoreDb;
GO

-- ============================================================================
-- TEST 1: Check All Active Flash Sales
-- ============================================================================
PRINT '=== TEST 1: Active Flash Sales ==='
DECLARE @Now DATETIME = GETUTCDATE();

SELECT 
    fs.FlashSaleId,
    fs.Name,
    fs.StartDate,
    fs.EndDate,
    fs.IsActive,
    COUNT(fsp.FlashSaleProductId) AS ProductCount,
    SUM(fsp.SoldCount) AS TotalSold,
    CASE 
        WHEN fs.StartDate > @Now THEN '🔵 Upcoming'
        WHEN fs.EndDate < @Now THEN '⚫ Expired'
        WHEN fs.IsActive = 0 THEN '🔴 Disabled'
        ELSE '🟢 Active'
    END AS Status
FROM FlashSales fs
LEFT JOIN FlashSaleProducts fsp ON fs.FlashSaleId = fsp.FlashSaleId
GROUP BY fs.FlashSaleId, fs.Name, fs.StartDate, fs.EndDate, fs.IsActive
ORDER BY fs.CreatedAt DESC;
GO

-- ============================================================================
-- TEST 2: Check for Overlapping Flash Sales (Should Return 0)
-- ============================================================================
PRINT '=== TEST 2: Overlapping Flash Sales (Should be empty) ==='
SELECT 
    p.ProductId,
    p.Title,
    COUNT(*) AS OverlapCount,
    STRING_AGG(fs.Name, ', ') AS FlashSaleNames
FROM FlashSaleProducts fsp1
JOIN Products p ON fsp1.ProductId = p.ProductId
JOIN FlashSales fs1 ON fsp1.FlashSaleId = fs1.FlashSaleId
JOIN FlashSaleProducts fsp2 ON fsp1.ProductId = fsp2.ProductId 
    AND fsp1.FlashSaleProductId != fsp2.FlashSaleProductId
JOIN FlashSales fs2 ON fsp2.FlashSaleId = fs2.FlashSaleId
WHERE fs1.IsActive = 1 
  AND fs2.IsActive = 1
  AND fs1.StartDate < fs2.EndDate 
  AND fs1.EndDate > fs2.StartDate
GROUP BY p.ProductId, p.Title
HAVING COUNT(*) > 1;

IF @@ROWCOUNT = 0
    PRINT '✅ PASS: No overlapping flash sales found';
ELSE
    PRINT '❌ FAIL: Found overlapping flash sales!';
GO

-- ============================================================================
-- TEST 3: Verify Decimal Precision
-- ============================================================================
PRINT '=== TEST 3: Decimal Precision Check ==='
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    CASE 
        WHEN DATA_TYPE = 'decimal' AND NUMERIC_PRECISION = 18 AND NUMERIC_SCALE = 2 
        THEN '✅ PASS'
        ELSE '❌ FAIL'
    END AS Status
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('FlashSaleProducts', 'Products', 'OrderItems', 'Orders', 'Payments')
  AND DATA_TYPE = 'decimal'
ORDER BY TABLE_NAME, COLUMN_NAME;
GO

-- ============================================================================
-- TEST 4: Check Flash Sale Product Pricing Consistency
-- ============================================================================
PRINT '=== TEST 4: Flash Sale Pricing Consistency ==='
SELECT 
    fsp.FlashSaleProductId,
    p.Title AS ProductName,
    fsp.OriginalPrice,
    fsp.SalePrice,
    fsp.DiscountPercentage,
    -- Verify discount percentage calculation
    CAST(((fsp.OriginalPrice - fsp.SalePrice) / fsp.OriginalPrice * 100) AS DECIMAL(5,2)) AS CalculatedDiscount,
    CASE 
        WHEN fsp.SalePrice >= fsp.OriginalPrice THEN '❌ Sale price >= Original price'
        WHEN ABS(fsp.DiscountPercentage - ((fsp.OriginalPrice - fsp.SalePrice) / fsp.OriginalPrice * 100)) > 0.1 
        THEN '⚠️ Discount % mismatch'
        ELSE '✅ OK'
    END AS Status
FROM FlashSaleProducts fsp
JOIN Products p ON fsp.ProductId = p.ProductId
JOIN FlashSales fs ON fsp.FlashSaleId = fs.FlashSaleId
WHERE fs.IsActive = 1;
GO

-- ============================================================================
-- TEST 5: Check Stock Limit Enforcement
-- ============================================================================
PRINT '=== TEST 5: Stock Limit Status ==='
SELECT 
    fsp.FlashSaleProductId,
    p.Title AS ProductName,
    fsp.StockLimit,
    fsp.SoldCount,
    CASE 
        WHEN fsp.StockLimit IS NULL THEN 'Unlimited'
        ELSE CAST((fsp.StockLimit - fsp.SoldCount) AS VARCHAR) 
    END AS Remaining,
    CASE 
        WHEN fsp.StockLimit IS NOT NULL AND fsp.SoldCount > fsp.StockLimit 
        THEN '❌ OVERSOLD!'
        WHEN fsp.StockLimit IS NOT NULL AND fsp.SoldCount = fsp.StockLimit 
        THEN '⚠️ Sold Out'
        WHEN fsp.StockLimit IS NOT NULL AND (fsp.StockLimit - fsp.SoldCount) <= 5 
        THEN '🟡 Low Stock'
        ELSE '✅ OK'
    END AS Status
FROM FlashSaleProducts fsp
JOIN Products p ON fsp.ProductId = p.ProductId
JOIN FlashSales fs ON fsp.FlashSaleId = fs.FlashSaleId
WHERE fs.IsActive = 1
ORDER BY Status DESC, Remaining;
GO

-- ============================================================================
-- TEST 6: Check Cart Items with Flash Sales
-- ============================================================================
PRINT '=== TEST 6: Cart Items with Flash Sale ==='
SELECT 
    ci.CartItemId,
    u.Email AS UserEmail,
    p.Title AS ProductName,
    ci.Quantity,
    ci.LockedPrice,
    p.Price AS CurrentProductPrice,
    fsp.SalePrice AS FlashSalePrice,
    CASE 
        WHEN ci.FlashSaleProductId IS NOT NULL AND ci.LockedPrice != fsp.SalePrice 
        THEN '⚠️ Price mismatch'
        WHEN ci.FlashSaleProductId IS NOT NULL AND fs.EndDate < GETUTCDATE() 
        THEN '❌ Flash sale expired'
        WHEN ci.FlashSaleProductId IS NOT NULL 
        THEN '✅ Valid flash sale'
        ELSE 'Regular item'
    END AS Status
FROM CartItems ci
JOIN AspNetUsers u ON ci.UserId = u.Id
JOIN Products p ON ci.ProductId = p.ProductId
LEFT JOIN FlashSaleProducts fsp ON ci.FlashSaleProductId = fsp.FlashSaleProductId
LEFT JOIN FlashSales fs ON fsp.FlashSaleId = fs.FlashSaleId
ORDER BY ci.DateAdded DESC;
GO

-- ============================================================================
-- TEST 7: Check Order Items with Flash Sale History
-- ============================================================================
PRINT '=== TEST 7: Order Items with Flash Sale ==='
SELECT TOP 20
    oi.OrderItemId,
    o.OrderNumber,
    p.Title AS ProductName,
    oi.UnitPrice,
    oi.Quantity,
    oi.WasOnFlashSale,
    CASE 
        WHEN oi.WasOnFlashSale = 1 AND oi.FlashSaleProductId IS NULL 
        THEN '⚠️ Missing FlashSaleProductId'
        WHEN oi.WasOnFlashSale = 1 
        THEN '✅ Flash sale recorded'
        ELSE 'Regular purchase'
    END AS Status
FROM OrderItems oi
JOIN Orders o ON oi.OrderId = o.OrderId
JOIN Products p ON oi.ProductId = p.ProductId
ORDER BY o.OrderDate DESC;
GO

-- ============================================================================
-- TEST 8: Performance Check - Query Execution Time
-- ============================================================================
PRINT '=== TEST 8: Query Performance ==='
SET STATISTICS TIME ON;

-- Test active flash sale lookup (this runs on product pages)
DECLARE @TestProductId INT = (SELECT TOP 1 ProductId FROM Products WHERE IsActive = 1);
DECLARE @Now2 DATETIME = GETUTCDATE();

SELECT fsp.*
FROM FlashSaleProducts fsp
JOIN FlashSales fs ON fsp.FlashSaleId = fs.FlashSaleId
WHERE fsp.ProductId = @TestProductId
  AND fs.IsActive = 1
  AND fs.StartDate <= @Now2
  AND fs.EndDate >= @Now2;

SET STATISTICS TIME OFF;
PRINT 'Query should complete in < 50ms for optimal performance';
GO

-- ============================================================================
-- TEST 9: Data Integrity Constraints
-- ============================================================================
PRINT '=== TEST 9: Foreign Key Constraints ==='
SELECT 
    fk.name AS ConstraintName,
    OBJECT_NAME(fk.parent_object_id) AS TableName,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS ColumnName,
    OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS ReferencedColumn,
    fk.delete_referential_action_desc AS DeleteAction
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
WHERE OBJECT_NAME(fk.parent_object_id) IN ('FlashSales', 'FlashSaleProducts', 'CartItems', 'OrderItems')
ORDER BY TableName, ConstraintName;
GO

-- ============================================================================
-- TEST 10: Summary Report
-- ============================================================================
PRINT '=== TEST 10: Flash Sale Summary Report ==='
DECLARE @CurrentTime DATETIME = GETUTCDATE();

SELECT 
    'Total Flash Sales' AS Metric,
    COUNT(*) AS Value
FROM FlashSales
UNION ALL
SELECT 
    'Active Flash Sales',
    COUNT(*)
FROM FlashSales
WHERE IsActive = 1 
  AND StartDate <= @CurrentTime 
  AND EndDate >= @CurrentTime
UNION ALL
SELECT 
    'Upcoming Flash Sales',
    COUNT(*)
FROM FlashSales
WHERE IsActive = 1 AND StartDate > @CurrentTime
UNION ALL
SELECT 
    'Expired Flash Sales',
    COUNT(*)
FROM FlashSales
WHERE EndDate < @CurrentTime
UNION ALL
SELECT 
    'Total Products in Flash Sales',
    COUNT(*)
FROM FlashSaleProducts
UNION ALL
SELECT 
    'Total Flash Sale Revenue (Estimated)',
    CAST(SUM(fsp.SalePrice * fsp.SoldCount) AS INT)
FROM FlashSaleProducts fsp
UNION ALL
SELECT 
    'Cart Items with Flash Sale',
    COUNT(*)
FROM CartItems
WHERE FlashSaleProductId IS NOT NULL
UNION ALL
SELECT 
    'Orders with Flash Sale Items',
    COUNT(DISTINCT oi.OrderId)
FROM OrderItems oi
WHERE oi.WasOnFlashSale = 1;
GO

PRINT '=== All Tests Completed ==='
PRINT 'Review the results above for any failures or warnings.'
GO
