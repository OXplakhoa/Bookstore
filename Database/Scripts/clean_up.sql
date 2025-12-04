-- 1. Tắt toàn bộ ràng buộc khóa ngoại
EXEC sp_MSforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all"
GO

-- 2. Xóa dữ liệu (Đã thêm SET QUOTED_IDENTIFIER ON để fix lỗi 1934)
EXEC sp_MSforeachtable "SET QUOTED_IDENTIFIER ON; DELETE FROM ?"
GO

-- 3. Reset số tự tăng về 0 (Chỉ chạy trên bảng có Identity để fix lỗi 7997)
EXEC sp_MSforeachtable "
    IF OBJECTPROPERTY(OBJECT_ID('?'), 'TableHasIdentity') = 1 
    BEGIN 
        DBCC CHECKIDENT ('?', RESEED, 0) 
    END
"
GO

-- 4. Bật lại ràng buộc khóa ngoại
EXEC sp_MSforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all"
GO

PRINT N'Đã dọn dẹp sạch sẽ dữ liệu và không còn lỗi!'
