# Cloud setup — detail & copy-paste prompts

Full how-to for the `mission-control-cloud` add-on. Schemas match the base build; only the storage and
the dashboard change.

## 1. Supabase migration

Run `assets/mission-control-supabase.sql`. It creates one key/value table:

```
mc_documents( key text primary key, payload jsonb, updated_at timestamptz )
```

and enables RLS with a single policy: **logged-in users may SELECT**. Writes come from Cowork's
privileged Supabase connection (runs as the table owner, bypassing RLS), so no write policy is needed
and the anon key shipped in the dashboard can only read — and only once signed in.

Then create one login: Authentication → Providers → enable **Email**, then Users → **Add user**
(email + password, **Auto Confirm**).

## 2. The Cowork write-step (ready to paste)

Add this so each refresh mirrors its output to Supabase. Adjust the file paths to the build's actual
domain folders.

```
Extend the refresh workflows: after each one writes its local file in the project
folder, also push the same JSON to Supabase so the hosted dashboard can read it.
Use the Supabase connector to upsert one row per document:

  insert into public.mc_documents (key, payload, updated_at)
  values ('<key>', '<json>'::jsonb, now())
  on conflict (key) do update
    set payload = excluded.payload, updated_at = now();

Map files to keys:
  {daily-domain}/data/calendar.json        -> 'calendar'
  {daily-domain}/data/inbox-triage.json    -> 'inbox-triage'
  {client-domain}/data/hours-summary.json  -> 'hours-summary'
  {client-domain}/data/client-inbox.json   -> 'client-inbox'
  {client-domain}/inputs/clients.json      -> 'clients'
Latest brief -> key 'brief-latest', payload {"name":"<filename>","content":"<markdown>"}.
Outputs      -> key 'outputs', payload {"files":[<names in the outputs/ dirs>]}.

Keep writing the local files too — the local dashboard and on-demand skills still
use them; Supabase is a SECOND sink, not a replacement. Escape JSON properly,
never put secrets in payload. This step only writes to Supabase; the dashboard
only reads.
```

After adding it, run a refresh once to populate the table.

## 3. Configure & deploy the dashboard

- In `assets/dashboard-cloud.html`, set `MC_CONFIG.SUPABASE_URL` and `SUPABASE_ANON_KEY` (Project
  Settings → API → Project URL + **anon public** key), plus title/brand/labels/panels.
- Deploy the single file to **Vercel** or **Cloudflare Pages** (drag-drop or a one-file repo; free,
  HTTPS included). Open the URL on the phone, sign in once — the session persists in the browser.

## 4. Security (for client data)

- RLS makes the data unreadable without a signed-in session; the anon key alone reveals nothing.
- The anon key is **designed to be public**; never ship the service-role key in the dashboard.
- Always serve over HTTPS (Vercel/Cloudflare provide it). One user is fine; add more in Supabase Auth.
- `outputs/` files live locally — cloud mode lists them by name only; it does not host the files.

## 5. Cost

- Supabase free tier easily covers a handful of small JSON rows and one user.
- The dashboard polls **only while visible** (default 5 min), so an open phone tab costs almost nothing.
- Prefer a **free static host** (Vercel/Cloudflare Pages) over a container host like Railway — a
  container bills for running continuously even when idle; static hosting does not.

## 6. Multi-business

Add a `workspace` column to `mc_documents` (the SQL footer shows how), make the primary key
`(workspace, key)`, scope the read policy by a workspace claim, and give each business its own login.
A single workspace needs none of this.
