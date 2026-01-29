-- EMERGENCY FIX: Run this IMMEDIATELY in Supabase SQL Editor
-- This fixes the "operator does not exist: extensions.vector <=> extensions.vector" error
-- Step 1: Drop ALL variants of the function
DROP FUNCTION IF EXISTS match_test_embeddings(extensions.vector, float, int) CASCADE;
DROP FUNCTION IF EXISTS match_test_embeddings(vector, float, int) CASCADE;
DROP FUNCTION IF EXISTS match_test_embeddings(vector(768), float, int) CASCADE;
DROP FUNCTION IF EXISTS public.match_test_embeddings(extensions.vector, float, int) CASCADE;
DROP FUNCTION IF EXISTS public.match_test_embeddings(vector, float, int) CASCADE;
DROP FUNCTION IF EXISTS public.match_test_embeddings(vector(768), float, int) CASCADE;
-- Step 2: Recreate with CORRECT configuration
CREATE OR REPLACE FUNCTION public.match_test_embeddings (
        query_embedding vector(768),
        -- Use vector(768), NOT extensions.vector
        match_threshold float,
        match_count int
    ) RETURNS TABLE (
        id uuid,
        content text,
        metadata jsonb,
        similarity float
    ) LANGUAGE plpgsql STABLE
SET search_path TO public,
    pg_temp -- Use public, NOT extensions
    AS $$ BEGIN RETURN QUERY
SELECT test_embeddings.id,
    test_embeddings.content,
    test_embeddings.metadata,
    1 - (test_embeddings.embedding <=> query_embedding) AS similarity
FROM public.test_embeddings
WHERE auth.uid() = test_embeddings.user_id
    AND 1 - (test_embeddings.embedding <=> query_embedding) > match_threshold
ORDER BY similarity DESC
LIMIT match_count;
END;
$$;
-- Step 3: Grant permissions
GRANT EXECUTE ON FUNCTION public.match_test_embeddings(vector(768), float, int) TO authenticated;
-- Done! Test by running:
-- SELECT * FROM public.match_test_embeddings(ARRAY_FILL(0.1, ARRAY[768])::vector(768), 0.5, 5);