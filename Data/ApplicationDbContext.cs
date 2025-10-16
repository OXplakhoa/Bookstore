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

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);
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
    }
}
