-- DATABASE RECOVERY: Fix "Database error creating new user"
-- This script stabilizes the 'profiles' table and re-creates the Auth trigger.
-- Safe to run multiple times (idempotent)

BEGIN;

-- 1. Ensure the profiles table exists with correct structure
CREATE TABLE IF NOT EXISTS public.profiles (
    id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    first_name text NOT NULL DEFAULT 'User',
    last_name text DEFAULT '',
    relationship text NOT NULL DEFAULT 'Self',
    avatar_color text DEFAULT '0xFF2196F3',
    avatar_url text,
    date_of_birth date,
    gender text DEFAULT 'Other',
    conditions text[] DEFAULT '{}',
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL
);

-- 2. Add missing columns safely (idempotent)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'profiles'
        AND column_name = 'relationship'
    ) THEN
        ALTER TABLE public.profiles
        ADD COLUMN relationship text NOT NULL DEFAULT 'Self';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'profiles'
        AND column_name = 'gender'
    ) THEN
        ALTER TABLE public.profiles
        ADD COLUMN gender text DEFAULT 'Other';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'profiles'
        AND column_name = 'conditions'
    ) THEN
        ALTER TABLE public.profiles
        ADD COLUMN conditions text[] DEFAULT '{}';
    END IF;
END $$;

-- 3. Create or replace the trigger function with error handling
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    username text;
BEGIN
    -- Extract first_name from metadata, fallback to 'User'
    username := COALESCE(
        NULLIF(TRIM(new.raw_user_meta_data->>'first_name'), ''),
        'User'
    );

    -- Insert profile with error suppression on conflict
    INSERT INTO public.profiles (
        id,
        first_name,
        relationship,
        created_at,
        updated_at
    )
    VALUES (
        new.id,
        username,
        'Self',
        now(),
        now()
    )
    ON CONFLICT (id) DO NOTHING;

    RETURN new;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't block user creation
        RAISE WARNING 'Failed to create profile for user %: %', new.id, SQLERRM;
        RETURN new;
END;
$$;

-- 4. Re-create the trigger (idempotent)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- 5. Create updated_at trigger for automatic timestamp management
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS set_updated_at ON public.profiles;

CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- 6. Enable RLS and set up policies
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies (idempotent)
DROP POLICY IF EXISTS "Users can view their own profile." ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile." ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile." ON public.profiles;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone." ON public.profiles;

-- Create policies
CREATE POLICY "Users can view their own profile."
    ON public.profiles
    FOR SELECT
    USING (auth.uid() = id);

-- Note: INSERT policy allows users to manually create profiles if needed,
-- while the trigger (using SECURITY DEFINER) bypasses RLS automatically for initial profile creation.
CREATE POLICY "Users can insert their own profile."
    ON public.profiles
    FOR INSERT
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile."
    ON public.profiles
    FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- 7. Grant permissions
GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated;
GRANT ALL ON public.profiles TO service_role;
GRANT INSERT ON public.profiles TO service_role;



COMMIT;

-- Verification query (run separately to check)
-- SELECT
--     t.trigger_name,
--     t.event_manipulation,
--     t.action_timing,
--     p.proname as function_name
-- FROM information_schema.triggers t
-- JOIN pg_proc p ON p.oid = (
--     SELECT tgfoid FROM pg_trigger
--     WHERE tgname = t.trigger_name
-- )
-- WHERE t.event_object_table = 'users'
-- AND t.trigger_schema = 'auth';