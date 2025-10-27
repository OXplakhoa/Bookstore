using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Bookstore.Migrations
{
    /// <inheritdoc />
    public partial class UpdateFlashSaleModels : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_FlashSaleProduct_FlashSale_FlashSaleId",
                table: "FlashSaleProduct");

            migrationBuilder.DropForeignKey(
                name: "FK_FlashSaleProduct_Products_ProductId",
                table: "FlashSaleProduct");

            migrationBuilder.DropPrimaryKey(
                name: "PK_FlashSaleProduct",
                table: "FlashSaleProduct");

            migrationBuilder.DropPrimaryKey(
                name: "PK_FlashSale",
                table: "FlashSale");

            migrationBuilder.RenameTable(
                name: "FlashSaleProduct",
                newName: "FlashSaleProducts");

            migrationBuilder.RenameTable(
                name: "FlashSale",
                newName: "FlashSales");

            migrationBuilder.RenameIndex(
                name: "IX_FlashSaleProduct_ProductId",
                table: "FlashSaleProducts",
                newName: "IX_FlashSaleProducts_ProductId");

            migrationBuilder.RenameIndex(
                name: "IX_FlashSaleProduct_FlashSaleId",
                table: "FlashSaleProducts",
                newName: "IX_FlashSaleProducts_FlashSaleId");

            migrationBuilder.AddPrimaryKey(
                name: "PK_FlashSaleProducts",
                table: "FlashSaleProducts",
                column: "FlashSaleProductId");

            migrationBuilder.AddPrimaryKey(
                name: "PK_FlashSales",
                table: "FlashSales",
                column: "FlashSaleId");

            migrationBuilder.AddForeignKey(
                name: "FK_FlashSaleProducts_FlashSales_FlashSaleId",
                table: "FlashSaleProducts",
                column: "FlashSaleId",
                principalTable: "FlashSales",
                principalColumn: "FlashSaleId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_FlashSaleProducts_Products_ProductId",
                table: "FlashSaleProducts",
                column: "ProductId",
                principalTable: "Products",
                principalColumn: "ProductId",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_FlashSaleProducts_FlashSales_FlashSaleId",
                table: "FlashSaleProducts");

            migrationBuilder.DropForeignKey(
                name: "FK_FlashSaleProducts_Products_ProductId",
                table: "FlashSaleProducts");

            migrationBuilder.DropPrimaryKey(
                name: "PK_FlashSales",
                table: "FlashSales");

            migrationBuilder.DropPrimaryKey(
                name: "PK_FlashSaleProducts",
                table: "FlashSaleProducts");

            migrationBuilder.RenameTable(
                name: "FlashSales",
                newName: "FlashSale");

            migrationBuilder.RenameTable(
                name: "FlashSaleProducts",
                newName: "FlashSaleProduct");

            migrationBuilder.RenameIndex(
                name: "IX_FlashSaleProducts_ProductId",
                table: "FlashSaleProduct",
                newName: "IX_FlashSaleProduct_ProductId");

            migrationBuilder.RenameIndex(
                name: "IX_FlashSaleProducts_FlashSaleId",
                table: "FlashSaleProduct",
                newName: "IX_FlashSaleProduct_FlashSaleId");

            migrationBuilder.AddPrimaryKey(
                name: "PK_FlashSale",
                table: "FlashSale",
                column: "FlashSaleId");

            migrationBuilder.AddPrimaryKey(
                name: "PK_FlashSaleProduct",
                table: "FlashSaleProduct",
                column: "FlashSaleProductId");

            migrationBuilder.AddForeignKey(
                name: "FK_FlashSaleProduct_FlashSale_FlashSaleId",
                table: "FlashSaleProduct",
                column: "FlashSaleId",
                principalTable: "FlashSale",
                principalColumn: "FlashSaleId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_FlashSaleProduct_Products_ProductId",
                table: "FlashSaleProduct",
                column: "ProductId",
                principalTable: "Products",
                principalColumn: "ProductId",
                onDelete: ReferentialAction.Restrict);
        }
    }
}
