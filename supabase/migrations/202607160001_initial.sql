create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  daily_goal smallint not null default 10 check (daily_goal between 1 and 500),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.reading_activity (
  user_id uuid not null references auth.users(id) on delete cascade,
  book_code text not null,
  chapter smallint not null check (chapter > 0),
  verse smallint not null check (verse > 0),
  read_day date not null,
  created_at timestamptz not null default now(),
  primary key (user_id, book_code, chapter, verse, read_day)
);

create table if not exists public.verse_preferences (
  user_id uuid not null references auth.users(id) on delete cascade,
  verse_id text not null,
  favorite boolean not null default false,
  highlight_color integer,
  updated_at timestamptz not null default now(),
  primary key (user_id, verse_id)
);

create table if not exists public.notes (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  book_code text not null,
  chapter smallint not null check (chapter > 0),
  start_verse smallint not null check (start_verse > 0),
  end_verse smallint not null check (end_verse >= start_verse),
  reference text not null,
  body text not null check (length(body) between 1 and 20000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists reading_activity_user_day_idx
  on public.reading_activity (user_id, read_day desc);
create index if not exists notes_user_updated_idx
  on public.notes (user_id, updated_at desc);

create or replace function public.create_profile_for_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (user_id) values (new.id);
  return new;
end;
$$;

drop trigger if exists create_profile_after_signup on auth.users;
create trigger create_profile_after_signup
  after insert on auth.users
  for each row execute function public.create_profile_for_new_user();

alter table public.profiles enable row level security;
alter table public.reading_activity enable row level security;
alter table public.verse_preferences enable row level security;
alter table public.notes enable row level security;

drop policy if exists "profiles belong to their user" on public.profiles;
create policy "profiles belong to their user" on public.profiles
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
drop policy if exists "reading activity belongs to its user" on public.reading_activity;
create policy "reading activity belongs to its user" on public.reading_activity
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
drop policy if exists "verse preferences belong to their user" on public.verse_preferences;
create policy "verse preferences belong to their user" on public.verse_preferences
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
drop policy if exists "notes belong to their user" on public.notes;
create policy "notes belong to their user" on public.notes
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

revoke all on public.profiles from anon;
revoke all on public.reading_activity from anon;
revoke all on public.verse_preferences from anon;
revoke all on public.notes from anon;
grant select, insert, update, delete on public.profiles to authenticated;
grant select, insert, update, delete on public.reading_activity to authenticated;
grant select, insert, update, delete on public.verse_preferences to authenticated;
grant select, insert, update, delete on public.notes to authenticated;
