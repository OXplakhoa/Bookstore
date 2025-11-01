using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Bookstore.Migrations
{
    /// <inheritdoc />
    public partial class AddFlashSaleToOrderItem : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<decimal>(
                name: "FlashSaleDiscount",
                table: "OrderItems",
                type: "decimal(18,2)",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "FlashSaleProductId",
                table: "OrderItems",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "WasOnFlashSale",
                table: "OrderItems",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.CreateIndex(
                name: "IX_OrderItems_FlashSaleProductId",
                table: "OrderItems",
                column: "FlashSaleProductId");

            migrationBuilder.AddForeignKey(
                name: "FK_OrderItems_FlashSaleProducts_FlashSaleProductId",
                table: "OrderItems",
                column: "FlashSaleProductId",
                principalTable: "FlashSaleProducts",
                principalColumn: "FlashSaleProductId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_OrderItems_FlashSaleProducts_FlashSaleProductId",
                table: "OrderItems");

            migrationBuilder.DropIndex(
                name: "IX_OrderItems_FlashSaleProductId",
                table: "OrderItems");

            migrationBuilder.DropColumn(
                name: "FlashSaleDiscount",
                table: "OrderItems");

            migrationBuilder.DropColumn(
                name: "FlashSaleProductId",
                table: "OrderItems");

            migrationBuilder.DropColumn(
                name: "WasOnFlashSale",
                table: "OrderItems");
        }
    }
}
