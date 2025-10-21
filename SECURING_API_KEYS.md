# 🔐 Securing API Keys - Quick Start Guide

## 🚨 YOU'VE EXPOSED API KEYS ON GITHUB!

**Don't panic!** Follow these steps to fix it quickly and securely.

---

## ⚡ Quick Fix (5 minutes)

### 1️⃣ Revoke OLD API Keys (DO THIS FIRST!)

**SendGrid:**
1. Go to https://app.sendgrid.com/settings/api_keys
2. DELETE the key: `SG.hdRBB63FTE6fyOdAZ70_4g...`
3. CREATE a new API key
4. Copy it (you'll need it in step 3)

**Stripe:**
1. Go to https://dashboard.stripe.com/test/apikeys
2. Click "Roll keys" button
3. Copy new Publishable Key and Secret Key
4. Go to https://dashboard.stripe.com/test/webhooks
5. Click your webhook → Copy new signing secret

### 2️⃣ Run the Security Fix Script

Open PowerShell in the project directory and run:

```powershell
.\SecurityFix.ps1
```

This script will:
- Initialize User Secrets
- Prompt you for NEW API keys
- Save them securely in User Secrets
- Clean appsettings.json
- Commit and push the fix to GitHub

### 3️⃣ Verify Everything Works

```powershell
dotnet run
```

Test:
- Registration (email should arrive)
- Checkout (Stripe should work)

---

## 📚 What Are User Secrets?

User Secrets are a secure way to store sensitive data during development:

- ✅ **NOT stored in your project**
- ✅ **NOT committed to Git**
- ✅ **Stored in your user profile** (`%APPDATA%\Microsoft\UserSecrets\`)
- ✅ **Automatically loaded** by ASP.NET Core in Development mode

### How to Add Secrets Manually

```powershell
# Add a single secret
dotnet user-secrets set "SendGrid:ApiKey" "YOUR_API_KEY_HERE"

# List all secrets
dotnet user-secrets list

# Remove a secret
dotnet user-secrets remove "SendGrid:ApiKey"

# Clear all secrets
dotnet user-secrets clear
```

---

## 🏭 Production Configuration

**DO NOT use User Secrets in production!** They only work in Development mode.

### For Production, Use:

#### Option 1: Environment Variables (Simple)
```powershell
# Azure App Service
az webapp config appsettings set --name my-app --resource-group my-rg \
  --settings SendGrid__ApiKey="YOUR_KEY" Stripe__SecretKey="YOUR_KEY"
```

#### Option 2: Azure Key Vault (Recommended)
```csharp
// Program.cs
builder.Configuration.AddAzureKeyVault(
    new Uri("https://your-keyvault.vault.azure.net/"),
    new DefaultAzureCredential());
```

#### Option 3: AWS Secrets Manager
```csharp
// Program.cs
builder.Configuration.AddSecretsManager();
```

---

## 📁 Configuration File Structure

After fixing, your project should have:

```
Bookstore/
├── appsettings.json              ✅ Safe to commit (no secrets)
├── appsettings.Example.json      ✅ Safe to commit (template)
├── appsettings.Development.json  ❌ Gitignored (env-specific)
├── appsettings.Production.json   ❌ Gitignored (env-specific)
└── User Secrets (outside repo)   ✅ Secure (not in Git)
    └── %APPDATA%\Microsoft\UserSecrets\9aa86914...\secrets.json
```

---

## 🔍 How ASP.NET Core Loads Configuration

**Priority Order** (highest to lowest):

1. **Command-line arguments**
2. **Environment variables**
3. **User Secrets** (Development only) ⬅️ YOUR SECRETS HERE
4. **appsettings.{Environment}.json**
5. **appsettings.json** ⬅️ PLACEHOLDERS HERE

This means:
- User Secrets **override** appsettings.json in Development
- Environment Variables **override** everything in Production

---

## ✅ Security Checklist

Before you can relax, make sure:

- [ ] Old SendGrid API key DELETED from SendGrid dashboard
- [ ] Old Stripe keys ROLLED in Stripe dashboard
- [ ] NEW keys stored in User Secrets (`dotnet user-secrets list`)
- [ ] `appsettings.json` has NO real API keys
- [ ] Changes committed and force-pushed to GitHub
- [ ] Application runs successfully (`dotnet run`)
- [ ] Email functionality works (test registration)
- [ ] Stripe functionality works (test checkout)
- [ ] GitHub repository shows NO secrets in latest commit

---

## 🆘 Troubleshooting

### Problem: "Configuration value not found"

**Solution:** Make sure you're running in Development mode:
```powershell
$env:ASPNETCORE_ENVIRONMENT = "Development"
dotnet run
```

### Problem: "User Secrets not loading"

**Solution:** Check your `.csproj` file has:
```xml
<PropertyGroup>
  <UserSecretsId>9aa86914-c5e1-48b2-b153-d87254757ddc</UserSecretsId>
</PropertyGroup>
```

### Problem: "Old keys still on GitHub"

**Solution:** You need to rewrite Git history:
```powershell
# Nuclear option - removes all history
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch appsettings.json" \
  --prune-empty --tag-name-filter cat -- --all

git push origin master --force
```

---

## 📖 Learn More

- **Full Guide:** See `SECURITY_INCIDENT_RESPONSE.md`
- **Microsoft Docs:** https://docs.microsoft.com/aspnet/core/security/app-secrets
- **User Secrets Tool:** https://docs.microsoft.com/aspnet/core/security/app-secrets#secret-manager
- **Azure Key Vault:** https://docs.microsoft.com/azure/key-vault/

---

## 💡 Best Practices

1. **Never commit secrets** - Use `.gitignore` properly
2. **Rotate keys regularly** - Every 90 days minimum
3. **Use different keys** - Separate keys for dev/staging/production
4. **Monitor usage** - Check SendGrid/Stripe dashboards for anomalies
5. **Enable 2FA** - On SendGrid and Stripe accounts
6. **Use minimal permissions** - Don't use "Full Access" if you only need "Mail Send"

---

## 🎯 Quick Commands Reference

```powershell
# Initialize User Secrets
dotnet user-secrets init

# Set a secret
dotnet user-secrets set "Key:Name" "value"

# List all secrets
dotnet user-secrets list

# Remove a secret
dotnet user-secrets remove "Key:Name"

# Clear all secrets
dotnet user-secrets clear

# Run the security fix script
.\SecurityFix.ps1

# Run the app
dotnet run

# Check git status
git status

# Force push (if needed)
git push origin master --force
```

---

**Remember:** This is a learning experience! Everyone makes mistakes. The important thing is to fix them quickly and learn for next time. 💪

---

**Created:** October 21, 2025  
**Last Updated:** October 21, 2025
