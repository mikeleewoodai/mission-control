---
name: mission-control-cloud
description: >-
  Add a cloud data layer and a hosted, login-protected dashboard to an existing or planned Mission
  Control so it's reachable from a phone or any device with the laptop closed. This is an OPTIONAL
  add-on layer that sits on top of `mission-control-blueprint` (which builds the local-first system) —
  use it only when you or a client specifically wants MOBILE / phone / remote / always-on access,
  since many builds are perfectly fine local-only. Triggers: "make the mission control mobile", "access
  it on my phone", "the client wants it on their phone", "put the dashboard in the cloud", "reach it
  when the laptop is off", "always-on dashboard", "host the mission control dashboard", "remote access
  to mission control". Produces a cloud add-on packet: the Supabase table + RLS migration, a configured
  Supabase-backed dashboard, the Cowork write-step that mirrors each refresh to Supabase, and a
  free static-host deploy checklist — plus a short client-facing privacy note. Use even if they don't
  say "skill" or "cloud" explicitly.
---

# Mission Control — Cloud Add-on

Layer a **cloud data layer + hosted dashboard** onto a Mission Control so it's reachable from a phone
or any device **with the laptop closed**. This is an **optional add-on** to `mission-control-blueprint`,
not a replacement: the base skill builds the local-first system; this one makes it remotely accessible
when that's actually wanted.

**Use this only when mobile / always-on access is a real requirement.** Many clients are happy local-
only. And if "from my phone" just means "while my machine is on," the lighter answer is a **Cloudflare
Tunnel or Tailscale** over the existing local server — no re-architecture, free, nothing to host.
Reach for this skill when the dashboard must be live **independent of the laptop**.

## What changes (and what doesn't)

The **data schemas are identical** to the base build — only *where* the data lives and *how* the
dashboard reads it change.

| | Base (local) | With this add-on (cloud) |
|---|---|---|
| Data layer | local JSON/MD files | rows in Supabase `mc_documents` (key = filename, payload = the JSON) |
| Dashboard | served folder (`dashboard.html`) | hosted `dashboard-cloud.html`, Supabase login |
| Reads | `fetch()` relative paths | Supabase REST, `authenticated` only (RLS) |
| Writes | refresh writes local files | refresh ALSO upserts to Supabase (local stays primary) |
| Hosting | `python -m http.server` | Vercel / Cloudflare Pages (free static, HTTPS) |
| Cost | none | Supabase free tier + free static host |

Document keys: `calendar`, `inbox-triage`, `hours-summary`, `client-inbox`, `clients`, `brief-latest`
(`{name,content}`), `outputs` (`{files:[...]}`). Full detail, SQL, and the write-step live in
`references/cloud-setup.md`.

## Prerequisites

- A Mission Control already built (or being built) with `mission-control-blueprint`, producing the
  standard data contract.
- A Supabase project (yours or the client's).
- A free static host account (Vercel or Cloudflare Pages).

## Step 1 — Provision Supabase

Run `assets/mission-control-supabase.sql` (Supabase SQL editor, or the connected Supabase tools). It
creates `mc_documents` and enables RLS with a **read-only-for-logged-in** policy. Then create one login:
Authentication → Providers (enable Email) → Users → Add user (email + password, Auto Confirm).

## Step 2 — Configure the dashboard

Use `assets/dashboard-cloud.html`. In `MC_CONFIG`, set `SUPABASE_URL` and `SUPABASE_ANON_KEY`
(Project Settings → API; both are **public-safe** — the anon key can only read, and only once signed
in), plus title, brand, labels, and which panels show. It polls **only while the tab is visible** and
defaults to a 5-min interval.

## Step 3 — Add the Cowork write-step

Extend each refresh so that, after it writes its local file, it also upserts the same JSON to Supabase
through Cowork's privileged Supabase connection (bypasses RLS — no write policy needed). The exact
ready-to-paste prompt and key mapping are in `references/cloud-setup.md`. **Keep the local files as the
primary sink** — the local dashboard and on-demand skills still use them; Supabase is a second sink.

## Step 4 — Deploy

Push `dashboard-cloud.html` to Vercel or Cloudflare Pages (free static hosting, HTTPS by default). Open
the URL on the phone and sign in once — the session persists.

## Output — Cloud add-on packet

Render, clearly labeled:
1. **Supabase migration** — the SQL to run.
2. **Configured dashboard** — `dashboard-cloud.html` with the client's `SUPABASE_URL`/anon key, brand,
   labels, panels.
3. **Cowork write-step** — the upsert prompt + key mapping.
4. **Deploy checklist** — host, set login, open on phone.
5. **Client-facing privacy note** — plain language: you open one private link on your phone, you log in
   once, the data is locked behind that login over HTTPS, and nothing is ever sent on your behalf.

## Principles

- **Optional layer.** Default to local; add this only when mobile / always-on is wanted. Prefer a
  tunnel when laptop-on access is enough.
- **RLS is non-negotiable for client data** — the dashboard holds calendar, client email, and hours;
  it must sit behind a login over HTTPS.
- The **anon key is public-safe**; never ship the service-role key in the dashboard.
- **Local files stay the source of truth**; Supabase is a mirror for remote reads.
- Generated `outputs/` files live locally — cloud mode lists them by name only.
