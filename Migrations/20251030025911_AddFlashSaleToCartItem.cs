using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Bookstore.Migrations
{
    /// <inheritdoc />
    public partial class AddFlashSaleToCartItem : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "FlashSaleProductId",
                table: "CartItems",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "LockedPrice",
                table: "CartItems",
                type: "decimal(18,2)",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_CartItems_FlashSaleProductId",
                table: "CartItems",
                column: "FlashSaleProductId");

            migrationBuilder.AddForeignKey(
                name: "FK_CartItems_FlashSaleProducts_FlashSaleProductId",
                table: "CartItems",
                column: "FlashSaleProductId",
                principalTable: "FlashSaleProducts",
                principalColumn: "FlashSaleProductId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_CartItems_FlashSaleProducts_FlashSaleProductId",
                table: "CartItems");

            migrationBuilder.DropIndex(
                name: "IX_CartItems_FlashSaleProductId",
                table: "CartItems");

            migrationBuilder.DropColumn(
                name: "FlashSaleProductId",
                table: "CartItems");

            migrationBuilder.DropColumn(
                name: "LockedPrice",
                table: "CartItems");
        }
    }
}
