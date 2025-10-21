# 🚨 SECURITY INCIDENT RESPONSE GUIDE 🚨

## ⚠️ CRITICAL: API Keys Exposed on GitHub

**Date:** October 21, 2025  
**Severity:** CRITICAL  
**Status:** NEEDS IMMEDIATE ACTION

---

## 📋 Exposed Secrets

The following sensitive credentials were committed to GitHub:

### SendGrid API Key
- **Key:** `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`
- **Risk:** Attackers can send unlimited emails using your account
- **Action:** ❌ REVOKE IMMEDIATELY

### Stripe Test Keys
- **Publishable Key:** `pk_test_51SHiS6IMKUpn6ZtXA7DVGzt...`
- **Secret Key:** `sk_test_51SHiS6IMKUpn6ZtXFEy0t6R...`
- **Webhook Secret:** `whsec_233e21bc57c6dc7b085c20eeaf329ba2...`
- **Risk:** Attackers can access test payment data, create test charges
- **Action:** ❌ REVOKE IMMEDIATELY

---

## 🔥 IMMEDIATE ACTIONS (Do These NOW!)

### 1️⃣ Revoke SendGrid API Key

```
1. Visit: https://app.sendgrid.com/settings/api_keys
2. Find the exposed API key (starts with SG.hdRBB63FTE6...)
3. Click the trash icon to DELETE it
4. Create a NEW API key:
   - Click "Create API Key"
   - Name: "Bookstore Production Key"
   - Permissions: Full Access (or Mail Send only)
   - Click "Create & View"
   - COPY THE NEW KEY (you'll only see it once!)
```

### 2️⃣ Revoke Stripe Keys

```
1. Visit: https://dashboard.stripe.com/test/apikeys
2. Click "Roll keys" or "Reveal test key" → "Roll"
3. This generates NEW keys automatically
4. Copy the new Publishable and Secret keys
5. Update Webhook Secret:
   - Go to: https://dashboard.stripe.com/test/webhooks
   - Click your webhook endpoint
   - Click "Reveal" to see the new signing secret
```

### 3️⃣ Monitor for Unauthorized Usage

**SendGrid:**
- Check: https://app.sendgrid.com/statistics
- Look for unusual email activity since exposure

**Stripe:**
- Check: https://dashboard.stripe.com/test/payments
- Look for unauthorized test transactions

---

## 🛡️ STEP-BY-STEP FIX PROCESS

### Step 1: Create User Secrets Configuration

Run these commands in PowerShell:

```powershell
# Navigate to project directory
cd F:\code\NET\Bookstore

# Initialize user secrets (already done, but just in case)
dotnet user-secrets init

# Add NEW SendGrid secrets (use the NEW API key you created)
dotnet user-secrets set "SendGrid:ApiKey" "YOUR_NEW_SENDGRID_API_KEY_HERE"
dotnet user-secrets set "SendGrid:SenderEmail" "oxplakhoa@gmail.com"
dotnet user-secrets set "SendGrid:SenderName" "Bookstore"

# Add NEW Stripe secrets (use the NEW keys from Stripe)
dotnet user-secrets set "Stripe:PublishableKey" "YOUR_NEW_STRIPE_PUBLISHABLE_KEY"
dotnet user-secrets set "Stripe:SecretKey" "YOUR_NEW_STRIPE_SECRET_KEY"
dotnet user-secrets set "Stripe:WebhookSecret" "YOUR_NEW_WEBHOOK_SECRET"

# List all secrets to verify (optional)
dotnet user-secrets list
```

### Step 2: Create Template Configuration File

Create `appsettings.Example.json` as a template (safe to commit):

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=YOUR_SERVER;Database=BookstoreDb;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "Stripe": {
    "PublishableKey": "pk_test_YOUR_STRIPE_PUBLISHABLE_KEY_HERE",
    "SecretKey": "sk_test_YOUR_STRIPE_SECRET_KEY_HERE",
    "WebhookSecret": "whsec_YOUR_WEBHOOK_SECRET_HERE"
  },
  "SendGrid": {
    "ApiKey": "SG.YOUR_SENDGRID_API_KEY_HERE",
    "SenderEmail": "your-email@example.com",
    "SenderName": "Your App Name"
  },
  "AllowedHosts": "*"
}
```

### Step 3: Update appsettings.json (Remove Secrets)

Replace `appsettings.json` with placeholder values:

```json
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
```

### Step 4: Remove Sensitive Data from Git History

**Option A: Simple approach (recommended for small repos)**

```powershell
# WARNING: This rewrites Git history and requires force push!

# 1. Create a backup first
git tag backup-before-cleanup

# 2. Remove appsettings.json from Git tracking (but keep the file)
git rm --cached appsettings.json

# 3. Add the cleaned version
git add appsettings.json

# 4. Commit the change
git commit -m "Remove sensitive API keys from appsettings.json"

# 5. Force push to GitHub (THIS WILL REWRITE HISTORY!)
git push origin master --force

# 6. Notify collaborators (if any) to re-clone the repository
```

**Option B: Use BFG Repo-Cleaner (for thorough cleanup)**

```powershell
# Download BFG Repo-Cleaner
# Visit: https://rtyley.github.io/bfg-repo-cleaner/

# Run BFG to remove all traces of the sensitive data
java -jar bfg.jar --replace-text passwords.txt Bookstore.git

# Force push
git push origin master --force
```

### Step 5: Update .gitignore

Ensure `.gitignore` prevents future accidents:

```gitignore
# Sensitive configuration files
appsettings.json
appsettings.*.json
!appsettings.Example.json
*.secrets.json
secrets.json
.env
.env.local
.env.*.local
```

### Step 6: Verify User Secrets Work

```powershell
# Run the app - it should load secrets from User Secrets
dotnet run

# Check if emails are working (test registration)
# Check if Stripe is working (test checkout)
```

---

## 📚 How User Secrets Work

### Location of User Secrets:
```
Windows: %APPDATA%\Microsoft\UserSecrets\<user_secrets_id>\secrets.json
macOS/Linux: ~/.microsoft/usersecrets/<user_secrets_id>/secrets.json
```

### Your User Secrets ID:
Check `Bookstore.csproj` for:
```xml
<UserSecretsId>9aa86914-c5e1-48b2-b153-d87254757ddc</UserSecretsId>
```

Your secrets are stored at:
```
%APPDATA%\Microsoft\UserSecrets\9aa86914-c5e1-48b2-b153-d87254757ddc\secrets.json
```

### Configuration Priority (ASP.NET Core):
1. **User Secrets** (Development only) - HIGHEST PRIORITY
2. **Environment Variables**
3. **appsettings.{Environment}.json**
4. **appsettings.json** - LOWEST PRIORITY

This means User Secrets will override values in `appsettings.json`!

---

## 🚀 Production Deployment (Azure/AWS/etc.)

### For Azure App Service:

```powershell
# Set application settings via Azure Portal or CLI
az webapp config appsettings set --name bookstore-app --resource-group bookstore-rg --settings \
  "SendGrid__ApiKey=YOUR_API_KEY" \
  "Stripe__SecretKey=YOUR_SECRET_KEY"
```

### For Docker/Containers:

```yaml
# docker-compose.yml
environment:
  - SendGrid__ApiKey=${SENDGRID_API_KEY}
  - Stripe__SecretKey=${STRIPE_SECRET_KEY}
```

### For Azure Key Vault (Recommended for Production):

```csharp
// Program.cs
builder.Configuration.AddAzureKeyVault(
    new Uri($"https://{keyVaultName}.vault.azure.net/"),
    new DefaultAzureCredential());
```

---

## ✅ Verification Checklist

After completing all steps, verify:

- [ ] Old SendGrid API key has been DELETED from SendGrid dashboard
- [ ] Old Stripe keys have been ROLLED in Stripe dashboard
- [ ] New API keys stored in User Secrets (run `dotnet user-secrets list`)
- [ ] `appsettings.json` contains NO real API keys (only placeholders)
- [ ] `appsettings.Example.json` created with placeholder values
- [ ] `.gitignore` updated to ignore `appsettings.json`
- [ ] Git history cleaned (forced push to GitHub)
- [ ] Application runs successfully with User Secrets
- [ ] Registration email works with new SendGrid key
- [ ] Stripe checkout works with new Stripe keys
- [ ] GitHub repository shows NO sensitive data in latest commit
- [ ] GitHub repository history cleaned (or at least latest commit is safe)

---

## 🔐 Best Practices Going Forward

### 1. Never Commit Secrets
- Use User Secrets for local development
- Use Environment Variables for production
- Use Azure Key Vault / AWS Secrets Manager for enterprise

### 2. Regular Security Audits
```powershell
# Check for accidentally committed secrets
git log -p | grep -i "apikey\|secret\|password"
```

### 3. Pre-commit Hooks
Install `git-secrets` to prevent future accidents:
```powershell
# Install git-secrets
# Windows: Use chocolatey
choco install git-secrets

# Configure to scan for secrets
git secrets --install
git secrets --register-aws
```

### 4. Environment-Specific Configuration
```
appsettings.json                 → Base configuration (safe to commit)
appsettings.Development.json     → Dev overrides (gitignored)
appsettings.Production.json      → Prod overrides (gitignored)
User Secrets                     → Local secrets (not in git)
Environment Variables            → Production secrets (server-side)
```

---

## 📞 Support Resources

- **SendGrid Support:** https://support.sendgrid.com/
- **Stripe Support:** https://support.stripe.com/
- **GitHub Security:** https://docs.github.com/en/code-security
- **Microsoft User Secrets:** https://docs.microsoft.com/aspnet/core/security/app-secrets

---

## 🎯 Summary

**CRITICAL ACTIONS:**
1. ❌ Revoke old SendGrid API key NOW
2. ❌ Roll Stripe keys NOW
3. ✅ Store new keys in User Secrets
4. ✅ Remove secrets from appsettings.json
5. ✅ Clean Git history (force push)
6. ✅ Test that everything still works

**DON'T PANIC!** These are test keys, not production. But act quickly to prevent abuse.

---

**Last Updated:** October 21, 2025  
**Status:** PENDING COMPLETION
