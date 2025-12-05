/*
=============================================
Bookstore Database - Master Script
=============================================
File: 00_RunAll.sql
Description: Master script to run all database scripts in order
Version: 1.0
=============================================

INSTRUCTIONS:
1. Open SQL Server Management Studio (SSMS)
2. Connect to your SQL Server instance
3. Ensure BookstoreDb database exists
4. Run this script or run individual scripts in order

ORDER OF EXECUTION:
1. 01_Triggers.sql - Database triggers
2. 02_StoredProcedures.sql - Stored procedures
3. 03_Functions.sql - Scalar and table-valued functions
4. 04_DatabaseBackup.sql - Backup procedures
5. 05_UserRoleManagement.sql - User roles and permissions
6. 06_ConcurrencyControl.sql - Concurrency handling mechanisms

=============================================
*/

USE BookstoreDb;
GO

PRINT '=============================================';
PRINT 'Starting Bookstore Database Setup';
PRINT 'Timestamp: ' + CONVERT(VARCHAR(50), GETDATE(), 120);
PRINT '=============================================';
PRINT '';
GO

-- Verify database exists
IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = 'BookstoreDb')
BEGIN
    RAISERROR('Database BookstoreDb does not exist. Please create it first using EF Core migrations.', 16, 1);
    RETURN;
END
GO

PRINT 'Database BookstoreDb verified.';
PRINT '';
GO

-- =============================================
-- NOTE: Run each script file individually or
-- copy their contents below in the correct order
-- =============================================

/*
-- STEP 1: Run Triggers
-- :r .\01_Triggers.sql
-- OR copy contents of 01_Triggers.sql here

-- STEP 2: Run Stored Procedures
-- :r .\02_StoredProcedures.sql
-- OR copy contents of 02_StoredProcedures.sql here

-- STEP 3: Run Functions
-- :r .\03_Functions.sql
-- OR copy contents of 03_Functions.sql here

-- STEP 4: Run Backup Scripts
-- :r .\04_DatabaseBackup.sql
-- OR copy contents of 04_DatabaseBackup.sql here

-- STEP 5: Run User Role Management
-- :r .\05_UserRoleManagement.sql
-- OR copy contents of 05_UserRoleManagement.sql here

-- STEP 6: Run Concurrency Control
-- :r .\06_ConcurrencyControl.sql
-- OR copy contents of 06_ConcurrencyControl.sql here
*/

-- =============================================
-- Verification Queries
-- =============================================

PRINT '';
PRINT '=============================================';
PRINT 'Verification: Checking created objects';
PRINT '=============================================';
PRINT '';

-- List all triggers
PRINT 'TRIGGERS:';
SELECT name AS TriggerName, 
       OBJECT_NAME(parent_id) AS TableName,
       create_date AS CreatedDate
FROM sys.triggers 
WHERE is_ms_shipped = 0
ORDER BY TableName, TriggerName;

-- List all stored procedures (user-defined)
PRINT '';
PRINT 'STORED PROCEDURES:';
SELECT name AS ProcedureName,
       create_date AS CreatedDate
FROM sys.procedures 
WHERE is_ms_shipped = 0 AND name LIKE 'sp_%'
ORDER BY name;

-- List all functions
PRINT '';
PRINT 'FUNCTIONS:';
SELECT name AS FunctionName,
       type_desc AS FunctionType,
       create_date AS CreatedDate
FROM sys.objects 
WHERE type IN ('FN', 'IF', 'TF') AND name LIKE 'fn_%'
ORDER BY name;

-- List all database roles
PRINT '';
PRINT 'DATABASE ROLES:';
SELECT name AS RoleName,
       create_date AS CreatedDate
FROM sys.database_principals 
WHERE type = 'R' AND name LIKE 'Bookstore%'
ORDER BY name;

-- List RowVersion columns (for concurrency control)
PRINT '';
PRINT 'ROWVERSION COLUMNS (Concurrency Control):';
SELECT 
    OBJECT_NAME(object_id) AS TableName,
    name AS ColumnName,
    TYPE_NAME(user_type_id) AS DataType
FROM sys.columns 
WHERE TYPE_NAME(user_type_id) = 'timestamp'
AND OBJECT_NAME(object_id) IN ('Products', 'Orders', 'FlashSaleProducts', 'CartItems')
ORDER BY TableName;

PRINT '';
PRINT '=============================================';
PRINT 'Setup Complete!';
PRINT '=============================================';
PRINT '';
PRINT 'Next Steps:';
PRINT '1. Review created objects above';
PRINT '2. Update backup path in sp_BackupDatabase_* procedures';
PRINT '3. Change default passwords for SQL logins';
PRINT '4. Configure connection string in application';
PRINT '5. Test stored procedures with sample data';
PRINT '6. Consider enabling READ_COMMITTED_SNAPSHOT for better concurrency';
PRINT '=============================================';
GO

-- =============================================
-- Quick Test Script
-- =============================================
/*
-- Test Dashboard Stats
EXEC sp_GetDashboardStats;

-- Test Product Search
EXEC sp_SearchProducts @SearchTerm = 'sách';

-- Test Active Flash Sales
EXEC sp_GetActiveFlashSales;

-- Test User Stats
EXEC sp_GetUserStats @Days = 30;

-- Test Functions
SELECT dbo.fn_FormatVNDCurrency(150000);
SELECT dbo.fn_GetOrderStatusDisplay('Pending');
SELECT * FROM dbo.fn_GetFlashSaleProducts();

-- Test Concurrency Procedures
DECLARE @Success BIT, @NewStock INT, @ErrorMessage NVARCHAR(500);
EXEC sp_DecrementStock_Atomic @ProductId = 1, @Quantity = 1, 
    @Success = @Success OUTPUT, @NewStock = @NewStock OUTPUT, @ErrorMessage = @ErrorMessage OUTPUT;
SELECT @Success AS Success, @NewStock AS NewStock, @ErrorMessage AS ErrorMessage;
*/
