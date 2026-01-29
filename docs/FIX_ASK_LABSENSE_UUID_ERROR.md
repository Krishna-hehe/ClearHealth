# Fix for Ask LabSense PostgreSQL Type Mismatch Error

## Problem

The "Ask LabSense" feature was failing with:

```text
PostgresException: structure of query does not match function result type
(bigint vs uuid mismatch in column 1)
```

## Root Cause

Two conflicting SQL files defined the `match_test_embeddings` function differently:

- `scripts/setup_pgvector.sql` - Used `bigint` for id (WRONG)
- `supabase/setup_vector.sql` - Used `uuid` for id (CORRECT)

The database was using the wrong schema.

## Solution Applied

### 1. Created Migration File

**File:** `supabase/migrations/002_fix_vector_uuid_mismatch.sql`

This migration:

- Drops the old `match_test_embeddings` function
- Drops and recreates `test_embeddings` table with UUID primary key
- Recreates the function with correct UUID return type
- Adds proper RLS policies
- Creates performance indexes

### 2. Updated Reference Files

**Files Updated:**

- `scripts/setup_pgvector.sql` - Fixed to use UUID schema

## How to Apply the Fix

### Option A: Using Supabase Dashboard (Recommended)

1. **Open Supabase Dashboard**
   - Go to <https://supabase.com/dashboard>
   - Select your LabSense2 project

2. **Navigate to SQL Editor**
   - Click "SQL Editor" in the left sidebar
   - Click "New Query"

3. **Copy and Run Migration**
   - Open: `supabase/migrations/002_fix_vector_uuid_mismatch.sql`
   - Copy the entire contents
   - Paste into the SQL Editor
   - Click "Run" button

4. **Verify Success**
   - You should see "Success. No rows returned"
   - Check the "Table Editor" to confirm `test_embeddings` table exists with UUID id

### Option B: Using Supabase CLI

```powershell
# Navigate to project directory
cd c:\Users\krish\OneDrive\Desktop\LabSense2

# Link to your Supabase project (if not already linked)
supabase link --project-ref YOUR_PROJECT_REF

# Push the migration
supabase db push

# Or apply specific migration
supabase migration up
```

## Verification Steps

### 1. Test in SQL Editor

Run this query in Supabase SQL Editor:

```sql
-- Test the function
SELECT * FROM match_test_embeddings(
  ARRAY[0.1, 0.2, ...]::vector(768),  -- Replace with actual embedding
  0.5,
  5
);
```

### 2. Test in App

1. Launch the LabSense app
2. Navigate to "Ask LabSense"
3. Type a question: "Explain my latest lab report"
4. Verify no PostgreSQL errors appear

### 3. Check Table Schema

```sql
-- Verify table structure
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'test_embeddings';
```

Expected output should show `id` as `uuid` (not `bigint`).

## Important Notes

⚠️ **Data Loss Warning**: This migration drops and recreates the `test_embeddings` table. Any existing embeddings will be lost. If you have important data:

1. Backup first:

```sql
CREATE TABLE test_embeddings_backup AS 
SELECT * FROM test_embeddings;
```

1. After migration, you'll need to re-ingest lab results to regenerate embeddings.

## Rollback (If Needed)

If something goes wrong, you can rollback:

```sql
-- Drop the new table
DROP TABLE IF EXISTS public.test_embeddings CASCADE;

-- Restore from backup (if you created one)
CREATE TABLE public.test_embeddings AS 
SELECT * FROM test_embeddings_backup;
```

## Next Steps After Migration

1. **Re-ingest Lab Results**: The AI service will automatically create embeddings when users upload new lab reports
2. **Test Ask LabSense**: Verify the feature works end-to-end
3. **Monitor Logs**: Check for any new errors in Supabase logs

## Files Modified

- ✅ `supabase/migrations/002_fix_vector_uuid_mismatch.sql` (NEW)
- ✅ `scripts/setup_pgvector.sql` (UPDATED - UUID schema)
- ✅ `supabase/setup_vector.sql` (Already correct - no changes)

---

**Status:** Ready to apply migration
**Priority:** High - Blocks Ask LabSense feature
**Estimated Time:** 2-3 minutes
