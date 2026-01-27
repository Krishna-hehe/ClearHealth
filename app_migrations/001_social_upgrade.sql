-- Migration: Social Upgrade (Chat & Streaks)

-- 1. Create circle_messages table
create table if not exists circle_messages (
  id uuid default gen_random_uuid() primary key,
  circle_id uuid references health_circles(id) on delete cascade not null,
  sender_id uuid references profiles(id) on delete cascade not null,
  content text not null,
  created_at timestamptz default now(),
  type text default 'text' -- 'text', 'image', 'system'
);

-- Enable Realtime
alter publication supabase_realtime add table circle_messages;

-- RLS for messages
alter table circle_messages enable row level security;

create policy "Members can view messages"
  on circle_messages for select
  using (
    exists (
      select 1 from health_circle_members
      where health_circle_members.circle_id = circle_messages.circle_id
      and health_circle_members.user_id = auth.uid()
    )
  );

create policy "Members can send messages"
  on circle_messages for insert
  with check (
    exists (
      select 1 from health_circle_members
      where health_circle_members.circle_id = circle_messages.circle_id
      and health_circle_members.user_id = auth.uid()
    )
  );

-- 2. Create user_streaks table (or we can just append to profiles, but separate is cleaner)
create table if not exists user_streaks (
  user_id uuid references profiles(id) on delete cascade primary key,
  current_streak int default 0,
  longest_streak int default 0,
  last_login_date date default CURRENT_DATE,
  updated_at timestamptz default now()
);

alter table user_streaks enable row level security;

create policy "Users can view own streak"
  on user_streaks for select
  using (auth.uid() = user_id);

create policy "Users can update own streak"
  on user_streaks for update
  using (auth.uid() = user_id);

-- Insert initial record trigger? 
-- For now, handled in app logic on login.
