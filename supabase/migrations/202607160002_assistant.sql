create table if not exists public.assistant_conversations (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  reference text not null check (length(reference) between 1 and 100),
  passage_text text not null check (length(passage_text) between 1 and 12000),
  question text not null check (length(question) between 1 and 1000),
  answer text not null check (length(answer) between 1 and 30000),
  created_at timestamptz not null default now()
);

create table if not exists public.assistant_daily_usage (
  user_id uuid not null references auth.users(id) on delete cascade,
  usage_day date not null,
  request_count integer not null default 0 check (request_count >= 0),
  primary key (user_id, usage_day)
);

create table if not exists public.assistant_monthly_usage (
  usage_month date primary key,
  request_count integer not null default 0 check (request_count >= 0)
);

create index if not exists assistant_conversations_user_created_idx
  on public.assistant_conversations (user_id, created_at desc);

alter table public.assistant_conversations enable row level security;
alter table public.assistant_daily_usage enable row level security;
alter table public.assistant_monthly_usage enable row level security;

drop policy if exists "assistant conversations belong to their user"
  on public.assistant_conversations;
create policy "assistant conversations belong to their user"
  on public.assistant_conversations
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

revoke all on public.assistant_conversations from anon;
revoke all on public.assistant_daily_usage from anon, authenticated;
revoke all on public.assistant_monthly_usage from anon, authenticated;
grant select, insert, update, delete
  on public.assistant_conversations to authenticated;

create or replace function public.consume_assistant_quota(
  p_user_id uuid,
  p_daily_limit integer,
  p_monthly_limit integer
)
returns table (allowed boolean, daily_remaining integer)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_day date := current_date;
  v_month date := date_trunc('month', current_date)::date;
  v_daily integer;
  v_monthly integer;
begin
  if p_user_id is null or p_daily_limit < 1 or p_monthly_limit < 1 then
    return query select false, 0;
    return;
  end if;

  -- ponytail: one global lock is sufficient at this scale. Replace it with
  -- per-user and per-month locks only if assistant throughput becomes material.
  perform pg_advisory_xact_lock(hashtextextended('lumen-assistant-quota', 0));

  insert into public.assistant_daily_usage (user_id, usage_day)
  values (p_user_id, v_day)
  on conflict do nothing;
  insert into public.assistant_monthly_usage (usage_month)
  values (v_month)
  on conflict do nothing;

  select request_count into v_daily
  from public.assistant_daily_usage
  where user_id = p_user_id and usage_day = v_day;
  select request_count into v_monthly
  from public.assistant_monthly_usage
  where usage_month = v_month;

  if v_daily >= p_daily_limit or v_monthly >= p_monthly_limit then
    return query select false, greatest(p_daily_limit - v_daily, 0);
    return;
  end if;

  update public.assistant_daily_usage
  set request_count = request_count + 1
  where user_id = p_user_id and usage_day = v_day;
  update public.assistant_monthly_usage
  set request_count = request_count + 1
  where usage_month = v_month;

  return query select true, p_daily_limit - v_daily - 1;
end;
$$;

revoke all on function public.consume_assistant_quota(uuid, integer, integer)
  from public, anon, authenticated;
grant execute on function public.consume_assistant_quota(uuid, integer, integer)
  to service_role;
