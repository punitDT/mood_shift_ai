# MoodShift AI Cloud Functions

## Environment Setup

This project uses environment variables instead of Firebase Secret Manager to reduce costs.

### 1. Create Environment Files

Create two files with your actual credentials:

**`functions/.env.dev`** - Development credentials
```bash
GROQ_API_KEY=your_dev_groq_api_key
AWS_ACCESS_KEY=your_dev_aws_access_key
AWS_SECRET_KEY=your_dev_aws_secret_key
```

**`functions/.env.prod`** - Production credentials
```bash
GROQ_API_KEY=your_prod_groq_api_key
AWS_ACCESS_KEY=your_prod_aws_access_key
AWS_SECRET_KEY=your_prod_aws_secret_key
```

⚠️ **Important**: These files are in `.gitignore` and should NEVER be committed to git!

### 2. Deploy to Development

```bash
./deploy-dev.sh
```

This will:
1. Copy `.env.dev` to `.env`
2. Deploy to `mood-shift-ai-dev` project
3. Clean up the `.env` file

### 3. Deploy to Production

```bash
./deploy-prod.sh
```

This will:
1. Copy `.env.prod` to `.env`
2. Deploy to `mood-shift-ai` project
3. Clean up the `.env` file

## Manual Deployment

If you prefer to deploy manually:

```bash
# For development
cp functions/.env.dev functions/.env
firebase deploy --only functions -P dev
rm functions/.env

# For production
cp functions/.env.prod functions/.env
firebase deploy --only functions -P default
rm functions/.env
```

## Local Testing

For local testing with emulators:

```bash
# Copy your dev environment
cp functions/.env.dev functions/.env

# Run emulators
npm run serve

# Don't forget to clean up
rm functions/.env
```

## Migration from Secret Manager

If you're migrating from Secret Manager:

1. Get your secrets from Google Cloud Console
2. Add them to `.env.dev` and `.env.prod`
3. Deploy using the new scripts
4. (Optional) Delete the secrets from Secret Manager to stop billing

## Security Notes

- ✅ Environment files are in `.gitignore`
- ✅ Deployment scripts clean up `.env` after deployment
- ✅ Never commit `.env`, `.env.dev`, or `.env.prod` files
- ✅ Keep production and development credentials separate

