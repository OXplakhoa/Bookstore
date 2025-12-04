-- =============================================
-- Bookstore Database Cleanup Script
-- =============================================
-- This script deletes all data from transactional and catalog tables,
-- but leaves the AspNet identity tables (AspNetUsers, AspNetRoles, etc.) intact.
-- It's useful for resetting the database to a clean state without losing user accounts.
--
-- The delete operations are ordered to respect foreign key constraints.
-- =============================================

USE Bookstore;
GO

PRINT N'Starting database cleanup. AspNet tables will not be affected.';
GO

-- To prevent foreign key constraint errors, we must delete data from tables in a specific order.
-- We start with tables that are "children" in foreign key relationships.

-- 1. Deleting from tables that depend on Orders, Products, Users, etc.
PRINT N'Deleting from linking and transactional tables...';
DELETE FROM [dbo].[Payments];
DELETE FROM [dbo].[OrderItems];
DELETE FROM [dbo].[CartItems];
DELETE FROM [dbo].[Reviews];
DELETE FROM [dbo].[FavoriteProducts];
DELETE FROM [dbo].[RecentlyViewedProducts];
DELETE FROM [dbo].[Notifications];
DELETE FROM [dbo].[Messages];
DELETE FROM [dbo].[ProductImages];
GO

-- 2. Deleting from core transactional tables after their dependencies are cleared.
PRINT N'Deleting from Orders...';
DELETE FROM [dbo].[Orders];
GO

-- 3. Deleting from FlashSale and Product-related tables.
PRINT N'Deleting from FlashSaleProducts...';
DELETE FROM [dbo].[FlashSaleProducts];
GO

PRINT N'Deleting from Products...';
DELETE FROM [dbo].[Products];
GO

PRINT N'Deleting from FlashSales...';
DELETE FROM [dbo].FlashSales;
GO

-- 4. Finally, deleting from main catalog tables.
PRINT N'Deleting from Categories...';
DELETE FROM [dbo].[Categories];
GO

/*
-- Optional: If you want to reset the IDENTITY seed for the tables, uncomment the lines below.
-- This will make the next inserted record have an ID of 1.

PRINT N'Resetting IDENTITY columns...';
DBCC CHECKIDENT ('[dbo].[Payments]', RESEED, 0);
DBCC CHECKIDENT ('[dbo].[OrderItems]', RESEED, 0);
DBCC CHECKIDENT ('[dbo].[CartItems]', RESEED, 0);
DBCC CHECKIDENT ('[dbo].[Reviews]', RESEED, 0);
DBCC CHECKIDENT ('[dbo].[RecentlyViewedProducts]', RESEED, 0);
DBCC CHECKIDENT ('[dbo].[Notifications]', RESEED, 0);
DBCC CHECKIDENT ('[dbo].[Messages]', RESEED, 0);
DBCC CHECKIDENT ('[dbo].[ProductImages]', RESEED, 0);
DBCC CHECKIDENT ('[dbo].[Orders]', RESEED, 0);
DBCC CHECKIDENT ('[dbo].[FlashSaleProducts]', RESEED, 0);
DBCC CHECKIDENT ('[dbo].[Products]', RESEED, 0);
DBCC CHECKIDENT ('[dbo].[FlashSales]', RESEED, 0);
DBCC CHECKIDENT ('[dbo].[Categories]', RESEED, 0);
GO
*/

PRINT N'Database cleanup script finished successfully.';
GO
