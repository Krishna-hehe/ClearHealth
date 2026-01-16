-- Enable the pgvector extension to work with embedding vectors
create extension if not exists vector;

-- Create a table to store your documents
create table if not exists test_embeddings (
  id bigserial primary key,
  user_id uuid references auth.users not null,
  test_name text not null,
  content text not null, -- The raw text content of the lab result
  metadata jsonb, -- Additional metadata like date, status, etc.
  embedding vector(768) -- Google Gemini text-embedding-004 produces 768 dimensions
);

-- Enable Row Level Security (RLS)
alter table test_embeddings enable row level security;

-- Create a policy that allows users to select only their own embeddings
create policy "Users can select their own embeddings"
on test_embeddings for select
using (auth.uid() = user_id);

-- Create a policy that allows users to insert their own embeddings
create policy "Users can insert their own embeddings"
on test_embeddings for insert
with check (auth.uid() = user_id);

-- Create a policy that allows users to delete their own embeddings
create policy "Users can delete their own embeddings"
on test_embeddings for delete
using (auth.uid() = user_id);

-- Create a match function to be used via RPC
create or replace function match_test_embeddings (
  query_embedding vector(768),
  match_threshold float,
  match_count int
)
returns table (
  id bigint,
  content text,
  metadata jsonb,
  similarity float
)
language plpgsql
stable
as $$
begin
  return query
  select
    test_embeddings.id,
    test_embeddings.content,
    test_embeddings.metadata,
    1 - (test_embeddings.embedding <=> query_embedding) as similarity
  from test_embeddings
  where 1 - (test_embeddings.embedding <=> query_embedding) > match_threshold
  order by test_embeddings.embedding <=> query_embedding
  limit match_count;
end;
$$;
