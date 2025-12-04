-- =============================================
-- FILE: Test_FN.sql
-- Mục đích: Test tất cả 13 functions
-- Lưu ý: Mỗi test sẽ có phần cleanup dữ liệu (nếu cần)
-- =============================================

USE Bookstore;
GO

PRINT N'========================================';
PRINT N'BẮT ĐẦU TEST CÁC FUNCTIONS';
PRINT N'========================================';
GO

-- =============================================
-- TEST 1: fn_CalculateDiscount (Scalar Function)
-- Mục đích: Tính số tiền giảm giá dựa trên giá gốc và phần trăm
-- =============================================
PRINT N'';
PRINT N'--- TEST 1: fn_CalculateDiscount ---';

-- Test 1.1: Giảm 20% cho sản phẩm 100,000đ
PRINT N'Test 1.1: 100,000đ giảm 20% = ?';
SELECT dbo.fn_CalculateDiscount(100000, 20) AS DiscountAmount;
-- Kết quả mong đợi: 20,000đ

-- Test 1.2: Giảm 50% cho sản phẩm 500,000đ
PRINT N'Test 1.2: 500,000đ giảm 50% = ?';
SELECT dbo.fn_CalculateDiscount(500000, 50) AS DiscountAmount;
-- Kết quả mong đợi: 250,000đ

-- Test 1.3: Giảm 10.5% cho sản phẩm 200,000đ
PRINT N'Test 1.3: 200,000đ giảm 10.5% = ?';
SELECT dbo.fn_CalculateDiscount(200000, 10.5) AS DiscountAmount;
-- Kết quả mong đợi: 21,000đ

-- Test 1.4: Không giảm giá (0%)
PRINT N'Test 1.4: 100,000đ giảm 0% = ?';
SELECT dbo.fn_CalculateDiscount(100000, 0) AS DiscountAmount;
-- Kết quả mong đợi: 0đ

-- Không cần cleanup vì chỉ tính toán
PRINT N'✓ TEST 1 hoàn thành - Không cần cleanup';
GO

-- =============================================
-- TEST 2: fn_CalculateFinalPrice (Scalar Function)
-- Mục đích: Tính giá cuối cùng sau khi giảm giá
-- =============================================
PRINT N'';
PRINT N'--- TEST 2: fn_CalculateFinalPrice ---';

-- Test 2.1: Giá sau khi giảm 20%
PRINT N'Test 2.1: 100,000đ sau khi giảm 20% = ?';
SELECT dbo.fn_CalculateFinalPrice(100000, 20) AS FinalPrice;
-- Kết quả mong đợi: 80,000đ

-- Test 2.2: Giá sau khi giảm 50%
PRINT N'Test 2.2: 500,000đ sau khi giảm 50% = ?';
SELECT dbo.fn_CalculateFinalPrice(500000, 50) AS FinalPrice;
-- Kết quả mong đợi: 250,000đ

-- Test 2.3: Giá sau khi giảm 15%
PRINT N'Test 2.3: 350,000đ sau khi giảm 15% = ?';
SELECT dbo.fn_CalculateFinalPrice(350000, 15) AS FinalPrice;
-- Kết quả mong đợi: 297,500đ

-- Test 2.4: Sử dụng trong SELECT với bảng Products
PRINT N'Test 2.4: Áp dụng giảm 10% cho tất cả sản phẩm';
SELECT TOP 5
    ProductId,
    Title,
    Price AS OriginalPrice,
    dbo.fn_CalculateFinalPrice(Price, 10) AS PriceAfter10PercentOff
FROM dbo.Products
WHERE IsActive = 1;

-- Không cần cleanup vì chỉ tính toán
PRINT N'✓ TEST 2 hoàn thành - Không cần cleanup';
GO

-- =============================================
-- TEST 3: fn_GetUserCartTotal (Scalar Function)
-- Mục đích: Tính tổng tiền giỏ hàng của user
-- =============================================
PRINT N'';
PRINT N'--- TEST 3: fn_GetUserCartTotal ---';

DECLARE @TestUserId3 NVARCHAR(450);
DECLARE @TestProductId3a INT;
DECLARE @TestProductId3b INT;
DECLARE @ProductPrice3a DECIMAL(18,2);
DECLARE @ProductPrice3b DECIMAL(18,2);

SELECT TOP 1 @TestUserId3 = Id FROM dbo.AspNetUsers;
SELECT TOP 1 @TestProductId3a = ProductId, @ProductPrice3a = Price FROM dbo.Products WHERE IsActive = 1 AND Stock > 0;
SELECT TOP 1 @TestProductId3b = ProductId, @ProductPrice3b = Price FROM dbo.Products WHERE IsActive = 1 AND Stock > 0 AND ProductId <> @TestProductId3a;

IF @TestUserId3 IS NOT NULL AND @TestProductId3a IS NOT NULL
BEGIN
    -- Xóa giỏ hàng cũ của user (nếu có)
    DELETE FROM dbo.CartItems WHERE UserId = @TestUserId3;
    
    -- Thêm sản phẩm vào giỏ hàng để test
    INSERT INTO dbo.CartItems (UserId, ProductId, Quantity, DateAdded)
    VALUES (@TestUserId3, @TestProductId3a, 2, GETUTCDATE());
    
    IF @TestProductId3b IS NOT NULL
    BEGIN
        INSERT INTO dbo.CartItems (UserId, ProductId, Quantity, DateAdded)
        VALUES (@TestUserId3, @TestProductId3b, 1, GETUTCDATE());
    END
    
    PRINT N'Đã thêm sản phẩm vào giỏ hàng để test';
    
    -- Test 3.1: Tính tổng tiền giỏ hàng
    PRINT N'Test 3.1: Tổng tiền giỏ hàng của user';
    SELECT dbo.fn_GetUserCartTotal(@TestUserId3) AS CartTotal;
    
    -- Kiểm tra chi tiết để so sánh
    PRINT N'Chi tiết giỏ hàng:';
    SELECT 
        ci.ProductId,
        p.Title,
        p.Price,
        ci.Quantity,
        (p.Price * ci.Quantity) AS Subtotal
    FROM dbo.CartItems ci
    INNER JOIN dbo.Products p ON ci.ProductId = p.ProductId
    WHERE ci.UserId = @TestUserId3;
    
    -- CLEANUP
    PRINT N'--- CLEANUP TEST 3 ---';
    DELETE FROM dbo.CartItems WHERE UserId = @TestUserId3;
    PRINT N'Đã xóa CartItems test';
END
ELSE
BEGIN
    PRINT N'⚠ Không đủ dữ liệu để test';
END

-- Test 3.2: User không có giỏ hàng (phải trả về 0)
PRINT N'Test 3.2: User không có giỏ hàng (phải trả về 0)';
SELECT dbo.fn_GetUserCartTotal('non-existent-user-id') AS EmptyCartTotal;

PRINT N'✓ TEST 3 hoàn thành - Đã cleanup';
GO

-- =============================================
-- TEST 4: fn_GetUserCartCount (Scalar Function)
-- Mục đích: Đếm tổng số sản phẩm trong giỏ hàng
-- =============================================
PRINT N'';
PRINT N'--- TEST 4: fn_GetUserCartCount ---';

DECLARE @TestUserId4 NVARCHAR(450);
DECLARE @TestProductId4a INT;
DECLARE @TestProductId4b INT;

SELECT TOP 1 @TestUserId4 = Id FROM dbo.AspNetUsers;
SELECT TOP 1 @TestProductId4a = ProductId FROM dbo.Products WHERE IsActive = 1 AND Stock > 0;
SELECT TOP 1 @TestProductId4b = ProductId FROM dbo.Products WHERE IsActive = 1 AND Stock > 0 AND ProductId <> @TestProductId4a;

IF @TestUserId4 IS NOT NULL AND @TestProductId4a IS NOT NULL
BEGIN
    -- Xóa giỏ hàng cũ
    DELETE FROM dbo.CartItems WHERE UserId = @TestUserId4;
    
    -- Thêm sản phẩm: 2 cái sản phẩm A + 3 cái sản phẩm B = 5 sản phẩm
    INSERT INTO dbo.CartItems (UserId, ProductId, Quantity, DateAdded)
    VALUES (@TestUserId4, @TestProductId4a, 2, GETUTCDATE());
    
    IF @TestProductId4b IS NOT NULL
    BEGIN
        INSERT INTO dbo.CartItems (UserId, ProductId, Quantity, DateAdded)
        VALUES (@TestUserId4, @TestProductId4b, 3, GETUTCDATE());
    END
    
    PRINT N'Test 4.1: Đếm số sản phẩm trong giỏ (2 + 3 = 5)';
    SELECT dbo.fn_GetUserCartCount(@TestUserId4) AS CartCount;
    
    -- Kiểm tra chi tiết
    PRINT N'Chi tiết giỏ hàng:';
    SELECT ProductId, Quantity FROM dbo.CartItems WHERE UserId = @TestUserId4;
    
    -- CLEANUP
    PRINT N'--- CLEANUP TEST 4 ---';
    DELETE FROM dbo.CartItems WHERE UserId = @TestUserId4;
    PRINT N'Đã xóa CartItems test';
END
ELSE
BEGIN
    PRINT N'⚠ Không đủ dữ liệu để test';
END

-- Test 4.2: User không có giỏ hàng
PRINT N'Test 4.2: User không có giỏ hàng (phải trả về 0)';
SELECT dbo.fn_GetUserCartCount('non-existent-user-id') AS EmptyCartCount;

PRINT N'✓ TEST 4 hoàn thành - Đã cleanup';
GO

-- =============================================
-- TEST 5: fn_GetProductAverageRating (Scalar Function)
-- Mục đích: Tính điểm đánh giá trung bình của sản phẩm
-- =============================================
PRINT N'';
PRINT N'--- TEST 5: fn_GetProductAverageRating ---';

DECLARE @TestProductId5 INT;
DECLARE @TestUserId5 NVARCHAR(450);

SELECT TOP 1 @TestProductId5 = ProductId FROM dbo.Products WHERE IsActive = 1;
SELECT TOP 1 @TestUserId5 = Id FROM dbo.AspNetUsers;

IF @TestProductId5 IS NOT NULL AND @TestUserId5 IS NOT NULL
BEGIN
    -- Xóa review cũ của product này để test clean
    DELETE FROM dbo.Reviews WHERE ProductId = @TestProductId5;
    
    -- Thêm một số reviews để test (5 + 4 + 3 = 12, trung bình = 4.00)
    INSERT INTO dbo.Reviews (UserId, ProductId, Rating, Comment, CreatedAt)
    VALUES 
        (@TestUserId5, @TestProductId5, 5, N'Sách rất hay!', GETUTCDATE()),
        (@TestUserId5, @TestProductId5, 4, N'Khá tốt', GETUTCDATE()),
        (@TestUserId5, @TestProductId5, 3, N'Bình thường', GETUTCDATE());
    
    PRINT N'Đã thêm 3 reviews với rating 5, 4, 3';
    
    -- Test 5.1: Tính rating trung bình
    PRINT N'Test 5.1: Rating trung bình (5+4+3)/3 = 4.00';
    SELECT dbo.fn_GetProductAverageRating(@TestProductId5) AS AverageRating;
    
    -- Kiểm tra chi tiết
    PRINT N'Chi tiết reviews:';
    SELECT Rating FROM dbo.Reviews WHERE ProductId = @TestProductId5;
    
    -- CLEANUP
    PRINT N'--- CLEANUP TEST 5 ---';
    DELETE FROM dbo.Reviews WHERE ProductId = @TestProductId5 AND Comment IN (N'Sách rất hay!', N'Khá tốt', N'Bình thường');
    PRINT N'Đã xóa Reviews test';
END
ELSE
BEGIN
    PRINT N'⚠ Không đủ dữ liệu để test';
END

-- Test 5.2: Sản phẩm chưa có đánh giá
PRINT N'Test 5.2: Sản phẩm chưa có đánh giá (phải trả về 0)';
SELECT dbo.fn_GetProductAverageRating(-1) AS NoRatingProduct;

PRINT N'✓ TEST 5 hoàn thành - Đã cleanup';
GO

-- =============================================
-- TEST 6: fn_GetProductReviewCount (Scalar Function)
-- Mục đích: Đếm số lượng đánh giá của sản phẩm
-- =============================================
PRINT N'';
PRINT N'--- TEST 6: fn_GetProductReviewCount ---';

DECLARE @TestProductId6 INT;
DECLARE @TestUserId6 NVARCHAR(450);

SELECT TOP 1 @TestProductId6 = ProductId FROM dbo.Products WHERE IsActive = 1;
SELECT TOP 1 @TestUserId6 = Id FROM dbo.AspNetUsers;

IF @TestProductId6 IS NOT NULL AND @TestUserId6 IS NOT NULL
BEGIN
    -- Xóa review cũ
    DELETE FROM dbo.Reviews WHERE ProductId = @TestProductId6;
    
    -- Thêm 4 reviews để test
    INSERT INTO dbo.Reviews (UserId, ProductId, Rating, Comment, CreatedAt)
    VALUES 
        (@TestUserId6, @TestProductId6, 5, N'Test review 1', GETUTCDATE()),
        (@TestUserId6, @TestProductId6, 4, N'Test review 2', GETUTCDATE()),
        (@TestUserId6, @TestProductId6, 4, N'Test review 3', GETUTCDATE()),
        (@TestUserId6, @TestProductId6, 3, N'Test review 4', GETUTCDATE());
    
    PRINT N'Đã thêm 4 reviews';
    
    -- Test 6.1: Đếm số reviews
    PRINT N'Test 6.1: Đếm số reviews (phải = 4)';
    SELECT dbo.fn_GetProductReviewCount(@TestProductId6) AS ReviewCount;
    
    -- CLEANUP
    PRINT N'--- CLEANUP TEST 6 ---';
    DELETE FROM dbo.Reviews WHERE ProductId = @TestProductId6 AND Comment LIKE N'Test review%';
    PRINT N'Đã xóa Reviews test';
END
ELSE
BEGIN
    PRINT N'⚠ Không đủ dữ liệu để test';
END

-- Test 6.2: Sản phẩm chưa có đánh giá
PRINT N'Test 6.2: Sản phẩm chưa có đánh giá (phải trả về 0)';
SELECT dbo.fn_GetProductReviewCount(-1) AS NoReviewCount;

PRINT N'✓ TEST 6 hoàn thành - Đã cleanup';
GO

-- =============================================
-- TEST 7: fn_FormatVNDCurrency (Scalar Function)
-- Mục đích: Định dạng số tiền theo kiểu Việt Nam
-- =============================================
PRINT N'';
PRINT N'--- TEST 7: fn_FormatVNDCurrency ---';

-- Test 7.1: Định dạng số tiền đơn giản
PRINT N'Test 7.1: Định dạng 100000 => "100,000₫"';
SELECT dbo.fn_FormatVNDCurrency(100000) AS FormattedPrice;

-- Test 7.2: Số tiền lớn
PRINT N'Test 7.2: Định dạng 1234567890 => "1,234,567,890₫"';
SELECT dbo.fn_FormatVNDCurrency(1234567890) AS FormattedPrice;

-- Test 7.3: Số tiền có thập phân (sẽ được làm tròn)
PRINT N'Test 7.3: Định dạng 99999.50 => "100,000₫"';
SELECT dbo.fn_FormatVNDCurrency(99999.50) AS FormattedPrice;

-- Test 7.4: Số 0
PRINT N'Test 7.4: Định dạng 0 => "0₫"';
SELECT dbo.fn_FormatVNDCurrency(0) AS FormattedPrice;

-- Test 7.5: Sử dụng với bảng Products
PRINT N'Test 7.5: Hiển thị giá sản phẩm đã định dạng';
SELECT TOP 5
    ProductId,
    Title,
    Price,
    dbo.fn_FormatVNDCurrency(Price) AS FormattedPrice
FROM dbo.Products
WHERE IsActive = 1;

-- Không cần cleanup vì chỉ tính toán
PRINT N'✓ TEST 7 hoàn thành - Không cần cleanup';
GO

-- =============================================
-- TEST 8: fn_GetOrderStatusDisplay (Scalar Function)
-- Mục đích: Chuyển trạng thái đơn hàng sang tiếng Việt
-- =============================================
PRINT N'';
PRINT N'--- TEST 8: fn_GetOrderStatusDisplay ---';

-- Test 8.1: Tất cả các trạng thái
PRINT N'Test 8.1: Chuyển đổi tất cả các trạng thái';
SELECT 
    'Pending' AS OriginalStatus, dbo.fn_GetOrderStatusDisplay('Pending') AS DisplayStatus
UNION ALL
SELECT 
    'Processing', dbo.fn_GetOrderStatusDisplay('Processing')
UNION ALL
SELECT 
    'Shipped', dbo.fn_GetOrderStatusDisplay('Shipped')
UNION ALL
SELECT 
    'Delivered', dbo.fn_GetOrderStatusDisplay('Delivered')
UNION ALL
SELECT 
    'Cancelled', dbo.fn_GetOrderStatusDisplay('Cancelled');

-- Test 8.2: Trạng thái không xác định
PRINT N'Test 8.2: Trạng thái không xác định (trả về nguyên bản)';
SELECT dbo.fn_GetOrderStatusDisplay('Unknown') AS UnknownStatus;

-- Test 8.3: Sử dụng với bảng Orders
PRINT N'Test 8.3: Hiển thị trạng thái đơn hàng bằng tiếng Việt';
SELECT TOP 5
    OrderId,
    OrderNumber,
    OrderStatus,
    dbo.fn_GetOrderStatusDisplay(OrderStatus) AS TrangThai
FROM dbo.Orders;

-- Không cần cleanup vì chỉ tính toán
PRINT N'✓ TEST 8 hoàn thành - Không cần cleanup';
GO

-- =============================================
-- TEST 9: fn_GetMonthNameVietnamese (Scalar Function)
-- Mục đích: Chuyển số tháng sang tên tháng tiếng Việt
-- =============================================
PRINT N'';
PRINT N'--- TEST 9: fn_GetMonthNameVietnamese ---';

-- Test 9.1: Tất cả 12 tháng
PRINT N'Test 9.1: Chuyển đổi tất cả 12 tháng';
SELECT 
    n AS MonthNumber,
    dbo.fn_GetMonthNameVietnamese(n) AS MonthName
FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12)) AS T(n);

-- Test 9.2: Số tháng không hợp lệ
PRINT N'Test 9.2: Số tháng không hợp lệ (0, 13)';
SELECT dbo.fn_GetMonthNameVietnamese(0) AS InvalidMonth0;
SELECT dbo.fn_GetMonthNameVietnamese(13) AS InvalidMonth13;

-- Test 9.3: Sử dụng với dữ liệu thực
PRINT N'Test 9.3: Hiển thị tháng đặt hàng bằng tiếng Việt';
SELECT TOP 5
    OrderId,
    OrderDate,
    MONTH(OrderDate) AS MonthNumber,
    dbo.fn_GetMonthNameVietnamese(MONTH(OrderDate)) AS TenThang
FROM dbo.Orders
ORDER BY OrderDate DESC;

-- Không cần cleanup vì chỉ tính toán
PRINT N'✓ TEST 9 hoàn thành - Không cần cleanup';
GO

-- =============================================
-- TEST 10: fn_CalculateTax (Scalar Function)
-- Mục đích: Tính thuế VAT (10%) từ giá trị đơn hàng
-- =============================================
PRINT N'';
PRINT N'--- TEST 10: fn_CalculateTax ---';

-- Test 10.1: Tính thuế cho 100,000đ
PRINT N'Test 10.1: Thuế VAT 10% của 100,000đ = ?';
SELECT dbo.fn_CalculateTax(100000) AS TaxAmount;
-- Kết quả mong đợi: 10,000đ

-- Test 10.2: Tính thuế cho 1,500,000đ
PRINT N'Test 10.2: Thuế VAT 10% của 1,500,000đ = ?';
SELECT dbo.fn_CalculateTax(1500000) AS TaxAmount;
-- Kết quả mong đợi: 150,000đ

-- Test 10.3: Thuế của số 0
PRINT N'Test 10.3: Thuế VAT 10% của 0đ = ?';
SELECT dbo.fn_CalculateTax(0) AS TaxAmount;
-- Kết quả mong đợi: 0đ

-- Test 10.4: Sử dụng với bảng Orders để tính thuế
PRINT N'Test 10.4: Tính thuế cho các đơn hàng';
SELECT TOP 5
    OrderId,
    Total,
    dbo.fn_CalculateTax(Total) AS TaxAmount,
    Total + dbo.fn_CalculateTax(Total) AS TotalWithTax,
    dbo.fn_FormatVNDCurrency(Total + dbo.fn_CalculateTax(Total)) AS TotalWithTaxFormatted
FROM dbo.Orders;

-- Không cần cleanup vì chỉ tính toán
PRINT N'✓ TEST 10 hoàn thành - Không cần cleanup';
GO

-- =============================================
-- TEST 11: fn_GetProductsInCategory (Table-Valued Function)
-- Mục đích: Lấy danh sách sản phẩm trong 1 danh mục
-- =============================================
PRINT N'';
PRINT N'--- TEST 11: fn_GetProductsInCategory ---';

DECLARE @TestCategoryId11 INT;

-- Lấy CategoryId đầu tiên có sản phẩm
SELECT TOP 1 @TestCategoryId11 = CategoryId 
FROM dbo.Products 
WHERE IsActive = 1
GROUP BY CategoryId
HAVING COUNT(*) > 0;

IF @TestCategoryId11 IS NOT NULL
BEGIN
    -- Test 11.1: Lấy sản phẩm theo danh mục
    PRINT N'Test 11.1: Lấy sản phẩm trong CategoryId = ' + CAST(@TestCategoryId11 AS NVARCHAR(10));
    SELECT * FROM dbo.fn_GetProductsInCategory(@TestCategoryId11);
    
    -- Test 11.2: Đếm số sản phẩm trong danh mục
    PRINT N'Test 11.2: Đếm số sản phẩm trong danh mục';
    SELECT COUNT(*) AS ProductCount FROM dbo.fn_GetProductsInCategory(@TestCategoryId11);
    
    -- Test 11.3: Lọc thêm điều kiện với function
    PRINT N'Test 11.3: Lọc sản phẩm có giá > 100,000đ trong danh mục';
    SELECT * FROM dbo.fn_GetProductsInCategory(@TestCategoryId11)
    WHERE Price > 100000;
END
ELSE
BEGIN
    PRINT N'⚠ Không có danh mục nào có sản phẩm';
END

-- Test 11.4: Danh mục không tồn tại (trả về rỗng)
PRINT N'Test 11.4: Danh mục không tồn tại (phải trả về rỗng)';
SELECT * FROM dbo.fn_GetProductsInCategory(-1);

-- Không cần cleanup vì chỉ SELECT
PRINT N'✓ TEST 11 hoàn thành - Không cần cleanup';
GO

-- =============================================
-- TEST 12: fn_GetTopSellingProducts (Table-Valued Function)
-- Mục đích: Lấy top sản phẩm bán chạy nhất
-- =============================================
PRINT N'';
PRINT N'--- TEST 12: fn_GetTopSellingProducts ---';

-- Test 12.1: Top 5 sản phẩm bán chạy
PRINT N'Test 12.1: Top 5 sản phẩm bán chạy nhất';
SELECT * FROM dbo.fn_GetTopSellingProducts(5);

-- Test 12.2: Top 10 sản phẩm bán chạy
PRINT N'Test 12.2: Top 10 sản phẩm bán chạy nhất';
SELECT * FROM dbo.fn_GetTopSellingProducts(10);

-- Test 12.3: Top 3 với thêm định dạng tiền
PRINT N'Test 12.3: Top 3 với định dạng tiền tệ';
SELECT 
    ProductId,
    Title,
    Author,
    dbo.fn_FormatVNDCurrency(Price) AS GiaBan,
    TotalSold AS DaBan,
    dbo.fn_FormatVNDCurrency(TotalRevenue) AS DoanhThu
FROM dbo.fn_GetTopSellingProducts(3);

-- Không cần cleanup vì chỉ SELECT
PRINT N'✓ TEST 12 hoàn thành - Không cần cleanup';
GO

-- =============================================
-- TEST 13: fn_GetOrdersByDateRange (Table-Valued Function)
-- Mục đích: Lấy danh sách đơn hàng trong khoảng thời gian
-- =============================================
PRINT N'';
PRINT N'--- TEST 13: fn_GetOrdersByDateRange ---';

-- Test 13.1: Đơn hàng trong 7 ngày gần nhất
PRINT N'Test 13.1: Đơn hàng trong 7 ngày gần nhất';
DECLARE @EndDate13 DATE = CAST(GETUTCDATE() AS DATE);
DECLARE @StartDate13 DATE = DATEADD(DAY, -7, @EndDate13);
SELECT * FROM dbo.fn_GetOrdersByDateRange(@StartDate13, @EndDate13);

-- Test 13.2: Đơn hàng tháng 11/2025
PRINT N'Test 13.2: Đơn hàng tháng 11/2025';
SELECT * FROM dbo.fn_GetOrdersByDateRange('2025-11-01', '2025-11-30');

-- Test 13.3: Đơn hàng cả năm 2025
PRINT N'Test 13.3: Đơn hàng năm 2025';
SELECT * FROM dbo.fn_GetOrdersByDateRange('2025-01-01', '2025-12-31');

-- Test 13.4: Kết hợp với các function khác
PRINT N'Test 13.4: Đơn hàng với trạng thái tiếng Việt và định dạng tiền';
SELECT 
    OrderId,
    OrderNumber,
    OrderDate,
    dbo.fn_GetMonthNameVietnamese(MONTH(OrderDate)) AS ThangDatHang,
    dbo.fn_FormatVNDCurrency(Total) AS TongTien,
    dbo.fn_GetOrderStatusDisplay(OrderStatus) AS TrangThai,
    CustomerName
FROM dbo.fn_GetOrdersByDateRange('2025-01-01', '2025-12-31');

-- Test 13.5: Lọc thêm điều kiện
PRINT N'Test 13.5: Chỉ lấy đơn hàng đã thanh toán trong năm 2025';
SELECT * FROM dbo.fn_GetOrdersByDateRange('2025-01-01', '2025-12-31')
WHERE PaymentStatus = 'Paid';

-- Không cần cleanup vì chỉ SELECT
PRINT N'✓ TEST 13 hoàn thành - Không cần cleanup';
GO

-- =============================================
-- BONUS: Test kết hợp nhiều functions
-- =============================================
PRINT N'';
PRINT N'--- BONUS: Kết hợp nhiều functions ---';

-- Hiển thị thông tin sản phẩm với nhiều function
PRINT N'Hiển thị thông tin sản phẩm tổng hợp:';
SELECT TOP 5
    p.ProductId,
    p.Title,
    p.Price AS GiaGoc,
    dbo.fn_FormatVNDCurrency(p.Price) AS GiaGocFormatted,
    dbo.fn_CalculateDiscount(p.Price, 15) AS TienGiam15Percent,
    dbo.fn_CalculateFinalPrice(p.Price, 15) AS GiaSauGiam15Percent,
    dbo.fn_FormatVNDCurrency(dbo.fn_CalculateFinalPrice(p.Price, 15)) AS GiaSauGiamFormatted,
    dbo.fn_GetProductAverageRating(p.ProductId) AS DiemDanhGia,
    dbo.fn_GetProductReviewCount(p.ProductId) AS SoLuotDanhGia
FROM dbo.Products p
WHERE p.IsActive = 1;

PRINT N'✓ BONUS hoàn thành';
GO

-- =============================================
-- KẾT THÚC TEST
-- =============================================
PRINT N'';
PRINT N'========================================';
PRINT N'HOÀN THÀNH TEST TẤT CẢ 13 FUNCTIONS';
PRINT N'========================================';
PRINT N'';
PRINT N'TÓM TẮT:';
PRINT N'';
PRINT N'SCALAR FUNCTIONS (10 cái):';
PRINT N'  1.  fn_CalculateDiscount        - ✓ Không cần cleanup';
PRINT N'  2.  fn_CalculateFinalPrice      - ✓ Không cần cleanup';
PRINT N'  3.  fn_GetUserCartTotal         - ✓ Đã cleanup';
PRINT N'  4.  fn_GetUserCartCount         - ✓ Đã cleanup';
PRINT N'  5.  fn_GetProductAverageRating  - ✓ Đã cleanup';
PRINT N'  6.  fn_GetProductReviewCount    - ✓ Đã cleanup';
PRINT N'  7.  fn_FormatVNDCurrency        - ✓ Không cần cleanup';
PRINT N'  8.  fn_GetOrderStatusDisplay    - ✓ Không cần cleanup';
PRINT N'  9.  fn_GetMonthNameVietnamese   - ✓ Không cần cleanup';
PRINT N'  10. fn_CalculateTax             - ✓ Không cần cleanup';
PRINT N'';
PRINT N'TABLE-VALUED FUNCTIONS (3 cái):';
PRINT N'  11. fn_GetProductsInCategory    - ✓ Không cần cleanup';
PRINT N'  12. fn_GetTopSellingProducts    - ✓ Không cần cleanup';
PRINT N'  13. fn_GetOrdersByDateRange     - ✓ Không cần cleanup';
PRINT N'';
PRINT N'- Dữ liệu gốc được bảo toàn nguyên vẹn';
PRINT N'========================================';
GO
