-- Synapse dogfooding schema
-- Run in Supabase SQL editor

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  created_at timestamptz default now()
);

create table if not exists tasks (
  id bigint primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  type text, kind text, dur text, done boolean, completed_at bigint,
  title text, descr text, date text, time text, place text,
  priority int, category text, energy int, repeat text, locked_by text,
  updated_at timestamptz default now()
);
create table if not exists goals (id bigint primary key, user_id uuid not null references auth.users(id) on delete cascade, title text, date text, descr text, progress int, micros jsonb, updated_at timestamptz default now());
create table if not exists reminders (id bigint primary key, user_id uuid not null references auth.users(id) on delete cascade, title text, done boolean);
create table if not exists settings (user_id uuid primary key references auth.users(id) on delete cascade, data jsonb);

alter table tasks enable row level security;
alter table goals enable row level security;
alter table reminders enable row level security;
alter table settings enable row level security;

drop policy if exists "owner tasks" on tasks;
drop policy if exists "owner goals" on goals;
drop policy if exists "owner rems" on reminders;
drop policy if exists "owner settings" on settings;
create policy "owner tasks" on tasks for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "owner goals" on goals for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "owner rems" on reminders for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "owner settings" on settings for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Notebook sync (one row per note, last-write-wins via updated_at)
create table if not exists nb_notes (
  id bigint primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  title text, tag text, content text, pinned boolean default false,
  updated_at timestamptz default now()
);
alter table nb_notes enable row level security;
drop policy if exists "owner nb" on nb_notes;
create policy "owner nb" on nb_notes for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Phase 1: reminders need updated_at for last-write-wins merge
alter table reminders add column if not exists updated_at timestamptz default now();
-- Phase reminders: tasks need remind fields (1h default for events)
alter table tasks add column if not exists remind_before text default '';
alter table tasks add column if not exists remind_at timestamptz;
alter table tasks add column if not exists remind_fired boolean default false;
alter table tasks add column if not exists gcal_id text;
alter table tasks add column if not exists gcal_link text;
