using Bookstore.Settings;
using Microsoft.AspNetCore.Identity.UI.Services;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SendGrid;
using SendGrid.Helpers.Mail;

namespace Bookstore.Services;

public class EmailSender : IEmailSender
{
    private readonly EmailSettings _settings;
    private readonly ILogger<EmailSender> _logger;

    public EmailSender(IOptions<EmailSettings> settings, ILogger<EmailSender> logger)
    {
        _settings = settings.Value;
        _logger = logger;
    }

    public async Task SendEmailAsync(string email, string subject, string htmlMessage)
    {
        if (string.IsNullOrWhiteSpace(_settings.ApiKey))
        {
            throw new InvalidOperationException("SendGrid API key is not configured.");
        }

        if (string.IsNullOrWhiteSpace(_settings.SenderEmail))
        {
            throw new InvalidOperationException("SendGrid sender email is not configured.");
        }

        var client = new SendGridClient(_settings.ApiKey);
        var message = new SendGridMessage
        {
            From = new EmailAddress(_settings.SenderEmail, _settings.SenderName),
            Subject = subject,
            HtmlContent = htmlMessage
        };

        message.AddTo(email);
        
        // Tắt click tracking và open tracking để tránh spam filter
        message.SetClickTracking(false, false);
        message.SetOpenTracking(false);
        
        // Thêm plain text content để tránh spam filter
        message.PlainTextContent = StripHtml(htmlMessage);

        var response = await client.SendEmailAsync(message);
        if (!response.IsSuccessStatusCode)
        {
            _logger.LogError("Failed to send email to {Recipient}. StatusCode: {StatusCode}", email, response.StatusCode);
        }
        else
        {
            _logger.LogInformation("Queued email to {Recipient}", email);
        }
    }
    
    /// <summary>
    /// Loại bỏ HTML tags để tạo plain text version
    /// </summary>
    private string StripHtml(string html)
    {
        if (string.IsNullOrEmpty(html))
            return string.Empty;
            
        // Loại bỏ các HTML tags
        var text = System.Text.RegularExpressions.Regex.Replace(html, "<.*?>", string.Empty);
        // Decode HTML entities
        text = System.Net.WebUtility.HtmlDecode(text);
        // Loại bỏ nhiều dòng trống liên tiếp
        text = System.Text.RegularExpressions.Regex.Replace(text, @"(\r?\n\s*){3,}", "\n\n");
        return text.Trim();
    }
}
