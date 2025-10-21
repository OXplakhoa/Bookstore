using System.ComponentModel.DataAnnotations;

public class RecentlyViewedProduct
{
    [Key]
    public int Id { get; set; } // Primary key
    public string ApplicationUserId { get; set; } = null!; // FK represent to the table(sql)
    public ApplicationUser? ApplicationUser { get; set; } // represents the relationship to the code
    // The Logic to use ApplicationUser here is to use .Include in EF Core queries 
// (e.g., context.RecentlyViewedProducts.Include(rvp => rvp.ApplicationUser).First(rvd => rvd.Id == someId);)
    public int ProductId { get; set; } 
    public Product? Product { get; set; }

    public DateTime ViewedAt { get; set; } // Timestamp of when the product was viewed
}