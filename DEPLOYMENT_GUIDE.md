# MoodShift AI - Deployment Guide

## 🎯 What Changed

We've migrated from **Firebase Secret Manager** to **Environment Variables** to reduce costs.

### Changes Made:
- ✅ Removed Secret Manager dependencies from cloud functions
- ✅ Added `dotenv` package for environment variable loading
- ✅ Created deployment scripts for dev and prod
- ✅ Updated `.gitignore` to protect credentials
- ✅ Created environment file templates

## 📋 Setup Instructions

### Step 1: Add Your Credentials

You need to create two files with your actual API keys:

#### `functions/.env.dev` (Development)
```bash
GROQ_API_KEY=your_actual_dev_groq_api_key
AWS_ACCESS_KEY=your_actual_dev_aws_access_key
AWS_SECRET_KEY=your_actual_dev_aws_secret_key
```

#### `functions/.env.prod` (Production)
```bash
GROQ_API_KEY=your_actual_prod_groq_api_key
AWS_ACCESS_KEY=your_actual_prod_aws_access_key
AWS_SECRET_KEY=your_actual_prod_aws_secret_key
```

**Where to get these:**
- **GROQ_API_KEY**: https://console.groq.com/keys
- **AWS_ACCESS_KEY & AWS_SECRET_KEY**: AWS IAM Console (for Polly service)

⚠️ **IMPORTANT**: These files are in `.gitignore` and will NOT be committed to git!

### Step 2: Deploy to Production

**First time or after migration from Secret Manager:**
```bash
./delete-and-deploy-prod.sh
```

**For subsequent deployments:**
```bash
./deploy-prod.sh
```

This will:
1. Copy `functions/.env.prod` to `functions/.env`
2. Build and deploy to `mood-shift-ai` (production)
3. Clean up the temporary `.env` file

### Step 3: Deploy to Development (Optional)

**First time or after migration from Secret Manager:**
```bash
./delete-and-deploy-dev.sh
```

**For subsequent deployments:**
```bash
./deploy-dev.sh
```

This will deploy to `mood-shift-ai-dev` (development environment).

## 🚀 Quick Deployment Commands

```bash
# Deploy to production
./deploy-prod.sh

# Deploy to development
./deploy-dev.sh
```

## 🔧 Manual Deployment (Alternative)

If you prefer manual control:

```bash
# Production
cp functions/.env.prod functions/.env
firebase deploy --only functions -P default
rm functions/.env

# Development
cp functions/.env.dev functions/.env
firebase deploy --only functions -P dev
rm functions/.env
```

## 📝 Files Created/Modified

### New Files:
- `functions/.env.example` - Template for environment variables
- `functions/.env.dev` - Development credentials (you need to fill this)
- `functions/.env.prod` - Production credentials (you need to fill this)
- `functions/README.md` - Functions-specific documentation
- `deploy-dev.sh` - Development deployment script
- `deploy-prod.sh` - Production deployment script
- `DEPLOYMENT_GUIDE.md` - This file

### Modified Files:
- `functions/package.json` - Added `dotenv` dependency
- `functions/src/processUserInput.ts` - Load env vars instead of secrets
- `functions/src/services/groqService.ts` - Removed Secret Manager
- `functions/src/services/pollyService.ts` - Removed Secret Manager
- `.gitignore` - Added environment files

## 🔒 Security Checklist

- ✅ Environment files are in `.gitignore`
- ✅ Deployment scripts clean up `.env` after use
- ✅ Separate credentials for dev and prod
- ✅ No credentials in source code

## 💰 Cost Savings

**Before**: ~$0.06 per 10,000 secret accesses with Secret Manager
**After**: $0 - Environment variables are free!

## ⚠️ Important Notes

1. **Never commit** `.env`, `.env.dev`, or `.env.prod` files
2. **Keep backups** of your credentials in a secure password manager
3. **Rotate keys** periodically for security
4. **Use different keys** for dev and prod environments

## 🐛 Troubleshooting

### Error: "Missing required environment variables"
- Make sure you've created `functions/.env.dev` or `functions/.env.prod`
- Verify all three variables are set (GROQ_API_KEY, AWS_ACCESS_KEY, AWS_SECRET_KEY)

### Error: "functions/.env.prod not found"
- Create the file from the template: `cp functions/.env.example functions/.env.prod`
- Add your actual credentials

### Build fails
- Run `cd functions && npm install` to ensure all dependencies are installed
- Run `npm run build` to check for TypeScript errors

## 📞 Next Steps

1. ✅ Add your credentials to `functions/.env.dev` and `functions/.env.prod`
2. ✅ Run `./deploy-prod.sh` to deploy to production
3. ✅ Test the app to ensure everything works
4. ✅ (Optional) Delete secrets from Google Cloud Secret Manager to stop billing

