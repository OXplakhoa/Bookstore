namespace Bookstore.Services;

/// <summary>
/// Interface cho Flash Sale Notification Service
/// </summary>
public interface IFlashSaleNotificationService
{
    /// <summary>
    /// Gửi email thông báo flash sale cho users có favorite products trong flash sale
    /// </summary>
    /// <param name="flashSaleId">ID của flash sale</param>
    /// <returns>Số lượng email đã gửi thành công</returns>
    Task<int> SendFlashSaleNotificationsAsync(int flashSaleId);

    /// <summary>
    /// Gửi email cho một user cụ thể về flash sale
    /// </summary>
    /// <param name="userId">ID của user</param>
    /// <param name="flashSaleId">ID của flash sale</param>
    /// <returns>True nếu gửi thành công</returns>
    Task<bool> SendFlashSaleNotificationToUserAsync(string userId, int flashSaleId);
}
