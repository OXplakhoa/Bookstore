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

        try
        {
            await context.Database.MigrateAsync();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Lưu ý: Không thể chạy Migration tự động (có thể do Database đã được tạo thủ công). Lỗi: {ex.Message}");
            // Tiếp tục chạy ứng dụng thay vì dừng lại
        }

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
        else
        {
            // Nếu user đã tồn tại (do chạy script SQL), reset mật khẩu về mặc định để đảm bảo đăng nhập được
            bool needReset = false;
            try 
            {
                if (!await userManager.CheckPasswordAsync(admin, "Admin@123"))
                {
                    needReset = true;
                }
            }
            catch (FormatException)
            {
                // Hash trong database bị lỗi (không phải Base64 hợp lệ), cần reset ngay
                needReset = true;
            }

            if (needReset)
            {
                var token = await userManager.GeneratePasswordResetTokenAsync(admin);
                await userManager.ResetPasswordAsync(admin, token, "Admin@123");
            }
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