public class FavoriteProduct
{
    public string ApplicationUserId { get; set; } = null!; // Foreign key to ApplicationUser
    public ApplicationUser? ApplicationUser { get; set; } // Navigation property
    public int ProductId { get; set; }
    public Product? Product { get; set; } 
}
// Similar logic to RecentlyViewedProduct model for EF Core relationships and navigation properties