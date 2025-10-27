namespace Bookstore.ViewModels.Admin;

public class FlashSaleViewModel
{
    public int FlashSaleId { get; set; }
    public string? Name { get; set; }
    public string? Description { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public int ProductCount { get; set; }

    // Computed props
    public string Status { get; set; } = "Inactive";
    public string StatusBadgeClass => Status switch
    {
        "Active" => "badge bg-success",
        "Upcoming" => "badge bg-primary",
        "Expired" => "badge bg-secondary",
        _ => "badge bg-waring",
    };
    public TimeSpan TimeRemaining => EndDate - DateTime.UtcNow;
    public bool IsExpired => DateTime.UtcNow > EndDate;
    public bool IsUpcoming => DateTime.UtcNow < StartDate;
    public bool IsCurrentlyActive => IsActive && DateTime.UtcNow >= StartDate && DateTime.UtcNow <= EndDate;
}
