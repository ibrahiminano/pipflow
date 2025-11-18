# Supabase Setup Guide

## Prerequisites
1. Create a Supabase account at https://supabase.com
2. Create a new project

## Database Schema

Run these SQL commands in your Supabase SQL editor:

### 1. User Profiles Table
```sql
-- Create profiles table
CREATE TABLE profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    is_premium BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- Create trigger to create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name)
    VALUES (new.id, new.email, new.raw_user_meta_data->>'full_name');
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

### 2. User Settings Table
```sql
CREATE TABLE user_settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE UNIQUE,
    theme TEXT DEFAULT 'black',
    notifications_enabled BOOLEAN DEFAULT true,
    biometric_enabled BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own settings" ON user_settings
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own settings" ON user_settings
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own settings" ON user_settings
    FOR INSERT WITH CHECK (auth.uid() = user_id);
```

### 3. Trading Accounts Table
```sql
CREATE TABLE trading_accounts (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    account_id TEXT NOT NULL,
    account_type TEXT NOT NULL,
    broker_name TEXT NOT NULL,
    server_name TEXT NOT NULL,
    platform_type TEXT NOT NULL,
    currency TEXT NOT NULL,
    leverage INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT true,
    connected_date TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE trading_accounts ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own trading accounts" ON trading_accounts
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own trading accounts" ON trading_accounts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own trading accounts" ON trading_accounts
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own trading accounts" ON trading_accounts
    FOR DELETE USING (auth.uid() = user_id);
```

### 4. Trades History Table
```sql
CREATE TABLE trades (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    account_id TEXT REFERENCES trading_accounts(id) ON DELETE CASCADE,
    position_id TEXT NOT NULL,
    symbol TEXT NOT NULL,
    type TEXT NOT NULL,
    volume DECIMAL NOT NULL,
    open_price DECIMAL NOT NULL,
    close_price DECIMAL,
    stop_loss DECIMAL,
    take_profit DECIMAL,
    commission DECIMAL DEFAULT 0,
    swap DECIMAL DEFAULT 0,
    profit DECIMAL DEFAULT 0,
    status TEXT NOT NULL,
    open_time TIMESTAMPTZ NOT NULL,
    close_time TIMESTAMPTZ,
    reason TEXT,
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE trades ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own trades" ON trades
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own trades" ON trades
    FOR INSERT WITH CHECK (auth.uid() = user_id);
```

### 5. AI Signals Table
```sql
CREATE TABLE ai_signals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    symbol TEXT NOT NULL,
    direction TEXT NOT NULL,
    entry_price DECIMAL NOT NULL,
    stop_loss DECIMAL NOT NULL,
    take_profit DECIMAL NOT NULL,
    confidence DECIMAL NOT NULL,
    reasoning TEXT,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ
);

-- Enable RLS
ALTER TABLE ai_signals ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own signals" ON ai_signals
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own signals" ON ai_signals
    FOR INSERT WITH CHECK (auth.uid() = user_id);
```

## Environment Configuration

1. Copy `.env.example` to `.env`
2. Add your Supabase project URL and anon key:

```bash
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

## Testing the Integration

1. Build and run the app
2. Try creating a new account
3. Check your Supabase dashboard to see if the user was created
4. Check the `profiles` and `user_settings` tables

## Troubleshooting

### Common Issues

1. **"Invalid API key"**: Make sure your anon key is correct and the project URL is valid
2. **"User already exists"**: The email is already registered
3. **Network errors**: Check your internet connection and Supabase project status

### Debug Mode

To enable Supabase debug logging, add this to your `AppDelegate.swift`:

```swift
#if DEBUG
Supabase.enableLogging = true
#endif
```