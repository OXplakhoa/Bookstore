/*
=============================================
Bookstore Database User Role Management
=============================================
File: 05_UserRoleManagement.sql
Description: SQL Server user roles, permissions, and security scripts
Version: 1.0
=============================================

SECURITY NOTES:
1. These scripts create database roles for different access levels
2. Application should use a dedicated SQL login, not sa
3. Review permissions before applying to production
4. Always follow principle of least privilege
=============================================
*/

USE BookstoreDb;
GO

-- =============================================
-- SECTION 1: Create Database Roles
-- =============================================

-- Role for application read operations
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'BookstoreReader' AND type = 'R')
BEGIN
    CREATE ROLE [BookstoreReader];
    PRINT 'Role BookstoreReader created.';
END
GO

-- Role for application write operations
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'BookstoreWriter' AND type = 'R')
BEGIN
    CREATE ROLE [BookstoreWriter];
    PRINT 'Role BookstoreWriter created.';
END
GO

-- Role for admin operations
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'BookstoreAdmin' AND type = 'R')
BEGIN
    CREATE ROLE [BookstoreAdmin];
    PRINT 'Role BookstoreAdmin created.';
END
GO

-- Role for reporting/analytics
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'BookstoreReporter' AND type = 'R')
BEGIN
    CREATE ROLE [BookstoreReporter];
    PRINT 'Role BookstoreReporter created.';
END
GO

-- Role for backup operations
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'BookstoreBackupOperator' AND type = 'R')
BEGIN
    CREATE ROLE [BookstoreBackupOperator];
    PRINT 'Role BookstoreBackupOperator created.';
END
GO

PRINT 'All database roles created successfully.';
GO

-- =============================================
-- SECTION 2: Grant Permissions to Roles
-- =============================================

-- BookstoreReader: SELECT only on all tables
GRANT SELECT ON dbo.Categories TO [BookstoreReader];
GRANT SELECT ON dbo.Products TO [BookstoreReader];
GRANT SELECT ON dbo.ProductImages TO [BookstoreReader];
GRANT SELECT ON dbo.Orders TO [BookstoreReader];
GRANT SELECT ON dbo.OrderItems TO [BookstoreReader];
GRANT SELECT ON dbo.CartItems TO [BookstoreReader];
GRANT SELECT ON dbo.Reviews TO [BookstoreReader];
GRANT SELECT ON dbo.Payments TO [BookstoreReader];
GRANT SELECT ON dbo.Notifications TO [BookstoreReader];
GRANT SELECT ON dbo.Messages TO [BookstoreReader];
GRANT SELECT ON dbo.FavoriteProducts TO [BookstoreReader];
GRANT SELECT ON dbo.RecentlyViewedProducts TO [BookstoreReader];
GRANT SELECT ON dbo.FlashSales TO [BookstoreReader];
GRANT SELECT ON dbo.FlashSaleProducts TO [BookstoreReader];
GRANT SELECT ON dbo.AspNetUsers TO [BookstoreReader];
GRANT SELECT ON dbo.AspNetRoles TO [BookstoreReader];
GRANT SELECT ON dbo.AspNetUserRoles TO [BookstoreReader];

PRINT 'Permissions granted to BookstoreReader.';
GO

-- BookstoreWriter: CRUD on customer-facing tables
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.CartItems TO [BookstoreWriter];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.FavoriteProducts TO [BookstoreWriter];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.RecentlyViewedProducts TO [BookstoreWriter];
GRANT SELECT, INSERT, UPDATE ON dbo.Orders TO [BookstoreWriter];
GRANT SELECT, INSERT ON dbo.OrderItems TO [BookstoreWriter];
GRANT SELECT, INSERT, UPDATE ON dbo.Payments TO [BookstoreWriter];
GRANT SELECT, INSERT ON dbo.Reviews TO [BookstoreWriter];
GRANT SELECT, INSERT ON dbo.Notifications TO [BookstoreWriter];
GRANT SELECT, INSERT ON dbo.Messages TO [BookstoreWriter];
GRANT SELECT ON dbo.Categories TO [BookstoreWriter];
GRANT SELECT, UPDATE ON dbo.Products TO [BookstoreWriter]; -- For stock updates
GRANT SELECT ON dbo.ProductImages TO [BookstoreWriter];
GRANT SELECT, UPDATE ON dbo.FlashSales TO [BookstoreWriter];
GRANT SELECT, UPDATE ON dbo.FlashSaleProducts TO [BookstoreWriter];
GRANT SELECT ON dbo.AspNetUsers TO [BookstoreWriter];
GRANT SELECT ON dbo.AspNetRoles TO [BookstoreWriter];
GRANT SELECT ON dbo.AspNetUserRoles TO [BookstoreWriter];

-- Grant EXECUTE on stored procedures
GRANT EXECUTE ON dbo.sp_AddToCart TO [BookstoreWriter];
GRANT EXECUTE ON dbo.sp_CreateOrder TO [BookstoreWriter];
GRANT EXECUTE ON dbo.sp_GetActiveFlashSales TO [BookstoreWriter];
GRANT EXECUTE ON dbo.sp_GetOrderDetails TO [BookstoreWriter];
GRANT EXECUTE ON dbo.sp_GetUserOrders TO [BookstoreWriter];
GRANT EXECUTE ON dbo.sp_GetProductsByCategory TO [BookstoreWriter];
GRANT EXECUTE ON dbo.sp_SearchProducts TO [BookstoreWriter];

PRINT 'Permissions granted to BookstoreWriter.';
GO

-- BookstoreAdmin: Full CRUD on all tables
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Categories TO [BookstoreAdmin];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Products TO [BookstoreAdmin];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.ProductImages TO [BookstoreAdmin];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Orders TO [BookstoreAdmin];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.OrderItems TO [BookstoreAdmin];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.CartItems TO [BookstoreAdmin];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Reviews TO [BookstoreAdmin];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Payments TO [BookstoreAdmin];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Notifications TO [BookstoreAdmin];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Messages TO [BookstoreAdmin];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.FavoriteProducts TO [BookstoreAdmin];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.RecentlyViewedProducts TO [BookstoreAdmin];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.FlashSales TO [BookstoreAdmin];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.FlashSaleProducts TO [BookstoreAdmin];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.AspNetUsers TO [BookstoreAdmin];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.AspNetRoles TO [BookstoreAdmin];
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.AspNetUserRoles TO [BookstoreAdmin];

-- Grant EXECUTE on all stored procedures
GRANT EXECUTE ON dbo.sp_GetDashboardStats TO [BookstoreAdmin];
GRANT EXECUTE ON dbo.sp_GetProductsByCategory TO [BookstoreAdmin];
GRANT EXECUTE ON dbo.sp_GetOrderDetails TO [BookstoreAdmin];
GRANT EXECUTE ON dbo.sp_CreateOrder TO [BookstoreAdmin];
GRANT EXECUTE ON dbo.sp_UpdateOrderStatus TO [BookstoreAdmin];
GRANT EXECUTE ON dbo.sp_GetUserOrders TO [BookstoreAdmin];
GRANT EXECUTE ON dbo.sp_AddToCart TO [BookstoreAdmin];
GRANT EXECUTE ON dbo.sp_GetActiveFlashSales TO [BookstoreAdmin];
GRANT EXECUTE ON dbo.sp_GetRevenueReport TO [BookstoreAdmin];
GRANT EXECUTE ON dbo.sp_GetTopProducts TO [BookstoreAdmin];
GRANT EXECUTE ON dbo.sp_GetUserStats TO [BookstoreAdmin];
GRANT EXECUTE ON dbo.sp_SearchProducts TO [BookstoreAdmin];

PRINT 'Permissions granted to BookstoreAdmin.';
GO

-- BookstoreReporter: SELECT + EXECUTE reporting procedures
GRANT SELECT ON dbo.Categories TO [BookstoreReporter];
GRANT SELECT ON dbo.Products TO [BookstoreReporter];
GRANT SELECT ON dbo.Orders TO [BookstoreReporter];
GRANT SELECT ON dbo.OrderItems TO [BookstoreReporter];
GRANT SELECT ON dbo.Reviews TO [BookstoreReporter];
GRANT SELECT ON dbo.Payments TO [BookstoreReporter];
GRANT SELECT ON dbo.FlashSales TO [BookstoreReporter];
GRANT SELECT ON dbo.FlashSaleProducts TO [BookstoreReporter];
GRANT SELECT ON dbo.AspNetUsers TO [BookstoreReporter];

GRANT EXECUTE ON dbo.sp_GetDashboardStats TO [BookstoreReporter];
GRANT EXECUTE ON dbo.sp_GetRevenueReport TO [BookstoreReporter];
GRANT EXECUTE ON dbo.sp_GetTopProducts TO [BookstoreReporter];
GRANT EXECUTE ON dbo.sp_GetUserStats TO [BookstoreReporter];

PRINT 'Permissions granted to BookstoreReporter.';
GO

-- BookstoreBackupOperator: Backup permissions
GRANT EXECUTE ON dbo.sp_BackupDatabase_Full TO [BookstoreBackupOperator];
GRANT EXECUTE ON dbo.sp_BackupDatabase_Differential TO [BookstoreBackupOperator];
GRANT EXECUTE ON dbo.sp_BackupTransactionLog TO [BookstoreBackupOperator];
GRANT EXECUTE ON dbo.sp_GetBackupHistory TO [BookstoreBackupOperator];
GRANT EXECUTE ON dbo.sp_CleanupOldBackups TO [BookstoreBackupOperator];

PRINT 'Permissions granted to BookstoreBackupOperator.';
GO

-- =============================================
-- SECTION 3: Create SQL Logins and Users
-- =============================================

-- Switch to master for login creation
USE master;
GO

/*
=============================================
SECURITY WARNING: The login creation statements below use placeholder passwords.
Before running in production:
1. Replace '<CHANGE_THIS_PASSWORD>' with strong, unique passwords
2. Store passwords securely (use a password manager or secrets vault)
3. Never commit actual passwords to source control
4. Consider using Windows Authentication instead of SQL Authentication
=============================================
*/

-- Create application login (production)
-- CHANGE PASSWORD BEFORE DEPLOYING TO PRODUCTION!
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'BookstoreApp')
BEGIN
    CREATE LOGIN [BookstoreApp] WITH PASSWORD = '<CHANGE_APP_PASSWORD>';
    PRINT 'Login BookstoreApp created. WARNING: Change the password before production use!';
END
GO

-- Create read-only login (for reporting)
-- CHANGE PASSWORD BEFORE DEPLOYING TO PRODUCTION!
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'BookstoreReports')
BEGIN
    CREATE LOGIN [BookstoreReports] WITH PASSWORD = '<CHANGE_REPORTS_PASSWORD>';
    PRINT 'Login BookstoreReports created. WARNING: Change the password before production use!';
END
GO

-- Create admin login
-- CHANGE PASSWORD BEFORE DEPLOYING TO PRODUCTION!
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'BookstoreDbAdmin')
BEGIN
    CREATE LOGIN [BookstoreDbAdmin] WITH PASSWORD = '<CHANGE_ADMIN_PASSWORD>';
    PRINT 'Login BookstoreDbAdmin created. WARNING: Change the password before production use!';
END
GO

-- Create backup operator login
-- CHANGE PASSWORD BEFORE DEPLOYING TO PRODUCTION!
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'BookstoreBackup')
BEGIN
    CREATE LOGIN [BookstoreBackup] WITH PASSWORD = '<CHANGE_BACKUP_PASSWORD>';
    PRINT 'Login BookstoreBackup created. WARNING: Change the password before production use!';
END
GO

-- Switch to BookstoreDb
USE BookstoreDb;
GO

-- Create database users and map to roles
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'BookstoreApp')
BEGIN
    CREATE USER [BookstoreApp] FOR LOGIN [BookstoreApp];
    ALTER ROLE [BookstoreWriter] ADD MEMBER [BookstoreApp];
    PRINT 'User BookstoreApp created and added to BookstoreWriter role.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'BookstoreReports')
BEGIN
    CREATE USER [BookstoreReports] FOR LOGIN [BookstoreReports];
    ALTER ROLE [BookstoreReporter] ADD MEMBER [BookstoreReports];
    PRINT 'User BookstoreReports created and added to BookstoreReporter role.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'BookstoreDbAdmin')
BEGIN
    CREATE USER [BookstoreDbAdmin] FOR LOGIN [BookstoreDbAdmin];
    ALTER ROLE [BookstoreAdmin] ADD MEMBER [BookstoreDbAdmin];
    PRINT 'User BookstoreDbAdmin created and added to BookstoreAdmin role.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'BookstoreBackup')
BEGIN
    CREATE USER [BookstoreBackup] FOR LOGIN [BookstoreBackup];
    ALTER ROLE [BookstoreBackupOperator] ADD MEMBER [BookstoreBackup];
    ALTER ROLE [db_backupoperator] ADD MEMBER [BookstoreBackup];
    PRINT 'User BookstoreBackup created and added to backup roles.';
END
GO

-- =============================================
-- SECTION 4: Stored Procedures for Role Management
-- =============================================

-- Procedure to add application role to user
IF OBJECT_ID('dbo.sp_AddUserToAppRole', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_AddUserToAppRole;
GO

CREATE PROCEDURE sp_AddUserToAppRole
    @UserId NVARCHAR(450),
    @RoleName NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @RoleId NVARCHAR(450);
    
    -- Get role ID
    SELECT @RoleId = Id FROM dbo.AspNetRoles WHERE Name = @RoleName;
    
    IF @RoleId IS NULL
    BEGIN
        RAISERROR(N'Role không tồn tại.', 16, 1);
        RETURN;
    END
    
    -- Check if user exists
    IF NOT EXISTS (SELECT 1 FROM dbo.AspNetUsers WHERE Id = @UserId)
    BEGIN
        RAISERROR(N'User không tồn tại.', 16, 1);
        RETURN;
    END
    
    -- Check if already in role
    IF EXISTS (SELECT 1 FROM dbo.AspNetUserRoles WHERE UserId = @UserId AND RoleId = @RoleId)
    BEGIN
        PRINT N'User đã có role này.';
        RETURN;
    END
    
    -- Add to role
    INSERT INTO dbo.AspNetUserRoles (UserId, RoleId)
    VALUES (@UserId, @RoleId);
    
    PRINT N'Đã thêm user vào role ' + @RoleName;
END
GO

PRINT 'Stored Procedure sp_AddUserToAppRole created.';
GO

-- Procedure to remove application role from user
IF OBJECT_ID('dbo.sp_RemoveUserFromAppRole', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_RemoveUserFromAppRole;
GO

CREATE PROCEDURE sp_RemoveUserFromAppRole
    @UserId NVARCHAR(450),
    @RoleName NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @RoleId NVARCHAR(450);
    
    -- Get role ID
    SELECT @RoleId = Id FROM dbo.AspNetRoles WHERE Name = @RoleName;
    
    IF @RoleId IS NULL
    BEGIN
        RAISERROR(N'Role không tồn tại.', 16, 1);
        RETURN;
    END
    
    -- Remove from role
    DELETE FROM dbo.AspNetUserRoles 
    WHERE UserId = @UserId AND RoleId = @RoleId;
    
    IF @@ROWCOUNT > 0
        PRINT N'Đã xóa user khỏi role ' + @RoleName;
    ELSE
        PRINT N'User không có role này.';
END
GO

PRINT 'Stored Procedure sp_RemoveUserFromAppRole created.';
GO

-- Procedure to get user roles
IF OBJECT_ID('dbo.sp_GetUserAppRoles', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetUserAppRoles;
GO

CREATE PROCEDURE sp_GetUserAppRoles
    @UserId NVARCHAR(450)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        u.Id AS UserId,
        u.Email,
        u.FullName,
        r.Name AS RoleName
    FROM dbo.AspNetUsers u
    LEFT JOIN dbo.AspNetUserRoles ur ON u.Id = ur.UserId
    LEFT JOIN dbo.AspNetRoles r ON ur.RoleId = r.Id
    WHERE u.Id = @UserId;
END
GO

PRINT 'Stored Procedure sp_GetUserAppRoles created.';
GO

-- Procedure to get all users in a role
IF OBJECT_ID('dbo.sp_GetUsersInAppRole', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetUsersInAppRole;
GO

CREATE PROCEDURE sp_GetUsersInAppRole
    @RoleName NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        u.Id AS UserId,
        u.Email,
        u.FullName,
        u.CreatedAt,
        u.IsActive
    FROM dbo.AspNetUsers u
    INNER JOIN dbo.AspNetUserRoles ur ON u.Id = ur.UserId
    INNER JOIN dbo.AspNetRoles r ON ur.RoleId = r.Id
    WHERE r.Name = @RoleName
    ORDER BY u.FullName;
END
GO

PRINT 'Stored Procedure sp_GetUsersInAppRole created.';
GO

-- Procedure to create new application role
IF OBJECT_ID('dbo.sp_CreateAppRole', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_CreateAppRole;
GO

CREATE PROCEDURE sp_CreateAppRole
    @RoleName NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if role exists
    IF EXISTS (SELECT 1 FROM dbo.AspNetRoles WHERE Name = @RoleName)
    BEGIN
        PRINT N'Role đã tồn tại.';
        RETURN;
    END
    
    -- Create role
    INSERT INTO dbo.AspNetRoles (Id, Name, NormalizedName, ConcurrencyStamp)
    VALUES (NEWID(), @RoleName, UPPER(@RoleName), NEWID());
    
    PRINT N'Đã tạo role ' + @RoleName;
END
GO

PRINT 'Stored Procedure sp_CreateAppRole created.';
GO

-- Procedure to deactivate user
IF OBJECT_ID('dbo.sp_DeactivateUser', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_DeactivateUser;
GO

CREATE PROCEDURE sp_DeactivateUser
    @UserId NVARCHAR(450),
    @Reason NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM dbo.AspNetUsers WHERE Id = @UserId)
    BEGIN
        RAISERROR(N'User không tồn tại.', 16, 1);
        RETURN;
    END
    
    -- Deactivate user
    UPDATE dbo.AspNetUsers
    SET IsActive = 0,
        LockoutEnabled = 1,
        LockoutEnd = DATEADD(YEAR, 100, GETUTCDATE()) -- Lock for 100 years
    WHERE Id = @UserId;
    
    -- Log notification
    DECLARE @AdminUserId NVARCHAR(450);
    SELECT TOP 1 @AdminUserId = u.Id 
    FROM dbo.AspNetUsers u
    INNER JOIN dbo.AspNetUserRoles ur ON u.Id = ur.UserId
    INNER JOIN dbo.AspNetRoles r ON ur.RoleId = r.Id
    WHERE r.Name = 'Admin' AND u.Id != @UserId;
    
    IF @AdminUserId IS NOT NULL
    BEGIN
        INSERT INTO dbo.Notifications (UserId, Message, CreatedAt)
        VALUES (@AdminUserId, 
               N'🔒 User ID ' + @UserId + N' đã bị vô hiệu hóa. Lý do: ' + ISNULL(@Reason, N'Không có'), 
               GETUTCDATE());
    END
    
    PRINT N'User đã bị vô hiệu hóa.';
END
GO

PRINT 'Stored Procedure sp_DeactivateUser created.';
GO

-- Procedure to reactivate user
IF OBJECT_ID('dbo.sp_ReactivateUser', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ReactivateUser;
GO

CREATE PROCEDURE sp_ReactivateUser
    @UserId NVARCHAR(450)
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM dbo.AspNetUsers WHERE Id = @UserId)
    BEGIN
        RAISERROR(N'User không tồn tại.', 16, 1);
        RETURN;
    END
    
    -- Reactivate user
    UPDATE dbo.AspNetUsers
    SET IsActive = 1,
        LockoutEnabled = 0,
        LockoutEnd = NULL
    WHERE Id = @UserId;
    
    -- Send notification to user
    INSERT INTO dbo.Notifications (UserId, Message, CreatedAt)
    VALUES (@UserId, 
           N'✅ Tài khoản của bạn đã được kích hoạt lại.', 
           GETUTCDATE());
    
    PRINT N'User đã được kích hoạt lại.';
END
GO

PRINT 'Stored Procedure sp_ReactivateUser created.';
GO

-- =============================================
-- SECTION 5: Security Audit Procedures
-- =============================================

-- Procedure to audit failed logins
IF OBJECT_ID('dbo.sp_GetFailedLogins', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetFailedLogins;
GO

CREATE PROCEDURE sp_GetFailedLogins
    @Days INT = 7
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        u.Email,
        u.FullName,
        u.AccessFailedCount,
        u.LockoutEnd,
        u.IsActive,
        u.UpdatedAt AS LastUpdated
    FROM dbo.AspNetUsers u
    WHERE u.AccessFailedCount > 0
    OR u.LockoutEnd IS NOT NULL
    ORDER BY u.AccessFailedCount DESC, u.LockoutEnd DESC;
END
GO

PRINT 'Stored Procedure sp_GetFailedLogins created.';
GO

-- Procedure to reset user lockout
IF OBJECT_ID('dbo.sp_ResetUserLockout', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ResetUserLockout;
GO

CREATE PROCEDURE sp_ResetUserLockout
    @UserId NVARCHAR(450)
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE dbo.AspNetUsers
    SET AccessFailedCount = 0,
        LockoutEnd = NULL
    WHERE Id = @UserId;
    
    IF @@ROWCOUNT > 0
        PRINT N'Đã reset lockout cho user.';
    ELSE
        PRINT N'User không tồn tại.';
END
GO

PRINT 'Stored Procedure sp_ResetUserLockout created.';
GO

-- =============================================
-- Summary: All user role management scripts created
-- =============================================
PRINT '';
PRINT '=============================================';
PRINT 'User Role Management scripts created successfully!';
PRINT '=============================================';
PRINT '';
PRINT '*** SECURITY WARNING ***';
PRINT 'SQL Logins have placeholder passwords (<CHANGE_*_PASSWORD>).';
PRINT 'You MUST change these passwords before using in production!';
PRINT '';
PRINT 'Database Roles:';
PRINT '1. BookstoreReader - Read-only access';
PRINT '2. BookstoreWriter - Read/Write for customer operations';
PRINT '3. BookstoreAdmin - Full administrative access';
PRINT '4. BookstoreReporter - Reporting and analytics';
PRINT '5. BookstoreBackupOperator - Backup operations';
PRINT '';
PRINT 'SQL Logins (CHANGE PLACEHOLDER PASSWORDS!):';
PRINT '1. BookstoreApp - Application login (BookstoreWriter)';
PRINT '2. BookstoreReports - Reporting login (BookstoreReporter)';
PRINT '3. BookstoreDbAdmin - Admin login (BookstoreAdmin)';
PRINT '4. BookstoreBackup - Backup login (BookstoreBackupOperator)';
PRINT '';
PRINT 'Application Role Management Procedures:';
PRINT '1. sp_AddUserToAppRole - Add user to application role';
PRINT '2. sp_RemoveUserFromAppRole - Remove user from application role';
PRINT '3. sp_GetUserAppRoles - Get user roles';
PRINT '4. sp_GetUsersInAppRole - Get users in a role';
PRINT '5. sp_CreateAppRole - Create new application role';
PRINT '6. sp_DeactivateUser - Deactivate user account';
PRINT '7. sp_ReactivateUser - Reactivate user account';
PRINT '8. sp_GetFailedLogins - Audit failed login attempts';
PRINT '9. sp_ResetUserLockout - Reset user lockout';
PRINT '=============================================';
GO
