namespace Bookstore.Services;

/// <summary>
/// Service để tạo các email template chuyên nghiệp với HTML/CSS
/// </summary>
public class EmailTemplateService
{
    /// <summary>
    /// Tạo HTML email template cho xác nhận email
    /// </summary>
    public string GenerateEmailConfirmationTemplate(string confirmationUrl, string userName)
    {
        return $@"
<!DOCTYPE html>
<html lang=""en"">
<head>
    <meta charset=""UTF-8"">
    <meta name=""viewport"" content=""width=device-width, initial-scale=1.0"">
    <title>Confirm Your Email</title>
</head>
<body style=""margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f4f4;"">
    <table role=""presentation"" style=""width: 100%; border-collapse: collapse;"">
        <tr>
            <td align=""center"" style=""padding: 40px 0;"">
                <table role=""presentation"" style=""width: 600px; border-collapse: collapse; background-color: #ffffff; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1); border-radius: 8px;"">
                    <!-- Header -->
                    <tr>
                        <td style=""background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px 30px; text-align: center; border-radius: 8px 8px 0 0;"">
                            <h1 style=""margin: 0; color: #ffffff; font-size: 28px; font-weight: 600;"">
                                📚 Bookstore
                            </h1>
                            <p style=""margin: 10px 0 0 0; color: #e0e7ff; font-size: 14px;"">
                                Your Online Book Paradise
                            </p>
                        </td>
                    </tr>
                    
                    <!-- Content -->
                    <tr>
                        <td style=""padding: 40px 30px;"">
                            <h2 style=""margin: 0 0 20px 0; color: #333333; font-size: 24px; font-weight: 600;"">
                                Welcome to Bookstore! 🎉
                            </h2>
                            <p style=""margin: 0 0 20px 0; color: #666666; font-size: 16px; line-height: 1.6;"">
                                Hi{(string.IsNullOrEmpty(userName) ? "" : $" {userName}")},
                            </p>
                            <p style=""margin: 0 0 20px 0; color: #666666; font-size: 16px; line-height: 1.6;"">
                                Thank you for registering with Bookstore! We're excited to have you on board. 
                                To get started, please confirm your email address by clicking the button below.
                            </p>
                            
                            <!-- CTA Button -->
                            <table role=""presentation"" style=""margin: 30px 0; width: 100%;"">
                                <tr>
                                    <td align=""center"">
                                        <a href=""{confirmationUrl}"" style=""display: inline-block; padding: 16px 40px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: #ffffff; text-decoration: none; border-radius: 6px; font-weight: 600; font-size: 16px; box-shadow: 0 4px 6px rgba(102, 126, 234, 0.4);"">
                                            Confirm Email Address
                                        </a>
                                    </td>
                                </tr>
                            </table>
                            
                            <p style=""margin: 20px 0; color: #666666; font-size: 14px; line-height: 1.6;"">
                                Or copy and paste this link into your browser:
                            </p>
                            <p style=""margin: 0 0 20px 0; padding: 15px; background-color: #f8f9fa; border-left: 4px solid #667eea; word-break: break-all; font-size: 13px; color: #667eea;"">
                                {confirmationUrl}
                            </p>
                            
                            <p style=""margin: 20px 0 0 0; color: #999999; font-size: 13px; line-height: 1.6;"">
                                <strong>Note:</strong> This link will expire in 24 hours for security reasons.
                            </p>
                        </td>
                    </tr>
                    
                    <!-- Footer -->
                    <tr>
                        <td style=""background-color: #f8f9fa; padding: 30px; text-align: center; border-radius: 0 0 8px 8px; border-top: 1px solid #e9ecef;"">
                            <p style=""margin: 0 0 10px 0; color: #999999; font-size: 13px;"">
                                If you didn't create an account with Bookstore, please ignore this email.
                            </p>
                            <p style=""margin: 0; color: #999999; font-size: 12px;"">
                                © 2025 Bookstore. All rights reserved.
                            </p>
                            <p style=""margin: 10px 0 0 0; color: #999999; font-size: 12px;"">
                                This is an automated message, please do not reply to this email.
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>";
    }

    /// <summary>
    /// Tạo HTML email template cho reset password
    /// </summary>
    public string GeneratePasswordResetTemplate(string resetUrl, string userName)
    {
        return $@"
<!DOCTYPE html>
<html lang=""en"">
<head>
    <meta charset=""UTF-8"">
    <meta name=""viewport"" content=""width=device-width, initial-scale=1.0"">
    <title>Reset Your Password</title>
</head>
<body style=""margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f4f4;"">
    <table role=""presentation"" style=""width: 100%; border-collapse: collapse;"">
        <tr>
            <td align=""center"" style=""padding: 40px 0;"">
                <table role=""presentation"" style=""width: 600px; border-collapse: collapse; background-color: #ffffff; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1); border-radius: 8px;"">
                    <!-- Header -->
                    <tr>
                        <td style=""background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); padding: 40px 30px; text-align: center; border-radius: 8px 8px 0 0;"">
                            <h1 style=""margin: 0; color: #ffffff; font-size: 28px; font-weight: 600;"">
                                📚 Bookstore
                            </h1>
                            <p style=""margin: 10px 0 0 0; color: #ffe0e6; font-size: 14px;"">
                                Password Reset Request
                            </p>
                        </td>
                    </tr>
                    
                    <!-- Content -->
                    <tr>
                        <td style=""padding: 40px 30px;"">
                            <h2 style=""margin: 0 0 20px 0; color: #333333; font-size: 24px; font-weight: 600;"">
                                Reset Your Password 🔐
                            </h2>
                            <p style=""margin: 0 0 20px 0; color: #666666; font-size: 16px; line-height: 1.6;"">
                                Hi{(string.IsNullOrEmpty(userName) ? "" : $" {userName}")},
                            </p>
                            <p style=""margin: 0 0 20px 0; color: #666666; font-size: 16px; line-height: 1.6;"">
                                We received a request to reset the password for your Bookstore account. 
                                Click the button below to create a new password.
                            </p>
                            
                            <!-- CTA Button -->
                            <table role=""presentation"" style=""margin: 30px 0; width: 100%;"">
                                <tr>
                                    <td align=""center"">
                                        <a href=""{resetUrl}"" style=""display: inline-block; padding: 16px 40px; background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: #ffffff; text-decoration: none; border-radius: 6px; font-weight: 600; font-size: 16px; box-shadow: 0 4px 6px rgba(245, 87, 108, 0.4);"">
                                            Reset Password
                                        </a>
                                    </td>
                                </tr>
                            </table>
                            
                            <p style=""margin: 20px 0; color: #666666; font-size: 14px; line-height: 1.6;"">
                                Or copy and paste this link into your browser:
                            </p>
                            <p style=""margin: 0 0 20px 0; padding: 15px; background-color: #fff5f5; border-left: 4px solid #f5576c; word-break: break-all; font-size: 13px; color: #f5576c;"">
                                {resetUrl}
                            </p>
                            
                            <div style=""margin: 30px 0; padding: 20px; background-color: #fff8e1; border-radius: 6px; border-left: 4px solid #ffc107;"">
                                <p style=""margin: 0; color: #856404; font-size: 14px; line-height: 1.6;"">
                                    <strong>⚠️ Security Notice:</strong><br>
                                    • This link will expire in 1 hour<br>
                                    • If you didn't request this, please ignore this email<br>
                                    • Your password won't change until you access the link above
                                </p>
                            </div>
                        </td>
                    </tr>
                    
                    <!-- Footer -->
                    <tr>
                        <td style=""background-color: #f8f9fa; padding: 30px; text-align: center; border-radius: 0 0 8px 8px; border-top: 1px solid #e9ecef;"">
                            <p style=""margin: 0 0 10px 0; color: #999999; font-size: 13px;"">
                                If you didn't request a password reset, you can safely ignore this email.
                            </p>
                            <p style=""margin: 0; color: #999999; font-size: 12px;"">
                                © 2025 Bookstore. All rights reserved.
                            </p>
                            <p style=""margin: 10px 0 0 0; color: #999999; font-size: 12px;"">
                                This is an automated message, please do not reply to this email.
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>";
    }

    /// <summary>
    /// Tạo plain text version cho email clients không hỗ trợ HTML
    /// </summary>
    public string GenerateEmailConfirmationPlainText(string confirmationUrl, string userName)
    {
        return $@"Welcome to Bookstore!

Hi{(string.IsNullOrEmpty(userName) ? "" : $" {userName}")},

Thank you for registering with Bookstore! We're excited to have you on board.

To get started, please confirm your email address by visiting this link:

{confirmationUrl}

Note: This link will expire in 24 hours for security reasons.

If you didn't create an account with Bookstore, please ignore this email.

---
© 2025 Bookstore. All rights reserved.
This is an automated message, please do not reply to this email.";
    }

    /// <summary>
    /// Tạo plain text version cho password reset
    /// </summary>
    public string GeneratePasswordResetPlainText(string resetUrl, string userName)
    {
        return $@"Reset Your Password - Bookstore

Hi{(string.IsNullOrEmpty(userName) ? "" : $" {userName}")},

We received a request to reset the password for your Bookstore account.

To reset your password, visit this link:

{resetUrl}

SECURITY NOTICE:
• This link will expire in 1 hour
• If you didn't request this, please ignore this email
• Your password won't change until you access the link above

If you didn't request a password reset, you can safely ignore this email.

---
© 2025 Bookstore. All rights reserved.
This is an automated message, please do not reply to this email.";
    }
}
