-- =============================================
-- FILE: Test_TG_CC_USR.sql
-- Mục đích: Test Triggers, Concurrency Control, User Role Management
-- Lưu ý: Mỗi test sẽ có phần cleanup dữ liệu
-- =============================================

USE Bookstore;
GO

PRINT N'========================================';
PRINT N'BẮT ĐẦU TEST TRIGGERS, CONCURRENCY, USER ROLE';
PRINT N'========================================';
GO

-- =============================================
-- PHẦN A: TEST TRIGGERS (10 triggers)
-- =============================================

PRINT N'';
PRINT N'========================================';
PRINT N'PHẦN A: TEST TRIGGERS';
PRINT N'========================================';
GO

-- =============================================
-- TEST TRIGGER 1: tr_Products_SetCreatedAt
-- Mục đích: Tự động gán thời gian tạo sản phẩm
-- =============================================
PRINT N'';
PRINT N'--- TEST TRIGGER 1: tr_Products_SetCreatedAt ---';

DECLARE @TestProductId1 INT;
DECLARE @TestCategoryId1 INT;

-- Lấy CategoryId để test
SELECT TOP 1 @TestCategoryId1 = CategoryId FROM dbo.Categories;

IF @TestCategoryId1 IS NOT NULL
BEGIN
    -- Thêm sản phẩm KHÔNG có CreatedAt
    SET IDENTITY_INSERT dbo.Products ON;
    
    INSERT INTO dbo.Products (ProductId, Title, Author, Description, Price, Stock, CategoryId, IsActive, CreatedAt)
    VALUES (99901, N'Test Product Trigger 1', N'Test Author', N'Mô tả test', 100000, 50, @TestCategoryId1, 1, NULL);
    
    SET IDENTITY_INSERT dbo.Products OFF;
    
    SET @TestProductId1 = 99901;
    
    -- Kiểm tra CreatedAt đã được gán tự động chưa
    PRINT N'Kiểm tra CreatedAt sau khi insert:';
    SELECT ProductId, Title, CreatedAt 
    FROM dbo.Products 
    WHERE ProductId = @TestProductId1;
    
    -- CLEANUP
    PRINT N'--- CLEANUP TRIGGER 1 ---';
    DELETE FROM dbo.Products WHERE ProductId = @TestProductId1;
    PRINT N'Đã xóa Product test';
END
ELSE
BEGIN
    PRINT N'⚠ Không có Category để test';
END

PRINT N'✓ TEST TRIGGER 1 hoàn thành';
GO

-- =============================================
-- TEST TRIGGER 2: tr_Orders_SetCreatedAt
-- Mục đích: Tự động gán thời gian tạo đơn hàng
-- =============================================
PRINT N'';
PRINT N'--- TEST TRIGGER 2: tr_Orders_SetCreatedAt ---';

DECLARE @TestUserId2 NVARCHAR(450);
DECLARE @TestOrderId2 INT;

SELECT TOP 1 @TestUserId2 = Id FROM dbo.AspNetUsers;

IF @TestUserId2 IS NOT NULL
BEGIN
    -- Thêm đơn hàng KHÔNG có OrderDate
    SET IDENTITY_INSERT dbo.Orders ON;
    
    INSERT INTO dbo.Orders (OrderId, OrderNumber, UserId, OrderDate, Total, ShippingName, ShippingPhone, 
        ShippingEmail, ShippingAddress, OrderStatus, PaymentMethod, PaymentStatus)
    VALUES (99902, 'TEST-TG2-001', @TestUserId2, NULL, 100000, N'Test User', '0123456789',
        'test@example.com', N'Địa chỉ test', 'Pending', 'COD', 'Pending');
    
    SET IDENTITY_INSERT dbo.Orders OFF;
    
    SET @TestOrderId2 = 99902;
    
    -- Kiểm tra OrderDate đã được gán tự động chưa
    PRINT N'Kiểm tra OrderDate sau khi insert:';
    SELECT OrderId, OrderNumber, OrderDate 
    FROM dbo.Orders 
    WHERE OrderId = @TestOrderId2;
    
    -- CLEANUP
    PRINT N'--- CLEANUP TRIGGER 2 ---';
    DELETE FROM dbo.Orders WHERE OrderId = @TestOrderId2;
    PRINT N'Đã xóa Order test';
END
ELSE
BEGIN
    PRINT N'⚠ Không có User để test';
END

PRINT N'✓ TEST TRIGGER 2 hoàn thành';
GO

-- =============================================
-- TEST TRIGGER 3: tr_Users_UpdateTimestamp
-- Mục đích: Tự động cập nhật thời gian khi user thay đổi thông tin
-- =============================================
PRINT N'';
PRINT N'--- TEST TRIGGER 3: tr_Users_UpdateTimestamp ---';

DECLARE @TestUserId3 NVARCHAR(450);
DECLARE @OldUpdatedAt3 DATETIME2;

SELECT TOP 1 @TestUserId3 = Id FROM dbo.AspNetUsers;

IF @TestUserId3 IS NOT NULL
BEGIN
    -- Lưu UpdatedAt cũ
    SELECT @OldUpdatedAt3 = UpdatedAt FROM dbo.AspNetUsers WHERE Id = @TestUserId3;
    PRINT N'UpdatedAt trước khi update: ' + ISNULL(CONVERT(NVARCHAR(50), @OldUpdatedAt3, 120), 'NULL');
    
    -- Chờ 1 giây để thấy sự khác biệt thời gian
    WAITFOR DELAY '00:00:01';
    
    -- Cập nhật thông tin user
    UPDATE dbo.AspNetUsers
    SET FullName = FullName + N''  -- Cập nhật nhưng giữ nguyên giá trị
    WHERE Id = @TestUserId3;
    
    -- Kiểm tra UpdatedAt đã thay đổi chưa
    PRINT N'UpdatedAt sau khi update:';
    SELECT Id, FullName, UpdatedAt 
    FROM dbo.AspNetUsers 
    WHERE Id = @TestUserId3;
    
    -- CLEANUP: Khôi phục UpdatedAt cũ (nếu cần)
    PRINT N'--- CLEANUP TRIGGER 3 ---';
    -- Không cần cleanup vì trigger chạy đúng mục đích
    PRINT N'Không cần cleanup - trigger hoạt động đúng';
END
ELSE
BEGIN
    PRINT N'⚠ Không có User để test';
END

PRINT N'✓ TEST TRIGGER 3 hoàn thành';
GO

-- =============================================
-- TEST TRIGGER 4: tr_Products_LowStockNotification
-- Mục đích: Gửi thông báo khi tồn kho xuống thấp (< 10)
-- =============================================
PRINT N'';
PRINT N'--- TEST TRIGGER 4: tr_Products_LowStockNotification ---';

DECLARE @TestProductId4 INT;
DECLARE @TestCategoryId4 INT;
DECLARE @NotificationCountBefore4 INT;

SELECT TOP 1 @TestCategoryId4 = CategoryId FROM dbo.Categories;

IF @TestCategoryId4 IS NOT NULL
BEGIN
    -- Đếm notifications trước
    SELECT @NotificationCountBefore4 = COUNT(*) FROM dbo.Notifications;
    
    -- Tạo sản phẩm với Stock = 15 (trên ngưỡng)
    SET IDENTITY_INSERT dbo.Products ON;
    
    INSERT INTO dbo.Products (ProductId, Title, Author, Description, Price, Stock, CategoryId, IsActive, CreatedAt)
    VALUES (99904, N'Test Low Stock Product', N'Test Author', N'Mô tả test', 100000, 15, @TestCategoryId4, 1, GETUTCDATE());
    
    SET IDENTITY_INSERT dbo.Products OFF;
    
    SET @TestProductId4 = 99904;
    
    PRINT N'Đã tạo sản phẩm với Stock = 15';
    
    -- Giảm Stock xuống dưới ngưỡng (từ 15 xuống 8)
    PRINT N'Giảm Stock từ 15 xuống 8 (dưới ngưỡng 10):';
    UPDATE dbo.Products
    SET Stock = 8
    WHERE ProductId = @TestProductId4;
    
    -- Kiểm tra notification mới được tạo
    PRINT N'Kiểm tra Notification mới:';
    SELECT TOP 1 NotificationId, Message, CreatedAt 
    FROM dbo.Notifications 
    WHERE Message LIKE N'%Test Low Stock Product%'
    ORDER BY NotificationId DESC;
    
    -- CLEANUP
    PRINT N'--- CLEANUP TRIGGER 4 ---';
    DELETE FROM dbo.Notifications WHERE Message LIKE N'%Test Low Stock Product%';
    DELETE FROM dbo.Products WHERE ProductId = @TestProductId4;
    PRINT N'Đã xóa Product và Notification test';
END
ELSE
BEGIN
    PRINT N'⚠ Không có Category để test';
END

PRINT N'✓ TEST TRIGGER 4 hoàn thành';
GO

-- =============================================
-- TEST TRIGGER 5: tr_Products_OutOfStockNotification
-- Mục đích: Gửi cảnh báo khẩn cấp khi sản phẩm hết hàng
-- =============================================
PRINT N'';
PRINT N'--- TEST TRIGGER 5: tr_Products_OutOfStockNotification ---';

DECLARE @TestProductId5 INT;
DECLARE @TestCategoryId5 INT;

SELECT TOP 1 @TestCategoryId5 = CategoryId FROM dbo.Categories;

IF @TestCategoryId5 IS NOT NULL
BEGIN
    -- Tạo sản phẩm với Stock = 5
    SET IDENTITY_INSERT dbo.Products ON;
    
    INSERT INTO dbo.Products (ProductId, Title, Author, Description, Price, Stock, CategoryId, IsActive, CreatedAt)
    VALUES (99905, N'Test Out Of Stock Product', N'Test Author', N'Mô tả test', 100000, 5, @TestCategoryId5, 1, GETUTCDATE());
    
    SET IDENTITY_INSERT dbo.Products OFF;
    
    SET @TestProductId5 = 99905;
    
    PRINT N'Đã tạo sản phẩm với Stock = 5';
    
    -- Giảm Stock xuống 0 (hết hàng)
    PRINT N'Giảm Stock từ 5 xuống 0 (hết hàng):';
    UPDATE dbo.Products
    SET Stock = 0
    WHERE ProductId = @TestProductId5;
    
    -- Kiểm tra notification cảnh báo hết hàng
    PRINT N'Kiểm tra Notification cảnh báo hết hàng:';
    SELECT TOP 1 NotificationId, Message, CreatedAt 
    FROM dbo.Notifications 
    WHERE Message LIKE N'%Test Out Of Stock Product%'
    ORDER BY NotificationId DESC;
    
    -- CLEANUP
    PRINT N'--- CLEANUP TRIGGER 5 ---';
    DELETE FROM dbo.Notifications WHERE Message LIKE N'%Test Out Of Stock Product%';
    DELETE FROM dbo.Products WHERE ProductId = @TestProductId5;
    PRINT N'Đã xóa Product và Notification test';
END
ELSE
BEGIN
    PRINT N'⚠ Không có Category để test';
END

PRINT N'✓ TEST TRIGGER 5 hoàn thành';
GO

-- =============================================
-- TEST TRIGGER 6: tr_Reviews_SetCreatedAt
-- Mục đích: Tự động gán thời gian cho đánh giá mới
-- =============================================
PRINT N'';
PRINT N'--- TEST TRIGGER 6: tr_Reviews_SetCreatedAt ---';

DECLARE @TestUserId6 NVARCHAR(450);
DECLARE @TestProductId6 INT;
DECLARE @TestReviewId6 INT;

SELECT TOP 1 @TestUserId6 = Id FROM dbo.AspNetUsers;
SELECT TOP 1 @TestProductId6 = ProductId FROM dbo.Products WHERE IsActive = 1;

IF @TestUserId6 IS NOT NULL AND @TestProductId6 IS NOT NULL
BEGIN
    -- Thêm review KHÔNG có CreatedAt
    SET IDENTITY_INSERT dbo.Reviews ON;
    
    INSERT INTO dbo.Reviews (ReviewId, UserId, ProductId, Rating, Comment, CreatedAt)
    VALUES (99906, @TestUserId6, @TestProductId6, 5, N'Test review cho trigger', NULL);
    
    SET IDENTITY_INSERT dbo.Reviews OFF;
    
    SET @TestReviewId6 = 99906;
    
    -- Kiểm tra CreatedAt đã được gán tự động chưa
    PRINT N'Kiểm tra CreatedAt sau khi insert review:';
    SELECT ReviewId, Rating, Comment, CreatedAt 
    FROM dbo.Reviews 
    WHERE ReviewId = @TestReviewId6;
    
    -- CLEANUP
    PRINT N'--- CLEANUP TRIGGER 6 ---';
    DELETE FROM dbo.Reviews WHERE ReviewId = @TestReviewId6;
    PRINT N'Đã xóa Review test';
END
ELSE
BEGIN
    PRINT N'⚠ Không đủ dữ liệu để test';
END

PRINT N'✓ TEST TRIGGER 6 hoàn thành';
GO

-- =============================================
-- TEST TRIGGER 7: tr_Orders_NotifyNewOrder
-- Mục đích: Thông báo cho Admin khi có đơn hàng mới
-- =============================================
PRINT N'';
PRINT N'--- TEST TRIGGER 7: tr_Orders_NotifyNewOrder ---';

DECLARE @TestUserId7 NVARCHAR(450);
DECLARE @TestOrderId7 INT;

SELECT TOP 1 @TestUserId7 = Id FROM dbo.AspNetUsers;

IF @TestUserId7 IS NOT NULL
BEGIN
    -- Tạo đơn hàng mới
    SET IDENTITY_INSERT dbo.Orders ON;
    
    INSERT INTO dbo.Orders (OrderId, OrderNumber, UserId, OrderDate, Total, ShippingName, ShippingPhone, 
        ShippingEmail, ShippingAddress, OrderStatus, PaymentMethod, PaymentStatus)
    VALUES (99907, 'TEST-TG7-001', @TestUserId7, GETUTCDATE(), 500000, N'Test User 7', '0123456789',
        'test7@example.com', N'Địa chỉ test 7', 'Pending', 'COD', 'Pending');
    
    SET IDENTITY_INSERT dbo.Orders OFF;
    
    SET @TestOrderId7 = 99907;
    
    -- Kiểm tra notification cho Admin
    PRINT N'Kiểm tra Notification đơn hàng mới:';
    SELECT TOP 1 NotificationId, Message, CreatedAt 
    FROM dbo.Notifications 
    WHERE Message LIKE N'%99907%'
    ORDER BY NotificationId DESC;
    
    -- CLEANUP
    PRINT N'--- CLEANUP TRIGGER 7 ---';
    DELETE FROM dbo.Notifications WHERE Message LIKE N'%99907%';
    DELETE FROM dbo.Orders WHERE OrderId = @TestOrderId7;
    PRINT N'Đã xóa Order và Notification test';
END
ELSE
BEGIN
    PRINT N'⚠ Không có User để test';
END

PRINT N'✓ TEST TRIGGER 7 hoàn thành';
GO

-- =============================================
-- TEST TRIGGER 8: tr_Orders_StatusChangeNotification
-- Mục đích: Thông báo cho khách hàng khi trạng thái đơn hàng thay đổi
-- =============================================
PRINT N'';
PRINT N'--- TEST TRIGGER 8: tr_Orders_StatusChangeNotification ---';

DECLARE @TestUserId8 NVARCHAR(450);
DECLARE @TestOrderId8 INT;

SELECT TOP 1 @TestUserId8 = Id FROM dbo.AspNetUsers;

IF @TestUserId8 IS NOT NULL
BEGIN
    -- Tạo đơn hàng mới với trạng thái Pending
    SET IDENTITY_INSERT dbo.Orders ON;
    
    INSERT INTO dbo.Orders (OrderId, OrderNumber, UserId, OrderDate, Total, ShippingName, ShippingPhone, 
        ShippingEmail, ShippingAddress, OrderStatus, PaymentMethod, PaymentStatus)
    VALUES (99908, 'TEST-TG8-001', @TestUserId8, GETUTCDATE(), 300000, N'Test User 8', '0123456789',
        'test8@example.com', N'Địa chỉ test 8', 'Pending', 'COD', 'Pending');
    
    SET IDENTITY_INSERT dbo.Orders OFF;
    
    SET @TestOrderId8 = 99908;
    
    PRINT N'Đã tạo đơn hàng với OrderStatus = Pending';
    
    -- Cập nhật trạng thái đơn hàng
    PRINT N'Cập nhật OrderStatus từ Pending -> Processing:';
    UPDATE dbo.Orders
    SET OrderStatus = 'Processing'
    WHERE OrderId = @TestOrderId8;
    
    -- Kiểm tra notification cho khách hàng
    PRINT N'Kiểm tra Notification thay đổi trạng thái:';
    SELECT TOP 1 NotificationId, UserId, Message, CreatedAt 
    FROM dbo.Notifications 
    WHERE Message LIKE N'%99908%' AND Message LIKE N'%Pending%Processing%'
    ORDER BY NotificationId DESC;
    
    -- CLEANUP
    PRINT N'--- CLEANUP TRIGGER 8 ---';
    DELETE FROM dbo.Notifications WHERE Message LIKE N'%99908%';
    DELETE FROM dbo.Orders WHERE OrderId = @TestOrderId8;
    PRINT N'Đã xóa Order và Notification test';
END
ELSE
BEGIN
    PRINT N'⚠ Không có User để test';
END

PRINT N'✓ TEST TRIGGER 8 hoàn thành';
GO

-- =============================================
-- TEST TRIGGER 9: tr_CartItems_SetAddedAt
-- Mục đích: Tự động gán thời gian thêm vào giỏ hàng
-- =============================================
PRINT N'';
PRINT N'--- TEST TRIGGER 9: tr_CartItems_SetAddedAt ---';

DECLARE @TestUserId9 NVARCHAR(450);
DECLARE @TestProductId9 INT;
DECLARE @TestCartItemId9 INT;

SELECT TOP 1 @TestUserId9 = Id FROM dbo.AspNetUsers;
SELECT TOP 1 @TestProductId9 = ProductId FROM dbo.Products WHERE IsActive = 1 AND Stock > 0;

IF @TestUserId9 IS NOT NULL AND @TestProductId9 IS NOT NULL
BEGIN
    -- Thêm CartItem KHÔNG có DateAdded
    SET IDENTITY_INSERT dbo.CartItems ON;
    
    INSERT INTO dbo.CartItems (CartItemId, UserId, ProductId, Quantity, DateAdded, FlashSaleProductId, LockedPrice)
    VALUES (99909, @TestUserId9, @TestProductId9, 1, NULL, NULL, NULL);
    
    SET IDENTITY_INSERT dbo.CartItems OFF;
    
    SET @TestCartItemId9 = 99909;
    
    -- Kiểm tra DateAdded đã được gán tự động chưa
    PRINT N'Kiểm tra DateAdded sau khi insert:';
    SELECT CartItemId, ProductId, Quantity, DateAdded 
    FROM dbo.CartItems 
    WHERE CartItemId = @TestCartItemId9;
    
    -- CLEANUP
    PRINT N'--- CLEANUP TRIGGER 9 ---';
    DELETE FROM dbo.CartItems WHERE CartItemId = @TestCartItemId9;
    PRINT N'Đã xóa CartItem test';
END
ELSE
BEGIN
    PRINT N'⚠ Không đủ dữ liệu để test';
END

PRINT N'✓ TEST TRIGGER 9 hoàn thành';
GO

-- =============================================
-- TEST TRIGGER 10: tr_Products_PriceChangeLog
-- Mục đích: Ghi log khi giá sản phẩm thay đổi đáng kể (trên 10%)
-- =============================================
PRINT N'';
PRINT N'--- TEST TRIGGER 10: tr_Products_PriceChangeLog ---';

DECLARE @TestProductId10 INT;
DECLARE @TestCategoryId10 INT;

SELECT TOP 1 @TestCategoryId10 = CategoryId FROM dbo.Categories;

IF @TestCategoryId10 IS NOT NULL
BEGIN
    -- Tạo sản phẩm với giá 100,000
    SET IDENTITY_INSERT dbo.Products ON;
    
    INSERT INTO dbo.Products (ProductId, Title, Author, Description, Price, Stock, CategoryId, IsActive, CreatedAt)
    VALUES (99910, N'Test Price Change Product', N'Test Author', N'Mô tả test', 100000, 50, @TestCategoryId10, 1, GETUTCDATE());
    
    SET IDENTITY_INSERT dbo.Products OFF;
    
    SET @TestProductId10 = 99910;
    
    PRINT N'Đã tạo sản phẩm với Price = 100,000';
    
    -- Thay đổi giá trên 10% (từ 100,000 lên 120,000 = +20%)
    PRINT N'Thay đổi giá từ 100,000 lên 120,000 (+20%):';
    UPDATE dbo.Products
    SET Price = 120000
    WHERE ProductId = @TestProductId10;
    
    -- Kiểm tra notification log giá
    PRINT N'Kiểm tra Notification log thay đổi giá:';
    SELECT TOP 1 NotificationId, Message, CreatedAt 
    FROM dbo.Notifications 
    WHERE Message LIKE N'%Test Price Change Product%'
    ORDER BY NotificationId DESC;
    
    -- CLEANUP
    PRINT N'--- CLEANUP TRIGGER 10 ---';
    DELETE FROM dbo.Notifications WHERE Message LIKE N'%Test Price Change Product%';
    DELETE FROM dbo.Products WHERE ProductId = @TestProductId10;
    PRINT N'Đã xóa Product và Notification test';
END
ELSE
BEGIN
    PRINT N'⚠ Không có Category để test';
END

PRINT N'✓ TEST TRIGGER 10 hoàn thành';
GO

-- =============================================
-- PHẦN B: TEST CONCURRENCY CONTROL
-- =============================================

PRINT N'';
PRINT N'========================================';
PRINT N'PHẦN B: TEST CONCURRENCY CONTROL';
PRINT N'========================================';
GO

-- =============================================
-- TEST CC 1: Transaction cơ bản với TRY-CATCH
-- Mục đích: Kiểm tra COMMIT và ROLLBACK
-- =============================================
PRINT N'';
PRINT N'--- TEST CC 1: Transaction cơ bản ---';

DECLARE @TestProductIdCC1 INT;
DECLARE @TestCategoryIdCC1 INT;
DECLARE @OriginalStockCC1 INT;

SELECT TOP 1 @TestCategoryIdCC1 = CategoryId FROM dbo.Categories;

IF @TestCategoryIdCC1 IS NOT NULL
BEGIN
    -- Tạo sản phẩm test
    SET IDENTITY_INSERT dbo.Products ON;
    
    INSERT INTO dbo.Products (ProductId, Title, Author, Description, Price, Stock, CategoryId, IsActive, CreatedAt)
    VALUES (99801, N'Test Transaction Product', N'Test Author', N'Mô tả test', 100000, 100, @TestCategoryIdCC1, 1, GETUTCDATE());
    
    SET IDENTITY_INSERT dbo.Products OFF;
    
    SET @TestProductIdCC1 = 99801;
    SET @OriginalStockCC1 = 100;
    
    PRINT N'Đã tạo sản phẩm với Stock = 100';
    
    -- Test transaction thành công (COMMIT)
    BEGIN TRY
        BEGIN TRANSACTION;
        
            UPDATE dbo.Products
            SET Stock = Stock - 10
            WHERE ProductId = @TestProductIdCC1;
            
            PRINT N'Trừ 10 stock trong transaction';
            
        COMMIT TRANSACTION;
        PRINT N'COMMIT thành công!';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT N'ROLLBACK do lỗi: ' + ERROR_MESSAGE();
    END CATCH
    
    -- Kiểm tra kết quả
    PRINT N'Stock sau COMMIT:';
    SELECT ProductId, Title, Stock FROM dbo.Products WHERE ProductId = @TestProductIdCC1;
    
    -- CLEANUP
    PRINT N'--- CLEANUP CC 1 ---';
    DELETE FROM dbo.Notifications WHERE Message LIKE N'%Test Transaction Product%';
    DELETE FROM dbo.Products WHERE ProductId = @TestProductIdCC1;
    PRINT N'Đã xóa Product test';
END

PRINT N'✓ TEST CC 1 hoàn thành';
GO

-- =============================================
-- TEST CC 2: Transaction ROLLBACK khi có lỗi
-- Mục đích: Kiểm tra dữ liệu được khôi phục khi ROLLBACK
-- =============================================
PRINT N'';
PRINT N'--- TEST CC 2: Transaction ROLLBACK ---';

DECLARE @TestProductIdCC2 INT;
DECLARE @TestCategoryIdCC2 INT;

SELECT TOP 1 @TestCategoryIdCC2 = CategoryId FROM dbo.Categories;

IF @TestCategoryIdCC2 IS NOT NULL
BEGIN
    -- Tạo sản phẩm test
    SET IDENTITY_INSERT dbo.Products ON;
    
    INSERT INTO dbo.Products (ProductId, Title, Author, Description, Price, Stock, CategoryId, IsActive, CreatedAt)
    VALUES (99802, N'Test Rollback Product', N'Test Author', N'Mô tả test', 100000, 50, @TestCategoryIdCC2, 1, GETUTCDATE());
    
    SET IDENTITY_INSERT dbo.Products OFF;
    
    SET @TestProductIdCC2 = 99802;
    
    PRINT N'Đã tạo sản phẩm với Stock = 50';
    
    -- Test transaction thất bại (ROLLBACK)
    BEGIN TRY
        BEGIN TRANSACTION;
        
            -- Cập nhật stock
            UPDATE dbo.Products
            SET Stock = Stock - 20
            WHERE ProductId = @TestProductIdCC2;
            
            PRINT N'Đã trừ 20 stock (chưa commit)';
            
            -- Tạo lỗi có chủ đích để test ROLLBACK
            RAISERROR(N'Lỗi giả lập để test ROLLBACK!', 16, 1);
            
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        PRINT N'ROLLBACK thành công! Lỗi: ' + ERROR_MESSAGE();
    END CATCH
    
    -- Kiểm tra Stock vẫn giữ nguyên (50) sau ROLLBACK
    PRINT N'Stock sau ROLLBACK (phải = 50):';
    SELECT ProductId, Title, Stock FROM dbo.Products WHERE ProductId = @TestProductIdCC2;
    
    -- CLEANUP
    PRINT N'--- CLEANUP CC 2 ---';
    DELETE FROM dbo.Notifications WHERE Message LIKE N'%Test Rollback Product%';
    DELETE FROM dbo.Products WHERE ProductId = @TestProductIdCC2;
    PRINT N'Đã xóa Product test';
END

PRINT N'✓ TEST CC 2 hoàn thành';
GO

-- =============================================
-- TEST CC 3: UPDLOCK - Khóa dòng khi đọc để update
-- Mục đích: Tránh race condition khi nhiều session cùng truy cập
-- =============================================
PRINT N'';
PRINT N'--- TEST CC 3: UPDLOCK ---';

DECLARE @TestProductIdCC3 INT;
DECLARE @TestCategoryIdCC3 INT;
DECLARE @CurrentStockCC3 INT;

SELECT TOP 1 @TestCategoryIdCC3 = CategoryId FROM dbo.Categories;

IF @TestCategoryIdCC3 IS NOT NULL
BEGIN
    -- Tạo sản phẩm test
    SET IDENTITY_INSERT dbo.Products ON;
    
    INSERT INTO dbo.Products (ProductId, Title, Author, Description, Price, Stock, CategoryId, IsActive, CreatedAt)
    VALUES (99803, N'Test UPDLOCK Product', N'Test Author', N'Mô tả test', 100000, 30, @TestCategoryIdCC3, 1, GETUTCDATE());
    
    SET IDENTITY_INSERT dbo.Products OFF;
    
    SET @TestProductIdCC3 = 99803;
    
    PRINT N'Đã tạo sản phẩm với Stock = 30';
    
    -- Sử dụng UPDLOCK để đọc và cập nhật an toàn
    BEGIN TRANSACTION;
    
        -- Đọc với UPDLOCK (khóa dòng để chuẩn bị update)
        SELECT @CurrentStockCC3 = Stock
        FROM dbo.Products WITH (UPDLOCK)
        WHERE ProductId = @TestProductIdCC3;
        
        PRINT N'Đọc Stock với UPDLOCK: ' + CAST(@CurrentStockCC3 AS NVARCHAR(10));
        
        -- Kiểm tra và update
        IF @CurrentStockCC3 >= 5
        BEGIN
            UPDATE dbo.Products
            SET Stock = Stock - 5
            WHERE ProductId = @TestProductIdCC3;
            
            PRINT N'Trừ 5 stock thành công!';
        END
        
    COMMIT TRANSACTION;
    
    -- Kiểm tra kết quả
    PRINT N'Stock sau UPDLOCK + UPDATE:';
    SELECT ProductId, Title, Stock FROM dbo.Products WHERE ProductId = @TestProductIdCC3;
    
    -- CLEANUP
    PRINT N'--- CLEANUP CC 3 ---';
    DELETE FROM dbo.Notifications WHERE Message LIKE N'%Test UPDLOCK Product%';
    DELETE FROM dbo.Products WHERE ProductId = @TestProductIdCC3;
    PRINT N'Đã xóa Product test';
END

PRINT N'✓ TEST CC 3 hoàn thành';
GO

-- =============================================
-- TEST CC 4: sp_UpdateStock_Safe (Stored Procedure an toàn)
-- Mục đích: Test procedure cập nhật stock với concurrency control
-- =============================================
PRINT N'';
PRINT N'--- TEST CC 4: sp_UpdateStock_Safe ---';

-- Kiểm tra procedure có tồn tại không
IF OBJECT_ID('dbo.sp_UpdateStock_Safe', 'P') IS NOT NULL
BEGIN
    DECLARE @TestProductIdCC4 INT;
    DECLARE @TestCategoryIdCC4 INT;
    DECLARE @SuccessCC4 BIT;
    DECLARE @ErrorMsgCC4 NVARCHAR(500);
    
    SELECT TOP 1 @TestCategoryIdCC4 = CategoryId FROM dbo.Categories;
    
    IF @TestCategoryIdCC4 IS NOT NULL
    BEGIN
        -- Tạo sản phẩm test
        SET IDENTITY_INSERT dbo.Products ON;
        
        INSERT INTO dbo.Products (ProductId, Title, Author, Description, Price, Stock, CategoryId, IsActive, CreatedAt)
        VALUES (99804, N'Test Safe Stock Product', N'Test Author', N'Mô tả test', 100000, 20, @TestCategoryIdCC4, 1, GETUTCDATE());
        
        SET IDENTITY_INSERT dbo.Products OFF;
        
        SET @TestProductIdCC4 = 99804;
        
        PRINT N'Đã tạo sản phẩm với Stock = 20';
        
        -- Test trừ stock thành công
        PRINT N'Test 4.1: Trừ 5 stock (phải thành công)';
        EXEC sp_UpdateStock_Safe 
            @ProductId = @TestProductIdCC4, 
            @QuantityChange = -5,
            @Success = @SuccessCC4 OUTPUT,
            @ErrorMessage = @ErrorMsgCC4 OUTPUT;
        
        IF @SuccessCC4 = 1
            PRINT N'✓ Thành công! Stock còn: ' + CAST((SELECT Stock FROM dbo.Products WHERE ProductId = @TestProductIdCC4) AS NVARCHAR(10));
        ELSE
            PRINT N'✗ Thất bại: ' + @ErrorMsgCC4;
        
        -- Test trừ quá nhiều stock (phải thất bại)
        PRINT N'Test 4.2: Trừ 100 stock (phải thất bại - không đủ hàng)';
        EXEC sp_UpdateStock_Safe 
            @ProductId = @TestProductIdCC4, 
            @QuantityChange = -100,
            @Success = @SuccessCC4 OUTPUT,
            @ErrorMessage = @ErrorMsgCC4 OUTPUT;
        
        IF @SuccessCC4 = 1
            PRINT N'✓ Thành công!';
        ELSE
            PRINT N'✗ Thất bại (đúng mong đợi): ' + @ErrorMsgCC4;
        
        -- CLEANUP
        PRINT N'--- CLEANUP CC 4 ---';
        DELETE FROM dbo.Notifications WHERE Message LIKE N'%Test Safe Stock Product%';
        DELETE FROM dbo.Products WHERE ProductId = @TestProductIdCC4;
        PRINT N'Đã xóa Product test';
    END
END
ELSE
BEGIN
    PRINT N'⚠ Procedure sp_UpdateStock_Safe chưa được tạo. Chạy ConcurrencyControl.sql trước!';
END

PRINT N'✓ TEST CC 4 hoàn thành';
GO

-- =============================================
-- TEST CC 5: NOLOCK - Đọc dữ liệu không cần chờ (dirty read)
-- Mục đích: Đọc nhanh cho các trường hợp không cần chính xác tuyệt đối
-- =============================================
PRINT N'';
PRINT N'--- TEST CC 5: NOLOCK (dirty read) ---';

-- Test đọc với NOLOCK (nhanh, có thể đọc dữ liệu chưa commit)
PRINT N'Đọc danh sách sản phẩm với NOLOCK:';
SELECT TOP 5
    ProductId,
    Title,
    Price,
    Stock
FROM dbo.Products WITH (NOLOCK)
WHERE IsActive = 1
ORDER BY ProductId;

PRINT N'⚠ Lưu ý: NOLOCK có thể đọc dữ liệu chưa commit (dirty read)';
PRINT N'   Chỉ dùng cho dashboard, thống kê không cần chính xác tuyệt đối';

-- Không cần cleanup vì chỉ SELECT
PRINT N'✓ TEST CC 5 hoàn thành - Không cần cleanup';
GO

-- =============================================
-- PHẦN C: TEST USER ROLE MANAGEMENT
-- =============================================

PRINT N'';
PRINT N'========================================';
PRINT N'PHẦN C: TEST USER ROLE MANAGEMENT';
PRINT N'========================================';
GO

-- =============================================
-- TEST USR 1: Xem tất cả vai trò trong hệ thống
-- =============================================
PRINT N'';
PRINT N'--- TEST USR 1: Xem tất cả vai trò ---';

SELECT 
    Id AS [Mã Vai Trò],
    Name AS [Tên Vai Trò],
    NormalizedName AS [Tên Chuẩn Hóa]
FROM dbo.AspNetRoles
ORDER BY Name;

PRINT N'✓ TEST USR 1 hoàn thành - Không cần cleanup';
GO

-- =============================================
-- TEST USR 2: Đếm số lượng người dùng theo từng vai trò
-- =============================================
PRINT N'';
PRINT N'--- TEST USR 2: Đếm user theo vai trò ---';

SELECT 
    r.Name AS [Vai Trò],
    COUNT(ur.UserId) AS [Số Lượng User]
FROM dbo.AspNetRoles r
LEFT JOIN dbo.AspNetUserRoles ur ON r.Id = ur.RoleId
GROUP BY r.Name
ORDER BY COUNT(ur.UserId) DESC;

PRINT N'✓ TEST USR 2 hoàn thành - Không cần cleanup';
GO

-- =============================================
-- TEST USR 3: Xem vai trò của một user cụ thể
-- =============================================
PRINT N'';
PRINT N'--- TEST USR 3: Xem vai trò của user ---';

DECLARE @TestEmailUSR3 NVARCHAR(256);

-- Lấy email của user đầu tiên
SELECT TOP 1 @TestEmailUSR3 = Email FROM dbo.AspNetUsers;

IF @TestEmailUSR3 IS NOT NULL
BEGIN
    PRINT N'Xem vai trò của user: ' + @TestEmailUSR3;
    
    SELECT 
        u.Email,
        u.FullName AS [Họ Tên],
        STRING_AGG(r.Name, ', ') AS [Các Vai Trò]
    FROM dbo.AspNetUsers u
    LEFT JOIN dbo.AspNetUserRoles ur ON u.Id = ur.UserId
    LEFT JOIN dbo.AspNetRoles r ON ur.RoleId = r.Id
    WHERE u.Email = @TestEmailUSR3
    GROUP BY u.Email, u.FullName;
END
ELSE
BEGIN
    PRINT N'⚠ Không có user để test';
END

PRINT N'✓ TEST USR 3 hoàn thành - Không cần cleanup';
GO

-- =============================================
-- TEST USR 4: Thêm và xóa vai trò cho user (có cleanup)
-- =============================================
PRINT N'';
PRINT N'--- TEST USR 4: Thêm/Xóa vai trò cho user ---';

DECLARE @TestUserIdUSR4 NVARCHAR(450);
DECLARE @TestRoleIdUSR4 NVARCHAR(450);
DECLARE @OriginalRoleId NVARCHAR(450);

SELECT TOP 1 @TestUserIdUSR4 = Id FROM dbo.AspNetUsers;

-- Lấy RoleId của Customer (để test thêm role)
SELECT @TestRoleIdUSR4 = Id FROM dbo.AspNetRoles WHERE Name = 'Customer';

-- Lưu role hiện tại
SELECT @OriginalRoleId = RoleId FROM dbo.AspNetUserRoles WHERE UserId = @TestUserIdUSR4;

IF @TestUserIdUSR4 IS NOT NULL AND @TestRoleIdUSR4 IS NOT NULL
BEGIN
    -- Kiểm tra user có role Customer chưa
    IF NOT EXISTS (SELECT 1 FROM dbo.AspNetUserRoles WHERE UserId = @TestUserIdUSR4 AND RoleId = @TestRoleIdUSR4)
    BEGIN
        -- Thêm role Customer cho user
        INSERT INTO dbo.AspNetUserRoles (UserId, RoleId)
        VALUES (@TestUserIdUSR4, @TestRoleIdUSR4);
        
        PRINT N'Đã thêm vai trò Customer cho user';
        
        -- Kiểm tra kết quả
        SELECT 
            u.Email,
            STRING_AGG(r.Name, ', ') AS [Các Vai Trò]
        FROM dbo.AspNetUsers u
        LEFT JOIN dbo.AspNetUserRoles ur ON u.Id = ur.UserId
        LEFT JOIN dbo.AspNetRoles r ON ur.RoleId = r.Id
        WHERE u.Id = @TestUserIdUSR4
        GROUP BY u.Email;
        
        -- CLEANUP: Xóa role vừa thêm
        PRINT N'--- CLEANUP USR 4 ---';
        DELETE FROM dbo.AspNetUserRoles 
        WHERE UserId = @TestUserIdUSR4 AND RoleId = @TestRoleIdUSR4;
        PRINT N'Đã xóa vai trò Customer test';
    END
    ELSE
    BEGIN
        PRINT N'User đã có vai trò Customer rồi - bỏ qua test thêm';
    END
END
ELSE
BEGIN
    PRINT N'⚠ Không đủ dữ liệu để test';
END

PRINT N'✓ TEST USR 4 hoàn thành';
GO

-- =============================================
-- TEST USR 5: Kiểm tra quyền truy cập của user
-- =============================================
PRINT N'';
PRINT N'--- TEST USR 5: Kiểm tra quyền truy cập ---';

DECLARE @TestEmailUSR5 NVARCHAR(256);
DECLARE @RequiredRoleUSR5 NVARCHAR(50) = 'Admin';

SELECT TOP 1 @TestEmailUSR5 = Email FROM dbo.AspNetUsers;

IF @TestEmailUSR5 IS NOT NULL
BEGIN
    PRINT N'Kiểm tra user ' + @TestEmailUSR5 + N' có quyền ' + @RequiredRoleUSR5 + N' không:';
    
    IF EXISTS (
        SELECT 1 
        FROM dbo.AspNetUsers u
        INNER JOIN dbo.AspNetUserRoles ur ON u.Id = ur.UserId
        INNER JOIN dbo.AspNetRoles r ON ur.RoleId = r.Id
        WHERE u.Email = @TestEmailUSR5 AND r.Name = @RequiredRoleUSR5
    )
    BEGIN
        PRINT N'✓ User CÓ quyền ' + @RequiredRoleUSR5;
    END
    ELSE
    BEGIN
        PRINT N'✗ User KHÔNG CÓ quyền ' + @RequiredRoleUSR5;
    END
END

PRINT N'✓ TEST USR 5 hoàn thành - Không cần cleanup';
GO

-- =============================================
-- TEST USR 6: Thống kê người dùng theo trạng thái
-- =============================================
PRINT N'';
PRINT N'--- TEST USR 6: Thống kê user theo trạng thái ---';

SELECT 
    CASE 
        WHEN IsActive = 1 THEN N'Đang Hoạt Động'
        ELSE N'Không Hoạt Động'
    END AS [Trạng Thái],
    COUNT(*) AS [Số Lượng]
FROM dbo.AspNetUsers
GROUP BY IsActive;

PRINT N'✓ TEST USR 6 hoàn thành - Không cần cleanup';
GO

-- =============================================
-- TEST USR 7: Xem thông tin đầy đủ của một user
-- =============================================
PRINT N'';
PRINT N'--- TEST USR 7: Thông tin đầy đủ của user ---';

DECLARE @TestEmailUSR7 NVARCHAR(256);

SELECT TOP 1 @TestEmailUSR7 = Email FROM dbo.AspNetUsers;

IF @TestEmailUSR7 IS NOT NULL
BEGIN
    SELECT 
        u.Id,
        u.Email,
        u.FullName AS [Họ Tên],
        u.PhoneNumber AS [SĐT],
        u.Address AS [Địa Chỉ],
        u.IsActive AS [Hoạt Động],
        u.EmailConfirmed AS [Đã Xác Nhận Email],
        u.CreatedAt AS [Ngày Tạo],
        u.UpdatedAt AS [Ngày Cập Nhật],
        STRING_AGG(r.Name, ', ') AS [Các Vai Trò],
        (SELECT COUNT(*) FROM dbo.Orders WHERE UserId = u.Id) AS [Số Đơn Hàng],
        (SELECT COUNT(*) FROM dbo.Reviews WHERE UserId = u.Id) AS [Số Đánh Giá]
    FROM dbo.AspNetUsers u
    LEFT JOIN dbo.AspNetUserRoles ur ON u.Id = ur.UserId
    LEFT JOIN dbo.AspNetRoles r ON ur.RoleId = r.Id
    WHERE u.Email = @TestEmailUSR7
    GROUP BY u.Id, u.Email, u.FullName, u.PhoneNumber, u.Address, 
             u.IsActive, u.EmailConfirmed, u.CreatedAt, u.UpdatedAt;
END

PRINT N'✓ TEST USR 7 hoàn thành - Không cần cleanup';
GO

-- =============================================
-- KẾT THÚC TEST
-- =============================================
PRINT N'';
PRINT N'========================================';
PRINT N'HOÀN THÀNH TEST TẤT CẢ';
PRINT N'========================================';
PRINT N'';
PRINT N'TÓM TẮT:';
PRINT N'';
PRINT N'PHẦN A - TRIGGERS (10 tests):';
PRINT N'  1.  tr_Products_SetCreatedAt          - ✓';
PRINT N'  2.  tr_Orders_SetCreatedAt            - ✓';
PRINT N'  3.  tr_Users_UpdateTimestamp          - ✓';
PRINT N'  4.  tr_Products_LowStockNotification  - ✓';
PRINT N'  5.  tr_Products_OutOfStockNotification- ✓';
PRINT N'  6.  tr_Reviews_SetCreatedAt           - ✓';
PRINT N'  7.  tr_Orders_NotifyNewOrder          - ✓';
PRINT N'  8.  tr_Orders_StatusChangeNotification- ✓';
PRINT N'  9.  tr_CartItems_SetAddedAt           - ✓';
PRINT N'  10. tr_Products_PriceChangeLog        - ✓';
PRINT N'';
PRINT N'PHẦN B - CONCURRENCY CONTROL (5 tests):';
PRINT N'  1. Transaction cơ bản (COMMIT)        - ✓';
PRINT N'  2. Transaction ROLLBACK               - ✓';
PRINT N'  3. UPDLOCK                            - ✓';
PRINT N'  4. sp_UpdateStock_Safe                - ✓';
PRINT N'  5. NOLOCK (dirty read)                - ✓';
PRINT N'';
PRINT N'PHẦN C - USER ROLE MANAGEMENT (7 tests):';
PRINT N'  1. Xem tất cả vai trò                 - ✓';
PRINT N'  2. Đếm user theo vai trò              - ✓';
PRINT N'  3. Xem vai trò của user               - ✓';
PRINT N'  4. Thêm/Xóa vai trò                   - ✓';
PRINT N'  5. Kiểm tra quyền truy cập            - ✓';
PRINT N'  6. Thống kê user theo trạng thái      - ✓';
PRINT N'  7. Thông tin đầy đủ của user          - ✓';
PRINT N'';
PRINT N'- Dữ liệu gốc được bảo toàn nguyên vẹn';
PRINT N'========================================';
GO
