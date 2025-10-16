using Bookstore.Data;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

public static class DbInitializer 
{
    public static async Task SeedAsync(IServiceProvider serviceProvider)
    {
        using var scope = serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
        var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();

        await context.Database.MigrateAsync();

        // Roles
        string [] roles = new [] {"Admin", "Seller", "Customer"};
        foreach (var role in roles)
        {
            if (!await roleManager.RoleExistsAsync(role))
            {
                await roleManager.CreateAsync(new IdentityRole(role));
            }
        }
        // Create Admin User
        var adminEmail = "admin@bookstore.local";
        var admin = await userManager.FindByEmailAsync(adminEmail);
        if (admin == null)
        {
            admin = new ApplicationUser {UserName = adminEmail, Email = adminEmail, EmailConfirmed = true, FullName="Site Admin Local"};
            await userManager.CreateAsync(admin, "Admin@123"); //Need to change when in production
            await userManager.AddToRoleAsync(admin, "Admin");
        }
        //Seed Category + Product
        if (!context.Categories.Any())
        {
            var c1 = new Category { Name = "Tiểu thuyết", Slug = "tieu-thuyet", Description = "Tiểu thuyết Việt & ngoại" };
            var c2 = new Category { Name = "Kỹ năng sống", Slug = "ky-nang-song", Description = "Sách kỹ năng" };
            context.Categories.AddRange(c1,c2);
            await context.SaveChangesAsync();
            var p1 = new Product { Title = "Sách A", Author = "Tác giả A", Description = "Mô tả sách A", Price = 120000m, Stock = 50, CategoryId = c1.CategoryId };
            var p2 = new Product { Title = "Sách B", Author = "Tác giả B", Description = "Mô tả sách B", Price = 90000m, Stock = 30, CategoryId = c2.CategoryId };
            context.Products.AddRange(p1, p2);
            await context.SaveChangesAsync();
        }
        
    } 
}