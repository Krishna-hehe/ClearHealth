# PLAN-fix-profile-upload

## Context

- **User Request**: Fix issue where profile photo upload fails and settings changes are not saved.
- **Mode**: Fix
- **Status**: Implemented

## Problem Analysis

1. **Symptom**: Settings changes (data) are not saving. Photo upload likely appears to fail because the subsequent profile update fails.
2. **Root Cause**:
    - `SupabaseService.updateProfile` was using `upsert` but only providing `id` and the changed fields.
    - The `profiles` table has a **non-nullable** `user_id` column.
    - If a user's profile row does not exist (e.g., first-time save or failed signup trigger), the `upsert` attempts an `INSERT`.
    - This `INSERT` fails because `user_id` is missing and violates the `NOT NULL` constraint.
    - Consequently, `_saveProfile` and `_uploadPhoto` (which calls `updateProfile`) fail.

3. **Secondary Issues (Checked)**:
    - **Photo Upload**: `StorageService` uses `profiles` bucket. The path is valid. The bucket is public.
    - **Compression**: `FlutterImageCompress` might fail on Windows, but the code handles the exception and uses the original file.
    - **RLS**: Policies look standard (`uid = user_id`).

## Solution

- **Action**: Modify `SupabaseService.updateProfile` to explicitly include `'user_id': client.auth.currentUser!.id` in the `upsert` payload.
- **Outcome**: This ensures that if the profile row needs to be created, it satisfies the `user_id` constraint. Updates to existing rows will work as well (overwriting `user_id` with the same value is harmless).

## Tasks

- [x] **Step 1**: Analyze schema and code (Done).
- [x] **Step 2**: Edit `lib/core/supabase_service.dart` to add `user_id` (Done).
- [ ] **Step 3**: Verify fix (User to test).

## Verification

- **Manual Test**:
    1. Go to Settings.
    2. Change "First Name". Click "Save Changes".
    3. Verify success message.
    4. Upload a photo.
    5. Verify success message and photo update.
