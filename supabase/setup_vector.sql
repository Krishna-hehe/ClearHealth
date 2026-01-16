-- Enable the pgvector extension to work with embeddings
create extension if not exists vector;

-- Create a table to store lab result embeddings
create table if not exists public.test_embeddings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  test_name text not null,
  content text not null, -- The text chunk representing the lab result
  metadata jsonb, -- Additional info like date, status, etc.
  embedding vector(768), -- Gemini text-embedding-004 uses 768 dimensions
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Set up Row Level Security (RLS)
alter table public.test_embeddings enable row level security;

create policy "Users can view their own embeddings"
  on public.test_embeddings for select
  using (auth.uid() = user_id);

create policy "Users can insert their own embeddings"
  on public.test_embeddings for insert
  with check (auth.uid() = user_id);

-- Create a function to similarity search for embeddings
create or replace function match_test_embeddings (
  query_embedding vector(768),
  match_threshold float,
  match_count int
)
returns table (
  id uuid,
  content text,
  metadata jsonb,
  similarity float
)
language plpgsql
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
  order by similarity desc
  limit match_count;
end;
$$;
