-- ═══════════════════════════════════════════════════════════════════
--  Carrot Conveyor Chaos — leaderboard schema
--  Run this ONCE in your Supabase project:
--    Dashboard → SQL Editor → New query → paste → Run
-- ═══════════════════════════════════════════════════════════════════

create table if not exists public.scores (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  mode        text        not null check (mode in ('daily', 'endless')),
  -- which daily shift this belongs to; null for endless runs
  daily_num   integer     check (daily_num is null or daily_num between 1 and 100000),
  player_name text        not null check (player_name ~ '^[A-Za-z0-9_]{2,12}$'),
  -- a sane ceiling stops a tampered client from parking 9e99 at the top forever
  score       integer     not null check (score >= 0 and score <= 5000000),
  shift       integer     not null check (shift >= 1 and shift <= 999),
  sorted      integer     not null default 0 check (sorted >= 0 and sorted <= 200000),
  -- daily rows must carry a daily_num, endless rows must not
  constraint daily_num_matches_mode check (
    (mode = 'daily'   and daily_num is not null) or
    (mode = 'endless' and daily_num is null)
  )
);

-- Indexes matching the two queries the game actually makes
create index if not exists scores_daily_idx
  on public.scores (daily_num, score desc)
  where mode = 'daily';

create index if not exists scores_endless_idx
  on public.scores (score desc)
  where mode = 'endless';

-- ── Row Level Security ────────────────────────────────────────────
-- The anon key ships inside the game and is meant to be public. RLS is what
-- actually constrains it: anyone may read the board and append a score, but
-- nobody can edit or delete existing rows.
alter table public.scores enable row level security;

drop policy if exists "anyone can read scores"   on public.scores;
drop policy if exists "anyone can insert scores" on public.scores;

create policy "anyone can read scores"
  on public.scores for select
  to anon, authenticated
  using (true);

create policy "anyone can insert scores"
  on public.scores for insert
  to anon, authenticated
  with check (true);

-- Deliberately NO update or delete policy: with RLS on and no policy for an
-- action, that action is denied for everyone using the anon key.

-- ── Optional: quick views for checking on things ──────────────────
create or replace view public.v_today_top as
  select distinct on (player_name) player_name, score, shift, created_at
  from public.scores
  where mode = 'daily'
    and daily_num = floor(extract(epoch from (now() - timestamp '2026-01-01 00:00:00+00')) / 86400)::int + 1
  order by player_name, score desc;

create or replace view public.v_alltime_top as
  select distinct on (player_name) player_name, score, shift, created_at
  from public.scores
  where mode = 'endless'
  order by player_name, score desc;
