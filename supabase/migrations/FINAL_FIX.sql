-- FINAL SQL FIX
-- Problem: The previous fix removed 'extensions' from search_path, causing "operator does not exist"
-- Solution: Restore search_path to include BOTH extensions and public
-- 1. Drop all variants to ensure a clean slate
DROP FUNCTION IF EXISTS public.match_test_embeddings(vector, float, int);
DROP FUNCTION IF EXISTS public.match_test_embeddings(extensions.vector, float, int);
DROP FUNCTION IF EXISTS public.match_test_embeddings(vector(768), float, int);
-- 2. Recreate the function with the COMPLETE search path
CREATE OR REPLACE FUNCTION public.match_test_embeddings (
        query_embedding vector(768),
        match_threshold float,
        match_count int
    ) RETURNS TABLE (
        id uuid,
        content text,
        metadata jsonb,
        similarity float
    ) LANGUAGE plpgsql STABLE -- ✅ CRITICAL: Include 'extensions' so it can find the <=> operator
    -- ✅ CRITICAL: Include 'public' so it can find the table
SET search_path TO extensions,
    public,
    pg_temp AS $$ BEGIN RETURN QUERY
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
-- 3. Grant permissions
GRANT EXECUTE ON FUNCTION public.match_test_embeddings(vector(768), float, int) TO authenticated;