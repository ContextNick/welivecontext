-- WLC Design Work Tracker — shared board schema (Supabase / Postgres)
-- Access model: OPEN (anyone with the link can read + write). Security is
-- intentionally permissive; add auth + tighter RLS later without changing
-- the table shapes. Run this once in the Supabase SQL editor.

-- ── Jobs ────────────────────────────────────────────────────────────────
create table if not exists public.jobs (
  id           text primary key,          -- 'j0'.. seed ids, 'n<ts>' created ids
  title        text not null default '',
  client       text not null default '',
  owner        text not null default 'Other',
  director     text not null default 'Other',
  contact      text not null default 'Other',
  provided     integer,                   -- day-epoch (Excel serial, base 1899-12-30)
  needed       integer,
  type         text not null default 'Other',
  ready        text not null default 'no',
  status       text not null default 'booked',
  notes        text not null default '',
  comment      text not null default '',
  completed_at integer,                   -- day-epoch; set when status -> 'done'
  position     double precision not null default 0,  -- order within a status column
  updated_at   timestamptz not null default now()
);

create index if not exists jobs_status_position_idx on public.jobs (status, position);

-- ── Settings (single shared row) ─────────────────────────────────────────
create table if not exists public.settings (
  id         text primary key default 'global',
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- ── Row level security: OPEN policy for the anon (public) key ─────────────
alter table public.jobs     enable row level security;
alter table public.settings enable row level security;

drop policy if exists "open access" on public.jobs;
create policy "open access" on public.jobs
  for all to anon, authenticated using (true) with check (true);

drop policy if exists "open access" on public.settings;
create policy "open access" on public.settings
  for all to anon, authenticated using (true) with check (true);

-- ── Realtime: broadcast row changes to every open board ──────────────────
alter publication supabase_realtime add table public.jobs;
alter publication supabase_realtime add table public.settings;
