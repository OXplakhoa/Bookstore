-- =============================================
-- Bookstore Database Seed Data
-- SQL Server Insert Script
-- Generated: 2025-12-04
-- =============================================
-- This script seeds all tables with sample data
-- Password: Admin@123 (hashed with ASP.NET Core Identity)
-- =============================================

USE Bookstore;
GO

-- =============================================
-- 1. SEED ROLES
-- =============================================
PRINT N'Seeding AspNetRoles...';

INSERT INTO AspNetRoles (Id, Name, NormalizedName, ConcurrencyStamp)
VALUES 
    ('93942231-d855-4285-a9e5-c904082dd4ef', 'Admin', 'ADMIN', NEWID()),
    ('d7d5d42f-b777-4d45-85cb-efb4fd3b2017', 'Seller', 'SELLER', NEWID()),
    ('73cd6c4c-1708-4365-a612-9ce8acf9d6ee', 'Customer', 'CUSTOMER', NEWID());
GO

-- =============================================
-- 2. SEED USERS
-- =============================================
PRINT N'Seeding AspNetUsers...';

INSERT INTO AspNetUsers (Id, FullName, DateOfBirth, Address, ProfilePictureUrl, CreatedAt, UpdatedAt, IsActive, IsDeleted, 
    UserName, NormalizedUserName, Email, NormalizedEmail, EmailConfirmed, 
    PasswordHash, SecurityStamp, ConcurrencyStamp, PhoneNumber, PhoneNumberConfirmed, 
    TwoFactorEnabled, LockoutEnd, LockoutEnabled, AccessFailedCount)
VALUES 
    ('89854b13-2d30-4bbe-a292-74e53d85f0af', N'Quản trị viên', '1990-01-01', N'123 Đường Admin, Quận 1, TP.HCM', NULL, GETUTCDATE(), NULL, 1, 0,
     'admin@bookstore.local', 'ADMIN@BOOKSTORE.LOCAL', 'admin@bookstore.local', 'ADMIN@BOOKSTORE.LOCAL', 1,
     'AQAAAAIAAYagAAAAELYEP0kJCHvGZk2qZKX6OhWBNrHQRnF8T6M8x3DqD1T+X3mN8bQMKJLkHvWnE5FLYA==',
     NEWID(), NEWID(), '0901234567', 0, 0, NULL, 1, 0);
GO

-- =============================================
-- 3. ASSIGN USER ROLES
-- =============================================
PRINT N'Seeding AspNetUserRoles...';

INSERT INTO AspNetUserRoles (UserId, RoleId)
VALUES 
    ('89854b13-2d30-4bbe-a292-74e53d85f0af', '93942231-d855-4285-a9e5-c904082dd4ef');
GO

-- =============================================
-- 4. SEED CATEGORIES
-- =============================================
PRINT N'Seeding Categories...';

SET IDENTITY_INSERT Categories ON;

INSERT INTO Categories (CategoryId, Name, Slug, Description)
VALUES 
    (1, N'Văn học Việt Nam', 'van-hoc-viet-nam', N'Các tác phẩm văn học của các tác giả Việt Nam'),
    (2, N'Văn học nước ngoài', 'van-hoc-nuoc-ngoai', N'Các tác phẩm văn học dịch từ nước ngoài'),
    (3, N'Kinh tế - Kinh doanh', 'kinh-te-kinh-doanh', N'Sách về kinh tế, tài chính, khởi nghiệp và quản trị'),
    (4, N'Kỹ năng sống', 'ky-nang-song', N'Sách phát triển bản thân và kỹ năng mềm'),
    (5, N'Khoa học - Công nghệ', 'khoa-hoc-cong-nghe', N'Sách về khoa học tự nhiên và công nghệ'),
    (6, N'Thiếu nhi', 'thieu-nhi', N'Sách dành cho trẻ em và thanh thiếu niên'),
    (7, N'Tâm lý - Triết học', 'tam-ly-triet-hoc', N'Sách về tâm lý học và triết học'),
    (8, N'Lịch sử - Địa lý', 'lich-su-dia-ly', N'Sách về lịch sử và địa lý'),
    (9, N'Giáo trình - Tham khảo', 'giao-trinh-tham-khao', N'Sách giáo khoa và tài liệu tham khảo'),
    (10, N'Truyện tranh - Manga', 'truyen-tranh-manga', N'Truyện tranh và manga các thể loại');

SET IDENTITY_INSERT Categories OFF;
GO

-- =============================================
-- 5. SEED PRODUCTS (BOOKS)
-- =============================================
PRINT N'Seeding Products...';

SET IDENTITY_INSERT Products ON;

INSERT INTO Products (ProductId, Title, Author, Description, Price, Stock, CategoryId, IsActive, CreatedAt)
VALUES 
    -- Văn học Việt Nam
    (1, N'Dế Mèn Phiêu Lưu Ký', N'Tô Hoài', 
     N'Tác phẩm kinh điển của văn học thiếu nhi Việt Nam, kể về cuộc phiêu lưu của chú Dế Mèn.', 
     85000.00, 100, 1, 1, GETUTCDATE()),
    
    (2, N'Số Đỏ', N'Vũ Trọng Phụng', 
     N'Tiểu thuyết trào phúng nổi tiếng nhất của văn học Việt Nam hiện đại.', 
     120000.00, 50, 1, 1, GETUTCDATE()),
    
    (3, N'Truyện Kiều', N'Nguyễn Du', 
     N'Kiệt tác của nền văn học cổ điển Việt Nam, được UNESCO công nhận là danh nhân văn hóa thế giới.', 
     150000.00, 80, 1, 1, GETUTCDATE()),
    
    (4, N'Tắt Đèn', N'Ngô Tất Tố', 
     N'Tiểu thuyết hiện thực phê phán về cuộc sống của người nông dân Việt Nam trước Cách mạng.', 
     95000.00, 60, 1, 1, GETUTCDATE()),
    
    -- Văn học nước ngoài
    (5, N'Nhà Giả Kim', N'Paulo Coelho', 
     N'Cuốn sách bán chạy nhất mọi thời đại về hành trình theo đuổi giấc mơ.', 
     79000.00, 200, 2, 1, GETUTCDATE()),
    
    (6, N'Đắc Nhân Tâm', N'Dale Carnegie', 
     N'Cuốn sách kinh điển về nghệ thuật giao tiếp và ứng xử.', 
     88000.00, 150, 2, 1, GETUTCDATE()),
    
    (7, N'1984', N'George Orwell', 
     N'Tiểu thuyết dystopia kinh điển về xã hội toàn trị.', 
     115000.00, 70, 2, 1, GETUTCDATE()),
    
    (8, N'Harry Potter và Hòn Đá Phù Thủy', N'J.K. Rowling', 
     N'Tập đầu tiên trong series Harry Potter huyền thoại.', 
     135000.00, 120, 2, 1, GETUTCDATE()),
    
    -- Kinh tế - Kinh doanh
    (9, N'Cha Giàu Cha Nghèo', N'Robert Kiyosaki', 
     N'Cuốn sách về tài chính cá nhân bán chạy nhất mọi thời đại.', 
     110000.00, 90, 3, 1, GETUTCDATE()),
    
    (10, N'Khởi Nghiệp Tinh Gọn', N'Eric Ries', 
     N'Phương pháp khởi nghiệp hiệu quả trong thời đại số.', 
     165000.00, 40, 3, 1, GETUTCDATE()),
    
    (11, N'Tư Duy Nhanh và Chậm', N'Daniel Kahneman', 
     N'Cuốn sách về tâm lý học hành vi và ra quyết định.', 
     189000.00, 55, 3, 1, GETUTCDATE()),
    
    -- Kỹ năng sống
    (12, N'Đời Ngắn Đừng Ngủ Dài', N'Robin Sharma', 
     N'Cuốn sách truyền cảm hứng về cách sống ý nghĩa.', 
     75000.00, 85, 4, 1, GETUTCDATE()),
    
    (13, N'Nghĩ Giàu Làm Giàu', N'Napoleon Hill', 
     N'Cuốn sách kinh điển về tư duy thành công.', 
     98000.00, 100, 4, 1, GETUTCDATE()),
    
    (14, N'7 Thói Quen Hiệu Quả', N'Stephen Covey', 
     N'Cuốn sách về phát triển bản thân và lãnh đạo.', 
     145000.00, 65, 4, 1, GETUTCDATE()),
    
    -- Khoa học - Công nghệ
    (15, N'Lược Sử Thời Gian', N'Stephen Hawking', 
     N'Cuốn sách phổ biến khoa học nổi tiếng nhất về vũ trụ học.', 
     125000.00, 45, 5, 1, GETUTCDATE()),
    
    (16, N'Clean Code', N'Robert C. Martin', 
     N'Cuốn sách kinh điển về lập trình sạch và chuyên nghiệp.', 
     350000.00, 30, 5, 1, GETUTCDATE()),
    
    (17, N'Sapiens: Lược Sử Loài Người', N'Yuval Noah Harari', 
     N'Cuốn sách về lịch sử và tiến hóa của loài người.', 
     199000.00, 75, 5, 1, GETUTCDATE()),
    
    -- Thiếu nhi
    (18, N'Hoàng Tử Bé', N'Antoine de Saint-Exupéry', 
     N'Câu chuyện cổ tích triết lý dành cho mọi lứa tuổi.', 
     65000.00, 150, 6, 1, GETUTCDATE()),
    
    (19, N'Doraemon Tập 1', N'Fujiko F. Fujio', 
     N'Tập đầu tiên của series manga huyền thoại.', 
     25000.00, 200, 6, 1, GETUTCDATE()),
    
    (20, N'Nhóc Nicolas', N'René Goscinny', 
     N'Những câu chuyện hài hước về cậu bé Nicolas.', 
     85000.00, 80, 6, 1, GETUTCDATE()),
    
    -- Tâm lý - Triết học
    (21, N'Đọc Vị Bất Kỳ Ai', N'David J. Lieberman', 
     N'Cuốn sách về nghệ thuật đọc vị tâm lý người khác.', 
     89000.00, 95, 7, 1, GETUTCDATE()),
    
    (22, N'Tâm Lý Học Đám Đông', N'Gustave Le Bon', 
     N'Cuốn sách kinh điển về tâm lý học xã hội.', 
     75000.00, 60, 7, 1, GETUTCDATE()),
    
    -- Lịch sử - Địa lý
    (23, N'Việt Nam Sử Lược', N'Trần Trọng Kim', 
     N'Tác phẩm lịch sử nổi tiếng về Việt Nam.', 
     185000.00, 40, 8, 1, GETUTCDATE()),
    
    (24, N'Đại Việt Sử Ký Toàn Thư', N'Ngô Sĩ Liên', 
     N'Bộ quốc sử lớn nhất của Việt Nam thời phong kiến.', 
     450000.00, 25, 8, 1, GETUTCDATE()),
    
    -- Giáo trình - Tham khảo
    (25, N'Giải Tích 1', N'Nguyễn Đình Trí', 
     N'Giáo trình toán cao cấp dành cho sinh viên đại học.', 
     95000.00, 100, 9, 1, GETUTCDATE()),
    
    (26, N'Tiếng Anh Giao Tiếp', N'Đặng Văn Kỳ', 
     N'Sách học tiếng Anh giao tiếp cơ bản.', 
     120000.00, 80, 9, 1, GETUTCDATE()),
    
    -- Truyện tranh - Manga
    (27, N'One Piece Tập 1', N'Eiichiro Oda', 
     N'Tập đầu tiên của series manga bán chạy nhất mọi thời đại.', 
     25000.00, 300, 10, 1, GETUTCDATE()),
    
    (28, N'Naruto Tập 1', N'Masashi Kishimoto', 
     N'Tập đầu tiên của series manga ninja huyền thoại.', 
     25000.00, 250, 10, 1, GETUTCDATE()),
    
    (29, N'Conan Tập 1', N'Gosho Aoyama', 
     N'Tập đầu tiên của series manga trinh thám nổi tiếng.', 
     25000.00, 200, 10, 1, GETUTCDATE()),
    
    (30, N'Dragon Ball Tập 1', N'Akira Toriyama', 
     N'Tập đầu tiên của series manga hành động kinh điển.', 
     30000.00, 180, 10, 1, GETUTCDATE());

SET IDENTITY_INSERT Products OFF;
GO

-- =============================================
-- 6. SEED PRODUCT IMAGES
-- =============================================
PRINT N'Seeding ProductImages...';

SET IDENTITY_INSERT ProductImages ON;

INSERT INTO ProductImages (ProductImageId, ProductId, ImageUrl, IsMain)
VALUES 
    (1, 1, '/images/products/de-men-phieu-luu-ky.jpg', 1),
    (2, 2, '/images/products/so-do.jpg', 1),
    (3, 3, '/images/products/truyen-kieu.jpg', 1),
    (4, 4, '/images/products/tat-den.jpg', 1),
    (5, 5, '/images/products/nha-gia-kim.jpg', 1),
    (6, 6, '/images/products/dac-nhan-tam.jpg', 1),
    (7, 7, '/images/products/1984.jpg', 1),
    (8, 8, '/images/products/harry-potter-1.jpg', 1),
    (9, 9, '/images/products/cha-giau-cha-ngheo.jpg', 1),
    (10, 10, '/images/products/khoi-nghiep-tinh-gon.jpg', 1),
    (11, 11, '/images/products/tu-duy-nhanh-va-cham.jpg', 1),
    (12, 12, '/images/products/doi-ngan-dung-ngu-dai.jpg', 1),
    (13, 13, '/images/products/nghi-giau-lam-giau.jpg', 1),
    (14, 14, '/images/products/7-thoi-quen-hieu-qua.jpg', 1),
    (15, 15, '/images/products/luoc-su-thoi-gian.jpg', 1),
    (16, 16, '/images/products/clean-code.jpg', 1),
    (17, 17, '/images/products/sapiens.jpg', 1),
    (18, 18, '/images/products/hoang-tu-be.jpg', 1),
    (19, 19, '/images/products/doraemon-1.jpg', 1),
    (20, 20, '/images/products/nhoc-nicolas.jpg', 1),
    (21, 21, '/images/products/doc-vi-bat-ky-ai.jpg', 1),
    (22, 22, '/images/products/tam-ly-hoc-dam-dong.jpg', 1),
    (23, 23, '/images/products/viet-nam-su-luoc.jpg', 1),
    (24, 24, '/images/products/dai-viet-su-ky-toan-thu.jpg', 1),
    (25, 25, '/images/products/giai-tich-1.jpg', 1),
    (26, 26, '/images/products/tieng-anh-giao-tiep.jpg', 1),
    (27, 27, '/images/products/one-piece-1.jpg', 1),
    (28, 28, '/images/products/naruto-1.jpg', 1),
    (29, 29, '/images/products/conan-1.jpg', 1),
    (30, 30, '/images/products/dragon-ball-1.jpg', 1);

SET IDENTITY_INSERT ProductImages OFF;
GO

-- =============================================
-- 7. SEED FLASH SALES
-- =============================================
PRINT N'Seeding FlashSales...';

SET IDENTITY_INSERT FlashSales ON;

INSERT INTO FlashSales (FlashSaleId, Name, Description, StartDate, EndDate, IsActive, CreatedAt)
VALUES 
    (1, N'Flash Sale Cuối Tuần', N'Giảm giá sốc cuối tuần - Lên đến 50%!', 
     DATEADD(DAY, -1, GETUTCDATE()), DATEADD(DAY, 2, GETUTCDATE()), 1, GETUTCDATE()),
    
    (2, N'Sale Giáng Sinh 2025', N'Chương trình khuyến mãi đặc biệt mùa Giáng Sinh', 
     '2025-12-20', '2025-12-26', 1, GETUTCDATE()),
    
    (3, N'Flash Sale Sách Văn Học', N'Ưu đãi đặc biệt cho sách văn học', 
     DATEADD(DAY, 3, GETUTCDATE()), DATEADD(DAY, 10, GETUTCDATE()), 0, GETUTCDATE());

SET IDENTITY_INSERT FlashSales OFF;
GO

-- =============================================
-- 8. SEED FLASH SALE PRODUCTS
-- =============================================
PRINT N'Seeding FlashSaleProducts...';

SET IDENTITY_INSERT FlashSaleProducts ON;

INSERT INTO FlashSaleProducts (FlashSaleProductId, FlashSaleId, ProductId, OriginalPrice, SalePrice, DiscountPercentage, StockLimit, SoldCount)
VALUES 
    -- Flash Sale Cuối Tuần
    (1, 1, 5, 79000.00, 59000.00, 25.00, 50, 12),   -- Nhà Giả Kim
    (2, 1, 6, 88000.00, 66000.00, 25.00, 40, 8),    -- Đắc Nhân Tâm
    (3, 1, 12, 75000.00, 52000.00, 30.00, 30, 15),  -- Đời Ngắn Đừng Ngủ Dài
    (4, 1, 18, 65000.00, 45000.00, 30.00, 60, 25),  -- Hoàng Tử Bé
    
    -- Sale Giáng Sinh 2025
    (5, 2, 8, 135000.00, 95000.00, 30.00, 100, 0),  -- Harry Potter
    (6, 2, 19, 25000.00, 18000.00, 28.00, 100, 0),  -- Doraemon
    (7, 2, 27, 25000.00, 18000.00, 28.00, 100, 0),  -- One Piece
    
    -- Flash Sale Sách Văn Học
    (8, 3, 1, 85000.00, 59000.00, 30.00, 50, 0),    -- Dế Mèn Phiêu Lưu Ký
    (9, 3, 2, 120000.00, 84000.00, 30.00, 30, 0),   -- Số Đỏ
    (10, 3, 3, 150000.00, 105000.00, 30.00, 40, 0); -- Truyện Kiều

SET IDENTITY_INSERT FlashSaleProducts OFF;
GO

-- =============================================
-- 9. SEED ORDERS
-- =============================================
PRINT N'Seeding Orders...';

SET IDENTITY_INSERT Orders ON;

INSERT INTO Orders (OrderId, UserId, OrderNumber, OrderDate, Total, OrderStatus, PaymentStatus, PaymentMethod, 
    ShippingName, ShippingEmail, ShippingPhone, ShippingAddress, TrackingNumber, Notes)
VALUES 
    -- Order for admin user
    (1, '89854b13-2d30-4bbe-a292-74e53d85f0af', 'ORD-20251201-001', DATEADD(DAY, -3, GETUTCDATE()), 223000.00, N'Delivered', N'Paid', N'Stripe',
     N'Quản trị viên', 'admin@bookstore.local', '0901234567', N'123 Đường Admin, Quận 1, TP.HCM', 
     'VN123456789', N'Giao hàng giờ hành chính'),
    
    -- Another order for admin user
    (2, '89854b13-2d30-4bbe-a292-74e53d85f0af', 'ORD-20251202-002', DATEADD(DAY, -2, GETUTCDATE()), 189000.00, N'Shipped', N'Paid', N'COD',
     N'Quản trị viên', 'admin@bookstore.local', '0901234567', N'123 Đường Admin, Quận 1, TP.HCM', 
     'VN987654321', NULL),
    
    -- Another order for admin user
    (3, '89854b13-2d30-4bbe-a292-74e53d85f0af', 'ORD-20251203-003', DATEADD(DAY, -1, GETUTCDATE()), 350000.00, N'Processing', N'Paid', N'Stripe',
     N'Quản trị viên', 'admin@bookstore.local', '0901234567', N'123 Đường Admin, Quận 1, TP.HCM', 
     NULL, N'Đóng gói cẩn thận'),
    
    -- Another order for admin user
    (4, '89854b13-2d30-4bbe-a292-74e53d85f0af', 'ORD-20251204-004', GETUTCDATE(), 141000.00, N'Pending', N'Pending', NULL,
     N'Quản trị viên', 'admin@bookstore.local', '0901234567', N'123 Đường Admin, Quận 1, TP.HCM', 
     NULL, NULL);

SET IDENTITY_INSERT Orders OFF;
GO

-- =============================================
-- 10. SEED ORDER ITEMS
-- =============================================
PRINT N'Seeding OrderItems...';

SET IDENTITY_INSERT OrderItems ON;

INSERT INTO OrderItems (OrderItemId, OrderId, ProductId, FlashSaleProductId, Quantity, UnitPrice, WasOnFlashSale, FlashSaleDiscount)
VALUES 
    -- Order 1
    (1, 1, 5, 1, 1, 59000.00, 1, 20000.00),    -- Nhà Giả Kim (Flash Sale)
    (2, 1, 6, 2, 1, 66000.00, 1, 22000.00),    -- Đắc Nhân Tâm (Flash Sale)
    (3, 1, 13, NULL, 1, 98000.00, 0, NULL),    -- Nghĩ Giàu Làm Giàu
    
    -- Order 2
    (4, 2, 11, NULL, 1, 189000.00, 0, NULL),   -- Tư Duy Nhanh và Chậm
    
    -- Order 3
    (5, 3, 16, NULL, 1, 350000.00, 0, NULL),   -- Clean Code
    
    -- Order 4
    (6, 4, 12, 3, 1, 52000.00, 1, 23000.00),   -- Đời Ngắn Đừng Ngủ Dài (Flash Sale)
    (7, 4, 21, NULL, 1, 89000.00, 0, NULL);    -- Đọc Vị Bất Kỳ Ai

SET IDENTITY_INSERT OrderItems OFF;
GO

-- =============================================
-- 11. SEED CART ITEMS
-- =============================================
PRINT N'Seeding CartItems...';

SET IDENTITY_INSERT CartItems ON;

INSERT INTO CartItems (CartItemId, UserId, ProductId, FlashSaleProductId, Quantity, DateAdded, LockedPrice)
VALUES 
    (1, '89854b13-2d30-4bbe-a292-74e53d85f0af', 17, NULL, 1, GETUTCDATE(), 199000.00),   -- Sapiens
    (2, '89854b13-2d30-4bbe-a292-74e53d85f0af', 15, NULL, 2, GETUTCDATE(), 125000.00),   -- Lược Sử Thời Gian
    (3, '89854b13-2d30-4bbe-a292-74e53d85f0af', 18, 4, GETUTCDATE(), 45000.00),          -- Hoàng Tử Bé (Flash Sale)
    (4, '89854b13-2d30-4bbe-a292-74e53d85f0af', 27, 7, GETUTCDATE(), 18000.00);          -- One Piece Tập 1 (Flash Sale)

SET IDENTITY_INSERT CartItems OFF;
GO

-- =============================================
-- 12. SEED PAYMENTS
-- =============================================
PRINT N'Seeding Payments...';

SET IDENTITY_INSERT Payments ON;

INSERT INTO Payments (PaymentId, OrderId, PaymentMethod, Status, PaymentDate, Amount, TransactionId, PaymentIntentId)
VALUES 
    (1, 1, N'Stripe', N'Completed', DATEADD(DAY, -3, GETUTCDATE()), 223000.00, 'txn_1234567890', 'pi_1234567890'),
    (2, 2, N'COD', N'Completed', DATEADD(DAY, -2, GETUTCDATE()), 189000.00, NULL, NULL),
    (3, 3, N'Stripe', N'Completed', DATEADD(DAY, -1, GETUTCDATE()), 350000.00, 'txn_0987654321', 'pi_0987654321');

SET IDENTITY_INSERT Payments OFF;
GO

-- =============================================
-- 13. SEED REVIEWS
-- =============================================
PRINT N'Seeding Reviews...';

SET IDENTITY_INSERT Reviews ON;

INSERT INTO Reviews (ReviewId, UserId, ProductId, Rating, Comment, CreatedAt)
VALUES 
    (1, '89854b13-2d30-4bbe-a292-74e53d85f0af', 5, 5, N'Sách rất hay, đọc rất cuốn hút. Highly recommended!', DATEADD(DAY, -2, GETUTCDATE())),
    (2, '89854b13-2d30-4bbe-a292-74e53d85f0af', 6, 4, N'Nội dung tốt, giúp tôi giao tiếp hiệu quả hơn.', DATEADD(DAY, -2, GETUTCDATE())),
    (3, '89854b13-2d30-4bbe-a292-74e53d85f0af', 16, 5, N'Cuốn sách tuyệt vời cho lập trình viên. Must read!', DATEADD(DAY, -1, GETUTCDATE())),
    (4, '89854b13-2d30-4bbe-a292-74e53d85f0af', 11, 5, N'Sách hay, giải thích rõ ràng về tâm lý học hành vi.', DATEADD(DAY, -1, GETUTCDATE())),
    (5, '89854b13-2d30-4bbe-a292-74e53d85f0af', 18, 5, N'Hoàng Tử Bé - một kiệt tác! Đọc đi đọc lại nhiều lần vẫn thấy hay.', GETUTCDATE()),
    (6, '89854b13-2d30-4bbe-a292-74e53d85f0af', 13, 4, N'Sách truyền cảm hứng, đáng đọc.', DATEADD(DAY, -3, GETUTCDATE())),
    (7, '89854b13-2d30-4bbe-a292-74e53d85f0af', 17, 5, N'Sapiens mở rộng tầm nhìn của tôi về lịch sử loài người.', DATEADD(DAY, -2, GETUTCDATE())),
    (8, '89854b13-2d30-4bbe-a292-74e53d85f0af', 27, 5, N'One Piece là manga hay nhất! Mua để sưu tầm.', GETUTCDATE());

SET IDENTITY_INSERT Reviews OFF;
GO

-- =============================================
-- 14. SEED FAVORITE PRODUCTS
-- =============================================
PRINT N'Seeding FavoriteProducts...';

INSERT INTO FavoriteProducts (ApplicationUserId, ProductId)
VALUES 
    ('89854b13-2d30-4bbe-a292-74e53d85f0af', 5),   -- Nhà Giả Kim
    ('89854b13-2d30-4bbe-a292-74e53d85f0af', 6),   -- Đắc Nhân Tâm
    ('89854b13-2d30-4bbe-a292-74e53d85f0af', 17),  -- Sapiens
    ('89854b13-2d30-4bbe-a292-74e53d85f0af', 16),  -- Clean Code
    ('89854b13-2d30-4bbe-a292-74e53d85f0af', 15),  -- Lược Sử Thời Gian
    ('89854b13-2d30-4bbe-a292-74e53d85f0af', 18),  -- Hoàng Tử Bé
    ('89854b13-2d30-4bbe-a292-74e53d85f0af', 27),  -- One Piece
    ('89854b13-2d30-4bbe-a292-74e53d85f0af', 28);  -- Naruto
GO

-- =============================================
-- 15. SEED RECENTLY VIEWED PRODUCTS
-- =============================================
PRINT N'Seeding RecentlyViewedProducts...';

SET IDENTITY_INSERT RecentlyViewedProducts ON;

INSERT INTO RecentlyViewedProducts (Id, ApplicationUserId, ProductId, ViewedAt)
VALUES 
    (1, '89854b13-2d30-4bbe-a292-74e53d85f0af', 5, DATEADD(HOUR, -1, GETUTCDATE())),
    (2, '89854b13-2d30-4bbe-a292-74e53d85f0af', 6, DATEADD(HOUR, -2, GETUTCDATE())),
    (3, '89854b13-2d30-4bbe-a292-74e53d85f0af', 17, DATEADD(HOUR, -3, GETUTCDATE())),
    (4, '89854b13-2d30-4bbe-a292-74e53d85f0af', 15, DATEADD(HOUR, -4, GETUTCDATE())),
    (5, '89854b13-2d30-4bbe-a292-74e53d85f0af', 16, DATEADD(HOUR, -1, GETUTCDATE())),
    (6, '89854b13-2d30-4bbe-a292-74e53d85f0af', 11, DATEADD(HOUR, -2, GETUTCDATE())),
    (7, '89854b13-2d30-4bbe-a292-74e53d85f0af', 10, DATEADD(HOUR, -3, GETUTCDATE())),
    (8, '89854b13-2d30-4bbe-a292-74e53d85f0af', 27, DATEADD(MINUTE, -30, GETUTCDATE())),
    (9, '89854b13-2d30-4bbe-a292-74e53d85f0af', 28, DATEADD(MINUTE, -45, GETUTCDATE())),
    (10, '89854b13-2d30-4bbe-a292-74e53d85f0af', 29, DATEADD(HOUR, -1, GETUTCDATE())),
    (11, '89854b13-2d30-4bbe-a292-74e53d85f0af', 18, DATEADD(HOUR, -2, GETUTCDATE()));

SET IDENTITY_INSERT RecentlyViewedProducts OFF;
GO

-- =============================================
-- 16. SEED NOTIFICATIONS
-- =============================================
PRINT N'Seeding Notifications...';

SET IDENTITY_INSERT Notifications ON;

INSERT INTO Notifications (NotificationId, UserId, Message, CreatedAt)
VALUES 
    (1, '89854b13-2d30-4bbe-a292-74e53d85f0af', N'Đơn hàng ORD-20251201-001 của bạn đã được giao thành công!', DATEADD(DAY, -3, GETUTCDATE())),
    (2, '89854b13-2d30-4bbe-a292-74e53d85f0af', N'Đơn hàng ORD-20251202-002 đang được vận chuyển.', DATEADD(DAY, -2, GETUTCDATE())),
    (3, '89854b13-2d30-4bbe-a292-74e53d85f0af', N'Đơn hàng ORD-20251203-003 đang được xử lý.', DATEADD(DAY, -1, GETUTCDATE())),
    (4, '89854b13-2d30-4bbe-a292-74e53d85f0af', N'Flash Sale Cuối Tuần đã bắt đầu! Giảm giá đến 50%!', DATEADD(DAY, -1, GETUTCDATE())),
    (5, '89854b13-2d30-4bbe-a292-74e53d85f0af', N'Có 1 đơn hàng mới cần xử lý.', GETUTCDATE());

SET IDENTITY_INSERT Notifications OFF;
GO

-- =============================================
-- 17. SEED MESSAGES
-- =============================================
PRINT N'Seeding Messages...';

SET IDENTITY_INSERT Messages ON;

INSERT INTO Messages (MessageId, SenderId, ReceiverId, Content, CreatedAt)
VALUES 
    (1, '89854b13-2d30-4bbe-a292-74e53d85f0af', '89854b13-2d30-4bbe-a292-74e53d85f0af', N'Ghi chú cá nhân: Cần kiểm tra kho hàng Nhà Giả Kim.', DATEADD(DAY, -2, GETUTCDATE())),
    (2, '89854b13-2d30-4bbe-a292-74e53d85f0af', '89854b13-2d30-4bbe-a292-74e53d85f0af', N'Cần xem xét chính sách đổi trả sách.', DATEADD(DAY, -1, GETUTCDATE()));

SET IDENTITY_INSERT Messages OFF;
GO

-- =============================================
-- VERIFICATION QUERIES
-- =============================================
PRINT N'Verifying seed data...';

SELECT 'AspNetRoles' AS TableName, COUNT(*) AS RecordCount FROM AspNetRoles
UNION ALL SELECT 'AspNetUsers', COUNT(*) FROM AspNetUsers
UNION ALL SELECT 'AspNetUserRoles', COUNT(*) FROM AspNetUserRoles
UNION ALL SELECT 'Categories', COUNT(*) FROM Categories
UNION ALL SELECT 'Products', COUNT(*) FROM Products
UNION ALL SELECT 'ProductImages', COUNT(*) FROM ProductImages
UNION ALL SELECT 'FlashSales', COUNT(*) FROM FlashSales
UNION ALL SELECT 'FlashSaleProducts', COUNT(*) FROM FlashSaleProducts
UNION ALL SELECT 'Orders', COUNT(*) FROM Orders
UNION ALL SELECT 'OrderItems', COUNT(*) FROM OrderItems
UNION ALL SELECT 'CartItems', COUNT(*) FROM CartItems
UNION ALL SELECT 'Payments', COUNT(*) FROM Payments
UNION ALL SELECT 'Reviews', COUNT(*) FROM Reviews
UNION ALL SELECT 'FavoriteProducts', COUNT(*) FROM FavoriteProducts
UNION ALL SELECT 'RecentlyViewedProducts', COUNT(*) FROM RecentlyViewedProducts
UNION ALL SELECT 'Notifications', COUNT(*) FROM Notifications
UNION ALL SELECT 'Messages', COUNT(*) FROM Messages;

PRINT N'Seed data inserted successfully!';
GO
