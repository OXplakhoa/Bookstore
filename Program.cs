using Bookstore.Data;
using Bookstore.Services;
using Bookstore.Settings;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.UI.Services;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(connectionString));

// Register email services BEFORE Identity configuration
builder.Services.Configure<EmailSettings>(builder.Configuration.GetSection("SendGrid"));
builder.Services.AddTransient<IEmailSender, EmailSender>();
builder.Services.AddSingleton<EmailTemplateService>();

// builder.Services.AddDefaultIdentity<ApplicationUser>(options => options.SignIn.RequireConfirmedAccount = true).AddEntityFrameworkStores<ApplicationDbContext>();

builder.Services.AddIdentity<ApplicationUser, IdentityRole>(options =>
{
    options.Password.RequireDigit = true;
    options.Password.RequiredLength = 6;
    // tùy chỉnh policy mật khẩu, email confirmation...
    options.SignIn.RequireConfirmedAccount = true; //Moved from the deleted AddDefaultIdentity
})
    .AddEntityFrameworkStores<ApplicationDbContext>()
    .AddDefaultTokenProviders()
    .AddDefaultUI();

builder.Services.AddControllersWithViews();
// Register User Activity Service (to track user activities through HttpContext)
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<IUserActivityService, UserActivityService>();

builder.Services.AddMemoryCache();

// Register Stripe services
builder.Services.Configure<StripeSettings>(builder.Configuration.GetSection("Stripe"));
builder.Services.AddScoped<IStripePaymentService, StripePaymentService>();

// Register Flash Sale services
builder.Services.AddScoped<IFlashSaleService, FlashSaleService>();
builder.Services.AddScoped<IFlashSaleNotificationService, FlashSaleNotificationService>();

// Register Database Service (for Stored Procedures & Functions)
builder.Services.AddScoped<IDatabaseService, DatabaseService>();

var app = builder.Build();

// pipeline (giữ nguyên cấu hình mặc định)
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllerRoute(
    name: "areas",
    pattern: "{area:exists}/{controller=Home}/{action=Index}/{id?}");

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");
//Add explicit webhook endpoint mapping
app.MapControllerRoute(
    name: "webhook",
    pattern: "webhook/{action=HandleWebhook}",
    defaults: new { controller = "StripeWebhook", action = "HandleWebhook" }
);

app.MapRazorPages(); // để Identity UI hoạt động

// gọi seed roles / data ở đây (mình sẽ thêm đoạn seed ở bước tiếp theo)
await DbInitializer.SeedAsync(app.Services);

app.Run();
