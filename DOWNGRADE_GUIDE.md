# Bookstore Project Downgrade Guide: .NET 9.0 → .NET Framework 4.7.2

This comprehensive guide provides instructions for downgrading the Bookstore project from .NET 9.0 ASP.NET Core MVC to .NET Framework 4.7.2 ASP.NET MVC. The guide also includes SQL scripts for database enhancements including Triggers, Stored Procedures, Functions, Database Backup, and User Role management.

## Table of Contents

1. [Project Overview](#project-overview)
2. [Database Schema](#database-schema)
3. [SQL Scripts](#sql-scripts)
   - [Triggers](#triggers)
   - [Stored Procedures](#stored-procedures)
   - [Functions](#functions)
   - [Database Backup](#database-backup)
   - [User Role Management](#user-role-management)
4. [Migration Guide](#migration-guide)
5. [Business Logic Migration](#business-logic-migration)

---

## Project Overview

### Current Technology Stack (.NET 9.0)
- **Framework**: .NET 9.0 ASP.NET Core MVC
- **Database**: SQL Server with Entity Framework Core 9.0
- **Authentication**: ASP.NET Core Identity
- **Payment**: Stripe Integration
- **Email**: SendGrid Integration
- **Architecture**: MVC with Areas (Admin, Identity)

### Target Technology Stack (.NET 4.7.2)
- **Framework**: .NET Framework 4.7.2 ASP.NET MVC
- **Database**: SQL Server with Entity Framework 6 or ADO.NET
- **Authentication**: ASP.NET Identity for MVC 5 or Forms Authentication
- **Payment**: Stripe Integration (legacy SDK)
- **Email**: SendGrid Integration (legacy SDK)
- **Architecture**: MVC with Areas

---

## Database Schema

### Core Tables

| Table | Description |
|-------|-------------|
| `AspNetUsers` | User accounts (extended with ApplicationUser) |
| `AspNetRoles` | User roles (Admin, Seller, Customer) |
| `AspNetUserRoles` | User-role mappings |
| `Categories` | Book categories |
| `Products` | Book products |
| `ProductImages` | Product image URLs |
| `Orders` | Customer orders |
| `OrderItems` | Order line items |
| `CartItems` | Shopping cart items |
| `Reviews` | Product reviews |
| `Payments` | Payment records |
| `Notifications` | User notifications |
| `Messages` | User messages |
| `FavoriteProducts` | User favorite products |
| `RecentlyViewedProducts` | Recently viewed products |
| `FlashSales` | Flash sale events |
| `FlashSaleProducts` | Products in flash sales |

### Entity Relationships

```
ApplicationUser (1) ──── (N) Orders
ApplicationUser (1) ──── (N) CartItems
ApplicationUser (1) ──── (N) FavoriteProducts
ApplicationUser (1) ──── (N) RecentlyViewedProducts

Category (1) ──── (N) Products

Product (1) ──── (N) ProductImages
Product (1) ──── (N) OrderItems
Product (1) ──── (N) CartItems
Product (1) ──── (N) Reviews
Product (1) ──── (N) FavoriteProducts
Product (1) ──── (N) RecentlyViewedProducts

Order (1) ──── (N) OrderItems
Order (1) ──── (N) Payments

FlashSale (1) ──── (N) FlashSaleProducts
Product (1) ──── (N) FlashSaleProducts
```

---

## SQL Scripts

All SQL scripts are located in the `Database/Scripts` directory.

### File Overview

| File | Description |
|------|-------------|
| `01_Triggers.sql` | Database triggers for audit and automation |
| `02_StoredProcedures.sql` | Stored procedures for business operations |
| `03_Functions.sql` | Scalar and table-valued functions |
| `04_DatabaseBackup.sql` | Backup and restore scripts |
| `05_UserRoleManagement.sql` | User role and permission scripts |

---

## Migration Guide

### Step 1: Create .NET 4.7.2 MVC Project

```bash
# Using Visual Studio
1. File > New > Project
2. Select "ASP.NET Web Application (.NET Framework)"
3. Choose .NET Framework 4.7.2
4. Select "MVC" template with "Individual User Accounts"
```

### Step 2: Install NuGet Packages

```powershell
# Entity Framework 6
Install-Package EntityFramework -Version 6.4.4

# ASP.NET Identity
Install-Package Microsoft.AspNet.Identity.EntityFramework
Install-Package Microsoft.AspNet.Identity.Owin
Install-Package Microsoft.Owin.Security.Cookies
Install-Package Microsoft.Owin.Host.SystemWeb

# Stripe (legacy)
Install-Package Stripe.net -Version 41.0.0

# SendGrid (legacy)
Install-Package SendGrid -Version 9.28.1

# JSON serialization
Install-Package Newtonsoft.Json
```

### Step 3: Database Configuration

**Web.config (replaces appsettings.json)**
```xml
<connectionStrings>
  <add name="DefaultConnection" 
       connectionString="Server=YOUR_SERVER;Database=BookstoreDb;Trusted_Connection=True;MultipleActiveResultSets=true;" 
       providerName="System.Data.SqlClient" />
</connectionStrings>

<appSettings>
  <add key="Stripe:PublishableKey" value="" />
  <add key="Stripe:SecretKey" value="" />
  <add key="Stripe:WebhookSecret" value="" />
  <add key="SendGrid:ApiKey" value="" />
  <add key="SendGrid:SenderEmail" value="" />
  <add key="SendGrid:SenderName" value="" />
</appSettings>
```

### Step 4: Convert Models

**Original (.NET 9.0)**
```csharp
public class Product 
{
    public int ProductId { get; set; }
    public string? Title { get; set; }
    public decimal Price { get; set; }
    // nullable reference types not available
}
```

**Converted (.NET 4.7.2)**
```csharp
public class Product 
{
    public int ProductId { get; set; }
    public string Title { get; set; }
    public decimal Price { get; set; }
    // Use null checks instead of nullable reference types
}
```

### Step 5: Convert DbContext

**Original (.NET 9.0)**
```csharp
namespace Bookstore.Data;

public class ApplicationDbContext : IdentityDbContext<ApplicationUser>
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options) { }
}
```

**Converted (.NET 4.7.2)**
```csharp
namespace Bookstore.Data
{
    public class ApplicationDbContext : IdentityDbContext<ApplicationUser>
    {
        public ApplicationDbContext()
            : base("DefaultConnection", throwIfV1Schema: false) { }

        public static ApplicationDbContext Create()
        {
            return new ApplicationDbContext();
        }
    }
}
```

### Step 6: Convert Controllers

**Original (.NET 9.0)**
```csharp
namespace Bookstore.Controllers;

public class HomeController : Controller
{
    private readonly ILogger<HomeController> _logger;
    
    public async Task<IActionResult> Index()
    {
        return View();
    }
}
```

**Converted (.NET 4.7.2)**
```csharp
namespace Bookstore.Controllers
{
    public class HomeController : Controller
    {
        public async Task<ActionResult> Index()
        {
            return View();
        }
    }
}
```

### Step 7: Convert Program.cs to Global.asax + Startup.cs

**Original Program.cs** is replaced with:

**Global.asax.cs**
```csharp
public class MvcApplication : System.Web.HttpApplication
{
    protected void Application_Start()
    {
        AreaRegistration.RegisterAllAreas();
        FilterConfig.RegisterGlobalFilters(GlobalFilters.Filters);
        RouteConfig.RegisterRoutes(RouteTable.Routes);
        BundleConfig.RegisterBundles(BundleTable.Bundles);
    }
}
```

**Startup.cs (OWIN)**
```csharp
public partial class Startup
{
    public void Configuration(IAppBuilder app)
    {
        ConfigureAuth(app);
    }
}
```

---

## Business Logic Migration

### Services to Migrate

| Service | Description | Migration Notes |
|---------|-------------|-----------------|
| `FlashSaleService` | Flash sale price and stock management | Convert to use Entity Framework 6, replace MemoryCache with System.Runtime.Caching |
| `StripePaymentService` | Stripe payment processing | Use Stripe.net 41.x with sync methods |
| `EmailSender` | SendGrid email sending | Use SendGrid 9.x |
| `EmailTemplateService` | Email template management | Direct port |
| `UserActivityService` | User activity tracking | Replace HttpContextAccessor with HttpContext.Current |
| `FlashSaleNotificationService` | Flash sale notifications | Direct port |

### Key Conversion Patterns

#### 1. Dependency Injection → Constructor/Factory Pattern

**Original**
```csharp
public class CartController : Controller
{
    private readonly ApplicationDbContext _context;
    private readonly UserManager<ApplicationUser> _userManager;

    public CartController(ApplicationDbContext context, UserManager<ApplicationUser> userManager)
    {
        _context = context;
        _userManager = userManager;
    }
}
```

**Converted**
```csharp
public class CartController : Controller
{
    private ApplicationDbContext _context = new ApplicationDbContext();
    private UserManager<ApplicationUser> _userManager;

    public CartController()
    {
        _userManager = new UserManager<ApplicationUser>(new UserStore<ApplicationUser>(_context));
    }
}
```

#### 2. Async/Await Patterns (mostly compatible)

.NET 4.7.2 supports async/await, so most async code can be ported directly. Replace:
- `Task<IActionResult>` → `Task<ActionResult>`
- `IActionResult` → `ActionResult`

#### 3. JSON Results

**Original**
```csharp
return Json(new { success = true, message = "Added" });
```

**Converted**
```csharp
return Json(new { success = true, message = "Added" }, JsonRequestBehavior.AllowGet);
```

#### 4. Authorization Attributes

**Original**
```csharp
[Authorize(Roles = "Admin")]
```

**Converted** (same syntax works with ASP.NET Identity for MVC 5)
```csharp
[Authorize(Roles = "Admin")]
```

#### 5. ViewBag/TempData (identical)

No changes needed - ViewBag and TempData work the same way.

### Areas Configuration

**Original** (`Program.cs`)
```csharp
app.MapControllerRoute(
    name: "areas",
    pattern: "{area:exists}/{controller=Home}/{action=Index}/{id?}");
```

**Converted** (`RouteConfig.cs`)
```csharp
routes.MapRoute(
    name: "Admin",
    url: "Admin/{controller}/{action}/{id}",
    defaults: new { controller = "Home", action = "Index", id = UrlParameter.Optional }
).DataTokens.Add("area", "Admin");
```

---

## Data Access Migration

### Using Stored Procedures

After running the SQL scripts from `Database/Scripts/02_StoredProcedures.sql`, you can call stored procedures from your .NET 4.7.2 application:

#### Entity Framework 6
```csharp
// Get dashboard statistics
var stats = _context.Database.SqlQuery<DashboardStats>("EXEC sp_GetDashboardStats").FirstOrDefault();

// Get products with pagination
var products = _context.Database.SqlQuery<ProductDTO>(
    "EXEC sp_GetProductsByCategory @CategoryId, @PageNumber, @PageSize",
    new SqlParameter("@CategoryId", categoryId),
    new SqlParameter("@PageNumber", page),
    new SqlParameter("@PageSize", pageSize)
).ToList();
```

#### ADO.NET (alternative)
```csharp
using (var connection = new SqlConnection(connectionString))
{
    using (var command = new SqlCommand("sp_GetDashboardStats", connection))
    {
        command.CommandType = CommandType.StoredProcedure;
        connection.Open();
        
        using (var reader = command.ExecuteReader())
        {
            // Read results
        }
    }
}
```

### Using Functions

```csharp
// Scalar function in LINQ
var effectivePrice = _context.Database.SqlQuery<decimal>(
    "SELECT dbo.fn_GetEffectivePrice(@ProductId)",
    new SqlParameter("@ProductId", productId)
).FirstOrDefault();

// Table-valued function
var topProducts = _context.Database.SqlQuery<Product>(
    "SELECT * FROM dbo.fn_GetTopSellingProducts(@TopN, @StartDate, @EndDate)",
    new SqlParameter("@TopN", 10),
    new SqlParameter("@StartDate", startDate),
    new SqlParameter("@EndDate", endDate)
).ToList();
```

---

## Migration Checklist

### Pre-Migration
- [ ] Backup current database
- [ ] Document all custom configurations
- [ ] List all NuGet packages and versions
- [ ] Test database backup/restore scripts

### Database
- [ ] Run trigger scripts (`01_Triggers.sql`)
- [ ] Run stored procedure scripts (`02_StoredProcedures.sql`)
- [ ] Run function scripts (`03_Functions.sql`)
- [ ] Run user role management scripts (`05_UserRoleManagement.sql`)
- [ ] Verify all database objects created successfully

### Application
- [ ] Create new .NET 4.7.2 MVC project
- [ ] Install required NuGet packages
- [ ] Convert all models (remove nullable reference types)
- [ ] Convert ApplicationDbContext
- [ ] Convert all controllers
- [ ] Convert all services
- [ ] Convert all views (minimal changes needed)
- [ ] Configure authentication (OWIN)
- [ ] Configure routing
- [ ] Set up Areas

### Testing
- [ ] Test user registration/login
- [ ] Test product listing
- [ ] Test cart functionality
- [ ] Test checkout process
- [ ] Test admin dashboard
- [ ] Test stored procedures
- [ ] Test flash sale functionality
- [ ] Test email notifications

### Post-Migration
- [ ] Performance testing
- [ ] Security audit
- [ ] Documentation update
- [ ] Team training

---

## Additional Resources

- [ASP.NET MVC 5 Documentation](https://docs.microsoft.com/en-us/aspnet/mvc/overview/)
- [Entity Framework 6 Documentation](https://docs.microsoft.com/en-us/ef/ef6/)
- [ASP.NET Identity for MVC 5](https://docs.microsoft.com/en-us/aspnet/identity/)
- [OWIN and Katana](https://docs.microsoft.com/en-us/aspnet/aspnet/overview/owin-and-katana/)

---

## Support

For issues during migration, refer to:
1. This guide's detailed sections
2. SQL scripts in `Database/Scripts/` directory
3. The original .NET 9.0 codebase for business logic reference
