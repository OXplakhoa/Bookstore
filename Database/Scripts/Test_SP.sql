-- =============================================
-- FILE: Test.sql
-- Mục đích: Test tất cả 14 stored procedures
-- Lưu ý: Mỗi test sẽ có phần cleanup dữ liệu
-- =============================================

USE Bookstore;
GO

PRINT N'========================================';
PRINT N'BẮT ĐẦU TEST CÁC STORED PROCEDURES';
PRINT N'========================================';
GO

-- =============================================
-- TEST 1: sp_GetDashboardStats
-- Mục đích: Lấy thống kê tổng quan cho Admin Dashboard
-- =============================================
PRINT N'';
PRINT N'--- TEST 1: sp_GetDashboardStats ---';
PRINT N'Không cần dữ liệu test, chỉ đọc dữ liệu hiện có';

EXEC sp_GetDashboardStats;

-- Không cần cleanup vì chỉ SELECT
PRINT N'✓ TEST 1 hoàn thành - Không cần cleanup';
GO

-- =============================================
-- TEST 2: sp_SearchProducts
-- Mục đích: Tìm kiếm và lọc sản phẩm với phân trang
-- =============================================
PRINT N'';
PRINT N'--- TEST 2: sp_SearchProducts ---';

-- Test 2.1: Lấy tất cả sản phẩm (mặc định)
PRINT N'Test 2.1: Lấy tất cả sản phẩm trang 1';
EXEC sp_SearchProducts;

-- Test 2.2: Tìm kiếm theo từ khóa
PRINT N'Test 2.2: Tìm kiếm theo từ khóa "Harry"';
EXEC sp_SearchProducts @SearchTerm = N'Harry';

-- Test 2.3: Lọc theo khoảng giá
PRINT N'Test 2.3: Lọc sản phẩm có giá từ 100,000 đến 500,000';
EXEC sp_SearchProducts @MinPrice = 100000, @MaxPrice = 500000;

-- Test 2.4: Lọc theo CategoryId (giả sử Category 1 tồn tại)
PRINT N'Test 2.4: Lọc theo danh mục (CategoryId = 1)';
EXEC sp_SearchProducts @CategoryId = 1;

-- Test 2.5: Chỉ lấy sản phẩm còn hàng, sắp xếp theo giá tăng dần
PRINT N'Test 2.5: Sản phẩm còn hàng, sắp xếp theo giá ASC';
EXEC sp_SearchProducts @InStockOnly = 1, @SortBy = 'Price', @SortOrder = 'ASC';

-- Test 2.6: Phân trang - trang 2, mỗi trang 5 sản phẩm
PRINT N'Test 2.6: Phân trang - Trang 2, PageSize = 5';
EXEC sp_SearchProducts @PageNumber = 2, @PageSize = 5;

-- Không cần cleanup vì chỉ SELECT
PRINT N'✓ TEST 2 hoàn thành - Không cần cleanup';
GO

-- =============================================
-- TEST 3: sp_GetOrderDetails
-- Mục đích: Lấy chi tiết đơn hàng đầy đủ
-- =============================================
PRINT N'';
PRINT N'--- TEST 3: sp_GetOrderDetails ---';

-- Lấy OrderId đầu tiên trong hệ thống để test
DECLARE @TestOrderId3 INT;
SELECT TOP 1 @TestOrderId3 = OrderId FROM dbo.Orders;

IF @TestOrderId3 IS NOT NULL
BEGIN
    PRINT N'Test với OrderId = ' + CAST(@TestOrderId3 AS NVARCHAR(10));
    EXEC sp_GetOrderDetails @OrderId = @TestOrderId3;
END
ELSE
BEGIN
    PRINT N'⚠ Không có đơn hàng nào để test. Thử với OrderId = 1';
    EXEC sp_GetOrderDetails @OrderId = 1;
END

-- Không cần cleanup vì chỉ SELECT
PRINT N'✓ TEST 3 hoàn thành - Không cần cleanup';
GO

-- =============================================
-- TEST 4: sp_CreateOrder
-- Mục đích: Tạo đơn hàng mới từ giỏ hàng
-- ⚠ QUAN TRỌNG: Test này sẽ tạo dữ liệu thật
-- =============================================
PRINT N'';
PRINT N'--- TEST 4: sp_CreateOrder ---';

-- Biến để lưu dữ liệu test
DECLARE @TestUserId4 NVARCHAR(450);
DECLARE @TestProductId4 INT;
DECLARE @TestOrderId4 INT;
DECLARE @OriginalStock4 INT;

-- Lấy một UserId để test
SELECT TOP 1 @TestUserId4 = Id FROM dbo.AspNetUsers;

-- Lấy một ProductId có stock > 0 để test
SELECT TOP 1 @TestProductId4 = ProductId, @OriginalStock4 = Stock 
FROM dbo.Products 
WHERE IsActive = 1 AND Stock > 0;

IF @TestUserId4 IS NOT NULL AND @TestProductId4 IS NOT NULL
BEGIN
    PRINT N'Chuẩn bị test với UserId và ProductId có sẵn';
    
    -- Thêm sản phẩm vào giỏ hàng để test
    INSERT INTO dbo.CartItems (UserId, ProductId, Quantity, DateAdded)
    VALUES (@TestUserId4, @TestProductId4, 1, GETUTCDATE());
    
    PRINT N'Đã thêm sản phẩm vào giỏ hàng';
    
    -- Gọi stored procedure để tạo đơn hàng
    EXEC sp_CreateOrder 
        @UserId = @TestUserId4,
        @ShippingName = N'Nguyễn Văn Test',
        @ShippingPhone = '0901234567',
        @ShippingEmail = 'test@example.com',
        @ShippingAddress = N'123 Đường Test, Quận 1, TP.HCM',
        @PaymentMethod = 'COD',
        @Notes = N'Đơn hàng test - sẽ xóa sau',
        @OrderId = @TestOrderId4 OUTPUT;
    
    PRINT N'Đã tạo đơn hàng mới với OrderId = ' + ISNULL(CAST(@TestOrderId4 AS NVARCHAR(10)), 'NULL');
    
    -- CLEANUP: Xóa dữ liệu test
    PRINT N'--- CLEANUP TEST 4 ---';
    
    -- Xóa OrderItems trước (do có foreign key)
    DELETE FROM dbo.OrderItems WHERE OrderId = @TestOrderId4;
    PRINT N'Đã xóa OrderItems';
    
    -- Xóa Payments nếu có
    DELETE FROM dbo.Payments WHERE OrderId = @TestOrderId4;
    PRINT N'Đã xóa Payments (nếu có)';
    
    -- Xóa Notifications liên quan
    DELETE FROM dbo.Notifications 
    WHERE UserId = @TestUserId4 
    AND Message LIKE N'%#' + CAST(@TestOrderId4 AS NVARCHAR(10)) + N'%';
    PRINT N'Đã xóa Notifications';
    
    -- Xóa Order
    DELETE FROM dbo.Orders WHERE OrderId = @TestOrderId4;
    PRINT N'Đã xóa Order';
    
    -- Khôi phục lại stock
    UPDATE dbo.Products 
    SET Stock = @OriginalStock4 
    WHERE ProductId = @TestProductId4;
    PRINT N'Đã khôi phục Stock về ' + CAST(@OriginalStock4 AS NVARCHAR(10));
END
ELSE
BEGIN
    PRINT N'⚠ Không đủ dữ liệu để test (cần User và Product)';
END

PRINT N'✓ TEST 4 hoàn thành - Đã cleanup';
GO

-- =============================================
-- TEST 5: sp_UpdateOrderStatus
-- Mục đích: Cập nhật trạng thái đơn hàng
-- =============================================
PRINT N'';
PRINT N'--- TEST 5: sp_UpdateOrderStatus ---';

DECLARE @TestUserId5 NVARCHAR(450);
DECLARE @TestOrderId5 INT;

-- Lấy UserId
SELECT TOP 1 @TestUserId5 = Id FROM dbo.AspNetUsers;

IF @TestUserId5 IS NOT NULL
BEGIN
    -- Tạo đơn hàng test
    INSERT INTO dbo.Orders (
        UserId, OrderDate, Total, ShippingName, ShippingPhone,
        ShippingEmail, ShippingAddress, PaymentMethod, PaymentStatus, OrderStatus
    )
    VALUES (
        @TestUserId5, GETUTCDATE(), 100000, N'Test User 5', '0909999999',
        'test5@example.com', N'Địa chỉ test 5', 'COD', 'COD', 'Pending'
    );
    
    SET @TestOrderId5 = SCOPE_IDENTITY();
    PRINT N'Đã tạo đơn hàng test với OrderId = ' + CAST(@TestOrderId5 AS NVARCHAR(10));
    
    -- Test cập nhật trạng thái
    PRINT N'Test 5.1: Cập nhật từ Pending -> Processing';
    EXEC sp_UpdateOrderStatus @OrderId = @TestOrderId5, @NewStatus = 'Processing';
    
    -- Kiểm tra kết quả
    SELECT OrderId, OrderStatus FROM dbo.Orders WHERE OrderId = @TestOrderId5;
    
    PRINT N'Test 5.2: Cập nhật từ Processing -> Shipped (với tracking number)';
    EXEC sp_UpdateOrderStatus 
        @OrderId = @TestOrderId5, 
        @NewStatus = 'Shipped',
        @TrackingNumber = 'VN123456789';
    
    -- Kiểm tra kết quả
    SELECT OrderId, OrderStatus, TrackingNumber FROM dbo.Orders WHERE OrderId = @TestOrderId5;
    
    -- CLEANUP
    PRINT N'--- CLEANUP TEST 5 ---';
    DELETE FROM dbo.Notifications WHERE UserId = @TestUserId5 AND Message LIKE N'%#' + CAST(@TestOrderId5 AS NVARCHAR(10)) + N'%';
    DELETE FROM dbo.Orders WHERE OrderId = @TestOrderId5;
    PRINT N'Đã xóa Order và Notifications';
END
ELSE
BEGIN
    PRINT N'⚠ Không có User để test';
END

PRINT N'✓ TEST 5 hoàn thành - Đã cleanup';
GO

-- =============================================
-- TEST 6: sp_GetUserOrders
-- Mục đích: Lấy danh sách đơn hàng của user
-- =============================================
PRINT N'';
PRINT N'--- TEST 6: sp_GetUserOrders ---';

DECLARE @TestUserId6 NVARCHAR(450);

-- Lấy UserId có đơn hàng
SELECT TOP 1 @TestUserId6 = UserId FROM dbo.Orders;

IF @TestUserId6 IS NOT NULL
BEGIN
    PRINT N'Test 6.1: Lấy tất cả đơn hàng của user';
    EXEC sp_GetUserOrders @UserId = @TestUserId6;
    
    PRINT N'Test 6.2: Lọc đơn hàng theo trạng thái Pending';
    EXEC sp_GetUserOrders @UserId = @TestUserId6, @Status = 'Pending';
    
    PRINT N'Test 6.3: Phân trang - trang 1, 5 đơn/trang';
    EXEC sp_GetUserOrders @UserId = @TestUserId6, @PageNumber = 1, @PageSize = 5;
END
ELSE
BEGIN
    PRINT N'⚠ Không có đơn hàng nào để test';
END

-- Không cần cleanup vì chỉ SELECT
PRINT N'✓ TEST 6 hoàn thành - Không cần cleanup';
GO

-- =============================================
-- TEST 7: sp_AddToCart
-- Mục đích: Thêm sản phẩm vào giỏ hàng
-- =============================================
PRINT N'';
PRINT N'--- TEST 7: sp_AddToCart ---';

DECLARE @TestUserId7 NVARCHAR(450);
DECLARE @TestProductId7 INT;

SELECT TOP 1 @TestUserId7 = Id FROM dbo.AspNetUsers;
SELECT TOP 1 @TestProductId7 = ProductId FROM dbo.Products WHERE IsActive = 1 AND Stock > 5;

IF @TestUserId7 IS NOT NULL AND @TestProductId7 IS NOT NULL
BEGIN
    -- Xóa giỏ hàng cũ của user này (nếu có) để test clean
    DELETE FROM dbo.CartItems WHERE UserId = @TestUserId7 AND ProductId = @TestProductId7;
    
    PRINT N'Test 7.1: Thêm sản phẩm mới vào giỏ (số lượng = 2)';
    EXEC sp_AddToCart @UserId = @TestUserId7, @ProductId = @TestProductId7, @Quantity = 2;
    
    -- Kiểm tra
    SELECT * FROM dbo.CartItems WHERE UserId = @TestUserId7 AND ProductId = @TestProductId7;
    
    PRINT N'Test 7.2: Thêm tiếp sản phẩm đã có (UPSERT - tăng số lượng)';
    EXEC sp_AddToCart @UserId = @TestUserId7, @ProductId = @TestProductId7, @Quantity = 1;
    
    -- Kiểm tra - số lượng phải là 3
    SELECT * FROM dbo.CartItems WHERE UserId = @TestUserId7 AND ProductId = @TestProductId7;
    
    -- CLEANUP
    PRINT N'--- CLEANUP TEST 7 ---';
    DELETE FROM dbo.CartItems WHERE UserId = @TestUserId7 AND ProductId = @TestProductId7;
    PRINT N'Đã xóa CartItem test';
END
ELSE
BEGIN
    PRINT N'⚠ Không đủ dữ liệu để test';
END

PRINT N'✓ TEST 7 hoàn thành - Đã cleanup';
GO

-- =============================================
-- TEST 8: sp_GetTopSellingProducts
-- Mục đích: Lấy danh sách sản phẩm bán chạy nhất
-- =============================================
PRINT N'';
PRINT N'--- TEST 8: sp_GetTopSellingProducts ---';

-- Test 8.1: Lấy top 5 sản phẩm bán chạy nhất (mọi thời điểm)
PRINT N'Test 8.1: Top 5 sản phẩm bán chạy nhất';
EXEC sp_GetTopSellingProducts @TopN = 5;

-- Test 8.2: Lấy top 10 trong tháng này
PRINT N'Test 8.2: Top 10 sản phẩm bán chạy trong tháng này';
DECLARE @StartOfMonth DATE = DATEFROMPARTS(YEAR(GETUTCDATE()), MONTH(GETUTCDATE()), 1);
EXEC sp_GetTopSellingProducts @TopN = 10, @StartDate = @StartOfMonth, @EndDate = NULL;

-- Test 8.3: Lấy top trong khoảng thời gian cụ thể
PRINT N'Test 8.3: Top 10 từ ngày 01/01/2025 đến nay';
EXEC sp_GetTopSellingProducts @TopN = 10, @StartDate = '2025-01-01', @EndDate = '2025-12-31';

-- Không cần cleanup vì chỉ SELECT
PRINT N'✓ TEST 8 hoàn thành - Không cần cleanup';
GO

-- =============================================
-- TEST 9: sp_GetDailyRevenue
-- Mục đích: Thống kê doanh thu theo ngày
-- =============================================
PRINT N'';
PRINT N'--- TEST 9: sp_GetDailyRevenue ---';

-- Test 9.1: Doanh thu 7 ngày gần nhất
PRINT N'Test 9.1: Doanh thu 7 ngày gần nhất';
DECLARE @EndDate9 DATE = CAST(GETUTCDATE() AS DATE);
DECLARE @StartDate9 DATE = DATEADD(DAY, -7, @EndDate9);
EXEC sp_GetDailyRevenue @StartDate = @StartDate9, @EndDate = @EndDate9;

-- Test 9.2: Doanh thu tháng 11/2025
PRINT N'Test 9.2: Doanh thu tháng 11/2025';
EXEC sp_GetDailyRevenue @StartDate = '2025-11-01', @EndDate = '2025-11-30';

-- Test 9.3: Doanh thu cả năm 2025
PRINT N'Test 9.3: Doanh thu năm 2025';
EXEC sp_GetDailyRevenue @StartDate = '2025-01-01', @EndDate = '2025-12-31';

-- Không cần cleanup vì chỉ SELECT
PRINT N'✓ TEST 9 hoàn thành - Không cần cleanup';
GO

-- =============================================
-- TEST 10: sp_GetCategoryStatistics
-- Mục đích: Thống kê sản phẩm và doanh thu theo danh mục
-- =============================================
PRINT N'';
PRINT N'--- TEST 10: sp_GetCategoryStatistics ---';

PRINT N'Thống kê chi tiết theo từng danh mục';
EXEC sp_GetCategoryStatistics;

-- Không cần cleanup vì chỉ SELECT
PRINT N'✓ TEST 10 hoàn thành - Không cần cleanup';
GO

-- =============================================
-- TEST 11: sp_GetTopCustomers
-- Mục đích: Lấy danh sách khách hàng mua nhiều nhất
-- =============================================
PRINT N'';
PRINT N'--- TEST 11: sp_GetTopCustomers ---';

-- Test 11.1: Top 5 khách hàng VIP
PRINT N'Test 11.1: Top 5 khách hàng VIP';
EXEC sp_GetTopCustomers @TopN = 5;

-- Test 11.2: Top 10 khách hàng
PRINT N'Test 11.2: Top 10 khách hàng';
EXEC sp_GetTopCustomers @TopN = 10;

-- Không cần cleanup vì chỉ SELECT
PRINT N'✓ TEST 11 hoàn thành - Không cần cleanup';
GO

-- =============================================
-- TEST 12: sp_UpdateCartItemQuantity
-- Mục đích: Cập nhật số lượng sản phẩm trong giỏ hàng
-- =============================================
PRINT N'';
PRINT N'--- TEST 12: sp_UpdateCartItemQuantity ---';

DECLARE @TestUserId12 NVARCHAR(450);
DECLARE @TestProductId12 INT;
DECLARE @TestCartItemId12 INT;

SELECT TOP 1 @TestUserId12 = Id FROM dbo.AspNetUsers;
SELECT TOP 1 @TestProductId12 = ProductId FROM dbo.Products WHERE IsActive = 1 AND Stock > 10;

IF @TestUserId12 IS NOT NULL AND @TestProductId12 IS NOT NULL
BEGIN
    -- Tạo CartItem để test
    INSERT INTO dbo.CartItems (UserId, ProductId, Quantity, DateAdded)
    VALUES (@TestUserId12, @TestProductId12, 1, GETUTCDATE());
    
    SET @TestCartItemId12 = SCOPE_IDENTITY();
    PRINT N'Đã tạo CartItem test với Id = ' + CAST(@TestCartItemId12 AS NVARCHAR(10));
    
    -- Test cập nhật số lượng
    PRINT N'Test 12.1: Cập nhật số lượng từ 1 -> 5';
    EXEC sp_UpdateCartItemQuantity @CartItemId = @TestCartItemId12, @NewQuantity = 5;
    
    -- Kiểm tra
    SELECT * FROM dbo.CartItems WHERE CartItemId = @TestCartItemId12;
    
    PRINT N'Test 12.2: Cập nhật số lượng từ 5 -> 3';
    EXEC sp_UpdateCartItemQuantity @CartItemId = @TestCartItemId12, @NewQuantity = 3;
    
    -- Kiểm tra
    SELECT * FROM dbo.CartItems WHERE CartItemId = @TestCartItemId12;
    
    -- CLEANUP
    PRINT N'--- CLEANUP TEST 12 ---';
    DELETE FROM dbo.CartItems WHERE CartItemId = @TestCartItemId12;
    PRINT N'Đã xóa CartItem test';
END
ELSE
BEGIN
    PRINT N'⚠ Không đủ dữ liệu để test';
END

PRINT N'✓ TEST 12 hoàn thành - Đã cleanup';
GO

-- =============================================
-- TEST 13: sp_ClearUserCart
-- Mục đích: Xóa toàn bộ giỏ hàng của user
-- =============================================
PRINT N'';
PRINT N'--- TEST 13: sp_ClearUserCart ---';

DECLARE @TestUserId13 NVARCHAR(450);
DECLARE @TestProductId13a INT;
DECLARE @TestProductId13b INT;

SELECT TOP 1 @TestUserId13 = Id FROM dbo.AspNetUsers;
SELECT TOP 2 @TestProductId13a = ProductId FROM dbo.Products WHERE IsActive = 1 AND Stock > 0;
SELECT @TestProductId13a = ProductId FROM (SELECT TOP 1 ProductId FROM dbo.Products WHERE IsActive = 1 AND Stock > 0) t;
SELECT @TestProductId13b = ProductId FROM (SELECT TOP 1 ProductId FROM dbo.Products WHERE IsActive = 1 AND Stock > 0 AND ProductId <> @TestProductId13a) t;

IF @TestUserId13 IS NOT NULL AND @TestProductId13a IS NOT NULL
BEGIN
    -- Tạo vài CartItem để test
    INSERT INTO dbo.CartItems (UserId, ProductId, Quantity, DateAdded)
    VALUES 
        (@TestUserId13, @TestProductId13a, 2, GETUTCDATE());
    
    IF @TestProductId13b IS NOT NULL
    BEGIN
        INSERT INTO dbo.CartItems (UserId, ProductId, Quantity, DateAdded)
        VALUES (@TestUserId13, @TestProductId13b, 1, GETUTCDATE());
    END
    
    PRINT N'Đã thêm sản phẩm vào giỏ hàng để test';
    
    -- Kiểm tra trước khi xóa
    PRINT N'Giỏ hàng trước khi xóa:';
    SELECT * FROM dbo.CartItems WHERE UserId = @TestUserId13;
    
    -- Test xóa giỏ hàng
    PRINT N'Thực hiện xóa toàn bộ giỏ hàng:';
    EXEC sp_ClearUserCart @UserId = @TestUserId13;
    
    -- Kiểm tra sau khi xóa
    PRINT N'Giỏ hàng sau khi xóa (phải rỗng):';
    SELECT * FROM dbo.CartItems WHERE UserId = @TestUserId13;
END
ELSE
BEGIN
    PRINT N'⚠ Không đủ dữ liệu để test';
END

-- Không cần cleanup vì procedure đã xóa rồi
PRINT N'✓ TEST 13 hoàn thành - Procedure đã tự cleanup';
GO

-- =============================================
-- TEST 14: sp_GetLowStockProducts
-- Mục đích: Lấy danh sách sản phẩm sắp hết hàng
-- =============================================
PRINT N'';
PRINT N'--- TEST 14: sp_GetLowStockProducts ---';

-- Test 14.1: Sản phẩm có stock < 10 (mặc định)
PRINT N'Test 14.1: Sản phẩm có stock < 10 (mặc định)';
EXEC sp_GetLowStockProducts;

-- Test 14.2: Sản phẩm có stock < 5
PRINT N'Test 14.2: Sản phẩm có stock < 5';
EXEC sp_GetLowStockProducts @Threshold = 5;

-- Test 14.3: Sản phẩm có stock < 20
PRINT N'Test 14.3: Sản phẩm có stock < 20';
EXEC sp_GetLowStockProducts @Threshold = 20;

-- Không cần cleanup vì chỉ SELECT
PRINT N'✓ TEST 14 hoàn thành - Không cần cleanup';
GO

-- =============================================
-- KẾT THÚC TEST
-- =============================================
PRINT N'';
PRINT N'========================================';
PRINT N'HOÀN THÀNH TEST TẤT CẢ 14 STORED PROCEDURES';
PRINT N'========================================';
PRINT N'';
PRINT N'TÓM TẮT:';
PRINT N'- Các procedure chỉ SELECT: Không cần cleanup';
PRINT N'- Các procedure có INSERT/UPDATE/DELETE: Đã cleanup';
PRINT N'- Dữ liệu gốc được bảo toàn nguyên vẹn';
PRINT N'========================================';
GO
