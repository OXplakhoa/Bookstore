// Data/ApplicationDbContext.cs
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace Bookstore.Data;

public class ApplicationDbContext : IdentityDbContext<ApplicationUser>
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options) { }

    public DbSet<Category> Categories { get; set; }
    public DbSet<Product> Products { get; set; }
    public DbSet<ProductImage> ProductImages { get; set; }
    public DbSet<Order> Orders { get; set; }
    public DbSet<OrderItem> OrderItems { get; set; }
    public DbSet<CartItem> CartItems { get; set; }
    public DbSet<Review> Reviews { get; set; }
    public DbSet<Payment> Payments { get; set; }
    public DbSet<Notification> Notifications { get; set; }
    public DbSet<Message> Messages { get; set; }
    public DbSet<FavoriteProduct> FavoriteProducts { get; set; }
    public DbSet<RecentlyViewedProduct> RecentlyViewedProducts { get; set; }
    public DbSet<FlashSale> FlashSales { get; set; }
    public DbSet<FlashSaleProduct> FlashSaleProducts { get; set; }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);
        
        // Configure ApplicationUser table to handle triggers (fixes OUTPUT clause issue)
        builder.Entity<ApplicationUser>()
            .ToTable(tb => tb.HasTrigger("SomeTrigger"));
        
        // Add Configurations
        builder.Entity<Product>()
            .Property(p => p.Price)
            .HasColumnType("decimal(18,2)");
        builder.Entity<Payment>()
            .Property(p => p.Amount)
            .HasColumnType("decimal(18,2)");
        builder.Entity<Order>()
            .Property(o => o.Total)
            .HasColumnType("decimal(18,2)");
        builder.Entity<OrderItem>()
            .Property(o => o.UnitPrice)
            .HasColumnType("decimal(18,2)");
        builder.Entity<OrderItem>()
            .Property(o => o.FlashSaleDiscount)
            .HasColumnType("decimal(18,2)");
        builder.Entity<CartItem>()
            .Property(c => c.LockedPrice)
            .HasColumnType("decimal(18,2)");
        builder.Entity<FavoriteProduct>()
            .HasKey(fp => new { fp.ApplicationUserId, fp.ProductId });
        // Configure the many-to-many relationship through FavoriteProduct
        builder.Entity<FavoriteProduct>()
            .HasOne(fp => fp.ApplicationUser)
            .WithMany(u => u.FavoriteProducts)
            .HasForeignKey(fp => fp.ApplicationUserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Entity<FavoriteProduct>()
            .HasOne(fp => fp.Product)
            .WithMany(p => p.FavoritedByUsers)
            .HasForeignKey(fp => fp.ProductId)
            .OnDelete(DeleteBehavior.Cascade);
        // Configure RecentlyViewedProduct relationships
        builder.Entity<RecentlyViewedProduct>()
            .HasOne(rv => rv.ApplicationUser)
            .WithMany(u => u.RecentlyViewedProducts)
            .HasForeignKey(rv => rv.ApplicationUserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Entity<RecentlyViewedProduct>()
            .HasOne(rv => rv.Product)
            .WithMany(p => p.ViewedByUsers)
            .HasForeignKey(rv => rv.ProductId)
            .OnDelete(DeleteBehavior.Cascade);
        // Configure FlashSaleProduct relationships
        builder.Entity<FlashSaleProduct>()
            .Property(fsp => fsp.OriginalPrice)
            .HasColumnType("decimal(18,2)");
        builder.Entity<FlashSaleProduct>()
            .Property(fsp => fsp.SalePrice)
            .HasColumnType("decimal(18,2)");
        builder.Entity<FlashSaleProduct>()
            .Property(fs => fs.DiscountPercentage)
            .HasColumnType("decimal(5,2)");
        builder.Entity<FlashSaleProduct>()
            .HasOne(fsp => fsp.FlashSale)
            .WithMany(fs => fs.FlashSaleProducts)
            .HasForeignKey(fsp => fsp.FlashSaleId)
            .OnDelete(DeleteBehavior.Cascade);
        builder.Entity<FlashSaleProduct>()
            .HasOne(fsp => fsp.Product)
            .WithMany() // Not need to query from Product -> FlashSales (one way navigation)
            .HasForeignKey(fsp => fsp.ProductId)
            .OnDelete(DeleteBehavior.Restrict); // Prevent deletion of Product if associated with FlashSaleProduct
    }
}