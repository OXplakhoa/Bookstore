public class CartItem 
{
    public int CartItemId { get; set; }
    public string? UserId { get; set; }
    public int ProductId { get; set; }
    public int Quantity { get; set; }
    public DateTime DateAdded { get; set; } = DateTime.UtcNow;
}