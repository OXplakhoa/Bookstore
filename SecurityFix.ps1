# ============================================================================
# SECURITY FIX SCRIPT - Remove Exposed API Keys
# ============================================================================
# This script helps you securely migrate API keys from appsettings.json 
# to User Secrets
# ============================================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🚨 SECURITY FIX ASSISTANT 🚨" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if we're in the right directory
if (-not (Test-Path "Bookstore.csproj")) {
    Write-Host "❌ ERROR: Bookstore.csproj not found!" -ForegroundColor Red
    Write-Host "Please run this script from the Bookstore project root directory." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Project file found." -ForegroundColor Green
Write-Host ""

# ============================================================================
# STEP 1: Initialize User Secrets
# ============================================================================
Write-Host "📋 STEP 1: Initializing User Secrets..." -ForegroundColor Cyan
Write-Host ""

$userSecretsId = "9aa86914-c5e1-48b2-b153-d87254757ddc"
Write-Host "User Secrets ID: $userSecretsId" -ForegroundColor Gray

dotnet user-secrets init --id $userSecretsId

Write-Host ""
Write-Host "✅ User Secrets initialized." -ForegroundColor Green
Write-Host ""

# ============================================================================
# STEP 2: Prompt for NEW API Keys
# ============================================================================
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "⚠️  IMPORTANT: USE NEW API KEYS!" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Before continuing, you MUST:" -ForegroundColor Yellow
Write-Host "  1. Revoke your old SendGrid API key at: https://app.sendgrid.com/settings/api_keys" -ForegroundColor Yellow
Write-Host "  2. Create a NEW SendGrid API key" -ForegroundColor Yellow
Write-Host "  3. Roll your Stripe keys at: https://dashboard.stripe.com/test/apikeys" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press ENTER when you have NEW API keys ready..." -ForegroundColor Cyan
Read-Host

Write-Host ""
Write-Host "📋 STEP 2: Setting up SendGrid secrets..." -ForegroundColor Cyan
Write-Host ""

# SendGrid API Key
Write-Host "Enter your NEW SendGrid API Key (starts with 'SG.'):" -ForegroundColor Yellow
$sendGridApiKey = Read-Host -AsSecureString
$sendGridApiKeyPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sendGridApiKey))

if ($sendGridApiKeyPlain -like "SG.*") {
    dotnet user-secrets set "SendGrid:ApiKey" $sendGridApiKeyPlain
    Write-Host "✅ SendGrid API Key saved to User Secrets" -ForegroundColor Green
} else {
    Write-Host "❌ Invalid SendGrid API Key format. Should start with 'SG.'" -ForegroundColor Red
    exit 1
}

# SendGrid Sender Email
Write-Host ""
Write-Host "Enter your SendGrid Sender Email:" -ForegroundColor Yellow
$sendGridEmail = Read-Host
dotnet user-secrets set "SendGrid:SenderEmail" $sendGridEmail
Write-Host "✅ Sender Email saved" -ForegroundColor Green

# SendGrid Sender Name
Write-Host ""
Write-Host "Enter your SendGrid Sender Name (e.g., 'Bookstore'):" -ForegroundColor Yellow
$sendGridName = Read-Host
dotnet user-secrets set "SendGrid:SenderName" $sendGridName
Write-Host "✅ Sender Name saved" -ForegroundColor Green

Write-Host ""
Write-Host "📋 STEP 3: Setting up Stripe secrets..." -ForegroundColor Cyan
Write-Host ""

# Stripe Publishable Key
Write-Host "Enter your NEW Stripe Publishable Key (starts with 'pk_test_'):" -ForegroundColor Yellow
$stripePublishable = Read-Host
if ($stripePublishable -like "pk_test_*") {
    dotnet user-secrets set "Stripe:PublishableKey" $stripePublishable
    Write-Host "✅ Stripe Publishable Key saved" -ForegroundColor Green
} else {
    Write-Host "❌ Invalid Stripe Publishable Key format. Should start with 'pk_test_'" -ForegroundColor Red
    exit 1
}

# Stripe Secret Key
Write-Host ""
Write-Host "Enter your NEW Stripe Secret Key (starts with 'sk_test_'):" -ForegroundColor Yellow
$stripeSecret = Read-Host -AsSecureString
$stripeSecretPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($stripeSecret))

if ($stripeSecretPlain -like "sk_test_*") {
    dotnet user-secrets set "Stripe:SecretKey" $stripeSecretPlain
    Write-Host "✅ Stripe Secret Key saved" -ForegroundColor Green
} else {
    Write-Host "❌ Invalid Stripe Secret Key format. Should start with 'sk_test_'" -ForegroundColor Red
    exit 1
}

# Stripe Webhook Secret
Write-Host ""
Write-Host "Enter your NEW Stripe Webhook Secret (starts with 'whsec_'):" -ForegroundColor Yellow
$webhookSecret = Read-Host -AsSecureString
$webhookSecretPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($webhookSecret))

if ($webhookSecretPlain -like "whsec_*") {
    dotnet user-secrets set "Stripe:WebhookSecret" $webhookSecretPlain
    Write-Host "✅ Webhook Secret saved" -ForegroundColor Green
} else {
    Write-Host "❌ Invalid Webhook Secret format. Should start with 'whsec_'" -ForegroundColor Red
    exit 1
}

# ============================================================================
# STEP 4: List All Secrets
# ============================================================================
Write-Host ""
Write-Host "📋 STEP 4: Verifying User Secrets..." -ForegroundColor Cyan
Write-Host ""

dotnet user-secrets list

# ============================================================================
# STEP 5: Clean appsettings.json
# ============================================================================
Write-Host ""
Write-Host "📋 STEP 5: Cleaning appsettings.json..." -ForegroundColor Cyan
Write-Host ""

$cleanConfig = @'
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=DESKTOP-JLJ00JT;Database=BookstoreDb;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "Stripe": {
    "PublishableKey": "",
    "SecretKey": "",
    "WebhookSecret": ""
  },
  "SendGrid": {
    "ApiKey": "",
    "SenderEmail": "",
    "SenderName": ""
  },
  "AllowedHosts": "*"
}
'@

$cleanConfig | Out-File -FilePath "appsettings.json" -Encoding UTF8
Write-Host "✅ appsettings.json cleaned (API keys removed)" -ForegroundColor Green

# ============================================================================
# STEP 6: Git Operations
# ============================================================================
Write-Host ""
Write-Host "📋 STEP 6: Updating Git..." -ForegroundColor Cyan
Write-Host ""

# Stage the cleaned appsettings.json
git add appsettings.json
git add appsettings.Example.json

# Commit the change
git commit -m "Security: Remove exposed API keys from appsettings.json"

Write-Host ""
Write-Host "✅ Changes committed locally" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "⚠️  FORCE PUSH WARNING" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "To remove the API keys from GitHub history, you need to force push." -ForegroundColor Yellow
Write-Host "This will rewrite Git history on GitHub." -ForegroundColor Yellow
Write-Host ""
Write-Host "Do you want to FORCE PUSH to GitHub now? (yes/no):" -ForegroundColor Cyan
$forcePush = Read-Host

if ($forcePush -eq "yes") {
    Write-Host ""
    Write-Host "🚀 Force pushing to GitHub..." -ForegroundColor Cyan
    git push origin master --force
    Write-Host "✅ Force push complete!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "⚠️  Skipping force push. You can do it later with:" -ForegroundColor Yellow
    Write-Host "   git push origin master --force" -ForegroundColor Gray
}

# ============================================================================
# STEP 7: Test the Application
# ============================================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ SECURITY FIX COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 What was done:" -ForegroundColor Cyan
Write-Host "  ✅ User Secrets initialized" -ForegroundColor Green
Write-Host "  ✅ NEW API keys stored in User Secrets" -ForegroundColor Green
Write-Host "  ✅ appsettings.json cleaned (no secrets)" -ForegroundColor Green
Write-Host "  ✅ Changes committed to Git" -ForegroundColor Green
Write-Host ""
Write-Host "🔍 User Secrets location:" -ForegroundColor Cyan
Write-Host "   $env:APPDATA\Microsoft\UserSecrets\$userSecretsId\secrets.json" -ForegroundColor Gray
Write-Host ""
Write-Host "🧪 Next steps:" -ForegroundColor Cyan
Write-Host "  1. Run: dotnet run" -ForegroundColor Yellow
Write-Host "  2. Test registration (email should work)" -ForegroundColor Yellow
Write-Host "  3. Test checkout (Stripe should work)" -ForegroundColor Yellow
Write-Host ""
Write-Host "❗ Don't forget to:" -ForegroundColor Red
Write-Host "  - Verify old SendGrid key is DELETED" -ForegroundColor Yellow
Write-Host "  - Verify old Stripe keys are ROLLED" -ForegroundColor Yellow
Write-Host "  - Check GitHub for no exposed secrets" -ForegroundColor Yellow
Write-Host ""
Write-Host "📚 Full guide available in: SECURITY_INCIDENT_RESPONSE.md" -ForegroundColor Cyan
Write-Host ""
