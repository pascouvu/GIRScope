# GIRScope Authentication Setup Guide

This guide will help you set up Supabase authentication for your GIRScope Flutter app.

## Prerequisites

1. A Supabase project (create one at https://supabase.com)
2. Flutter SDK installed
3. Your existing GIRScope app

## Step 1: Database Setup

### 1.1 Run the Database Schema

Execute the SQL script in `supabase_auth_schema.sql` in your Supabase SQL editor:

```sql
-- Copy and paste the entire content of supabase_auth_schema.sql
-- This will create the necessary tables and policies
```

### 1.2 Configure Supabase Auth Settings

1. Go to your Supabase project dashboard
2. Navigate to **Authentication** > **Settings**
3. Configure the following:
   - **Site URL**: Your app's URL (for web) or custom scheme (for mobile)
   - **Redirect URLs**: Add your app's redirect URLs
   - **Email Templates**: Customize the email templates if needed

## Step 2: App Configuration

### 2.1 Create Secret File

1. Create a new file `lib/secret.dart` (this file is already in .gitignore)
2. Copy the template from `lib/secret_template.dart` and replace with your actual credentials:

```dart
class SupabaseCredentials {
  static const String SUPABASE_URL = 'https://your-project.supabase.co';
  static const String SUPABASE_ANON_KEY = 'your-anon-key-here';
}
```

### 2.2 Get Your Supabase Credentials

1. Go to your Supabase project dashboard
2. Navigate to **Settings** > **API**
3. Copy the **Project URL** and **anon public** key
4. Paste them in your `secret.dart` file

## Step 3: Install Dependencies

Run the following command to install the new dependencies:

```bash
flutter pub get
```

## Step 4: Test the Authentication

### 4.1 Run the App

```bash
flutter run
```

### 4.2 Test the Flow

1. **Sign Up**: Create a new account with email verification
2. **Email Verification**: Check your email and enter the OTP code
3. **Sign In**: Test logging in with your credentials
4. **Password Reset**: Test the forgot password functionality
5. **Sign Out**: Test signing out from the profile screen

## Step 5: Business Setup (Optional)

If you want to associate users with businesses:

### 5.1 Create a Business

You can create businesses directly in the Supabase dashboard or add an admin interface later.

### 5.2 Associate Users with Businesses

Update the user's business_id in the users table:

```sql
UPDATE users 
SET business_id = 'your-business-id' 
WHERE email = 'user@example.com';
```

## Features Included

### ✅ Authentication Features
- [x] Email/Password Sign Up
- [x] Email/Password Sign In
- [x] Email Verification with OTP
- [x] Password Reset
- [x] Sign Out
- [x] Persistent Authentication State

### ✅ UI Features
- [x] Beautiful login screen with app logo
- [x] Sign up screen with form validation
- [x] OTP verification screen using pinput package
- [x] Forgot password screen
- [x] Profile screen with sign out option
- [x] Responsive design for mobile and web

### ✅ Security Features
- [x] Row Level Security (RLS) policies
- [x] Email verification required
- [x] Password validation
- [x] Secure token handling

### ✅ Database Features
- [x] Users table with business association
- [x] Businesses table for multi-tenant support
- [x] Automatic user profile creation on signup
- [x] Timestamp tracking

## File Structure

```
lib/
├── models/
│   ├── user.dart              # User model
│   └── business.dart          # Business model
├── services/
│   └── auth_service.dart      # Authentication service
├── views/
│   └── auth/
│       ├── login_screen.dart           # Login screen
│       ├── signup_screen.dart          # Sign up screen
│       ├── otp_verification_screen.dart # OTP verification
│       └── forgot_password_screen.dart  # Password reset
├── main.dart                  # Updated with auth wrapper
└── secret.dart               # Your Supabase credentials (create this)
```

## Troubleshooting

### Common Issues

1. **"Invalid API key" error**
   - Check your `secret.dart` file has the correct credentials
   - Ensure you're using the anon key, not the service role key

2. **Email not received**
   - Check spam folder
   - Verify email templates in Supabase dashboard
   - Check if email is enabled in Supabase auth settings

3. **OTP verification fails**
   - Ensure you're using the correct email
   - Check if the OTP hasn't expired (usually 1 hour)
   - Try resending the OTP

4. **App crashes on startup**
   - Ensure `secret.dart` file exists and has correct format
   - Check all dependencies are installed with `flutter pub get`

### Debug Mode

To see detailed error messages, run the app in debug mode:

```bash
flutter run --debug
```

## Next Steps

1. **Customize UI**: Modify the authentication screens to match your brand
2. **Add Business Management**: Create admin interfaces for managing businesses
3. **Add User Roles**: Implement role-based access control
4. **Add Social Auth**: Integrate Google, Apple, or other social providers
5. **Add Two-Factor Authentication**: Implement 2FA for enhanced security

## Support

If you encounter any issues:

1. Check the Supabase documentation: https://supabase.com/docs
2. Check Flutter documentation: https://flutter.dev/docs
3. Review the error messages in the debug console
4. Ensure all SQL scripts have been executed successfully

## Security Notes

- Never commit your `secret.dart` file to version control
- Use environment variables in production
- Regularly rotate your API keys
- Monitor your Supabase dashboard for suspicious activity
- Consider implementing rate limiting for authentication endpoints

