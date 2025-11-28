/*
=============================================
Bookstore Database Backup Scripts
=============================================
File: 04_DatabaseBackup.sql
Description: SQL Server backup and restore scripts
Version: 1.0
=============================================

IMPORTANT NOTES:
1. Run these scripts with appropriate permissions (db_backupoperator or sysadmin)
2. Modify @BackupPath to match your server's backup directory
3. Test restore procedures in a development environment first
4. Schedule regular backups using SQL Server Agent
=============================================
*/

USE master;
GO

-- =============================================
-- SECTION 1: Configuration Variables
-- =============================================
DECLARE @DatabaseName NVARCHAR(128) = 'BookstoreDb';
DECLARE @BackupPath NVARCHAR(500) = 'C:\SQLBackups\'; -- MODIFY THIS PATH

-- =============================================
-- STORED PROCEDURE: sp_BackupDatabase_Full
-- Description: Perform full database backup
-- =============================================
USE BookstoreDb;
GO

IF OBJECT_ID('dbo.sp_BackupDatabase_Full', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_BackupDatabase_Full;
GO

CREATE PROCEDURE sp_BackupDatabase_Full
    @BackupPath NVARCHAR(500) = 'C:\SQLBackups\',
    @Compress BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @DatabaseName NVARCHAR(128) = 'BookstoreDb';
    DECLARE @BackupFileName NVARCHAR(500);
    DECLARE @BackupName NVARCHAR(200);
    DECLARE @SQL NVARCHAR(MAX);
    
    -- Generate backup filename with timestamp
    SET @BackupFileName = @BackupPath + @DatabaseName + '_Full_' 
        + FORMAT(GETDATE(), 'yyyyMMdd_HHmmss') + '.bak';
    
    SET @BackupName = @DatabaseName + ' Full Backup ' + FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss');
    
    -- Build backup command
    SET @SQL = 'BACKUP DATABASE [' + @DatabaseName + '] ' +
               'TO DISK = ''' + @BackupFileName + ''' ' +
               'WITH NAME = ''' + @BackupName + ''', ' +
               'DESCRIPTION = ''Full backup of Bookstore database'', ' +
               'STATS = 10';
    
    IF @Compress = 1
        SET @SQL = @SQL + ', COMPRESSION';
    
    -- Execute backup
    BEGIN TRY
        EXEC sp_executesql @SQL;
        
        PRINT '=============================================';
        PRINT 'Full backup completed successfully!';
        PRINT 'Backup file: ' + @BackupFileName;
        PRINT 'Timestamp: ' + FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss');
        PRINT '=============================================';
        
        -- Log backup to notification (optional)
        DECLARE @AdminUserId NVARCHAR(450);
        SELECT TOP 1 @AdminUserId = u.Id 
        FROM dbo.AspNetUsers u
        INNER JOIN dbo.AspNetUserRoles ur ON u.Id = ur.UserId
        INNER JOIN dbo.AspNetRoles r ON ur.RoleId = r.Id
        WHERE r.Name = 'Admin';
        
        IF @AdminUserId IS NOT NULL
        BEGIN
            INSERT INTO dbo.Notifications (UserId, Message, CreatedAt)
            VALUES (@AdminUserId, 
                   N'✅ Database backup completed: ' + @BackupFileName, 
                   GETUTCDATE());
        END
    END TRY
    BEGIN CATCH
        PRINT 'ERROR: Backup failed!';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

PRINT 'Stored Procedure sp_BackupDatabase_Full created successfully.';
GO

-- =============================================
-- STORED PROCEDURE: sp_BackupDatabase_Differential
-- Description: Perform differential database backup
-- =============================================
IF OBJECT_ID('dbo.sp_BackupDatabase_Differential', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_BackupDatabase_Differential;
GO

CREATE PROCEDURE sp_BackupDatabase_Differential
    @BackupPath NVARCHAR(500) = 'C:\SQLBackups\',
    @Compress BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @DatabaseName NVARCHAR(128) = 'BookstoreDb';
    DECLARE @BackupFileName NVARCHAR(500);
    DECLARE @BackupName NVARCHAR(200);
    DECLARE @SQL NVARCHAR(MAX);
    
    -- Generate backup filename with timestamp
    SET @BackupFileName = @BackupPath + @DatabaseName + '_Diff_' 
        + FORMAT(GETDATE(), 'yyyyMMdd_HHmmss') + '.bak';
    
    SET @BackupName = @DatabaseName + ' Differential Backup ' + FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss');
    
    -- Build backup command
    SET @SQL = 'BACKUP DATABASE [' + @DatabaseName + '] ' +
               'TO DISK = ''' + @BackupFileName + ''' ' +
               'WITH DIFFERENTIAL, ' +
               'NAME = ''' + @BackupName + ''', ' +
               'DESCRIPTION = ''Differential backup of Bookstore database'', ' +
               'STATS = 10';
    
    IF @Compress = 1
        SET @SQL = @SQL + ', COMPRESSION';
    
    -- Execute backup
    BEGIN TRY
        EXEC sp_executesql @SQL;
        
        PRINT '=============================================';
        PRINT 'Differential backup completed successfully!';
        PRINT 'Backup file: ' + @BackupFileName;
        PRINT 'Timestamp: ' + FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss');
        PRINT '=============================================';
    END TRY
    BEGIN CATCH
        PRINT 'ERROR: Backup failed!';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

PRINT 'Stored Procedure sp_BackupDatabase_Differential created successfully.';
GO

-- =============================================
-- STORED PROCEDURE: sp_BackupTransactionLog
-- Description: Backup transaction log (for point-in-time recovery)
-- =============================================
IF OBJECT_ID('dbo.sp_BackupTransactionLog', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_BackupTransactionLog;
GO

CREATE PROCEDURE sp_BackupTransactionLog
    @BackupPath NVARCHAR(500) = 'C:\SQLBackups\',
    @Compress BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @DatabaseName NVARCHAR(128) = 'BookstoreDb';
    DECLARE @BackupFileName NVARCHAR(500);
    DECLARE @BackupName NVARCHAR(200);
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @RecoveryModel NVARCHAR(50);
    
    -- Check recovery model
    SELECT @RecoveryModel = recovery_model_desc 
    FROM sys.databases 
    WHERE name = @DatabaseName;
    
    IF @RecoveryModel = 'SIMPLE'
    BEGIN
        PRINT 'WARNING: Database is in SIMPLE recovery mode.';
        PRINT 'Transaction log backups are not supported in SIMPLE recovery mode.';
        PRINT 'To enable transaction log backups, change to FULL recovery mode:';
        PRINT 'ALTER DATABASE [' + @DatabaseName + '] SET RECOVERY FULL;';
        RETURN;
    END
    
    -- Generate backup filename with timestamp
    SET @BackupFileName = @BackupPath + @DatabaseName + '_Log_' 
        + FORMAT(GETDATE(), 'yyyyMMdd_HHmmss') + '.trn';
    
    SET @BackupName = @DatabaseName + ' Log Backup ' + FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss');
    
    -- Build backup command
    SET @SQL = 'BACKUP LOG [' + @DatabaseName + '] ' +
               'TO DISK = ''' + @BackupFileName + ''' ' +
               'WITH NAME = ''' + @BackupName + ''', ' +
               'DESCRIPTION = ''Transaction log backup of Bookstore database'', ' +
               'STATS = 10';
    
    IF @Compress = 1
        SET @SQL = @SQL + ', COMPRESSION';
    
    -- Execute backup
    BEGIN TRY
        EXEC sp_executesql @SQL;
        
        PRINT '=============================================';
        PRINT 'Transaction log backup completed successfully!';
        PRINT 'Backup file: ' + @BackupFileName;
        PRINT 'Timestamp: ' + FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss');
        PRINT '=============================================';
    END TRY
    BEGIN CATCH
        PRINT 'ERROR: Backup failed!';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO

PRINT 'Stored Procedure sp_BackupTransactionLog created successfully.';
GO

-- =============================================
-- STORED PROCEDURE: sp_GetBackupHistory
-- Description: Get backup history for the database
-- =============================================
IF OBJECT_ID('dbo.sp_GetBackupHistory', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetBackupHistory;
GO

CREATE PROCEDURE sp_GetBackupHistory
    @Days INT = 30
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        bs.database_name AS DatabaseName,
        CASE bs.type
            WHEN 'D' THEN 'Full'
            WHEN 'I' THEN 'Differential'
            WHEN 'L' THEN 'Transaction Log'
            ELSE 'Other'
        END AS BackupType,
        bs.backup_start_date AS StartDate,
        bs.backup_finish_date AS FinishDate,
        DATEDIFF(SECOND, bs.backup_start_date, bs.backup_finish_date) AS DurationSeconds,
        bs.backup_size / 1024 / 1024 AS SizeMB,
        bs.compressed_backup_size / 1024 / 1024 AS CompressedSizeMB,
        bmf.physical_device_name AS BackupFile,
        bs.user_name AS BackupUser
    FROM msdb.dbo.backupset bs
    INNER JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
    WHERE bs.database_name = 'BookstoreDb'
    AND bs.backup_start_date >= DATEADD(DAY, -@Days, GETDATE())
    ORDER BY bs.backup_start_date DESC;
END
GO

PRINT 'Stored Procedure sp_GetBackupHistory created successfully.';
GO

-- =============================================
-- STORED PROCEDURE: sp_CleanupOldBackups
-- Description: Delete old backup files (retention policy)
-- =============================================
IF OBJECT_ID('dbo.sp_CleanupOldBackups', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_CleanupOldBackups;
GO

CREATE PROCEDURE sp_CleanupOldBackups
    @BackupPath NVARCHAR(500) = 'C:\SQLBackups\',
    @RetentionDays INT = 30
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @DeleteDate DATETIME = DATEADD(DAY, -@RetentionDays, GETDATE());
    DECLARE @DeleteCmd NVARCHAR(500);
    
    PRINT '=============================================';
    PRINT 'Cleanup old backups older than ' + CAST(@RetentionDays AS NVARCHAR(10)) + ' days';
    PRINT 'Cutoff date: ' + FORMAT(@DeleteDate, 'yyyy-MM-dd HH:mm:ss');
    PRINT '=============================================';
    
    -- Use xp_delete_file to delete old backup files
    -- Parameters: file_type (0=backup), folder_path, file_extension, cutoff_date, subfolder_flag
    
    -- Delete full backups (.bak files)
    SET @DeleteCmd = 'EXECUTE master.dbo.xp_delete_file 0, ''' + @BackupPath + ''', ''bak'', ''' + 
                     CONVERT(NVARCHAR(50), @DeleteDate, 120) + ''', 0';
    
    BEGIN TRY
        EXEC sp_executesql @DeleteCmd;
        PRINT 'Old .bak files cleaned up successfully.';
    END TRY
    BEGIN CATCH
        PRINT 'Note: Could not delete .bak files. Error: ' + ERROR_MESSAGE();
    END CATCH
    
    -- Delete transaction log backups (.trn files)
    SET @DeleteCmd = 'EXECUTE master.dbo.xp_delete_file 0, ''' + @BackupPath + ''', ''trn'', ''' + 
                     CONVERT(NVARCHAR(50), @DeleteDate, 120) + ''', 0';
    
    BEGIN TRY
        EXEC sp_executesql @DeleteCmd;
        PRINT 'Old .trn files cleaned up successfully.';
    END TRY
    BEGIN CATCH
        PRINT 'Note: Could not delete .trn files. Error: ' + ERROR_MESSAGE();
    END CATCH
    
    PRINT '=============================================';
    PRINT 'Cleanup completed.';
    PRINT '=============================================';
END
GO

PRINT 'Stored Procedure sp_CleanupOldBackups created successfully.';
GO

-- =============================================
-- SAMPLE: SQL Server Agent Job Script for Scheduled Backups
-- Description: Template for creating backup maintenance plan
-- =============================================
/*
-- FULL BACKUP JOB (Weekly - Sunday at 2:00 AM)
USE msdb;
GO

EXEC sp_add_job
    @job_name = N'Bookstore_FullBackup_Weekly',
    @enabled = 1,
    @description = N'Weekly full backup of Bookstore database';

EXEC sp_add_jobstep
    @job_name = N'Bookstore_FullBackup_Weekly',
    @step_name = N'Execute Full Backup',
    @subsystem = N'TSQL',
    @command = N'EXEC BookstoreDb.dbo.sp_BackupDatabase_Full @BackupPath = ''C:\SQLBackups\'', @Compress = 1',
    @database_name = N'BookstoreDb';

EXEC sp_add_schedule
    @schedule_name = N'Weekly_Sunday_2AM',
    @freq_type = 8, -- Weekly
    @freq_interval = 1, -- Sunday
    @freq_recurrence_factor = 1,
    @active_start_time = 020000;

EXEC sp_attach_schedule
    @job_name = N'Bookstore_FullBackup_Weekly',
    @schedule_name = N'Weekly_Sunday_2AM';

EXEC sp_add_jobserver
    @job_name = N'Bookstore_FullBackup_Weekly';
GO

-- DIFFERENTIAL BACKUP JOB (Daily at 2:00 AM except Sunday)
EXEC sp_add_job
    @job_name = N'Bookstore_DiffBackup_Daily',
    @enabled = 1,
    @description = N'Daily differential backup of Bookstore database';

EXEC sp_add_jobstep
    @job_name = N'Bookstore_DiffBackup_Daily',
    @step_name = N'Execute Differential Backup',
    @subsystem = N'TSQL',
    @command = N'EXEC BookstoreDb.dbo.sp_BackupDatabase_Differential @BackupPath = ''C:\SQLBackups\'', @Compress = 1',
    @database_name = N'BookstoreDb';

EXEC sp_add_schedule
    @schedule_name = N'Daily_2AM_ExceptSunday',
    @freq_type = 8, -- Weekly
    @freq_interval = 126, -- Mon-Sat (2+4+8+16+32+64)
    @freq_recurrence_factor = 1,
    @active_start_time = 020000;

EXEC sp_attach_schedule
    @job_name = N'Bookstore_DiffBackup_Daily',
    @schedule_name = N'Daily_2AM_ExceptSunday';

EXEC sp_add_jobserver
    @job_name = N'Bookstore_DiffBackup_Daily';
GO

-- CLEANUP JOB (Weekly - Sunday at 4:00 AM)
EXEC sp_add_job
    @job_name = N'Bookstore_Cleanup_Weekly',
    @enabled = 1,
    @description = N'Weekly cleanup of old backup files';

EXEC sp_add_jobstep
    @job_name = N'Bookstore_Cleanup_Weekly',
    @step_name = N'Cleanup Old Backups',
    @subsystem = N'TSQL',
    @command = N'EXEC BookstoreDb.dbo.sp_CleanupOldBackups @BackupPath = ''C:\SQLBackups\'', @RetentionDays = 30',
    @database_name = N'BookstoreDb';

EXEC sp_add_schedule
    @schedule_name = N'Weekly_Sunday_4AM',
    @freq_type = 8,
    @freq_interval = 1,
    @freq_recurrence_factor = 1,
    @active_start_time = 040000;

EXEC sp_attach_schedule
    @job_name = N'Bookstore_Cleanup_Weekly',
    @schedule_name = N'Weekly_Sunday_4AM';

EXEC sp_add_jobserver
    @job_name = N'Bookstore_Cleanup_Weekly';
GO
*/

-- =============================================
-- RESTORE SCRIPTS (Reference Only - Use with caution)
-- =============================================
/*
-- RESTORE FROM FULL BACKUP
RESTORE DATABASE [BookstoreDb_Restored]
FROM DISK = 'C:\SQLBackups\BookstoreDb_Full_20241201_020000.bak'
WITH 
    MOVE 'BookstoreDb' TO 'C:\SQLData\BookstoreDb_Restored.mdf',
    MOVE 'BookstoreDb_log' TO 'C:\SQLData\BookstoreDb_Restored_log.ldf',
    NORECOVERY, -- Use NORECOVERY if applying differential/log backups
    STATS = 10;

-- RESTORE DIFFERENTIAL BACKUP (after full backup with NORECOVERY)
RESTORE DATABASE [BookstoreDb_Restored]
FROM DISK = 'C:\SQLBackups\BookstoreDb_Diff_20241202_020000.bak'
WITH 
    NORECOVERY,
    STATS = 10;

-- RESTORE TRANSACTION LOG (after differential with NORECOVERY)
RESTORE LOG [BookstoreDb_Restored]
FROM DISK = 'C:\SQLBackups\BookstoreDb_Log_20241202_120000.trn'
WITH 
    RECOVERY, -- Use RECOVERY for the last restore
    STATS = 10;

-- VERIFY BACKUP
RESTORE VERIFYONLY
FROM DISK = 'C:\SQLBackups\BookstoreDb_Full_20241201_020000.bak';

-- GET BACKUP FILE INFORMATION
RESTORE FILELISTONLY
FROM DISK = 'C:\SQLBackups\BookstoreDb_Full_20241201_020000.bak';

-- GET BACKUP HEADER INFORMATION
RESTORE HEADERONLY
FROM DISK = 'C:\SQLBackups\BookstoreDb_Full_20241201_020000.bak';
*/

-- =============================================
-- Summary: All backup procedures created
-- =============================================
PRINT '';
PRINT '=============================================';
PRINT 'Database Backup scripts created successfully!';
PRINT '=============================================';
PRINT '1. sp_BackupDatabase_Full - Full database backup';
PRINT '2. sp_BackupDatabase_Differential - Differential backup';
PRINT '3. sp_BackupTransactionLog - Transaction log backup';
PRINT '4. sp_GetBackupHistory - View backup history';
PRINT '5. sp_CleanupOldBackups - Cleanup old backup files';
PRINT '';
PRINT 'IMPORTANT: Modify @BackupPath before running backups!';
PRINT '=============================================';
GO
