using Bookstore.Data;
using Bookstore.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Bookstore.Areas.Admin.Controllers;

[Area("Admin")]
[Authorize (Roles = "Admin")]
public class FlashSalesController : Controller
{
    private readonly ApplicationDbContext _context;
    private readonly IFlashSaleService _flashSaleService;

    public FlashSalesController(ApplicationDbContext context, IFlashSaleService flashSaleService)
    {
        _context = context;
        _flashSaleService = flashSaleService;
    }
    // GET: Admin/FlashSale
    
}