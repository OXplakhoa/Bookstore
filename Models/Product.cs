using System;

public class Product 
{
    public int ProductId { get; set; }
    public string? Title { get; set; }
    public string? Author { get; set; }
    public string? Description { get; set; }
    public decimal Price { get; set; }
    public int Stock { get; set; }
    public int CategoryId { get; set; }
    public bool IsActive { get; set; } = true;
    public Category? Category { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public ICollection<ProductImage>? ProductImages { get; set; }
    public virtual ICollection<FavoriteProduct>? FavoritedByUsers { get; set; } = new List<FavoriteProduct>();
    public virtual ICollection<RecentlyViewedProduct>? ViewedByUsers { get; set; } = new List<RecentlyViewedProduct>();
}