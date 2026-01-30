# PLAN-fix-schema-mismatch

## Context

- **User Request**: Error updating profile (column 'country' not found) and error uploading photo (Blob URL).
- **Mode**: Fix
- **Status**: Proposed

## Problem Analysis

1. **Schema Mismatch**: The `profiles` table in Supabase is missing several columns that the app tries to write to.
    - **Missing**: `country`, `state`, `postal_code`, `phone_number`, `avatar_url`, `email_notifications`, `result_reminders`.
    - **Naming Mismatch**: App sends `dob`, DB has `date_of_birth`.
2. **Photo Upload Error**: "Could not load Blob from its URL" suggests an issue reading the image file, but the schema error on `avatar_url` (if it's missing) would also fail the save *after* upload. We fix the schema first.

## Proposed Solution

1. **Update Database Schema**:
    - Run SQL to add missing columns.
2. **Update Code**:
    - Map `dob` to `date_of_birth` in `SettingsPage`.
3. **Verify**:
    - Save profile info.
    - Upload photo.

## Database Changes

```sql
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS country text,
ADD COLUMN IF NOT EXISTS state text,
ADD COLUMN IF NOT EXISTS postal_code text,
ADD COLUMN IF NOT EXISTS phone_number text,
ADD COLUMN IF NOT EXISTS avatar_url text,
ADD COLUMN IF NOT EXISTS email_notifications boolean DEFAULT true,
ADD COLUMN IF NOT EXISTS result_reminders boolean DEFAULT true;
```

## Task Breakdown

- [ ] **Step 1**: Execute SQL migration to add columns.
- [ ] **Step 2**: Update `lib/features/settings/settings_page.dart` to send `date_of_birth` instead of `dob`.
- [ ] **Step 3**: Verify.
