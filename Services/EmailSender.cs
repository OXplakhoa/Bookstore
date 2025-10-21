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
            PlainTextContent = htmlMessage,
            HtmlContent = htmlMessage
        };

        message.AddTo(email);
        message.SetClickTracking(false, false); // disable click tracking for simplicity

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
}
