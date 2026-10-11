-- ====================================================================
-- TRADEVISION AI - SUPABASE DATABASE SCHEMA FOR USERS & AUTH
-- ====================================================================
-- Run this script in your Supabase Dashboard -> SQL Editor
-- This sets up the 'users' table, Row Level Security (RLS), and an
-- automatic trigger that syncs any Google OAuth signups directly into
-- the public.users database table.
-- ====================================================================

-- 1. Create the public.users table to store user credentials & profile
CREATE TABLE IF NOT EXISTS public.users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT,
    full_name TEXT,
    avatar_url TEXT,
    provider TEXT DEFAULT 'google',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Enable Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 3. Create RLS Policies
-- Allow users to view their own profile
DROP POLICY IF EXISTS "Users can read own profile" ON public.users;
CREATE POLICY "Users can read own profile"
    ON public.users
    FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

-- Allow users to insert or update their own profile
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
CREATE POLICY "Users can insert own profile"
    ON public.users
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
CREATE POLICY "Users can update own profile"
    ON public.users
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- 4. Automatic Trigger: Sync Auth Users into public.users
-- Whenever someone logs in or registers with Google or Email via Supabase Auth,
-- this function automatically extracts full_name, avatar_url, and email into public.users.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, full_name, avatar_url, provider, created_at, updated_at)
    VALUES (
        new.id,
        new.email,
        COALESCE(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', ''),
        COALESCE(new.raw_user_meta_data->>'avatar_url', new.raw_user_meta_data->>'picture', ''),
        COALESCE(new.raw_app_meta_data->>'provider', 'google'),
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = COALESCE(EXCLUDED.full_name, public.users.full_name),
        avatar_url = COALESCE(EXCLUDED.avatar_url, public.users.avatar_url),
        updated_at = NOW();
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Attach the trigger to auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT OR UPDATE ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 6. Real-Time Interactive Watchlist Table with Row Level Security (RLS)
CREATE TABLE IF NOT EXISTS public.user_watchlists (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    symbol TEXT NOT NULL,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id, symbol)
);

ALTER TABLE public.user_watchlists ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own watchlist" ON public.user_watchlists;
CREATE POLICY "Users can read own watchlist"
    ON public.user_watchlists
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own watchlist" ON public.user_watchlists;
CREATE POLICY "Users can insert own watchlist"
    ON public.user_watchlists
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own watchlist" ON public.user_watchlists;
CREATE POLICY "Users can delete own watchlist"
    ON public.user_watchlists
    FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

-- Enable Realtime publication on user_watchlists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'user_watchlists'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.user_watchlists;
    END IF;
EXCEPTION WHEN OTHERS THEN
    -- Ignore if publication already configured or in local sandbox
END $$;

-- ====================================================================
-- SETUP INSTRUCTIONS FOR GOOGLE AUTH IN SUPABASE CONSOLE:
-- ====================================================================
-- 1. Go to your Supabase Project Dashboard (https://supabase.com/dashboard)
-- 2. Navigate to: Authentication -> Providers -> Google
-- 3. Enable the Google provider toggle.
-- 4. Fill in:
--      - Client ID (From Google Cloud Console OAuth 2.0 Web Client ID)
--      - Client Secret (From Google Cloud Console)
-- 5. In Google Cloud Console, add Supabase's Redirect URL:
--      https://<YOUR_PROJECT_REF>.supabase.co/auth/v1/callback
-- 6. In Supabase Dashboard -> Authentication -> URL Configuration -> Redirect URLs:
--      Add the Android APK callback URL:
--      io.supabase.tradevision://login-callback/**
--      http://localhost:5050/** (for web testing)
-- 7. In TradeVision, paste your Supabase URL & Anon Key into:
--      frontend/lib/core/config/supabase_config.dart
-- ====================================================================
