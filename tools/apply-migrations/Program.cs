using System.Data;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

// Read connection string from appsettings.json in repo root, or use env var DB_CONN.
var config = new ConfigurationBuilder()
    .SetBasePath(Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", ".."))) // project root
    .AddJsonFile("appsettings.json", optional: true)
    .Build();

var connStr = Environment.GetEnvironmentVariable("DB_CONN") ?? config.GetConnectionString("DefaultConnection");
if (string.IsNullOrEmpty(connStr))
{
    Console.WriteLine("No connection string provided. Set DB_CONN env var or appsettings.json 'DefaultConnection'.");
    return;
}

Console.WriteLine($"Using connection string: {connStr}");

var sql = @"
-- Add FlashSaleDiscount column if missing
IF COL_LENGTH('dbo.OrderItems', 'FlashSaleDiscount') IS NULL
BEGIN
    ALTER TABLE dbo.OrderItems ADD FlashSaleDiscount DECIMAL(18,2) NULL;
    PRINT 'Added FlashSaleDiscount column to OrderItems';
END
ELSE
    PRINT 'FlashSaleDiscount already exists';

-- Add FlashSaleProductId column if missing
IF COL_LENGTH('dbo.OrderItems', 'FlashSaleProductId') IS NULL
BEGIN
    ALTER TABLE dbo.OrderItems ADD FlashSaleProductId INT NULL;
    PRINT 'Added FlashSaleProductId column to OrderItems';
END
ELSE
    PRINT 'FlashSaleProductId already exists';

-- Add WasOnFlashSale column if missing
IF COL_LENGTH('dbo.OrderItems', 'WasOnFlashSale') IS NULL
BEGIN
    ALTER TABLE dbo.OrderItems ADD WasOnFlashSale BIT NOT NULL CONSTRAINT DF_OrderItems_WasOnFlashSale DEFAULT 0;
    PRINT 'Added WasOnFlashSale column to OrderItems';
END
ELSE
    PRINT 'WasOnFlashSale already exists';

-- Add index if missing
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_OrderItems_FlashSaleProductId' AND object_id = OBJECT_ID('dbo.OrderItems'))
BEGIN
    CREATE INDEX IX_OrderItems_FlashSaleProductId ON dbo.OrderItems (FlashSaleProductId);
    PRINT 'Created index IX_OrderItems_FlashSaleProductId';
END
ELSE
    PRINT 'Index IX_OrderItems_FlashSaleProductId already exists';

-- Add FK if missing
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_OrderItems_FlashSaleProducts_FlashSaleProductId' AND parent_object_id = OBJECT_ID('dbo.OrderItems'))
BEGIN
    ALTER TABLE dbo.OrderItems ADD CONSTRAINT FK_OrderItems_FlashSaleProducts_FlashSaleProductId FOREIGN KEY (FlashSaleProductId) REFERENCES dbo.FlashSaleProducts(FlashSaleProductId);
    PRINT 'Added FK FK_OrderItems_FlashSaleProducts_FlashSaleProductId';
END
ELSE
    PRINT 'FK FK_OrderItems_FlashSaleProducts_FlashSaleProductId already exists';
";

using var conn = new SqlConnection(connStr);
await conn.OpenAsync();
using var cmd = conn.CreateCommand();
cmd.CommandType = CommandType.Text;
cmd.CommandText = sql;
cmd.CommandTimeout = 60;

try
{
    var result = await cmd.ExecuteNonQueryAsync();
    Console.WriteLine("Executed migration SQL (result rows: " + result + ")");
}
catch (Exception ex)
{
    Console.WriteLine("Error executing SQL: " + ex.Message);
}

await conn.CloseAsync();

// Verify columns are present
await conn.OpenAsync();
using var checkCmd = conn.CreateCommand();
checkCmd.CommandType = CommandType.Text;
checkCmd.CommandText = "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'OrderItems' ORDER BY ORDINAL_POSITION";
using var reader = await checkCmd.ExecuteReaderAsync();
var cols = new List<string>();
while (await reader.ReadAsync())
{
    cols.Add(reader.GetString(0));
}
Console.WriteLine("OrderItems columns: " + string.Join(", ", cols));
await conn.CloseAsync();
// Check migration history
await conn.OpenAsync();
using var histCmd = conn.CreateCommand();
histCmd.CommandType = CommandType.Text;
histCmd.CommandText = "SELECT MigrationId, ProductVersion FROM __EFMigrationsHistory ORDER BY MigrationId";
using var histReader = await histCmd.ExecuteReaderAsync();
var migrations = new List<string>();
while (await histReader.ReadAsync())
{
    migrations.Add(histReader.GetString(0) + " -> " + histReader.GetString(1));
}
Console.WriteLine("Applied migrations: " + (migrations.Any() ? string.Join(", ", migrations) : "(none)"));
await conn.CloseAsync();
