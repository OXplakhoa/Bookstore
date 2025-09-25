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
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public ICollection<ProductImage>? ProductImages { get; set; }
}