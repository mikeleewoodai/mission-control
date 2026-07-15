-- ============================================================
-- Mission Control — cloud data layer (Supabase)
-- One key/value table that mirrors the local file contract:
-- each "file" becomes a row keyed by its name, payload = its JSON.
-- Cowork writes rows via its privileged Supabase connection;
-- the hosted dashboard reads them only after logging in (RLS).
-- ============================================================

create table if not exists public.mc_documents (
  key        text primary key,          -- 'calendar' | 'inbox-triage' | 'hours-summary'
                                         -- | 'client-inbox' | 'clients' | 'brief-latest' | 'outputs'
  payload    jsonb       not null,       -- the document's JSON (same shapes as the local files)
  updated_at timestamptz not null default now()
);

-- Row Level Security ON — nothing is readable without an authenticated session.
alter table public.mc_documents enable row level security;

-- Logged-in users may READ every document.
drop policy if exists "mc_read_authenticated" on public.mc_documents;
create policy "mc_read_authenticated"
  on public.mc_documents
  for select
  to authenticated
  using (true);

-- NOTE on writes: Cowork upserts through its privileged Supabase connection
-- (runs as the table owner, bypassing RLS), so no INSERT/UPDATE policy is
-- needed for the anon/auth path. The anon key shipped in the dashboard can
-- ONLY read, and only once a user is signed in.

-- ---- Create your single dashboard user (run once) ----
-- Easiest: Supabase Studio → Authentication → Users → "Add user",
-- set an email + password, and toggle "Auto Confirm User".
-- (Email/password sign-in must be enabled under Authentication → Providers.)

-- ---- Multi-business later ----
-- To host more than one Mission Control from one project, add:
--   alter table public.mc_documents add column workspace text not null default 'default';
--   alter table public.mc_documents drop constraint mc_documents_pkey;
--   alter table public.mc_documents add primary key (workspace, key);
-- then scope the read policy by a workspace claim. Single workspace needs none of this.
